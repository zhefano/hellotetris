//
//  GameScene.swift
//  hellotetris
//
//  Created by Noel Blom on 7/19/25.
//

import SpriteKit
import GameplayKit
import SwiftUI
import Observation

// MARK: - Game Types

struct TetriminoBlock {
    let color: Color
    
    init(color: Color) {
        self.color = color
    }
}

struct GameUpdateResult {
    let score: Int
    let linesCleared: Int
    let gameOver: Bool
}

struct PiecePosition {
    var row: Int
    var col: Int
    var rotation: Int
}

// MARK: - Tetrimino Piece

@Observable
class TetriminoPiece: Sendable {
    let shape: [[Bool]]
    let color: Color
    let rotationStates: [[[Bool]]]
    
    init(shape: [[Bool]], color: Color, rotationStates: [[[Bool]]]) {
        self.shape = shape
        self.color = color
        self.rotationStates = rotationStates
    }

    func rotate() async {
        // Basic rotation feedback - can be enhanced with HapticEngine later
        print("Piece rotated")
    }

    static let allTypes: [TetriminoPiece] = [
        // I-piece
        TetriminoPiece(
            shape: [[true, true, true, true]],
            color: .cyan,
            rotationStates: [
                [[true, true, true, true]],
                [[true], [true], [true], [true]]
            ]
        ),
        // J-piece
        TetriminoPiece(
            shape: [[true, false, false],
                    [true, true, true]],
            color: .blue,
            rotationStates: [
                [[true, false, false],
                 [true, true, true]],
                [[true, true],
                 [true, false],
                 [true, false]],
                [[true, true, true],
                 [false, false, true]],
                [[false, true],
                 [false, true],
                 [true, true]]
            ]
        ),
        // L-piece
        TetriminoPiece(
            shape: [[false, false, true],
                    [true, true, true]],
            color: .orange,
            rotationStates: [
                [[false, false, true],
                 [true, true, true]],
                [[true, false],
                 [true, false],
                 [true, true]],
                [[true, true, true],
                 [true, false, false]],
                [[true, true],
                 [false, true],
                 [false, true]]
            ]
        ),
        // O-piece
        TetriminoPiece(
            shape: [[true, true],
                    [true, true]],
            color: .yellow,
            rotationStates: [
                [[true, true],
                 [true, true]]
            ]
        ),
        // S-piece
        TetriminoPiece(
            shape: [[false, true, true],
                    [true, true, false]],
            color: .green,
            rotationStates: [
                [[false, true, true],
                 [true, true, false]],
                [[true, false],
                 [true, true],
                 [false, true]]
            ]
        ),
        // T-piece
        TetriminoPiece(
            shape: [[false, true, false],
                    [true, true, true]],
            color: .purple,
            rotationStates: [
                [[false, true, false],
                 [true, true, true]],
                [[true, false],
                 [true, true],
                 [true, false]],
                [[true, true, true],
                 [false, true, false]],
                [[false, true],
                 [true, true],
                 [false, true]]
            ]
        ),
        // Z-piece
        TetriminoPiece(
            shape: [[true, true, false],
                    [false, true, true]],
            color: .red,
            rotationStates: [
                [[true, true, false],
                 [false, true, true]],
                [[false, true],
                 [true, true],
                 [true, false]]
            ]
        )
    ]
}

// MARK: - Game Engine

actor GameEngine {
    var gameBoard: GameBoard
    private var currentPiece: TetriminoPiece?
    private var currentPosition: PiecePosition?
    private var score: Int = 0
    private var gameOver: Bool = false
    private var dropTimer: TimeInterval = 0
    private let dropInterval: TimeInterval = 1.0 // 1 second per drop
    
    // Make these accessible for rendering
    var currentPieceForRendering: TetriminoPiece? { get { currentPiece } }
    var currentPositionForRendering: PiecePosition? { get { currentPosition } }
    
    init(rows: Int, columns: Int) {
        self.gameBoard = GameBoard(rows: rows, columns: columns)
    }
    

    
    func startGame() async {
        gameOver = false
        score = 0
        await spawnNewPiece()
    }
    
    func spawnNewPiece() async {
        currentPiece = await MainActor.run { TetriminoPiece.allTypes.randomElement() }
        currentPosition = PiecePosition(row: 0, col: 3, rotation: 0)
        
        // Check if game is over (piece can't be placed)
        if let piece = currentPiece, let position = currentPosition {
            let isValid = await gameBoard.isPositionValid(piece: piece, at: position)
            if !isValid {
                gameOver = true
            }
        }
    }
    
    func movePieceLeft() async {
        guard let piece = currentPiece, let position = currentPosition else { return }
        let newPosition = PiecePosition(row: position.row, col: position.col - 1, rotation: position.rotation)
        let isValid = await gameBoard.isPositionValid(piece: piece, at: newPosition)
        if isValid {
            currentPosition = newPosition
        }
    }
    
    func movePieceRight() async {
        guard let piece = currentPiece, let position = currentPosition else { return }
        let newPosition = PiecePosition(row: position.row, col: position.col + 1, rotation: position.rotation)
        let isValid = await gameBoard.isPositionValid(piece: piece, at: newPosition)
        if isValid {
            currentPosition = newPosition
        }
    }
    
    func rotatePiece() async {
        guard let piece = currentPiece, let position = currentPosition else { return }
        let newRotation = (position.rotation + 1) % piece.rotationStates.count
        let newPosition = PiecePosition(row: position.row, col: position.col, rotation: newRotation)
        let isValid = await gameBoard.isPositionValid(piece: piece, at: newPosition)
        if isValid {
            currentPosition = newPosition
        }
    }
    
    func dropPiece() async {
        guard let piece = currentPiece, let position = currentPosition else { return }
        let newPosition = PiecePosition(row: position.row + 1, col: position.col, rotation: position.rotation)
        let isValid = await gameBoard.isPositionValid(piece: piece, at: newPosition)
        if isValid {
            currentPosition = newPosition
        } else {
            // Lock piece in place
            await gameBoard.add(piece: piece, at: position)
            let linesCleared = await gameBoard.clearLines()
            score += linesCleared * 100
            await spawnNewPiece()
        }
    }
    
    // Swift 6.2 enhanced structured concurrency
    func updateGame(deltaTime: TimeInterval) async -> GameUpdateResult {
        dropTimer += deltaTime
        
        if dropTimer >= dropInterval {
            dropTimer = 0
            await dropPiece()
        }
        
        return GameUpdateResult(score: score, linesCleared: 0, gameOver: gameOver)
    }
}

// MARK: - Game Scene

class GameScene: SKScene {
    var gameEngine: GameEngine
    private var lastUpdateTime: TimeInterval = 0
    private let blockSize: CGFloat = 30.0 // Larger blocks for better visibility
    
    // UI Elements
    private var scoreLabel: SKLabelNode?
    private var gameOverLabel: SKLabelNode?

    init(size: CGSize, gameEngine: GameEngine) {
        self.gameEngine = gameEngine
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        setupScene()
        setupUI()
        
        // Start the game
        Task {
            await gameEngine.startGame()
        }
    }
    
    private func setupScene() {
        backgroundColor = SKColor.black
        
        // Add grid lines for better visibility
        drawGrid()
    }
    
    private func setupUI() {
        // Score label
        scoreLabel = SKLabelNode(fontNamed: "Arial-Bold")
        scoreLabel?.text = "Score: 0"
        scoreLabel?.fontSize = 24
        scoreLabel?.fontColor = SKColor.white
        scoreLabel?.position = CGPoint(x: size.width - 100, y: size.height - 50)
        addChild(scoreLabel!)
        
        // Game over label (hidden initially)
        gameOverLabel = SKLabelNode(fontNamed: "Arial-Bold")
        gameOverLabel?.text = "GAME OVER"
        gameOverLabel?.fontSize = 48
        gameOverLabel?.fontColor = SKColor.red
        gameOverLabel?.position = CGPoint(x: size.width / 2, y: size.height / 2)
        gameOverLabel?.isHidden = true
        addChild(gameOverLabel!)
    }
    
    private func drawGrid() {
        // Draw vertical lines
        for col in 0...10 {
            let x = CGFloat(col) * blockSize
            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: CGFloat(22) * blockSize))
            line.path = path
            line.strokeColor = SKColor.darkGray
            line.lineWidth = 1
            addChild(line)
        }
        
        // Draw horizontal lines
        for row in 0...22 {
            let y = CGFloat(row) * blockSize
            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: CGFloat(10) * blockSize, y: y))
            line.path = path
            line.strokeColor = SKColor.darkGray
            line.lineWidth = 1
            addChild(line)
        }
    }

    override func update(_ currentTime: TimeInterval) {
        if (self.lastUpdateTime == 0) {
            self.lastUpdateTime = currentTime
        }

        let dt = currentTime - self.lastUpdateTime

        // Update game engine
        Task {
            let result = await gameEngine.updateGame(deltaTime: dt)
            self.updateUI(result: result)
            await self.drawGameBoard()
        }

        self.lastUpdateTime = currentTime
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Simple touch controls
        if location.x < size.width / 3 {
            Task { await gameEngine.movePieceLeft() }
        } else if location.x > size.width * 2 / 3 {
            Task { await gameEngine.movePieceRight() }
        } else {
            Task { await gameEngine.rotatePiece() }
        }
    }

    private func updateUI(result: GameUpdateResult) {
        scoreLabel?.text = "Score: \(result.score)"
        
        if result.gameOver {
            gameOverLabel?.isHidden = false
        }
    }

    @MainActor private func drawGameBoard() async {
        // Remove existing blocks from the scene
        children.filter { $0.name == "tetrisBlock" }.forEach { $0.removeFromParent() }

        let board = await gameEngine.gameBoard

        // Draw placed blocks
        for row in 0..<board.rows {
            for col in 0..<board.columns {
                if let block = board.grid[row][col] {
                    let x = CGFloat(col) * blockSize + blockSize / 2
                    let y = CGFloat(board.rows - 1 - row) * blockSize + blockSize / 2
                    let sprite = SKShapeNode(rectOf: CGSize(width: blockSize - 2, height: blockSize - 2), cornerRadius: 2)
                    sprite.fillColor = SKColor(block.color)
                    sprite.strokeColor = SKColor.white
                    sprite.lineWidth = 1
                    sprite.position = CGPoint(x: x, y: y)
                    sprite.name = "tetrisBlock"
                    addChild(sprite)
                }
            }
        }
        
        // Draw current piece
        if let currentPiece = await gameEngine.currentPieceForRendering,
           let currentPosition = await gameEngine.currentPositionForRendering {
            let shape = currentPiece.rotationStates[currentPosition.rotation]
            for (row, shapeRow) in shape.enumerated() {
                for (col, isFilled) in shapeRow.enumerated() {
                    if isFilled {
                        let x = CGFloat(currentPosition.col + col) * blockSize + blockSize / 2
                        let y = CGFloat(board.rows - 1 - (currentPosition.row + row)) * blockSize + blockSize / 2
                        let sprite = SKShapeNode(rectOf: CGSize(width: blockSize - 2, height: blockSize - 2), cornerRadius: 2)
                        sprite.fillColor = SKColor(currentPiece.color)
                        sprite.strokeColor = SKColor.white
                        sprite.lineWidth = 1
                        sprite.alpha = 0.8 // Make current piece slightly transparent
                        sprite.position = CGPoint(x: x, y: y)
                        sprite.name = "tetrisBlock"
                        addChild(sprite)
                    }
                }
            }
        }
    }
}

// MARK: - SwiftUI Integration (Optional)

struct TetrisGameView: View {
    @State private var gameEngine = GameEngine(rows: 22, columns: 10)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Game board with enhanced rendering
                SpriteView(scene: createGameScene(size: geometry.size, gameEngine: gameEngine))
                    .ignoresSafeArea()
            }
        }
    }
    
    private func createGameScene(size: CGSize, gameEngine: GameEngine) -> SKScene {
        let scene = GameScene(size: size, gameEngine: gameEngine)
        scene.scaleMode = .resizeFill
        return scene
    }
}
