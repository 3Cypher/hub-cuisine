import Foundation

struct CheckResult: Identifiable {
  var name: String
  var passed: Bool
  var detail: String
  var id: String { name }
}
enum CoreChecks {
  static func run() -> [CheckResult] {
    var result: [CheckResult] = []
    func check(_ name: String, _ test: () throws -> Bool) {
      do {
        let ok = try test()
        result.append(
          CheckResult(name: name, passed: ok, detail: ok ? "Réussi" : "Résultat inattendu"))
      } catch {
        result.append(CheckResult(name: name, passed: false, detail: error.localizedDescription))
      }
    }
    var pasta = Recipe(
      name: "Pâtes à la crème", timeMinutes: 20, servings: 4, estimatedCostEUR: 6, isFavorite: true,
      tags: ["Été"])
    pasta.ingredients = [
      Quantity.ingredient(name: "Crème", quantity: "250 ml"),
      Quantity.ingredient(name: "Pâtes", quantity: "400 g"),
    ]
    pasta.steps = [
      RecipeStep(title: "Cuire", instruction: "Cuire les pâtes 10 minutes.", timerSeconds: 600)
    ]
    var state = HubState()
    state.seedOnce([pasta])
    check("Recherche et filtres combinés") {
      var f = RecipeFilter()
      f.query = "pates creme"
      f.quick = true
      f.favorite = true
      f.budget = true
      f.tags = ["ete"]
      return Search.results(state, filter: f).count == 1
        && Search.results(state, filter: RecipeFilter(query: "absent")).isEmpty
    }
    check("Portions et fractions") {
      Quantity.ingredient(name: "Farine", quantity: "1 1/2 kg").scaled(from: 4, to: 2).amount
        == 0.75 && Quantity.parse("½ sachet").0 == 0.5 && Quantity.parse("1 à 2").0 == nil
    }
    check("Fusion de quantités compatibles") {
      var items: [ShoppingItem] = []
      ShoppingLogic.add(Quantity.ingredient(name: "Sucre", quantity: "500 g"), to: &items)
      ShoppingLogic.add(Quantity.ingredient(name: "sucre", quantity: "1 kg"), to: &items)
      ShoppingLogic.add(Quantity.ingredient(name: "sucre", quantity: "2 c. à soupe"), to: &items)
      ShoppingLogic.add(Ingredient(name: "Sucre", originalQuantityText: "Selon goût"), to: &items)
      return items.count == 3 && items[0].ingredient.amount == 1500
    }
    check("Planning unique et courses proportionnelles") {
      var s = state
      let e = MealPlanEntry(day: "2026-09-14", slot: .lunch, recipeID: pasta.id, servings: 2)
      s.upsertMeal(e)
      var replacement = e
      replacement.id = UUID()
      s.upsertMeal(replacement)
      let n = ShoppingLogic.generate(state: &s, mealIDs: [replacement.id])
      let again = ShoppingLogic.generate(state: &s, mealIDs: [replacement.id])
      return s.meals.count == 1 && n == 1 && again == 0
        && s.shopping.first?.ingredient.amount == 125
    }
    check("Dates de semaine et changement d’année") {
      Day.key(Day.monday(Day.date("2027-01-03"))) == "2026-12-28"
    }
    check("Import texte français") {
      let r = try RecipeImport.text(
        "Crêpes\nPour 4 personnes\nIngrédients\n250 g de farine\n1/2 l de lait\nPréparation\n1. Mélanger.\n2. Cuire 3 minutes."
      ).recipe
      return r.name == "Crêpes" && r.ingredients.count == 2 && r.ingredients[0].name == "farine"
        && r.ingredients[1].amount == 0.5 && r.steps.count == 2 && r.steps[1].timerSeconds == 180
    }
    check("Import JSON-LD imbriqué") {
      let html =
        #"<script type="application/ld+json">{"@graph":[{"@type":["Recipe"],"name":"Pain &amp; beurre","recipeYield":"4 portions","totalTime":"PT1H20M","recipeIngredient":["500 g de farine"],"recipeInstructions":[{"@type":"HowToSection","itemListElement":[{"@type":"HowToStep","name":"Mélange","text":"Mélanger 2 minutes."}]}]}]}</script>"#
      let r = try RecipeImport.jsonLD(html)[0].recipe
      return r.name == "Pain & beurre" && r.timeMinutes == 80 && r.steps.count == 1
        && r.steps[0].timerSeconds == 120 && r.servings == 4
    }
    check("Échec d’import explicite") {
      do {
        _ = try RecipeImport.jsonLD("<html>Aucune recette</html>")
        return false
      } catch { return true }
    }
    check("Démonstration insérée une seule fois") {
      var s = state
      s.recipes = []
      s.seedOnce([pasta])
      return s.recipes.isEmpty && s.seeded
    }
    check("Sauvegarde complète aller-retour") {
      var s = state
      s.recipes[0].photoData = Data([0, 1, 2, 3])
      s.recipes[0].notes = "Texte\navec accents éè"
      s.pantry = [PantryItem(ingredient: pasta.ingredients[0])]
      s.drafts = [Recipe(name: "Brouillon")]
      s.session = CookingSession(recipeID: pasta.id, recipe: pasta, stepIndex: 0, servings: 3)
      s.timers = [CookingTimer.start(name: "Pâtes", seconds: 120)]
      let data = try Backup.encode(s)
      let restored = try Backup.decode(data)
      return try Backup.encode(restored) == data
        && restored.recipes[0].photoData == Data([0, 1, 2, 3]) && restored.drafts.count == 1
        && restored.session?.servings == 3
    }
    check("Doublon et variante indépendante") {
      var copy = pasta
      copy.id = UUID()
      copy.name = "PATES A LA CREME"
      let variant = pasta.duplicate()
      return state.duplicateCandidates(for: copy).count == 1 && variant.id != pasta.id
        && variant.ingredients[0].id != pasta.ingredients[0].id
    }
    check("Minuteur après interruption") {
      let now = Date(timeIntervalSince1970: 1_000)
      let t = CookingTimer.start(name: "Four", seconds: 60, now: Date(timeIntervalSince1970: 1_000))
      return t.remaining(at: now.addingTimeInterval(25)) == 35
        && t.remaining(at: now.addingTimeInterval(90)) == 0
    }
    check("Garde-manger : quantités et produits périmés") {
      let p = [
        PantryItem(ingredient: Quantity.ingredient(name: "Crème", quantity: "0,5 l")),
        PantryItem(ingredient: Quantity.ingredient(name: "Pâtes", quantity: "200 g")),
      ]
      let m = PantryLogic.matching([pasta], pantry: p, servings: 2)[0]
      var expired = p
      expired[0].expiryDate = Date(timeIntervalSince1970: 0)
      return m.percentage == 100
        && PantryLogic.matching([pasta], pantry: expired, servings: 2)[0].percentage == 50
    }
    check("Garde-manger : stock partagé entre deux lignes") {
      var r = pasta
      r.servings = 2
      r.ingredients = [
        Quantity.ingredient(name: "Sucre", quantity: "200 g"),
        Quantity.ingredient(name: "sucre", quantity: "200 g"),
      ]
      let p = [PantryItem(ingredient: Quantity.ingredient(name: "Sucre", quantity: "300 g"))]
      let match = PantryLogic.matching([r], pantry: p, servings: 2)[0]
      return match.percentage == 50 && match.missing.first?.amount == 100
    }
    check("Refus d’une sauvegarde incohérente") {
      var s = state
      s.recipes.append(pasta)
      do {
        _ = try Backup.decode(Backup.encode(s))
        return false
      } catch { return true }
    }
    return result
  }
}
