import Foundation

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
        var parts = [name]
        if let percent = window.remainingPercent {
            parts.append("剩余 \(QuotaFormatter.percent(percent))")
            parts.append(theme.copy(for: window.mood).headline)
        } else {
            parts.append(theme.copy(for: .unavailable).headline)
        }

        if window.resetsAt != nil {
            parts.append(QuotaFormatter.resetText(window.resetsAt))
        }
        return parts.joined(separator: "，")
    }
}

private extension QuotaThemeID {
    var displayName: String {
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
