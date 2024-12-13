//
//  Chess.swift
//  SintaKlaus
//
//  Created by Jacob Edwards on 30/11/2024.
//

import SwiftUI
import RealityKit
import Foundation


enum ChessPieceType: String {
    case pawn
    case rook
    case knight
    case bishop
    case queen
    case king
}

enum ChessPieceColor: String {
    case white
    case black
}

struct BoardState {
    var selectedPiece: ChessPiece?
    var isWhiteTurn: Bool
    var isGameOver: Bool
    var isCheck: Bool
    var isCheckmate: Bool
    var isStalemate: Bool
    var isDraw: Bool
    var pieces: [ChessPiece]
    var pgn: String
    
}

struct ChessPiece {
    var name: String
    var model: ModelEntity?
    var id: UInt64 = 0
    var position: SIMD3<Float>?
    var initalPosition: SIMD3<Float>?
    var boardPosition: (Int, Int)
    var isAlive: Bool = true
    var colour: ChessPieceColor
    var type: ChessPieceType
}

func toAlgebraicNotation(_ boardPosition: (Int, Int)) -> String {
    let (x, y) = boardPosition
    let files = ["a", "b", "c", "d", "e", "f", "g", "h"]
    let column = files[x]
    let row = String(y + 1)
    return "\(column)\(row)"
}

struct Puzzle {
    let name: PuzzleE
    let initialState: BoardState
    let solutionMoves: [(playerMove: Move, opponentMove:Move?)]
}

struct GameState {
    var boardState: BoardState
    var currentPuzzle: Puzzle?
    var currentStep: Int = 0
}

struct Move {
    let from: (Int, Int)
    let to: (Int, Int)
    var isCapture: Bool = false
    let isEnPassant: Bool = false
    let isPromotion: Bool = false
    let isCastle: Bool = false
     

    let isCheck: Bool = false
    
    
    
    let isValid: Bool = true
    
    func Notation() -> String {
        let fromAlgebraic = toAlgebraicNotation(from)
        let toAlgebraic = toAlgebraicNotation(to)
        
        if isCapture {
            return "\(fromAlgebraic)x\(toAlgebraic)"
        }
        
        return "\(fromAlgebraic)\(toAlgebraic)"
        
    }
}


func bishopCanMove(piece: ChessPiece, board: BoardState, to: (Int, Int)) -> Bool {
    let (x1, y1) = piece.boardPosition
    let (x2, y2) = to
    let pathLengthX = abs(x2 - x1)
    let pathLengthY = abs(y2 - y1)
    
    if pathLengthX != pathLengthY {
        return false
    }
    
    let xDirection = (x2 > x1) ? 1 : -1
        let yDirection = (y2 > y1) ? 1 : -1
        
        // Check each square along the diagonal path, excluding the destination square
        var x = x1 + xDirection
        var y = y1 + yDirection
        while (x != x2) && (y != y2) {
            if board.pieces.contains(where: { $0.boardPosition == (x, y) }) {
                return false // A piece is blocking the path
            }
            x += xDirection
            y += yDirection
        }
        
        // No pieces block the path, so the move is valid
        return true
}

func knightCanMove(piece: ChessPiece, board: BoardState, to: (Int, Int)) -> Bool {
    let (x1, y1) = piece.boardPosition
    let (x2, y2) = to
    
    return abs(x1 - x2) == 1 && abs(y1 - y2) == 2 || abs(x1 - x2) == 2 && abs(y1 - y2) == 1
}

func rookCanMove(piece: ChessPiece, board: BoardState, to: (Int, Int)) -> Bool {
    let (x1, y1) = piece.boardPosition
    let (x2, y2) = to
    
    if x1 != x2 && y1 != y2 {
            return false
    }
    
    let xDirection = x1 == x2 ? 0 : (x2 > x1 ? 1 : -1)
    let yDirection = y1 == y2 ? 0 : (y2 > y1 ? 1 : -1)
    
    var x = x1 + xDirection
    var y = y1 + yDirection
        while x != x2 || y != y2 {
            if board.pieces.contains(where: { $0.boardPosition == (x, y) }) {
                return false
            }
            x += xDirection
            y += yDirection
    }
        
    return true
}

func queenCanMove(piece: ChessPiece, board: BoardState, to: (Int, Int)) -> Bool {
    return bishopCanMove(piece: piece, board: board, to: to) || rookCanMove(piece: piece, board: board, to: to)
}

func kingCanMove(piece: ChessPiece, board: BoardState, to: (Int, Int)) -> Bool {
    let (x1, y1) = piece.boardPosition
    let (x2, y2) = to
    
    let pathLength = abs(x1 - x2)
    let pathLength2 = abs(y1 - y2)
    
    return pathLength <= 1 && pathLength2 <= 1
}

func pawnCanMove(piece: ChessPiece, board: BoardState, to: (Int, Int)) -> Bool {
    let (x1, y1) = piece.boardPosition
        let (x2, y2) = to
        let pathLengthX = abs(x1 - x2)
        let pathLengthY = y2 - y1
        
        let forward = piece.colour == .white ? 1 : -1
        let startingRow = piece.colour == .white ? 1 : 6

        if pathLengthX == 0 && pathLengthY == forward {
            return board.pieces.first(where: { $0.boardPosition == to }) == nil
        }

        if pathLengthX == 0 && pathLengthY == 2 * forward && y1 == startingRow {
            let intermediateSquare = (x1, y1 + forward)
            return board.pieces.first(where: { $0.boardPosition == intermediateSquare }) == nil &&
                   board.pieces.first(where: { $0.boardPosition == to }) == nil
        }

        if pathLengthX == 1 && pathLengthY == forward {
            return board.pieces.contains { $0.boardPosition == to && $0.colour != piece.colour }
        }

        return false
}



func putsInCheck(piece: ChessPiece, state: BoardState, to: (Int, Int)) -> Bool {
    let colour = piece.colour
    
    var simulatedState = state
    
    guard let pieceIndex = simulatedState.pieces.firstIndex(where: { $0.id == piece.id }) else {
        return false
    }
    
    simulatedState.pieces[pieceIndex].boardPosition = to
    
    
    guard let kingPosition = simulatedState.pieces.first(where: { $0.type == .king && $0.colour == colour })?.boardPosition else {
        return false
    }
    
    for opponent in simulatedState.pieces where opponent.colour != colour && opponent.boardPosition != to {
        if canPieceAttack(opponent: opponent, state: simulatedState, to: kingPosition) {
            return true
        }
    }
    
    return false
}


func canPieceAttack(opponent: ChessPiece, state: BoardState, to: (Int, Int)) -> Bool {
    switch opponent.type {
    case .pawn:
        return pawnCanMove(piece: opponent, board: state, to: to)
    case .knight:
        return knightCanMove(piece: opponent, board: state, to: to)
    case .bishop:
        return bishopCanMove(piece: opponent, board: state, to: to)
    case .rook:
        return rookCanMove(piece: opponent, board: state, to: to)
    case .queen:
        return queenCanMove(piece: opponent, board: state, to: to)
    case .king:
        return kingCanMove(piece: opponent, board: state, to: to)
    }
}

func pieceCanMove(piece: ChessPiece, board: BoardState, to: (Int, Int)) -> Bool {
    return canPieceAttack(opponent: piece, state: board, to: to) && !putsInCheck(piece: piece, state: board, to: to) && !board.pieces.contains(where: { $0.boardPosition == to && $0.colour == piece.colour })
}

func isCapture(p: ChessPiece, state: BoardState, to: (Int, Int)) -> Bool {
    return state.pieces.contains(where: { $0.boardPosition == to && p.colour != $0.colour })
}

func initialNormalState () -> BoardState {
    return BoardState(selectedPiece: nil, isWhiteTurn: true, isGameOver: false, isCheck: false, isCheckmate: false, isStalemate: false, isDraw: false, pieces: [
        ChessPiece(name: "whitePawn1", boardPosition: (0, 1), colour: .white, type: .pawn),
        ChessPiece(name: "whitePawn2", boardPosition: (1, 1), colour: .white, type: .pawn),
        ChessPiece(name: "whitePawn3", boardPosition: (2, 1), colour: .white, type: .pawn),
        ChessPiece(name: "whitePawn4", boardPosition: (3, 1), colour: .white, type: .pawn),
        ChessPiece(name: "whitePawn5", boardPosition: (4, 1), colour: .white, type: .pawn),
        ChessPiece(name: "whitePawn6", boardPosition: (5, 1), colour: .white, type: .pawn),
        ChessPiece(name: "whitePawn7", boardPosition: (6, 1), colour: .white, type: .pawn),
        ChessPiece(name: "whitePawn8", boardPosition: (7, 1), colour: .white, type: .pawn),
        ChessPiece(name: "whiteRook1", boardPosition: (0, 0), colour: .white, type: .rook),
        ChessPiece(name: "whiteRook2", boardPosition: (7, 0), colour: .white, type: .rook),
        ChessPiece(name: "whiteKnight1", boardPosition: (1, 0), colour: .white, type: .knight),
        ChessPiece(name: "whiteKnight2", boardPosition: (6, 0), colour: .white, type: .knight),
        ChessPiece(name: "whiteBishop1", boardPosition: (2, 0), colour: .white, type: .bishop),
        ChessPiece(name: "whiteBishop2", boardPosition: (5, 0), colour: .white, type: .bishop),
        ChessPiece(name: "whiteQueen", boardPosition: (3, 0), colour: .white, type: .queen),
        ChessPiece(name: "whiteKing", boardPosition: (4, 0), colour: .white, type: .king),
        ChessPiece(name: "blackPawn1", boardPosition: (0, 6), colour: .black, type: .pawn),
        ChessPiece(name: "blackPawn2", boardPosition: (1, 6), colour:.black, type: .pawn),
        ChessPiece(name: "blackPawn3", boardPosition: (2, 6),colour: .black, type: .pawn),
        ChessPiece(name: "blackPawn4", boardPosition: (3, 6), colour:.black, type: .pawn),
        ChessPiece(name: "blackPawn5", boardPosition: (4, 6), colour:.black, type: .pawn),
        ChessPiece(name: "blackPawn6", boardPosition: (5, 6), colour:.black, type: .pawn),
        ChessPiece(name: "blackPawn7", boardPosition: (6, 6), colour:.black, type: .pawn),
        ChessPiece(name: "blackPawn8", boardPosition: (7, 6), colour:.black, type: .pawn),
        ChessPiece(name: "blackRook1", boardPosition: (0, 7), colour:.black, type: .rook),
        ChessPiece(name: "blackRook2", boardPosition: (7, 7), colour:.black, type: .rook),
        ChessPiece(name: "blackKnight1", boardPosition: (1, 7), colour:.black, type: .knight),
        ChessPiece(name: "blackKnight2", boardPosition: (6, 7), colour:.black, type: .knight),
        ChessPiece(name: "blackBishop1", boardPosition: (2, 7), colour:.black, type: .bishop),
        ChessPiece(name: "blackBishop2", boardPosition: (5, 7), colour:.black, type: .bishop),
        ChessPiece(name: "blackQueen", boardPosition: (3, 7), colour:.black, type: .queen),
        ChessPiece(name: "blackKing", boardPosition: (4, 7), colour:.black, type: .king),
    ], pgn: "")
}

enum NotImplementetError: Error {
    case notImplemented
}

// todo, these arent real puzzles
func predefinedPuzzles() -> [Puzzle] {
    return [
        Puzzle(
            name: .First,
            initialState: BoardState(
                selectedPiece: nil,
                isWhiteTurn: true,
                isGameOver: false,
                isCheck: false,
                isCheckmate: false,
                isStalemate: false,
                isDraw: false,
                pieces: [
                    ChessPiece(name: "whiteKing", boardPosition: (3, 7), colour: .white, type: .king),
                    ChessPiece(name: "blackKing", boardPosition: (3, 5), colour: .black, type: .king),
                    ChessPiece(name: "whiteBishop1", boardPosition: (2, 3), colour: .white, type: .bishop),
                    ChessPiece(name: "blackPawn1", boardPosition: (3, 0), colour: .black, type: .pawn),
                    ChessPiece(name: "whiteQueen", boardPosition: (5, 1), colour: .white, type: .queen),
                    ChessPiece(name: "blackQueen", boardPosition: (6, 6), colour: .black, type: .queen)
                ],
                pgn: ""
            ),
            solutionMoves: [
                (playerMove: Move(from: (5, 1), to: (1, 5)), opponentMove: Move(from: (3, 5), to: (4, 4))),//Move(from: (4, 7), to: (5, 7))),
                (playerMove: Move(from: (1, 5), to: (1, 1)), opponentMove: nil)
            ]
        ),


        Puzzle(
            name: .Second,
            initialState: BoardState(
                selectedPiece: nil,
                isWhiteTurn: true,
                isGameOver: false,
                isCheck: false,
                isCheckmate: false,
                isStalemate: false,
                isDraw: false,
                pieces: [
                    ChessPiece(name: "whiteKing", boardPosition: (5, 7), colour: .white, type: .king),
                    ChessPiece(name: "blackKing", boardPosition: (5, 5), colour: .black, type: .king),
                    ChessPiece(name: "whiteBishop1", boardPosition: (5, 2), colour: .white, type: .bishop),
                    ChessPiece(name: "blackPawn1", boardPosition: (3, 0), colour: .black, type: .pawn),
                    ChessPiece(name: "blackQueen", boardPosition: (5, 1), colour: .black, type: .queen),
                    ChessPiece(name: "whiteQueen", boardPosition: (4, 3), colour: .white, type: .queen)
                ],
                pgn: ""
            ),
            solutionMoves: [
                (playerMove: Move(from: (4, 3), to: (5, 3)), opponentMove: Move(from: (5, 5), to: (4, 5))),
                (playerMove: Move(from: (5, 2), to: (6, 3)), opponentMove: nil)
            ]
        ),
        Puzzle(
            name: .Third,
            initialState: BoardState(
                selectedPiece: nil,
                isWhiteTurn: true,
                isGameOver: false,
                isCheck: false,
                isCheckmate: false,
                isStalemate: false,
                isDraw: false,
                pieces: [
                    ChessPiece(name: "whiteKing", boardPosition: (2, 3), colour: .white, type: .king),
                    ChessPiece(name: "blackKing", boardPosition: (0, 7), colour: .black, type: .king),
                    ChessPiece(name: "whiteBishop1", boardPosition: (4, 1), colour: .white, type: .bishop),
                    ChessPiece(name: "whiteBishop2", boardPosition: (4, 2), colour: .white, type: .bishop),
                    ChessPiece(name: "blackRook1", boardPosition: (3, 5), colour: .black, type: .rook),
                ],
                pgn: ""
            ),
            solutionMoves: [
                (playerMove: Move(from: (4, 1), to: (5, 2)), opponentMove: Move(from: (0, 7), to: (1, 7))),
                (playerMove: Move(from: (4, 2), to: (5, 3)), opponentMove: Move(from: (1, 7), to: (2, 6))),
                (playerMove: Move(from: (2, 3), to: (2, 4)), opponentMove: nil)
            ]
        )
    ]
}

func initState(puzzle: PuzzleE) -> GameState {
    switch puzzle {
    case .empty:
        return GameState(
            boardState: initialNormalState(),
            currentPuzzle: nil,
            currentStep: 0
        )
    default:
        guard let puzzle = predefinedPuzzles().first(where: { $0.name == puzzle }) else {
            fatalError("Puzzle \(puzzle) not found!")
            }
        return GameState(
            boardState: puzzle.initialState,
            currentPuzzle: puzzle,
            currentStep: 0
        )
    }
}

func validateMove(puzzle: Puzzle, currentMoveIndex: Int, attemptedMove: Move) -> Bool {
    guard currentMoveIndex < puzzle.solutionMoves.count else { return false }
    
    let (expectedMove, _) = puzzle.solutionMoves[currentMoveIndex]
    
    return attemptedMove.from == expectedMove.from &&
           attemptedMove.to == expectedMove.to &&
           attemptedMove.isCapture == expectedMove.isCapture
}


