import AVFoundation
import SwiftUI

struct CookingView: View {
  @EnvironmentObject private var store: HubStore
  @Environment(\.dismiss) private var dismiss
  @Environment(\.scenePhase) private var phase
  @ScaledMetric(relativeTo: .title2) private var textScale = 26.0
  @State private var allSteps = false
  @State private var finish = false
  @State private var customTimer = false
  @State private var previousIdle = false
  @State private var speaker = AVSpeechSynthesizer()
  var body: some View {
    Group {
      if let session = store.state.session {
        GeometryReader { geometry in
          VStack(spacing: 0) {
            header(session)
            HStack(spacing: 0) {
              if geometry.size.width > 850 {
                ScrollView { stepList(session) }.frame(width: 260).background(
                  Color.white.opacity(0.025))
              }
              ScrollView { active(session).padding(geometry.size.width > 850 ? 32 : 20) }.frame(
                maxWidth: .infinity)
            }
            controls(session)
          }
        }
      } else {
        VStack(spacing: 20) {
          HCEmptyState(
            title: "Aucune recette en cours", message: "Ouvre une recette pour commencer.",
            symbol: "fork.knife")
          Button("Fermer") { dismiss() }
        }
      }
    }.background(HC.cacao).foregroundStyle(HC.cream).tint(HC.gold).preferredColorScheme(.dark)
      .onAppear {
        previousIdle = UIApplication.shared.isIdleTimerDisabled
        UIApplication.shared.isIdleTimerDisabled = true
      }
      .onDisappear {
        UIApplication.shared.isIdleTimerDisabled = previousIdle
        speaker.stopSpeaking(at: .immediate)
      }
      .onChange(of: phase) { _, phase in
        UIApplication.shared.isIdleTimerDisabled = phase == .active ? true : previousIdle
      }
      .sheet(isPresented: $allSteps) {
        NavigationStack {
          if let session = store.state.session {
            ScrollView {
              VStack(alignment: .leading, spacing: 20) {
                HCSectionHeader(title: session.recipe.name)
                stepList(session)
                Divider()
                HCSectionHeader(title: "Ingrédients")
                ForEach(session.recipe.ingredients) { i in
                  HCIngredientRow(
                    ingredient: i.scaled(from: session.recipe.servings, to: session.servings),
                    checked: session.checkedIngredientIDs.contains(i.id)
                  ) {
                    store.change { s in
                      guard var current = s.session else { return }
                      if current.checkedIngredientIDs.contains(i.id) {
                        current.checkedIngredientIDs.removeAll { $0 == i.id }
                      } else {
                        current.checkedIngredientIDs.append(i.id)
                      }
                      s.session = current
                    }
                  }
                }
              }.padding(20)
            }.hcPage().toolbar {
              ToolbarItem(placement: .confirmationAction) {
                Button("Revenir à l’étape") { allSteps = false }
              }
            }
          }
        }
      }
      .sheet(isPresented: $finish) {
        if let session = store.state.session { FinishCookingView(session: session) { dismiss() } }
      }
      .sheet(isPresented: $customTimer) { TimerEditorView() }
  }
  private func header(_ session: CookingSession) -> some View {
    HStack(alignment: .center, spacing: 12) {
      VStack(alignment: .leading, spacing: 5) {
        Text("EN CUISINE").font(.caption.weight(.semibold)).tracking(2).foregroundStyle(HC.gold)
        Text(session.recipe.name).font(HC.title(.title3))
      }
      Spacer()
      Menu {
        Button("Toute la recette", systemImage: "list.bullet") { allSteps = true }
        Button("Lire l’instruction", systemImage: "speaker.wave.2") { speak(session) }
        Button("Agrandir le texte", systemImage: "textformat.size.larger") {
          store.change { $0.settings.cookingTextSize = min(40, $0.settings.cookingTextSize + 2) }
        }
        Button("Réduire le texte", systemImage: "textformat.size.smaller") {
          store.change { $0.settings.cookingTextSize = max(20, $0.settings.cookingTextSize - 2) }
        }
        Button("Nouveau minuteur", systemImage: "timer") { customTimer = true }
      } label: {
        Image(systemName: "ellipsis.circle").font(.title2).frame(width: 44, height: 44)
      }
      Button("Quitter") { dismiss() }.frame(minHeight: 44)
    }.padding(20).background(Color.white.opacity(0.04))
  }
  private func stepList(_ session: CookingSession) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      ForEach(Array(session.recipe.steps.enumerated()), id: \.element.id) { i, step in
        Button {
          setStep(i)
          allSteps = false
        } label: {
          HStack(alignment: .top, spacing: 12) {
            Image(
              systemName: session.checkedStepIDs.contains(step.id)
                ? "checkmark.circle.fill" : "\(min(i+1,50)).circle"
            ).font(.title2)
            VStack(alignment: .leading, spacing: 5) {
              Text(step.title).font(.headline)
              Text(step.instruction).font(.subheadline).foregroundStyle(HC.secondary)
            }
          }.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading).padding(14).background(
            i == session.stepIndex ? HC.gold.opacity(0.18) : Color.white.opacity(0.04),
            in: RoundedRectangle(cornerRadius: 16))
        }.buttonStyle(.plain)
      }
    }.padding(12)
  }
  private func active(_ session: CookingSession) -> some View {
    let index = min(max(0, session.stepIndex), max(0, session.recipe.steps.count - 1))
    return VStack(alignment: .leading, spacing: 28) {
      if session.recipe.steps.indices.contains(index) {
        let step = session.recipe.steps[index]
        HStack {
          Text("ÉTAPE \(index+1) SUR \(session.recipe.steps.count)").font(
            .caption.weight(.semibold)
          ).tracking(2)
          Spacer()
          Text("\(session.checkedStepIDs.count) terminées").font(.caption)
        }.foregroundStyle(HC.gold)
        ProgressView(
          value: Double(session.checkedStepIDs.count),
          total: Double(max(1, session.recipe.steps.count))
        ).tint(HC.gold)
        Text(step.title).font(.system(.largeTitle, design: .serif, weight: .semibold)).fixedSize(
          horizontal: false, vertical: true)
        Text(step.instruction).font(
          .system(size: textScale * store.state.settings.cookingTextSize / 26)
        ).lineSpacing(8).fixedSize(horizontal: false, vertical: true)
          .gesture(
            DragGesture(minimumDistance: 70).onEnded { value in
              if abs(value.translation.width) > abs(value.translation.height) {
                setStep(index + (value.translation.width < 0 ? 1 : -1))
              }
            })
        Button {
          store.change { s in
            guard var current = s.session else { return }
            if current.checkedStepIDs.contains(step.id) {
              current.checkedStepIDs.removeAll { $0 == step.id }
            } else {
              current.checkedStepIDs.append(step.id)
            }
            s.session = current
          }
          Haptics.light()
        } label: {
          Label(
            session.checkedStepIDs.contains(step.id)
              ? "Étape terminée" : "Marquer cette étape terminée",
            systemImage: session.checkedStepIDs.contains(step.id)
              ? "checkmark.circle.fill" : "circle"
          ).frame(minHeight: 48)
        }.buttonStyle(.bordered)
        if step.timerSeconds > 0 {
          Button {
            store.startTimer(
              name: "\(session.recipe.name) · \(step.title)", seconds: step.timerSeconds,
              recipeID: session.recipeID, stepID: step.id)
          } label: {
            Label(
              "Lancer \(Quantity.number(Double(step.timerSeconds)/60)) min", systemImage: "timer"
            ).font(.title3.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 58)
          }.buttonStyle(.borderedProminent).tint(HC.gold).foregroundStyle(HC.cacao)
        }
        ForEach(store.state.timers.filter { !$0.acknowledged }) { timer in
          HCTimerCard(timer: timer) { store.stopTimer(timer.id) }.overlay(
            RoundedRectangle(cornerRadius: 22).stroke(HC.gold.opacity(0.4)))
        }
        Button {
          speak(session)
        } label: {
          Label("Répéter l’instruction", systemImage: "speaker.wave.2").frame(minHeight: 44)
        }
      }
    }.frame(maxWidth: 760, alignment: .leading).frame(maxWidth: .infinity)
  }
  private func controls(_ session: CookingSession) -> some View {
    HStack(spacing: 12) {
      Button {
        setStep(session.stepIndex - 1)
      } label: {
        Image(systemName: "arrow.left").frame(minWidth: 52, minHeight: 56)
      }.buttonStyle(.bordered).disabled(session.stepIndex == 0).accessibilityLabel(
        "Étape précédente")
      Button {
        if session.recipe.steps.indices.contains(session.stepIndex) {
          let id = session.recipe.steps[session.stepIndex].id
          store.change {
            if $0.session?.checkedStepIDs.contains(id) == false {
              $0.session?.checkedStepIDs.append(id)
            }
          }
        }
        if session.stepIndex == session.recipe.steps.count - 1 {
          finish = true
        } else {
          setStep(session.stepIndex + 1)
        }
      } label: {
        Text(
          session.stepIndex == session.recipe.steps.count - 1
            ? "Recette terminée" : "Étape suivante"
        ).font(.headline).frame(maxWidth: .infinity, minHeight: 56)
      }.buttonStyle(.borderedProminent).tint(HC.gold).foregroundStyle(HC.cacao)
    }.padding(16).background(Color.white.opacity(0.04))
  }
  private func setStep(_ index: Int) {
    guard let session = store.state.session, session.recipe.steps.indices.contains(index) else {
      return
    }
    store.change { $0.session?.stepIndex = index }
    Haptics.light()
  }
  private func speak(_ session: CookingSession) {
    guard session.recipe.steps.indices.contains(session.stepIndex) else { return }
    speaker.stopSpeaking(at: .immediate)
    let utterance = AVSpeechUtterance(string: session.recipe.steps[session.stepIndex].instruction)
    utterance.voice = AVSpeechSynthesisVoice(language: "fr-FR")
    utterance.rate = 0.46
    speaker.speak(utterance)
  }
}
struct FinishCookingView: View {
  @EnvironmentObject private var store: HubStore
  @Environment(\.dismiss) private var dismiss
  var session: CookingSession
  var completed: () -> Void
  @State private var rating = 4.0
  @State private var comment = ""
  @State private var deduct = false
  var body: some View {
    NavigationStack {
      Form {
        Section {
          VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "checkmark.seal").font(.largeTitle).foregroundStyle(HC.success)
            Text("À table !").font(HC.title(.largeTitle))
            Text(session.recipe.name).font(.title3)
            Text("Garde une trace de ce qui t’a plu.").foregroundStyle(HC.secondary)
          }.padding(.vertical, 12)
        }
        Section("Ton souvenir de cuisine") {
          Stepper("Note : \(Quantity.number(rating))/5", value: $rating, in: 0...5, step: 0.5)
          TextField("Ce que je referai, ce que je changerai…", text: $comment, axis: .vertical)
            .lineLimit(3...8)
        }
        if !store.state.pantry.isEmpty {
          Section {
            Toggle("Déduire les ingrédients du garde-manger", isOn: $deduct)
            if deduct {
              Text(
                "Les quantités calculables seront retirées des produits portant exactement le même nom, avec une unité compatible. Les basiques permanents ne seront pas touchés."
              ).font(.footnote)
              ForEach(session.recipe.ingredients) { i in
                Text(
                  "\(i.scaled(from: session.recipe.servings, to: session.servings).quantity) \(i.name)"
                )
              }
            }
          }
        }
        HCPrimaryButton(title: "Enregistrer ce moment", symbol: "checkmark") {
          let success = store.change("Recette ajoutée à l’historique", undo: true) { s in
            s.history.append(
              CookingHistoryEntry(
                recipeID: session.recipeID, recipeName: session.recipe.name,
                servings: session.servings, rating: rating, comment: comment))
            if let i = s.recipes.firstIndex(where: { $0.id == session.recipeID }) {
              s.recipes[i].lastCookedAt = Date()
              s.recipes[i].rating = rating
            }
            if deduct {
              PantryLogic.deduct(
                recipe: session.recipe, servings: session.servings, pantry: &s.pantry)
            }
            s.session = nil
          }
          if success {
            dismiss()
            completed()
          }
        }
      }.scrollContentBackground(.hidden).hcPage().navigationTitle("Recette terminée").toolbar {
        ToolbarItem(placement: .cancellationAction) { Button("Revenir") { dismiss() } }
      }
    }
  }
}
struct TimerEditorView: View {
  @EnvironmentObject private var store: HubStore
  @Environment(\.dismiss) private var dismiss
  @State private var name = "Mon minuteur"
  @State private var minutes = 5
  @State private var seconds = 0
  var body: some View {
    NavigationStack {
      Form {
        TextField("Nom", text: $name)
        Stepper("\(minutes) minutes", value: $minutes, in: 0...1440)
        Stepper("\(seconds) secondes", value: $seconds, in: 0...59)
        Button("Lancer") {
          store.startTimer(name: name, seconds: minutes * 60 + seconds)
          dismiss()
        }.disabled(minutes * 60 + seconds == 0 || name.isEmpty)
      }.hcPage().navigationTitle("Nouveau minuteur").toolbar {
        ToolbarItem(placement: .cancellationAction) { Button("Annuler") { dismiss() } }
      }
    }
  }
}
