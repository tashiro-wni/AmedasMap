//
//  AmedasMapApp.swift
//  AmedasMap
//
//  Created by tasshy on 2021/02/28.
//

import SwiftUI

@main
struct AmedasMapApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AmedasMapViewModel())
        }
    }
}
