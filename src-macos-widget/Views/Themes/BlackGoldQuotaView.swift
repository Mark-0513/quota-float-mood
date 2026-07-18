import SwiftUI
import WidgetKit

struct BlackGoldQuotaPresentation {
    let mood: QuotaMood

    var headline: String { QuotaThemeID.blackGold.copy(for: mood).headline }
    var detail: String { QuotaThemeID.blackGold.copy(for: mood).detail }
    var memberNumber: String { "NO. QF-042" }
    var interruptsFormalOrder: Bool { mood == .critical }

    var brass: Color {
        switch mood {
        case .critical: return Color(red: 0.91, green: 0.18, blue: 0.13)
        case .unavailable: return Color(red: 0.43, green: 0.39, blue: 0.33)
        default: return Color(red: 0.72, green: 0.52, blue: 0.27)
        }
    }

    var statusCode: String {
        switch mood {
        case .abundant: return "MEMBER IN GOOD STANDING"
        case .steady: return "RESERVE CONTROLLED"
        case .tense: return "PRIVILEGE WATCH"
        case .critical: return "STATUS INTERRUPTED"
        case .unavailable: return "ACCOUNT PENDING"
        }
    }
}

struct BlackGoldQuotaView: View {
    let model: QuotaDisplayModel
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                BlackGoldMediumQuotaView(model: model)
            default:
                BlackGoldSmallQuotaView(model: model)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(QuotaAccessibility.summary(theme: .blackGold, model: model))
        .containerBackground(BlackGoldPalette.background, for: .widget)
    }
}

struct BlackGoldSmallQuotaView: View {
    let model: QuotaDisplayModel

    private var primary: QuotaDisplayWindow {
        model.short.remainingPercent == nil ? model.weekly : model.short
    }

    private var presentation: BlackGoldQuotaPresentation {
        BlackGoldQuotaPresentation(mood: primary.mood)
    }

    var body: some View {
        ZStack {
            BlackGoldCardSurface()

            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .top, spacing: 5) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("BLACK GOLD")
                            .font(.system(size: 10, weight: .semibold, design: .serif))
                            .tracking(1.8)
                            .foregroundStyle(BlackGoldPalette.paper)
                        Text("PRIVATE CLUB")
                            .font(.system(size: 7, weight: .medium, design: .monospaced))
                            .tracking(1.2)
                            .foregroundStyle(presentation.brass)
                    }
                    Spacer(minLength: 1)
                    BlackGoldMonogram(color: presentation.brass)
                }

                BrassRule(color: presentation.brass)

                VStack(alignment: .leading, spacing: 1) {
                    Text(model.short.remainingPercent == nil ? "WEEKLY PRIVILEGE" : "5H PRIVILEGE")
                        .font(.system(size: 7, weight: .semibold, design: .monospaced))
                        .tracking(0.8)
                        .foregroundStyle(BlackGoldPalette.paper.opacity(0.5))
                    Text(QuotaFormatter.percent(primary.remainingPercent))
                        .font(.system(size: 35, weight: .light, design: .serif))
                        .monospacedDigit()
                        .foregroundStyle(BlackGoldPalette.paper)
                        .minimumScaleFactor(0.7)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(presentation.headline)
                        .font(.system(size: 13, weight: .semibold, design: .serif))
                        .foregroundStyle(presentation.interruptsFormalOrder ? presentation.brass : BlackGoldPalette.paper)
                        .lineLimit(1)
                    Text(presentation.statusCode)
                        .font(.system(size: 7, weight: .semibold, design: .monospaced))
                        .tracking(0.5)
                        .foregroundStyle(presentation.brass)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }

                Spacer(minLength: 0)
                Group {
                    if case .unavailable = model.source {
                        CacheStatusLabel(source: model.source, tint: presentation.brass)
                            .layoutPriority(1)
                    } else {
                        HStack(spacing: 5) {
                            Text(presentation.memberNumber)
                                .font(.system(size: 8, weight: .medium, design: .monospaced))
                                .foregroundStyle(BlackGoldPalette.paper.opacity(0.58))
                            Spacer(minLength: 2)
                            CacheStatusLabel(source: model.source, tint: presentation.brass)
                        }
                    }
                }
            }
            .padding(15)

            if presentation.interruptsFormalOrder {
                BlackGoldCriticalInterruption(compact: true)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(presentation.brass.opacity(0.56), lineWidth: 0.8)
                .padding(6)
        }
    }
}

struct BlackGoldMediumQuotaView: View {
    let model: QuotaDisplayModel

    private var primary: QuotaDisplayWindow {
        model.short.remainingPercent == nil ? model.weekly : model.short
    }

    private var presentation: BlackGoldQuotaPresentation {
        BlackGoldQuotaPresentation(mood: primary.mood)
    }

    var body: some View {
        ZStack {
            BlackGoldCardSurface()

            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 7) {
                        BlackGoldMonogram(color: presentation.brass)
                        VStack(alignment: .leading, spacing: 0) {
                            Text("BLACK GOLD")
                                .font(.system(size: 11, weight: .semibold, design: .serif))
                                .tracking(2.0)
                            Text("PRIVATE CLUB")
                                .font(.system(size: 7, weight: .medium, design: .monospaced))
                                .tracking(1.1)
                                .foregroundStyle(presentation.brass)
                        }
                        .foregroundStyle(BlackGoldPalette.paper)
                    }

                    BrassRule(color: presentation.brass)

                    Text(model.plan?.uppercased() ?? "PLAN --")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .tracking(0.5)
                        .foregroundStyle(BlackGoldPalette.paper.opacity(0.60))
                        .lineLimit(2)
                        .minimumScaleFactor(0.62)
                        .frame(height: 18, alignment: .topLeading)

                    Text(presentation.headline)
                        .font(.system(size: 16, weight: .semibold, design: .serif))
                        .foregroundStyle(presentation.interruptsFormalOrder ? presentation.brass : BlackGoldPalette.paper)
                        .lineLimit(1)

                    Text(presentation.memberNumber)
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .tracking(0.9)
                        .foregroundStyle(presentation.brass)
                }
                .frame(width: 125, alignment: .leading)

                Rectangle()
                    .fill(presentation.brass.opacity(0.48))
                    .frame(width: 0.7)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(presentation.statusCode)
                            .font(.system(size: 7, weight: .semibold, design: .monospaced))
                            .tracking(0.75)
                            .foregroundStyle(presentation.brass)
                            .lineLimit(1)
                            .minimumScaleFactor(0.62)
                        Spacer(minLength: 3)
                        Text("EST. 2026")
                            .font(.system(size: 7, weight: .regular, design: .serif))
                            .foregroundStyle(BlackGoldPalette.paper.opacity(0.38))
                    }

                    HStack(spacing: 12) {
                        BlackGoldWindow(title: "5H ACCESS", window: model.short)
                        BlackGoldWindow(title: "WEEKLY", window: model.weekly)
                    }

                    BrassRule(color: presentation.brass)

                    HStack(spacing: 5) {
                        Text(presentation.detail)
                            .font(.system(size: 9, weight: .regular, design: .serif))
                            .foregroundStyle(BlackGoldPalette.paper.opacity(0.64))
                            .lineLimit(1)
                        Spacer(minLength: 2)
                        CacheStatusLabel(source: model.source, tint: presentation.brass)
                    }
                }
            }
            .padding(.horizontal, 17)
            .padding(.vertical, 15)

            if presentation.interruptsFormalOrder {
                BlackGoldCriticalInterruption(compact: false)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(presentation.brass.opacity(0.52), lineWidth: 0.8)
                .padding(6)
        }
    }
}

private struct BlackGoldWindow: View {
    let title: String
    let window: QuotaDisplayWindow

    private var presentation: BlackGoldQuotaPresentation {
        BlackGoldQuotaPresentation(mood: window.mood)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                .tracking(0.5)
                .foregroundStyle(presentation.brass)
            Text(QuotaFormatter.percent(window.remainingPercent))
                .font(.system(size: 29, weight: .light, design: .serif))
                .monospacedDigit()
                .foregroundStyle(BlackGoldPalette.paper)
                .minimumScaleFactor(0.68)
            Text(QuotaFormatter.resetText(window.resetsAt))
                .font(.system(size: 7, weight: .regular, design: .serif))
                .foregroundStyle(BlackGoldPalette.paper.opacity(0.45))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct BlackGoldMonogram: View {
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .stroke(color, lineWidth: 0.9)
                .frame(width: 24, height: 18)
            Text("BG")
                .font(.system(size: 7, weight: .bold, design: .serif))
                .tracking(0.8)
                .foregroundStyle(color)
        }
    }
}

private struct BrassRule: View {
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Rectangle().fill(color.opacity(0.85)).frame(width: 14, height: 0.8)
            Rectangle().fill(color.opacity(0.28)).frame(height: 0.8)
        }
    }
}

private struct BlackGoldCardSurface: View {
    var body: some View {
        ZStack {
            BlackGoldPalette.background
            LinearGradient(
                colors: [.clear, Color.white.opacity(0.035), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Path { path in
                path.move(to: CGPoint(x: 0, y: 46))
                path.addLine(to: CGPoint(x: 230, y: 0))
            }
            .stroke(Color.white.opacity(0.025), lineWidth: 22)
        }
    }
}

private struct BlackGoldCriticalInterruption: View {
    let compact: Bool

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Rectangle()
                    .fill(Color(red: 0.82, green: 0.08, blue: 0.06).opacity(0.78))
                    .frame(width: proxy.size.width * (compact ? 0.88 : 0.58), height: compact ? 3 : 4)
                    .rotationEffect(.degrees(-14))
                    .offset(x: compact ? 12 : 72, y: compact ? 34 : 47)

                Text("PRIVILEGE ALERT")
                    .font(.system(size: compact ? 7 : 8, weight: .black, design: .monospaced))
                    .tracking(1.2)
                    .foregroundStyle(Color(red: 0.96, green: 0.25, blue: 0.18))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(BlackGoldPalette.background.opacity(0.94))
                    .overlay(Rectangle().stroke(Color(red: 0.96, green: 0.25, blue: 0.18), lineWidth: 1))
                    .rotationEffect(.degrees(compact ? -7 : -5))
                    .position(
                        x: proxy.size.width * (compact ? 0.70 : 0.73),
                        y: proxy.size.height * (compact ? 0.72 : 0.77)
                    )
            }
        }
        .allowsHitTesting(false)
    }
}

private enum BlackGoldPalette {
    static let background = Color(red: 0.035, green: 0.034, blue: 0.032)
    static let paper = Color(red: 0.91, green: 0.87, blue: 0.78)
}

#if DEBUG
private enum BlackGoldPreviewFixtures {
    static let abundant = model(short: 94, weekly: 88, plan: "ULTRA EXCLUSIVE INTERNATIONAL MEMBERSHIP PLAN")
    static let tense = model(short: 16, weekly: 22)
    static let critical = model(short: 3, weekly: 7)
    static let unavailable = model(short: nil, weekly: nil, source: .unavailable(message: nil))

    private static func model(
        short: Double?,
        weekly: Double?,
        plan: String = "PLUS",
        source: QuotaSource = .live
    ) -> QuotaDisplayModel {
        QuotaDisplayModel(
            snapshot: ProviderSnapshot(
                provider: "codex",
                displayName: "CODEX",
                plan: plan,
                shortWindow: short.map { UsageWindow(remainingPercent: $0, resetsAt: "2026-07-18T10:30:00Z", windowSeconds: 18_000) },
                weeklyWindow: weekly.map { UsageWindow(remainingPercent: $0, resetsAt: "2026-07-21T08:00:00Z", windowSeconds: 604_800) },
                resetCredits: nil,
                resetCreditExpiresAt: [],
                updatedAt: "2026-07-18T07:00:00Z",
                status: "ok",
                message: nil
            ),
            source: source
        )
    }
}

struct BlackGoldQuotaView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            BlackGoldQuotaView(model: BlackGoldPreviewFixtures.abundant)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Black Gold · Abundant · Small")
            BlackGoldQuotaView(model: BlackGoldPreviewFixtures.abundant)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Black Gold · Long Plan · Medium")
            BlackGoldQuotaView(model: BlackGoldPreviewFixtures.tense)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Black Gold · Tense · Small")
            BlackGoldQuotaView(model: BlackGoldPreviewFixtures.tense)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Black Gold · Tense · Medium")
            BlackGoldQuotaView(model: BlackGoldPreviewFixtures.critical)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Black Gold · Critical · Small")
            BlackGoldQuotaView(model: BlackGoldPreviewFixtures.critical)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Black Gold · Critical · Medium")
            BlackGoldQuotaView(model: BlackGoldPreviewFixtures.unavailable)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Black Gold · Unavailable · Small")
            BlackGoldQuotaView(model: BlackGoldPreviewFixtures.unavailable)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Black Gold · Unavailable · Medium")
        }
    }
}
#endif
