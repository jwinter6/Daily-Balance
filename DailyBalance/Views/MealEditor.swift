import SwiftUI
import PhotosUI
import ImageIO
import AVFoundation

// Separate value drafts ensure cancellation never mutates persisted data.
enum PhotoSource { case camera, library }
struct MealEditorRoute: Identifiable {
    let id = UUID()
    let meal: MealValue
    var source: PhotoSource?
    static func new(day: DayKey, source: PhotoSource? = nil) -> Self {
        let now = Date()
        let time = Calendar.current.dateComponents([.hour, .minute], from: now)
        let date = Calendar.current.date(bySettingHour: time.hour!, minute: time.minute!, second: 0, of: day.date()) ?? day.date()
        return Self(meal: MealValue(day: day, timestamp: date, category: .suggested(at: date), imageName: ""), source: source)
    }
}
struct CameraRoute: Identifiable { let id = UUID() }

struct MealEditor: View {
    let route: MealEditorRoute
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var draft: MealValue
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var preview: UIImage?
    @State private var camera: CameraRoute?
    @State private var libraryOpen = false
    @State private var loading = false
    @State private var saving = false
    @State private var error: String?
    @State private var timestampChanged = false
    init(route: MealEditorRoute) { self.route = route; _draft = State(initialValue: route.meal) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if let preview {
                        Image(uiImage: preview).resizable().scaledToFit().frame(maxHeight: 260)
                            .frame(maxWidth: .infinity).clipShape(RoundedRectangle(cornerRadius: 16))
                    } else if !draft.imageName.isEmpty {
                        LocalPhoto(name: draft.imageName, thumbnail: false, service: store.images)
                            .frame(height: 240).clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        EmptyJournal(title: "Deine Mahlzeit im Bild", message: "Ein Foto genügt für deinen Eintrag.", symbol: "camera")
                    }
                    Button("Foto aufnehmen", systemImage: "camera") { openCamera() }
                    Button("Aus Mediathek wählen", systemImage: "photo.on.rectangle") { libraryOpen = true }
                    if loading { ProgressView("Foto wird vorbereitet …") }
                }
                Section("Details · freiwillig") {
                    Picker("Mahlzeit", selection: $draft.category) {
                        ForEach(MealCategory.allCases) { category in Text(category.rawValue).tag(category) }
                    }
                    DatePicker("Uhrzeit", selection: $draft.timestamp, displayedComponents: .hourAndMinute)
                        .onChange(of: draft.timestamp) { _, _ in timestampChanged = true }
                    TextField("Beschreibung", text: $draft.notes, axis: .vertical).lineLimit(2...5)
                }
                if let error { Section { Text(error).foregroundStyle(.red) } }
                Section {
                    Label("Das Foto bleibt im geschützten App-Speicher. Es wird nicht in deine Mediathek kopiert.", systemImage: "lock.shield")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle(draft.imageName.isEmpty ? "Mahlzeit hinzufügen" : "Mahlzeit bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() }.disabled(saving) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") { Task { await save() } }
                        .disabled(!store.canEdit(draft.day) || saving || loading || (imageData == nil && draft.imageName.isEmpty))
                        .accessibilityIdentifier("saveMeal")
                }
            }
            .disabled(saving || !store.canEdit(draft.day))
            .overlay { if saving { ProgressView("Wird lokal gespeichert …").padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18)) } }
        }
        .interactiveDismissDisabled(saving)
        .photosPicker(isPresented: $libraryOpen, selection: $selectedPhoto, matching: .images, photoLibrary: .shared())
        .sheet(item: $camera) { _ in
            CameraPicker { data in
                imageData = data; preview = UIImage(data: data); camera = nil
            } onCancel: { camera = nil }
            .protectJournal()
        }
        .task(id: selectedPhoto) {
            guard let selectedPhoto else { return }
            loading = true
            defer { loading = false }
            do {
                guard let data = try await selectedPhoto.loadTransferable(type: Data.self) else { throw BalanceError.invalidImage }
                guard !Task.isCancelled else { return }
                guard data.count <= 60_000_000 else { throw BalanceError.photoTooLarge }
                // Display preparation uses ImageIO too, avoiding an unbounded full-resolution decode.
                guard let source = CGImageSourceCreateWithData(data as CFData, nil),
                      let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                        kCGImageSourceCreateThumbnailFromImageAlways: true,
                        kCGImageSourceCreateThumbnailWithTransform: true,
                        kCGImageSourceThumbnailMaxPixelSize: 900
                      ] as CFDictionary) else { throw BalanceError.invalidImage }
                imageData = data; preview = UIImage(cgImage: cg)
            } catch { if !Task.isCancelled { self.error = error.localizedDescription } }
        }
        .task {
            if route.source == .camera { openCamera() }
            if route.source == .library { libraryOpen = true }
        }
    }
    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            error = "Auf diesem Gerät ist keine Kamera verfügbar. Wähle ein Foto aus der Mediathek."
            return
        }
        Task {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            let allowed: Bool
            if status == .notDetermined { allowed = await AVCaptureDevice.requestAccess(for: .video) }
            else { allowed = status == .authorized }
            if allowed { camera = CameraRoute() }
            else { error = "Kamerazugriff ist deaktiviert. Erlaube ihn in den iOS-Einstellungen oder wähle ein Foto aus der Mediathek." }
        }
    }
    private func save() async {
        saving = true
        defer { saving = false }
        do {
            var value = draft
            if timestampChanged {
                value.day = DayKey(value.timestamp)
                value.timeZoneID = TimeZone.current.identifier
            }
            value.notes = value.notes.trimmingCharacters(in: .whitespacesAndNewlines)
            try await store.saveMeal(value, imageData: imageData)
            dismiss()
        } catch { self.error = error.localizedDescription }
    }
}

struct CameraPicker: UIViewControllerRepresentable {
    var onCapture: (Data) -> Void
    var onCancel: () -> Void
    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera; picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(parent: CameraPicker) { self.parent = parent }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.onCancel() }
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            guard let image = info[.originalImage] as? UIImage, let data = image.jpegData(compressionQuality: 0.9) else {
                parent.onCancel(); return
            }
            parent.onCapture(data)
        }
    }
}
