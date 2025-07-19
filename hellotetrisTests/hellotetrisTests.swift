//
//  hellotetrisTests.swift
//  hellotetrisTests
//
//  Created by Noel Blom on 7/19/25.
//

import XCTest
@testable import hellotetris

final class hellotetrisTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testGameBoardInitialization() async throws {
        // Test GameBoard initialization
        let gameBoard = await GameBoard(rows: 22, columns: 10)
        
        XCTAssertEqual(gameBoard.rows, 22)
        XCTAssertEqual(gameBoard.columns, 10)
        XCTAssertEqual(gameBoard.grid.count, 22)
        XCTAssertEqual(gameBoard.grid[0].count, 10)
    }
    
    func testTetriminoPieceCreation() throws {
        // Test TetriminoPiece creation
        let shape = [[true, true], [true, true]]
        let color = Color.blue
        let rotationStates = [[[true, true], [true, true]]]
        
        let piece = TetriminoPiece(shape: shape, color: color, rotationStates: rotationStates)
        
        XCTAssertEqual(piece.shape.count, 2)
        XCTAssertEqual(piece.shape[0].count, 2)
        XCTAssertEqual(piece.rotationStates.count, 1)
    }
    
    func testPiecePosition() throws {
        // Test PiecePosition struct
        let position = PiecePosition(row: 5, col: 3, rotation: 1)
        
        XCTAssertEqual(position.row, 5)
        XCTAssertEqual(position.col, 3)
        XCTAssertEqual(position.rotation, 1)
    }
    
    func testGameUpdateResult() throws {
        // Test GameUpdateResult struct
        let result = GameUpdateResult(score: 100, linesCleared: 2, gameOver: false)
        
        XCTAssertEqual(result.score, 100)
        XCTAssertEqual(result.linesCleared, 2)
        XCTAssertFalse(result.gameOver)
    }
    
    func testTetriminoBlock() throws {
        // Test TetriminoBlock struct
        let block = TetriminoBlock(color: .red)
        
        XCTAssertEqual(block.color, .red)
    }
    
    func testGameEngineInitialization() async throws {
        // Test GameEngine initialization
        let gameEngine = await GameEngine(rows: 22, columns: 10)
        
        // Verify the game engine was created successfully
        XCTAssertNotNil(gameEngine)
    }
    
    func testPerformanceExample() throws {
        // Performance test
        measure {
            // Measure the time of creating a game board
            Task {
                let _ = await GameBoard(rows: 22, columns: 10)
            }
        }
    }
}
