import Combine
import Foundation
import GameController

@MainActor
final class ControllerManager: ObservableObject {
    @Published private(set) var connectedControllerName: String?
    @Published private(set) var latestPressedButton: ControllerButton?

    var isControllerConnected: Bool {
        connectedControllerName != nil
    }

    private let mappingManager: MappingManager
    private var activeController: GCController?
    private var notificationObservers: [NSObjectProtocol] = []
    private var pressedButtons = Set<ControllerButton>()
    private var isDiscoveringControllers = false

    init(mappingManager: MappingManager) {
        self.mappingManager = mappingManager
        GCController.shouldMonitorBackgroundEvents = true
        setupNotifications()
        scanControllers()
    }

    deinit {
        for observer in notificationObservers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func scanControllers() {
        print("Controller scan started")

        let controllers = GCController.controllers()
        if let controller = controllers.first {
            configure(controller)
        } else {
            activeController = nil
            connectedControllerName = nil
            latestPressedButton = nil
            pressedButtons.removeAll()
        }

        startWirelessDiscoveryIfNeeded()
    }

    private func setupNotifications() {
        let center = NotificationCenter.default

        notificationObservers.append(
            center.addObserver(
                forName: .GCControllerDidConnect,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                MainActor.assumeIsolated {
                    guard let self else { return }

                    if let controller = notification.object as? GCController {
                        self.configure(controller)
                    } else {
                        self.scanControllers()
                    }
                }
            }
        )

        notificationObservers.append(
            center.addObserver(
                forName: .GCControllerDidDisconnect,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    self.handleControllerDisconnected(notification.object as? GCController)
                }
            }
        )
    }

    private func startWirelessDiscoveryIfNeeded() {
        guard !isDiscoveringControllers else { return }

        isDiscoveringControllers = true
        GCController.startWirelessControllerDiscovery { [weak self] in
            DispatchQueue.main.async {
                self?.isDiscoveringControllers = false
            }
        }
    }

    private func configure(_ controller: GCController) {
        activeController = controller
        connectedControllerName = controller.vendorName ?? "Unknown Controller"
        pressedButtons.removeAll()

        print("Controller connected: \(connectedControllerName ?? "Unknown Controller")")

        if let gamepad = controller.extendedGamepad {
            configureExtendedGamepad(gamepad)
        } else if let gamepad = controller.microGamepad {
            configureMicroGamepad(gamepad)
        }
    }

    private func handleControllerDisconnected(_ controller: GCController?) {
        guard controller == nil || controller === activeController else {
            return
        }

        print("Controller disconnected")
        activeController = nil
        connectedControllerName = nil
        latestPressedButton = nil
        pressedButtons.removeAll()
        scanControllers()
    }

    private func configureExtendedGamepad(_ gamepad: GCExtendedGamepad) {
        bind(gamepad.buttonA, to: .a)
        bind(gamepad.buttonB, to: .b)
        bind(gamepad.buttonX, to: .x)
        bind(gamepad.buttonY, to: .y)
        bind(gamepad.leftShoulder, to: .leftShoulder)
        bind(gamepad.rightShoulder, to: .rightShoulder)
        bind(gamepad.leftTrigger, to: .leftTrigger)
        bind(gamepad.rightTrigger, to: .rightTrigger)
        bind(gamepad.dpad.up, to: .dpadUp)
        bind(gamepad.dpad.down, to: .dpadDown)
        bind(gamepad.dpad.left, to: .dpadLeft)
        bind(gamepad.dpad.right, to: .dpadRight)
    }

    private func configureMicroGamepad(_ gamepad: GCMicroGamepad) {
        gamepad.reportsAbsoluteDpadValues = true

        bind(gamepad.buttonA, to: .a)
        bind(gamepad.buttonX, to: .x)
        bind(gamepad.dpad.up, to: .dpadUp)
        bind(gamepad.dpad.down, to: .dpadDown)
        bind(gamepad.dpad.left, to: .dpadLeft)
        bind(gamepad.dpad.right, to: .dpadRight)
    }

    private func bind(_ input: GCControllerButtonInput, to button: ControllerButton) {
        input.pressedChangedHandler = { [weak self] _, _, isPressed in
            DispatchQueue.main.async {
                self?.handleButton(button, isPressed: isPressed)
            }
        }
    }

    private func handleButton(_ button: ControllerButton, isPressed: Bool) {
        if isPressed {
            guard !pressedButtons.contains(button) else {
                return
            }

            pressedButtons.insert(button)
            latestPressedButton = button
            print("Button pressed: \(button.displayName)")
            mappingManager.handleButtonPress(button)
        } else {
            pressedButtons.remove(button)
            print("Button released: \(button.displayName)")
        }
    }
}
