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
    case unableToOpen(String)
    
    // Object errors
    case unknownObjectName(String)
    case typeMismatch(String, String, String)
    case compilationError
    

    public var description: String {
        switch self {
        case .malformedLocation(let value):
            return "Malformed location: \(value)"
        case .unableToOpen(let value):
            return "Unable to open: \(value)"
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
        case .unableToOpen(_):
            return nil
        case .compilationError:
            return "Make sure that the model is valid, check the detailed list of model issues."
        case .unknownObjectName(_):
            return "See the list of available names by using the 'list' command."
        case .typeMismatch(_, _, _):
            return nil
        }
    }

}


// NOTE: Sync with Poietic/PoieticTool

func openDesign(url: URL, metamodel: Metamodel = FlowsMetamodel) throws -> Design {
    let store = MakeshiftDesignStore(url: url)
    let design: Design
    design = try store.load(metamodel: metamodel)
    // TODO: Print validation errors as in the cmdline tool
    
    return design
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
