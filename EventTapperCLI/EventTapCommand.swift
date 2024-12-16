//
//  EventTapCommand.swift
//  EventTapperCLI
//
//  Created by Phil Zakharchenko on 12/14/24.
//

import Foundation
import ArgumentParser
import EventTapCore
import CoreGraphics

@main
struct EventTapCommand: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "event-tap",
        abstract: "Monitor system events like keyboard and mouse input",
        version: "1.0"
    )
    
    @Option(name: .shortAndLong, help: "Duration to run the monitor (in seconds). Omit for continuous monitoring.")
    var duration: Double?
    
    @Option(name: .shortAndLong, help: "Location to monitor events from.")
    var location: TapLocation = .session
    
    @Option(name: .shortAndLong, help: "Placement of the event tap.")
    var placement: TapPlacement = .head
    
    @Option(name: .long, help: "Filter events by type (e.g. mouse, keyboard, all).")
    var types: EventFilter = .all
    
    @Option(name: .long, help: "Raw values of field keys to display. By default, all fields are included.")
    var fields: [UInt32] = Array(0...200)
    
    @Option(name: .long, help: "Include labels for known fields.")
    var labeledFields: Bool = false
    
    @Flag(name: .long, help: "Output events as JSON.")
    var json: Bool = false
    
    @Flag(name: .shortAndLong, help: "Include timestamp in output.")
    var timestamp: Bool = false
    
    enum EventFilter: String, ExpressibleByArgument {
        case all, mouse, keyboard
        
        func matches(_ type: CGEventType) -> Bool {
            let key = EventTypeKey(rawValue: type.rawValue)
            return switch self {
            case .all: true
            case .mouse: key.isMouseEvent
            case .keyboard: key.isKeyboardEvent
            }
        }
    }
    
    mutating func run() async throws {
        guard CGPreflightListenEventAccess() else {
            CGRequestListenEventAccess()
            print("Monitoring events in other applications requires the Input Monitoring permission.")
            throw ExitCode.failure
        }
        
        let eventTap = EventTap(tapLocation: .cghidEventTap, tapPlacement: .headInsertEventTap)
        
        // Print the header.
        if !json {
            printTableHeader()
        }
        
        // Set up termination handling.
        try handleTermination()
        
        // Set up duration-based termination if specified.
        if let duration {
            Task {
                try await Task.sleep(for: .seconds(duration))
                Self.exit(withError: nil)
            }
        }
        
        // Start monitoring events.
        try eventTap.startMonitoring { [self] type, event in
            guard types.matches(type) else { return }
            
            let eventInfo = Event(event: event, of: type)
            
            if json {
                printJsonEvent(eventInfo)
            } else {
                printTableRow(eventInfo)
            }
        }
    }
    
    private func handleTermination() throws {
        let signalQueue = DispatchQueue(label: "signal-queue")
        let signalSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: signalQueue)
        
        signal(SIGINT, SIG_IGN)
        
        signalSource.setEventHandler {
            if json {
                print("]")
            }
            
            Self.exit(withError: nil)
        }
        
        signalSource.resume()
        
        if json {
            print("[")
        }
    }
    
    private func printTableHeader() {
        let header = [
            "Type".padding(toLength: 15, withPad: " ", startingAt: 0),
            "Details".padding(toLength: 30, withPad: " ", startingAt: 0),
            "Fields"
        ].joined(separator: " │ ")
        
        print(header)
        print(String(repeating: "─", count: 16) + "┼" +
              String(repeating: "─", count: 32) + "┼" +
              String(repeating: "─", count: 30))
    }
    
    private func printTableRow(_ event: Event) {
        let description = cliDescription(for: event)
        return if timestamp {
            print("\(dateFormatter.string(from: event.date)) │ \(description)")
        } else {
            print(description)
        }
    }
    
    private func printJsonEvent(_ event: Event) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let jsonData = try? JSONSerialization.data(withJSONObject: event),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString + ",")
        }
    }
    
    private var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "HH:mm:ss.SSS"
        return df
    }
    
    private func cliDescription(for event: Event) -> String {
        var components: [String] = []
        
        let type = formatEventType(for: event)
        let details = formatEventDetails(for: event)
        let fields = formatFields(for: event)
        
        components.append(contentsOf: [type, details, fields])
        
        return components.joined(separator: " │ ")
    }
    
    private func formatEventType(for event: Event) -> String {
        let typeLabel = String(event.type.rawValue) + " " + (event.type.label ?? "Unknown")
        return typeLabel.padding(toLength: 15, withPad: " ", startingAt: 0)
    }
    
    private func formatEventDetails(for event: Event) -> String {
        var details: [String] = []
        
        // Add keyboard info if present
        if let keyString = event.keyboardKeyString {
            details.append("Key: \(keyString)")
        }
        
        // Add mouse location if relevant
        if event.type.isMouseEvent {
            details.append("(\(Int(event.mouseLocation.x)), \(Int(event.mouseLocation.y)))")
        }
        
        // Add flags if present
        if !event.flags.isEmpty {
            let flagsStr = event.flags.map(\.shortDescription).joined()
            details.append("[\(flagsStr)]")
        }
        
        return details.joined(separator: " ")
            .padding(toLength: 30, withPad: " ", startingAt: 0)
    }
    
    private func formatFields(for event: Event) -> String {
        var fieldStrings: [String] = []
        let allowedFields = Set(fields)
        
        // Format integer fields.
        let relevantIntFields = event.intFields.filter { field in
            allowedFields.contains(field.key.rawValue) && field.value != 0
        }
        
        if !relevantIntFields.isEmpty {
            fieldStrings.append(contentsOf: relevantIntFields.map { field in
                let rawValueString = String(field.key.rawValue)
                let label: String = if labeledFields {
                    field.key.description
                } else {
                    rawValueString
                }
                
                return "\(label): \(field.value)"
            })
        }
        
        // Format double fields.
        let relevantDoubleFields = event.doubleFields.filter { field in
            allowedFields.contains(field.key.rawValue) && field.value != 0
        }
        
        if !relevantDoubleFields.isEmpty {
            fieldStrings.append(contentsOf: relevantDoubleFields.map { field in
                let rawValueString = String(field.key.rawValue)
                let label: String = if labeledFields {
                    field.key.description
                } else {
                    rawValueString
                }
                
                return "\(label): \(String(format: "%.2f", field.value))"
            })
        }
        
        return fieldStrings.isEmpty ? "" : fieldStrings.joined(separator: ", ")
    }
}
