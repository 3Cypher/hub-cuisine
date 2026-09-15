import SwiftUI

struct ShoppingView: View {
  @EnvironmentObject private var store: HubStore
  @State private var filter = "À acheter"
  @State private var manual = ""
  @State private var editing: ShoppingItem? = nil
  @State private var clear = false
  @State private var collapsed: Set<String> = []
  @State private var transfer: ShoppingItem? = nil
  private var items: [ShoppingItem] {
    store.state.shopping.filter {
      filter == "Tous" || (filter == "Acheté" ? $0.isChecked : !$0.isChecked)
    }
  }
  private var aisles: [String] {
    let all = Set(items.map { $0.ingredient.aisle })
    return store.state.settings.preferredAisleOrder.filter { all.contains($0) }
      + all.filter { !store.state.settings.preferredAisleOrder.contains($0) }.sorted()
  }
  var body: some View {
    List {
      Section {
        VStack(alignment: .leading, spacing: 14) {
          HCSectionHeader(
            title: "Le panier du jour",
            subtitle: "\(store.state.shopping.filter { !$0.isChecked }.count) articles à acheter")
          ProgressView(
            value: Double(store.state.shopping.filter(\.isChecked).count),
            total: Double(max(1, store.state.shopping.count)))
          Picker("Afficher", selection: $filter) {
            ForEach(["À acheter", "Acheté", "Tous"], id: \.self) { Text($0) }
          }.pickerStyle(.segmented)
        }.padding(.vertical, 8)
      }.listRowBackground(HC.surface)
      if items.isEmpty {
        HCEmptyState(
          title: store.state.shopping.isEmpty ? "Un panier tout neuf" : "Tout est coché",
          message: store.state.shopping.isEmpty
            ? "Ajoute des ingrédients depuis une recette, le planning ou le champ ci-dessous."
            : "Les articles cochés se trouvent dans « Acheté ».", symbol: "basket"
        ).listRowBackground(Color.clear)
      }
      ForEach(aisles, id: \.self) { aisle in
        let group = items.filter { $0.ingredient.aisle == aisle }.sorted { $0.order < $1.order }
        Section {
          if !collapsed.contains(aisle) {
            ForEach(group) { item in
              HCShoppingRow(item: item, check: { check(item) }, edit: { editing = item })
                .swipeActions {
                  Button("Supprimer", role: .destructive) {
                    store.change("Article supprimé", undo: true) {
                      $0.shopping.removeAll { $0.id == item.id }
                    }
                  }
                  if item.isChecked { Button("Ranger") { transfer = item }.tint(HC.success) }
                }
                .contextMenu {
                  if item.isChecked { Button("Ranger dans le garde-manger") { transfer = item } }
                  Button("Modifier") { editing = item }
                }
            }.onMove { from, to in reorder(group, from: from, to: to) }
          }
        } header: {
          Button {
            if collapsed.contains(aisle) {
              collapsed.remove(aisle)
            } else {
              collapsed.insert(aisle)
            }
          } label: {
            HStack {
              Text("\(aisle) · \(group.count)")
              Spacer()
              Image(systemName: collapsed.contains(aisle) ? "chevron.down" : "chevron.up")
            }.frame(minHeight: 44)
          }.buttonStyle(.plain)
        }.listRowBackground(HC.surface)
      }
      if !store.state.recentShopping.isEmpty {
        Section("Les habitués") {
          ScrollView(.horizontal, showsIndicators: false) {
            HStack {
              ForEach(Array(store.state.recentShopping.prefix(12))) { i in
                Button(i.name) {
                  store.change("Article ajouté", undo: true) {
                    ShoppingLogic.add(i, to: &$0.shopping)
                  }
                }.buttonStyle(.bordered).tint(HC.accent)
              }
            }.padding(.vertical, 8)
          }
        }.listRowBackground(HC.surface)
      }
    }.scrollContentBackground(.hidden).hcPage().navigationTitle("Courses")
      .safeAreaInset(edge: .bottom) {
        HStack {
          TextField("Ajouter un produit…", text: $manual).textFieldStyle(.roundedBorder).onSubmit(
            addManual)
          Button(action: addManual) {
            Image(systemName: "plus.circle.fill").font(.title).frame(width: 44, height: 44)
          }.disabled(manual.trimmingCharacters(in: .whitespaces).isEmpty).accessibilityLabel(
            "Ajouter le produit")
        }.padding(16).background(.regularMaterial)
      }
      .toolbar {
        ToolbarItemGroup(placement: .primaryAction) {
          EditButton()
          ShareLink(item: ShoppingLogic.sharedText(store.state.shopping)) {
            Image(systemName: "square.and.arrow.up")
          }
          Button {
            clear = true
          } label: {
            Image(systemName: "trash")
          }.disabled(store.state.shopping.isEmpty).accessibilityLabel("Vider la liste")
        }
      }
      .sheet(item: $editing) { ShoppingEditorView(item: $0) }
      .sheet(item: $transfer) { item in
        PantryEditorView(item: PantryItem(ingredient: item.ingredient), shoppingID: item.id)
      }
      .confirmationDialog(
        "Vider la liste de courses ?", isPresented: $clear, titleVisibility: .visible
      ) {
        Button("Tout vider", role: .destructive) {
          store.change("Liste vidée", undo: true) { $0.shopping = [] }
        }
        Button("Retirer seulement les articles achetés") {
          store.change("Articles achetés retirés", undo: true) {
            $0.shopping.removeAll(where: \.isChecked)
          }
        }
      }
  }
  private func addManual() {
    let name = manual.trimmingCharacters(in: .whitespaces)
    guard !name.isEmpty else { return }
    let item = RecipeImport.ingredientLine(name)
    if store.change("Article ajouté", undo: true, { ShoppingLogic.add(item, to: &$0.shopping) }) {
      manual = ""
    }
  }
  private func check(_ item: ShoppingItem) {
    store.change { s in
      if let i = s.shopping.firstIndex(where: { $0.id == item.id }) {
        s.shopping[i].isChecked.toggle()
        if s.shopping[i].isChecked {
          s.recentShopping.removeAll {
            Search.normalize($0.name) == Search.normalize(item.ingredient.name)
          }
          s.recentShopping.insert(item.ingredient, at: 0)
          s.recentShopping = Array(s.recentShopping.prefix(30))
        }
      }
    }
    Haptics.light()
  }
  private func reorder(_ group: [ShoppingItem], from: IndexSet, to: Int) {
    var ordered = group
    ordered.move(fromOffsets: from, toOffset: to)
    store.change { s in
      for (order, item) in ordered.enumerated() {
        if let i = s.shopping.firstIndex(where: { $0.id == item.id }) {
          s.shopping[i].order = order
        }
      }
    }
  }
}
struct ShoppingEditorView: View {
  @EnvironmentObject private var store: HubStore
  @Environment(\.dismiss) private var dismiss
  @State var item: ShoppingItem
  var body: some View {
    NavigationStack {
      Form {
        Section("Article") {
          TextField("Nom", text: $item.ingredient.name)
          TextField(
            "Quantité",
            text: Binding(
              get: { item.ingredient.quantity },
              set: {
                let p = Quantity.parse($0)
                item.ingredient.amount = p.0
                item.ingredient.unit = p.1
                item.ingredient.originalQuantityText = $0
              }))
          TextField("Unité", text: $item.ingredient.unit)
          TextField("Rayon", text: $item.ingredient.aisle)
          Toggle("Acheté", isOn: $item.isChecked)
        }
        if !item.sourceNames.isEmpty {
          Section("Origine") { Text(item.sourceNames.joined(separator: "\n")) }
        }
      }.navigationTitle("Modifier l’article").toolbar {
        ToolbarItem(placement: .cancellationAction) { Button("Annuler") { dismiss() } }
        ToolbarItem(placement: .confirmationAction) {
          Button("Enregistrer") {
            if store.change(
              "Article modifié",
              { s in
                if let i = s.shopping.firstIndex(where: { $0.id == item.id }) {
                  s.shopping[i] = item
                }
              })
            {
              dismiss()
            }
          }.disabled(item.ingredient.name.trimmingCharacters(in: .whitespaces).isEmpty)
        }
      }.hcPage()
    }
  }
}
