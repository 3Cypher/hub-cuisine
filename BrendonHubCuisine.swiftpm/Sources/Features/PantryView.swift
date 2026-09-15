import SwiftUI

struct PantryView: View {
  @EnvironmentObject private var store: HubStore
  @State private var zone: PantryZone = .fridge
  @State private var editing: PantryItem? = nil
  @State private var deleting: PantryItem? = nil
  private var items: [PantryItem] {
    store.state.pantry.filter { $0.zone == zone }.sorted {
      ($0.expiryDate ?? .distantFuture) < ($1.expiryDate ?? .distantFuture)
    }
  }
  var body: some View {
    List {
      Section {
        HCSectionHeader(
          title: "Ce qu’il reste de bon", subtitle: "Une idée commence souvent dans le frigo."
        ).padding(.vertical, 12)
        Picker("Zone", selection: $zone) {
          ForEach(PantryZone.allCases) { Text($0.rawValue).tag($0) }
        }.pickerStyle(.segmented)
        NavigationLink {
          PantryIdeasView()
        } label: {
          Label("Cuisiner avec ce que j’ai", systemImage: "leaf.circle").font(.headline).frame(
            minHeight: 48)
        }
      }.listRowBackground(HC.surface)
      if items.isEmpty {
        HCEmptyState(
          title: "Un espace à remplir",
          message: "Ajoute tes produits ou range un article acheté depuis la liste de courses.",
          symbol: "refrigerator"
        ).listRowBackground(Color.clear)
      }
      ForEach(items) { item in
        Button {
          editing = item
        } label: {
          HStack(alignment: .top, spacing: 12) {
            Image(
              systemName: item.isStaple
                ? "infinity.circle" : item.needsRestock ? "basket" : "shippingbox"
            ).font(.title2).foregroundStyle(HC.accent).frame(width: 35)
            VStack(alignment: .leading, spacing: 7) {
              Text(item.ingredient.name).font(.headline)
              Text(item.ingredient.quantity).font(.subheadline).foregroundStyle(HC.secondary)
              if let expiry = item.expiryDate {
                Label(
                  "\(Day.key(expiry) < Day.key(Date()) ? "Date dépassée" : "À utiliser avant") : \(expiry.formatted(.dateTime.day().month().year()))",
                  systemImage: "calendar"
                ).font(.caption).foregroundStyle(item.expiresSoon() ? HC.danger : HC.secondary)
              }
              if item.needsRestock {
                Label("À racheter", systemImage: "basket").font(.caption).foregroundStyle(HC.accent)
              }
              if item.isStaple {
                Text("Basique toujours disponible").font(.caption).foregroundStyle(HC.secondary)
              }
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(HC.secondary)
          }.frame(minHeight: 56).padding(.vertical, 8)
        }.buttonStyle(.plain).listRowBackground(HC.surface)
          .swipeActions {
            Button("Retirer", role: .destructive) { deleting = item }
            Button("Racheter") {
              store.change("Produit ajouté aux courses", undo: true) {
                ShoppingLogic.add(item.ingredient, to: &$0.shopping)
              }
            }.tint(HC.accent)
          }
      }
    }.scrollContentBackground(.hidden).hcPage().navigationTitle("Garde-manger")
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button {
            editing = PantryItem(zone: zone)
          } label: {
            Image(systemName: "plus").frame(width: 44, height: 44)
          }.accessibilityLabel("Ajouter un produit")
        }
      }
      .sheet(item: $editing) { PantryEditorView(item: $0) }
      .confirmationDialog(
        "Retirer ce produit du garde-manger ?",
        isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }),
        titleVisibility: .visible
      ) {
        Button("Produit consommé ou retiré") { remove(wasted: false) }
        Button("Produit jeté", role: .destructive) { remove(wasted: true) }
      }
  }
  private func remove(wasted: Bool) {
    guard let item = deleting else { return }
    store.change("Produit retiré", undo: true) { s in
      s.pantry.removeAll { $0.id == item.id }
      if wasted { s.waste.append(WasteEvent(name: item.ingredient.name)) }
    }
    deleting = nil
  }
}
struct PantryEditorView: View {
  @EnvironmentObject private var store: HubStore
  @Environment(\.dismiss) private var dismiss
  @State var item: PantryItem
  var shoppingID: UUID? = nil
  var body: some View {
    NavigationStack {
      Form {
        Section("Le produit") {
          TextField("Nom", text: $item.ingredient.name)
          TextField(
            "Quantité : 500 g, 1 l…",
            text: Binding(
              get: { item.ingredient.quantity },
              set: {
                let parsed = Quantity.parse($0)
                item.ingredient.amount = parsed.0
                item.ingredient.unit = parsed.1
                item.ingredient.originalQuantityText = $0
              }))
          Picker("Où le ranger ?", selection: $item.zone) {
            ForEach(PantryZone.allCases) { Text($0.rawValue).tag($0) }
          }
          TextField("Rayon du magasin", text: $item.ingredient.aisle)
          Toggle("Toujours disponible (basique)", isOn: $item.isStaple)
          Toggle("À racheter", isOn: $item.needsRestock)
        }
        Section("Dates et notes") {
          Toggle(
            "Noter la date d’ouverture",
            isOn: Binding(get: { item.openedAt != nil }, set: { item.openedAt = $0 ? Date() : nil })
          )
          if item.openedAt != nil {
            DatePicker(
              "Ouvert le",
              selection: Binding(get: { item.openedAt ?? Date() }, set: { item.openedAt = $0 }),
              displayedComponents: .date)
          }
          Toggle(
            "Noter la date de péremption",
            isOn: Binding(
              get: { item.expiryDate != nil },
              set: { item.expiryDate = $0 ? Day.adding(7, to: Date()) : nil }))
          if item.expiryDate != nil {
            DatePicker(
              "Date indiquée",
              selection: Binding(get: { item.expiryDate ?? Date() }, set: { item.expiryDate = $0 }),
              displayedComponents: .date)
          }
          TextField("Notes", text: $item.notes, axis: .vertical).lineLimit(3...8)
        }
        if shoppingID != nil {
          Section {
            Text(
              "L’article sera retiré des courses et ajouté au garde-manger. Les lots restent séparés pour conserver leurs dates."
            ).font(.footnote).foregroundStyle(HC.secondary)
          }
        }
      }.scrollContentBackground(.hidden).hcPage().navigationTitle(
        shoppingID == nil ? "Mon produit" : "Ranger les courses"
      ).toolbar {
        ToolbarItem(placement: .cancellationAction) { Button("Annuler") { dismiss() } }
        ToolbarItem(placement: .confirmationAction) {
          Button("Enregistrer") {
            if store.change(
              "Produit enregistré", undo: true,
              { s in
                if let i = s.pantry.firstIndex(where: { $0.id == item.id }) {
                  s.pantry[i] = item
                } else {
                  s.pantry.append(item)
                }
                if let shoppingID { s.shopping.removeAll { $0.id == shoppingID } }
              })
            {
              dismiss()
            }
          }.disabled(item.ingredient.name.trimmingCharacters(in: .whitespaces).isEmpty)
        }
      }
    }
  }
}
struct PantryIdeasView: View {
  @EnvironmentObject private var store: HubStore
  @State private var zero = false
  @State private var urgent = false
  @State private var quick = false
  @State private var budget = false
  @State private var servings = 2
  @State private var category: RecipeCategory? = nil
  private var matches: [PantryMatch] {
    var f = RecipeFilter()
    f.quick = quick
    f.budget = budget
    f.category = category
    var result = PantryLogic.matching(
      Search.results(store.state, filter: f), pantry: store.state.pantry, servings: servings)
    if zero { result = result.filter { $0.percentage == 100 } }
    if urgent { result = result.filter { $0.urgent > 0 }.sorted { $0.urgent > $1.urgent } }
    return result
  }
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        HCSectionHeader(
          title: "De ton frigo à l’assiette",
          subtitle:
            "Les noms des ingrédients et les unités doivent correspondre. Les quantités libres restent à vérifier."
        )
        Stepper("\(servings) portions", value: $servings, in: 1...24)
        ScrollView(.horizontal, showsIndicators: false) {
          HStack {
            HCFilterChip(title: "Zéro course", active: zero) { zero.toggle() }
            HCFilterChip(title: "Anti-gaspillage", active: urgent) { urgent.toggle() }
            HCFilterChip(title: "Rapide", active: quick) { quick.toggle() }
            HCFilterChip(title: "Petit budget", active: budget) { budget.toggle() }
          }
        }
        Picker("Catégorie", selection: $category) {
          Text("Toutes").tag(Optional<RecipeCategory>.none)
          ForEach(RecipeCategory.allCases) { Text($0.rawValue).tag(Optional($0)) }
        }
        if matches.isEmpty {
          HCEmptyState(
            title: "Pas encore de correspondance",
            message: "Ajoute tes produits, ajuste les portions ou élargis les filtres.",
            symbol: "leaf")
        }
        ForEach(matches) { match in
          VStack(alignment: .leading, spacing: 14) {
            NavigationLink {
              RecipeDetailView(recipeID: match.id)
            } label: {
              HCRecipeCard(recipe: match.recipe)
            }.buttonStyle(.plain)
            HStack {
              Label("\(match.percentage) % disponibles", systemImage: "checkmark.circle")
                .foregroundStyle(HC.success)
              Spacer()
              if match.urgent > 0 {
                Label("\(match.urgent) à utiliser", systemImage: "leaf").font(.caption)
              }
            }
            if !match.missing.isEmpty {
              Text("À prévoir : " + match.missing.map(\.name).joined(separator: ", ")).font(
                .subheadline
              ).foregroundStyle(HC.secondary)
              HCSecondaryButton(title: "Ajouter ce qui manque", symbol: "basket") {
                store.change("Ingrédients manquants ajoutés", undo: true) { s in
                  for i in match.missing {
                    ShoppingLogic.add(i, recipe: match.recipe, to: &s.shopping)
                  }
                }
              }
            }
          }.padding(.bottom, 16)
        }
      }.padding(20).frame(maxWidth: 900)
    }.frame(maxWidth: .infinity).hcPage().navigationTitle("Cuisiner avec ce que j’ai")
      .navigationBarTitleDisplayMode(.inline).onAppear {
        servings = store.state.settings.defaultServings
      }
  }
}
