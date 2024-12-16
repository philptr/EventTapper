//
//  Coordinator.swift
//  EventTapper
//
//  Created by Phil Zakharchenko on 12/14/24.
//

import Foundation
import Observation
import EventTapCore
import ObservableUserDefault
import CoreGraphics

@Observable @MainActor
final class Coordinator {
    var tapLocation: TapLocation {
        get { .init(rawValue: _tapLocation)! }
        set { _tapLocation = newValue.rawValue }
    }
    
    var tapPlacement: TapPlacement {
        get { .init(rawValue: _tapPlacement)! }
        set { _tapPlacement = newValue.rawValue }
    }
    
    var throttleDurationMilliseconds: Int {
        get { _throttleDurationMilliseconds }
        set { _throttleDurationMilliseconds = newValue }
    }
    
    var hasListenEventAccess: Bool = false
    
    @ObservableUserDefault(.init(key: "tapLocation", defaultValue: TapLocation.session.rawValue, store: .standard))
    @ObservationIgnored
    private var _tapLocation: TapLocation.RawValue
    
    @ObservableUserDefault(.init(key: "tapPlacement", defaultValue: TapPlacement.head.rawValue, store: .standard))
    @ObservationIgnored
    private var _tapPlacement: TapPlacement.RawValue
    
    @ObservableUserDefault(.init(key: "throttleDurationMilliseconds", defaultValue: 500, store: .standard))
    @ObservationIgnored
    private var _throttleDurationMilliseconds: Int
    
    init() {
        fetchListenEventAccess()
    }
    
    func fetchListenEventAccess() {
        hasListenEventAccess = CGPreflightListenEventAccess()
    }
}
