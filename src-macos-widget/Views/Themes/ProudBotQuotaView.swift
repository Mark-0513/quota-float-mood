import SwiftUI

struct ProudBotQuotaView: View {
    let model: QuotaDisplayModel

    var body: some View {
        Text(QuotaFormatter.percent(model.short.remainingPercent ?? model.weekly.remainingPercent))
            .containerBackground(.blue, for: .widget)
    }
}
