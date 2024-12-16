//
//  ContentView.swift
//  EventTapper
//
//  Created by Phil Zakharchenko on 1/11/24.
//

import SwiftUI
import PredicateView
import EventTapCore

struct ContentView: View {
    @Environment(EventTapCoordinator.self) var eventCoordinator
    @Environment(Coordinator.self) var coordinator
    
    @State private var selectedEventIDs: Set<IdentifiedEvent.ID> = []
    @State private var pinnedEvent: IdentifiedEvent?
    @State private var sectionVisibility: Set<EventDetailView.Section> = [.fields]
    @State private var predicate: Predicate<IdentifiedEvent> = .true
    @State private var firstViewScrollPosition: ScrollPosition = .init()
    @State private var secondViewScrollPosition: ScrollPosition = .init()
    
    var body: some View {
        VSplitView {
            FilteredTableView(
                coordinator: eventCoordinator,
                predicate: $predicate,
                selectedEventIDs: $selectedEventIDs
            )
            .safeAreaInset(edge: .bottom) {
                ScrollView(.horizontal) {
                    PredicateView(predicate: $predicate, rowTemplates: [
                        .init(keyPath: \.info.type.rawValue, title: "Type ID"),
                        .init(keyPath: \.info.keyboardKeyString, title: "Keyboard Key"),
                        .init(keyPath: \.info.intFields, title: "Integer Fields", rowTemplates: [
                            .init(keyPath: \.key.rawValue, title: "Key"),
                            .init(keyPath: \.value, title: "Value"),
                        ])
                    ])
                    .padding(.vertical, 4)
                    .padding(.horizontal)
                }
                .background(.thinMaterial)
            }
            
            HSplitView {
                if let pinnedEvent {
                    ScrollView(.vertical) {
                        EventDetailView(
                            event: pinnedEvent,
                            sectionVisibility: $sectionVisibility,
                            pinnedEvent: $pinnedEvent,
                            selectedEventIDs: $selectedEventIDs
                        )
                        .backgroundStyle(.windowBackground)
                    }
                    .scrollPosition($firstViewScrollPosition)
                    .onScrollGeometryChange(for: CGFloat.self) { geometry in
                        geometry.contentOffset.y
                    } action: { oldValue, newValue in
                        guard oldValue != newValue else { return }
                        secondViewScrollPosition.scrollTo(y: newValue)
                    }
                }
                
                ScrollView([.horizontal, .vertical]) {
                    if selectedEvents.isEmpty {
                        ContentUnavailableView("No events selected", image: "")
                    } else {
                        LazyHStack(alignment: .top) {
                            ForEach(selectedEvents) { event in
                                EventDetailView(event: event, sectionVisibility: $sectionVisibility, pinnedEvent: $pinnedEvent, selectedEventIDs: $selectedEventIDs)
                            }
                        }
                    }
                }
                .scrollPosition($secondViewScrollPosition)
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y
                } action: { oldValue, newValue in
                    guard oldValue != newValue else { return }
                    firstViewScrollPosition.scrollTo(y: newValue)
                }
            }
            .frame(minHeight: 110)
        }
        .onNotification(named: NSWindow.didBecomeKeyNotification) {
            coordinator.fetchListenEventAccess()
        }
        .toolbar {
            if !coordinator.hasListenEventAccess {
                Button {
                    CGRequestListenEventAccess()
                    guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") else { return }
                    NSWorkspace.shared.open(url)
                } label: {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                        Text("Grant Access")
                    }
                }
                .help("Monitoring events in other applications requires the Input Monitoring permission. Click here to open System Settings.")
            } else {
                Button("Clear", systemImage: "trash") {
                    selectedEventIDs.removeAll()
                    pinnedEvent = nil
                    eventCoordinator.reset()
                }
                .disabled(eventCoordinator.isEmpty)
                
                Button(eventCoordinator.isMonitoring ? "Stop" : "Start", systemImage: eventCoordinator.isMonitoring ? "stop.fill" : "play.fill") {
                    if eventCoordinator.isMonitoring {
                        eventCoordinator.stopMonitoring()
                    } else {
                        eventCoordinator.startMonitoring(
                            tapLocation: coordinator.tapLocation,
                            tapPlacement: coordinator.tapPlacement,
                            throttledFor: .milliseconds(coordinator.throttleDurationMilliseconds)
                        )
                    }
                }
            }
        }
    }
    
    private var selectedEvents: [IdentifiedEvent] {
        selectedEventIDs
            .subtracting(pinnedEvent != nil ? [pinnedEvent!.id] : [])
            .map { eventCoordinator.events[$0] }
            .sorted(using: KeyPathComparator(\IdentifiedEvent.info.date, order: .forward))
    }
}
