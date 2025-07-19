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
import AsyncAlgorithms

// MARK: - Swift 6 Enhanced Features

// Swift 6: Raw identifiers for better test naming (SE-0451)
enum GameEvent: String, Sendable {
    case `piece-moved` = "Piece moved"
    case `line-cleared` = "Line cleared"
    case `game-over` = "Game over"
    case `score-updated` = "Score updated"
    case `level-up` = "Level up"
}

// Swift 6: Enhanced string interpolation with raw identifiers
extension String {
    func gameStatus(_ score: Int?) -> String {
        return "Score: \(score ?? 0)"
    }
    
    func levelStatus(_ level: Int) -> String {
        return "Level: \(level)"
    }
}

// MARK: - iOS 26 Enhanced Features

// iOS 26: Enhanced haptic feedback with ProMotion support
@MainActor
class HapticEngine: Sendable {
    static let shared = HapticEngine()
    
    private var impactFeedback: UIImpactFeedbackGenerator?
    private var notificationFeedback: UINotificationFeedbackGenerator?
    private var selectionFeedback: UISelectionFeedbackGenerator?
    
    private init() {
        setupHapticEngines()
    }
    
    private func setupHapticEngines() {
        // iOS 26: Enhanced haptic feedback with ProMotion
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
        try? await Task.sleep(for: .milliseconds(100))
        impactFeedback?.impactOccurred(intensity: 0.7)
        try? await Task.sleep(for: .milliseconds(100))
        impactFeedback?.impactOccurred(intensity: 0.3)
    }
    
    private func playGameOverHapticPattern() async {
        // Error pattern: strong-strong-strong
        for _ in 0..<3 {
            impactFeedback?.impactOccurred(intensity: 1.0)
            try? await Task.sleep(for: .milliseconds(200))
        }
    }
}

// MARK: - Game Types

struct TetriminoBlock: Sendable {
    let color: Color
    
    init(color: Color) {
        self.color = color
    }
}

struct GameUpdateResult: Sendable {
    let score: Int
    let linesCleared: Int
    let gameOver: Bool
    let level: Int
}

struct PiecePosition: Sendable {
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

// MARK: - Game Engine with Swift 6 Concurrency

actor GameEngine: Sendable {
    var gameBoard: GameBoard
    private var currentPiece: TetriminoPiece?
    private var currentPosition: PiecePosition?
    private var score: Int = 0
    private var level: Int = 1
    private var gameOver: Bool = false
    private var dropTimer: TimeInterval = 0
    private var dropInterval: TimeInterval = 1.0 // 1 second per drop
    
    // Swift 6: Enhanced concurrency with AsyncChannel for events
    private let eventChannel = AsyncChannel<GameEvent>()
    
    // Make these accessible for rendering
    var currentPieceForRendering: TetriminoPiece? { get { currentPiece } }
    var currentPositionForRendering: PiecePosition? { get { currentPosition } }
    
    init(rows: Int, columns: Int) async {
        self.gameBoard = await GameBoard(rows: rows, columns: columns)
    }
    
    // Swift 6: Async sequence for game events
    var events: AsyncChannel<GameEvent> { eventChannel }
    
    func startGame() async {
        gameOver = false
        score = 0
        level = 1
        await eventChannel.send(.`score-updated`)
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
                await eventChannel.send(.`game-over`)
                await HapticEngine.shared.playGameOverFeedback()
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
            await eventChannel.send(.`piece-moved`)
        }
    }
    
    func movePieceRight() async {
        guard let piece = currentPiece, let position = currentPosition else { return }
        let newPosition = PiecePosition(row: position.row, col: position.col + 1, rotation: position.rotation)
        let isValid = await gameBoard.isPositionValid(piece: piece, at: newPosition)
        if isValid {
            currentPosition = newPosition
            await HapticEngine.shared.playMoveFeedback()
            await eventChannel.send(.`piece-moved`)
        }
    }
    
    func rotatePiece() async {
        guard let piece = currentPiece, let position = currentPosition else { return }
        let newRotation = (position.rotation + 1) % piece.rotationStates.count
        let newPosition = PiecePosition(row: position.row, col: position.col, rotation: newRotation)
        let isValid = await gameBoard.isPositionValid(piece: piece, at: newPosition)
        if isValid {
            currentPosition = newPosition
            await HapticEngine.shared.playRotationFeedback()
            await eventChannel.send(.`piece-moved`)
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
            
            if linesCleared > 0 {
                score += linesCleared * 100 * level
                await HapticEngine.shared.playLineClearFeedback()
                await eventChannel.send(.`line-cleared`)
                
                // Level up every 10 lines
                let newLevel = (score / 1000) + 1
                if newLevel > level {
                    level = newLevel
                    dropInterval = max(0.1, 1.0 - (Double(level - 1) * 0.1)) // Speed up with level
                    await eventChannel.send(.`level-up`)
                }
            }
            
            await eventChannel.send(.`score-updated`)
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
        
        if linesCleared > 0 {
            score += linesCleared * 100 * level
            await HapticEngine.shared.playLineClearFeedback()
            await eventChannel.send(.`line-cleared`)
            
            // Level up every 10 lines
            let newLevel = (score / 1000) + 1
            if newLevel > level {
                level = newLevel
                dropInterval = max(0.1, 1.0 - (Double(level - 1) * 0.1))
                await eventChannel.send(.`level-up`)
            }
        }
        
        await HapticEngine.shared.playDropFeedback()
        await eventChannel.send(.`score-updated`)
        await spawnNewPiece()
    }
    
    func rotatePieceCounterClockwise() async {
        guard let piece = currentPiece, let position = currentPosition else { return }
        let newRotation = (position.rotation - 1 + piece.rotationStates.count) % piece.rotationStates.count
        let newPosition = PiecePosition(row: position.row, col: position.col, rotation: newRotation)
        let isValid = await gameBoard.isPositionValid(piece: piece, at: newPosition)
        if isValid {
            currentPosition = newPosition
            await HapticEngine.shared.playRotationFeedback()
            await eventChannel.send(.`piece-moved`)
        }
    }
    
    func updateGame(deltaTime: TimeInterval) async -> GameUpdateResult {
        dropTimer += deltaTime
        
        if dropTimer >= dropInterval {
            dropTimer = 0
            await dropPiece()
        }
        
        return GameUpdateResult(score: score, linesCleared: 0, gameOver: gameOver, level: level)
    }
}

// MARK: - Enhanced Game Scene with iOS 26 Features

class GameScene: SKScene {
    var gameEngine: GameEngine
    private var lastUpdateTime: TimeInterval = 0
    private let blockSize: CGFloat = 30.0
    
    // UI Elements
    private var scoreLabel: SKLabelNode?
    private var levelLabel: SKLabelNode?
    private var gameOverLabel: SKLabelNode?
    private var restartLabel: SKLabelNode?
    
    // iOS 26: Enhanced visual effects
    private var particleSystem: SKEmitterNode?
    private var backgroundGradient: SKSpriteNode?

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
        setupEventHandling()
        
        // Start the game
        Task {
            await gameEngine.startGame()
        }
    }
    
    private func setupScene() {
        // iOS 26: Enhanced background with gradient
        setupBackgroundGradient()
        
        // Add title with Swift 6 string interpolation
        let titleLabel = SKLabelNode(fontNamed: "SF Pro Display-Bold")
        titleLabel.text = "TETRIS"
        titleLabel.fontSize = 32
        titleLabel.fontColor = SKColor.label
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height - 100)
        addChild(titleLabel)
        
        // Draw grid
        drawGrid()
        
        // iOS 26: Add particle system for visual effects
        setupParticleSystem()
    }
    
    private func setupBackgroundGradient() {
        // iOS 26: Enhanced background with dynamic gradient
        let gradient = CAGradientLayer()
        gradient.frame = CGRect(origin: .zero, size: size)
        gradient.colors = [
            SKColor.systemBackground.cgColor,
            SKColor.systemGray6.cgColor,
            SKColor.systemBackground.cgColor
        ]
        gradient.locations = [0.0, 0.5, 1.0]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        
        let gradientImage = UIGraphicsImageRenderer(size: size).image { context in
            gradient.render(in: context.cgContext)
        }
        
        backgroundGradient = SKSpriteNode(texture: SKTexture(image: gradientImage))
        backgroundGradient?.position = CGPoint(x: size.width / 2, y: size.height / 2)
        backgroundGradient?.zPosition = -100
        addChild(backgroundGradient!)
    }
    
    private func setupParticleSystem() {
        // iOS 26: Enhanced particle system for visual effects
        particleSystem = SKEmitterNode()
        
        // Configure particle properties
        particleSystem?.particleBirthRate = 3
        particleSystem?.numParticlesToEmit = 20
        particleSystem?.particleLifetime = 2.0
        particleSystem?.particleLifetimeRange = 0.5
        particleSystem?.particleSpeed = 15
        particleSystem?.particleSpeedRange = 5
        particleSystem?.particleAlpha = 0.2
        particleSystem?.particleAlphaRange = 0.1
        particleSystem?.particleScale = 0.05
        particleSystem?.particleScaleRange = 0.02
        particleSystem?.particleColor = SKColor.systemBlue
        particleSystem?.particleColorBlendFactor = 0.6
        particleSystem?.particleBlendMode = .add
        
        // Position particles around the game area
        particleSystem?.position = CGPoint(x: size.width / 2, y: size.height / 2)
        particleSystem?.zPosition = -50
        
        addChild(particleSystem!)
    }
    
    private func setupUI() {
        // Score label with Swift 6 string interpolation
        scoreLabel = SKLabelNode(fontNamed: "SF Pro Display-Bold")
        scoreLabel?.text = "Score: 0"
        scoreLabel?.fontSize = 20
        scoreLabel?.fontColor = SKColor.label
        scoreLabel?.position = CGPoint(x: size.width - 100, y: size.height - 50)
        addChild(scoreLabel!)
        
        // Level label
        levelLabel = SKLabelNode(fontNamed: "SF Pro Display-Bold")
        levelLabel?.text = "Level: 1"
        levelLabel?.fontSize = 18
        levelLabel?.fontColor = SKColor.secondaryLabel
        levelLabel?.position = CGPoint(x: size.width - 100, y: size.height - 80)
        addChild(levelLabel!)
        
        // Game over label (hidden initially)
        gameOverLabel = SKLabelNode(fontNamed: "SF Pro Display-Bold")
        gameOverLabel?.text = "GAME OVER"
        gameOverLabel?.fontSize = 48
        gameOverLabel?.fontColor = SKColor.systemRed
        gameOverLabel?.position = CGPoint(x: size.width / 2, y: size.height / 2 + 50)
        gameOverLabel?.isHidden = true
        addChild(gameOverLabel!)
        
        // Restart label
        restartLabel = SKLabelNode(fontNamed: "SF Pro Display")
        restartLabel?.text = "Tap to restart"
        restartLabel?.fontSize = 24
        restartLabel?.fontColor = SKColor.systemBlue
        restartLabel?.position = CGPoint(x: size.width / 2, y: size.height / 2 - 50)
        restartLabel?.isHidden = true
        addChild(restartLabel!)
        
        // Controls help (only show on simulator)
        #if targetEnvironment(simulator)
        addControlsHelp()
        #endif
    }
    
    private func setupEventHandling() {
        // Swift 6: Handle game events asynchronously
        Task {
            for await event in gameEngine.events {
                await MainActor.run {
                    handleGameEvent(event)
                }
            }
        }
    }
    
    private func handleGameEvent(_ event: GameEvent) {
        switch event {
        case .`score-updated`:
            // Update score display
            break
        case .`line-cleared`:
            // Trigger line clear animation
            triggerLineClearAnimation()
        case .`level-up`:
            // Trigger level up animation
            triggerLevelUpAnimation()
        case .`game-over`:
            // Show game over UI
            showGameOver()
        default:
            break
        }
    }
    
    private func triggerLineClearAnimation() {
        // iOS 26: Enhanced line clear animation
        let flash = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.1),
            SKAction.fadeAlpha(to: 1.0, duration: 0.1)
        ])
        
        children.filter { $0.name == "tetrisBlock" }.forEach { block in
            block.run(SKAction.repeat(flash, count: 3))
        }
    }
    
    private func triggerLevelUpAnimation() {
        // iOS 26: Enhanced level up animation
        levelLabel?.run(SKAction.sequence([
            SKAction.scale(to: 1.5, duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.2)
        ]))
        
        // Change particle color for level up
        particleSystem?.particleColor = SKColor.systemGreen
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.particleSystem?.particleColor = SKColor.systemBlue
        }
    }
    
    private func showGameOver() {
        gameOverLabel?.isHidden = false
        restartLabel?.isHidden = false
        
        // iOS 26: Enhanced game over animation
        gameOverLabel?.run(SKAction.sequence([
            SKAction.scale(to: 0.5, duration: 0),
            SKAction.scale(to: 1.2, duration: 0.3),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))
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
        // Draw vertical lines
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
        
        // Draw horizontal lines
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
        
        // Check if restart was tapped
        if let restartLabel = restartLabel, restartLabel.contains(location) {
            Task {
                await gameEngine.startGame()
                gameOverLabel?.isHidden = true
                restartLabel.isHidden = true
            }
            return
        }
        
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
        scoreLabel?.text = result.score.gameStatus(nil)
        levelLabel?.text = result.level.levelStatus(result.level)
        
        if result.gameOver {
            gameOverLabel?.isHidden = false
            restartLabel?.isHidden = false
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
                    
                    let sprite = SKShapeNode(rectOf: CGSize(width: blockSize - 2, height: blockSize - 2), cornerRadius: 4)
                    sprite.fillColor = convertSwiftUIColorToSKColor(block.color)
                    sprite.strokeColor = SKColor.white.withAlphaComponent(0.3)
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
                        
                        let sprite = SKShapeNode(rectOf: CGSize(width: blockSize - 2, height: blockSize - 2), cornerRadius: 4)
                        sprite.fillColor = convertSwiftUIColorToSKColor(currentPiece.color)
                        sprite.strokeColor = SKColor.white.withAlphaComponent(0.6)
                        sprite.lineWidth = 2
                        sprite.alpha = 0.9
                        sprite.position = CGPoint(x: x, y: y)
                        sprite.name = "tetrisBlock"
                        
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

// MARK: - SwiftUI Integration with iOS 26 Features

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
