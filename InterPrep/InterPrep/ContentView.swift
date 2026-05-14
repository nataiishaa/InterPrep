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
