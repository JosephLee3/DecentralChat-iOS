//
//  ContentView.swift
//  DecentralChat
//
//  Created by Joseph Lee on 5/15/26.
//

import SwiftUI

struct ContentView: View {
    let container: AppContainer

    init(container: AppContainer = .shared) {
        self.container = container
    }

    var body: some View {
        ContactListView(container: container)
    }
}

#Preview {
    ContentView()
}
