//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 10/10/2023.
//

import Foundation
import PoieticCore
import PoieticFlows

/// Error thrown by the command-line tool.
///
enum ToolError: Error, CustomStringConvertible {
    // I/O errors
    case malformedLocation(String)

    public var description: String {
        switch self {
        case .malformedLocation(let value):
            return "Malformed location: \(value)"
        }
    }
    
    public var hint: String? {
        // NOTE: Keep this list without 'default' so we know which cases we
        //       covered.
        
        switch self {
        case .malformedLocation(_):
            return nil
        }
    }

}



// NOTE: Sync with Poietic/PoieticTool

let defaultDatabase = "Design.poietic"
let databaseEnvironment = "POIETIC_DESIGN"

/// Get the database URL. The database location can be specified by options,
/// environment variable or as a default name, in respective order.
func databaseURL(path: String?) throws -> URL {
    let location: String
    let env = ProcessInfo.processInfo.environment
    
    if let path {
        location = path
    }
    else if let path = env[databaseEnvironment] {
        location = path
    }
    else {
        location = defaultDatabase
    }
    
    if let url = URL(string: location) {
        if url.scheme == nil {
            return URL(fileURLWithPath: location, isDirectory: false)
        }
        else {
            return url
        }
    }
    else {
        throw ToolError.malformedLocation(location)
    }
}

/// Opens a graph from a package specified in the options.
///
func openMemory(path: String?) throws -> ObjectMemory {
    let memory: ObjectMemory = ObjectMemory(metamodel: FlowsMetamodel.self)
    let dataURL = try databaseURL(path: path)

    try memory.restoreAll(from: dataURL)
    
    return memory
}


