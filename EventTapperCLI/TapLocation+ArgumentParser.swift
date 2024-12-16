//
//  TapLocation+ArgumentParser.swift
//  EventTapperCLI
//
//  Created by Phil Zakharchenko on 12/14/24.
//

import ArgumentParser
import EventTapCore

extension TapLocation: @retroactive ExpressibleByArgument {
    public init?(argument: String) {
        self.init(rawValue: argument.lowercased())
    }
    
    public static var allValueStrings: [String] {
        allCases.map(\.rawValue)
    }
}
