import SwiftUI

struct LocalPhoto: View {
    let name: String
    var thumbnail = true
    let service: ImageStorageService
    @State private var image: UIImage?
    @State private var failed = false
    var body: some View {
        GeometryReader { geometry in
            Group {
                if let image {
                    Image(uiImage: image).resizable().scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height).clipped()
                } else {
                    ZStack {
                        Color.balanceTeal.opacity(0.08)
                        if failed { Image(systemName: "photo.badge.exclamationmark").foregroundStyle(.secondary) }
                        else { ProgressView() }
                    }
                }
            }
        }
        .task(id: "\(name)-\(thumbnail)") {
            image = nil; failed = false
            do {
                let data = try await service.read(name, thumbnail: thumbnail)
                guard !Task.isCancelled else { return }
                image = UIImage(data: data); failed = image == nil
            } catch { if !Task.isCancelled { failed = true } }
        }
        .accessibilityLabel(failed ? "Foto konnte nicht geladen werden" : "Mahlzeitenfoto")
    }
}
