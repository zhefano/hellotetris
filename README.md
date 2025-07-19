# Hello Tetris 🎮

A modern Tetris implementation built with **Swift 6**, **SpriteKit**, and **iOS 26** features.

![iOS](https://img.shields.io/badge/iOS-26.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-6.2+-orange.svg)
![Xcode](https://img.shields.io/badge/Xcode-16.0+-blue.svg)

## ✨ Features

- 🎯 **Classic Tetris Gameplay** - All 7 standard Tetrimino pieces with accurate physics
- 🎨 **Modern iOS 26 Design** - Glass morphism UI with dynamic backgrounds
- 📱 **Responsive Controls** - Touch gestures and keyboard support
- 🔊 **Haptic Feedback** - Enhanced tactile feedback using iOS 26 haptic engine
- ⚡ **Swift 6 Concurrency** - Actor-based architecture for thread-safe gameplay
- 🎭 **Visual Effects** - Particle systems and smooth animations
- 📊 **Real-time Stats** - Score, level, and lines cleared tracking

## 🎮 How to Play

### Touch Controls
- **Tap left**: Move piece left
- **Tap right**: Move piece right  
- **Tap center**: Rotate piece

### Keyboard Controls
- **Arrow Keys** / **WASD**: Move and rotate pieces
- **Spacebar**: Hard drop
- **R**: Restart game

## 🚀 Quick Start

### Prerequisites
- **Xcode 16.0+** with iOS 26 SDK
- **iOS 26.0+** device or simulator

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/hellotetris.git
   cd hellotetris
   ```

2. Open in Xcode:
   ```bash
   open hellotetris.xcodeproj
   ```

3. Build and run:
   ```bash
   ⌘ + R
   ```

## 🏗️ Architecture

- **`GameEngine`** - Actor-based game logic with Swift 6 concurrency
- **`GameBoard`** - Grid management and collision detection
- **`GameScene`** - SpriteKit rendering and visual effects
- **`TetriminoPiece`** - Piece definitions and rotation states

## 🎯 Technical Highlights

- **Swift 6 Features**: Actor isolation, enhanced concurrency patterns
- **iOS 26 APIs**: Modern haptic feedback, glass morphism effects
- **Performance**: 60 FPS smooth gameplay with optimized rendering
- **Memory Safe**: Proper memory management with automatic cleanup

## 🔧 Build & Test

```bash
# Build for simulator
xcodebuild build -project hellotetris.xcodeproj -scheme hellotetris \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Run tests
xcodebuild test -project hellotetris.xcodeproj -scheme hellotetris \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

## 🤝 Contributing

1. Fork the project
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is for educational purposes. Tetris is a trademark of The Tetris Company.

---

**Enjoy playing!** Built with ❤️ using Swift 6 and iOS 26 