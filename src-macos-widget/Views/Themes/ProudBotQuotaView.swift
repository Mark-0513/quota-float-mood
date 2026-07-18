import SwiftUI
import WidgetKit

enum ProudBotFaceState: Equatable {
    case crowned
    case confident
    case stubborn
    case needsCharge
    case radar
}

enum ProudBotPlanPolicy {
    static let mediumMinimumScaleFactor: CGFloat = 1

    static func mediumLabel(_ plan: String?) -> String {
        let normalized = plan?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        let label = normalized.flatMap { $0.isEmpty ? nil : $0 } ?? "PLAN --"
        guard label.count > 21 else { return label }
        return String(label.prefix(21)) + "…"
    }
}

struct ProudBotQuotaPresentation {
    let mood: QuotaMood

    var headline: String { QuotaThemeID.proudBot.copy(for: mood).headline }
    var detail: String { QuotaThemeID.proudBot.copy(for: mood).detail }
    var showsPercentage: Bool { mood != .unavailable }

    var faceState: ProudBotFaceState {
        switch mood {
        case .abundant: return .crowned
        case .steady: return .confident
        case .tense: return .stubborn
        case .critical: return .needsCharge
        case .unavailable: return .radar
        }
    }

    var showsCrown: Bool { faceState == .crowned }
    var showsSweat: Bool { faceState == .stubborn }
    var showsChargeRequest: Bool { faceState == .needsCharge }
    var usesRadar: Bool { faceState == .radar }

    var accent: Color {
        switch mood {
        case .abundant: return Color(red: 0.38, green: 1.00, blue: 0.77)
        case .steady: return Color(red: 0.22, green: 0.78, blue: 1.00)
        case .tense: return Color(red: 1.00, green: 0.72, blue: 0.17)
        case .critical: return Color(red: 1.00, green: 0.24, blue: 0.31)
        case .unavailable: return Color(red: 0.47, green: 0.60, blue: 0.72)
        }
    }

    var eyeColor: Color {
        mood == .critical ? accent.opacity(0.30) : accent
    }

    var statusCode: String {
        switch mood {
        case .abundant: return "CORE // MAX PRIDE"
        case .steady: return "CORE // HOLDING"
        case .tense: return "CORE // STILL FINE"
        case .critical: return "CORE // CHARGE ME"
        case .unavailable: return "RADAR // NO RETURN"
        }
    }
}

struct ProudBotQuotaView: View {
    let model: QuotaDisplayModel
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                ProudBotMediumQuotaView(model: model)
            default:
                ProudBotSmallQuotaView(model: model)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(QuotaAccessibility.summary(theme: .proudBot, model: model))
        .containerBackground(ProudBotPalette.background, for: .widget)
    }
}

struct ProudBotSmallQuotaView: View {
    let model: QuotaDisplayModel

    private var primary: QuotaDisplayWindow {
        model.short.remainingPercent == nil ? model.weekly : model.short
    }

    private var presentation: ProudBotQuotaPresentation {
        ProudBotQuotaPresentation(mood: primary.mood)
    }

    var body: some View {
        ZStack {
            ProudBotCircuitSurface(accent: presentation.accent)

            VStack(spacing: 5) {
                HStack(spacing: 5) {
                    Text("QF BOT / 042")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundStyle(ProudBotPalette.paper)
                    Spacer(minLength: 2)
                    Circle()
                        .fill(presentation.accent)
                        .frame(width: 6, height: 6)
                    Text(primary.mood == .unavailable ? "SCAN" : "ONLINE")
                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                        .foregroundStyle(presentation.accent)
                }

                ProudBotFace(presentation: presentation)
                    .frame(width: 82, height: 72)

                HStack(alignment: .center, spacing: 7) {
                    if presentation.showsPercentage, let percent = primary.remainingPercent {
                        Text(QuotaFormatter.percent(percent))
                            .font(.system(size: 29, weight: .black, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(ProudBotPalette.paper)
                            .minimumScaleFactor(0.72)
                    } else {
                        Text("SCAN")
                            .font(.system(size: 19, weight: .black, design: .rounded))
                            .foregroundStyle(presentation.accent)
                    }

                    VStack(alignment: .leading, spacing: 0) {
                        Text(presentation.headline)
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(presentation.accent)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                        Text(presentation.statusCode)
                            .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                            .foregroundStyle(ProudBotPalette.paper.opacity(0.48))
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                    }
                    Spacer(minLength: 0)
                }

                Group {
                    if case .unavailable = model.source {
                        CacheStatusLabel(source: model.source, tint: presentation.accent.opacity(0.82))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        HStack(spacing: 5) {
                            Text(weeklySummary)
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundStyle(ProudBotPalette.paper.opacity(0.62))
                                .lineLimit(1)
                            Spacer(minLength: 2)
                            CacheStatusLabel(source: model.source, tint: presentation.accent.opacity(0.82))
                        }
                    }
                }
            }
            .padding(12)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(presentation.accent.opacity(0.42), lineWidth: 1)
                .padding(5)
        }
    }

    private var weeklySummary: String {
        guard let percent = model.weekly.remainingPercent else { return "WK // 雷达未回传" }
        return "WK // \(QuotaFormatter.percent(percent))"
    }
}

struct ProudBotMediumQuotaView: View {
    let model: QuotaDisplayModel

    private var primary: QuotaDisplayWindow {
        model.short.remainingPercent == nil ? model.weekly : model.short
    }

    private var presentation: ProudBotQuotaPresentation {
        ProudBotQuotaPresentation(mood: primary.mood)
    }

    var body: some View {
        ZStack {
            ProudBotCircuitSurface(accent: presentation.accent)

            HStack(spacing: 14) {
                VStack(spacing: 5) {
                    Text("PROUD UNIT // 042")
                        .font(.system(size: 8, weight: .black, design: .monospaced))
                        .foregroundStyle(ProudBotPalette.paper.opacity(0.70))
                        .lineLimit(1)

                    ProudBotFace(presentation: presentation)
                        .frame(width: 118, height: 102)

                    Text(presentation.headline)
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(presentation.accent)
                        .lineLimit(1)
                }
                .frame(width: 128)

                Rectangle()
                    .fill(presentation.accent.opacity(0.25))
                    .frame(width: 1)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 7) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("QUOTA CORE")
                                .font(.system(size: 9, weight: .black, design: .monospaced))
                                .foregroundStyle(ProudBotPalette.paper)
                            if case .unavailable = model.source {
                                CacheStatusLabel(source: model.source, tint: presentation.accent.opacity(0.80))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                HStack(spacing: 5) {
                                    Text(ProudBotPlanPolicy.mediumLabel(model.plan))
                                        .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                                        .foregroundStyle(presentation.accent.opacity(0.82))
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                    Spacer(minLength: 2)
                                    CacheStatusLabel(source: model.source, tint: presentation.accent.opacity(0.80))
                                }
                            }
                        }
                        Spacer(minLength: 2)
                        ProudBotCoreIndicator(presentation: presentation)
                            .frame(width: 25, height: 25)
                    }

                    ProudBotEnergyRow(title: "5H CELL", window: model.short)
                    ProudBotEnergyRow(title: "WEEK CELL", window: model.weekly)

                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 13)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(presentation.accent.opacity(0.42), lineWidth: 1)
                .padding(5)
        }
    }
}

private struct ProudBotEnergyRow: View {
    let title: String
    let window: QuotaDisplayWindow

    private var presentation: ProudBotQuotaPresentation {
        ProudBotQuotaPresentation(mood: window.mood)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(title)
                    .font(.system(size: 8, weight: .black, design: .monospaced))
                    .foregroundStyle(presentation.accent)
                Spacer(minLength: 3)
                Text(QuotaFormatter.percent(window.remainingPercent))
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(ProudBotPalette.paper)
            }

            ProudBotChargeBar(window: window, presentation: presentation)
                .frame(height: 8)

            HStack(spacing: 5) {
                Text(window.remainingPercent == nil ? presentation.headline : QuotaFormatter.resetText(window.resetsAt))
                    .font(.system(size: 7.5, weight: .semibold))
                    .foregroundStyle(ProudBotPalette.paper.opacity(0.47))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Spacer(minLength: 2)
                ProudBotMiniExpression(state: presentation.faceState, color: presentation.accent)
                    .frame(width: 19, height: 11)
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(ProudBotPalette.panel.opacity(0.72))
        .overlay {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(presentation.accent.opacity(0.30), lineWidth: 1)
        }
    }
}

private struct ProudBotFace: View {
    let presentation: ProudBotQuotaPresentation

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let headWidth = size * 0.92
            let headHeight = size * 0.70

            ZStack {
                if presentation.showsCrown {
                    ProudBotCrown()
                        .fill(Color(red: 1.00, green: 0.80, blue: 0.18))
                        .overlay(ProudBotCrown().stroke(ProudBotPalette.background, lineWidth: 1.5))
                        .frame(width: headWidth * 0.52, height: headHeight * 0.36)
                        .offset(y: -headHeight * 0.58)
                } else {
                    ProudBotAntenna(color: presentation.accent)
                        .frame(width: headWidth * 0.34, height: headHeight * 0.35)
                        .offset(y: -headHeight * 0.58)
                }

                HStack(spacing: headWidth * 0.82) {
                    Capsule().fill(presentation.accent.opacity(0.76))
                    Capsule().fill(presentation.accent.opacity(0.76))
                }
                .frame(width: headWidth * 1.08, height: headHeight * 0.26)

                RoundedRectangle(cornerRadius: headHeight * 0.25, style: .continuous)
                    .fill(ProudBotPalette.shell)
                    .frame(width: headWidth, height: headHeight)
                    .overlay {
                        RoundedRectangle(cornerRadius: headHeight * 0.25, style: .continuous)
                            .stroke(presentation.accent, lineWidth: max(2, size * 0.025))
                    }
                    .shadow(color: presentation.accent.opacity(0.20), radius: 8)

                RoundedRectangle(cornerRadius: headHeight * 0.16, style: .continuous)
                    .fill(ProudBotPalette.screen)
                    .frame(width: headWidth * 0.73, height: headHeight * 0.61)

                if presentation.usesRadar {
                    ProudBotRadar(color: presentation.accent)
                        .frame(width: headWidth * 0.49, height: headHeight * 0.49)
                } else {
                    ProudBotExpression(presentation: presentation)
                        .frame(width: headWidth * 0.58, height: headHeight * 0.40)
                }

                if presentation.showsSweat {
                    ProudBotSweatDrop()
                        .fill(Color(red: 0.26, green: 0.78, blue: 1.00))
                        .frame(width: size * 0.13, height: size * 0.18)
                        .offset(x: headWidth * 0.41, y: -headHeight * 0.25)
                }

                if presentation.showsChargeRequest {
                    ProudBotChargeRequest(color: presentation.accent)
                        .frame(width: size * 0.29, height: size * 0.22)
                        .offset(x: headWidth * 0.38, y: headHeight * 0.30)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityHidden(true)
    }
}

private struct ProudBotExpression: View {
    let presentation: ProudBotQuotaPresentation

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack {
                switch presentation.faceState {
                case .crowned:
                    HStack(spacing: width * 0.20) {
                        ProudBotRaisedEye()
                            .stroke(presentation.eyeColor, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                        ProudBotRaisedEye()
                            .stroke(presentation.eyeColor, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                            .scaleEffect(x: -1, y: 1)
                    }
                    .frame(width: width * 0.82, height: height * 0.35)
                    .offset(y: -height * 0.18)
                    ProudBotMouth(state: .crowned)
                        .stroke(presentation.accent, style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round))
                        .frame(width: width * 0.38, height: height * 0.24)
                        .offset(y: height * 0.25)
                case .confident:
                    HStack(spacing: width * 0.24) {
                        Capsule().fill(presentation.eyeColor)
                        Capsule().fill(presentation.eyeColor)
                    }
                    .frame(width: width * 0.72, height: height * 0.13)
                    .offset(y: -height * 0.17)
                    ProudBotMouth(state: .confident)
                        .stroke(presentation.accent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                        .frame(width: width * 0.34, height: height * 0.20)
                        .offset(y: height * 0.24)
                case .stubborn:
                    HStack(spacing: width * 0.23) {
                        Capsule().fill(presentation.eyeColor).rotationEffect(.degrees(12))
                        Capsule().fill(presentation.eyeColor).rotationEffect(.degrees(-12))
                    }
                    .frame(width: width * 0.70, height: height * 0.13)
                    .offset(y: -height * 0.17)
                    ProudBotMouth(state: .stubborn)
                        .stroke(presentation.accent, style: StrokeStyle(lineWidth: 2.7, lineCap: .round, lineJoin: .round))
                        .frame(width: width * 0.42, height: height * 0.20)
                        .offset(y: height * 0.24)
                case .needsCharge:
                    HStack(spacing: width * 0.27) {
                        Circle().fill(presentation.eyeColor)
                        Circle().fill(presentation.eyeColor)
                    }
                    .frame(width: width * 0.63, height: height * 0.13)
                    .offset(y: -height * 0.17)
                    ProudBotMouth(state: .needsCharge)
                        .stroke(presentation.accent.opacity(0.65), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .frame(width: width * 0.27, height: height * 0.18)
                        .offset(y: height * 0.25)
                case .radar:
                    EmptyView()
                }
            }
        }
    }
}

private struct ProudBotRaisedEye: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY * 0.76))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.22))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY * 0.62))
        return path
    }
}

private struct ProudBotMouth: Shape {
    let state: ProudBotFaceState

    func path(in rect: CGRect) -> Path {
        var path = Path()
        switch state {
        case .crowned:
            path.move(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.25))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.25),
                control: CGPoint(x: rect.midX, y: rect.maxY)
            )
        case .confident:
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.midY),
                control: CGPoint(x: rect.midX, y: rect.maxY * 0.80)
            )
        case .stubborn:
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY * 0.68))
            path.addLine(to: CGPoint(x: rect.width * 0.34, y: rect.height * 0.40))
            path.addLine(to: CGPoint(x: rect.width * 0.66, y: rect.height * 0.64))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.height * 0.36))
        case .needsCharge:
            path.addEllipse(in: rect.insetBy(dx: rect.width * 0.12, dy: rect.height * 0.10))
        case .radar:
            break
        }
        return path
    }
}

private struct ProudBotRadar: View {
    let color: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Circle().stroke(color.opacity(0.34), lineWidth: 1)
                Circle().stroke(color.opacity(0.48), lineWidth: 1)
                    .scaleEffect(0.62)
                Circle().fill(color).frame(width: 5, height: 5)
                Path { path in
                    path.move(to: CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2))
                    path.addLine(to: CGPoint(x: proxy.size.width * 0.86, y: proxy.size.height * 0.22))
                }
                .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                Circle()
                    .fill(color)
                    .frame(width: 4, height: 4)
                    .offset(x: proxy.size.width * 0.20, y: -proxy.size.height * 0.12)
            }
        }
    }
}

private struct ProudBotAntenna: View {
    let color: Color

    var body: some View {
        VStack(spacing: 0) {
            Circle().fill(color).frame(width: 7, height: 7)
            Rectangle().fill(color).frame(width: 2)
        }
    }
}

private struct ProudBotCrown: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.10, y: rect.minY + rect.height * 0.18))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.34, y: rect.minY + rect.height * 0.58))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.66, y: rect.minY + rect.height * 0.58))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.90, y: rect.minY + rect.height * 0.18))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct ProudBotSweatDrop: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY * 0.68), control: CGPoint(x: rect.maxX, y: rect.height * 0.38))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY * 0.68), control: CGPoint(x: rect.midX, y: rect.maxY * 1.08))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.height * 0.38))
        path.closeSubpath()
        return path
    }
}

private struct ProudBotChargeRequest: View {
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(ProudBotPalette.screen)
                .overlay(RoundedRectangle(cornerRadius: 3, style: .continuous).stroke(color, lineWidth: 1.5))
            Rectangle().fill(color).frame(width: 3, height: 7).offset(x: 13)
            Image(systemName: "bolt.fill")
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(color)
        }
    }
}

private struct ProudBotCoreIndicator: View {
    let presentation: ProudBotQuotaPresentation

    var body: some View {
        ZStack {
            Circle().stroke(presentation.accent.opacity(0.28), lineWidth: 2)
            Circle().fill(presentation.accent).frame(width: 8, height: 8)
            if presentation.usesRadar {
                Circle().stroke(presentation.accent, lineWidth: 1).scaleEffect(0.65)
            }
        }
        .accessibilityHidden(true)
    }
}

private struct ProudBotChargeBar: View {
    let window: QuotaDisplayWindow
    let presentation: ProudBotQuotaPresentation

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(ProudBotPalette.paper.opacity(0.09))
                Capsule()
                    .fill(presentation.accent)
                    .frame(width: QuotaBarWidth(percent: window.remainingPercent, availableWidth: proxy.size.width))
            }
            .overlay(Capsule().stroke(presentation.accent.opacity(0.28), lineWidth: 1))
        }
    }
}

private struct ProudBotMiniExpression: View {
    let state: ProudBotFaceState
    let color: Color

    var body: some View {
        Group {
            if state == .radar {
                Image(systemName: "radar")
                    .font(.system(size: 9, weight: .bold))
            } else if state == .needsCharge {
                Image(systemName: "battery.0percent")
                    .font(.system(size: 9, weight: .bold))
            } else if state == .stubborn {
                Image(systemName: "drop.fill")
                    .font(.system(size: 8, weight: .bold))
            } else if state == .crowned {
                Image(systemName: "crown.fill")
                    .font(.system(size: 9, weight: .bold))
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 9, weight: .bold))
            }
        }
        .foregroundStyle(color)
        .accessibilityHidden(true)
    }
}

private struct ProudBotCircuitSurface: View {
    let accent: Color

    var body: some View {
        ZStack {
            ProudBotPalette.background
            LinearGradient(
                colors: [accent.opacity(0.11), .clear, Color.black.opacity(0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            GeometryReader { proxy in
                Path { path in
                    path.move(to: CGPoint(x: 0, y: proxy.size.height * 0.22))
                    path.addLine(to: CGPoint(x: proxy.size.width * 0.16, y: proxy.size.height * 0.22))
                    path.addLine(to: CGPoint(x: proxy.size.width * 0.22, y: proxy.size.height * 0.30))
                    path.move(to: CGPoint(x: proxy.size.width, y: proxy.size.height * 0.76))
                    path.addLine(to: CGPoint(x: proxy.size.width * 0.84, y: proxy.size.height * 0.76))
                    path.addLine(to: CGPoint(x: proxy.size.width * 0.78, y: proxy.size.height * 0.68))
                }
                .stroke(accent.opacity(0.22), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            }
        }
        .accessibilityHidden(true)
    }
}

private enum ProudBotPalette {
    static let background = Color(red: 0.035, green: 0.055, blue: 0.10)
    static let shell = Color(red: 0.16, green: 0.20, blue: 0.29)
    static let screen = Color(red: 0.025, green: 0.045, blue: 0.075)
    static let panel = Color(red: 0.075, green: 0.105, blue: 0.17)
    static let paper = Color(red: 0.91, green: 0.95, blue: 0.98)
}

#if DEBUG
private enum ProudBotPreviewFixtures {
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
            plan: "Plus · Super Long Autonomous Robot Plan",
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

struct ProudBotQuotaView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            botPreview(ProudBotPreviewFixtures.abundant, family: .systemSmall, name: "Bot Small · Abundant")
            botPreview(ProudBotPreviewFixtures.steady, family: .systemSmall, name: "Bot Small · Steady")
            botPreview(ProudBotPreviewFixtures.tense, family: .systemSmall, name: "Bot Small · Tense")
            botPreview(ProudBotPreviewFixtures.critical, family: .systemSmall, name: "Bot Small · Critical")
            botPreview(ProudBotPreviewFixtures.unavailable, family: .systemSmall, name: "Bot Small · Unavailable")
            botPreview(ProudBotPreviewFixtures.abundant, family: .systemMedium, name: "Bot Medium · Abundant")
            botPreview(ProudBotPreviewFixtures.steady, family: .systemMedium, name: "Bot Medium · Steady")
            botPreview(ProudBotPreviewFixtures.tense, family: .systemMedium, name: "Bot Medium · Tense")
            botPreview(ProudBotPreviewFixtures.critical, family: .systemMedium, name: "Bot Medium · Critical")
            botPreview(ProudBotPreviewFixtures.unavailable, family: .systemMedium, name: "Bot Medium · Unavailable")
            botPreview(ProudBotPreviewFixtures.missingFiveHour, family: .systemMedium, name: "Bot Medium · 5H Missing")
        }
    }

    private static func botPreview(
        _ model: QuotaDisplayModel,
        family: WidgetFamily,
        name: String
    ) -> some View {
        ProudBotQuotaView(model: model)
            .previewDisplayName(name)
            .previewContext(WidgetPreviewContext(family: family))
    }
}
#endif
