import SwiftUI

extension Color {
    static let balanceTeal = Color(red: 0.13, green: 0.48, blue: 0.46)
    static let balanceBlue = Color(red: 0.32, green: 0.49, blue: 0.68)
    static let balanceCanvas = Color(uiColor: .systemGroupedBackground)
    static let balanceCard = Color(uiColor: .secondarySystemGroupedBackground)
}

struct BalanceCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 18) { content }
            .padding(20).frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.balanceCard, in: RoundedRectangle(cornerRadius: 24))
    }
}

struct SectionEyebrow: View {
    let title: String
    var body: some View { Text(title.uppercased()).font(.caption.weight(.semibold)).tracking(1.6).foregroundStyle(.secondary) }
}

struct RatingSelector: View {
    let metric: Metric
    let value: Int?
    var onSelect: (Int?) -> Void
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(metric.title, systemImage: metric.symbol).font(.headline)
                Spacer(minLength: 4)
                Text(metric.label(value)).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.trailing)
            }
            Text(metric.explanation).font(.caption).foregroundStyle(.secondary)
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { rating in
                    Button { onSelect(value == rating ? nil : rating) } label: {
                        Group {
                            if metric == .mood && !typeSize.isAccessibilitySize {
                                Text(["😞", "😕", "😐", "🙂", "😄"][rating - 1]).font(.title2)
                            } else { Text("\(rating)").font(.body.weight(.semibold)) }
                        }
                        .frame(maxWidth: .infinity, minHeight: 46)
                        .background(value == rating ? Color.balanceTeal.opacity(0.17) : Color.primary.opacity(0.04),
                                    in: RoundedRectangle(cornerRadius: 13))
                        .overlay(RoundedRectangle(cornerRadius: 13).stroke(value == rating ? Color.balanceTeal : .clear, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(metric.title): \(metric.label(rating)), \(rating) von 5")
                    .accessibilityAddTraits(value == rating ? [.isSelected] : [])
                    .accessibilityHint(value == rating ? "Nochmals tippen, um den Wert zu entfernen" : "Bewertung auswählen")
                    .accessibilityIdentifier("rating.\(metric.rawValue).\(rating)")
                }
            }
            HStack(alignment: .top) {
                Text("1 · " + metric.labels[0])
                Spacer(minLength: 12)
                Text("5 · " + metric.labels[4]).multilineTextAlignment(.trailing)
            }.font(.caption2).foregroundStyle(.secondary).accessibilityHidden(true)
        }
    }
}

struct EmptyJournal: View {
    let title: String
    let message: String
    let symbol: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol).font(.largeTitle).foregroundStyle(Color.balanceTeal).padding(.bottom, 4)
            Text(title).font(.headline)
            Text(message).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }.frame(maxWidth: .infinity).padding(.vertical, 28)
    }
}

extension View {
    func journalBackground() -> some View { self.background(Color.balanceCanvas) }
}
