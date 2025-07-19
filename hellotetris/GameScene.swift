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

// MARK: - Swift 6.2 Enhanced Features

// Raw identifiers for better test naming (SE-0451)
enum GameEvent: String {
    case `piece-moved` = "Piece moved"
    case `line-cleared` = "Line cleared"
    case `game-over` = "Game over"
    case `score-updated` = "Score updated"
}

// Swift 6.2: Enhanced string interpolation
extension String {
    func gameStatus(_ score: Int?) -> String {
        return "Score: \(score ?? 0)"
    }
}

// MARK: - iOS 26 Liquid Glass UI Components

struct LiquidGlassStyle {
    let depth: CGFloat
    let segments: Int
    let radius: CGFloat
    let transmission: CGFloat
    let roughness: CGFloat
    let reflectivity: CGFloat
    let ior: CGFloat
    let thickness: CGFloat
    
    static let modern = LiquidGlassStyle(
        depth: 0.8,
        segments: 64,
        radius: 0.3,
        transmission: 0.95,
        roughness: 0.05,
        reflectivity: 0.5,
        ior: 1.5,
        thickness: 0.5
    )
    
    static let subtle = LiquidGlassStyle(
        depth: 0.3,
        segments: 32,
        radius: 0.2,
        transmission: 0.9,
        roughness: 0.1,
        reflectivity: 0.3,
        ior: 1.3,
        thickness: 0.3
    )
}

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
        // iOS 26 haptic feedback integration
        await HapticEngine.shared.playRotationFeedback()
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
    
    init(rows: Int, columns: Int) async {
        self.gameBoard = await GameBoard(rows: rows, columns: columns)
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
            await HapticEngine.shared.playMoveFeedback()
        }
    }
    
    func movePieceRight() async {
        guard let piece = currentPiece, let position = currentPosition else { return }
        let newPosition = PiecePosition(row: position.row, col: position.col + 1, rotation: position.rotation)
        let isValid = await gameBoard.isPositionValid(piece: piece, at: newPosition)
        if isValid {
            currentPosition = newPosition
            await HapticEngine.shared.playMoveFeedback()
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
    
    func hardDrop() async {
        guard let piece = currentPiece, let position = currentPosition else { return }
        
        // Find the lowest valid position
        var dropDistance = 0
        while true {
            let newPosition = PiecePosition(row: position.row + dropDistance + 1, col: position.col, rotation: position.rotation)
            let isValid = await gameBoard.isPositionValid(piece: piece, at: newPosition)
            if !isValid {
                break
            }
            dropDistance += 1
        }
        
        // Move piece to the lowest valid position
        let finalPosition = PiecePosition(row: position.row + dropDistance, col: position.col, rotation: position.rotation)
        currentPosition = finalPosition
        
        // Lock piece in place
        await gameBoard.add(piece: piece, at: finalPosition)
        let linesCleared = await gameBoard.clearLines()
        score += linesCleared * 100
        await spawnNewPiece()
    }
    
    func rotatePieceCounterClockwise() async {
        guard let piece = currentPiece, let position = currentPosition else { return }
        let newRotation = (position.rotation - 1 + piece.rotationStates.count) % piece.rotationStates.count
        let newPosition = PiecePosition(row: position.row, col: position.col, rotation: newRotation)
        let isValid = await gameBoard.isPositionValid(piece: piece, at: newPosition)
        if isValid {
            currentPosition = newPosition
        }
    }
    
    // Swift 6.2 enhanced structured concurrency
    func updateGame(deltaTime: TimeInterval) async -> GameUpdateResult {
        dropTimer += deltaTime
        
        if dropTimer >= dropInterval {
            dropTimer = 0
            await dropPiece()
        }
        
        // Swift 6.2: Use raw identifiers for event tracking
        await logGameEvent(.`piece-moved`)
        
        return GameUpdateResult(score: score, linesCleared: 0, gameOver: gameOver)
    }
    
    // Swift 6.2: Enhanced logging with raw identifiers
    private func logGameEvent(_ event: GameEvent) async {
        print("Game Event: \(event.rawValue)")
    }
}

// MARK: - iOS 26 Enhanced Haptic Engine

@MainActor
class HapticEngine {
    static let shared = HapticEngine()
    
    private var impactFeedback: UIImpactFeedbackGenerator?
    private var notificationFeedback: UINotificationFeedbackGenerator?
    private var selectionFeedback: UISelectionFeedbackGenerator?
    
    private init() {
        setupHapticEngines()
    }
    
    private func setupHapticEngines() {
        impactFeedback = UIImpactFeedbackGenerator(style: .light)
        notificationFeedback = UINotificationFeedbackGenerator()
        selectionFeedback = UISelectionFeedbackGenerator()
        
        // iOS 26: Prepare haptic engines for better performance
        impactFeedback?.prepare()
        notificationFeedback?.prepare()
        selectionFeedback?.prepare()
    }
    
    func playRotationFeedback() async {
        impactFeedback?.impactOccurred(intensity: 0.7)
        print("Piece rotated with enhanced haptic feedback")
    }
    
    func playLineClearFeedback() async {
        notificationFeedback?.notificationOccurred(.success)
        
        // iOS 26: Enhanced haptic pattern for line clear
        await playHapticPattern()
    }
    
    func playGameOverFeedback() async {
        notificationFeedback?.notificationOccurred(.error)
        
        // iOS 26: Dramatic haptic pattern for game over
        await playGameOverHapticPattern()
    }
    
    func playMoveFeedback() async {
        selectionFeedback?.selectionChanged()
    }
    
    func playDropFeedback() async {
        impactFeedback?.impactOccurred(intensity: 0.5)
    }
    
    // iOS 26: Enhanced haptic patterns
    private func playHapticPattern() async {
        // Success pattern: light-medium-light
        impactFeedback?.impactOccurred(intensity: 0.3)
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        impactFeedback?.impactOccurred(intensity: 0.7)
        try? await Task.sleep(nanoseconds: 100_000_000)
        impactFeedback?.impactOccurred(intensity: 0.3)
    }
    
    private func playGameOverHapticPattern() async {
        // Error pattern: strong-strong-strong
        for _ in 0..<3 {
            impactFeedback?.impactOccurred(intensity: 1.0)
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 second
        }
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
    private var debugLabel: SKLabelNode?
    
    // iOS 26 Liquid Glass Elements
    private var glassBackground: SKSpriteNode?
    private var glassHUD: SKSpriteNode?
    private var particleSystem: SKEmitterNode?

    init(size: CGSize, gameEngine: GameEngine) {
        self.gameEngine = gameEngine
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        setupScene()
        setupLiquidGlassUI()
        setupUI()
        
        // Start the game
        Task {
            await gameEngine.startGame()
        }
    }
    
    private func setupScene() {
        // iOS 26 modern dark background
        backgroundColor = SKColor.systemBackground
        
        // Add a test label to verify the scene is working
        let testLabel = SKLabelNode(fontNamed: "SF Pro Display-Bold")
        testLabel.text = "TETRIS"
        testLabel.fontSize = 32
        testLabel.fontColor = SKColor.label
        testLabel.position = CGPoint(x: size.width / 2, y: size.height - 100)
        addChild(testLabel)
        
        // Add grid lines for better visibility
        drawGrid()
    }
    
    private func setupLiquidGlassUI() {
        // Create glass background effect
        createGlassBackground()
        
        // Create glass HUD elements
        createGlassHUD()
        
        // Add particle system for modern effects
        createParticleSystem()
    }
    
    private func createGlassBackground() {
        // iOS 26 Liquid Glass background effect
        let glassNode = SKSpriteNode(color: SKColor.systemGray6.withAlphaComponent(0.1), size: CGSize(width: size.width * 0.8, height: size.height * 0.6))
        glassNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        
        // Apply glass morphism effect
        glassNode.alpha = 0.1
        glassNode.blendMode = .screen
        
        glassBackground = glassNode
        addChild(glassNode)
    }
    
    private func createGlassHUD() {
        // Create glass HUD container
        let hudSize = CGSize(width: size.width * 0.3, height: size.height * 0.2)
        let hudNode = SKSpriteNode(color: .clear, size: hudSize)
        hudNode.position = CGPoint(x: size.width - hudSize.width / 2 - 20, y: size.height - hudSize.height / 2 - 20)
        
        // Apply glass effect to HUD
        hudNode.alpha = 0.8
        hudNode.blendMode = .screen
        
        // Add rounded corners
        let cornerRadius: CGFloat = 16
        let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: hudSize), cornerRadius: cornerRadius)
        let shapeNode = SKShapeNode(path: path.cgPath)
        shapeNode.fillColor = SKColor.systemGray6.withAlphaComponent(0.3)
        shapeNode.strokeColor = SKColor.systemGray5.withAlphaComponent(0.5)
        shapeNode.lineWidth = 1
        hudNode.addChild(shapeNode)
        
        glassHUD = hudNode
        addChild(hudNode)
    }
    
    private func createParticleSystem() {
        // iOS 26 modern particle system
        let particleNode = SKEmitterNode()
        
        // Configure particle properties
        particleNode.particleTexture = SKTexture(imageNamed: "spark") // Default spark texture
        particleNode.particleBirthRate = 5
        particleNode.numParticlesToEmit = 50
        particleNode.particleLifetime = 3.0
        particleNode.particleLifetimeRange = 1.0
        particleNode.particleSpeed = 20
        particleNode.particleSpeedRange = 10
        particleNode.particleAlpha = 0.3
        particleNode.particleAlphaRange = 0.2
        particleNode.particleScale = 0.1
        particleNode.particleScaleRange = 0.05
        particleNode.particleColor = SKColor.systemBlue
        particleNode.particleColorBlendFactor = 0.8
        particleNode.particleBlendMode = .add
        
        // Position particles around the game area
        particleNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        
        particleSystem = particleNode
        addChild(particleNode)
    }
    
    private func setupUI() {
        // Score label with Swift 6.2 string interpolation
        scoreLabel = SKLabelNode(fontNamed: "SF Pro Display-Bold")
        scoreLabel?.text = "Score: 0"
        scoreLabel?.fontSize = 20
        scoreLabel?.fontColor = SKColor.label
        scoreLabel?.position = CGPoint(x: size.width - 100, y: size.height - 50)
        addChild(scoreLabel!)
        
        // Game over label (hidden initially)
        gameOverLabel = SKLabelNode(fontNamed: "SF Pro Display-Bold")
        gameOverLabel?.text = "GAME OVER"
        gameOverLabel?.fontSize = 48
        gameOverLabel?.fontColor = SKColor.systemRed
        gameOverLabel?.position = CGPoint(x: size.width / 2, y: size.height / 2)
        gameOverLabel?.isHidden = true
        addChild(gameOverLabel!)
        
        // Debug label for Swift 6.2 testing
        debugLabel = SKLabelNode(fontNamed: "SF Mono")
        debugLabel?.text = "TETRIS GAME - Swift 6.2 + iOS 26"
        debugLabel?.fontSize = 14
        debugLabel?.fontColor = SKColor.tertiaryLabel
        debugLabel?.position = CGPoint(x: size.width / 2, y: size.height - 30)
        addChild(debugLabel!)
        
        // Controls help (only show on simulator)
        #if targetEnvironment(simulator)
        addControlsHelp()
        #endif
    }
    
    private func addControlsHelp() {
        let controlsTitle = SKLabelNode(fontNamed: "SF Pro Display-Bold")
        controlsTitle.text = "KEYBOARD CONTROLS"
        controlsTitle.fontSize = 16
        controlsTitle.fontColor = SKColor.secondaryLabel
        controlsTitle.position = CGPoint(x: 100, y: size.height - 150)
        addChild(controlsTitle)
        
        let controlsText = SKLabelNode(fontNamed: "SF Pro Display")
        controlsText.text = "←→/AD: Move  ↑/W: Rotate  ↓: Soft Drop  Space: Hard Drop  R: Restart"
        controlsText.fontSize = 12
        controlsText.fontColor = SKColor.secondaryLabel
        controlsText.position = CGPoint(x: 100, y: size.height - 170)
        addChild(controlsText)
    }
    
    private func drawGrid() {
        // Draw vertical lines with modern styling
        for col in 0...10 {
            let x = CGFloat(col) * blockSize
            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: CGFloat(22) * blockSize))
            line.path = path
            line.strokeColor = SKColor.systemGray5.withAlphaComponent(0.3)
            line.lineWidth = 0.5
            addChild(line)
        }
        
        // Draw horizontal lines with modern styling
        for row in 0...22 {
            let y = CGFloat(row) * blockSize
            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: CGFloat(10) * blockSize, y: y))
            line.path = path
            line.strokeColor = SKColor.systemGray5.withAlphaComponent(0.3)
            line.lineWidth = 0.5
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
            Task {
                await HapticEngine.shared.playGameOverFeedback()
            }
        }
    }

    @MainActor private func drawGameBoard() async {
        // Remove existing blocks from the scene
        children.filter { $0.name == "tetrisBlock" }.forEach { $0.removeFromParent() }

        let board = await gameEngine.gameBoard

        // Draw placed blocks with modern styling
        for row in 0..<board.rows {
            for col in 0..<board.columns {
                if let block = board.grid[row][col] {
                    let x = CGFloat(col) * blockSize + blockSize / 2
                    let y = CGFloat(board.rows - 1 - row) * blockSize + blockSize / 2
                    
                    // Create modern block with rounded corners
                    let sprite = SKShapeNode(rectOf: CGSize(width: blockSize - 2, height: blockSize - 2), cornerRadius: 4)
                    sprite.fillColor = convertSwiftUIColorToSKColor(block.color)
                    sprite.strokeColor = SKColor.white.withAlphaComponent(0.3)
                    sprite.lineWidth = 1
                    sprite.position = CGPoint(x: x, y: y)
                    sprite.name = "tetrisBlock"
                    
                    // Add subtle border effect
                    sprite.strokeColor = SKColor.white.withAlphaComponent(0.3)
                    sprite.lineWidth = 1
                    
                    addChild(sprite)
                }
            }
        }
        
        // Draw current piece with enhanced styling
        if let currentPiece = await gameEngine.currentPieceForRendering,
           let currentPosition = await gameEngine.currentPositionForRendering {
            let shape = currentPiece.rotationStates[currentPosition.rotation]
            for (row, shapeRow) in shape.enumerated() {
                for (col, isFilled) in shapeRow.enumerated() {
                    if isFilled {
                        let x = CGFloat(currentPosition.col + col) * blockSize + blockSize / 2
                        let y = CGFloat(board.rows - 1 - (currentPosition.row + row)) * blockSize + blockSize / 2
                        
                        // Create current piece block with special styling
                        let sprite = SKShapeNode(rectOf: CGSize(width: blockSize - 2, height: blockSize - 2), cornerRadius: 4)
                        sprite.fillColor = convertSwiftUIColorToSKColor(currentPiece.color)
                        sprite.strokeColor = SKColor.white.withAlphaComponent(0.6)
                        sprite.lineWidth = 2
                        sprite.alpha = 0.9 // Make current piece slightly transparent
                        sprite.position = CGPoint(x: x, y: y)
                        sprite.name = "tetrisBlock"
                        
                        // Add glow effect for current piece
                        sprite.strokeColor = convertSwiftUIColorToSKColor(currentPiece.color)
                        sprite.lineWidth = 2
                        
                        addChild(sprite)
                    }
                }
            }
        }
    }
    
    private func convertSwiftUIColorToSKColor(_ color: Color) -> SKColor {
        switch color {
        case .cyan:
            return SKColor.systemCyan
        case .blue:
            return SKColor.systemBlue
        case .orange:
            return SKColor.systemOrange
        case .yellow:
            return SKColor.systemYellow
        case .green:
            return SKColor.systemGreen
        case .purple:
            return SKColor.systemPurple
        case .red:
            return SKColor.systemRed
        default:
            return SKColor.label
        }
    }
}

// MARK: - SwiftUI Integration (Optional)

struct TetrisGameView: View {
    @State private var gameEngine: GameEngine?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let gameEngine = gameEngine {
                    // Game board with enhanced rendering
                    SpriteView(scene: createGameScene(size: geometry.size, gameEngine: gameEngine))
                        .ignoresSafeArea()
                } else {
                    ProgressView("Loading...")
                }
            }
        }
        .task {
            gameEngine = await GameEngine(rows: 22, columns: 10)
        }
    }
    
    private func createGameScene(size: CGSize, gameEngine: GameEngine) -> SKScene {
        let scene = GameScene(size: size, gameEngine: gameEngine)
        scene.scaleMode = .resizeFill
        return scene
    }
}
