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
    private let dpadThreshold: Float = 0.5
    private var usesLeftJoyConDirectionalFaceButtonCorrection = false

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
            mappingManager.releaseAllHeldModifiers()
            activeController = nil
            connectedControllerName = nil
            latestPressedButton = nil
            usesLeftJoyConDirectionalFaceButtonCorrection = false
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
        mappingManager.releaseAllHeldModifiers()
        activeController = controller
        connectedControllerName = controller.vendorName ?? "Unknown Controller"
        usesLeftJoyConDirectionalFaceButtonCorrection = isLeftJoyCon(controller)
        pressedButtons.removeAll()

        print(
            "Controller connected: \(connectedControllerName ?? "Unknown Controller") " +
            "(extendedGamepad: \(controller.extendedGamepad != nil), microGamepad: \(controller.microGamepad != nil))"
        )
        print("Joy-Con (L) directional correction: \(usesLeftJoyConDirectionalFaceButtonCorrection ? "enabled" : "disabled")")

        if let gamepad = controller.extendedGamepad {
            configureExtendedGamepad(gamepad)
        }

        if let gamepad = controller.microGamepad {
            configureMicroGamepad(gamepad)
        }

        configurePhysicalInputProfile(controller.physicalInputProfile)

        if controller.extendedGamepad == nil && controller.microGamepad == nil {
            print("Controller connected but no supported gamepad profile was available")
        }
    }

    private func handleControllerDisconnected(_ controller: GCController?) {
        guard controller == nil || controller === activeController else {
            return
        }

        print("Controller disconnected")
        mappingManager.releaseAllHeldModifiers()
        activeController = nil
        connectedControllerName = nil
        latestPressedButton = nil
        usesLeftJoyConDirectionalFaceButtonCorrection = false
        pressedButtons.removeAll()
        scanControllers()
    }

    private func configureExtendedGamepad(_ gamepad: GCExtendedGamepad) {
        let profile = "extendedGamepad"
        print("Configuring controller profile: \(profile)")

        bind(gamepad.buttonA, to: .a, profile: profile)
        bind(gamepad.buttonB, to: .b, profile: profile)
        bind(gamepad.buttonX, to: .x, profile: profile)
        bind(gamepad.buttonY, to: .y, profile: profile)
        bind(gamepad.leftShoulder, to: .leftShoulder, profile: profile)
        bind(gamepad.rightShoulder, to: .rightShoulder, profile: profile)
        bind(gamepad.leftTrigger, to: .leftTrigger, profile: profile)
        bind(gamepad.rightTrigger, to: .rightTrigger, profile: profile)
        bindDPad(gamepad.dpad, profile: profile)
    }

    private func configureMicroGamepad(_ gamepad: GCMicroGamepad) {
        let profile = "microGamepad"
        print("Configuring controller profile: \(profile)")
        gamepad.reportsAbsoluteDpadValues = true

        bind(gamepad.buttonA, to: .a, profile: profile)
        bind(gamepad.buttonX, to: .x, profile: profile)
        bindDPad(gamepad.dpad, profile: profile)
    }

    private func configurePhysicalInputProfile(_ profile: GCPhysicalInputProfile) {
        let buttonNames = profile.buttons.keys.sorted()
        let dpadNames = profile.dpads.keys.sorted()

        print("Physical input buttons: \(joinedNames(buttonNames))")
        print("Physical input dpads: \(joinedNames(dpadNames))")

        for name in dpadNames {
            guard let dpad = profile.dpads[name] else { continue }
            bindDPad(dpad, profile: "physicalInputProfile.\(name)")
        }

        for name in buttonNames {
            guard
                let input = profile.buttons[name],
                let button = controllerButton(forPhysicalButton: input, name: name)
            else {
                continue
            }

            bind(input, to: button, profile: "physicalInputProfile.\(name)")
        }

        profile.valueDidChangeHandler = { [weak self] _, element in
            DispatchQueue.main.async {
                self?.handlePhysicalInputChange(element)
            }
        }
    }

    private func bind(_ input: GCControllerButtonInput, to button: ControllerButton, profile: String) {
        print("Bound \(profile) button handler: \(button.displayName)")

        input.pressedChangedHandler = { [weak self] _, _, isPressed in
            DispatchQueue.main.async {
                self?.handleButton(button, isPressed: isPressed, profile: profile)
            }
        }

        input.valueChangedHandler = { [weak self] _, value, isPressed in
            DispatchQueue.main.async {
                let formattedValue = String(format: "%.2f", value)
                print("Button value changed [\(profile)]: \(button.displayName), value=\(formattedValue), pressed=\(isPressed)")
                self?.handleButton(button, isPressed: isPressed, profile: "\(profile).value")
            }
        }
    }

    private func bindDPad(_ dpad: GCControllerDirectionPad, profile: String) {
        bind(dpad.up, to: .dpadUp, profile: "\(profile).dpad")
        bind(dpad.down, to: .dpadDown, profile: "\(profile).dpad")
        bind(dpad.left, to: .dpadLeft, profile: "\(profile).dpad")
        bind(dpad.right, to: .dpadRight, profile: "\(profile).dpad")
        bindDPadAxes(dpad, profile: profile)
    }

    private func bindDPadAxes(_ dpad: GCControllerDirectionPad, profile: String) {
        print("Bound \(profile) dpad axis handler")

        dpad.valueChangedHandler = { [weak self] _, xValue, yValue in
            DispatchQueue.main.async {
                self?.handleDPadAxisChange(xValue: xValue, yValue: yValue, profile: profile)
            }
        }
    }

    private func handleDPadAxisChange(xValue: Float, yValue: Float, profile: String) {
        let formattedXValue = String(format: "%.2f", xValue)
        let formattedYValue = String(format: "%.2f", yValue)

        print("DPad axis changed [\(profile)]: x=\(formattedXValue), y=\(formattedYValue)")

        handleButton(.dpadRight, isPressed: xValue > dpadThreshold, profile: "\(profile).dpad.axis")
        handleButton(.dpadLeft, isPressed: xValue < -dpadThreshold, profile: "\(profile).dpad.axis")
        handleButton(.dpadUp, isPressed: yValue > dpadThreshold, profile: "\(profile).dpad.axis")
        handleButton(.dpadDown, isPressed: yValue < -dpadThreshold, profile: "\(profile).dpad.axis")
    }

    private func handlePhysicalInputChange(_ element: GCControllerElement) {
        print("Physical input changed: \(elementDescription(element))")

        if let buttonInput = element as? GCControllerButtonInput {
            if let button = controllerButton(forPhysicalButton: buttonInput, name: nil) {
                handleButton(button, isPressed: buttonInput.isPressed, profile: "physicalInputProfile.raw")
            }

            return
        }

        if let dpad = element as? GCControllerDirectionPad {
            handleDPadAxisChange(
                xValue: dpad.xAxis.value,
                yValue: dpad.yAxis.value,
                profile: "physicalInputProfile.raw.dpad"
            )
            return
        }

        if
            let axis = element as? GCControllerAxisInput,
            let dpad = axis.collection as? GCControllerDirectionPad
        {
            handleDPadAxisChange(
                xValue: dpad.xAxis.value,
                yValue: dpad.yAxis.value,
                profile: "physicalInputProfile.raw.axis"
            )
        }
    }

    private func handleButton(_ button: ControllerButton, isPressed: Bool, profile: String) {
        if isPressed {
            guard !pressedButtons.contains(button) else {
                return
            }

            pressedButtons.insert(button)
            latestPressedButton = button
            print("Button pressed [\(profile)]: \(button.displayName)")
            mappingManager.handleButtonPress(button)
        } else {
            guard pressedButtons.remove(button) != nil else {
                return
            }

            print("Button released [\(profile)]: \(button.displayName)")
            mappingManager.handleButtonRelease(button)
        }
    }

    private func controllerButton(forPhysicalButton input: GCControllerButtonInput, name: String?) -> ControllerButton? {
        if let directionalButton = controllerButton(forDirectionalButton: input) {
            return directionalButton
        }

        if
            usesLeftJoyConDirectionalFaceButtonCorrection,
            let name,
            let correctedButton = leftJoyConDirectionalButton(forInputName: name)
        {
            print("Joy-Con (L) corrected input: \(name) -> \(correctedButton.displayName)")
            return correctedButton
        }

        if let name, let namedButton = controllerButton(forInputName: name) {
            return namedButton
        }

        for alias in input.aliases {
            if
                usesLeftJoyConDirectionalFaceButtonCorrection,
                let correctedButton = leftJoyConDirectionalButton(forInputName: alias)
            {
                print("Joy-Con (L) corrected input alias: \(alias) -> \(correctedButton.displayName)")
                return correctedButton
            }

            if let aliasedButton = controllerButton(forInputName: alias) {
                return aliasedButton
            }
        }

        return nil
    }

    private func controllerButton(forDirectionalButton input: GCControllerButtonInput) -> ControllerButton? {
        guard let dpad = input.collection as? GCControllerDirectionPad else {
            return nil
        }

        if input === dpad.up {
            return .dpadUp
        }

        if input === dpad.down {
            return .dpadDown
        }

        if input === dpad.left {
            return .dpadLeft
        }

        if input === dpad.right {
            return .dpadRight
        }

        return nil
    }

    private func leftJoyConDirectionalButton(forInputName name: String) -> ControllerButton? {
        switch normalizedInputName(name) {
        case "button y", "y":
            return .dpadRight
        case "button x", "x":
            return .dpadDown
        case "button b", "b":
            return .dpadUp
        case "button a", "a":
            return .dpadLeft
        default:
            return nil
        }
    }

    private func controllerButton(forInputName name: String) -> ControllerButton? {
        let normalizedName = normalizedInputName(name)

        if let dpadButton = controllerButton(forDPadInputName: normalizedName) {
            return dpadButton
        }

        switch normalizedName {
        case "button a", "a":
            return .a
        case "button b", "b":
            return .b
        case "button x", "x":
            return .x
        case "button y", "y":
            return .y
        case "left shoulder", "left bumper":
            return .leftShoulder
        case "right shoulder", "right bumper":
            return .rightShoulder
        case "left trigger":
            return .leftTrigger
        case "right trigger":
            return .rightTrigger
        default:
            return nil
        }
    }

    private func controllerButton(forDPadInputName name: String) -> ControllerButton? {
        let mentionsDPad = name.contains("dpad")
            || name.contains("d pad")
            || name.contains("direction pad")
            || name.contains("directional pad")

        guard mentionsDPad else {
            return nil
        }

        if name.contains("up") {
            return .dpadUp
        }

        if name.contains("down") {
            return .dpadDown
        }

        if name.contains("left") {
            return .dpadLeft
        }

        if name.contains("right") {
            return .dpadRight
        }

        return nil
    }

    private func normalizedInputName(_ name: String) -> String {
        name
            .lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
    }

    private func elementDescription(_ element: GCControllerElement) -> String {
        let aliases = element.aliases.sorted().joined(separator: ", ")
        let localizedName = element.localizedName ?? "nil"
        let unmappedLocalizedName = element.unmappedLocalizedName ?? "nil"
        let typeName = String(describing: type(of: element))

        if let buttonInput = element as? GCControllerButtonInput {
            let formattedValue = String(format: "%.2f", buttonInput.value)

            return "\(typeName), aliases=[\(aliases)], localizedName=\(localizedName), " +
                "unmappedLocalizedName=\(unmappedLocalizedName), value=\(formattedValue), " +
                "pressed=\(buttonInput.isPressed)"
        }

        if let axisInput = element as? GCControllerAxisInput {
            let formattedValue = String(format: "%.2f", axisInput.value)

            return "\(typeName), aliases=[\(aliases)], localizedName=\(localizedName), " +
                "unmappedLocalizedName=\(unmappedLocalizedName), value=\(formattedValue)"
        }

        return "\(typeName), aliases=[\(aliases)], localizedName=\(localizedName), " +
            "unmappedLocalizedName=\(unmappedLocalizedName)"
    }

    private func joinedNames(_ names: [String]) -> String {
        names.isEmpty ? "none" : names.joined(separator: ", ")
    }

    private func isLeftJoyCon(_ controller: GCController) -> Bool {
        let vendorName = (controller.vendorName ?? "").lowercased()

        return vendorName.contains("joy-con")
            && (vendorName.contains("(l)") || vendorName.contains("left"))
    }
}
