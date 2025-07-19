# Contributing to Hello Tetris

Thank you for your interest in contributing to Hello Tetris! This document provides guidelines and information for contributors.

## Getting Started

### Prerequisites
- Xcode 16.0 or later
- iOS 26.0 SDK
- Swift 6.2
- Git

### Development Setup
1. Fork the repository
2. Clone your fork locally
3. Open `hellotetris.xcodeproj` in Xcode
4. Build and run the project

## Issue Labels

We use the following labels to categorize issues and pull requests:

### Type Labels
- `bug` - Something isn't working
- `enhancement` - New feature or request
- `documentation` - Improvements or additions to documentation
- `good first issue` - Good for newcomers
- `help wanted` - Extra attention is needed

### Game Labels
- `gameplay` - Game mechanics and rules
- `controls` - Input handling and user interaction
- `ui-improvement` - User interface enhancements
- `visual-effects` - Graphics, animations, particles
- `sound` - Audio and music features

### Platform Labels
- `ios26` - iOS 26 specific features
- `swift62` - Swift 6.2 language features
- `haptic-feedback` - Haptic engine and feedback
- `performance` - Performance optimizations
- `accessibility` - Accessibility improvements

### Technical Labels
- `architecture` - Code structure and design
- `concurrency` - Async/await and actor usage
- `testing` - Unit tests and integration tests
- `build` - Build system and dependencies
- `deployment` - App Store and distribution

### Priority Labels
- `high-priority` - Critical issues requiring immediate attention
- `medium-priority` - Important but not urgent
- `low-priority` - Nice to have features

## Development Guidelines

### Code Style
- Follow Swift style guidelines
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions focused and concise

### Swift 6.2 Features
- Use raw identifiers where appropriate (SE-0451)
- Implement enhanced string interpolation (SE-0477)
- Leverage actor-based concurrency
- Use modern iOS 26 APIs

### Architecture
- Maintain actor isolation in GameEngine
- Use proper async/await patterns
- Keep UI updates on the main thread
- Follow MVVM principles where applicable

### Testing
- Write unit tests for game logic
- Test on both simulator and device
- Verify haptic feedback functionality
- Test performance on different devices

## Pull Request Process

1. **Create a feature branch** from `main`
2. **Make your changes** following the guidelines above
3. **Test thoroughly** on simulator and device
4. **Update documentation** if needed
5. **Create a pull request** with a clear description
6. **Add appropriate labels** to your PR
7. **Wait for review** and address feedback

### Pull Request Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] Tests pass
- [ ] No new warnings
- [ ] Screenshots added (if UI changes)

## Issue Reporting

### Bug Reports
- Use the bug report template
- Include steps to reproduce
- Provide environment details
- Add screenshots if applicable

### Feature Requests
- Use the feature request template
- Explain the problem being solved
- Provide implementation ideas
- Consider alternatives

## Current Development Focus

### In Progress
- Hold piece functionality
- Next piece preview
- High score tracking
- Sound effects integration

### Planned Features
- Multiple difficulty levels
- Multiplayer support
- Apple Intelligence integration
- Advanced particle effects
- Custom themes and skins

## Getting Help

- Check existing issues and pull requests
- Join discussions in issues
- Ask questions in issue comments
- Review the README for setup instructions

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn and grow
- Follow project guidelines

## License

By contributing to Hello Tetris, you agree that your contributions will be licensed under the same license as the project.

Thank you for contributing to Hello Tetris! 