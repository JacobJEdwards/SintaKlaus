//
//  SintaKlausApp.swift
//  SintaKlaus
//
//  Created by Jacob Edwards on 13/11/2024.
//

import SwiftUI

@main
struct SintaKlausApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
        }
        
        ImmersiveSpace(id: "chess") {
            ChessView()
        }
    }
}
