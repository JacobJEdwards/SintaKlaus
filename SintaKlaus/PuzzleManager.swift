//
//  PuzzleManager.swift
//  SintaKlaus
//
//  Created by Jacob Edwards on 30/11/2024.
//

import SwiftUI
    
    
enum PuzzleE : Codable {
    case empty
    case First
    case Second
    case Third
}

func getNumberOfPuzzle(puzzle: PuzzleE) -> Int {
    switch puzzle {
        case .empty: return 0
        case .First: return 43
        case .Second: return 20
        case .Third: return 3
    }
}

class PuzzleManager : ObservableObject {
    static let shared = PuzzleManager()
    
    @Published var puzzle: PuzzleE = .empty
    @Published var finished: Bool = false
}
