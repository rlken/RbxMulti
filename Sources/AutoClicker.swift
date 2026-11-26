import SwiftUI
import AppKit
import ApplicationServices

// MARK: - Engine

/// A general-purpose auto clicker for accessibility and app testing.
/// Clicks at the current cursor position on a fixed interval.
///
@MainActor
final class AutoClicker: ObservableObject {

    @Published var isRunning = false
    @Published var interval: Double = 1.0        // seconds between clicks
    @Published var clickCount = 0
    @Published var status = "Ready"
    @Published var hasClickPermission = AXIsProcessTrusted() && CGPreflightPostEventAccess()
    @Published var hasInputMonitoring = CGPreflightListenEventAccess()

    /// F6 by default. Change the key code here if you want another hotkey.
    let hotkeyCode: UInt16 = 97
    let hotkeyLabel = "F6"

    private var timer: Timer?
    private var globalMonitor: Any?
    private var localMonitor: Any?

    init() {
        installHotkey()
    }

    deinit {
        timer?.invalidate()
        if let g = globalMonitor { NSEvent.removeMonitor(g) }
        if let l = localMonitor { NSEvent.removeMonitor(l) }
    }

    // MARK: Permissions

    /// Click posting requires Accessibility trust and macOS event-posting authorization.
    func requestClickPermission() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        _ = AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
        _ = CGRequestPostEventAccess()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self else { return }
            self.refreshPermissions()
            guard !self.hasClickPermission,
                  let url = URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility") else { return }
            NSWorkspace.shared.open(url)
        }
    }

    /// The global F6 listener uses the separate macOS Input Monitoring permission.
    func requestInputMonitoring() {
        _ = CGRequestListenEventAccess()
        refreshPermissionsSoon()
    }

    private func refreshPermissionsSoon() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.refreshPermissions()
        }
    }

    func refreshPermissions() {
        hasClickPermission = AXIsProcessTrusted() && CGPreflightPostEventAccess()
        let wasListening = hasInputMonitoring
        hasInputMonitoring = CGPreflightListenEventAccess()
        if hasInputMonitoring && !wasListening { installHotkey() }
    }

    // MARK: Start / stop

    func toggle() {
        isRunning ? stop() : start()
    }

    func start() {
        refreshPermissions()
        guard hasClickPermission else {
            status = "Needs click permission"
            return
        }
        isRunning = true
        status = "Running"
        scheduleTimer()
    }

    func stop(message: String = "Stopped") {
        timer?.invalidate()
        timer = nil
        isRunning = false
        status = message
    }

    func resetCount() {
        clickCount = 0
    }

    /// Call when the interval slider changes so a running clicker picks up the new speed.
    func intervalChanged() {
        if isRunning { scheduleTimer() }
    }

    // MARK: Internals

    private func scheduleTimer() {
        timer?.invalidate()
        let safeInterval = max(interval, 0.05)   // never faster than 20 clicks/sec
        let t = Timer(timeInterval: safeInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func tick() {
        if !AXIsProcessTrusted() || !CGPreflightPostEventAccess() {
            stop(message: "Stopped: click permission was removed")
            return
        }
        click()
    }

    private func click() {
        let position = CGEvent(source: nil)?.location ?? .zero
        for type in [CGEventType.leftMouseDown, .leftMouseUp] {
            CGEvent(mouseEventSource: nil,
                    mouseType: type,
                    mouseCursorPosition: position,
                    mouseButton: .left)?.post(tap: .cghidEventTap)
        }
        clickCount += 1
    }

    private func installHotkey() {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        // Works when another app is in front.
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == self?.hotkeyCode else { return }
            Task { @MainActor in self?.toggle() }
        }
        // Works when this app is in front.
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == self?.hotkeyCode {
                Task { @MainActor in self?.toggle() }
                return nil
            }
            return event
        }
    }
}

// MARK: - UI

/// Drop this view into your existing menu-bar popover or window.
struct AutoClickerView: View {
    @ObservedObject var clicker: AutoClicker

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Text("Auto Clicker").font(.headline)
                Spacer()
                Text(clicker.status)
                    .font(.caption)
                    .foregroundStyle(clicker.isRunning ? .green : .secondary)
                    .lineLimit(1)
            }

            if !clicker.hasClickPermission {
                permissionRow("Accessibility access is needed to post clicks.", button: "Allow", action: clicker.requestClickPermission)
                Text("Enable RbxMulti in Privacy & Security → Accessibility. Reopen the app if needed.")
                    .font(.system(size: 11)).foregroundStyle(LauncherStyle.secondaryText)
            }
            if !clicker.hasInputMonitoring {
                permissionRow("Input Monitoring enables F6 outside this app.", button: "Enable F6", action: clicker.requestInputMonitoring)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Click every \(clicker.interval, specifier: "%.2f") s")
                    .font(.subheadline)
                Slider(value: $clicker.interval, in: 0.05...5.0, step: 0.05)
                    .onChange(of: clicker.interval) { _ in clicker.intervalChanged() }
            }

            HStack {
                Button(clicker.isRunning ? "Stop" : "Start") { clicker.toggle() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                Text("or press \(clicker.hotkeyLabel)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Clicks: \(clicker.clickCount)")
                    .monospacedDigit()
                Button("Reset") { clicker.resetCount() }
                    .buttonStyle(.borderless)
            }

            Text("Clicks at the current pointer position in the active app.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LauncherStyle.surface, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(LauncherStyle.separator, lineWidth: 0.5))
        .onAppear { clicker.refreshPermissions() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            clicker.refreshPermissions()
        }
    }

    private func permissionRow(_ message: String, button: String, action: @escaping () -> Void) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Text(message).font(.system(size: 12)).foregroundStyle(LauncherStyle.secondaryText)
            Spacer(minLength: 8)
            Button(button, action: action).controlSize(.small)
        }
    }
}
