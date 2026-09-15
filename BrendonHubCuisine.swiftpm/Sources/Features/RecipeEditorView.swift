import AVFoundation
import PhotosUI
import SwiftUI

struct RecipeEditorView: View {
  @EnvironmentObject private var store: HubStore
  @Environment(\.dismiss) private var dismiss
  @Environment(\.horizontalSizeClass) private var sizeClass
  @State var recipe: Recipe
  var importWarnings: [String] = []
  @State private var page = 0
  @State private var tags = ""
  @State private var photo: PhotosPickerItem? = nil
  @State private var camera = false
  @State private var loading = false
  @State private var localError: String? = nil
  @State private var duplicate = false
  @State private var discard = false
  @State private var initial = true
  @State private var saved = false
  private let pages = ["La recette", "Ingrédients", "Préparation", "Les détails"]
  private var valid: Bool {
    !recipe.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      && !recipe.ingredients.isEmpty && !recipe.steps.isEmpty
      && recipe.ingredients.allSatisfy { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
      && recipe.steps.allSatisfy {
        !$0.instruction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      }
  }
  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack {
            ForEach(pages.indices, id: \.self) { i in
              HCFilterChip(title: "\(i+1). \(pages[i])", active: page == i) { page = i }
            }
          }.padding(16)
        }
        if let localError { HCErrorState(message: localError).padding(.horizontal) }
        if loading { HCSkeleton().padding(.horizontal) }
        if sizeClass == .regular {
          HStack(alignment: .top, spacing: 0) {
            ScrollView {
              VStack(alignment: .leading, spacing: 16) {
                HCPhotoHero(recipe: recipe, height: 260).clipShape(
                  RoundedRectangle(cornerRadius: 22))
                Text(recipe.name.isEmpty ? "Ta prochaine création" : recipe.name).font(
                  HC.title(.title))
                Text("Un brouillon est conservé automatiquement.").font(.caption).foregroundStyle(
                  HC.secondary)
              }.padding(20)
            }.frame(width: 280)
            editorForm
          }
        } else {
          editorForm
        }
        HStack {
          if page > 0 { HCSecondaryButton(title: "Retour", symbol: "chevron.left") { page -= 1 } }
          HCPrimaryButton(
            title: page < 3 ? "Continuer" : "Enregistrer",
            symbol: page < 3 ? "arrow.right" : "checkmark"
          ) { if page < 3 { page += 1 } else { attemptSave() } }.disabled(loading)
        }.padding(16).background(.regularMaterial)
      }.hcPage().navigationTitle(
        importWarnings.isEmpty ? "Écrire une recette" : "Vérifier l’import"
      ).navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) { Button("Fermer") { dismiss() } }
          ToolbarItem(placement: .primaryAction) {
            Menu {
              Button("Supprimer ce brouillon", role: .destructive) { discard = true }
            } label: {
              Image(systemName: "ellipsis.circle")
            }
          }
        }
        .onAppear {
          if initial {
            tags = recipe.tags.joined(separator: ", ")
            if let draft = store.state.drafts.first(where: { $0.id == recipe.id }) {
              recipe = draft
              tags = draft.tags.joined(separator: ", ")
            }
            initial = false
          }
        }
        .onChange(of: recipe) { _, _ in persistDraft() }
        .onChange(of: tags) { _, value in
          recipe.tags = value.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        }
        .onChange(of: photo) { _, item in
          Task {
            do {
              loading = true
              defer { loading = false }
              if let data = try await item?.loadTransferable(type: Data.self) {
                recipe.photoData = try PhotoService.prepared(data)
                recipe.photoAsset = ""
                recipe.photoURL = ""
              }
            } catch { localError = error.localizedDescription }
          }
        }
        .fullScreenCover(isPresented: $camera) {
          CameraPicker { data in
            do {
              recipe.photoData = try PhotoService.prepared(data)
              recipe.photoAsset = ""
              recipe.photoURL = ""
            } catch { localError = error.localizedDescription }
          }
        }
        .confirmationDialog(
          "Une recette au même nom ou avec la même source existe déjà.", isPresented: $duplicate,
          titleVisibility: .visible
        ) {
          Button("Enregistrer une recette supplémentaire") { save() }
          Button("Revenir au formulaire", role: .cancel) {}
        }
        .confirmationDialog(
          "Supprimer le brouillon ? La recette enregistrée reste disponible.",
          isPresented: $discard, titleVisibility: .visible
        ) {
          Button("Supprimer le brouillon", role: .destructive) {
            saved = true
            store.change { $0.drafts.removeAll { $0.id == recipe.id } }
            dismiss()
          }
        }
    }
  }
  private var editorForm: some View {
    Form {
      if !importWarnings.isEmpty {
        Section("À vérifier avant de sauvegarder") {
          ForEach(importWarnings, id: \.self) {
            Text($0).font(.footnote).foregroundStyle(HC.secondary)
          }
          if !recipe.sourceText.isEmpty {
            DisclosureGroup("Texte d’origine") { Text(recipe.sourceText).textSelection(.enabled) }
          }
        }
      }
      switch page {
      case 0: identity
      case 1: ingredientFields
      case 2: stepFields
      default: details
      }
    }.scrollContentBackground(.hidden)
  }
  private var identity: some View {
    Group {
      Section("L’essentiel") {
        TextField("Nom de la recette *", text: $recipe.name, axis: .vertical)
        Picker("Catégorie", selection: $recipe.category) {
          ForEach(RecipeCategory.allCases) { Text($0.rawValue).tag($0) }
        }
        Picker("Difficulté", selection: $recipe.difficulty) {
          ForEach(Difficulty.allCases) { Text($0.rawValue).tag($0) }
        }
        Stepper("\(recipe.timeMinutes) minutes", value: $recipe.timeMinutes, in: 0...1440, step: 5)
        Stepper("\(recipe.servings) portions", value: $recipe.servings, in: 1...100)
        optionalNumber("Coût total estimé (€)", value: $recipe.estimatedCostEUR)
        TextField("Emoji", text: $recipe.emoji)
        TextField("Tags séparés par des virgules", text: $tags)
      }
      Section("La photo") {
        if sizeClass != .regular {
          HCPhotoHero(recipe: recipe, height: 190).clipShape(RoundedRectangle(cornerRadius: 16))
        }
        PhotosPicker(selection: $photo, matching: .images) {
          Label("Choisir dans Photos", systemImage: "photo.on.rectangle").frame(minHeight: 44)
        }
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
          Button {
            Task {
              let ok = await AVCaptureDevice.requestAccess(for: .video)
              if ok {
                camera = true
              } else {
                localError =
                  "Accès à l’appareil photo refusé. Vous pouvez choisir une photo existante."
              }
            }
          } label: {
            Label("Prendre une photo", systemImage: "camera").frame(minHeight: 44)
          }
        }
        TextField("URL de l’image", text: $recipe.photoURL).textInputAutocapitalization(.never)
          .keyboardType(.URL)
        Button("Télécharger cette photo") {
          Task {
            do {
              loading = true
              defer { loading = false }
              recipe.photoData = try PhotoService.prepared(
                await NetworkImport.read(recipe.photoURL, limit: 20_000_000))
              recipe.photoAsset = ""
            } catch { localError = error.localizedDescription }
          }
        }.disabled(recipe.photoURL.isEmpty || loading)
        if recipe.photoData != nil || !recipe.photoAsset.isEmpty {
          Button("Retirer la photo", role: .destructive) {
            recipe.photoData = nil
            recipe.photoAsset = ""
            recipe.photoURL = ""
          }
        }
      }
    }
  }
  private var ingredientFields: some View {
    Group {
      Section {
        Text(
          "Conserve une quantité libre si elle n’est pas calculable, par exemple « selon goût ». Les unités compatibles seront adaptées aux portions."
        ).font(.footnote).foregroundStyle(HC.secondary)
      }
      ForEach($recipe.ingredients) { $i in
        Section {
          TextField("Nom de l’ingrédient *", text: $i.name)
          TextField(
            "Quantité : 250 g, ½ sachet…",
            text: Binding(
              get: { i.originalQuantityText },
              set: { value in
                let parsed = Quantity.parse(value)
                i.originalQuantityText = value
                i.amount = parsed.0
                i.unit = parsed.1
              }))
          TextField("Rayon", text: $i.aisle)
          optionalNumber("Prix de cette quantité (€)", value: $i.priceEUR)
          HStack {
            Button("Monter", systemImage: "arrow.up") { moveIngredient(i.id, by: -1) }.disabled(
              recipe.ingredients.first?.id == i.id)
            Spacer()
            Button("Descendre", systemImage: "arrow.down") { moveIngredient(i.id, by: 1) }.disabled(
              recipe.ingredients.last?.id == i.id)
            Spacer()
            Button("Retirer", role: .destructive) { recipe.ingredients.removeAll { $0.id == i.id } }
          }.font(.caption).buttonStyle(.borderless)
        }
      }
      Button {
        recipe.ingredients.append(Ingredient())
      } label: {
        Label("Ajouter un ingrédient", systemImage: "plus.circle").frame(minHeight: 44)
      }
    }
  }
  private var stepFields: some View {
    Group {
      ForEach($recipe.steps) { $step in
        Section {
          TextField("Titre de l’étape", text: $step.title)
          TextField("Instruction *", text: $step.instruction, axis: .vertical).lineLimit(3...12)
          Stepper(
            "Minuteur : \(step.timerSeconds/60) min",
            value: Binding(get: { step.timerSeconds / 60 }, set: { step.timerSeconds = $0 * 60 }),
            in: 0...1440)
          HStack {
            Button("Monter", systemImage: "arrow.up") { moveStep(step.id, by: -1) }.disabled(
              recipe.steps.first?.id == step.id)
            Spacer()
            Button("Descendre", systemImage: "arrow.down") { moveStep(step.id, by: 1) }.disabled(
              recipe.steps.last?.id == step.id)
            Spacer()
            Button("Retirer", role: .destructive) { recipe.steps.removeAll { $0.id == step.id } }
          }.font(.caption).buttonStyle(.borderless)
        }
      }
      Button {
        recipe.steps.append(RecipeStep(title: "Étape \(recipe.steps.count+1)"))
      } label: {
        Label("Ajouter une étape", systemImage: "plus.circle").frame(minHeight: 44)
      }
    }
  }
  private var details: some View {
    Group {
      Section("Notes et source") {
        TextField("Astuces et variantes", text: $recipe.notes, axis: .vertical).lineLimit(4...12)
        TextField("Lien d’origine", text: $recipe.sourceURL).textInputAutocapitalization(.never)
          .keyboardType(.URL)
      }
      Section("Nutrition par portion — facultative") {
        optionalNumber("Calories (kcal)", value: $recipe.nutrition.calories)
        optionalNumber("Protéines (g)", value: $recipe.nutrition.protein)
        optionalNumber("Glucides (g)", value: $recipe.nutrition.carbs)
        optionalNumber("Lipides (g)", value: $recipe.nutrition.fat)
      }
      Section("Dans le carnet") {
        Toggle("Favori", isOn: $recipe.isFavorite)
        Stepper(
          "Note : \(Quantity.number(recipe.rating))/5", value: $recipe.rating, in: 0...5, step: 0.5)
        Text("\(recipe.ingredients.count) ingrédients · \(recipe.steps.count) étapes")
          .foregroundStyle(HC.secondary)
      }
    }
  }
  private func optionalNumber(_ title: String, value: Binding<Double?>) -> some View {
    HStack {
      Text(title)
      TextField(
        "—",
        text: Binding(
          get: { value.wrappedValue.map(Quantity.number) ?? "" },
          set: {
            let v = $0.replacingOccurrences(of: ",", with: ".")
            value.wrappedValue = Double(v).map { max(0, $0) }
          })
      ).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
    }
  }
  private func moveIngredient(_ id: UUID, by delta: Int) {
    guard let i = recipe.ingredients.firstIndex(where: { $0.id == id }),
      recipe.ingredients.indices.contains(i + delta)
    else { return }
    recipe.ingredients.swapAt(i, i + delta)
  }
  private func moveStep(_ id: UUID, by delta: Int) {
    guard let i = recipe.steps.firstIndex(where: { $0.id == id }),
      recipe.steps.indices.contains(i + delta)
    else { return }
    recipe.steps.swapAt(i, i + delta)
  }
  private func persistDraft() {
    guard !initial, !saved else { return }
    store.change { s in
      if let i = s.drafts.firstIndex(where: { $0.id == recipe.id }) {
        s.drafts[i] = recipe
      } else {
        s.drafts.append(recipe)
      }
    }
  }
  private func attemptSave() {
    guard valid else {
      localError =
        "Renseignez un nom, au moins un ingrédient nommé et une étape avec une instruction. Le brouillon est conservé."
      return
    }
    if !store.state.duplicateCandidates(for: recipe).isEmpty { duplicate = true } else { save() }
  }
  private func save() {
    if store.updateRecipe(recipe) {
      saved = true
      dismiss()
    }
  }
}
