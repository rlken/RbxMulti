import SwiftUI
import AppKit

enum LauncherStyle {
    static let accent = Color(nsColor: .systemPurple)
    static let surface = Color(nsColor: .controlBackgroundColor)
    static let canvas = Color(nsColor: .windowBackgroundColor)
    static let separator = Color(nsColor: .separatorColor)
    static let secondaryText = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(calibratedWhite: 0.70, alpha: 1)
            : NSColor(calibratedWhite: 0.38, alpha: 1)
    })
    static let inset: CGFloat = 24
}

struct AccountRow: View {
    @Binding var item: Instance
    var rename: (String) -> Void
    var close: () -> Void
    @State private var editing = false
    @State private var draft = ""
    @State private var confirmClose = false

    private var status: String {
        if !item.running { return "Player closed" }
        if item.accountCollision { return "Account changed during rejoin" }
        if item.isolationLost { return "Roblox updated · relaunch needed" }
        return item.userID == nil ? "Detecting account…" : "Player running"
    }
    private var statusIcon: String {
        if !item.running { return "circle" }
        return item.accountCollision || item.isolationLost ? "exclamationmark.triangle" : "circle.fill"
    }

    var body: some View {
        HStack(spacing: 14) {
            AsyncImage(url: item.avatarURL) { phase in
                if let image = phase.image { image.resizable().scaledToFill() }
                else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable().scaledToFit().foregroundStyle(LauncherStyle.secondaryText).padding(8)
                }
            }
            .frame(width: 48, height: 48)
            .background(LauncherStyle.canvas)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.name).font(.system(size: 15, weight: .semibold))
                    .lineLimit(1).truncationMode(.middle).help(item.name)
                HStack(spacing: 5) {
                    Image(systemName: statusIcon).font(.system(size: statusIcon == "circle.fill" ? 6 : 11))
                        .foregroundStyle(item.running ? (item.accountCollision || item.isolationLost ? Color.orange : Color.green) : Color.secondary)
                        .accessibilityHidden(true)
                    Text(status).font(.system(size: 12)).foregroundStyle(LauncherStyle.secondaryText)
                        .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if item.running {
                VStack(alignment: .trailing, spacing: 5) {
                    Text(item.started, style: .relative).font(.system(size: 12, weight: .medium)).monospacedDigit()
                    Text("since launch").font(.system(size: 11)).foregroundStyle(LauncherStyle.secondaryText)
                }.frame(width: 100, alignment: .trailing)
                Button("Show") { NSRunningApplication(processIdentifier: item.pid)?.activate(options: [.activateIgnoringOtherApps]) }
                    .controlSize(.regular).help("Bring \(item.name)'s Roblox window forward")
                    .accessibilityLabel("Show \(item.name)'s Roblox window")
            }
            Menu {
                Button("Edit account name…") { draft = item.name; editing = true }
                if item.running {
                    Divider()
                    Button("Close player…", role: .destructive) { confirmClose = true }
                }
            } label: {
                Image(systemName: "ellipsis").frame(width: 24, height: 24)
            }
            .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
            .accessibilityLabel("Options for \(item.name)")
            .popover(isPresented: $editing) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Account name").font(.headline)
                    TextField("Roblox username", text: $draft).textFieldStyle(.roundedBorder)
                        .onSubmit(saveName)
                    Text("Use a Roblox username to look up its public avatar.").font(.caption).foregroundStyle(LauncherStyle.secondaryText)
                    HStack { Spacer(); Button("Cancel") { editing = false }; Button("Save", action: saveName).keyboardShortcut(.defaultAction) }
                }.padding(20).frame(width: 290)
            }
            .alert("Close \(item.name)'s player?", isPresented: $confirmClose) {
                Button("Cancel", role: .cancel) { }
                Button("Close player", role: .destructive, action: close)
            } message: { Text("This ends that Roblox session. Your other players will stay open.") }
        }
        .padding(.horizontal, 18).padding(.vertical, 17)
    }
    private func saveName() {
        let value = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        item.name = value
        rename(value)
        editing = false
    }
}

struct ContentView: View {
    @ObservedObject var model: Model
    var hide: () -> Void
    @State private var page = 0
    @State private var showGuide = false
    @State private var confirmCloseAll = false
    @State private var confirmRestore = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !model.handlerOK { linkWarning }
                    if page == 0 {
                        if showGuide || model.items.isEmpty { guide }
                        if !model.items.isEmpty { accounts }
                    } else { activity }
                }
                .padding(LauncherStyle.inset)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            footer
        }
        .background(LauncherStyle.canvas)
        .tint(LauncherStyle.accent)
        .frame(minWidth: 620, minHeight: 480)
        .alert("Close all Roblox players?", isPresented: $confirmCloseAll) {
            Button("Cancel", role: .cancel) { }
            Button("Close all players", role: .destructive) { model.closeAll() }
        } message: { Text("This ends all \(model.runningCount) running sessions. Hiding RbxMulti keeps them open instead.") }
        .alert("Send Play links directly to Roblox?", isPresented: $confirmRestore) {
            Button("Cancel", role: .cancel) { }
            Button("Restore Roblox links") { model.restoreLinks() }
        } message: { Text("New Play clicks will bypass RbxMulti until you enable its link handling again. Existing players stay open.") }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your accounts").font(.system(size: 25, weight: .bold))
                    Text("\(model.runningCount) \(model.runningCount == 1 ? "player" : "players") running on this Mac")
                        .font(.system(size: 13)).foregroundStyle(LauncherStyle.secondaryText)
                }
                Spacer()
                Button(action: hide) { Label("Hide", systemImage: "rectangle.compress.vertical") }
                    .help("Keep RbxMulti running in the menu bar").keyboardShortcut("h", modifiers: .command)
                Button { showGuide.toggle(); page = 0 } label: { Label("Add account", systemImage: "plus") }
                    .buttonStyle(.borderedProminent)
            }
            HStack {
                Picker("View", selection: $page) {
                    Text("Accounts").tag(0)
                    Text("Activity").tag(1)
                }.pickerStyle(.segmented).labelsHidden().frame(width: 210)
                Spacer()
                Label(model.handlerOK ? "Play links ready" : "Link setup needed",
                      systemImage: model.handlerOK ? "link" : "exclamationmark.triangle")
                    .font(.system(size: 12)).foregroundStyle(LauncherStyle.secondaryText)
            }
        }.padding(LauncherStyle.inset)
    }

    private var accounts: some View {
        VStack(spacing: 0) {
            ForEach($model.items) { $item in
                AccountRow(item: $item, rename: { model.resolveUsername(for: item.id, username: $0) }, close: { model.close(item) })
                if item.id != model.items.last?.id { Divider().padding(.leading, 80) }
            }
        }
        .background(LauncherStyle.surface, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(LauncherStyle.separator, lineWidth: 0.5))
    }

    private var guide: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(model.items.isEmpty ? "Start with your first account" : "Add another account")
                .font(.system(size: 17, weight: .semibold))
            Text("Sign in on roblox.com, choose your game, then press Play. To add another player, switch accounts in the browser and press Play again.")
                .font(.system(size: 13)).foregroundStyle(LauncherStyle.secondaryText).fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 12) {
                Button("Open roblox.com") { NSWorkspace.shared.open(URL(string: "https://www.roblox.com")!) }
                if !model.items.isEmpty { Button("Done") { showGuide = false } }
            }
        }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
            .background(LauncherStyle.surface, in: RoundedRectangle(cornerRadius: 14))
    }

    private var linkWarning: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle").foregroundStyle(.orange).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text("Play links are bypassing RbxMulti").font(.system(size: 13, weight: .semibold))
                Text("Enable link handling to open separate players from your browser.").font(.caption).foregroundStyle(LauncherStyle.secondaryText)
            }
            Spacer()
            Button("Enable") { model.claimLinks() }
        }.padding(16).background(LauncherStyle.surface, in: RoundedRectangle(cornerRadius: 12))
    }

    private var activity: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recent activity").font(.system(size: 17, weight: .semibold))
            Text("Launch events and account changes. Game connection status is not monitored.")
                .font(.system(size: 12)).foregroundStyle(LauncherStyle.secondaryText)
            if model.log.isEmpty {
                Text("No events yet. Your next Play click will appear here.").foregroundStyle(LauncherStyle.secondaryText).padding(.vertical, 20)
            } else {
                ForEach(Array(model.log.reversed().enumerated()), id: \.offset) { _, entry in
                    Text(entry).font(.system(size: 12, design: .monospaced))
                        .textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
                    Divider()
                }
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 14) {
            Divider()
            HStack(spacing: 12) {
                Image(systemName: "moon.zzz").font(.system(size: 18)).foregroundStyle(LauncherStyle.secondaryText).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Keep Mac awake").font(.system(size: 13, weight: .medium))
                    Text("Prevents idle sleep while RbxMulti runs.").font(.system(size: 12)).foregroundStyle(LauncherStyle.secondaryText)
                }
                Spacer()
                Toggle("Keep Mac awake", isOn: $model.keepMacAwake).labelsHidden().toggleStyle(.switch).controlSize(.small)
                Menu {
                    Button("Clear closed players") { model.items.removeAll { !$0.running } }
                        .disabled(!model.items.contains { !$0.running })
                    Button("Restore Roblox links…") { confirmRestore = true }
                    Divider()
                    Button("Close all players…", role: .destructive) { confirmCloseAll = true }.disabled(model.runningCount == 0)
                } label: { Image(systemName: "gearshape").frame(width: 28, height: 28) }
                    .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize().accessibilityLabel("Launcher settings")
            }
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "menubar.rectangle").accessibilityHidden(true)
                Text("Closing this window keeps RbxMulti in the menu bar.")
            }.font(.system(size: 11)).foregroundStyle(LauncherStyle.secondaryText)
            if !model.message.isEmpty {
                Text(model.message).font(.system(size: 12)).foregroundStyle(LauncherStyle.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }.padding(.horizontal, LauncherStyle.inset).padding(.bottom, 18)
    }
}
