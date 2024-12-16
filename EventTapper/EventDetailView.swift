//
//  EventDetailView.swift
//  EventTapper
//
//  Created by Phil Zakharchenko on 2/23/24.
//

import SwiftUI
import EventTapCore

struct EventDetailView: View {
    enum Section {
        case fields
    }
    
    struct Row: Identifiable {
        let id = UUID()
        let key: DataCell
        let value: DataCell
        let type: String
    }
    
    var event: IdentifiedEvent
    @Binding var sectionVisibility: Set<Section>
    @Binding var pinnedEvent: IdentifiedEvent?
    @Binding var selectedEventIDs: Set<IdentifiedEvent.ID>
    
    @State private var selectedRowIDs: Set<Row.ID> = []
    
    var body: some View {
        Form {
            HStack {
                Button(isPinned ? "Unpin" : "Pin", systemImage: isPinned ? "pin.fill" : "pin") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if isPinned {
                            pinnedEvent = nil
                        } else {
                            pinnedEvent = event
                        }
                    }
                }
                
                Button("Deselect", systemImage: "xmark") {
                    selectedEventIDs.remove(event.id)
                }
            }
            .buttonStyle(.accessoryBar)
            .fontWeight(.medium)
            .labelsHidden()
            .foregroundStyle(.secondary)
            
            LabeledContent("Date") {
                Text(event.info.date.formatted(.iso8601))
            }
            
            LabeledContent("Timestamp") {
                Text("\(event.info.rawTimestamp)")
            }
            
            LabeledContent("Event Type") {
                DataCellView(cell: DataCell(event.info.type))
            }
            
            DisclosureGroup(
                isExpanded: isSectionExpanded(.fields),
                content: { EmptyView() },
                label: { Text("Fields") }
            )
            
            if sectionVisibility.contains(.fields) {
                Table(rows, selection: $selectedRowIDs) {
                    TableColumn("Key") { row in
                        DataCellView(cell: row.key)
                    }
                    
                    TableColumn("Value") { row in
                        DataCellView(cell: row.value)
                    }
                    
                    TableColumn("Type") { row in
                        Text(row.type)
                    }
                }
            }
        }
        .formStyle(.grouped)
//        .frame(maxHeight: .infinity, alignment: .top)
        .fixedSize()
    }
    
    private func isSectionExpanded(_ section: Section) -> Binding<Bool> {
        Binding(get: {
            sectionVisibility.contains(section)
        }, set: { newValue in
            withAnimation {
                if newValue {
                    sectionVisibility.insert(section)
                } else {
                    sectionVisibility.remove(section)
                }
            }
        })
    }
    
    private var rows: [Row] {
        var rows: [Row] = []
        
        rows += event.info.intFields.map { field in
            Row(key: .init(field.key), value: .init(rawValue: field.value), type: "Integer Field")
        }
        
        rows += event.info.doubleFields.map { field in
            Row(key: .init(field.key), value: .init(rawValue: field.value), type: "Double Field")
        }
        
        return rows
    }
    
    private var isPinned: Bool {
        pinnedEvent?.id == event.id
    }
}
