import AVFoundation
import SwiftUI
import UIKit
import UniformTypeIdentifiers
import UserNotifications
import Vision

@MainActor enum TimerService {
  private static var revisions: [UUID: UUID] = [:]
  static func schedule(_ timer: CookingTimer, requestPermission: Bool) async throws -> Bool {
    let center = UNUserNotificationCenter.current()
    if let old = revisions[timer.id] {
      center.removePendingNotificationRequests(withIdentifiers: [
        "hc-\(timer.id.uuidString)-\(old.uuidString)"
      ])
    }
    let revision = UUID()
    revisions[timer.id] = revision
    let identifier = "hc-\(timer.id.uuidString)-\(revision.uuidString)"
    var settings = await center.notificationSettings()
    if settings.authorizationStatus == .notDetermined && requestPermission {
      _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])
      settings = await center.notificationSettings()
    }
    guard revisions[timer.id] == revision else { return true }
    guard
      settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    else { return false }
    let remaining = timer.endDate.timeIntervalSinceNow
    guard remaining > 0, !timer.acknowledged else { return true }
    let content = UNMutableNotificationContent()
    content.title = "C’est prêt !"
    content.body = timer.name
    content.sound = .default
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, remaining), repeats: false)
    try await center.add(
      UNNotificationRequest(
        identifier: identifier, content: content, trigger: trigger))
    if revisions[timer.id] != revision {
      center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    return true
  }
  static func cancel(_ id: UUID) {
    let previous = revisions[id]
    revisions[id] = UUID()
    let center = UNUserNotificationCenter.current()
    var ids = ["hc-" + id.uuidString]
    if let previous { ids.append("hc-\(id.uuidString)-\(previous.uuidString)") }
    center.removePendingNotificationRequests(withIdentifiers: ids)
    center.removeDeliveredNotifications(withIdentifiers: ids)
  }
  static func synchronize(_ currentTimers: @escaping @MainActor () -> [CookingTimer]) async {
    let center = UNUserNotificationCenter.current()
    let pending = await center.pendingNotificationRequests()
    let timers = currentTimers().filter { !$0.acknowledged && $0.endDate > Date() }
    // Remove only the captured requests before recreating notifications from live state.
    // This also replaces identifiers from a previous launch without duplicating alerts.
    center.removePendingNotificationRequests(
      withIdentifiers: pending.filter { $0.identifier.hasPrefix("hc-") }.map(\.identifier))
    for timer in timers {
      guard currentTimers().contains(where: { $0.id == timer.id }) else { continue }
      _ = try? await schedule(timer, requestPermission: false)
      if !currentTimers().contains(where: { $0.id == timer.id }) { cancel(timer.id) }
    }
  }
}
final class NotificationDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate
{
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    return true
  }
  func userNotificationCenter(
    _ center: UNUserNotificationCenter, willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) { completionHandler([.banner, .sound]) }
}
enum NetworkImport {
  static func read(_ urlString: String, limit: Int = 8_000_000) async throws -> Data {
    guard let url = URL(string: urlString),
      ["https", "http"].contains(url.scheme?.lowercased() ?? ""), url.host != nil
    else { throw HubError.message("Saisissez une URL http ou https valide.") }
    var request = URLRequest(url: url)
    request.timeoutInterval = 25
    let config = URLSessionConfiguration.ephemeral
    config.httpCookieStorage = nil
    let session = URLSession(configuration: config)
    defer { session.invalidateAndCancel() }
    let (bytes, response) = try await session.bytes(for: request)
    guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode)
    else {
      throw HubError.message(
        "Cette page est inaccessible. Copiez le texte de la recette ou importez une capture.")
    }
    guard response.expectedContentLength <= limit else {
      throw HubError.message("Le fichier est trop volumineux.")
    }
    var data = Data()
    for try await byte in bytes {
      data.append(byte)
      if data.count > limit { throw HubError.message("Le fichier dépasse la taille autorisée.") }
    }
    return data
  }
  static func recipes(_ url: String) async throws -> [ImportResult] {
    let data = try await read(url)
    guard let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1)
    else { throw HubError.message("Le texte de la page est illisible.") }
    return try RecipeImport.jsonLD(html, sourceURL: url)
  }
}
enum PhotoService {
  static func prepared(_ data: Data) throws -> Data {
    guard data.count <= 35_000_000, let image = UIImage(data: data) else {
      throw HubError.message("Image non prise en charge ou supérieure à 35 Mo.")
    }
    let scale = min(1, 1600 / max(image.size.width, image.size.height))
    let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    let output = UIGraphicsImageRenderer(size: size, format: format).image { _ in
      image.draw(in: CGRect(origin: .zero, size: size))
    }
    guard let jpeg = output.jpegData(compressionQuality: 0.82) else {
      throw HubError.message("Impossible de préparer la photo.")
    }
    return jpeg
  }
  static func recognize(_ data: Data) async throws -> String {
    try await Task.detached(priority: .userInitiated) {
      let request = VNRecognizeTextRequest()
      request.recognitionLevel = .accurate
      request.recognitionLanguages = ["fr-FR", "en-US"]
      request.usesLanguageCorrection = true
      try VNImageRequestHandler(data: data, options: [:]).perform([request])
      let text =
        request.results?.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
        ?? ""
      guard !text.isEmpty else {
        throw HubError.message(
          "Aucun texte lisible. Essayez une photo plus nette et bien éclairée.")
      }
      return text
    }.value
  }
}
struct JSONDocument: FileDocument {
  static var readableContentTypes: [UTType] { [.json] }
  var data: Data
  init(data: Data = Data()) { self.data = data }
  init(configuration: ReadConfiguration) throws {
    data = configuration.file.regularFileContents ?? Data()
  }
  func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
    FileWrapper(regularFileWithContents: data)
  }
}
struct CameraPicker: UIViewControllerRepresentable {
  var onPhoto: (Data) -> Void
  @Environment(\.dismiss) private var dismiss
  func makeCoordinator() -> Coordinator { Coordinator(parent: self) }
  func makeUIViewController(context: Context) -> UIImagePickerController {
    let controller = UIImagePickerController()
    controller.sourceType = .camera
    controller.delegate = context.coordinator
    return controller
  }
  func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
  final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate
  {
    var parent: CameraPicker
    init(parent: CameraPicker) { self.parent = parent }
    func imagePickerController(
      _ picker: UIImagePickerController,
      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
      if let image = info[.originalImage] as? UIImage,
        let data = image.jpegData(compressionQuality: 0.9)
      {
        parent.onPhoto(data)
      }
      parent.dismiss()
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
  }
}
