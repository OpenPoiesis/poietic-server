//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 25/09/2023.
//

import PoieticCore
import PoieticFlows
@preconcurrency import ArgumentParser
import Foundation

import Hummingbird

@main
struct PoieticServerTool: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "poietic-server",
        abstract: "Poietic-Flows simulation server."
    )
    
    @Option(name: .shortAndLong)
    var hostname: String = "127.0.0.1"


    @Option(name: .shortAndLong)
    var port: Int = 8080
    
    @Argument(help: "URL or a path for design library")
    var libraryLocation: String = "poietic-library.json"
    
    mutating func run() async throws {
        print("Using library description: \(libraryLocation)")

        let library = try libraryInfo(from: libraryLocation)
        
        print("Serving \(library.items.count) models.")
        
        // create router and add a single GET /hello route
        let router = Router()
        router.get("/models") { request, context in
            library.items
        }
        
        router.get("/models/:name") { request, context in
            guard let name = context.parameters.get("name") else {
                throw HTTPError(.badRequest, message: "No design name given.")
            }
            guard let item = library.items.first(where: { $0.name == name}) else {
                throw HTTPError(.notFound, message: "Design '\(name)' not found.")
            }
            
            let controller = try DesignController<BasicRequestContext>(url: item.url)
            
            do {
                return try controller.getDesign(request: request, context: context)
            }
            catch {
                print("ERROR: \(error)")
                throw HTTPError(.internalServerError, message: "Something went wron.")
            }
        }

        router.get("/models/:name/run") { request, context in
            guard let name = context.parameters.get("name") else {
                throw HTTPError(.badRequest, message: "No design name given.")
            }
            guard let item = library.items.first(where: { $0.name == name}) else {
                throw HTTPError(.notFound, message: "Design '\(name)' not found.")
            }
            
            let controller = try DesignController<BasicRequestContext>(url: item.url)
            
            return try controller.runSimulation(request: request, context: context)
        }

        // create application using router
        let app = Application(
            router: router,
            configuration: .init(address: .hostname(self.hostname, port: self.port))
        )
        print("APP: \(app)")
        // run hummingbird application
        print("Starting server...")
        try await app.runService()
        print("Poietic Server finished.")
    }
}

func libraryInfo(from location: String) throws -> DesignLibraryInfo {
    guard let url = URL(string: location) else {
        throw ToolError.malformedLocation(location)
    }

    let actualURL = if url.scheme == nil {
        URL(fileURLWithPath: location, isDirectory: false).absoluteURL
    }
    else {
        url
    }

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let data: Data
    do {
        data = try Data(contentsOf: actualURL)
    }
    catch {
        throw ToolError.unableToOpen(location)
    }

    return try decoder.decode(DesignLibraryInfo.self, from: data)
}
