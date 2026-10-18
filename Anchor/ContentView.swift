//
//  ContentView.swift
//  Anchor
//
//  Created by IM Student on 2026-10-17.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        AnchorTabView(parkingService: ParkingService(persistenceController: .shared))
    }
}

#Preview {
    ContentView()
}
