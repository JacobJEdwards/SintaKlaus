//
//  ChessView.swift
//  SintaKlaus
//
//  Created by Jacob Edwards on 13/11/2024.
//

import SwiftUI
import RealityKit
import Foundation

func getPieceModelName(_ pieceType: ChessPieceType, _ pieceColor: ChessPieceColor) -> String {
    return "\(pieceType.rawValue)_\(pieceColor.rawValue)"
}

func getPieceModel(_ pieceType: ChessPieceType, _ pieceColor: ChessPieceColor) -> ModelEntity? {
    let pieceModelName: String = getPieceModelName(pieceType, pieceColor)
    
    guard let pieceModel = try? ModelEntity.loadModel(named: pieceModelName) else {
        assertionFailure("Failed to load model:\(pieceModelName)")
        return nil
    }
    
    return pieceModel
}


struct ChessView: View {
    /// The initial scale of the entity.
    @ObservedObject var puzzleManager: PuzzleManager = PuzzleManager.shared
    
    @State var initialPosition: SIMD3<Float>? = nil
    @State var state: GameState = initState(puzzle: PuzzleManager.shared.puzzle)
    
    @State var board: ModelEntity?
    let sensitivity: Double = 1.5

    let boardName: String = "board"
    let boardScale: Float = 0.000009
    
    var translationGesture: some Gesture {
        /// The gesture to move an entity.
        DragGesture()
            .targetedToAnyEntity()
            .onChanged({ value in
                /// The entity that the drag gesture targets.
                let rootEntity = value.entity

                if initialPosition == nil {
                    initialPosition = rootEntity.position
                }

                /// The movement that converts a global world space to the scene world space of the entity.
                let movement = value.convert(value.translation3D * sensitivity, from: .global, to: .scene)

                rootEntity.position = (initialPosition ?? .zero) + movement.grounded
            })
            .onEnded({ value in
                defer {
                    initialPosition = nil
                }
                let rootEntity = value.entity
                
                guard let i = state.boardState.pieces.firstIndex(where: { $0.model == rootEntity }) else {
                                print("Piece with id \(rootEntity.id) not found.")
                                return
                            }
                
                if !(state.boardState.pieces[i].colour == (state.boardState.isWhiteTurn ? .white : .black)) {
                    rootEntity.position = state.boardState.pieces[i].position ?? rootEntity.position
                    return
                }
                        
                let newPos = calculateBoardPosition(position: rootEntity.position)
                let oldPos = state.boardState.pieces[i].boardPosition
                var move = Move(from: oldPos, to: newPos)
                
                if state.currentPuzzle == nil {
                    if !pieceCanMove(piece: state.boardState.pieces[i], board: state.boardState, to: newPos) {
                        rootEntity.position = state.boardState.pieces[i].position ?? rootEntity.position
                        return
                    }
                } else {
                    if !validateMove(puzzle: state.currentPuzzle!, currentMoveIndex: state.currentStep, attemptedMove: move) {
                        rootEntity.position = state.boardState.pieces[i].position ?? rootEntity.position
                        return
                    }
                }
                
       
                
                state.boardState.pieces[i].position = rootEntity.position
                state.boardState.pieces[i].boardPosition = newPos
                            
                let pos = calcPiecePosition(piece: state.boardState.pieces[i].boardPosition)
                state.boardState.pieces[i].position = pos
                rootEntity.position = pos
                
                if (isCapture(p: state.boardState.pieces[i], state: state.boardState, to: newPos)) {
                    let capture = state.boardState.pieces.firstIndex(where: { $0.boardPosition == newPos && $0.colour != state.boardState.pieces[i].colour})!
                    
                    // hide model or delete
                    state.boardState.pieces[capture].model?.removeFromParent()
                    state.boardState.pieces[capture].model = nil
                    state.boardState.pieces.remove(at: capture)
                    
                    move.isCapture = true
                    
                } else {
                    move.isCapture = false
                   
                }
                let notatedMove = move.Notation()
                state.boardState.pgn.append(notatedMove + " ")

                state.boardState.isWhiteTurn.toggle()
                
                if let currentPuzzle = state.currentPuzzle {
                    let (_, opponentMove) = currentPuzzle.solutionMoves[state.currentStep]
                    
                    guard let opponentMove = opponentMove else {
                        state.boardState.isGameOver = true
                        puzzleManager.finished = true
                        return
                    }
                    
                    let from = opponentMove.from
                    let to = opponentMove.to
                    
                    guard let opponentPieceIndex = state.boardState.pieces.firstIndex(where: { $0.boardPosition == from }) else {
                                print("Opponent's piece not found at \(from).")
                                return
                            }
                    
                    var opponentPiece = state.boardState.pieces[opponentPieceIndex]
                    
                    if let capturedIndex = state.boardState.pieces.firstIndex(where: { $0.boardPosition == to && $0.colour != opponentPiece.colour }) {
                                state.boardState.pieces[capturedIndex].model?.removeFromParent()
                                state.boardState.pieces[capturedIndex].model = nil
                                state.boardState.pieces.remove(at: capturedIndex)
                            }
                    
                    opponentPiece.boardPosition = to
                    opponentPiece.position = calcPiecePosition(piece: to)
                    opponentPiece.model?.position = calcPiecePosition(piece: to)
                    state.boardState.pieces[opponentPieceIndex] = opponentPiece
                    
                    let opponentNotatedMove = opponentMove.Notation()
                            state.boardState.pgn.append(opponentNotatedMove + " ")

                            // Update game state
                            state.boardState.isWhiteTurn.toggle()
                    
                    
                }
                
                state.currentStep += 1
            })
    }
    
    var body: some View {
        RealityView { content in
            state = initState(puzzle: puzzleManager.puzzle)
            
            board = try! await ModelEntity(named: boardName)
            
            guard let board else { return }
            
            board.scale = .init(repeating: boardScale)
            let bounds = board.visualBounds(relativeTo: nil)
            
            let boardWidth: Float = (board.model?.mesh.bounds.max.x)!
            
            let boardHeight: Float = (board.model?.mesh.bounds.max.y)!
            
            let boardDepth: Float = (board.model?.mesh.bounds.max.z)!
            
            let boxShape = ShapeResource.generateBox(width: boardWidth, height: boardHeight, depth: boardDepth)
            
            board.components.set(CollisionComponent(shapes: [boxShape]))
            
            board.position.y = 0
            
            board.position.z += bounds.min.z
            // centre it
            board.position.x += bounds.min.x
            
            content.add(board)
            
            for i in 0...state.boardState.pieces.count-1 {
                guard let pieceModel = getPieceModel(state.boardState.pieces[i].type, state.boardState.pieces[i].colour) else {
                    assertionFailure("Failed to load model")
                    return
                }
                
                state.boardState.pieces[i].model = pieceModel
                
                pieceModel.scale = .init(repeating: 0.0005)
                
                let boardWidth: Float = (pieceModel.model?.mesh.bounds.max.x)!
                
                let boardHeight: Float = (pieceModel.model?.mesh.bounds.max.y)!
                
                let boardDepth: Float = (pieceModel.model?.mesh.bounds.max.z)!
                
                let boxShape = ShapeResource.generateBox(width: boardWidth, height: boardHeight, depth: boardDepth)
                
                pieceModel.components.set(CollisionComponent(shapes: [boxShape]))
                
                pieceModel.components.set(InputTargetComponent())
                
                pieceModel.position = calcPiecePosition(piece: state.boardState.pieces[i].boardPosition)
               
                pieceModel.components.set(InputTargetComponent())
                pieceModel.components.set(HoverEffectComponent())
                
                state.boardState.pieces[i].id = pieceModel.id
                state.boardState.pieces[i].position = pieceModel.position
                
                content.add(pieceModel)
            }
         
        }
        .gesture(translationGesture)
    }
    
    func calcPiecePosition(piece: (Int, Int)) -> SIMD3<Float> {
        guard let board else { return .zero }
        
            let numTilesX = 8
            let numTilesZ = 8
            
            // Calculate width and height of each tile
        let tileWidth: Float = (board.model?.mesh.bounds.max.x ?? 0) * boardScale / Float(numTilesX)
        let tileDepth: Float = (board.model?.mesh.bounds.max.z ?? 0) * boardScale / Float(numTilesZ)
            
            // Calculate the relative position on the board
            let posXRel = (Float(piece.0) - Float(numTilesX - 1) / 2) * tileWidth
            let posZRel = (Float(piece.1) - Float(numTilesZ - 1) / 2) * tileDepth
        let posY: Float = -0.02  // Fixed height for all pieces
            
            // Apply these positions to place the piece on the board
            let posX = board.position.x + posXRel * 2
            let posZ = board.position.z + posZRel * 2
            
            return SIMD3(x: posX, y: posY, z: posZ)
    }
    
    func calculateBoardPosition(position: SIMD3<Float>) -> (Int, Int) {
        let numTilesX = 8
        let numTilesZ = 8
        
        // Calculate the width and depth of each tile based on the board dimensions
        var possibleCoords: Dictionary<SIMD2<Float>, (Int, Int)> = [:]
        
        for x in 0..<numTilesX {
            for z in 0..<numTilesZ {
                let coord = calcPiecePosition(piece: (x, z))
                let xy = SIMD2<Float>(coord.x, coord.z)
                possibleCoords[xy] = (x, z)
            }
        }
        
        var closestCoord: (Float, (Int, Int))?
        
        let posAs2 = SIMD2<Float>(position.x, position.z)
        for (xy, coord) in possibleCoords {
            let dist = distance(posAs2, xy)
            if closestCoord == nil || dist < closestCoord!.0 {
                closestCoord = (dist, coord)
            }
            
        }
        
        return closestCoord!.1
        
    }

    
}
