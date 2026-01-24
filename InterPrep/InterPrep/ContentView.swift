//
//  ContentView.swift
//  InterPrep
//
//  Created by Наталья Захарова on 21.01.2026.
//

import SwiftUI

struct ContentView: View {
    let appGraph = AppGraph()
    
    var body: some View {
        MainTabView(appGraph: appGraph)
    }
}

#Preview {
    ContentView()
}
