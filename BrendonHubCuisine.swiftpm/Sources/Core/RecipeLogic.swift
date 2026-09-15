import Foundation

enum Quantity {
  static let units = [
    "g", "kg", "ml", "cl", "l", "c. à café", "c. à soupe", "pièce", "gousse", "pincée", "poignée",
    "paquet", "sachet", "bol", "bac", "tranche",
  ]
  static func canonical(_ unit: String) -> String {
    let u = Search.normalize(unit).trimmingCharacters(in: .whitespaces)
    switch u {
    case "gramme", "grammes", "gr", "g": return "g"
    case "kilogrammes", "kilogramme", "kg": return "kg"
    case "millilitre", "millilitres", "ml": return "ml"
    case "cl", "centilitres": return "cl"
    case "litre", "litres", "l": return "l"
    case "c. a cafe", "c a cafe", "cc", "cac", "tsp", "cuillere a cafe", "cuilleres a cafe":
      return "c. à café"
    case "c. a soupe", "c a soupe", "cs", "cas", "tbsp", "cuillere a soupe", "cuilleres a soupe":
      return "c. à soupe"
    case "", "piece", "pieces": return "pièce"
    default: return u.hasSuffix("s") ? String(u.dropLast()) : u
    }
  }
  static func base(_ amount: Double, unit: String) -> (Double, String) {
    switch canonical(unit) {
    case "kg": return (amount * 1000, "g")
    case "cl": return (amount * 10, "ml")
    case "l": return (amount * 1000, "ml")
    default: return (amount, canonical(unit))
    }
  }
  static func number(_ value: Double) -> String {
    let f = NumberFormatter()
    f.locale = Locale(identifier: "fr_BE")
    f.maximumFractionDigits = 2
    f.minimumFractionDigits = 0
    return f.string(from: NSNumber(value: value)) ?? "\(value)"
  }
  static func format(_ amount: Double?, unit: String, fallback: String = "") -> String {
    guard let amount else { return fallback }
    var n = amount
    var u = unit
    if canonical(u) == "g", n >= 1000 {
      n /= 1000
      u = "kg"
    }
    if canonical(u) == "ml", n >= 1000 {
      n /= 1000
      u = "l"
    }
    return [number(n), u].filter { !$0.isEmpty }.joined(separator: " ")
  }
  static func parse(_ text: String) -> (Double?, String) {
    var s = text.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(
      of: ",", with: ".")
    for (symbol, fraction) in [
      ("½", "1/2"), ("¼", "1/4"), ("¾", "3/4"), ("⅓", "1/3"), ("⅔", "2/3"),
    ] {
      s = s.replacingOccurrences(of: symbol, with: " " + fraction)
    }
    s = s.trimmingCharacters(in: .whitespaces)
    let pattern = #"^(\d+\s+\d+/\d+|\d+/\d+|\d+(?:\.\d+)?)\s*(.*)$"#
    guard let regex = try? NSRegularExpression(pattern: pattern),
      let m = regex.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)),
      let a = Range(m.range(at: 1), in: s), let u = Range(m.range(at: 2), in: s)
    else { return (nil, "") }
    let suffix = String(s[u]).trimmingCharacters(in: .whitespaces)
    // A range or a count with package contents is intentionally not guessed.
    if suffix.hasPrefix("-") || suffix.hasPrefix("à ") || suffix.hasPrefix("a ")
      || suffix.hasPrefix("x ")
    {
      return (nil, "")
    }
    var total = 0.0
    for part in s[a].split(separator: " ") {
      let p = part.split(separator: "/")
      if p.count == 2, let n = Double(p[0]), let d = Double(p[1]), d > 0 {
        total += n / d
      } else if let n = Double(part) {
        total += n
      } else {
        return (nil, "")
      }
    }
    guard total.isFinite, total >= 0 else { return (nil, "") }
    return (total, suffix.isEmpty ? "pièce" : canonical(suffix))
  }
  static func ingredient(name: String, quantity: String, aisle: String = "Autre") -> Ingredient {
    let parsed = parse(quantity)
    return Ingredient(
      name: name, amount: parsed.0, unit: parsed.1, originalQuantityText: quantity, aisle: aisle)
  }
}
struct RecipeFilter: Equatable {
  var query = ""
  var category: RecipeCategory? = nil
  var difficulty: Difficulty? = nil
  var favorite = false
  var quick = false
  var budget = false
  var tags: Set<String> = []
  var collectionID: UUID? = nil
  var sort: RecipeSort = .newest
  var maximumMinutes = 0
}
enum RecipeSort: String, CaseIterable, Identifiable {
  case newest = "Date d’ajout"
  case name = "Nom"
  case rating = "Note"
  case time = "Durée"
  case cost = "Coût"
  case cooked = "Dernière préparation"
  var id: String { rawValue }
}
enum Search {
  static func normalize(_ value: String) -> String {
    value.folding(
      options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "fr_BE")
    )
    .replacingOccurrences(of: "œ", with: "oe").replacingOccurrences(of: "’", with: "'")
    .split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
  }
  static func results(_ state: HubState, filter f: RecipeFilter) -> [Recipe] {
    let exclusions = state.settings.excludedFoods.split(separator: ",").map {
      normalize(String($0))
    }.filter { !$0.isEmpty }
    let collection = state.collections.first { $0.id == f.collectionID }
    var result = state.recipes.filter { r in
      let blob = normalize(
        ([r.name, r.category.rawValue, r.difficulty.rawValue] + r.tags + r.ingredients.map(\.name))
          .joined(separator: " "))
      let q = normalize(f.query).split(separator: " ")
      return (f.category == nil || r.category == f.category)
        && (f.difficulty == nil || r.difficulty == f.difficulty)
        && (!f.favorite || r.isFavorite) && (!f.quick || r.timeMinutes <= 25)
        && (!f.budget || (r.estimatedTotal.map { $0 <= 7 } ?? false))
        && f.tags.allSatisfy { t in r.tags.contains { normalize($0) == normalize(t) } }
        && q.allSatisfy { blob.contains($0) }
        && !exclusions.contains { x in r.ingredients.contains { normalize($0.name).contains(x) } }
        && (collection.map { $0.recipeIDs.contains(r.id) } ?? true)
        && (f.maximumMinutes == 0 || r.timeMinutes <= f.maximumMinutes)
    }
    result.sort { a, b in
      switch f.sort {
      case .newest: return a.createdAt > b.createdAt
      case .name: return a.name.localizedStandardCompare(b.name) == .orderedAscending
      case .rating: return a.rating > b.rating
      case .time: return a.timeMinutes < b.timeMinutes
      case .cost:
        return (a.estimatedTotal ?? .greatestFiniteMagnitude)
          < (b.estimatedTotal ?? .greatestFiniteMagnitude)
      case .cooked: return (a.lastCookedAt ?? .distantPast) > (b.lastCookedAt ?? .distantPast)
      }
    }
    return result
  }
}
enum ShoppingLogic {
  static func add(
    _ ingredient: Ingredient, recipe: Recipe? = nil, mealID: UUID? = nil,
    to items: inout [ShoppingItem]
  ) {
    let candidate = items.firstIndex { item in
      guard !item.isChecked,
        Search.normalize(item.ingredient.name) == Search.normalize(ingredient.name),
        let a = item.ingredient.amount, let b = ingredient.amount
      else { return false }
      return Quantity.base(a, unit: item.ingredient.unit).1
        == Quantity.base(b, unit: ingredient.unit).1
    }
    if let index = candidate, let a = items[index].ingredient.amount, let b = ingredient.amount {
      let aa = Quantity.base(a, unit: items[index].ingredient.unit)
      let bb = Quantity.base(b, unit: ingredient.unit)
      items[index].ingredient.amount = aa.0 + bb.0
      items[index].ingredient.unit = aa.1
      items[index].ingredient.originalQuantityText = items[index].ingredient.quantity
      if let recipe, !items[index].sourceRecipeIDs.contains(recipe.id) {
        items[index].sourceRecipeIDs.append(recipe.id)
        items[index].sourceNames.append(recipe.name)
      }
      if let mealID, !items[index].sourceMealIDs.contains(mealID) {
        items[index].sourceMealIDs.append(mealID)
      }
    } else {
      items.append(
        ShoppingItem(
          ingredient: ingredient, sourceRecipeIDs: recipe.map { [$0.id] } ?? [],
          sourceNames: recipe.map { [$0.name] } ?? [], sourceMealIDs: mealID.map { [$0] } ?? [],
          order: (items.map(\.order).max() ?? -1) + 1))
    }
  }
  static func addRecipe(
    _ recipe: Recipe, servings: Int, mealID: UUID? = nil, to items: inout [ShoppingItem]
  ) {
    for ingredient in recipe.ingredients {
      add(
        ingredient.scaled(from: recipe.servings, to: servings), recipe: recipe, mealID: mealID,
        to: &items)
    }
  }
  static func generate(state: inout HubState, mealIDs: Set<UUID>) -> Int {
    var count = 0
    let existing = Set(state.shopping.flatMap(\.sourceMealIDs))
    for meal in state.meals
    where mealIDs.contains(meal.id) && !existing.contains(meal.id) && meal.kind == .recipe {
      if let recipe = state.recipe(meal.recipeID) {
        addRecipe(recipe, servings: meal.servings, mealID: meal.id, to: &state.shopping)
        count += 1
      }
    }
    return count
  }
  static func sharedText(_ items: [ShoppingItem]) -> String {
    "Liste de courses\n\n"
      + items.map {
        "\($0.isChecked ? "✓" : "☐") \($0.ingredient.name) — \($0.ingredient.quantity)"
      }.joined(separator: "\n")
  }
}
struct PantryMatch: Identifiable {
  var recipe: Recipe
  var available: Int
  var missing: [Ingredient]
  var urgent: Int
  var id: UUID { recipe.id }
  var percentage: Int {
    recipe.ingredients.isEmpty ? 0 : Int(Double(available) / Double(recipe.ingredients.count) * 100)
  }
}
enum PantryLogic {
  static func matching(_ recipes: [Recipe], pantry: [PantryItem], servings: Int, now: Date = Date())
    -> [PantryMatch]
  {
    recipes.map { recipe in
      var missing: [Ingredient] = []
      var urgent = 0
      var allocated: [String: Double] = [:]
      for i in recipe.ingredients.map({ $0.scaled(from: recipe.servings, to: servings) }) {
        let matches = pantry.filter {
          Search.normalize($0.ingredient.name) == Search.normalize(i.name) && !$0.needsRestock
            && ($0.expiryDate.map { Day.key($0) >= Day.key(now) } ?? true)
        }
        let enough: Bool
        var missingIngredient = i
        if matches.contains(where: \.isStaple) {
          enough = true
        } else if let amount = i.amount {
          let required = Quantity.base(amount, unit: i.unit)
          let stock = matches.reduce(0.0) { sum, p in
            guard let a = p.ingredient.amount else { return sum }
            let value = Quantity.base(a, unit: p.ingredient.unit)
            return sum + (value.1 == required.1 ? value.0 : 0)
          }
          let key = Search.normalize(i.name) + "|" + required.1
          let available = max(0, stock - (allocated[key] ?? 0))
          enough = available + 0.00001 >= required.0
          allocated[key, default: 0] += min(available, required.0)
          if !enough {
            missingIngredient.amount = max(0, required.0 - available)
            missingIngredient.unit = required.1
          }
        } else {
          enough = !matches.isEmpty
        }
        if enough {
          if matches.contains(where: { $0.expiresSoon(now: now) }) { urgent += 1 }
        } else {
          missing.append(missingIngredient)
        }
      }
      return PantryMatch(
        recipe: recipe, available: recipe.ingredients.count - missing.count, missing: missing,
        urgent: urgent)
    }.sorted { $0.percentage > $1.percentage }
  }
  static func deduct(recipe: Recipe, servings: Int, pantry: inout [PantryItem]) {
    for i in recipe.ingredients.map({ $0.scaled(from: recipe.servings, to: servings) }) {
      guard let amount = i.amount else { continue }
      let required = Quantity.base(amount, unit: i.unit)
      var remaining = required.0
      let indices = pantry.indices.filter {
        !pantry[$0].isStaple
          && Search.normalize(pantry[$0].ingredient.name) == Search.normalize(i.name)
      }
      .sorted {
        (pantry[$0].expiryDate ?? .distantFuture) < (pantry[$1].expiryDate ?? .distantFuture)
      }
      for index in indices where remaining > 0 {
        guard let stock = pantry[index].ingredient.amount else { continue }
        let value = Quantity.base(stock, unit: pantry[index].ingredient.unit)
        guard value.1 == required.1 else { continue }
        let taken = min(value.0, remaining)
        remaining -= taken
        pantry[index].ingredient.amount = value.0 - taken
        pantry[index].ingredient.unit = value.1
        if value.0 - taken <= 0 { pantry[index].needsRestock = true }
      }
    }
  }
}
enum Backup {
  static func encode(_ state: HubState) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    encoder.dateEncodingStrategy = .iso8601
    return try encoder.encode(state)
  }
  static func decode(_ data: Data) throws -> HubState {
    guard data.count <= 100_000_000 else { throw HubError.message("Le fichier dépasse 100 Mo.") }
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let state = try decoder.decode(HubState.self, from: data)
    guard state.formatVersion == 1 else {
      throw HubError.message(
        "Version de sauvegarde non prise en charge. Aucune donnée n’a été modifiée.")
    }
    try validate(state)
    return state
  }
  static func validate(_ state: HubState) throws {
    func unique<T: Identifiable>(_ items: [T]) -> Bool { Set(items.map(\.id)).count == items.count }
    func validNumber(_ value: Double?) -> Bool { value.map { $0.isFinite && $0 >= 0 } ?? true }
    func validIngredient(_ i: Ingredient) -> Bool {
      validNumber(i.amount) && validNumber(i.priceEUR)
    }
    guard state.formatVersion == 1 else {
      throw HubError.message("Version de sauvegarde non prise en charge.")
    }
    guard unique(state.recipes), unique(state.shopping), unique(state.meals), unique(state.pantry),
      unique(state.collections), unique(state.timers), unique(state.history), unique(state.drafts),
      unique(state.waste),
      Set(state.meals.map(\.key)).count == state.meals.count,
      state.recipes.allSatisfy({
        !$0.name.trimmingCharacters(in: .whitespaces).isEmpty && $0.servings > 0
          && $0.timeMinutes >= 0 && unique($0.steps) && unique($0.ingredients)
          && $0.ingredients.allSatisfy(validIngredient) && validNumber($0.estimatedCostEUR)
          && $0.steps.allSatisfy { $0.timerSeconds >= 0 }
      }),
      state.meals.allSatisfy({
        $0.servings > 0 && $0.day.count == 10 && Day.key(Day.date($0.day)) == $0.day
          && ($0.kind != .recipe || state.recipe($0.recipeID) != nil)
      }),
      state.settings.defaultServings > 0,
      !state.settings.enabledMealSlots.isEmpty,
      Set(state.settings.enabledMealSlots).count == state.settings.enabledMealSlots.count,
      Set(state.settings.preferredAisleOrder).count == state.settings.preferredAisleOrder.count,
      state.settings.cookingTextSize.isFinite && state.settings.cookingTextSize > 0,
      state.shopping.allSatisfy({ validIngredient($0.ingredient) }),
      state.pantry.allSatisfy({ validIngredient($0.ingredient) }),
      state.timers.allSatisfy({ $0.duration > 0 })
    else {
      throw HubError.message(
        "Sauvegarde incohérente : identifiants, portions ou planning invalides. Aucune donnée n’a été modifiée."
      )
    }
    if let session = state.session {
      guard !session.recipe.steps.isEmpty, session.servings > 0, session.stepIndex >= 0,
        session.stepIndex < session.recipe.steps.count
      else { throw HubError.message("La session sauvegardée est invalide.") }
    }
  }
}
enum HubError: LocalizedError {
  case message(String)
  var errorDescription: String? {
    if case .message(let message) = self { return message }
    return nil
  }
}
