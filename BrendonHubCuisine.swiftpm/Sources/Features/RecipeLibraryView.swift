import SwiftUI

struct RecipeLibraryView: View {
  @EnvironmentObject private var store: HubStore
  @State private var filter = RecipeFilter()
  @State private var limit = 12
  @State private var filters = false
  @State private var add = false
  @State private var deleteID: UUID? = nil
  @State private var planning: Recipe? = nil
  private var results: [Recipe] { Search.results(store.state, filter: filter) }
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        HCSectionHeader(
          title: "Le goût de choisir", subtitle: "\(results.count) recettes dans ton carnet")
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 12) {
            ForEach(RecipeCategory.allCases) { c in
              HCCategoryCard(
                category: c, count: store.state.recipes.filter { $0.category == c }.count,
                active: filter.category == c
              ) { filter.category = filter.category == c ? nil : c }
            }
          }
        }
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            HCFilterChip(title: "Tous", active: filter == RecipeFilter()) {
              filter = RecipeFilter()
            }
            HCFilterChip(title: "Favoris", active: filter.favorite) { filter.favorite.toggle() }
            HCFilterChip(title: "Rapide", active: filter.quick) { filter.quick.toggle() }
            HCFilterChip(title: "Petit budget", active: filter.budget) { filter.budget.toggle() }
            HCFilterChip(
              title: "Filtres",
              active: !filter.tags.isEmpty || filter.difficulty != nil || filter.collectionID != nil
            ) { filters = true }
          }
        }
        HStack {
          Text("La collection").font(HC.title(.title2))
          Spacer()
          Menu {
            Picker("Trier par", selection: $filter.sort) {
              ForEach(RecipeSort.allCases) { Text($0.rawValue).tag($0) }
            }
          } label: {
            Label(filter.sort.rawValue, systemImage: "arrow.up.arrow.down").font(.subheadline)
              .frame(minHeight: 44)
          }
        }
        if results.isEmpty {
          HCEmptyState(
            title: "Une autre envie ?", message: "Aucune recette ne correspond à ces filtres.",
            symbol: "magnifyingglass")
          HCSecondaryButton(title: "Réinitialiser", symbol: "arrow.counterclockwise") {
            filter = RecipeFilter()
          }
        } else {
          LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 265, maximum: 460), spacing: 20)], spacing: 20
          ) {
            ForEach(Array(results.prefix(limit))) { r in
              NavigationLink {
                RecipeDetailView(recipeID: r.id)
              } label: {
                HCRecipeCard(recipe: r)
              }.buttonStyle(.plain)
                .contextMenu {
                  Button(
                    r.isFavorite ? "Retirer des favoris" : "Ajouter aux favoris",
                    systemImage: "heart"
                  ) { store.favorite(r.id) }
                  Button("Ajouter au menu", systemImage: "calendar") { planning = r }
                  Button("Dupliquer", systemImage: "plus.square.on.square") {
                    _ = store.updateRecipe(r.duplicate())
                  }
                  ShareLink(item: r.sharedText) {
                    Label("Partager", systemImage: "square.and.arrow.up")
                  }
                  Button("Supprimer", systemImage: "trash", role: .destructive) { deleteID = r.id }
                }
            }
          }
          if results.count > limit {
            HCSecondaryButton(title: "Voir plus", symbol: "chevron.down") { limit += 12 }
          }
        }
      }.padding(20).frame(maxWidth: 1300)
    }.frame(maxWidth: .infinity).hcPage().navigationTitle("Recettes").searchable(
      text: $filter.query, prompt: "Nom, ingrédient, envie…"
    )
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          add = true
        } label: {
          Image(systemName: "plus").frame(width: 44, height: 44)
        }.accessibilityLabel("Ajouter une recette")
      }
    }
    .sheet(isPresented: $filters) { filterSheet }
    .sheet(isPresented: $add) {
      RecipeEditorView(recipe: Recipe(servings: store.state.settings.defaultServings))
    }
    .sheet(item: $planning) { r in
      MealEditorView(
        entry: MealPlanEntry(recipeID: r.id, servings: store.state.settings.defaultServings))
    }
    .confirmationDialog(
      "Supprimer cette recette et ses repas planifiés ?",
      isPresented: Binding(get: { deleteID != nil }, set: { if !$0 { deleteID = nil } }),
      titleVisibility: .visible
    ) {
      Button("Supprimer", role: .destructive) {
        if let deleteID { store.deleteRecipe(deleteID) }
        deleteID = nil
      }
    }
  }
  private var filterSheet: some View {
    NavigationStack {
      Form {
        Section("Préférences") {
          Picker("Difficulté", selection: $filter.difficulty) {
            Text("Toutes").tag(Optional<Difficulty>.none)
            ForEach(Difficulty.allCases) { Text($0.rawValue).tag(Optional($0)) }
          }
          Stepper(
            filter.maximumMinutes == 0
              ? "Sans durée maximale" : "Maximum \(filter.maximumMinutes) minutes",
            value: $filter.maximumMinutes, in: 0...240, step: 5)
        }
        Section("Collections") {
          Picker("Collection", selection: $filter.collectionID) {
            Text("Toutes").tag(Optional<UUID>.none)
            ForEach(store.state.collections) { Text($0.name).tag(Optional($0.id)) }
          }
        }
        Section("Tags à combiner") {
          ForEach(Array(Set(store.state.recipes.flatMap(\.tags))).sorted(), id: \.self) { tag in
            Toggle(
              tag,
              isOn: Binding(
                get: { filter.tags.contains(tag) },
                set: { if $0 { filter.tags.insert(tag) } else { filter.tags.remove(tag) } }))
          }
        }
        Button("Réinitialiser tous les filtres") { filter = RecipeFilter() }
      }.scrollContentBackground(.hidden).hcPage().navigationTitle("Affiner l’envie").toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Voir les recettes") { filters = false }
        }
      }
    }
  }
}
