//
//  MainView.swift
//  SintaKlaus
//
//  Created by Jacob Edwards on 13/11/2024.
//
import SwiftUI

struct MainView: View {
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    
    @State var puzzle: PuzzleE?
    @ObservedObject var puzzleManager: PuzzleManager = PuzzleManager.shared
    @State var isOnNextStep: Bool = false
    @State var enteredNumbers: [Int] = []
    
    
    @State var firstNumber: String = ""
    @State var secondNumber: String = ""
    @State var thirdNumber: String = ""
    
    @State var isPassedPoem: Bool = false
    @State var isComplete: Bool = false
    
    var body: some View {
        VStack {
            if (isPassedPoem) {
                
                if isOnNextStep {
                    if isComplete {
                        Text("Je hebt de cadeau gewonnen!")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding()
                        Text("Ik kan niet denken aan een coole manier om deze cadeau te onthullen, dus maar zeg dat je klaar bent en ik ga deze cadeau halen!")
                    } else {
                        
                        Text("Druk de nummers in om je cadeau te krijgen")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        VStack(spacing: 16) {
                            Text("Eerste puzzle nummer:")
                            TextField("Enter first number", text: $firstNumber)
                                .padding()
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Text("Tweede puzzle nummer:")
                            TextField("Enter second number", text: $secondNumber)
                                .padding()
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Text("Derde puzzle nummer:")
                            TextField("Enter third number", text: $thirdNumber)
                                .padding()
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        .padding()
                        
                        Button("Indienen") {
                            if firstNumber == "43" && secondNumber == "20" && thirdNumber == "3" {
                                isComplete = true
                            }
                        }
                    }
                    
                    Button("Terug") {
                        isOnNextStep = false
                    }
                }
                
                else if puzzle != nil {
                    VStack(spacing: 16) {
                        Text("Vind de beste bewegening!")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        if puzzleManager.finished {
                            Text ("Je hebt de puzzle opgelost!")
                                .font(.headline)
                                .multilineTextAlignment(.center)
                                .padding()
                                .onAppear {
                                    Task {
                                        await dismissImmersiveSpace()
                                    }
                                }
                            
                            let number = getNumberOfPuzzle(puzzle: puzzleManager.puzzle)
                            
                            Text ("Je aanwijzing is het nummer: \(number)")
                        }
                        
                        
                        else if puzzle != .empty {
                            Text("Vind de beste bewegingen om deze puzzle te oplossen")
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .padding()
                                .onAppear {
                                    Task {
                                        await openImmersiveSpace(id: "chess")
                                        
                                    }
                                }
                        } else {
                            Text("Speel maar vrij")
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .padding()
                                .onAppear {
                                    Task {
                                        await openImmersiveSpace(id: "chess")
                                        
                                    }
                                }
                        }
                        
                        Button("Terug") {
                            Task {
                                await dismissImmersiveSpace()
                                puzzle = nil
                            }
                        }
                        .padding()
                    }
                    .padding()
                } else {
                    Text("Jij moet een puzzle kiezen")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button("Eerste puzzle") {
                        PuzzleManager.shared.puzzle = .First
                        puzzle = .First
                        puzzleManager.finished = false
                    }
                    .padding()
                    
                    Button("Tweede Puzzle") {
                        PuzzleManager.shared.puzzle = .Second
                        puzzle = .Second
                        puzzleManager.finished = false
                        
                    }
                    .padding()
                    
                    Button ("Derde puzzle") {
                        PuzzleManager.shared.puzzle = .Third
                        puzzle = .Third
                        puzzleManager.finished = false
                    }
                    .padding()
                    
                    Button ("Vrije speel") {
                        PuzzleManager.shared.puzzle = .empty
                        puzzle = .empty
                        puzzleManager.finished = false
                    }
                    .padding()
                    
                    Text("Los de puzzles op om een aantal nummers te vinden, en als je het helemaal hebt gevonden, klik op de knop 'Volgende'")
                        .padding()
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button ("Volgende") {
                        isOnNextStep = true
                    }
                }
            } else {
                Text("Sinter Klaas")
                    .font(.largeTitle)
                    .padding()
                    
                Text ("Klik op de knop 'Begin' om de puzzle te beginnen")
                    .padding()
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Text("Sinterklaas zat te denken")
                Text("wat hij natasja moet geven")
                Text("toen kwam het hem tegen")
                Text("hij wist dat je van schaak hou")
                Text("als je het leuk vinden zou")
                Text("dus maakte hij een puzzel of drie")
                Text("die jij kan proberen")
                Text("om je cadeau te krijgen!")
                
                Button ("Begin") {
                    isPassedPoem = true
                }
            }
        }
    }
}

//#Preview(windowStyle: .automatic) {
//    MainView()
//}
