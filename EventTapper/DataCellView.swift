//
//  DataCellView.swift
//  EventTapper
//
//  Created by Phil Zakharchenko on 2/23/24.
//

import SwiftUI
import EventTapCore

struct DataCell {
    let rawValue: CustomStringConvertible
    let metadata: FieldMetadata?
    
    init<T: EventInfoKey>(_ key: T) {
        rawValue = key.rawValue
        metadata = key.metadata
    }
    
    init(rawValue: CustomStringConvertible, metadata: FieldMetadata? = nil) {
        self.rawValue = rawValue
        self.metadata = metadata
    }
}

struct DataCellView: View {
    let cell: DataCell
    var alignment: Alignment = .leading
    
    var body: some View {
        content.help(helpString)
    }
    
    @ViewBuilder
    private var content: some View {
        if let metadata = cell.metadata {
            LabeledRow(label: cell.rawValue.description, primaryContent: metadata.label)
        } else {
            Text(cell.rawValue.description)
        }
    }
    
    private var helpString: String {
        guard let metadata = cell.metadata else { return "" }
        return metadata.description
    }
}
