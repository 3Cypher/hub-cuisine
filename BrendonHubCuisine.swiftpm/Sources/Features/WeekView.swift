import SwiftUI

struct WeekView: View {
  @EnvironmentObject private var store: HubStore
  @State private var week = Day.monday(Date())
  @State private var editing: MealPlanEntry? = nil
  @State private var generate = false
  @State private var copy = false
  private var days: [Date] { (0..<7).map { Day.adding($0, to: week) } }
  private var meals: [MealPlanEntry] {
    let keys = Set(days.map(Day.key))
    return store.state.meals.filter { keys.contains($0.day) }
  }
  private var cost: (Double, Int, Int) {
    let planned = meals.filter { $0.kind == .recipe }
    var sum = 0.0
    var count = 0
    for meal in planned {
      if let r = store.state.recipe(meal.recipeID), let cost = r.estimatedTotal {
        sum += cost * Double(meal.servings) / Double(max(1, r.servings))
        count += 1
      }
    }
    return (sum, count, planned.count)
  }
  var body: some View {
    GeometryReader { geometry in
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          HStack {
            HCIconButton(symbol: "chevron.left", label: "Semaine précédente") {
              week = Day.adding(-7, to: week)
            }
            Spacer()
            VStack {
              Text(
                "\(week.formatted(.dateTime.day().month(.abbreviated))) – \(Day.adding(6, to: week).formatted(.dateTime.day().month(.abbreviated).year()))"
              ).font(HC.title(.title2))
              Button("Cette semaine") { week = Day.monday(Date()) }.font(.caption).frame(
                minHeight: 44)
            }
            Spacer()
            HCIconButton(symbol: "chevron.right", label: "Semaine suivante") {
              week = Day.adding(7, to: week)
            }
          }
          LazyVGrid(
            columns: Array(
              repeating: GridItem(.flexible(), spacing: 12, alignment: .top),
              count: geometry.size.width > 950 ? 7 : geometry.size.width > 600 ? 3 : 1),
            alignment: .leading, spacing: 16
          ) {
            ForEach(days, id: \.self) { day in
              VStack(alignment: .leading, spacing: 12) {
                Text(day.formatted(.dateTime.weekday(.abbreviated).day())).font(.headline)
                  .foregroundStyle(Day.key(day) == Day.key(Date()) ? HC.accent : HC.ink).padding(
                    .vertical, 8)
                ForEach(store.state.settings.enabledMealSlots) { slot in
                  let entry = meals.first { $0.day == Day.key(day) && $0.slot == slot }
                  VStack(alignment: .leading, spacing: 0) {
                    Button {
                      editing =
                        entry
                        ?? MealPlanEntry(
                          day: Day.key(day), slot: slot,
                          servings: store.state.settings.defaultServings)
                    } label: {
                      HCMealSlot(
                        slot: slot, entry: entry,
                        recipe: entry?.kind == .recipe ? store.state.recipe(entry?.recipeID) : nil)
                    }.buttonStyle(.plain)
                    if let entry, let recipe = store.state.recipe(entry.recipeID),
                      entry.kind == .recipe
                    {
                      NavigationLink("Ouvrir la recette") { RecipeDetailView(recipeID: recipe.id) }
                        .font(.caption).frame(minHeight: 44)
                    }
                  }
                }
              }.padding(12).background(HC.surface, in: RoundedRectangle(cornerRadius: 22))
            }
          }
          if cost.1 > 0 {
            VStack(alignment: .leading, spacing: 10) {
              HCSectionHeader(
                title: cost.0.formatted(.currency(code: "EUR")),
                subtitle:
                  "Estimation pour \(cost.1) repas sur \(cost.2). Les repas sans prix ne sont pas comptés."
              )
              if let budget = store.state.settings.weeklyBudgetEUR, budget > 0 {
                ProgressView(value: min(cost.0, budget), total: budget)
                Text("Budget indicatif : \(budget.formatted(.currency(code: "EUR")))").font(
                  .caption
                ).foregroundStyle(HC.secondary)
              }
            }.hcCard()
          }
          HCPrimaryButton(title: "Préparer les courses", symbol: "basket") { generate = true }
            .disabled(meals.filter { $0.kind == .recipe }.isEmpty)
          HCSecondaryButton(title: "Copier la semaine précédente", symbol: "doc.on.doc") {
            copy = true
          }
        }.padding(20)
      }.hcPage()
    }.navigationTitle("À table cette semaine").navigationBarTitleDisplayMode(.inline)
      .sheet(item: $editing) { MealEditorView(entry: $0) }
      .sheet(isPresented: $generate) { GenerateShoppingView(meals: meals) }
      .confirmationDialog(
        "Copier la semaine précédente ? Les repas déjà prévus cette semaine seront remplacés.",
        isPresented: $copy, titleVisibility: .visible
      ) { Button("Copier les repas") { copyPrevious() } }
  }
  private func copyPrevious() {
    let keys = Set((0..<7).map { Day.key(Day.adding($0 - 7, to: week)) })
    let previous = store.state.meals.filter { keys.contains($0.day) }
    guard !previous.isEmpty else {
      store.toast = "La semaine précédente est vide."
      return
    }
    store.change("Semaine copiée", undo: true) { s in
      let currentKeys = Set(days.map(Day.key))
      s.meals.removeAll { currentKeys.contains($0.day) }
      for var meal in previous {
        meal.id = UUID()
        meal.day = Day.key(Day.adding(7, to: Day.date(meal.day)))
        s.upsertMeal(meal)
      }
    }
  }
}
struct MealEditorView: View {
  @EnvironmentObject private var store: HubStore
  @Environment(\.dismiss) private var dismiss
  @State var entry: MealPlanEntry
  @State private var query = ""
  @State private var replace = false
  @State private var delete = false
  private var filtered: [Recipe] { Search.results(store.state, filter: RecipeFilter(query: query)) }
  var body: some View {
    NavigationStack {
      Form {
        Section("Quand passe-t-on à table ?") {
          DatePicker(
            "Jour",
            selection: Binding(get: { Day.date(entry.day) }, set: { entry.day = Day.key($0) }),
            displayedComponents: .date)
          Picker("Repas", selection: $entry.slot) {
            ForEach(store.state.settings.enabledMealSlots) { Text($0.rawValue).tag($0) }
          }
          Picker("Type", selection: $entry.kind) {
            ForEach(MealKind.allCases, id: \.self) { Text($0.rawValue).tag($0) }
          }
          Stepper("\(entry.servings) portions", value: $entry.servings, in: 1...100)
          TextField("Note facultative", text: $entry.note, axis: .vertical)
        }
        if entry.kind == .recipe {
          Section("Choisir une recette") {
            TextField("Rechercher…", text: $query)
            ForEach(filtered) { r in
              Button {
                entry.recipeID = r.id
              } label: {
                HStack {
                  VStack(alignment: .leading) {
                    Text(r.name).font(.headline)
                    Text("\(r.timeMinutes) min · \(r.category.rawValue)").font(.caption)
                      .foregroundStyle(HC.secondary)
                  }
                  Spacer()
                  if entry.recipeID == r.id {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(HC.accent)
                  }
                }.frame(minHeight: 44)
              }.buttonStyle(.plain)
            }
          }
        }
        if store.state.meals.contains(where: { $0.id == entry.id }) {
          Button("Retirer ce repas", role: .destructive) { delete = true }
        }
      }.scrollContentBackground(.hidden).hcPage().navigationTitle("Un repas à prévoir").toolbar {
        ToolbarItem(placement: .cancellationAction) { Button("Annuler") { dismiss() } }
        ToolbarItem(placement: .confirmationAction) {
          Button("Enregistrer") {
            if store.state.meals.contains(where: { $0.key == entry.key && $0.id != entry.id }) {
              replace = true
            } else {
              save()
            }
          }.disabled(entry.kind == .recipe && entry.recipeID == nil)
        }
      }
      .confirmationDialog(
        "Remplacer le repas déjà prévu à ce créneau ?", isPresented: $replace,
        titleVisibility: .visible
      ) { Button("Remplacer", action: save) }
      .confirmationDialog("Retirer ce repas ?", isPresented: $delete, titleVisibility: .visible) {
        Button("Retirer", role: .destructive) {
          store.change("Repas retiré", undo: true) { $0.meals.removeAll { $0.id == entry.id } }
          dismiss()
        }
      }
    }
  }
  private func save() {
    if entry.kind != .recipe { entry.recipeID = nil }
    if store.change("Repas enregistré", undo: true, { $0.upsertMeal(entry) }) { dismiss() }
  }
}
struct GenerateShoppingView: View {
  @EnvironmentObject private var store: HubStore
  @Environment(\.dismiss) private var dismiss
  var meals: [MealPlanEntry]
  @State private var selected: Set<UUID> = []
  var body: some View {
    NavigationStack {
      List {
        Section {
          Text(
            "Choisis les repas à inclure. Un repas déjà ajouté à la liste actuelle n’est pas ajouté une seconde fois."
          ).font(.footnote).foregroundStyle(HC.secondary)
          Button("Tout sélectionner") {
            selected = Set(meals.filter { $0.kind == .recipe }.map(\.id))
          }
        }
        ForEach(Array(Set(meals.map(\.day))).sorted(), id: \.self) { day in
          Section(Day.date(day).formatted(.dateTime.weekday(.wide).day().month())) {
            ForEach(meals.filter { $0.day == day && $0.kind == .recipe }) { meal in
              Toggle(
                isOn: Binding(
                  get: { selected.contains(meal.id) },
                  set: { if $0 { selected.insert(meal.id) } else { selected.remove(meal.id) } })
              ) {
                VStack(alignment: .leading) {
                  Text(
                    "\(meal.slot.rawValue) · \(store.state.recipe(meal.recipeID)?.name ?? "Recette")"
                  )
                  Text("\(meal.servings) portions").font(.caption).foregroundStyle(HC.secondary)
                }
              }
            }
          }
        }
      }.scrollContentBackground(.hidden).hcPage().navigationTitle("Les courses du menu").toolbar {
        ToolbarItem(placement: .cancellationAction) { Button("Annuler") { dismiss() } }
        ToolbarItem(placement: .confirmationAction) {
          Button("Générer") {
            var count = 0
            if store.change(
              nil, undo: true, { count = ShoppingLogic.generate(state: &$0, mealIDs: selected) })
            {
              store.toast =
                count > 0
                ? "\(count) repas ajoutés aux courses" : "Ces repas sont déjà dans la liste."
              dismiss()
            }
          }.disabled(selected.isEmpty)
        }
      }
    }.onAppear { selected = Set(meals.filter { $0.kind == .recipe }.map(\.id)) }
  }
}
