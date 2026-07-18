import SwiftUI
import WidgetKit

struct VaultQuotaPresentation {
    let mood: QuotaMood

    var headline: String { QuotaThemeID.vault.copy(for: mood).headline }
    var detail: String { QuotaThemeID.vault.copy(for: mood).detail }

    var accent: Color {
        switch mood {
        case .abundant: return Color(red: 1.00, green: 0.79, blue: 0.25)
        case .steady: return Color(red: 0.88, green: 0.66, blue: 0.24)
        case .tense: return Color(red: 0.98, green: 0.49, blue: 0.13)
        case .critical: return Color(red: 0.93, green: 0.20, blue: 0.12)
        case .unavailable: return Color(red: 0.55, green: 0.48, blue: 0.36)
        }
    }

    static func coinSegmentCount(for percent: Double?) -> Int {
        guard let percent = QuotaMood.clampedPercent(percent), percent > 0 else { return 0 }
        return min(5, Int(ceil(percent / 20)))
    }
}

struct VaultQuotaView: View {
    let model: QuotaDisplayModel
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                VaultMediumQuotaView(model: model)
            default:
                VaultSmallQuotaView(model: model)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(QuotaAccessibility.summary(theme: .vault, model: model))
        .containerBackground(VaultPalette.background, for: .widget)
    }
}

struct VaultSmallQuotaView: View {
    let model: QuotaDisplayModel

    private var primary: QuotaDisplayWindow {
        model.short.remainingPercent == nil ? model.weekly : model.short
    }

    private var presentation: VaultQuotaPresentation {
        VaultQuotaPresentation(mood: primary.mood)
    }

    private var primaryLabel: String {
        model.short.remainingPercent == nil ? "WEEKLY RESERVE" : "5H RESERVE"
    }

    var body: some View {
        ZStack {
            VaultPalette.background
            VaultRadialGlow(color: presentation.accent)

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 6) {
                    VaultSeal(size: 17, color: presentation.accent)
                    Text("FORTUNE VAULT")
                        .font(.system(size: 10, weight: .black, design: .serif))
                        .tracking(1.1)
                        .foregroundStyle(VaultPalette.ivory)
                        .lineLimit(1)
                    Spacer(minLength: 2)
                }

                HStack(alignment: .center, spacing: 6) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(primaryLabel)
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundStyle(presentation.accent.opacity(0.9))
                            .lineLimit(1)
                        if let percent = primary.remainingPercent {
                            Text(QuotaFormatter.percent(percent))
                                .font(.system(size: 32, weight: .black, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(VaultPalette.ivory)
                                .minimumScaleFactor(0.72)
                        } else {
                            Text("--")
                                .font(.system(size: 32, weight: .black, design: .rounded))
                                .foregroundStyle(presentation.accent)
                        }
                    }

                    Spacer(minLength: 0)
                    VaultCoinStack(
                        segments: VaultQuotaPresentation.coinSegmentCount(
                            for: primary.remainingPercent
                        ),
                        color: presentation.accent
                    )
                    .frame(width: 56, height: 50)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(presentation.headline)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(primary.mood == .critical ? presentation.accent : VaultPalette.ivory)
                        .lineLimit(1)
                    Text(presentation.detail)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(VaultPalette.ivory.opacity(0.62))
                        .lineLimit(1)
                }

                VaultRule(color: presentation.accent)

                Group {
                    if case .unavailable = model.source {
                        CacheStatusLabel(source: model.source, tint: presentation.accent.opacity(0.9))
                            .layoutPriority(1)
                    } else {
                        HStack(spacing: 4) {
                            Text(weeklySummary)
                                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                                .foregroundStyle(VaultPalette.ivory.opacity(0.72))
                                .lineLimit(1)
                                .minimumScaleFactor(0.68)
                            Spacer(minLength: 2)
                            CacheStatusLabel(source: model.source, tint: presentation.accent.opacity(0.9))
                        }
                    }
                }
            }
            .padding(14)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(presentation.accent.opacity(0.42), lineWidth: 1)
                .padding(5)
        }
    }

    private var weeklySummary: String {
        guard let percent = model.weekly.remainingPercent else { return "WEEKLY · 等待入账" }
        return "WEEKLY · \(QuotaFormatter.percent(percent))"
    }
}

struct VaultMediumQuotaView: View {
    let model: QuotaDisplayModel

    private var primary: QuotaDisplayWindow {
        model.short.remainingPercent == nil ? model.weekly : model.short
    }

    private var presentation: VaultQuotaPresentation {
        VaultQuotaPresentation(mood: primary.mood)
    }

    var body: some View {
        ZStack {
            VaultPalette.background
            VaultRadialGlow(color: presentation.accent)

            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 7) {
                        VaultSeal(size: 21, color: presentation.accent)
                        VStack(alignment: .leading, spacing: 0) {
                            Text("FORTUNE VAULT")
                                .font(.system(size: 11, weight: .black, design: .serif))
                                .tracking(1.25)
                            Text("PRIVATE ASSET LEDGER")
                                .font(.system(size: 7, weight: .semibold, design: .monospaced))
                                .foregroundStyle(presentation.accent.opacity(0.78))
                        }
                        .foregroundStyle(VaultPalette.ivory)
                    }

                    HStack(alignment: .bottom, spacing: 8) {
                        VaultCoinStack(
                            segments: VaultQuotaPresentation.coinSegmentCount(
                                for: primary.remainingPercent
                            ),
                            color: presentation.accent
                        )
                        .frame(width: 72, height: 64)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("TOTAL\nRESERVE")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundStyle(presentation.accent)
                                .fixedSize(horizontal: true, vertical: true)
                            Text(QuotaFormatter.percent(primary.remainingPercent))
                                .font(.system(size: 29, weight: .black, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(VaultPalette.ivory)
                                .minimumScaleFactor(0.72)
                        }
                    }

                    Text(presentation.headline)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(primary.mood == .critical ? presentation.accent : VaultPalette.ivory)
                        .lineLimit(1)
                }
                .frame(width: 139, alignment: .leading)

                VaultRule(color: presentation.accent, vertical: true)

                VStack(alignment: .leading, spacing: 8) {
                    Text(model.plan?.uppercased() ?? "PLAN --")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(presentation.accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.38)
                        .allowsTightening(true)

                    VaultLedgerRow(title: "5H LIQUID", window: model.short)
                    VaultLedgerRow(title: "WEEKLY HOLD", window: model.weekly)

                    HStack(spacing: 5) {
                        Text(presentation.detail)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(VaultPalette.ivory.opacity(0.72))
                            .lineLimit(1)
                        Spacer(minLength: 2)
                        CacheStatusLabel(source: model.source, tint: presentation.accent.opacity(0.9))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(presentation.accent.opacity(0.40), lineWidth: 1)
                .padding(5)
        }
    }
}

private struct VaultLedgerRow: View {
    let title: String
    let window: QuotaDisplayWindow

    private var presentation: VaultQuotaPresentation {
        VaultQuotaPresentation(mood: window.mood)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(title)
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(presentation.accent)
                Spacer(minLength: 3)
                Text(QuotaFormatter.percent(window.remainingPercent))
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(VaultPalette.ivory)
            }
            HStack(spacing: 6) {
                Text(QuotaFormatter.resetText(window.resetsAt))
                    .font(.system(size: 7, weight: .regular))
                    .foregroundStyle(VaultPalette.ivory.opacity(0.48))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                Spacer(minLength: 2)
                VaultMiniCoins(
                    segments: VaultQuotaPresentation.coinSegmentCount(for: window.remainingPercent),
                    color: presentation.accent
                )
                .frame(width: 31, height: 15)
            }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 7)
        .background(VaultPalette.ivory.opacity(0.045))
        .overlay {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .stroke(presentation.accent.opacity(0.22), lineWidth: 0.7)
        }
    }
}

private struct VaultCoinStack: View {
    let segments: Int
    let color: Color

    var body: some View {
        GeometryReader { proxy in
            let coinHeight = max(7, proxy.size.height * 0.18)
            let verticalStep = max(6, proxy.size.height * 0.15)

            ZStack(alignment: .bottom) {
                Capsule()
                    .stroke(color.opacity(0.24), style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                    .frame(width: proxy.size.width * 0.82, height: coinHeight)

                ForEach(0..<segments, id: \.self) { index in
                    ZStack(alignment: .top) {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [color.opacity(0.68), color, color.opacity(0.55)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        Capsule()
                            .stroke(Color.white.opacity(0.32), lineWidth: 0.7)
                        Ellipse()
                            .fill(color.opacity(0.95))
                            .frame(height: max(3, coinHeight * 0.38))
                            .overlay(Ellipse().stroke(Color.white.opacity(0.42), lineWidth: 0.6))
                    }
                    .frame(
                        width: proxy.size.width * (0.72 + CGFloat(index) * 0.035),
                        height: coinHeight
                    )
                    .offset(x: index.isMultiple(of: 2) ? -2 : 2, y: -CGFloat(index) * verticalStep)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }
}

private struct VaultMiniCoins: View {
    let segments: Int
    let color: Color

    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(0..<5, id: \.self) { index in
                Capsule()
                    .fill(index < segments ? color : color.opacity(0.12))
                    .overlay(Capsule().stroke(color.opacity(0.38), lineWidth: 0.5))
                    .frame(width: 4, height: 6 + CGFloat(index) * 2)
            }
        }
    }
}

private struct VaultSeal: View {
    let size: CGFloat
    let color: Color

    var body: some View {
        ZStack {
            Circle().stroke(color, lineWidth: 1.5)
            Circle().stroke(color.opacity(0.45), lineWidth: 0.7).padding(3)
            Text("¥")
                .font(.system(size: size * 0.48, weight: .black, design: .serif))
                .foregroundStyle(color)
        }
        .frame(width: size, height: size)
    }
}

private struct VaultRule: View {
    let color: Color
    var vertical = false

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [color.opacity(0.05), color.opacity(0.8), color.opacity(0.05)],
                    startPoint: vertical ? .top : .leading,
                    endPoint: vertical ? .bottom : .trailing
                )
            )
            .frame(width: vertical ? 1 : nil, height: vertical ? nil : 1)
    }
}

private struct VaultRadialGlow: View {
    let color: Color

    var body: some View {
        RadialGradient(
            colors: [color.opacity(0.13), .clear],
            center: .bottomTrailing,
            startRadius: 0,
            endRadius: 150
        )
    }
}

private enum VaultPalette {
    static let background = Color(red: 0.055, green: 0.044, blue: 0.028)
    static let ivory = Color(red: 0.98, green: 0.94, blue: 0.82)
}

#if DEBUG
private enum VaultPreviewFixtures {
    static let abundant = model(short: 92, weekly: 84, plan: "ULTRA ASSET MAXIMUM MEMBERSHIP PLAN")
    static let tense = model(short: 18, weekly: 23)
    static let critical = model(short: 4, weekly: 8)
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

struct VaultQuotaView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VaultQuotaView(model: VaultPreviewFixtures.abundant)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Vault · Abundant · Small")
            VaultQuotaView(model: VaultPreviewFixtures.abundant)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Vault · Long Plan · Medium")
            VaultQuotaView(model: VaultPreviewFixtures.tense)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Vault · Tense · Small")
            VaultQuotaView(model: VaultPreviewFixtures.tense)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Vault · Tense · Medium")
            VaultQuotaView(model: VaultPreviewFixtures.critical)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Vault · Critical · Small")
            VaultQuotaView(model: VaultPreviewFixtures.critical)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Vault · Critical · Medium")
            VaultQuotaView(model: VaultPreviewFixtures.unavailable)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Vault · Unavailable · Small")
            VaultQuotaView(model: VaultPreviewFixtures.unavailable)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Vault · Unavailable · Medium")
        }
    }
}
#endif
