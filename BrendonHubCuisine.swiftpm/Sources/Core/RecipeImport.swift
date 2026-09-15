import Foundation

struct ImportResult: Identifiable {
  var id = UUID()
  var recipe: Recipe
  var warnings: [String]
}
enum RecipeImport {
  static func clean(_ text: String) -> String {
    var s = text.replacingOccurrences(of: #"<[^>]+>"#, with: " ", options: .regularExpression)
    for (a, b) in [
      ("&amp;", "&"), ("&quot;", "\""), ("&#39;", "'"), ("&apos;", "'"), ("&nbsp;", " "),
      ("&lt;", "<"), ("&gt;", ">"),
    ] { s = s.replacingOccurrences(of: a, with: b) }
    if let regex = try? NSRegularExpression(pattern: #"&#(x[0-9a-fA-F]+|[0-9]+);"#) {
      for m in regex.matches(in: s, range: NSRange(s.startIndex..., in: s)).reversed() {
        guard let r = Range(m.range, in: s), let n = Range(m.range(at: 1), in: s) else { continue }
        let v = String(s[n])
        let code = v.hasPrefix("x") ? UInt32(v.dropFirst(), radix: 16) : UInt32(v)
        if let code, let scalar = UnicodeScalar(code) { s.replaceSubrange(r, with: String(scalar)) }
      }
    }
    return s.trimmingCharacters(in: .whitespacesAndNewlines)
  }
  static func firstNumber(_ text: String) -> Double? {
    guard let r = text.range(of: #"\d+(?:[.,]\d+)?"#, options: .regularExpression) else {
      return nil
    }
    return Double(text[r].replacingOccurrences(of: ",", with: "."))
  }
  static func duration(_ text: String) -> Int {
    let upper = text.uppercased()
    if upper.hasPrefix("P") {
      var seconds = 0.0
      for (pattern, factor) in [
        (#"(\d+(?:\.\d+)?)D"#, 86400.0), (#"(\d+(?:\.\d+)?)H"#, 3600.0),
        (#"(\d+(?:\.\d+)?)M"#, 60.0), (#"(\d+(?:\.\d+)?)S"#, 1.0),
      ] {
        if let r = upper.range(of: pattern, options: .regularExpression) {
          seconds += (firstNumber(String(upper[r])) ?? 0) * factor
        }
      }
      return Int(seconds)
    }
    let lower = Search.normalize(text)
    var seconds = 0.0
    for (pattern, factor) in [
      (#"\d+(?:[.,]\d+)?\s*(?:heures?|hours?|h)\b"#, 3600.0),
      (#"\d+(?:[.,]\d+)?\s*(?:minutes?|min)\b"#, 60.0),
      (#"\d+(?:[.,]\d+)?\s*(?:secondes?|sec)\b"#, 1.0),
    ] {
      if let r = lower.range(of: pattern, options: .regularExpression) {
        seconds += (firstNumber(String(lower[r])) ?? 0) * factor
      }
    }
    return Int(seconds)
  }
  static func ingredientLine(_ raw: String) -> Ingredient {
    let line = raw.replacingOccurrences(of: #"^[\s•*\-]+"#, with: "", options: .regularExpression)
      .trimmingCharacters(in: .whitespaces)
    // Keep compounds/ranges intact instead of misinterpreting them.
    if line.range(of: #"^\d+\s*(?:-|à|x)\s*\d+"#, options: .regularExpression) != nil {
      return Ingredient(name: line, originalQuantityText: "À vérifier")
    }
    let pattern = #"^(\d+\s+\d+/\d+|\d+/\d+|\d+(?:[.,]\d+)?|[½¼¾⅓⅔])\s*(.*)$"#
    guard let regex = try? NSRegularExpression(pattern: pattern),
      let m = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
      let q = Range(m.range(at: 1), in: line), let rest = Range(m.range(at: 2), in: line)
    else { return Ingredient(name: line, originalQuantityText: "Selon besoin") }
    let quantity = String(line[q])
    var name = String(line[rest])
    var unit = "pièce"
    let unitPattern =
      #"^(c\.\s*à\s*(?:soupe|café)|cuillères?\s+à\s+(?:soupe|café)|kg|grammes?|g|gr|ml|cl|litres?|l|pièces?|gousses?|pincées?|poignées?|paquets?|sachets?|bols?|bacs?|tranches?|tsp|tbsp)\b\.?\s*"#
    if let r = name.range(of: unitPattern, options: [.regularExpression, .caseInsensitive]) {
      unit = String(name[r]).trimmingCharacters(in: .whitespaces)
      name.removeSubrange(r)
    }
    name = name.replacingOccurrences(
      of: #"^(?:de\s+|d['’])"#, with: "", options: [.regularExpression, .caseInsensitive])
    guard !name.isEmpty else { return Ingredient(name: line, originalQuantityText: "À vérifier") }
    return Quantity.ingredient(name: name, quantity: quantity + " " + unit)
  }
  static func text(_ raw: String) throws -> ImportResult {
    let lines = raw.components(separatedBy: .newlines).map {
      $0.trimmingCharacters(in: .whitespaces)
    }.filter { !$0.isEmpty }
    guard let title = lines.first, raw.count <= 250_000 else {
      throw HubError.message("Collez une recette de moins de 250 000 caractères.")
    }
    var recipe = Recipe(name: title)
    recipe.timeMinutes = 0
    recipe.sourceText = raw
    var region = ""
    var notes: [String] = []
    for line in lines.dropFirst() {
      let normalized = Search.normalize(line).trimmingCharacters(
        in: CharacterSet(charactersIn: ":"))
      if ["ingredients", "ingredient", "ingredients :"].contains(normalized) {
        region = "ingredients"
        continue
      }
      if ["preparation", "etapes", "instructions", "methode", "directions"].contains(normalized) {
        region = "steps"
        continue
      }
      if ["notes", "astuces", "conseils"].contains(normalized) {
        region = "notes"
        continue
      }
      if normalized.hasPrefix("portions") || normalized.hasPrefix("pour ")
        || normalized.hasPrefix("servings")
      {
        if let n = firstNumber(line) { recipe.servings = max(1, Int(n)) }
        continue
      }
      if normalized.hasPrefix("temps") || normalized.hasPrefix("duree") {
        recipe.timeMinutes = max(0, duration(line) / 60)
        continue
      }
      if region == "ingredients" {
        recipe.ingredients.append(ingredientLine(line))
      } else if region == "steps"
        || (region.isEmpty && line.range(of: #"^\d+[.)]\s"#, options: .regularExpression) != nil)
      {
        let instruction = line.replacingOccurrences(
          of: #"^\d+[.)]\s*"#, with: "", options: .regularExpression)
        recipe.steps.append(
          RecipeStep(
            title: "Étape \(recipe.steps.count + 1)", instruction: instruction,
            timerSeconds: duration(instruction)))
      } else if region.isEmpty
        && (line.first?.isNumber == true || line.hasPrefix("•") || line.hasPrefix("-"))
      {
        recipe.ingredients.append(ingredientLine(line))
      } else {
        notes.append(line)
      }
    }
    recipe.notes = notes.joined(separator: "\n")
    var warnings = ["Vérifiez les quantités, les portions et les durées avant d’enregistrer."]
    if recipe.ingredients.isEmpty {
      warnings.append(
        "Ingrédients non détectés : ajoutez un titre « Ingrédients » dans le texte ou saisissez-les dans le formulaire."
      )
    }
    if recipe.steps.isEmpty {
      warnings.append(
        "Étapes non détectées : ajoutez un titre « Préparation » ou complétez le formulaire.")
    }
    return ImportResult(recipe: recipe, warnings: warnings)
  }
  static func jsonLD(_ html: String, sourceURL: String = "") throws -> [ImportResult] {
    let regex = try NSRegularExpression(
      pattern:
        #"<script\b[^>]*type\s*=\s*["']application/ld\+json["'][^>]*>([\s\S]*?)</script\s*>"#,
      options: [.caseInsensitive])
    var objects: [[String: Any]] = []
    func walk(_ value: Any) {
      if let array = value as? [Any] { array.forEach(walk) }
      if let dictionary = value as? [String: Any] {
        let type = (dictionary["@type"] as? [String]) ?? [dictionary["@type"] as? String ?? ""]
        if type.contains(where: {
          $0.lowercased() == "recipe" || $0.lowercased().hasSuffix("/recipe")
        }) {
          objects.append(dictionary)
        } else {
          dictionary.values.forEach(walk)
        }
      }
    }
    for m in regex.matches(in: html, range: NSRange(html.startIndex..., in: html)) {
      guard let r = Range(m.range(at: 1), in: html) else { continue }
      let s = String(html[r]).trimmingCharacters(in: .whitespacesAndNewlines)
      if let data = s.data(using: .utf8), let json = try? JSONSerialization.jsonObject(with: data) {
        walk(json)
      }
    }
    func steps(_ value: Any?) -> [RecipeStep] {
      if let text = value as? String {
        return text.components(separatedBy: .newlines).map(clean).filter { !$0.isEmpty }.map {
          RecipeStep(title: "Préparation", instruction: $0, timerSeconds: duration($0))
        }
      }
      if let array = value as? [Any] { return array.flatMap { steps($0) } }
      if let d = value as? [String: Any] {
        if let child = d["itemListElement"] { return steps(child) }
        if let text = d["text"] as? String {
          return [
            RecipeStep(
              title: clean(d["name"] as? String ?? "Préparation"), instruction: clean(text),
              timerSeconds: duration(text))
          ]
        }
      }
      return []
    }
    let result = objects.compactMap { d -> ImportResult? in
      guard let name = d["name"] as? String, !name.isEmpty else { return nil }
      var r = Recipe(name: clean(name))
      r.sourceURL = sourceURL
      r.timeMinutes = 0
      r.ingredients = ((d["recipeIngredient"] as? [String]) ?? []).map { ingredientLine(clean($0)) }
      r.steps = steps(d["recipeInstructions"])
      r.timeMinutes = duration(d["totalTime"] as? String ?? "") / 60
      if r.timeMinutes == 0 {
        r.timeMinutes =
          (duration(d["prepTime"] as? String ?? "") + duration(d["cookTime"] as? String ?? "")) / 60
      }
      let yield = d["recipeYield"] as? String ?? (d["recipeYield"] as? [String])?.first ?? ""
      r.servings = max(1, Int(firstNumber(yield) ?? 2))
      if let image = d["image"] as? String {
        r.photoURL = image
      } else if let images = d["image"] as? [String] {
        r.photoURL = images.first ?? ""
      } else if let image = d["image"] as? [String: Any] {
        r.photoURL = image["url"] as? String ?? ""
      }
      let keywords = d["keywords"] as? String ?? ""
      r.tags = keywords.split(separator: ",").map { clean(String($0)) }
      let category = Search.normalize(d["recipeCategory"] as? String ?? "")
      if category.contains("dessert") {
        r.category = .dessert
      } else if category.contains("drink") || category.contains("boisson") {
        r.category = .drink
      } else if category.contains("entree") || category.contains("starter") {
        r.category = .starter
      }
      if let n = d["nutrition"] as? [String: Any] {
        func value(_ key: String) -> Double? {
          if let x = n[key] as? Double { return x }
          return firstNumber(n[key] as? String ?? "")
        }
        r.nutrition = Nutrition(
          calories: value("calories"), protein: value("proteinContent"),
          carbs: value("carbohydrateContent"), fat: value("fatContent"))
      }
      r.sourceText = clean(d["description"] as? String ?? "")
      return ImportResult(
        recipe: r,
        warnings: [
          "Données publiques détectées. Vérifiez les portions, la nutrition et les minuteurs ; les valeurs nutritionnelles dépendent du site d’origine."
        ])
    }
    guard !result.isEmpty else {
      throw HubError.message(
        "Aucune recette structurée n’a été trouvée sur cette page. Copiez son texte ou importez une capture d’écran."
      )
    }
    return result
  }
}
enum DemoData {
  private struct Legacy: Decodable {
    struct Item: Decodable {
      var name: String
      var qty: String
      var group: String
    }
    struct Step: Decodable {
      var title: String
      var text: String
      var timer: Int
    }
    struct Nut: Decodable {
      var cal: Double
      var prot: Double
      var carb: Double
      var fat: Double
    }
    var id: String
    var name: String
    var cat: String
    var emoji: String
    var img: String
    var time: Int
    var servings: Int
    var cost: Double
    var difficulty: String
    var rating: Double
    var tags: [String]
    var ingredients: [Item]
    var steps: [Step]
    var nutrition: Nut
    var notes: String
  }
  static func decode(_ data: Data) throws -> [Recipe] {
    try JSONDecoder().decode([Legacy].self, from: data).map { l in
      var r = Recipe(
        name: l.name, category: RecipeCategory(rawValue: l.cat) ?? .main,
        difficulty: Difficulty(rawValue: l.difficulty) ?? .easy,
        emoji: l.emoji, timeMinutes: l.time, servings: l.servings, estimatedCostEUR: l.cost,
        rating: l.rating, isFavorite: l.tags.contains("Favori"),
        tags: l.tags.filter { $0 != "Favori" })
      r.ingredients = l.ingredients.map {
        Quantity.ingredient(name: $0.name, quantity: $0.qty, aisle: $0.group)
      }
      r.steps = l.steps.map {
        RecipeStep(title: $0.title, instruction: $0.text, timerSeconds: $0.timer * 60)
      }
      r.nutrition = Nutrition(
        calories: l.nutrition.cal, protein: l.nutrition.prot, carbs: l.nutrition.carb,
        fat: l.nutrition.fat)
      r.notes = l.notes
      r.photoAsset = l.id
      r.sourceText =
        "Données du prototype fourni. Prix et nutrition indicatifs. Certaines étapes mentionnent des assaisonnements sans quantité."
      return r
    }
  }
}
