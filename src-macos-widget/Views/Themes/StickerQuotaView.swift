import SwiftUI
import WidgetKit

enum StickerMark: Equatable {
    case spark
    case check
    case warning
    case empty
    case lostSignal
}

enum StickerPlanPolicy {
    static let fixedTitleLayoutPriority = 1.0

    static func smallTagText(_ plan: String?) -> String {
        let normalized = plan?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        let label = normalized.flatMap { $0.isEmpty ? nil : $0 } ?? "PLAN --"
        guard label.count > 10 else { return label }
        return String(label.prefix(10)) + "…"
    }
}

struct StickerQuotaPresentation {
    let mood: QuotaMood

    var headline: String { QuotaThemeID.sticker.copy(for: mood).headline }
    var detail: String { QuotaThemeID.sticker.copy(for: mood).detail }
    var showsPercentage: Bool { mood != .unavailable }

    var mark: StickerMark {
        switch mood {
        case .abundant: return .spark
        case .steady: return .check
        case .tense: return .warning
        case .critical: return .empty
        case .unavailable: return .lostSignal
        }
    }

    var rotationDegrees: Double {
        switch mood {
        case .abundant: return -4
        case .steady: return 2
        case .tense: return -3
        case .critical: return 4
        case .unavailable: return -1
        }
    }

    var accent: Color {
        switch mood {
        case .abundant: return Color(red: 0.67, green: 1.00, blue: 0.12)
        case .steady: return Color(red: 0.16, green: 0.92, blue: 1.00)
        case .tense: return Color(red: 1.00, green: 0.88, blue: 0.10)
        case .critical: return Color(red: 1.00, green: 0.20, blue: 0.47)
        case .unavailable: return Color(red: 0.67, green: 0.62, blue: 0.78)
        }
    }

    var secondaryAccent: Color {
        switch mood {
        case .abundant: return Color(red: 1.00, green: 0.20, blue: 0.68)
        case .steady: return Color(red: 0.72, green: 1.00, blue: 0.16)
        case .tense: return Color(red: 1.00, green: 0.27, blue: 0.62)
        case .critical: return Color(red: 1.00, green: 0.78, blue: 0.08)
        case .unavailable: return Color(red: 0.44, green: 0.48, blue: 0.54)
        }
    }
}

struct StickerQuotaView: View {
    let model: QuotaDisplayModel
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                StickerMediumQuotaView(model: model)
            default:
                StickerSmallQuotaView(model: model)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(QuotaAccessibility.summary(theme: .sticker, model: model))
        .containerBackground(StickerPalette.silver, for: .widget)
    }
}

struct StickerSmallQuotaView: View {
    let model: QuotaDisplayModel

    private var primary: QuotaDisplayWindow {
        model.short.remainingPercent == nil ? model.weekly : model.short
    }

    private var presentation: StickerQuotaPresentation {
        StickerQuotaPresentation(mood: primary.mood)
    }

    private var primaryLabel: String {
        model.short.remainingPercent == nil ? "WEEKLY DROP" : "5H DROP"
    }

    var body: some View {
        ZStack {
            StickerSilverSurface(accent: presentation.accent)

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 6) {
                    Text("QF / DROP 042")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(StickerPalette.ink)
                        .fixedSize(horizontal: true, vertical: false)
                        .layoutPriority(StickerPlanPolicy.fixedTitleLayoutPriority)
                    Spacer(minLength: 2)
                    StickerPlanTag(plan: model.plan, color: presentation.secondaryAccent, compact: true)
                        .rotationEffect(.degrees(3))
                }

                HStack(alignment: .center, spacing: 7) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(primaryLabel)
                            .font(.system(size: 8, weight: .black, design: .monospaced))
                            .foregroundStyle(StickerPalette.ink.opacity(0.58))
                        if presentation.showsPercentage, let percent = primary.remainingPercent {
                            Text(QuotaFormatter.percent(percent))
                                .font(.system(size: 39, weight: .black, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(StickerPalette.ink)
                                .minimumScaleFactor(0.72)
                                .lineLimit(1)
                        } else {
                            Text("--")
                                .font(.system(size: 39, weight: .black, design: .rounded))
                                .foregroundStyle(StickerPalette.ink.opacity(0.38))
                        }
                    }

                    Spacer(minLength: 0)
                    StickerMoodMark(presentation: presentation, size: 43)
                        .rotationEffect(.degrees(presentation.rotationDegrees))
                }

                StickerProgressTape(window: primary, presentation: presentation)
                    .frame(height: 9)

                VStack(alignment: .leading, spacing: 2) {
                    Text(presentation.headline)
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(StickerPalette.ink)
                        .lineLimit(1)
                    Text(presentation.detail)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(StickerPalette.ink.opacity(0.62))
                        .lineLimit(1)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(presentation.accent)
                .overlay {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(.white, lineWidth: 2)
                }
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                .rotationEffect(.degrees(presentation.rotationDegrees * 0.45))

                Group {
                    if case .unavailable = model.source {
                        CacheStatusLabel(source: model.source, tint: StickerPalette.ink.opacity(0.65))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        HStack(spacing: 5) {
                            Text(weeklySummary)
                                .font(.system(size: 8, weight: .black, design: .monospaced))
                                .foregroundStyle(StickerPalette.ink.opacity(0.68))
                                .lineLimit(1)
                                .minimumScaleFactor(0.65)
                            Spacer(minLength: 2)
                            CacheStatusLabel(source: model.source, tint: StickerPalette.ink.opacity(0.65))
                        }
                    }
                }
            }
            .padding(13)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.72), lineWidth: 2)
                .padding(5)
        }
    }

    private var weeklySummary: String {
        guard let percent = model.weekly.remainingPercent else { return "WK · 信号走丢" }
        return "WK · \(QuotaFormatter.percent(percent))"
    }
}

struct StickerMediumQuotaView: View {
    let model: QuotaDisplayModel

    private var primary: QuotaDisplayWindow {
        model.short.remainingPercent == nil ? model.weekly : model.short
    }

    private var presentation: StickerQuotaPresentation {
        StickerQuotaPresentation(mood: primary.mood)
    }

    var body: some View {
        ZStack {
            StickerSilverSurface(accent: presentation.accent)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 6) {
                        Text("QUOTA DROP")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .tracking(1.1)
                        Text("#042")
                            .font(.system(size: 8, weight: .black, design: .monospaced))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(presentation.secondaryAccent)
                            .rotationEffect(.degrees(-3))
                    }
                    .foregroundStyle(StickerPalette.ink)

                    HStack(alignment: .center, spacing: 6) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(model.short.remainingPercent == nil ? "WEEKLY" : "5 HOURS")
                                .font(.system(size: 8, weight: .black, design: .monospaced))
                                .foregroundStyle(StickerPalette.ink.opacity(0.55))
                            Text(QuotaFormatter.percent(primary.remainingPercent))
                                .font(.system(size: 39, weight: .black, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(StickerPalette.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        Spacer(minLength: 0)
                        StickerMoodMark(presentation: presentation, size: 46)
                            .rotationEffect(.degrees(presentation.rotationDegrees))
                    }

                    Text(presentation.headline)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(StickerPalette.ink)
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(presentation.accent)
                        .overlay {
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .stroke(.white, lineWidth: 2)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                        .rotationEffect(.degrees(presentation.rotationDegrees * 0.35))

                    HStack(spacing: 5) {
                        StickerPlanTag(plan: model.plan, color: presentation.secondaryAccent)
                        CacheStatusLabel(source: model.source, tint: StickerPalette.ink.opacity(0.66))
                    }
                }
                .frame(width: 135, alignment: .leading)

                VStack(spacing: 9) {
                    StickerWindowCard(title: "5H / NOW", window: model.short, tilt: -1.5)
                    StickerWindowCard(title: "WEEK / TOTAL", window: model.weekly, tilt: 1.5)
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 13)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.72), lineWidth: 2)
                .padding(5)
        }
    }
}

private struct StickerWindowCard: View {
    let title: String
    let window: QuotaDisplayWindow
    let tilt: Double

    private var presentation: StickerQuotaPresentation {
        StickerQuotaPresentation(mood: window.mood)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 8, weight: .black, design: .monospaced))
                Spacer(minLength: 2)
                StickerTinyMark(mark: presentation.mark, color: presentation.accent)
                    .frame(width: 16, height: 16)
            }
            .foregroundStyle(StickerPalette.ink)

            HStack(alignment: .lastTextBaseline, spacing: 5) {
                Text(QuotaFormatter.percent(window.remainingPercent))
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(StickerPalette.ink)
                Spacer(minLength: 2)
                Text(presentation.headline)
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(StickerPalette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            StickerProgressTape(window: window, presentation: presentation)
                .frame(height: 7)

            Text(window.remainingPercent == nil ? presentation.detail : QuotaFormatter.resetText(window.resetsAt))
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(StickerPalette.ink.opacity(0.58))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(.white.opacity(0.88))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(StickerPalette.ink, lineWidth: 1.4)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .rotationEffect(.degrees(tilt))
    }
}

private struct StickerMoodMark: View {
    let presentation: StickerQuotaPresentation
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: size, height: size)
            Circle()
                .fill(presentation.secondaryAccent)
                .frame(width: size - 6, height: size - 6)
            Circle()
                .stroke(StickerPalette.ink, lineWidth: 2)
                .frame(width: size - 10, height: size - 10)
            StickerMarkGlyph(mark: presentation.mark)
                .stroke(StickerPalette.ink, style: StrokeStyle(lineWidth: 2.7, lineCap: .round, lineJoin: .round))
                .frame(width: size * 0.48, height: size * 0.48)
        }
        .shadow(color: StickerPalette.ink.opacity(0.2), radius: 0, x: 2, y: 2)
        .accessibilityHidden(true)
    }
}

private struct StickerTinyMark: View {
    let mark: StickerMark
    let color: Color

    var body: some View {
        ZStack {
            Circle().fill(color)
            StickerMarkGlyph(mark: mark)
                .stroke(StickerPalette.ink, style: StrokeStyle(lineWidth: 1.7, lineCap: .round, lineJoin: .round))
                .padding(4)
        }
        .accessibilityHidden(true)
    }
}

private struct StickerMarkGlyph: Shape {
    let mark: StickerMark

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        switch mark {
        case .spark:
            path.move(to: CGPoint(x: w * 0.50, y: 0))
            path.addLine(to: CGPoint(x: w * 0.62, y: h * 0.37))
            path.addLine(to: CGPoint(x: w, y: h * 0.50))
            path.addLine(to: CGPoint(x: w * 0.62, y: h * 0.63))
            path.addLine(to: CGPoint(x: w * 0.50, y: h))
            path.addLine(to: CGPoint(x: w * 0.38, y: h * 0.63))
            path.addLine(to: CGPoint(x: 0, y: h * 0.50))
            path.addLine(to: CGPoint(x: w * 0.38, y: h * 0.37))
            path.closeSubpath()
        case .check:
            path.move(to: CGPoint(x: w * 0.08, y: h * 0.55))
            path.addLine(to: CGPoint(x: w * 0.40, y: h * 0.84))
            path.addLine(to: CGPoint(x: w * 0.94, y: h * 0.16))
        case .warning:
            path.move(to: CGPoint(x: w * 0.50, y: h * 0.08))
            path.addLine(to: CGPoint(x: w * 0.50, y: h * 0.63))
            path.move(to: CGPoint(x: w * 0.50, y: h * 0.87))
            path.addLine(to: CGPoint(x: w * 0.50, y: h * 0.90))
        case .empty:
            path.addEllipse(in: rect.insetBy(dx: w * 0.08, dy: h * 0.08))
            path.move(to: CGPoint(x: w * 0.20, y: h * 0.80))
            path.addLine(to: CGPoint(x: w * 0.80, y: h * 0.20))
        case .lostSignal:
            path.addArc(
                center: CGPoint(x: w * 0.50, y: h * 0.84),
                radius: w * 0.42,
                startAngle: .degrees(205),
                endAngle: .degrees(335),
                clockwise: false
            )
            path.addArc(
                center: CGPoint(x: w * 0.50, y: h * 0.84),
                radius: w * 0.24,
                startAngle: .degrees(205),
                endAngle: .degrees(335),
                clockwise: false
            )
            path.addEllipse(in: CGRect(x: w * 0.44, y: h * 0.76, width: w * 0.12, height: h * 0.12))
            path.move(to: CGPoint(x: w * 0.12, y: h * 0.12))
            path.addLine(to: CGPoint(x: w * 0.88, y: h * 0.88))
        }
        return path
    }
}

private struct StickerProgressTape: View {
    let window: QuotaDisplayWindow
    let presentation: StickerQuotaPresentation

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(StickerPalette.ink.opacity(0.14))
                Capsule()
                    .fill(presentation.accent)
                    .frame(width: QuotaBarWidth(percent: window.remainingPercent, availableWidth: proxy.size.width))
            }
            .overlay(Capsule().stroke(.white.opacity(0.9), lineWidth: 1.5))
        }
    }
}

private struct StickerPlanTag: View {
    let plan: String?
    let color: Color
    var compact = false

    private var text: String {
        if compact {
            return StickerPlanPolicy.smallTagText(plan)
        }
        let trimmed = plan?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.flatMap { $0.isEmpty ? nil : $0.uppercased() } ?? "PLAN --"
    }

    var body: some View {
        Text(text)
            .font(.system(size: 7, weight: .black, design: .monospaced))
            .foregroundStyle(StickerPalette.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.45)
            .frame(maxWidth: compact ? 54 : nil)
            .padding(.horizontal, 5)
            .padding(.vertical, 3)
            .background(color)
            .overlay(Rectangle().stroke(.white, lineWidth: 1.5))
    }
}

private struct StickerSilverSurface: View {
    let accent: Color

    var body: some View {
        ZStack {
            StickerPalette.silver
            LinearGradient(
                colors: [.white.opacity(0.34), .clear, StickerPalette.ink.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            GeometryReader { proxy in
                Path { path in
                    var x: CGFloat = -proxy.size.height
                    while x < proxy.size.width {
                        path.move(to: CGPoint(x: x, y: proxy.size.height))
                        path.addLine(to: CGPoint(x: x + proxy.size.height, y: 0))
                        x += 22
                    }
                }
                .stroke(accent.opacity(0.08), lineWidth: 6)
            }
        }
        .accessibilityHidden(true)
    }
}

private enum StickerPalette {
    static let silver = Color(red: 0.72, green: 0.75, blue: 0.78)
    static let ink = Color(red: 0.075, green: 0.08, blue: 0.095)
}

#if DEBUG
private enum StickerPreviewFixtures {
    static let abundant = model(short: 86, weekly: 92)
    static let steady = model(short: 47, weekly: 55)
    static let tense = model(short: 18, weekly: 24)
    static let critical = model(short: 5, weekly: 8)
    static let unavailable = model(short: nil, weekly: nil, source: .unavailable(message: nil))
    static let missingFiveHour = model(short: nil, weekly: 64)

    private static func model(
        short: Double?,
        weekly: Double?,
        source: QuotaSource = .live
    ) -> QuotaDisplayModel {
        let snapshot = ProviderSnapshot(
            provider: "codex",
            displayName: "CODEX",
            plan: "Plus · Super Long Collectors Edition Plan",
            shortWindow: short.map {
                UsageWindow(remainingPercent: $0, resetsAt: "2026-07-18T10:30:00Z", windowSeconds: 18_000)
            },
            weeklyWindow: weekly.map {
                UsageWindow(remainingPercent: $0, resetsAt: "2026-07-21T08:00:00Z", windowSeconds: 604_800)
            },
            resetCredits: nil,
            resetCreditExpiresAt: [],
            updatedAt: "2026-07-18T07:00:00Z",
            status: "ok",
            message: nil
        )
        return QuotaDisplayModel(snapshot: snapshot, source: source)
    }
}

struct StickerQuotaView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            stickerPreview(StickerPreviewFixtures.abundant, family: .systemSmall, name: "Sticker Small · Abundant")
            stickerPreview(StickerPreviewFixtures.steady, family: .systemSmall, name: "Sticker Small · Steady")
            stickerPreview(StickerPreviewFixtures.tense, family: .systemSmall, name: "Sticker Small · Tense")
            stickerPreview(StickerPreviewFixtures.critical, family: .systemSmall, name: "Sticker Small · Critical")
            stickerPreview(StickerPreviewFixtures.unavailable, family: .systemSmall, name: "Sticker Small · Unavailable")
            stickerPreview(StickerPreviewFixtures.abundant, family: .systemMedium, name: "Sticker Medium · Abundant")
            stickerPreview(StickerPreviewFixtures.steady, family: .systemMedium, name: "Sticker Medium · Steady")
            stickerPreview(StickerPreviewFixtures.tense, family: .systemMedium, name: "Sticker Medium · Tense")
            stickerPreview(StickerPreviewFixtures.critical, family: .systemMedium, name: "Sticker Medium · Critical")
            stickerPreview(StickerPreviewFixtures.unavailable, family: .systemMedium, name: "Sticker Medium · Unavailable")
            stickerPreview(StickerPreviewFixtures.missingFiveHour, family: .systemMedium, name: "Sticker Medium · 5H Missing")
        }
    }

    private static func stickerPreview(
        _ model: QuotaDisplayModel,
        family: WidgetFamily,
        name: String
    ) -> some View {
        StickerQuotaView(model: model)
            .previewDisplayName(name)
            .previewContext(WidgetPreviewContext(family: family))
    }
}
#endif
