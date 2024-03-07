//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 25/09/2023.
//

import Swifter
import PoieticCore
import PoieticFlows
import ArgumentParser
import Dispatch


class PoieticServer: HttpServer {
    let frame: Frame
    let model: CompiledModel

    init(frame: Frame, model: CompiledModel) throws {
        self.frame = frame
        self.model = model
        
        super.init()
        
        self["design"] = self.getDesign
        self["simulate"] = self.simulate
    }
    
    
    /// Get the design and compiled model.
    ///
    /// Result properties:
    ///
    /// - `design_info` - human-relevant information about the design, the
    ///   keys are: `title`, `author`, `license`, `abstract` and `documentation`;
    ///   all design info keys are optional.
    /// - `objects` - a dictionary of all design objects, where the keys are
    ///   object IDs and values are the objects with their attributes.
    /// - `nodes` - list of IDs of nodes
    /// - `edges` - list of IDs of edges
    /// - `control_bindings` - list of resolved bindings
    ///
    /// The object dictionary:
    ///
    /// - `id` – object ID
    /// - `type` – object type name
    /// - `structure` – object structure type: `unstructured`, `node`, `edge`
    /// - `origin` and `target` for edge structure type
    /// - `parent` – ID of parent object (if present)
    /// - attributes of the object depending on the object type
    ///
    /// The control bindings structure is:
    ///
    /// - `control_node_id` – ID of a node that represents the control
    /// - `variable_node_id` – ID of a node that contains a simulation variable
    ///    that is being controlled
    /// - `variable_index` – index of the controlled variable in the list of
    ///    result variables
    ///
    func getDesign(request: HttpRequest) -> HttpResponse {
        let simulator = Simulator(model: model)
        var result: [String:Any] = [:]
        
        // All objects, id -> Object
        var objects: [String:Any] = [:]
        // List of node ids
        var nodes: [String] = []
        // List of edge ids
        var edges: [String] = []

        for object in frame.snapshots {
            let record = object.foreignRecord()
            let json = record.asJSON()
            objects[String(object.id)] = json

            // Extract by structure type
            if object.structure.type == .node {
                nodes.append(String(object.id))
            }
            else if object.structure.type == .edge {
                edges.append(String(object.id))
            }
        }
        
        if let designInfo = frame.first(type: ObjectType.DesignInfo) {
            result["design_info"] = designInfo.foreignRecord().asJSON()
        }
        
        // We need to initialize the state to get the control values
        do {
            try simulator.initializeState()
        }
        catch {
            print("ERROR: \(error)")
            return .internalServerError
        }

        let controlValues = simulator.controlValues()
        var bindings: [[String:Any]] = []
        for binding in model.valueBindings {
            let variable = model.computedVariables[binding.variableIndex]
            var record: [String:Any] = [:]
            record["control_node_id"] = binding.control
            record["variable_index"] = model.resultIndex(of: variable.id)
            record["variable_name"] = variable.name
            record["variable_node_id"] = variable.id
            record["initial_value"] = controlValues[binding.control]
            bindings.append(record)
        }
        

        result["objects"] = objects
        result["nodes"] = nodes
        result["edges"] = edges
        result["control_bindings"] = bindings
        
        return .ok(.json(result))
    }
    
    func parseParameters(parameters: [String:String]) -> [String:Variant] {
        var result: [String:Variant] = [:]
        for (key, value) in parameters {
            let foreignValue = Variant(value)
            result[key] = foreignValue
        }
        return result
    }
    func simulate(request: HttpRequest) -> HttpResponse {
        // let startTime = Double(request.params["start"] ?? "0.0")
        // let timeDelta = Double(request.params["timeDelta"] ?? "1.0")
//        guard let steps = Int(request.queryParams["steps"] ?? "10") else {
//            return .badRequest(.text("Invalid steps number: \(request.params["steps"])"))
//        }

        // Prepare the simulation
        // -----------------------------------------------------

        let steps = 100
        let simulator = Simulator(model: model)
        let view: StockFlowView
        
        // Override parameters from controls
        // -----------------------------------------------------
        print("=== Simulate")
        let overrideConstants: [ObjectID: Double]
        
        do {
            // TODO: Get only controls
            overrideConstants = try convertForeignParameters(request.queryParams, model: model)
        }
        catch let error as ToolError {
            // FIXME: Return detailed error
            print("ERROR: \(error)")
            return .internalServerError
        }
        catch {
            print("UNKNOWN ERROR: \(error)")
            return .internalServerError

        }

        do {
            try simulator.initializeState(override: overrideConstants)
        }
        catch {
            print("RUNTIME ERROR: \(error)")
            return .internalServerError
        }

        // Run the Simulation
        // -----------------------------------------------------
        let defaultSteps = simulator.compiledModel.simulationDefaults?.simulationSteps
//        let actualSteps = steps ?? defaultSteps ?? 10
        let actualSteps = defaultSteps ?? 10

        do {
            try simulator.run(actualSteps)
        }
        catch {
            print("RUNTIME ERROR: \(error)")
            return .internalServerError
        }

        // Process simulation output
        // -----------------------------------------------------
        let output: [[Any]] = simulator.output.map { state in
            state.allValues.map { $0.asJSON() }
        }
        
        var result: [String:Any] = [:]
        
        result["data"] = output
        
        var variables: [Any] = []
        for (index, simVariable) in model.allVariables.enumerated() {
            var variable: [String:Any] = [:]
            variable["index"] = index
            variable["name"] = simVariable.name
            variable["type"] = String(describing: simVariable.type)
            if let id = simVariable.id {
                variable["id"] = id
            }
            variables.append(variable)
        }
        result["variables"] = variables
        result["time_points"] = simulator.timePoints
        
        // Charts
        // ------
        
        var charts: [Any] = []
        
        for chart in model.charts {
            var chart_info: [String:Any] = [:]
            chart_info["id"] = chart.node.id
            var chart_series: [Any] = []
            
            for series in chart.series {
                var dict: [String:Any] = [:]
                dict["id"] = series.id
                dict["name"] = series.name
                let variable = model.variable(for: series.id)!
                dict["variable_index"] = variable.index
                dict["data"] = simulator.dataSeries(index: variable.index)
                chart_series.append(dict)
            }
            chart_info["series"] = chart_series
            charts.append(chart_info)
        }
        
        result["charts"] = charts
        return .ok(.json(result))
    }
}

struct PoieticTool: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "poietic-server",
        abstract: "Poietic-Flows simulation server."
    )
    
    @Argument(help: "Path to a Poietic Design database.")
    var database: String = "/Users/stefan/Developer/Projects/Poietic/demo.poietic"
    
    mutating func run() throws {
        print("DB: \(database)")

        let memory = try openMemory(path: database)
        let frame = memory.deriveFrame(original: memory.currentFrame.id)
        let compiledModel = try compile(frame)
        
        let server = try PoieticServer(frame: frame, model: compiledModel)

        print("Starting server...")
        let semaphore = DispatchSemaphore(value: 0)
        do {
          try server.start(9080, forceIPv4: true)
          print("Server has started ( port = \(try server.port()) ). Try to connect now...")
          semaphore.wait()
        } catch {
          print("Server start error: \(error)")
          semaphore.signal()
        }
        print("Server finished.")
    }
}

PoieticTool.main()
