import SwiftUI
import WidgetKit

struct TerminalQuotaPresentation {
    let mood: QuotaMood

    var coreStatus: String {
        switch mood {
        case .abundant: return "CORE://OVERLOAD"
        case .steady: return "CORE://NOMINAL"
        case .tense: return "CORE://THROTTLED"
        case .critical: return "CORE://CRITICAL"
        case .unavailable: return "NO SIGNAL"
        }
    }

    var showsPercentage: Bool { mood != .unavailable }
    var usesBrokenBar: Bool { mood == .critical }
    var showsPlanBadge: Bool { mood != .unavailable }

    var accent: Color {
        switch mood {
        case .abundant: return Color(red: 0.22, green: 1.0, blue: 0.45)
        case .steady: return Color(red: 0.12, green: 0.78, blue: 0.36)
        case .tense: return Color(red: 0.95, green: 0.77, blue: 0.12)
        case .critical: return Color(red: 1.0, green: 0.22, blue: 0.18)
        case .unavailable: return Color(red: 0.32, green: 0.58, blue: 0.43)
        }
    }
}

struct TerminalQuotaView: View {
    let model: QuotaDisplayModel
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                TerminalMediumQuotaView(model: model)
            default:
                TerminalSmallQuotaView(model: model)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(QuotaAccessibility.summary(theme: .terminal, model: model))
        .containerBackground(Color(red: 0.012, green: 0.035, blue: 0.022), for: .widget)
    }
}

struct TerminalSmallQuotaView: View {
    let model: QuotaDisplayModel

    private var primary: QuotaDisplayWindow {
        model.short.remainingPercent == nil ? model.weekly : model.short
    }

    private var presentation: TerminalQuotaPresentation {
        TerminalQuotaPresentation(mood: primary.mood)
    }

    private var channelName: String {
        model.short.remainingPercent == nil ? "WEEKLY.CH" : "5H.CORE"
    }

    var body: some View {
        ZStack {
            TerminalSurface()

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 5) {
                    Text("SYS:QF-47842")
                    Spacer(minLength: 2)
                    Text(primary.mood == .unavailable ? "× OFFLINE" : "● ONLINE")
                }
                .terminalFont(size: 8, weight: .bold)
                .foregroundStyle(presentation.accent.opacity(0.88))

                Text(presentation.coreStatus)
                    .terminalFont(size: 11, weight: .bold)
                    .foregroundStyle(presentation.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                if presentation.showsPercentage, let percent = primary.remainingPercent {
                    HStack(alignment: .lastTextBaseline, spacing: 5) {
                        Text(QuotaFormatter.percent(percent))
                            .terminalFont(size: 31, weight: .bold)
                            .monospacedDigit()
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.72)
                        Text(channelName)
                            .terminalFont(size: 8, weight: .bold)
                            .foregroundStyle(presentation.accent.opacity(0.75))
                    }
                } else {
                    Text("NO SIGNAL")
                        .terminalFont(size: 22, weight: .bold)
                        .foregroundStyle(presentation.accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                TerminalEnergyBar(
                    percent: primary.remainingPercent,
                    mood: primary.mood,
                    segmentCount: 14
                )
                .frame(height: 10)

                HStack(spacing: 5) {
                    Text("[\(QuotaThemeID.terminal.copy(for: primary.mood).headline)]")
                        .foregroundStyle(presentation.accent)
                    Spacer(minLength: 2)
                    Text(weeklyReadout)
                        .foregroundStyle(Color.white.opacity(0.7))
                }
                .terminalFont(size: 8, weight: .semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

                if model.short.remainingPercent == nil {
                    Text("> 5H.CORE // NO SIGNAL")
                        .terminalFont(size: 8, weight: .bold)
                        .foregroundStyle(Color(red: 0.95, green: 0.77, blue: 0.12))
                        .lineLimit(1)
                }

                CacheStatusLabel(source: model.source, tint: presentation.accent.opacity(0.8))
            }
            .padding(13)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 2)
                .stroke(presentation.accent.opacity(0.58), lineWidth: 1)
                .padding(6)
        }
    }

    private var weeklyReadout: String {
        guard let percent = model.weekly.remainingPercent else { return "WK: NO SIGNAL" }
        return "WK: \(QuotaFormatter.percent(percent))"
    }
}

struct TerminalMediumQuotaView: View {
    let model: QuotaDisplayModel

    private var mainMood: QuotaMood {
        model.short.remainingPercent == nil ? model.weekly.mood : model.short.mood
    }

    private var presentation: TerminalQuotaPresentation {
        TerminalQuotaPresentation(mood: mainMood)
    }

    var body: some View {
        ZStack {
            TerminalSurface()

            HStack(spacing: 15) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("QUOTA://CONTROL_NODE")
                        .terminalFont(size: 9, weight: .bold)
                        .foregroundStyle(presentation.accent.opacity(0.78))
                        .lineLimit(1)

                    Text(presentation.coreStatus)
                        .terminalFont(size: 14, weight: .bold)
                        .foregroundStyle(presentation.accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)

                    Text(QuotaThemeID.terminal.copy(for: mainMood).headline)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Spacer(minLength: 0)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("NODE 127.0.0.1:47842")
                        Text("PROVIDER CODEX // MAC-14")
                    }
                    .terminalFont(size: 8, weight: .medium)
                    .foregroundStyle(Color(red: 0.12, green: 0.78, blue: 0.36).opacity(0.62))

                    VStack(alignment: .leading, spacing: 4) {
                        if presentation.showsPlanBadge {
                            PlanBadge(
                                plan: model.plan,
                                foreground: .black,
                                background: presentation.accent
                            )
                        }
                        CacheStatusLabel(source: model.source, tint: presentation.accent.opacity(0.82))
                            .layoutPriority(1)
                    }
                }
                .frame(width: 137, alignment: .leading)

                VStack(spacing: 9) {
                    TerminalTelemetryRow(identifier: "CORE.5H", window: model.short)
                    TerminalTelemetryRow(identifier: "BUS.WEEKLY", window: model.weekly)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .overlay(alignment: .topTrailing) {
            Text("RX  ▂▄▆█")
                .terminalFont(size: 8, weight: .bold)
                .foregroundStyle(presentation.accent.opacity(0.65))
                .padding(10)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 3)
                .stroke(Color(red: 0.12, green: 0.78, blue: 0.36).opacity(0.48), lineWidth: 1)
                .padding(6)
        }
    }
}

private struct TerminalTelemetryRow: View {
    let identifier: String
    let window: QuotaDisplayWindow

    private var presentation: TerminalQuotaPresentation {
        TerminalQuotaPresentation(mood: window.mood)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 4) {
                Text(identifier)
                    .foregroundStyle(presentation.accent.opacity(0.82))
                Spacer(minLength: 2)
                Text(presentation.coreStatus)
                    .foregroundStyle(presentation.accent)
            }
            .terminalFont(size: 8, weight: .bold)
            .lineLimit(1)
            .minimumScaleFactor(0.68)

            if presentation.showsPercentage, let percent = window.remainingPercent {
                Text(QuotaFormatter.percent(percent))
                    .terminalFont(size: 23, weight: .bold)
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .minimumScaleFactor(0.75)
            } else {
                Text("NO SIGNAL")
                    .terminalFont(size: 15, weight: .bold)
                    .foregroundStyle(presentation.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .minimumScaleFactor(0.72)
            }

            TerminalEnergyBar(
                percent: window.remainingPercent,
                mood: window.mood,
                segmentCount: 18
            )
            .frame(height: 9)

            Text(window.remainingPercent == nil ? "AWAITING SYNC" : QuotaFormatter.resetText(window.resetsAt))
                .terminalFont(size: 8, weight: .medium)
                .foregroundStyle(.white.opacity(0.48))
                .lineLimit(1)
                .minimumScaleFactor(0.68)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color(red: 0.04, green: 0.10, blue: 0.065).opacity(0.72))
        .overlay {
            RoundedRectangle(cornerRadius: 2)
                .stroke(presentation.accent.opacity(0.42), lineWidth: 1)
        }
    }
}

private struct TerminalEnergyBar: View {
    let percent: Double?
    let mood: QuotaMood
    let segmentCount: Int

    private var presentation: TerminalQuotaPresentation {
        TerminalQuotaPresentation(mood: mood)
    }

    private var filledCount: Int {
        guard let percent = QuotaMood.clampedPercent(percent) else { return 0 }
        return min(segmentCount, Int(ceil(percent / 100 * Double(segmentCount))))
    }

    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            ForEach(0..<segmentCount, id: \.self) { index in
                Rectangle()
                    .fill(index < filledCount ? presentation.accent : Color.white.opacity(0.09))
                    .frame(height: segmentHeight(at: index))
                    .offset(y: segmentOffset(at: index))
            }
        }
        .padding(.horizontal, 2)
        .background(Color.black.opacity(0.7))
        .overlay {
            Rectangle().stroke(presentation.accent.opacity(0.34), lineWidth: 1)
        }
    }

    private func segmentHeight(at index: Int) -> CGFloat {
        guard presentation.usesBrokenBar else { return 6 }
        return index.isMultiple(of: 3) ? 3 : 6
    }

    private func segmentOffset(at index: Int) -> CGFloat {
        guard presentation.usesBrokenBar else { return 0 }
        return index.isMultiple(of: 2) ? -2 : 2
    }
}

private struct TerminalSurface: View {
    var body: some View {
        ZStack {
            Color(red: 0.012, green: 0.035, blue: 0.022)
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.22, blue: 0.12).opacity(0.32),
                    Color.clear,
                    Color(red: 0.02, green: 0.12, blue: 0.06).opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            TerminalScanLines()
                .opacity(0.15)
        }
    }
}

private struct TerminalScanLines: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                var y: CGFloat = 3
                while y < geometry.size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                    y += 4
                }
            }
            .stroke(Color(red: 0.32, green: 1.0, blue: 0.48), lineWidth: 0.5)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private extension View {
    func terminalFont(size: CGFloat, weight: Font.Weight) -> some View {
        font(.system(size: size, weight: weight, design: .monospaced))
    }
}

#if DEBUG
private enum TerminalPreviewFixtures {
    static let abundant = model(short: 91, weekly: 88)
    static let tense = model(short: 19, weekly: 27)
    static let critical = model(short: 4, weekly: 7)
    static let waitingForShort = model(short: nil, weekly: 64)
    static let unavailable = model(short: nil, weekly: nil, source: .unavailable(message: nil))

    private static func model(
        short: Double?,
        weekly: Double?,
        source: QuotaSource = .live
    ) -> QuotaDisplayModel {
        let snapshot = ProviderSnapshot(
            provider: "codex",
            displayName: "CODEX",
            plan: "Plus · Long Plan Name",
            shortWindow: short.map { UsageWindow(
                remainingPercent: $0,
                resetsAt: "2026-07-18T10:30:00Z",
                windowSeconds: 18_000
            ) },
            weeklyWindow: weekly.map { UsageWindow(
                remainingPercent: $0,
                resetsAt: "2026-07-21T08:00:00Z",
                windowSeconds: 604_800
            ) },
            resetCredits: nil,
            resetCreditExpiresAt: [],
            updatedAt: "2026-07-18T07:00:00Z",
            status: "ok",
            message: nil
        )
        return QuotaDisplayModel(snapshot: snapshot, source: source)
    }
}

struct TerminalQuotaView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TerminalQuotaView(model: TerminalPreviewFixtures.abundant)
                .previewDisplayName("Terminal Small · Abundant")
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            TerminalQuotaView(model: TerminalPreviewFixtures.tense)
                .previewDisplayName("Terminal Medium · Tense")
                .previewContext(WidgetPreviewContext(family: .systemMedium))
            TerminalQuotaView(model: TerminalPreviewFixtures.critical)
                .previewDisplayName("Terminal Small · Critical")
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            TerminalQuotaView(model: TerminalPreviewFixtures.waitingForShort)
                .previewDisplayName("Terminal Medium · 5H Waiting")
                .previewContext(WidgetPreviewContext(family: .systemMedium))
            TerminalQuotaView(model: TerminalPreviewFixtures.unavailable)
                .previewDisplayName("Terminal Medium · Unavailable")
                .previewContext(WidgetPreviewContext(family: .systemMedium))
        }
    }
}
#endif
