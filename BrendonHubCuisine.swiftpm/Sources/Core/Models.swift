import Foundation

enum RecipeCategory: String, Codable, CaseIterable, Identifiable {
  case starter = "Entrée"
  case main = "Plat"
  case dessert = "Dessert"
  case snack = "Petit creux"
  case drink = "Boisson"
  var id: String { rawValue }
  var emoji: String {
    switch self {
    case .starter: return "🥗"
    case .main: return "🍝"
    case .dessert: return "🍰"
    case .snack: return "🥪"
    case .drink: return "🍋"
    }
  }
}
enum Difficulty: String, Codable, CaseIterable, Identifiable {
  case veryEasy = "Très facile"
  case easy = "Facile"
  case medium = "Moyen"
  case hard = "Difficile"
  var id: String { rawValue }
}
enum MealSlot: String, Codable, CaseIterable, Identifiable {
  case breakfast = "Petit-déjeuner"
  case lunch = "Midi"
  case snack = "Collation"
  case dinner = "Soir"
  var id: String { rawValue }
}
enum MealKind: String, Codable, CaseIterable {
  case recipe = "Recette"
  case leftovers = "Restes"
  case outside = "Repas extérieur"
}
enum PantryZone: String, Codable, CaseIterable, Identifiable {
  case fridge = "Frigo"
  case freezer = "Congélateur"
  case cupboard = "Placard"
  var id: String { rawValue }
}
struct Ingredient: Codable, Identifiable, Equatable {
  var id = UUID()
  var name = ""
  var amount: Double? = nil
  var unit = ""
  var originalQuantityText = ""
  var aisle = "Autre"
  var priceEUR: Double? = nil
  var quantity: String { Quantity.format(amount, unit: unit, fallback: originalQuantityText) }
  func scaled(from base: Int, to target: Int) -> Ingredient {
    var result = self
    if let amount { result.amount = amount * Double(max(1, target)) / Double(max(1, base)) }
    return result
  }
}
struct RecipeStep: Codable, Identifiable, Equatable {
  var id = UUID()
  var title = ""
  var instruction = ""
  var timerSeconds = 0
}
struct Nutrition: Codable, Equatable {
  var calories: Double? = nil
  var protein: Double? = nil
  var carbs: Double? = nil
  var fat: Double? = nil
}
struct Recipe: Codable, Identifiable, Equatable {
  var id = UUID()
  var name = ""
  var category: RecipeCategory = .main
  var difficulty: Difficulty = .easy
  var emoji = "🍽️"
  var timeMinutes = 30
  var servings = 2
  var estimatedCostEUR: Double? = nil
  var rating = 0.0
  var isFavorite = false
  var tags: [String] = []
  var ingredients: [Ingredient] = []
  var steps: [RecipeStep] = []
  var nutrition = Nutrition()
  var notes = ""
  var sourceURL = ""
  var sourceText = ""
  var photoURL = ""
  var photoAsset = ""
  var photoData: Data? = nil
  var createdAt = Date()
  var updatedAt = Date()
  var lastViewedAt: Date? = nil
  var lastCookedAt: Date? = nil
  var estimatedTotal: Double? {
    if let estimatedCostEUR { return estimatedCostEUR }
    guard !ingredients.isEmpty, ingredients.allSatisfy({ $0.priceEUR != nil }) else { return nil }
    return ingredients.compactMap(\.priceEUR).reduce(0, +)
  }
  func duplicate() -> Recipe {
    var copy = self
    copy.id = UUID()
    copy.name += " — variante"
    copy.createdAt = Date()
    copy.updatedAt = Date()
    copy.lastViewedAt = nil
    copy.lastCookedAt = nil
    copy.ingredients = ingredients.map {
      var i = $0
      i.id = UUID()
      return i
    }
    copy.steps = steps.map {
      var s = $0
      s.id = UUID()
      return s
    }
    return copy
  }
  var sharedText: String {
    var text =
      "\(name)\n\(timeMinutes) min · \(servings) portions · \(difficulty.rawValue)\n\nIngrédients\n"
    text += ingredients.map { "• \($0.quantity) \($0.name)" }.joined(separator: "\n")
    text +=
      "\n\nPréparation\n"
      + steps.enumerated().map {
        "\($0.offset + 1). \($0.element.title)\n\($0.element.instruction)"
      }.joined(separator: "\n\n")
    if !notes.isEmpty { text += "\n\nNotes\n" + notes }
    if !sourceURL.isEmpty { text += "\n\nSource : " + sourceURL }
    return text
  }
}
struct ShoppingItem: Codable, Identifiable, Equatable {
  var id = UUID()
  var ingredient = Ingredient()
  var isChecked = false
  var sourceRecipeIDs: [UUID] = []
  var sourceNames: [String] = []
  var sourceMealIDs: [UUID] = []
  var createdAt = Date()
  var order = 0
}
struct MealPlanEntry: Codable, Identifiable, Equatable {
  var id = UUID()
  var day = Day.key(Date())
  var slot: MealSlot = .lunch
  var kind: MealKind = .recipe
  var recipeID: UUID? = nil
  var servings = 2
  var note = ""
  var key: String { day + "|" + slot.rawValue }
}
struct PantryItem: Codable, Identifiable, Equatable {
  var id = UUID()
  var ingredient = Ingredient()
  var zone: PantryZone = .fridge
  var openedAt: Date? = nil
  var expiryDate: Date? = nil
  var isStaple = false
  var needsRestock = false
  var notes = ""
  func expiresSoon(now: Date = Date()) -> Bool {
    guard let expiryDate else { return false }
    return expiryDate < (Calendar.current.date(byAdding: .day, value: 4, to: now) ?? now)
  }
}
struct RecipeCollection: Codable, Identifiable, Equatable {
  var id = UUID()
  var name = "À tester"
  var symbol = "books.vertical"
  var recipeIDs: [UUID] = []
}
struct CookingHistoryEntry: Codable, Identifiable, Equatable {
  var id = UUID()
  var recipeID: UUID
  var recipeName: String
  var cookedAt = Date()
  var servings = 2
  var rating = 0.0
  var comment = ""
}
struct CookingSession: Codable, Identifiable, Equatable {
  var id = UUID()
  var recipeID: UUID
  // Snapshot: editing or deleting the recipe never invalidates a running session.
  var recipe: Recipe
  var stepIndex = 0
  var checkedStepIDs: [UUID] = []
  var checkedIngredientIDs: [UUID] = []
  var servings = 2
  var startedAt = Date()
}
struct CookingTimer: Codable, Identifiable, Equatable {
  var id = UUID()
  var name: String
  var recipeID: UUID? = nil
  var stepID: UUID? = nil
  var endDate: Date
  var duration: Int
  var acknowledged = false
  func remaining(at date: Date = Date()) -> Int {
    max(0, Int(ceil(endDate.timeIntervalSince(date))))
  }
  static func start(name: String, seconds: Int, now: Date = Date()) -> CookingTimer {
    CookingTimer(
      name: name, endDate: now.addingTimeInterval(Double(max(1, seconds))),
      duration: max(1, seconds))
  }
}
struct WasteEvent: Codable, Identifiable, Equatable {
  var id = UUID()
  var name: String
  var date = Date()
}
struct AppSettings: Codable, Equatable {
  var displayName = "Brendon"
  var defaultServings = 2
  var enabledMealSlots: [MealSlot] = [.lunch, .dinner]
  var excludedFoods = ""
  var preferredAisleOrder = [
    "Fruits", "Légumes", "Boulangerie", "Viande", "Poisson", "Frais", "Épicerie", "Épices",
    "Surgelé", "Boissons", "Autre",
  ]
  var appearance = "Système"
  var reduceMotion = false
  var weeklyBudgetEUR: Double? = nil
  var cookingTextSize = 26.0
  var hasOnboarded = false
}
struct HubState: Codable, Equatable {
  var formatVersion = 1
  var seeded = false
  var recipes: [Recipe] = []
  var shopping: [ShoppingItem] = []
  var meals: [MealPlanEntry] = []
  var pantry: [PantryItem] = []
  var collections: [RecipeCollection] = []
  var history: [CookingHistoryEntry] = []
  var timers: [CookingTimer] = []
  var session: CookingSession? = nil
  var drafts: [Recipe] = []
  var recentShopping: [Ingredient] = []
  var waste: [WasteEvent] = []
  var settings = AppSettings()
  mutating func seedOnce(_ recipes: [Recipe]) {
    guard !seeded else { return }
    self.recipes = recipes
    seeded = true
    collections = [
      RecipeCollection(name: "À tester"),
      RecipeCollection(
        name: "Nos favoris", symbol: "heart", recipeIDs: recipes.filter(\.isFavorite).map(\.id)),
    ]
  }
  mutating func upsertMeal(_ entry: MealPlanEntry) {
    meals.removeAll { $0.key == entry.key || $0.id == entry.id }
    meals.append(entry)
  }
  func duplicateCandidates(for recipe: Recipe) -> [Recipe] {
    recipes.filter {
      $0.id != recipe.id
        && (Search.normalize($0.name) == Search.normalize(recipe.name)
          || (!recipe.sourceURL.isEmpty && $0.sourceURL == recipe.sourceURL))
    }
  }
  func recipe(_ id: UUID?) -> Recipe? { recipes.first { $0.id == id } }
}
enum Day {
  static var calendar: Calendar {
    var c = Calendar(identifier: .gregorian)
    c.locale = Locale(identifier: "fr_BE")
    c.firstWeekday = 2
    return c
  }
  static func key(_ date: Date) -> String {
    let d = calendar.dateComponents([.year, .month, .day], from: date)
    return String(format: "%04d-%02d-%02d", d.year ?? 2000, d.month ?? 1, d.day ?? 1)
  }
  static func date(_ key: String) -> Date {
    let p = key.split(separator: "-").compactMap { Int($0) }
    guard p.count == 3 else { return Date() }
    return calendar.date(from: DateComponents(year: p[0], month: p[1], day: p[2], hour: 12))
      ?? Date()
  }
  static func monday(_ date: Date) -> Date {
    let start = calendar.startOfDay(for: date)
    return calendar.date(
      byAdding: .day, value: -((calendar.component(.weekday, from: date) + 5) % 7), to: start)
      ?? start
  }
  static func adding(_ days: Int, to date: Date) -> Date {
    calendar.date(byAdding: .day, value: days, to: date) ?? date
  }
}
