import SwiftUI

enum QuotaAccessibility {
    static func summary(theme: QuotaThemeID, model: QuotaDisplayModel) -> String {
        let plan = model.plan?.trimmingCharacters(in: .whitespacesAndNewlines)
        let planLabel = plan.flatMap { $0.isEmpty ? nil : $0 } ?? "未知"
        var parts = ["\(theme.displayName)，计划 \(planLabel)"]
        parts.append(windowSummary(name: "5 小时额度", window: model.short, theme: theme))
        parts.append(windowSummary(name: "每周额度", window: model.weekly, theme: theme))

        if let sourceText = QuotaFormatter.sourceText(model.source) {
            parts.append(sourceText)
        }
        return parts.joined(separator: "；")
    }

    private static func windowSummary(
        name: String,
        window: QuotaDisplayWindow,
        theme: QuotaThemeID
    ) -> String {
        guard let percent = window.remainingPercent else {
            return "\(name)，\(theme.copy(for: .unavailable).headline)"
        }

        return [
            name,
            "剩余 \(QuotaFormatter.percent(percent))",
            theme.copy(for: window.mood).headline,
            QuotaFormatter.resetText(window.resetsAt)
        ].joined(separator: "，")
    }
}

extension QuotaThemeID {
    fileprivate var displayName: String {
        switch self {
        case .pixel: return "像素闯关机"
        case .terminal: return "赛博终端"
        case .vault: return "财富金库"
        case .blackGold: return "黑金俱乐部"
        case .sticker: return "潮玩贴纸"
        case .proudBot: return "傲娇机器人"
        }
    }
}

func QuotaBarWidth(percent: Double?, availableWidth: CGFloat) -> CGFloat {
    guard availableWidth > 0, let percent = QuotaMood.clampedPercent(percent) else {
        return 0
    }
    return availableWidth * CGFloat(percent / 100)
}

struct PlanBadge: View {
    let plan: String?
    var foreground: Color = .primary
    var background: Color = .secondary.opacity(0.18)

    private var label: String {
        let trimmed = plan?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.flatMap { $0.isEmpty ? nil : $0.uppercased() } ?? "PLAN --"
    }

    var body: some View {
        Text(label)
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundStyle(foreground)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
    }
}

struct CacheStatusLabel: View {
    let source: QuotaSource
    var tint: Color = .secondary

    var body: some View {
        if let text = QuotaFormatter.sourceText(source) {
            Label(text, systemImage: sourceSymbol)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private var sourceSymbol: String {
        switch source {
        case .live: return "checkmark.circle"
        case .cached: return "clock.arrow.circlepath"
        case .unavailable: return "antenna.radiowaves.left.and.right.slash"
        }
    }
}
