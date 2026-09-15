import Foundation
import SwiftData
import SwiftUI

enum HubSchemaV1: VersionedSchema {
  static var versionIdentifier = Schema.Version(1, 0, 0)
  static var models: [any PersistentModel.Type] { [StoredRecipe.self, StoredWorkspace.self] }
  @Model final class StoredRecipe {
    @Attribute(.unique) var id: UUID
    @Attribute(.externalStorage) var payload: Data
    init(id: UUID, payload: Data) {
      self.id = id
      self.payload = payload
    }
  }
  @Model final class StoredWorkspace {
    @Attribute(.unique) var key: String
    @Attribute(.externalStorage) var payload: Data
    init(key: String, payload: Data) {
      self.key = key
      self.payload = payload
    }
  }
}
enum HubMigrationPlan: SchemaMigrationPlan {
  static var schemas: [any VersionedSchema.Type] { [HubSchemaV1.self] }
  static var stages: [MigrationStage] { [] }
}
@MainActor final class HubRepository {
  let container: ModelContainer
  let context: ModelContext
  init(inMemory: Bool = false) throws {
    let schema = Schema(versionedSchema: HubSchemaV1.self)
    let config = ModelConfiguration(
      schema: schema, isStoredInMemoryOnly: inMemory, cloudKitDatabase: .none)
    container = try ModelContainer(
      for: schema, migrationPlan: HubMigrationPlan.self, configurations: [config])
    context = ModelContext(container)
    context.autosaveEnabled = false
  }
  func load() throws -> HubState {
    let records = try context.fetch(FetchDescriptor<HubSchemaV1.StoredWorkspace>())
    let recipeRecords = try context.fetch(FetchDescriptor<HubSchemaV1.StoredRecipe>())
    guard let workspace = records.first(where: { $0.key == "workspace-v1" }) else {
      guard recipeRecords.isEmpty else {
        throw HubError.message(
          "Le catalogue existe, mais ses réglages sont introuvables. Restaurez une sauvegarde ; les données existantes sont conservées."
        )
      }
      return HubState()
    }
    var state = try JSONDecoder().decode(HubState.self, from: workspace.payload)
    state.recipes = try recipeRecords.map {
      try JSONDecoder().decode(Recipe.self, from: $0.payload)
    }.sorted { $0.createdAt < $1.createdAt }
    try Backup.validate(state)
    return state
  }
  func save(_ state: HubState) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    // Encode all values before changing any SwiftData object.
    let payloads = try state.recipes.map { ($0.id, try encoder.encode($0)) }
    var metadata = state
    metadata.recipes = []
    let data = try encoder.encode(metadata)
    do {
      let stored = try context.fetch(FetchDescriptor<HubSchemaV1.StoredRecipe>())
      let ids = Set(state.recipes.map(\.id))
      for record in stored where !ids.contains(record.id) { context.delete(record) }
      for (id, payload) in payloads {
        if let record = stored.first(where: { $0.id == id }) {
          if record.payload != payload { record.payload = payload }
        } else {
          context.insert(HubSchemaV1.StoredRecipe(id: id, payload: payload))
        }
      }
      let workspace = try context.fetch(FetchDescriptor<HubSchemaV1.StoredWorkspace>()).first {
        $0.key == "workspace-v1"
      }
      if let workspace {
        workspace.payload = data
      } else {
        context.insert(HubSchemaV1.StoredWorkspace(key: "workspace-v1", payload: data))
      }
      try context.save()
    } catch {
      context.rollback()
      throw error
    }
  }
}
@MainActor final class HubStore: ObservableObject {
  @Published private(set) var state: HubState
  @Published var errorMessage: String? = nil
  @Published var toast: String? = nil
  @Published private(set) var canUndo = false
  private var previousState: HubState? = nil
  private let repository: HubRepository
  init(repository: HubRepository) throws {
    self.repository = repository
    var loaded = try repository.load()
    if !loaded.seeded {
      guard let url = Bundle.module.url(forResource: "LegacyRecipes", withExtension: "json") else {
        throw HubError.message("Les recettes initiales sont introuvables dans le projet.")
      }
      loaded.seedOnce(try DemoData.decode(Data(contentsOf: url)))
      try repository.save(loaded)
    }
    state = loaded
  }
  @discardableResult func change(
    _ message: String? = nil, undo: Bool = false, _ mutation: (inout HubState) -> Void
  ) -> Bool {
    var next = state
    mutation(&next)
    do {
      try repository.save(next)
      previousState = undo ? state : nil
      canUndo = undo
      state = next
      if let message { toast = message }
      return true
    } catch {
      errorMessage =
        "Modification non enregistrée. Vos données précédentes sont conservées.\n\(error.localizedDescription)"
      return false
    }
  }
  func undo() {
    guard let previousState else { return }
    if change("Action annulée", { $0 = previousState }) {
      Task { await TimerService.synchronize { self.state.timers } }
    }
  }
  func recipe(_ id: UUID) -> Recipe? { state.recipe(id) }
  func updateRecipe(_ recipe: Recipe) -> Bool {
    change("Recette enregistrée") { state in
      var r = recipe
      r.updatedAt = Date()
      if let i = state.recipes.firstIndex(where: { $0.id == r.id }) {
        state.recipes[i] = r
      } else {
        state.recipes.append(r)
      }
      state.drafts.removeAll { $0.id == r.id }
    }
  }
  func favorite(_ id: UUID) {
    change { s in
      if let i = s.recipes.firstIndex(where: { $0.id == id }) { s.recipes[i].isFavorite.toggle() }
    }
    Haptics.light()
  }
  func deleteRecipe(_ id: UUID) {
    change("Recette supprimée", undo: true) { s in
      s.recipes.removeAll { $0.id == id }
      s.meals.removeAll { $0.recipeID == id }
      for i in s.collections.indices { s.collections[i].recipeIDs.removeAll { $0 == id } }
      s.drafts.removeAll { $0.id == id }
    }
  }
  func viewed(_ id: UUID) {
    change { s in
      if let i = s.recipes.firstIndex(where: { $0.id == id }) { s.recipes[i].lastViewedAt = Date() }
    }
  }
  func addToShopping(_ r: Recipe, servings: Int) {
    change("Ingrédients ajoutés aux courses", undo: true) {
      ShoppingLogic.addRecipe(r, servings: servings, to: &$0.shopping)
    }
    Haptics.light()
  }
  func startCooking(_ recipe: Recipe, servings: Int) -> Bool {
    guard !recipe.steps.isEmpty else {
      errorMessage = "Ajoutez au moins une étape à cette recette."
      return false
    }
    if state.session?.recipeID == recipe.id { return true }
    return change {
      $0.session = CookingSession(recipeID: recipe.id, recipe: recipe, servings: servings)
    }
  }
  func startTimer(name: String, seconds: Int, recipeID: UUID? = nil, stepID: UUID? = nil) {
    guard state.timers.filter({ !$0.acknowledged && $0.endDate > Date() }).count < 50 else {
      errorMessage = "50 minuteurs sont déjà actifs. Arrêtez-en un avant d’en ajouter un autre."
      return
    }
    var timer = CookingTimer.start(name: name, seconds: seconds)
    timer.recipeID = recipeID
    timer.stepID = stepID
    guard change("Minuteur lancé", { $0.timers.append(timer) }) else { return }
    Task {
      do {
        let allowed = try await TimerService.schedule(timer, requestPermission: true)
        guard state.timers.contains(where: { $0.id == timer.id }) else {
          TimerService.cancel(timer.id)
          return
        }
        if !allowed {
          errorMessage =
            "Le minuteur fonctionne dans l’app. Les notifications sont désactivées : autorisez-les dans Réglages pour être averti en arrière-plan."
        }
      } catch {
        errorMessage =
          "Minuteur enregistré, mais notification indisponible : \(error.localizedDescription)"
      }
    }
  }
  func stopTimer(_ id: UUID) {
    if change(nil, { $0.timers.removeAll { $0.id == id } }) { TimerService.cancel(id) }
  }
  func restore(_ restored: HubState) -> Bool {
    do { try Backup.validate(restored) } catch {
      errorMessage = error.localizedDescription
      return false
    }
    let success = change("Sauvegarde restaurée", undo: true) {
      $0 = restored
      $0.seeded = true
    }
    if success { Task { await TimerService.synchronize { self.state.timers } } }
    return success
  }
}
