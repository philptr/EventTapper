//
//  FilteredTableView.swift
//  EventTapper
//
//  Created by Phil Zakharchenko on 12/15/24.
//

import SwiftUI
import EventTapCore

struct FilteredTableView: View {
    @Bindable var coordinator: EventTapCoordinator
    @Binding var predicate: Predicate<IdentifiedEvent>
    @Binding var selectedEventIDs: Set<IdentifiedEvent.ID>
    
    @SceneStorage("EventTableCustomization")
    private var customization: TableColumnCustomization<IdentifiedEvent>
    
    var body: some View {
        Table(filteredData, selection: $selectedEventIDs, columnCustomization: $customization) {
            TableColumn("Time") { event in
                Text("\(event.info.date.formatted(date: .numeric, time: .complete))")
            }
            .customizationID("time")
            
            TableColumn("Type") { event in
                DataCellView(cell: DataCell(event.info.type))
            }
            .customizationID("type")
            
            TableColumn("Mouse Location") { event in
                Text("\(String(describing: event.info.mouseLocation))")
            }
            .customizationID("mouseLocation")
            
            TableColumn("Unflipped Mouse Location") { event in
                Text("\(String(describing: event.info.unflippedLocation))")
            }
            .defaultVisibility(.hidden)
            .customizationID("unflippedLocation")
            
            TableColumn("Flags") { event in
                Text(
                    EventFlag.allCases
                        .filter { event.info.flags.contains($0) }
                        .map { "\($0)" }
                        .joined(separator: ", ")
                )
            }
            .customizationID("flags")
            
            TableColumn("Keyboard Key") { event in
                LabeledRow(label: "\(event.info.keyboardKey ?? 0)", primaryContent: event.info.keyboardKeyString)
            }
            .customizationID("keyboardKey")
        }
        .tableColumnHeaders(.visible)
    }
    
    private var filteredData: [IdentifiedEvent] {
        try! coordinator.events.filter(predicate)
    }
    }
