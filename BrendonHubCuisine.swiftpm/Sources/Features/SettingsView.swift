import SwiftData
import SwiftUI

struct SettingsView: View {
  @EnvironmentObject private var store: HubStore
  @State private var aisle = ""
  private func binding<T>(_ key: WritableKeyPath<AppSettings, T>) -> Binding<T> {
    Binding(
      get: { store.state.settings[keyPath: key] },
      set: { value in store.change { $0.settings[keyPath: key] = value } })
  }
  var body: some View {
    Form {
      Section("Identité") {
        TextField("Prénom", text: binding(\.displayName))
        Stepper(
          "\(store.state.settings.defaultServings) portions par défaut",
          value: binding(\.defaultServings), in: 1...24)
      }
      Section("Cuisine") {
        TextField(
          "Aliments exclus, séparés par des virgules", text: binding(\.excludedFoods),
          axis: .vertical)
        Text(
          "Ces mots filtrent les ingrédients des suggestions et de la bibliothèque. La vérification d’une allergie reste manuelle : les noms, variantes et traces ne sont pas tous détectés."
        ).font(.footnote).foregroundStyle(HC.secondary)
        TextField(
          "Budget de la semaine (€), facultatif",
          text: Binding(
            get: { store.state.settings.weeklyBudgetEUR.map(Quantity.number) ?? "" },
            set: { value in
              store.change {
                $0.settings.weeklyBudgetEUR = Double(value.replacingOccurrences(of: ",", with: "."))
                  .map { max(0, $0) }
              }
            })
        ).keyboardType(.decimalPad)
      }
      Section("Planning") {
        ForEach(MealSlot.allCases) { slot in
          Toggle(
            slot.rawValue,
            isOn: Binding(
              get: { store.state.settings.enabledMealSlots.contains(slot) },
              set: { enabled in
                store.change { s in
                  if enabled {
                    s.settings.enabledMealSlots.append(slot)
                  } else if s.settings.enabledMealSlots.count > 1 {
                    s.settings.enabledMealSlots.removeAll { $0 == slot }
                  }
                  s.settings.enabledMealSlots = MealSlot.allCases.filter {
                    s.settings.enabledMealSlots.contains($0)
                  }
                }
              }))
        }
        Text("Les repas des créneaux masqués restent enregistrés.").font(.footnote).foregroundStyle(
          HC.secondary)
      }
      Section("Ordre des rayons") {
        ForEach(store.state.settings.preferredAisleOrder, id: \.self) { Text($0) }.onMove {
          from, to in
          store.change { $0.settings.preferredAisleOrder.move(fromOffsets: from, toOffset: to) }
        }
        HStack {
          TextField("Nouveau rayon", text: $aisle)
          Button("Ajouter") {
            let name = aisle.trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty, !store.state.settings.preferredAisleOrder.contains(name) else {
              return
            }
            store.change { $0.settings.preferredAisleOrder.append(name) }
            aisle = ""
          }
        }
      }
      Section("Apparence et accessibilité") {
        Picker("Thème", selection: binding(\.appearance)) {
          ForEach(["Système", "Clair", "Sombre"], id: \.self) { Text($0) }
        }
        Toggle("Réduire les animations", isOn: binding(\.reduceMotion))
        Stepper(
          "Texte cuisine : \(Int(store.state.settings.cookingTextSize)) pt",
          value: binding(\.cookingTextSize), in: 20...40, step: 2)
        Button("Ouvrir les réglages de notifications") {
          if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
          }
        }
      }
      Section("Données") {
        NavigationLink("Sauvegarder ou restaurer") { BackupView() }
        Text(
          "Les recettes, photos, courses et préférences sont enregistrées sur cet appareil. Les imports par lien contactent uniquement le site demandé. Aucune API d’IA ni compte n’est utilisé."
        ).font(.footnote).foregroundStyle(HC.secondary)
      }
    }.scrollContentBackground(.hidden).hcPage().navigationTitle("Réglages").toolbar { EditButton() }
  }
}
struct BackupView: View {
  @EnvironmentObject private var store: HubStore
  @State private var exporting = false
  @State private var importing = false
  @State private var document = JSONDocument()
  @State private var preview: HubState? = nil
  @State private var confirm = false
  @State private var message: String? = nil
  @State private var success: String? = nil
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        HCSectionHeader(
          title: "Garder une copie du carnet",
          subtitle:
            "Une sauvegarde JSON contient les recettes, les photos personnelles, le planning, les courses, le garde-manger, les réglages et les sessions."
        )
        HCPrimaryButton(title: "Exporter ma sauvegarde", symbol: "square.and.arrow.up") {
          do {
            document = JSONDocument(data: try Backup.encode(store.state))
            exporting = true
          } catch { message = error.localizedDescription }
        }
        HCSecondaryButton(
          title: "Choisir une sauvegarde à restaurer", symbol: "square.and.arrow.down"
        ) { importing = true }
        if let message { HCErrorState(message: message) }
        if let success {
          Label(success, systemImage: "checkmark.circle").foregroundStyle(HC.success)
        }
        if let preview {
          VStack(alignment: .leading, spacing: 16) {
            HCSectionHeader(
              title: "Aperçu du fichier", subtitle: "Aucune donnée n’a encore été modifiée.")
            Text(
              "\(preview.recipes.count) recettes\n\(preview.shopping.count) articles de courses\n\(preview.meals.count) repas planifiés\n\(preview.pantry.count) produits\n\(preview.history.count) souvenirs de cuisine\n\(preview.drafts.count) brouillons"
            )
            HCPrimaryButton(title: "Restaurer cette sauvegarde", symbol: "arrow.clockwise") {
              confirm = true
            }
            Text(
              "Cette restauration remplace le carnet actuel. Exportez-le d’abord si vous souhaitez conserver les deux versions."
            ).font(.footnote).foregroundStyle(HC.secondary)
          }.hcCard()
        }
      }.padding(24).frame(maxWidth: 760)
    }.frame(maxWidth: .infinity).hcPage().navigationTitle("Sauvegardes")
      .fileExporter(
        isPresented: $exporting, document: document, contentType: .json,
        defaultFilename: "HubCuisine-\(Day.key(Date()))"
      ) { result in
        switch result {
        case .success:
          success = "Sauvegarde exportée."
          message = nil
        case .failure(let error): message = error.localizedDescription
        }
      }
      .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
        do {
          let url = try result.get()
          let access = url.startAccessingSecurityScopedResource()
          defer { if access { url.stopAccessingSecurityScopedResource() } }
          preview = try Backup.decode(Data(contentsOf: url))
          message = nil
          success = nil
        } catch {
          message = error.localizedDescription
          preview = nil
        }
      }
      .confirmationDialog(
        "Remplacer toutes les données actuelles par cette sauvegarde ?", isPresented: $confirm,
        titleVisibility: .visible
      ) {
        Button("Restaurer", role: .destructive) {
          if let preview, store.restore(preview) {
            self.preview = nil
            success = "Sauvegarde restaurée."
          }
        }
      }
  }
}
struct DiagnosticsView: View {
  @State private var results: [CheckResult] = []
  @State private var running = false
  var body: some View {
    List {
      Section {
        Text("Ces vérifications utilisent des exemples isolés. Votre carnet ne sera pas modifié.")
          .font(.footnote)
        Button("Exécuter les vérifications") { run() }.disabled(running)
      }
      ForEach(results) { result in
        VStack(alignment: .leading, spacing: 6) {
          Label(
            result.name, systemImage: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill"
          ).foregroundStyle(result.passed ? HC.success : HC.danger)
          Text(result.detail).font(.caption).foregroundStyle(HC.secondary)
        }
      }
    }.hcPage().navigationTitle("Vérifications").onAppear { if results.isEmpty { run() } }
  }
  private func run() {
    running = true
    results = CoreChecks.run()
    do {
      let repo = try HubRepository(inMemory: true)
      var state = HubState()
      let recipe = Recipe(name: "Test de persistance", notes: "Une note à retrouver")
      state.seedOnce([recipe])
      try repo.save(state)
      let freshContext = ModelContext(repo.container)
      let rows = try freshContext.fetch(FetchDescriptor<HubSchemaV1.StoredRecipe>())
      let decoded = try rows.map { try JSONDecoder().decode(Recipe.self, from: $0.payload) }
      let loaded = try repo.load()
      let ok = decoded.first?.notes == recipe.notes && loaded.seeded && loaded.recipes.count == 1
      results.append(
        CheckResult(
          name: "SwiftData : sauvegarde et nouvelle lecture", passed: ok,
          detail: ok
            ? "Recette retrouvée depuis un nouveau contexte en mémoire." : "Données inattendues."))
    } catch {
      results.append(
        CheckResult(name: "SwiftData", passed: false, detail: error.localizedDescription))
    }
    running = false
  }
}
