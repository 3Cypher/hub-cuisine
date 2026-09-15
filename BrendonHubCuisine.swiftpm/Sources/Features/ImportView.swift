import PhotosUI
import SwiftUI

struct ImportView: View {
  @EnvironmentObject private var store: HubStore
  @Environment(\.dismiss) private var dismiss
  @State private var mode = "Texte"
  @State private var text = ""
  @State private var url = ""
  @State private var photo: PhotosPickerItem? = nil
  @State private var loading = false
  @State private var message: String? = nil
  @State private var results: [ImportResult] = []
  @State private var selected: ImportResult? = nil
  @State private var lastSelectedID: UUID? = nil
  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          HCSectionHeader(
            title: "Une trouvaille à garder",
            subtitle:
              "Un texte, un lien ou une photo. Tu vérifies toujours la recette avant de la ranger.")
          Picker("Source", selection: $mode) {
            ForEach(["Texte", "Lien", "Photo"], id: \.self) { Text($0) }
          }.pickerStyle(.segmented)
          if mode == "Lien" {
            VStack(alignment: .leading, spacing: 14) {
              TextField("https://…", text: $url).textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never).keyboardType(.URL)
              Text(
                "L’app lit les recettes structurées des pages publiques. Certains sites bloquent cet accès ; le collage du texte reste disponible."
              ).font(.footnote).foregroundStyle(HC.secondary)
              HCPrimaryButton(title: "Lire cette page", symbol: "link", action: fetchURL).disabled(
                loading || url.isEmpty)
            }.hcCard()
          } else {
            if mode == "Photo" {
              VStack(alignment: .leading, spacing: 12) {
                PhotosPicker(selection: $photo, matching: .images) {
                  Label("Choisir une photo ou capture", systemImage: "doc.text.viewfinder").frame(
                    minHeight: 48)
                }
                Text(
                  "Reconnaissance du texte sur l’appareil. Après lecture, corrige le texte ci-dessous puis analyse-le."
                ).font(.footnote).foregroundStyle(HC.secondary)
              }.hcCard()
            }
            VStack(alignment: .leading, spacing: 14) {
              Text("Texte de la recette").font(.headline)
              TextEditor(text: $text).frame(minHeight: 280).padding(8).background(
                HC.secondarySurface, in: RoundedRectangle(cornerRadius: 14))
              Text(
                "Pour une bonne détection : titre, puis « Ingrédients » et « Préparation », chaque élément sur sa ligne."
              ).font(.footnote).foregroundStyle(HC.secondary)
              HCPrimaryButton(
                title: "Analyser et vérifier", symbol: "text.magnifyingglass", action: parseText
              ).disabled(loading || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }.hcCard()
          }
          if loading { HCSkeleton() }
          if let message {
            HCErrorState(message: message)
            if mode == "Lien" {
              HCSecondaryButton(title: "Coller le texte à la place", symbol: "doc.on.clipboard") {
                mode = "Texte"
              }
            }
          }
          ForEach(results) { result in
            Button {
              lastSelectedID = result.recipe.id
              selected = result
            } label: {
              VStack(alignment: .leading, spacing: 10) {
                Text(result.recipe.name).font(HC.title(.title2))
                Text(
                  "\(result.recipe.ingredients.count) ingrédients · \(result.recipe.steps.count) étapes"
                ).foregroundStyle(HC.secondary)
                Label("Ouvrir l’écran de vérification", systemImage: "pencil.and.list.clipboard")
                  .font(.headline)
              }.frame(maxWidth: .infinity, alignment: .leading).hcCard()
            }.buttonStyle(.plain)
          }
        }.padding(20).frame(maxWidth: 850)
      }.frame(maxWidth: .infinity).hcPage().navigationTitle("Importer").toolbar {
        ToolbarItem(placement: .cancellationAction) { Button("Fermer") { dismiss() } }
      }
      .sheet(
        item: $selected,
        onDismiss: { if let id = lastSelectedID, store.recipe(id) != nil { dismiss() } }
      ) { result in RecipeEditorView(recipe: result.recipe, importWarnings: result.warnings) }
      .onChange(of: photo) { _, item in
        Task {
          do {
            loading = true
            message = nil
            results = []
            defer { loading = false }
            if let data = try await item?.loadTransferable(type: Data.self) {
              text = try await PhotoService.recognize(data)
            }
          } catch { message = error.localizedDescription }
        }
      }
    }
  }
  private func parseText() {
    do {
      message = nil
      results = [try RecipeImport.text(text)]
      selected = results.first
      lastSelectedID = results.first?.recipe.id
    } catch { message = error.localizedDescription }
  }
  private func fetchURL() {
    Task {
      do {
        loading = true
        message = nil
        results = []
        defer { loading = false }
        results = try await NetworkImport.recipes(url)
        if results.count == 1 {
          selected = results.first
          lastSelectedID = results.first?.recipe.id
        }
      } catch { message = error.localizedDescription }
    }
  }
}
