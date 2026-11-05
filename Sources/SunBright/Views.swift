import AppKit
import SwiftUI
import SunBrightCore

@MainActor
struct MenuBarView: View {
    @ObservedObject var model: AppModel
    let openSettings: () -> Void
    let quit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                SunBadge(size: 42)
                VStack(alignment: .leading, spacing: 2) {
                    Text("SunBright").font(.title2.weight(.semibold))
                    Text("A little more daylight.").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }

            HStack(alignment: .top, spacing: 8) {
                Circle().fill(model.isBoosting ? Color.orange : Color.secondary.opacity(0.5))
                    .frame(width: 7, height: 7).padding(.top, 5)
                Text(model.statusMessage).font(.callout).fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)

            Picker("Activation", selection: $model.mode) {
                ForEach(ActivationMode.allCases) { mode in Text(mode.title).tag(mode) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            BrightnessControl(multiplier: $model.settings.multiplier)

            VStack(alignment: .leading, spacing: 10) {
                Text("DISPLAYS").font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                if model.displays.isEmpty {
                    Text("No displays detected").font(.callout).foregroundStyle(.secondary)
                }
                ForEach(model.displays) { display in
                    DisplayRow(display: display)
                }
            }
            .padding(12)
            .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))

            if model.mode == .automatic {
                Text("App rules and your daily schedule can each turn the boost on.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if model.renderingError != nil {
                Button("Try Again", action: model.retryRenderer)
            }
            if !model.shortcutAvailable {
                Text("⌥⌘B is in use by another app. Use the controls above.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Divider()
            HStack {
                Button(action: openSettings) { Label("Settings…", systemImage: "gearshape") }
                Spacer()
                Text("⌥⌘B").font(.caption.monospaced()).foregroundStyle(.secondary)
                    .help("Toggle SunBright globally")
                Button(action: quit) { Image(systemName: "power") }
                    .help("Quit SunBright and remove the brightness boost")
                    .accessibilityLabel("Quit SunBright")
            }
            .buttonStyle(.borderless)
        }
        .padding(20)
        .frame(width: 340)
        .tint(.orange)
    }
}

@MainActor
private struct SunBadge: View {
    let size: CGFloat

    var body: some View {
        Image(systemName: "sun.max.fill")
            .font(.system(size: size * 0.52, weight: .medium))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                LinearGradient(colors: [Color(red: 1, green: 0.74, blue: 0.22), .orange],
                               startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: size * 0.27)
            )
            .accessibilityHidden(true)
    }
}

@MainActor
private struct BrightnessControl: View {
    @Binding var multiplier: Double

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Brightness").font(.callout.weight(.medium))
                Spacer()
                Text(multiplier, format: .percent.precision(.fractionLength(0)))
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .monospacedDigit()
            }
            Slider(value: $multiplier, in: SunBrightSettings.multiplierRange, step: 0.05) {
                Text("Brightness multiplier")
            } minimumValueLabel: {
                Image(systemName: "sun.min")
            } maximumValueLabel: {
                Image(systemName: "sun.max.fill")
            }
            .accessibilityValue("\(Int((multiplier * 100).rounded())) percent")
            Text("Actual brightness follows your display’s available HDR headroom.")
                .font(.caption).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

@MainActor
private struct DisplayRow: View {
    let display: DisplayStatus

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "display").foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(display.name).font(.callout).lineLimit(1)
                Text(display.supportsHDR ? "HDR capable" : "Standard range · boost unavailable")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            if display.effectiveMultiplier > 1.01 {
                Text(display.effectiveMultiplier, format: .percent.precision(.fractionLength(0)))
                    .font(.caption.weight(.semibold)).foregroundStyle(.orange).monospacedDigit()
            }
        }
        .accessibilityElement(children: .combine)
    }
}

@MainActor
struct SettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                SunBadge(size: 48)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Your display, a little brighter.").font(.title2.weight(.semibold))
                    Text("SunBright 0.1 · First light").font(.callout).foregroundStyle(.secondary)
                }
                Spacer()
            }.padding(24)

            TabView {
                general.tabItem { Label("General", systemImage: "sun.max") }
                apps.tabItem { Label("App Rules", systemImage: "app.dashed") }
                schedule.tabItem { Label("Schedule", systemImage: "clock") }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(minWidth: 500, minHeight: 500)
        .tint(.orange)
    }

    private var general: some View {
        Form {
            Section {
                Picker("Activation", selection: $model.mode) {
                    ForEach(ActivationMode.allCases) { mode in Text(mode.title).tag(mode) }
                }
                BrightnessControl(multiplier: $model.settings.multiplier).padding(.vertical, 4)
                Toggle("Only boost on a power adapter", isOn: $model.settings.onlyOnPowerAdapter)
            } footer: {
                Text("SunBright starts off each time you launch it. Your brightness and automation preferences are saved.")
            }
            Section("Keyboard shortcut") {
                LabeledContent("Toggle brightness boost", value: "⌥⌘B")
                Text(model.shortcutAvailable
                     ? "A keyboard toggle overrides automation. Select Auto to resume your rules."
                     : "This shortcut is unavailable, possibly because another app uses it. The menu bar controls still work.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Connected displays") {
                ForEach(model.displays) { DisplayRow(display: $0) }
                if !model.hasHDRDisplay {
                    Text("Connect an HDR-capable display to use the brightness boost.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Section {
                Text("Turning SunBright off or quitting removes its overlays. It does not change your display profile or system brightness setting.")
                    .font(.caption).foregroundStyle(.secondary)
                if let warning = model.preferencesWarning {
                    Text(warning).font(.caption).foregroundStyle(.orange)
                }
            }
        }
        .formStyle(.grouped)
    }

    private var apps: some View {
        VStack(alignment: .leading, spacing: 16) {
            automationNotice
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Brighten your favorite apps").font(.headline)
                    Text("Activate while an enabled app is in the foreground.")
                        .font(.callout).foregroundStyle(.secondary)
                }
                Spacer()
                Button("Add Apps…", action: model.chooseApps)
            }
            if model.settings.apps.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "app.badge").font(.largeTitle).foregroundStyle(.secondary)
                    Text("No app rules yet").font(.headline)
                    Text("Add an app to automatically give it more brightness.")
                        .font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    Button("Choose Apps…", action: model.chooseApps)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach($model.settings.apps) { $app in
                        HStack(spacing: 10) {
                            Toggle(isOn: $app.isEnabled) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(app.name)
                                    Text(app.bundleIdentifier).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Button { model.removeApp(app.bundleIdentifier) } label: {
                                Image(systemName: "minus.circle")
                            }
                            .buttonStyle(.borderless)
                            .help("Remove \(app.name)")
                            .accessibilityLabel("Remove \(app.name)")
                        }.padding(.vertical, 4)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            if let error = model.appSelectionError {
                Text(error).font(.caption).foregroundStyle(.orange)
            }
            Text("Current app: \(model.frontmostAppName)").font(.caption).foregroundStyle(.secondary)
        }
        .padding(20)
    }

    private var schedule: some View {
        VStack(alignment: .leading, spacing: 20) {
            automationNotice
            VStack(alignment: .leading, spacing: 6) {
                Text("Make time for more daylight").font(.headline)
                Text("Run the boost during a daily window, using your Mac’s local time.")
                    .font(.callout).foregroundStyle(.secondary)
            }
            Toggle("Enable daily schedule", isOn: $model.settings.schedule.isEnabled)
            HStack(spacing: 24) {
                DatePicker("From", selection: timeBinding(start: true), displayedComponents: .hourAndMinute)
                DatePicker("Until", selection: timeBinding(start: false), displayedComponents: .hourAndMinute)
            }
            .disabled(!model.settings.schedule.isEnabled)
            .padding(16)
            .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))

            if model.settings.schedule.startMinute == model.settings.schedule.endMinute {
                Text("Choose different start and end times to create a schedule.")
                    .font(.callout).foregroundStyle(.orange)
            } else if model.settings.schedule.startMinute > model.settings.schedule.endMinute {
                Label("This window continues into the next day.", systemImage: "moon")
                    .font(.callout).foregroundStyle(.secondary)
            }
            Text("App rules and the schedule work together: either can enable brightness. Turning SunBright off pauses both.")
                .font(.callout).foregroundStyle(.secondary)
            Spacer()
        }
        .padding(20)
    }

    private var automationNotice: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles").foregroundStyle(.orange)
            Text(model.mode == .automatic ? "Automatic mode is ready" : "Select Auto to run your rules")
                .font(.callout.weight(.medium))
            Spacer()
            if model.mode != .automatic {
                Button("Enable Auto") { model.mode = .automatic }
            }
        }
        .padding(12)
        .background(Color.orange.opacity(0.09), in: RoundedRectangle(cornerRadius: 10))
    }

    private func timeBinding(start: Bool) -> Binding<Date> {
        Binding {
            let minute = start ? model.settings.schedule.startMinute : model.settings.schedule.endMinute
            return Calendar.current.date(from: DateComponents(year: 2001, month: 1, day: 15,
                                                              hour: minute / 60, minute: minute % 60)) ?? Date()
        } set: { date in
            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
            let minute = (components.hour ?? 0) * 60 + (components.minute ?? 0)
            if start { model.settings.schedule.startMinute = minute }
            else { model.settings.schedule.endMinute = minute }
        }
    }
}
