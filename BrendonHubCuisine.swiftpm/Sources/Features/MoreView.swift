import SwiftUI

struct MoreView: View {
  @EnvironmentObject private var store: HubStore
  @State private var adding = false
  @State private var importing = false
  @State private var draft: Recipe? = nil
  var body: some View {
    List {
      Section {
        VStack(alignment: .leading, spacing: 8) {
          Text("Un peu plus de cuisine.").font(HC.title(.largeTitle))
          Text("Tes habitudes, tes idées et ton carnet bien rangé.").foregroundStyle(HC.secondary)
        }.padding(.vertical, 14)
      }.listRowBackground(Color.clear)
      Section("Les recettes") {
        Button {
          adding = true
        } label: {
          row("Ajouter une recette", "square.and.pencil")
        }
        Button {
          importing = true
        } label: {
          row("Importer", "square.and.arrow.down")
        }
        NavigationLink {
          CollectionsView()
        } label: {
          row("Collections", "books.vertical")
        }
        NavigationLink {
          HistoryView()
        } label: {
          row("Historique de cuisine", "clock.arrow.circlepath")
        }
      }
      if !store.state.drafts.isEmpty {
        Section("Brouillons à reprendre") {
          ForEach(store.state.drafts) { r in
            Button {
              draft = r
            } label: {
              row(r.name.isEmpty ? "Recette sans titre" : r.name, "doc")
            }
          }
        }
      }
      Section("Le quotidien") {
        NavigationLink {
          PantryView()
        } label: {
          row("Garde-manger", "refrigerator")
        }
        NavigationLink {
          PantryIdeasView()
        } label: {
          row("Cuisiner avec ce que j’ai", "leaf")
        }
        NavigationLink {
          TimersView()
        } label: {
          row("Minuteurs", "timer")
        }
        NavigationLink {
          StatisticsView()
        } label: {
          row("Statistiques", "chart.bar")
        }
      }
      Section("Mon application") {
        NavigationLink {
          SettingsView()
        } label: {
          row("Réglages", "slider.horizontal.3")
        }
        NavigationLink {
          BackupView()
        } label: {
          row("Sauvegarder et restaurer", "externaldrive")
        }
        NavigationLink {
          DiagnosticsView()
        } label: {
          row("Vérifications de l’application", "checkmark.shield")
        }
        Text("Hub Cuisine · 1.0\nUn carnet personnel, gratuit et sans compte.").font(.footnote)
          .foregroundStyle(HC.secondary).padding(.vertical, 8)
      }
    }.scrollContentBackground(.hidden).hcPage().navigationTitle("Plus")
      .sheet(isPresented: $adding) {
        RecipeEditorView(recipe: Recipe(servings: store.state.settings.defaultServings))
      }
      .sheet(isPresented: $importing) { ImportView() }
      .sheet(item: $draft) { RecipeEditorView(recipe: $0) }
  }
  private func row(_ title: String, _ symbol: String) -> some View {
    Label(title, systemImage: symbol).frame(minHeight: 44).foregroundStyle(HC.ink)
  }
}
struct TimersView: View {
  @EnvironmentObject private var store: HubStore
  @State private var adding = false
  var body: some View {
    ScrollView {
      VStack(spacing: 16) {
        if store.state.timers.isEmpty {
          HCEmptyState(
            title: "Prends ton temps",
            message: "Les minuteurs continuent lorsque tu quittes le mode cuisine.", symbol: "timer"
          )
        }
        ForEach(store.state.timers.sorted { $0.endDate < $1.endDate }) { timer in
          HCTimerCard(timer: timer) { store.stopTimer(timer.id) }
        }
        HCPrimaryButton(title: "Nouveau minuteur", symbol: "plus") { adding = true }
      }.padding(20).frame(maxWidth: 760)
    }.frame(maxWidth: .infinity).hcPage().navigationTitle("Minuteurs").sheet(isPresented: $adding) {
      TimerEditorView()
    }
  }
}
struct CollectionsView: View {
  @EnvironmentObject private var store: HubStore
  @State private var editing: RecipeCollection? = nil
  @State private var deleting: RecipeCollection? = nil
  var body: some View {
    List {
      if store.state.collections.isEmpty {
        HCEmptyState(
          title: "Un carnet à ton image",
          message:
            "Crée une collection pour les invités, les soirs pressés ou les recettes à tester.",
          symbol: "books.vertical")
      }
      ForEach(store.state.collections) { c in
        Button {
          editing = c
        } label: {
          HStack {
            Image(systemName: c.symbol).font(.title2).foregroundStyle(HC.accent).frame(width: 42)
            VStack(alignment: .leading, spacing: 5) {
              Text(c.name).font(HC.title(.title3))
              Text("\(c.recipeIDs.count) recettes").font(.caption).foregroundStyle(HC.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
          }.frame(minHeight: 60)
        }.buttonStyle(.plain).swipeActions {
          Button("Supprimer", role: .destructive) { deleting = c }
        }
      }
    }.scrollContentBackground(.hidden).hcPage().navigationTitle("Collections").toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          editing = RecipeCollection(name: "")
        } label: {
          Image(systemName: "plus").frame(width: 44, height: 44)
        }.accessibilityLabel("Créer une collection")
      }
    }.sheet(item: $editing) { CollectionEditorView(collection: $0) }.confirmationDialog(
      "Supprimer la collection ? Ses recettes restent dans le carnet.",
      isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }),
      titleVisibility: .visible
    ) {
      Button("Supprimer", role: .destructive) {
        if let id = deleting?.id {
          store.change("Collection supprimée", undo: true) {
            $0.collections.removeAll { $0.id == id }
          }
        }
        deleting = nil
      }
    }
  }
}
struct CollectionEditorView: View {
  @EnvironmentObject private var store: HubStore
  @Environment(\.dismiss) private var dismiss
  @State var collection: RecipeCollection
  var body: some View {
    NavigationStack {
      List {
        Section("Ma collection") {
          TextField("Nom", text: $collection.name)
          Picker("Symbole", selection: $collection.symbol) {
            ForEach(["books.vertical", "heart", "clock", "person.2", "leaf", "star"], id: \.self) {
              Image(systemName: $0).tag($0)
            }
          }
        }
        Section("Les recettes") {
          ForEach(store.state.recipes) { r in
            HStack {
              Toggle(
                isOn: Binding(
                  get: { collection.recipeIDs.contains(r.id) },
                  set: { selected in
                    collection.recipeIDs.removeAll { $0 == r.id }
                    if selected { collection.recipeIDs.append(r.id) }
                  })
              ) { Text(r.name) }
              NavigationLink {
                RecipeDetailView(recipeID: r.id)
              } label: {
                Image(systemName: "arrow.up.right").frame(width: 44, height: 44)
              }.accessibilityLabel("Ouvrir \(r.name)")
            }
          }
        }
      }.hcPage().navigationTitle("Ma collection").toolbar {
        ToolbarItem(placement: .cancellationAction) { Button("Annuler") { dismiss() } }
        ToolbarItem(placement: .confirmationAction) {
          Button("Enregistrer") {
            if store.change(
              "Collection enregistrée",
              { s in
                if let i = s.collections.firstIndex(where: { $0.id == collection.id }) {
                  s.collections[i] = collection
                } else {
                  s.collections.append(collection)
                }
              })
            {
              dismiss()
            }
          }.disabled(collection.name.trimmingCharacters(in: .whitespaces).isEmpty)
        }
      }
    }
  }
}
struct HistoryView: View {
  @EnvironmentObject private var store: HubStore
  var body: some View {
    List {
      if store.state.history.isEmpty {
        HCEmptyState(
          title: "Tes premiers souvenirs",
          message: "Termine une recette en mode cuisine pour la retrouver ici.",
          symbol: "clock.arrow.circlepath")
      }
      ForEach(store.state.history.sorted { $0.cookedAt > $1.cookedAt }) { entry in
        VStack(alignment: .leading, spacing: 8) {
          Text(entry.cookedAt.formatted(.dateTime.day().month(.wide).year())).font(.caption)
            .foregroundStyle(HC.accent)
          Text(entry.recipeName).font(HC.title(.title3))
          Text("\(entry.servings) portions · \(Quantity.number(entry.rating))/5").font(.subheadline)
            .foregroundStyle(HC.secondary)
          if !entry.comment.isEmpty { Text(entry.comment) }
          if store.state.recipe(entry.recipeID) != nil {
            NavigationLink("Revoir la recette") { RecipeDetailView(recipeID: entry.recipeID) }
          }
        }.padding(.vertical, 10).swipeActions {
          Button("Retirer", role: .destructive) {
            store.change("Souvenir retiré", undo: true) {
              $0.history.removeAll { $0.id == entry.id }
            }
          }
        }
      }
    }.scrollContentBackground(.hidden).hcPage().navigationTitle("Au fil des repas")
  }
}
struct StatisticsView: View {
  @EnvironmentObject private var store: HubStore
  private var average: Int {
    store.state.recipes.isEmpty
      ? 0 : store.state.recipes.reduce(0) { $0 + $1.timeMinutes } / store.state.recipes.count
  }
  private var mostCooked: [(Recipe, Int)] {
    store.state.recipes.map { r in (r, store.state.history.filter { $0.recipeID == r.id }.count) }
      .filter { $0.1 > 0 }.sorted { $0.1 > $1.1 }
  }
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        HCSectionHeader(
          title: "Ta cuisine, au fil des jours",
          subtitle: "Quelques repères, juste pour le plaisir.")
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 155))], spacing: 14) {
          HCStatCard(value: "\(store.state.recipes.count)", title: "Recettes", symbol: "book")
          HCStatCard(
            value: "\(store.state.recipes.filter(\.isFavorite).count)", title: "Favoris",
            symbol: "heart")
          HCStatCard(value: "\(average) min", title: "Durée moyenne", symbol: "clock")
          HCStatCard(
            value: "\(store.state.shopping.count)", title: "Articles de courses", symbol: "basket")
        }
        VStack(alignment: .leading, spacing: 18) {
          HCSectionHeader(title: "Les envies du carnet")
          ForEach(RecipeCategory.allCases) { c in
            let count = store.state.recipes.filter { $0.category == c }.count
            VStack(spacing: 8) {
              HStack {
                Text(c.rawValue)
                Spacer()
                Text("\(count)").monospacedDigit()
              }
              ProgressView(value: Double(count), total: Double(max(1, store.state.recipes.count)))
                .tint(HC.accent)
            }
          }
        }.hcCard()
        HCSectionHeader(title: "Les mieux notées")
        ForEach(
          Array(
            store.state.recipes.filter { $0.rating > 0 }.sorted { $0.rating > $1.rating }.prefix(5))
        ) { r in
          NavigationLink {
            RecipeDetailView(recipeID: r.id)
          } label: {
            HStack {
              Text(r.name).font(HC.title(.headline))
              Spacer()
              Label(Quantity.number(r.rating), systemImage: "star.fill").foregroundStyle(HC.accent)
            }.hcCard(16)
          }.buttonStyle(.plain)
        }
        if !mostCooked.isEmpty {
          HCSectionHeader(title: "Les habituées de la table")
          ForEach(mostCooked.prefix(5), id: \.0.id) { pair in
            HStack {
              Text(pair.0.name)
              Spacer()
              Text("\(pair.1) fois").foregroundStyle(HC.secondary)
            }.hcCard(16)
          }
        }
        HStack(alignment: .top) {
          HCStatCard(
            value: "\(store.state.history.count)", title: "Recettes cuisinées", symbol: "fork.knife"
          )
          HCStatCard(
            value: "\(store.state.waste.count)", title: "Produits signalés jetés", symbol: "leaf")
        }
        if !store.state.waste.isEmpty {
          DisclosureGroup("Produits à acheter en plus petite quantité") {
            ForEach(
              Array(Dictionary(grouping: store.state.waste, by: \.name).keys).sorted(), id: \.self
            ) { name in
              Text("\(name) · \(store.state.waste.filter { $0.name == name }.count) signalement(s)")
                .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 6)
            }
          }.hcCard()
        }
      }.padding(20).frame(maxWidth: 1000)
    }.frame(maxWidth: .infinity).hcPage().navigationTitle("Statistiques")
      .navigationBarTitleDisplayMode(.inline)
  }
}
