import Combine
import Foundation
import GameController

struct ControllerDevice: Identifiable, Hashable {
    let id: String
    let name: String
    let productCategory: String

    var displayName: String {
        if productCategory.isEmpty || productCategory == name {
            return name
        }

        return "\(name) - \(productCategory)"
    }
}

@MainActor
final class ControllerManager: ObservableObject {
    static let automaticTargetID = "__joybridge_automatic_target__"

    private struct PolledButtonInput {
        let name: String
        let input: GCControllerButtonInput
        let button: ControllerButton?
        let profile: String
    }

    private struct PolledAxisInput {
        let name: String
        let input: GCControllerAxisInput
        let button: ControllerButton?
        let profile: String
    }

    @Published private(set) var connectedControllerName: String?
    @Published private(set) var latestPressedButton: ControllerButton?
    @Published private(set) var availableControllers: [ControllerDevice] = []
    @Published private(set) var selectedTargetControllerID: String?
    @Published private(set) var selectedTargetControllerName: String?

    var isControllerConnected: Bool {
        connectedControllerName != nil
    }

    var isTargetControllerSelected: Bool {
        selectedTargetControllerID != nil
    }

    var isSelectedTargetConnected: Bool {
        guard let selectedTargetControllerID else {
            return true
        }

        return availableControllers.contains { $0.id == selectedTargetControllerID }
    }

    private let mappingManager: MappingManager
    private var activeController: GCController?
    private var notificationObservers: [NSObjectProtocol] = []
    private var pressedButtons = Set<ControllerButton>()
    private var isDiscoveringControllers = false
    private let dpadThreshold: Float = 0.5
    private var usesLeftJoyConDirectionalFaceButtonCorrection = false
    private var physicalInputPollingTimer: Timer?
    private var polledButtonInputs: [PolledButtonInput] = []
    private var polledAxisInputs: [PolledAxisInput] = []
    private var activeDiagnosticButtons = Set<String>()
    private var activeDiagnosticAxes = Set<String>()

    private static let targetControllerIDDefaultsKey = "joybridge.targetControllerID"
    private static let targetControllerNameDefaultsKey = "joybridge.targetControllerName"

    init(mappingManager: MappingManager) {
        self.mappingManager = mappingManager
        selectedTargetControllerID = UserDefaults.standard.string(forKey: Self.targetControllerIDDefaultsKey)
        selectedTargetControllerName = UserDefaults.standard.string(forKey: Self.targetControllerNameDefaultsKey)
        GCController.shouldMonitorBackgroundEvents = true
        setupNotifications()
        scanControllers()
    }

    deinit {
        physicalInputPollingTimer?.invalidate()

        for observer in notificationObservers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func scanControllers() {
        print("Controller scan started")

        let controllers = GCController.controllers()
        updateAvailableControllers(controllers)

        if let controller = controllerForCurrentTarget(in: controllers) {
            configure(controller)
        } else {
            if let selectedTargetControllerName {
                print("Target controller not connected: \(selectedTargetControllerName)")
            }

            clearActiveController()
        }

        startWirelessDiscoveryIfNeeded()
    }

    func selectTargetController(id: String?) {
        if let id {
            let displayName = availableControllers.first { $0.id == id }?.displayName
                ?? selectedTargetControllerName
                ?? id
            selectedTargetControllerID = id
            selectedTargetControllerName = displayName
            UserDefaults.standard.set(id, forKey: Self.targetControllerIDDefaultsKey)
            UserDefaults.standard.set(displayName, forKey: Self.targetControllerNameDefaultsKey)
            print("Target controller selected: \(displayName)")
        } else {
            selectedTargetControllerID = nil
            selectedTargetControllerName = nil
            UserDefaults.standard.removeObject(forKey: Self.targetControllerIDDefaultsKey)
            UserDefaults.standard.removeObject(forKey: Self.targetControllerNameDefaultsKey)
            print("Target controller cleared; automatic controller selection enabled")
        }

        scanControllers()
    }

    func lockCurrentControllerAsTarget() {
        guard let activeController else {
            print("Cannot lock target controller because no controller is active")
            return
        }

        let id = controllerIdentifier(for: activeController)
        selectedTargetControllerID = id
        selectedTargetControllerName = controllerDisplayName(for: activeController)
        UserDefaults.standard.set(id, forKey: Self.targetControllerIDDefaultsKey)
        UserDefaults.standard.set(selectedTargetControllerName, forKey: Self.targetControllerNameDefaultsKey)
        print("Target controller locked: \(selectedTargetControllerName ?? id)")
        scanControllers()
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
                        print("Controller connected notification: \(controller.vendorName ?? "Unknown Controller")")
                    }

                    self.scanControllers()
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

    private func updateAvailableControllers(_ controllers: [GCController]) {
        availableControllers = controllers.map { controller in
            ControllerDevice(
                id: controllerIdentifier(for: controller),
                name: controller.vendorName ?? "Unknown Controller",
                productCategory: controller.productCategory
            )
        }

        if availableControllers.isEmpty {
            print("Available controllers: none")
        } else {
            let names = availableControllers.map(\.displayName).joined(separator: ", ")
            print("Available controllers: \(names)")
        }
    }

    private func controllerForCurrentTarget(in controllers: [GCController]) -> GCController? {
        guard let selectedTargetControllerID else {
            return controllers.first
        }

        return controllers.first { controller in
            controllerIdentifier(for: controller) == selectedTargetControllerID
        }
    }

    private func configure(_ controller: GCController) {
        if let activeController, activeController !== controller {
            clearHandlers(for: activeController)
        }

        stopPhysicalInputPolling()
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
        startPhysicalInputPolling()

        if controller.extendedGamepad == nil && controller.microGamepad == nil {
            print("Controller connected but no supported gamepad profile was available")
        }
    }

    private func handleControllerDisconnected(_ controller: GCController?) {
        guard controller == nil || controller === activeController else {
            scanControllers()
            return
        }

        print("Controller disconnected")
        clearActiveController()
        scanControllers()
    }

    private func clearActiveController() {
        if let activeController {
            clearHandlers(for: activeController)
        }

        stopPhysicalInputPolling()
        mappingManager.releaseAllHeldModifiers()
        activeController = nil
        connectedControllerName = nil
        latestPressedButton = nil
        usesLeftJoyConDirectionalFaceButtonCorrection = false
        pressedButtons.removeAll()
    }

    private func clearHandlers(for controller: GCController) {
        if let gamepad = controller.extendedGamepad {
            clearHandler(for: gamepad.buttonA)
            clearHandler(for: gamepad.buttonB)
            clearHandler(for: gamepad.buttonX)
            clearHandler(for: gamepad.buttonY)
            clearHandler(for: gamepad.leftShoulder)
            clearHandler(for: gamepad.rightShoulder)
            clearHandler(for: gamepad.leftTrigger)
            clearHandler(for: gamepad.rightTrigger)
            clearHandlers(for: gamepad.dpad)
        }

        if let gamepad = controller.microGamepad {
            clearHandler(for: gamepad.buttonA)
            clearHandler(for: gamepad.buttonX)
            clearHandlers(for: gamepad.dpad)
        }

        let profile = controller.physicalInputProfile
        profile.valueDidChangeHandler = nil

        for input in profile.buttons.values {
            clearHandler(for: input)
        }

        for input in profile.axes.values {
            input.valueChangedHandler = nil
        }

        for dpad in profile.dpads.values {
            clearHandlers(for: dpad)
        }
    }

    private func clearHandler(for input: GCControllerButtonInput) {
        input.pressedChangedHandler = nil
        input.valueChangedHandler = nil
    }

    private func clearHandlers(for dpad: GCControllerDirectionPad) {
        dpad.valueChangedHandler = nil
        clearHandler(for: dpad.up)
        clearHandler(for: dpad.down)
        clearHandler(for: dpad.left)
        clearHandler(for: dpad.right)
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
        let axisNames = profile.axes.keys.sorted()
        let dpadNames = profile.dpads.keys.sorted()

        print("Physical input buttons: \(joinedNames(buttonNames))")
        print("Physical input axes: \(joinedNames(axisNames))")
        print("Physical input dpads: \(joinedNames(dpadNames))")

        for name in dpadNames {
            guard let dpad = profile.dpads[name] else { continue }
            bindDPad(dpad, profile: "physicalInputProfile.\(name)")
        }

        for name in axisNames {
            guard let input = profile.axes[name] else {
                continue
            }

            let profileName = "physicalInputProfile.\(name)"
            let button = controllerButton(forInputName: name)

            if shouldPollPhysicalAxis(name: name, button: button) {
                polledAxisInputs.append(
                    PolledAxisInput(
                        name: name,
                        input: input,
                        button: button == .leftTrigger || button == .rightTrigger ? button : nil,
                        profile: profileName
                    )
                )
            }

            if let button, button == .leftTrigger || button == .rightTrigger {
                bindTriggerAxis(input, to: button, profile: profileName)
            } else {
                bindDiagnosticAxis(input, name: name, profile: profileName)
            }
        }

        for name in buttonNames {
            guard let input = profile.buttons[name] else {
                continue
            }

            let profileName = "physicalInputProfile.\(name)"
            let button = controllerButton(forPhysicalButton: input, name: name)

            if shouldPollPhysicalButton(name: name, button: button) {
                polledButtonInputs.append(
                    PolledButtonInput(
                        name: name,
                        input: input,
                        button: button,
                        profile: profileName
                    )
                )
            }

            if let button {
                bind(input, to: button, profile: profileName)
            } else {
                bindDiagnosticButton(input, name: name, profile: profileName)
            }
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

    private func bindDiagnosticButton(_ input: GCControllerButtonInput, name: String, profile: String) {
        print("Bound \(profile) diagnostic button handler: \(name)")

        input.valueChangedHandler = { _, value, isPressed in
            DispatchQueue.main.async {
                let formattedValue = String(format: "%.2f", value)
                print("Unmapped physical button changed [\(profile)]: name=\(name), value=\(formattedValue), pressed=\(isPressed)")
            }
        }

        input.pressedChangedHandler = { _, value, isPressed in
            DispatchQueue.main.async {
                let formattedValue = String(format: "%.2f", value)
                print("Unmapped physical button pressed change [\(profile)]: name=\(name), value=\(formattedValue), pressed=\(isPressed)")
            }
        }
    }

    private func bindTriggerAxis(_ input: GCControllerAxisInput, to button: ControllerButton, profile: String) {
        print("Bound \(profile) trigger axis handler: \(button.displayName)")

        input.valueChangedHandler = { [weak self] _, value in
            DispatchQueue.main.async {
                let formattedValue = String(format: "%.2f", value)
                print("Trigger axis changed [\(profile)]: \(button.displayName), value=\(formattedValue)")
                self?.handleButton(button, isPressed: value > 0.5, profile: "\(profile).axis")
            }
        }
    }

    private func bindDiagnosticAxis(_ input: GCControllerAxisInput, name: String, profile: String) {
        print("Bound \(profile) diagnostic axis handler: \(name)")

        input.valueChangedHandler = { _, value in
            DispatchQueue.main.async {
                let formattedValue = String(format: "%.2f", value)
                print("Unmapped physical axis changed [\(profile)]: name=\(name), value=\(formattedValue)")
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

    private func startPhysicalInputPolling() {
        guard !polledButtonInputs.isEmpty || !polledAxisInputs.isEmpty else {
            return
        }

        physicalInputPollingTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.pollPhysicalInputs()
            }
        }
        physicalInputPollingTimer?.tolerance = 0.01
        print("Physical input polling started")
    }

    private func stopPhysicalInputPolling() {
        physicalInputPollingTimer?.invalidate()
        physicalInputPollingTimer = nil
        polledButtonInputs.removeAll()
        polledAxisInputs.removeAll()
        activeDiagnosticButtons.removeAll()
        activeDiagnosticAxes.removeAll()
    }

    private func pollPhysicalInputs() {
        for item in polledButtonInputs {
            if let button = item.button {
                handleButton(button, isPressed: item.input.isPressed, profile: "\(item.profile).poll")
            } else {
                handleDiagnosticButtonPoll(item)
            }
        }

        for item in polledAxisInputs {
            if let button = item.button {
                handleButton(button, isPressed: item.input.value > 0.5, profile: "\(item.profile).poll")
            } else {
                handleDiagnosticAxisPoll(item)
            }
        }
    }

    private func handleDiagnosticButtonPoll(_ item: PolledButtonInput) {
        let key = item.profile
        let isPressed = item.input.isPressed

        if isPressed {
            guard activeDiagnosticButtons.insert(key).inserted else { return }
        } else {
            guard activeDiagnosticButtons.remove(key) != nil else { return }
        }

        let formattedValue = String(format: "%.2f", item.input.value)
        print("Unmapped physical button poll changed [\(item.profile)]: name=\(item.name), value=\(formattedValue), pressed=\(isPressed)")
    }

    private func handleDiagnosticAxisPoll(_ item: PolledAxisInput) {
        let key = item.profile
        let value = item.input.value
        let isActive = abs(value) > 0.5

        if isActive {
            guard activeDiagnosticAxes.insert(key).inserted else { return }
        } else {
            guard activeDiagnosticAxes.remove(key) != nil else { return }
        }

        let formattedValue = String(format: "%.2f", value)
        print("Unmapped physical axis poll changed [\(item.profile)]: name=\(item.name), value=\(formattedValue), active=\(isActive)")
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

    private func shouldPollPhysicalButton(name: String, button: ControllerButton?) -> Bool {
        if let button {
            return button == .leftShoulder
                || button == .rightShoulder
                || button == .leftTrigger
                || button == .rightTrigger
        }

        let normalizedName = normalizedInputName(name)
        return normalizedName.contains("shoulder") || normalizedName.contains("trigger")
    }

    private func shouldPollPhysicalAxis(name: String, button: ControllerButton?) -> Bool {
        if let button {
            return button == .leftTrigger || button == .rightTrigger
        }

        return normalizedInputName(name).contains("trigger")
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

    private func controllerDisplayName(for controller: GCController) -> String {
        let name = controller.vendorName ?? "Unknown Controller"
        let productCategory = controller.productCategory

        if productCategory.isEmpty || productCategory == name {
            return name
        }

        return "\(name) - \(productCategory)"
    }

    private func controllerIdentifier(for controller: GCController) -> String {
        let vendorName = controller.vendorName ?? "Unknown Controller"
        let profileParts = [
            controller.extendedGamepad == nil ? "noExtended" : "extended",
            controller.microGamepad == nil ? "noMicro" : "micro"
        ]

        return [
            vendorName,
            controller.productCategory,
            profileParts.joined(separator: "+")
        ]
        .joined(separator: "|")
    }

    private func isLeftJoyCon(_ controller: GCController) -> Bool {
        let vendorName = (controller.vendorName ?? "").lowercased()

        return vendorName.contains("joy-con")
            && (vendorName.contains("(l)") || vendorName.contains("left"))
    }
}
