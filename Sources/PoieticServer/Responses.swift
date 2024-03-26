//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 25/03/2024.
//

// NOTE: This is an exploration of requirements for the server.

import Foundation
import PoieticFlows
import PoieticCore


public struct ExportedSimulationObject: Encodable {
    let id: String
    let type: SimulationObject.SimulationObjectType
    let variableIndex: Int
    let valueType: String
}

public struct ExportedStateVariable: Encodable {
    let index: Int
    let type: String // builtin | object
    let valueType: String
    let name: String
    let id: String?
    
}

public struct ExportedParameterControl: Encodable {
    let controlNodeID: String
    let variableIndex: Int
    let variableName: String
    let variableNodeID: String
    let value: String?
}

public struct ExportedDesign: Encodable {
    // Message for whoever consumes the exported design (through a server)
    let __important_message = "THIS OUTPUT FORMAT IS A PROTOTYPE"
    let formatVersion = "0.0.1"
    let info: [String:Variant]
    let objects: [ForeignObject]
    let nodes: [String]
    let edges: [String]
    let stateVariables: [ExportedStateVariable]
    let simulationObjects: [ExportedSimulationObject]
    let parameterControls: [ExportedParameterControl]
    let timeVariableIndex: Int
}

public struct ExportedChart: Encodable {
    let id: String
    let series: [ExportedChartSeries]
}

public struct ExportedChartSeries: Encodable {
    let id: String
    let index: Int
    let data: [Double]
}

public struct ExportedSimulationResult: Encodable {
    let timePoints: [Double]
    let data: [[Variant]]
    let charts: [ExportedChart]
    let controls: [String:Double]
}
