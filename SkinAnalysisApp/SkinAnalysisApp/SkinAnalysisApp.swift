//
//  SkinAnalysisAppApp.swift
//  SkinAnalysisApp
//
//  Created by 김동현 on 6/26/24.
//
import SwiftUI

@main
struct SkinAnalysisApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(ContentViewModel())
        }
    }
}
