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
    let memory: ObjectMemory
    
    init(memory: ObjectMemory) {
        self.memory = memory
        super.init()
        self["design"] = self.getDesign
//        self["sheets"] = self.getSheetList
//        self["sheet"] = self.getSheet
        self["simulate"] = self.simulate
    }
    
    func getDesign(request: HttpRequest) -> HttpResponse {
        var result: [String:Any] = [:]
        let frame = memory.currentFrame
        
        // All objects, id -> Object
        var objects: [String:Any] = [:]
        // List of node ids
        var nodes: [String] = []
        // List of edge ids
        var edges: [String] = []

        for object in frame.snapshots {
            let record = object.foreignRecord()
            let json = record.asJSONObject()
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
            result["design_info"] = designInfo.foreignRecord().asJSONObject()
        }

        result["objects"] = objects
        result["nodes"] = nodes
        result["edges"] = edges
        
        return .ok(.json(result))
    }

    func simulate(request: HttpRequest) -> HttpResponse {
        // let startTime = Double(request.params["start"] ?? "0.0")
        // let timeDelta = Double(request.params["timeDelta"] ?? "1.0")
//        guard let steps = Int(request.queryParams["steps"] ?? "10") else {
//            return .badRequest(.text("Invalid steps number: \(request.params["steps"])"))
//        }
        let steps = 100
        let simulator = Simulator(memory: memory)
        let view: StockFlowView
        
        do {
            let frame = memory.deriveFrame(original: memory.currentFrame.id)
            view = StockFlowView(frame)
            try simulator.compile(frame)
        }
        catch {
            print("Something went wrong: \(error)")
            return .internalServerError
        }
        simulator.initializeSimulation()
        simulator.run(steps)

        let output: [[Any]] = simulator.output.map { state in
            state.allValues.map { $0.asJSONObject() }
        }
        
        var result: [String:Any] = [:]
        let all_variables = simulator.compiledModel!.allVariables
        
        result["data"] = output
        
        var variables: [Any] = []
        for compiled_variable in all_variables {
            var variable: [String:Any] = [:]
            variable["index"] = compiled_variable.index
            variable["name"] = compiled_variable.name
            variable["type"] = String(describing: compiled_variable.type)
            variable["id"] = compiled_variable.id
            variables.append(variable)
        }
        result["variables"] = variables
        result["time_points"] = simulator.timePoints
        
        // Charts
        // ------
        
        var charts: [Any] = []
        
        let model = simulator.compiledModel!
        for chart in view.charts {
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
        let server = PoieticServer(memory: memory)

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
