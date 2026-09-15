import SwiftUI

struct RecipeDetailView: View {
  @EnvironmentObject private var store: HubStore
  @Environment(\.dismiss) private var dismiss
  @Environment(\.horizontalSizeClass) private var sizeClass
  let recipeID: UUID
  @State private var servings = 2
  @State private var section = "Ingrédients"
  @State private var checked: Set<UUID> = []
  @State private var editing = false
  @State private var cooking = false
  @State private var delete = false
  @State private var replaceSession = false
  @State private var planning = false
  @State private var collections = false
  @State private var hasLoaded = false
  var body: some View {
    Group {
      if let r = store.recipe(recipeID) {
        detail(r)
      } else {
        HCEmptyState(title: "Recette introuvable", message: "Elle a peut-être été supprimée.")
      }
    }.hcPage().navigationBarTitleDisplayMode(.inline)
      .onAppear {
        if !hasLoaded, let r = store.recipe(recipeID) {
          servings = r.servings
          hasLoaded = true
          store.viewed(recipeID)
        }
      }
  }
  private func detail(_ r: Recipe) -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        HCPhotoHero(recipe: r, height: sizeClass == .regular ? 350 : 270).clipShape(
          RoundedRectangle(cornerRadius: 28))
        VStack(alignment: .leading, spacing: 14) {
          Text("\(r.emoji)  \(r.category.rawValue.uppercased())").font(.caption.weight(.semibold))
            .tracking(1.5).foregroundStyle(HC.accent)
          Text(r.name).font(HC.title(.largeTitle)).fixedSize(horizontal: false, vertical: true)
          LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))], spacing: 10) {
            meta("\(r.timeMinutes) min", "clock")
            meta(r.difficulty.rawValue, "chart.bar")
            if let cost = r.estimatedTotal {
              meta(cost.formatted(.currency(code: "EUR")), "eurosign.circle")
            }
            if r.rating > 0 { meta("\(Quantity.number(r.rating))/5", "star") }
          }
        }
        Stepper("\(servings) portions", value: $servings, in: 1...100).font(.headline).hcCard()
        ScrollView(.horizontal, showsIndicators: false) {
          HStack {
            ForEach(["Ingrédients", "Préparation", "Nutrition", "Notes"], id: \.self) { name in
              HCFilterChip(title: name, active: section == name) { section = name }
            }
            HCFilterChip(title: "Modifier", active: false) { editing = true }
          }
        }
        if sizeClass == .regular && section == "Ingrédients" {
          HStack(alignment: .top, spacing: 24) {
            ingredients(r).frame(maxWidth: .infinity)
            steps(r).frame(maxWidth: .infinity)
          }
        } else {
          sectionContent(r)
        }
        if !r.sourceURL.isEmpty, let url = URL(string: r.sourceURL) {
          Link(destination: url) {
            Label("Voir la recette originale", systemImage: "link").frame(minHeight: 44)
          }
        }
      }.padding(20).frame(maxWidth: 1100)
    }.frame(maxWidth: .infinity)
      .safeAreaInset(edge: .bottom) {
        HCPrimaryButton(
          title: store.state.session?.recipeID == r.id
            ? "Reprendre la recette" : "Commencer la recette", symbol: "play.fill"
        ) { begin(r) }.disabled(r.steps.isEmpty).padding(16).background(.regularMaterial)
      }
      .toolbar {
        ToolbarItemGroup(placement: .primaryAction) {
          Button {
            store.favorite(r.id)
          } label: {
            Image(systemName: r.isFavorite ? "heart.fill" : "heart")
          }.accessibilityLabel("Favori")
          Menu {
            Button("Modifier", systemImage: "pencil") { editing = true }
            Button("Ajouter au menu", systemImage: "calendar") { planning = true }
            Button("Collections", systemImage: "books.vertical") { collections = true }
            Button("Dupliquer", systemImage: "plus.square.on.square") {
              _ = store.updateRecipe(r.duplicate())
            }
            ShareLink(item: r.sharedText) { Label("Partager", systemImage: "square.and.arrow.up") }
            Button("Supprimer", systemImage: "trash", role: .destructive) { delete = true }
          } label: {
            Image(systemName: "ellipsis.circle")
          }
        }
      }
      .sheet(isPresented: $editing) { RecipeEditorView(recipe: r) }
      .sheet(isPresented: $planning) {
        MealEditorView(entry: MealPlanEntry(recipeID: r.id, servings: servings))
      }
      .sheet(isPresented: $collections) { collectionSheet(r) }
      .fullScreenCover(isPresented: $cooking) { CookingView() }
      .confirmationDialog(
        "Supprimer cette recette ?", isPresented: $delete, titleVisibility: .visible
      ) {
        Button("Supprimer", role: .destructive) {
          store.deleteRecipe(r.id)
          dismiss()
        }
      }
      .confirmationDialog(
        "Une autre recette est en cours. Remplacer sa session ? Les minuteurs continuent.",
        isPresented: $replaceSession, titleVisibility: .visible
      ) {
        Button("Commencer cette recette") { cooking = store.startCooking(r, servings: servings) }
        Button("Reprendre la session en cours") { cooking = true }
      }
  }
  private func begin(_ r: Recipe) {
    if let session = store.state.session, session.recipeID != r.id {
      replaceSession = true
    } else {
      cooking = store.startCooking(r, servings: servings)
    }
  }
  private func meta(_ label: String, _ symbol: String) -> some View {
    Label(label, systemImage: symbol).font(.caption).padding(10).frame(maxWidth: .infinity)
      .background(HC.secondarySurface, in: Capsule())
  }
  @ViewBuilder private func sectionContent(_ r: Recipe) -> some View {
    switch section {
    case "Ingrédients": ingredients(r)
    case "Préparation": steps(r)
    case "Nutrition":
      VStack(alignment: .leading, spacing: 16) {
        HCSectionHeader(
          title: "À titre indicatif",
          subtitle: "Valeurs saisies par portion, à vérifier auprès de la source.")
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 145))]) {
          nutrition("Calories", r.nutrition.calories, "kcal")
          nutrition("Protéines", r.nutrition.protein, "g")
          nutrition("Glucides", r.nutrition.carbs, "g")
          nutrition("Lipides", r.nutrition.fat, "g")
        }
      }
    default:
      VStack(alignment: .leading, spacing: 12) {
        HCSectionHeader(title: "La petite touche personnelle")
        TextEditor(
          text: Binding(
            get: { store.recipe(r.id)?.notes ?? "" },
            set: { value in
              store.change { state in
                if let i = state.recipes.firstIndex(where: { $0.id == r.id }) {
                  state.recipes[i].notes = value
                }
              }
            })
        ).frame(minHeight: 220).padding(10).background(
          HC.surface, in: RoundedRectangle(cornerRadius: 16))
        Text("Enregistré automatiquement.").font(.caption).foregroundStyle(HC.secondary)
      }
    }
  }
  private func ingredients(_ r: Recipe) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HCSectionHeader(title: "Sur le plan de travail")
      ForEach(r.ingredients) { i in
        HCIngredientRow(
          ingredient: i.scaled(from: r.servings, to: servings), checked: checked.contains(i.id)
        ) {
          if checked.contains(i.id) { checked.remove(i.id) } else { checked.insert(i.id) }
          Haptics.light()
        }
      }
      HCSecondaryButton(title: "Ajouter aux courses", symbol: "basket.badge.plus") {
        store.addToShopping(r, servings: servings)
      }
      if r.ingredients.isEmpty { Text("Aucun ingrédient renseigné.").foregroundStyle(HC.secondary) }
    }
  }
  private func steps(_ r: Recipe) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      HCSectionHeader(title: "Le fil de la recette")
      ForEach(Array(r.steps.enumerated()), id: \.element.id) { index, step in
        VStack(alignment: .leading, spacing: 10) {
          Text("\(index+1). \(step.title)").font(HC.title(.title3))
          Text(step.instruction).foregroundStyle(HC.secondary)
          if step.timerSeconds > 0 {
            Label("\(Quantity.number(Double(step.timerSeconds)/60)) min", systemImage: "timer")
              .font(.caption).foregroundStyle(HC.accent)
          }
        }.frame(maxWidth: .infinity, alignment: .leading).hcCard()
      }
    }
  }
  private func nutrition(_ title: String, _ value: Double?, _ unit: String) -> some View {
    HCStatCard(
      value: value.map { Quantity.number($0) + " " + unit } ?? "—", title: title, symbol: "leaf")
  }
  private func collectionSheet(_ r: Recipe) -> some View {
    NavigationStack {
      List {
        if store.state.collections.isEmpty { Text("Créez une collection dans Plus.") }
        ForEach(store.state.collections) { c in
          Toggle(
            c.name,
            isOn: Binding(
              get: { c.recipeIDs.contains(r.id) },
              set: { selected in
                store.change { s in
                  if let i = s.collections.firstIndex(where: { $0.id == c.id }) {
                    s.collections[i].recipeIDs.removeAll { $0 == r.id }
                    if selected { s.collections[i].recipeIDs.append(r.id) }
                  }
                }
              }))
        }
      }.navigationTitle("Ranger la recette").toolbar {
        ToolbarItem(placement: .confirmationAction) { Button("Terminé") { collections = false } }
      }.hcPage()
    }
  }
}
