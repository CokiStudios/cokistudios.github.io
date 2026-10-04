import Foundation
import GameController
import Combine

// MARK: - Gamepad Action Events
public enum GamepadAction {
    case dpadLeft
    case dpadRight
    case dpadUp
    case dpadDown
    case buttonA // Launch / Select
    case buttonB // Back / Cancel
    case buttonX // Toggle Grid / Carousel
    case buttonY // Bubbly Dot Assistant
    case shoulderLeft // Prev Category
    case shoulderRight // Next Category
    case menuButton // Settings Drawer
}

// MARK: - Game Controller Manager
public final class GameControllerManager: ObservableObject, @unchecked Sendable {
    public static let shared = GameControllerManager()

    @Published public var isControllerConnected: Bool = false
    @Published public var connectedControllerName: String = "Teclado y Ratón"
    @Published public var batteryPercentage: Float? = nil

    public var onAction: ((GamepadAction) -> Void)?

    private var lastThumbstickTimestamp: TimeInterval = 0
    private let thumbstickDebounce: TimeInterval = 0.22

    private init() {
        setupObservers()
        checkForConnectedControllers()
    }

    private func setupObservers() {
        NotificationCenter.default.addObserver(
            forName: .GCControllerDidConnect,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let controller = notification.object as? GCController {
                self?.handleControllerConnected(controller)
            }
        }

        NotificationCenter.default.addObserver(
            forName: .GCControllerDidDisconnect,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.checkForConnectedControllers()
        }
    }

    private func checkForConnectedControllers() {
        if let controller = GCController.controllers().first {
            handleControllerConnected(controller)
        } else {
            DispatchQueue.main.async {
                self.isControllerConnected = false
                self.connectedControllerName = "Teclado / Ratón"
                self.batteryPercentage = nil
            }
        }
    }

    private func handleControllerConnected(_ controller: GCController) {
        DispatchQueue.main.async {
            self.isControllerConnected = true
            let name = controller.vendorName ?? "Shine Loop Gamepad"
            self.connectedControllerName = name
            if let battery = controller.battery {
                self.batteryPercentage = battery.batteryLevel
            }
        }

        controller.extendedGamepad?.valueChangedHandler = nil

        if let extended = controller.extendedGamepad {
            extended.dpad.left.pressedChangedHandler = { [weak self] _, _, pressed in
                if pressed { self?.trigger(.dpadLeft) }
            }
            extended.dpad.right.pressedChangedHandler = { [weak self] _, _, pressed in
                if pressed { self?.trigger(.dpadRight) }
            }
            extended.dpad.up.pressedChangedHandler = { [weak self] _, _, pressed in
                if pressed { self?.trigger(.dpadUp) }
            }
            extended.dpad.down.pressedChangedHandler = { [weak self] _, _, pressed in
                if pressed { self?.trigger(.dpadDown) }
            }

            // Left Thumbstick Navigation with Deadzone
            extended.leftThumbstick.valueChangedHandler = { [weak self] _, x, y in
                guard let self = self else { return }
                let now = ProcessInfo.processInfo.systemUptime
                guard now - self.lastThumbstickTimestamp > self.thumbstickDebounce else { return }

                if x > 0.55 {
                    self.lastThumbstickTimestamp = now
                    self.trigger(.dpadRight)
                } else if x < -0.55 {
                    self.lastThumbstickTimestamp = now
                    self.trigger(.dpadLeft)
                } else if y > 0.55 {
                    self.lastThumbstickTimestamp = now
                    self.trigger(.dpadUp)
                } else if y < -0.55 {
                    self.lastThumbstickTimestamp = now
                    self.trigger(.dpadDown)
                }
            }

            // Action Buttons
            extended.buttonA.pressedChangedHandler = { [weak self] _, _, pressed in
                if pressed { self?.trigger(.buttonA) }
            }
            extended.buttonB.pressedChangedHandler = { [weak self] _, _, pressed in
                if pressed { self?.trigger(.buttonB) }
            }
            extended.buttonX.pressedChangedHandler = { [weak self] _, _, pressed in
                if pressed { self?.trigger(.buttonX) }
            }
            extended.buttonY.pressedChangedHandler = { [weak self] _, _, pressed in
                if pressed { self?.trigger(.buttonY) }
            }

            // Shoulders
            extended.leftShoulder.pressedChangedHandler = { [weak self] _, _, pressed in
                if pressed { self?.trigger(.shoulderLeft) }
            }
            extended.rightShoulder.pressedChangedHandler = { [weak self] _, _, pressed in
                if pressed { self?.trigger(.shoulderRight) }
            }

            // Options / Menu
            extended.buttonMenu.pressedChangedHandler = { [weak self] _, _, pressed in
                if pressed { self?.trigger(.menuButton) }
            }
        }
    }

    private func trigger(_ action: GamepadAction) {
        DispatchQueue.main.async { [weak self] in
            self?.onAction?(action)
        }
    }
}
