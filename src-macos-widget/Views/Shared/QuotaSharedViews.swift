import SwiftUI

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
