import SwiftUI

struct HomeView: View {
  @EnvironmentObject private var store: HubStore
  @State private var random = false
  @State private var add = false
  @State private var importing = false
  @State private var cooking = false
  private var today: [MealPlanEntry] { store.state.meals.filter { $0.day == Day.key(Date()) } }
  private var suggestion: Recipe? {
    let recipes = Search.results(store.state, filter: RecipeFilter())
    guard !recipes.isEmpty else { return nil }
    return recipes[(Day.calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1) % recipes.count]
  }
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 28) {
        VStack(alignment: .leading, spacing: 8) {
          Text(Date().formatted(.dateTime.weekday(.wide).day().month(.wide)).uppercased()).font(
            .caption.weight(.semibold)
          ).tracking(2).foregroundStyle(HC.accent)
          Text("Bon appétit,\n\(store.state.settings.displayName) !").font(HC.title(.largeTitle))
        }
        todayCard
        HCPrimaryButton(title: "Je ne sais pas quoi manger", symbol: "dice") { random = true }
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 145))], spacing: 12) {
          quickAction("Une recette", "plus", "À noter") { add = true }
          quickAction("Importer", "square.and.arrow.down", "À découvrir") { importing = true }
          NavigationLink {
            ShoppingView()
          } label: {
            quickLabel(
              "Courses", "basket",
              "\(store.state.shopping.filter { !$0.isChecked }.count) à acheter")
          }.buttonStyle(.plain)
          NavigationLink {
            PantryView()
          } label: {
            quickLabel("Garde-manger", "refrigerator", "Ce qu’il reste")
          }.buttonStyle(.plain)
        }
        if let session = store.state.session {
          HCSecondaryButton(title: "Reprendre : \(session.recipe.name)", symbol: "play.circle") {
            cooking = true
          }
        }
        if let timer = store.state.timers.filter({ !$0.acknowledged }).sorted(by: {
          $0.endDate < $1.endDate
        }).first {
          HCTimerCard(timer: timer) { store.stopTimer(timer.id) }
        }
        if !store.state.shopping.isEmpty {
          VStack(alignment: .leading, spacing: 12) {
            HCSectionHeader(title: "Le panier se remplit")
            ProgressView(
              value: Double(store.state.shopping.filter(\.isChecked).count),
              total: Double(store.state.shopping.count))
            Text(
              "\(store.state.shopping.filter(\.isChecked).count) sur \(store.state.shopping.count) articles achetés"
            ).font(.subheadline).foregroundStyle(HC.secondary)
          }.hcCard()
        }
        carousel("À refaire avec plaisir", recipes: store.state.recipes.filter(\.isFavorite))
        carousel(
          "Feuilletées récemment",
          recipes: store.state.recipes.filter { $0.lastViewedAt != nil }.sorted {
            $0.lastViewedAt! > $1.lastViewedAt!
          })
        if let suggestion {
          VStack(alignment: .leading, spacing: 16) {
            HCSectionHeader(title: "L’idée du jour", subtitle: "Et si on essayait ça ?")
            NavigationLink {
              RecipeDetailView(recipeID: suggestion.id)
            } label: {
              HCRecipeCard(recipe: suggestion)
            }.buttonStyle(.plain)
          }
        }
        if store.state.pantry.contains(where: { $0.expiresSoon() }) {
          NavigationLink {
            PantryView()
          } label: {
            Label("Quelques produits à utiliser bientôt", systemImage: "leaf").frame(
              maxWidth: .infinity, alignment: .leading
            ).hcCard()
          }
        }
        Text("« Un bon plat peut sauver une journée. »").font(HC.title(.title3)).italic()
          .foregroundStyle(HC.secondary).frame(maxWidth: .infinity).padding(.vertical, 12)
      }.padding(20).frame(maxWidth: 1100)
    }.frame(maxWidth: .infinity).hcPage().navigationTitle("Le carnet")
      .navigationBarTitleDisplayMode(.inline)
      .sheet(isPresented: $random) { RandomRecipeView() }
      .sheet(isPresented: $add) {
        RecipeEditorView(recipe: Recipe(servings: store.state.settings.defaultServings))
      }
      .sheet(isPresented: $importing) { ImportView() }
      .fullScreenCover(isPresented: $cooking) { CookingView() }
  }
  private var todayCard: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        HCSectionHeader(
          title: "Aujourd’hui", subtitle: "Un peu d’organisation, beaucoup de plaisir.")
        NavigationLink {
          WeekView()
        } label: {
          Image(systemName: "arrow.up.right").frame(width: 44, height: 44)
        }.accessibilityLabel("Voir le planning")
      }
      if today.isEmpty {
        NavigationLink {
          WeekView()
        } label: {
          VStack(alignment: .leading, spacing: 18) {
            if let suggestion {
              HCPhotoHero(recipe: suggestion, height: 220).clipShape(
                RoundedRectangle(cornerRadius: 18))
            }
            Label("Qu’est-ce qu’on prépare ?", systemImage: "calendar.badge.plus").font(.headline)
          }
        }.buttonStyle(.plain)
      } else {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 220))], spacing: 12) {
          ForEach(today) { meal in
            if let r = store.state.recipe(meal.recipeID), meal.kind == .recipe {
              NavigationLink {
                RecipeDetailView(recipeID: r.id)
              } label: {
                HCMealSlot(slot: meal.slot, entry: meal, recipe: r)
              }.buttonStyle(.plain)
            } else {
              HCMealSlot(slot: meal.slot, entry: meal, recipe: nil)
            }
          }
        }
      }
    }.hcCard()
  }
  private func quickAction(
    _ title: String, _ symbol: String, _ subtitle: String, action: @escaping () -> Void
  ) -> some View {
    Button(action: action) { quickLabel(title, symbol, subtitle) }.buttonStyle(.plain)
  }
  private func quickLabel(_ title: String, _ symbol: String, _ subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Image(systemName: symbol).font(.title2).foregroundStyle(HC.accent)
      Text(title).font(.headline)
      Text(subtitle).font(.caption).foregroundStyle(HC.secondary)
    }.frame(maxWidth: .infinity, alignment: .leading).hcCard(16)
  }
  @ViewBuilder private func carousel(_ title: String, recipes: [Recipe]) -> some View {
    if !recipes.isEmpty {
      VStack(spacing: 14) {
        HCSectionHeader(title: title)
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(alignment: .top, spacing: 16) {
            ForEach(Array(recipes.prefix(8))) { r in
              NavigationLink {
                RecipeDetailView(recipeID: r.id)
              } label: {
                HCRecipeCard(recipe: r, horizontal: true).frame(width: 265)
              }.buttonStyle(.plain)
            }
          }
        }
      }
    }
  }
}
struct RandomRecipeView: View {
  @EnvironmentObject private var store: HubStore
  @Environment(\.dismiss) private var dismiss
  @State private var current: Recipe? = nil
  @State private var quick = false
  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 24) {
          HCSectionHeader(title: "Ce soir, on se laisse surprendre.")
          Toggle("Rapide : 25 minutes maximum", isOn: $quick).onChange(of: quick) { _, _ in choose()
          }
          if let current {
            NavigationLink {
              RecipeDetailView(recipeID: current.id)
            } label: {
              HCRecipeCard(recipe: current)
            }.buttonStyle(.plain)
            HCPrimaryButton(title: "Une autre idée", symbol: "shuffle", action: choose)
          } else {
            HCEmptyState(
              title: "Aucune idée disponible",
              message: "Ajoutez une recette ou adaptez vos filtres et aliments exclus.")
          }
        }.padding(24)
      }.hcPage().navigationTitle("Surprise").toolbar {
        ToolbarItem(placement: .cancellationAction) { Button("Fermer") { dismiss() } }
      }
    }.onAppear(perform: choose)
  }
  private func choose() {
    var f = RecipeFilter()
    f.quick = quick
    let list = Search.results(store.state, filter: f)
    current = list.filter { $0.id != current?.id }.randomElement() ?? list.first
  }
}
