import SwiftUI
import WidgetKit

struct PixelQuotaPresentation {
    let mood: QuotaMood

    var headline: String { QuotaThemeID.pixel.copy(for: mood).headline }

    var heartCount: Int {
        switch mood {
        case .abundant: return 3
        case .steady: return 2
        case .tense, .critical: return 1
        case .unavailable: return 0
        }
    }

    var warningSymbol: String {
        switch mood {
        case .abundant: return "★"
        case .steady: return "◆"
        case .tense: return "!"
        case .critical: return "⚠"
        case .unavailable: return "?"
        }
    }

    var accent: Color {
        switch mood {
        case .abundant: return Color(red: 0.35, green: 1.0, blue: 0.45)
        case .steady: return Color(red: 0.20, green: 0.80, blue: 1.0)
        case .tense: return Color(red: 1.0, green: 0.82, blue: 0.16)
        case .critical: return Color(red: 1.0, green: 0.25, blue: 0.24)
        case .unavailable: return Color(red: 0.48, green: 0.52, blue: 0.58)
        }
    }
}

struct PixelQuotaView: View {
    let model: QuotaDisplayModel
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                PixelMediumQuotaView(model: model)
            default:
                PixelSmallQuotaView(model: model)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(QuotaAccessibility.summary(theme: .pixel, model: model))
        .containerBackground(Color(red: 0.055, green: 0.065, blue: 0.10), for: .widget)
    }
}

struct PixelSmallQuotaView: View {
    let model: QuotaDisplayModel

    private var primary: QuotaDisplayWindow {
        model.short.remainingPercent == nil ? model.weekly : model.short
    }

    private var primaryLabel: String {
        model.short.remainingPercent == nil ? "WEEKLY XP" : "5H ENERGY"
    }

    private var presentation: PixelQuotaPresentation {
        PixelQuotaPresentation(mood: primary.mood)
    }

    var body: some View {
        ZStack {
            Color(red: 0.055, green: 0.065, blue: 0.10)

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 6) {
                    Text("PIXEL QUEST")
                        .pixelFont(size: 10, weight: .bold)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Spacer(minLength: 2)
                    Text(presentation.warningSymbol)
                        .pixelFont(size: 14, weight: .bold)
                        .foregroundStyle(presentation.accent)
                }

                HStack(alignment: .lastTextBaseline, spacing: 5) {
                    if let percent = primary.remainingPercent {
                        Text(QuotaFormatter.percent(percent))
                            .pixelFont(size: 32, weight: .bold)
                            .monospacedDigit()
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.72)
                    } else {
                        Text("WAITING\nSERVER")
                            .pixelFont(size: 15, weight: .bold)
                            .foregroundStyle(presentation.accent)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 2)
                    Text(primaryLabel)
                        .pixelFont(size: 8, weight: .bold)
                        .foregroundStyle(presentation.accent)
                        .multilineTextAlignment(.trailing)
                }

                PixelSegmentedBar(
                    percent: primary.remainingPercent,
                    mood: primary.mood,
                    segmentCount: 10
                )
                .frame(height: 13)

                HStack(spacing: 5) {
                    PixelHearts(count: presentation.heartCount, tint: presentation.accent)
                    Text(presentation.headline)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Text("LV.\(levelText)")
                        .pixelFont(size: 8, weight: .bold)
                        .foregroundStyle(presentation.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    if model.short.remainingPercent == nil {
                        Text("5H · WAITING SERVER")
                            .foregroundStyle(Color(red: 1.0, green: 0.82, blue: 0.16))
                    }
                    Text(weeklySummary)
                        .foregroundStyle(.white.opacity(0.72))
                }
                .pixelFont(size: 8, weight: .regular)
                .lineLimit(1)

                CacheStatusLabel(source: model.source, tint: presentation.accent.opacity(0.85))
            }
            .padding(14)
        }
        .overlay {
            Rectangle()
                .stroke(presentation.accent, lineWidth: 5)
        }
        .overlay {
            Rectangle()
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
                .padding(7)
        }
    }

    private var weeklySummary: String {
        guard let percent = model.weekly.remainingPercent else {
            return "WEEKLY · WAITING SERVER"
        }
        return "WEEKLY · \(QuotaFormatter.percent(percent)) XP"
    }

    private var levelText: String {
        guard let percent = primary.remainingPercent else { return "--" }
        return String(Int(percent.rounded()))
    }
}

struct PixelMediumQuotaView: View {
    let model: QuotaDisplayModel

    private var mainMood: QuotaMood {
        model.short.remainingPercent == nil ? model.weekly.mood : model.short.mood
    }

    private var presentation: PixelQuotaPresentation {
        PixelQuotaPresentation(mood: mainMood)
    }

    var body: some View {
        ZStack {
            Color(red: 0.055, green: 0.065, blue: 0.10)

            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 8) {
                    Text("PIXEL QUEST // QUOTA RUN")
                        .pixelFont(size: 11, weight: .bold)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(presentation.warningSymbol)
                        .pixelFont(size: 14, weight: .bold)
                        .foregroundStyle(presentation.accent)
                    Spacer(minLength: 4)
                    PlanBadge(
                        plan: model.plan,
                        foreground: .black,
                        background: presentation.accent
                    )
                }

                HStack(spacing: 10) {
                    PixelStatPanel(title: "5H ENERGY", window: model.short)
                    PixelStatPanel(title: "WEEKLY XP", window: model.weekly)
                }

                HStack(spacing: 7) {
                    PixelHearts(count: presentation.heartCount, tint: presentation.accent)
                    Text(presentation.headline)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                    Text("LV.\(levelText)")
                        .pixelFont(size: 9, weight: .bold)
                        .foregroundStyle(presentation.accent)
                    Spacer(minLength: 2)
                    CacheStatusLabel(source: model.source, tint: presentation.accent.opacity(0.9))
                }
                .lineLimit(1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .overlay {
            Rectangle()
                .stroke(presentation.accent, lineWidth: 5)
        }
        .overlay(alignment: .topTrailing) {
            PixelCornerNotches(color: presentation.accent)
                .padding(7)
        }
    }

    private var levelText: String {
        guard let percent = model.short.remainingPercent ?? model.weekly.remainingPercent else {
            return "--"
        }
        return String(Int(percent.rounded()))
    }
}

private struct PixelStatPanel: View {
    let title: String
    let window: QuotaDisplayWindow

    private var presentation: PixelQuotaPresentation {
        PixelQuotaPresentation(mood: window.mood)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 4) {
                Text(title)
                    .pixelFont(size: 9, weight: .bold)
                    .foregroundStyle(presentation.accent)
                Spacer(minLength: 2)
                Text(presentation.warningSymbol)
                    .pixelFont(size: 10, weight: .bold)
                    .foregroundStyle(presentation.accent)
            }

            if let percent = window.remainingPercent {
                Text(QuotaFormatter.percent(percent))
                    .pixelFont(size: 25, weight: .bold)
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.75)
            } else {
                Text("WAITING SERVER")
                    .pixelFont(size: 12, weight: .bold)
                    .foregroundStyle(presentation.accent)
                    .frame(maxHeight: .infinity, alignment: .center)
                    .minimumScaleFactor(0.75)
            }

            PixelSegmentedBar(percent: window.remainingPercent, mood: window.mood, segmentCount: 12)
                .frame(height: 10)

            Text(window.remainingPercent == nil ? "SYNC PENDING" : QuotaFormatter.resetText(window.resetsAt))
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white.opacity(0.58))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(9)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.055))
        .overlay {
            Rectangle()
                .stroke(presentation.accent.opacity(0.75), lineWidth: 2)
        }
    }
}

private struct PixelSegmentedBar: View {
    let percent: Double?
    let mood: QuotaMood
    let segmentCount: Int

    private var filledCount: Int {
        guard let percent = QuotaMood.clampedPercent(percent) else { return 0 }
        return min(segmentCount, Int(ceil(percent / 100 * Double(segmentCount))))
    }

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<segmentCount, id: \.self) { index in
                Rectangle()
                    .fill(index < filledCount ? presentation.accent : Color.white.opacity(0.12))
            }
        }
        .padding(2)
        .background(Color.black.opacity(0.65))
        .overlay {
            Rectangle().stroke(Color.white.opacity(0.25), lineWidth: 1)
        }
    }

    private var presentation: PixelQuotaPresentation {
        PixelQuotaPresentation(mood: mood)
    }
}

private struct PixelHearts: View {
    let count: Int
    let tint: Color

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { index in
                Text(index < count ? "♥" : "♡")
                    .pixelFont(size: 10, weight: .bold)
                    .foregroundStyle(index < count ? tint : Color.white.opacity(0.28))
            }
        }
        .accessibilityHidden(true)
    }
}

private struct PixelCornerNotches: View {
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            Rectangle().fill(color).frame(width: 5, height: 5)
            Rectangle().fill(color.opacity(0.55)).frame(width: 5, height: 5)
            Rectangle().fill(color.opacity(0.3)).frame(width: 5, height: 5)
        }
    }
}

private extension View {
    func pixelFont(size: CGFloat, weight: Font.Weight) -> some View {
        font(.custom("Monaco", fixedSize: size).weight(weight))
    }
}

#if DEBUG
private enum PixelPreviewFixtures {
    static let abundant = model(short: 86, weekly: 93)
    static let tense = model(short: 18, weekly: 26)
    static let critical = model(short: 5, weekly: 8)
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

struct PixelQuotaView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PixelQuotaView(model: PixelPreviewFixtures.abundant)
                .previewDisplayName("Pixel Small · Abundant")
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            PixelQuotaView(model: PixelPreviewFixtures.tense)
                .previewDisplayName("Pixel Medium · Tense")
                .previewContext(WidgetPreviewContext(family: .systemMedium))
            PixelQuotaView(model: PixelPreviewFixtures.critical)
                .previewDisplayName("Pixel Small · Critical")
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            PixelQuotaView(model: PixelPreviewFixtures.waitingForShort)
                .previewDisplayName("Pixel Medium · 5H Waiting")
                .previewContext(WidgetPreviewContext(family: .systemMedium))
            PixelQuotaView(model: PixelPreviewFixtures.unavailable)
                .previewDisplayName("Pixel Medium · Unavailable")
                .previewContext(WidgetPreviewContext(family: .systemMedium))
        }
    }
}
#endif
