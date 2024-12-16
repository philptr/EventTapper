//
//  LabeledRow.swift
//  EventTapper
//
//  Created by Phil Zakharchenko on 3/31/24.
//

import SwiftUI

struct LabeledRow: View {
    let label: String
    let primaryContent: String?
    
    var body: some View {
        if let primaryContent {
            HStack(alignment: .firstTextBaseline) {
                Text(label)
                    .foregroundStyle(.secondary)
                
                Text(primaryContent)
            }
        } else {
            Text("None")
                .foregroundStyle(.tertiary)
        }
    }
}
