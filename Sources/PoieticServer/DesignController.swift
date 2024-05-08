//
//  File.swift
//
//
//  Created by Stefan Urbanek on 11/03/2024.
//

import PoieticCore
import PoieticFlows
import ArgumentParser
import Hummingbird
import Foundation


struct DesignController<Context: RequestContext> {
    let url: URL
    let design: Design
    let frame: Frame
    let model: CompiledModel
    
    func addRoutes(to group: RouterGroup<Context>) {
    }
    
    init(url: URL) throws {
        self.url = url
        self.design = try openDesign(url: url)
        self.frame = design.currentFrame
        let compiler = Compiler(frame: design.currentFrame)
        self.model = try compiler.compile()
    }

    func getDesign(request: Request, context: Context) throws -> Response {
        let simulator = Simulator(model: model)
        
        let designInfo = frame.first(type: ObjectType.DesignInfo)?
                            .asForeignObject().attributes ?? ForeignRecord()

        var objects: [ForeignObject] = []
        var nodes: [String] = []
        var edges: [String] = []

        for object in frame.snapshots {
            objects.append(object.asForeignObject())
            
            // Extract by structure type
            if object.structure.type == .node {
                nodes.append(String(object.id))
            }
            else if object.structure.type == .edge {
                edges.append(String(object.id))
            }
        }
        
        var stateVariables: [ExportedStateVariable] = []
        for variable in simulator.compiledModel.stateVariables {
            let idString: String? = if let id = variable.objectID {
                String(id)
            }
            else {
                nil
            }
            let out = ExportedStateVariable(
                index: variable.index,
                type: variable.type.rawValue,
                valueType: "\(variable.valueType)",
                name: variable.name,
                id: idString
            )
            stateVariables.append(out)
        }
        
        var simObjects: [ExportedSimulationObject] = []
        
        for object in simulator.compiledModel.simulationObjects {
            let out = ExportedSimulationObject(
                id: String(object.id),
                type: object.type,
                variableIndex: object.variableIndex,
                valueType: "\(object.valueType)"
            )
            simObjects.append(out)
        }
        
        // We need to initialize the state to get the control values
        do {
            try simulator.initializeState()
        }
        catch {
            print("ERROR: \(error)")
            throw HTTPError(.internalServerError)
        }

        var controls = exportParameterControls(simulator)

        let result = ExportedDesign(
            info: designInfo.dictionary,
            objects: objects,
            nodes: nodes,
            edges: edges,
            stateVariables: stateVariables,
            simulationObjects: simObjects,
            parameterControls: controls,
            timeVariableIndex: simulator.compiledModel.timeVariableIndex
        )
        
        let encoder = Hummingbird.JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return try encoder.encode(result, from: request, context: context)
    }

    func runSimulation(request: Request, context: Context) throws -> Response {
        // let startTime = Double(request.params["start"] ?? "0.0")
        // let timeDelta = Double(request.params["timeDelta"] ?? "1.0")

        // Prepare the simulation
        // -----------------------------------------------------

        let simulator = Simulator(model: model)
        
        // Override parameters from controls
        // -----------------------------------------------------
        print("=== Simulate")
        let overrideConstants: [ObjectID: Double]
        
        overrideConstants = try parseParameterConstants(request)

        do {
            try simulator.initializeState(override: overrideConstants)
        }
        catch {
            print("RUNTIME ERROR: \(error)")
            throw HTTPError(.internalServerError)
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
            throw HTTPError(.internalServerError)
        }

        // Process simulation output
        // -----------------------------------------------------
        let data: [[Variant]] = simulator.output.map { state in
            state.values
        }
        
        var result: [String:Any] = [:]
        
        var variables: [Any] = []
        for (index, simVariable) in model.stateVariables.enumerated() {
            var variable: [String:Any] = [:]
            variable["index"] = index
            variable["name"] = simVariable.name
            variable["type"] = String(describing: simVariable.type)
            if let id = simVariable.objectID {
                variable["id"] = id
            }
            variables.append(variable)
        }
        result["variables"] = variables
        result["time_points"] = simulator.timePoints
        
        // Charts
        // ------
        
        var charts: [ExportedChart] = []
        
        for chart in model.charts {
            var outSeries: [ExportedChartSeries] = []

            for series in chart.series {
                let index = model.variableIndex(of: series.id)!
                let item = ExportedChartSeries(
                    id: String(series.id),
                    index: index,
                    data: simulator.dataSeries(index: index)
                )
                outSeries.append(item)
            }
            let outChart = ExportedChart(
                id: String(chart.node.id),
                series: outSeries
            )
            charts.append(outChart)
        }

        // NOTE: This is needed because JSON encoder encodes [ObjectID:Double] as an array.
        let controls: [String:Double] = Dictionary(uniqueKeysWithValues:
            simulator.currentControlValues().map({ (key, value) in
            (String(key), value)
        }))
        
        let result2 = ExportedSimulationResult(
            timePoints: simulator.timePoints,
            data: data,
            charts: charts,
            controls: controls
        )
        
        let encoder = Hummingbird.JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return try encoder.encode(result2, from: request, context: context)
    }

    func parseParameterConstants(_ request: Request) throws -> [ObjectID:Double] {
        var result: [ObjectID:Double] = [:]
        for (key, value) in request.uri.queryParameters {
            let foreignValue = try Variant(String(value)).doubleValue()
            guard let id = model.variable(named: String(key))?.id else {
                throw HTTPError(.badRequest, message: "Unknown object for a parameter with name: \(key)")
            }
            
            result[id] = foreignValue
        }
        return result
    }
    
    func exportParameterControls(_ simulator: Simulator) -> [ExportedParameterControl] {
        // TODO: Integrate into the response function, no longer needed as shared
        let controlValues = simulator.currentControlValues()
        var controls: [ExportedParameterControl] = []
        for binding in model.valueBindings {
            let variable = model.stateVariables[binding.variableIndex]
            let control = ExportedParameterControl(
                controlNodeID: String(binding.control),
                variableIndex: variable.index,
                variableName: variable.name,
                variableNodeID: String(variable.objectID!),
                value: String(controlValues[binding.control]!)
            )

            controls.append(control)
        }
        return controls
    }
}

extension Simulator {
    /// Return a mapping of control IDs and values of their targets.
    ///
    /// The values are obtained from the current simulation state.
    ///
    /// - SeeAlso: ``CompiledModel/valueBindings``,
    ///   ``PoieticCore/ObjectType/Control``
    ///
    public func currentControlValues() -> [ObjectID:Double] {
        // FIXME: Use convertForeignParameters
        precondition(currentState != nil,
                    "Trying to get control values without initialized state")
        // TODO: [REFACTORING] Move to SimulationState
        // TODO: This is redundant, it is extracted in the control nodes
        var values: [ObjectID:Double] = [:]
        for binding in compiledModel.valueBindings {
            values[binding.control] = currentState.double(at: binding.variableIndex)
        }
        return values
    }
}
