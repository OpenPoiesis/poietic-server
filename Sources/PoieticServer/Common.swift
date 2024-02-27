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

    // Object errors
    case unknownObjectName(String)
    case typeMismatch(String, String, String)
    case compilationError

    public var description: String {
        switch self {
        case .malformedLocation(let value):
            return "Malformed location: \(value)"
        case .compilationError:
            return "Design compilation failed"
        case .unknownObjectName(let value):
            return "Unknown object with name '\(value)'"
        case .typeMismatch(let subject, let value, let expected):
            return "Type mismatch in \(subject) value '\(value)', expected type: \(expected)"

        }
    }
    
    public var hint: String? {
        // NOTE: Keep this list without 'default' so we know which cases we
        //       covered.
        
        switch self {
        case .malformedLocation(_):
            return nil
        case .compilationError:
            return nil
        case .unknownObjectName(_):
            return "See the list of available names by using the 'list' command."
        case .typeMismatch(_, _, _):
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

/// Compile the frame into a compiled stock-flows model.
///
/// This method compiles the model to be used with the simulator.
///
/// If the frame contains errors then the errors are printed out and an
/// ``ToolError`` exception is raised.
///
func compile(_ frame: MutableFrame) throws -> CompiledModel {
    // NOTE: Make this in sync with the Poietic flows tool
    // TODO: Use stderr as output
    let compiledModel: CompiledModel
    do {
        let compiler = Compiler(frame: frame)
        compiledModel = try compiler.compile()
    }
    catch let error as NodeIssuesError {
        for (id, issues) in error.issues {
            for issue in issues {
                let object = frame.object(id)
                let label: String
                if let name = object.name {
                    label = "\(id)(\(name))"
                }
                else {
                    label = "\(id)"
                }

                print("ERROR: node \(label): \(issue)")
                if let issue = issue as? NodeIssue, let hint = issue.hint {
                    print("HINT: node \(label): \(hint)")
                }
            }
        }
        throw ToolError.compilationError
    }
    return compiledModel
}


/// Convert values of controls from foreign format into internal value types.
///
/// This function takes a map of string representation of variable or object
/// references (names or IDs) and their corresponding values. The textual
/// references are mapped into internal references and the values are
/// converted into corresponding type.
///
func convertForeignParameters(_ foreignParameters: [(String, String)], model: CompiledModel) throws -> [ObjectID:Double] {
    var result: [ObjectID: Double] = [:]
    for (key, stringValue) in foreignParameters {
        guard let doubleValue = Double(stringValue) else {
            throw ToolError.typeMismatch("constant override '\(key)'", stringValue, "double")
        }
        guard let variable = model.variable(named: key) else {
            throw ToolError.unknownObjectName(key)
        }
        result[variable.id] = doubleValue
    }
    return result
}
