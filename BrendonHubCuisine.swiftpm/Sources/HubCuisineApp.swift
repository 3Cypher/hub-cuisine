import SwiftData
import SwiftUI

@MainActor final class Bootstrap: ObservableObject {
  @Published var store: HubStore? = nil
  @Published var error: String? = nil
  func load() {
    do {
      store = try HubStore(repository: HubRepository())
      error = nil
    } catch { self.error = error.localizedDescription }
  }
  func recover(_ data: Data) {
    do {
      var state = try Backup.decode(data)
      state.seeded = true
      let repository = try HubRepository()
      try repository.save(state)
      store = try HubStore(repository: repository)
      error = nil
    } catch { self.error = error.localizedDescription }
  }
}
@main struct HubCuisineApp: App {
  @UIApplicationDelegateAdaptor(NotificationDelegate.self) private var appDelegate
  @StateObject private var bootstrap = Bootstrap()
  var body: some Scene {
    WindowGroup {
      Group {
        if let store = bootstrap.store {
          HubRootView().environmentObject(store)
        } else {
          StartupView(bootstrap: bootstrap)
        }
      }.task { if bootstrap.store == nil && bootstrap.error == nil { bootstrap.load() } }
        .environment(\.locale, Locale(identifier: "fr_BE"))
    }
  }
}
struct StartupView: View {
  @ObservedObject var bootstrap: Bootstrap
  @State private var importer = false
  @State private var recoveryData: Data?
  @State private var recoverySummary = ""
  @State private var confirmRecovery = false
  var body: some View {
    VStack(spacing: 24) {
      Image(systemName: "fork.knife.circle").font(.system(size: 82, weight: .ultraLight))
        .foregroundStyle(HC.accent)
      Text("Hub Cuisine").font(HC.title(.largeTitle))
      if let error = bootstrap.error {
        HCErrorState(
          message: "Impossible d’ouvrir vos données. Elles n’ont pas été effacées.\n\(error)",
          retry: bootstrap.load)
        Button("Restaurer une sauvegarde JSON") { importer = true }.frame(minHeight: 44)
      } else {
        ProgressView("Ouverture du carnet…")
      }
    }.padding(32).frame(maxWidth: .infinity, maxHeight: .infinity).hcPage()
      .fileImporter(isPresented: $importer, allowedContentTypes: [.json]) { result in
        do {
          let url = try result.get()
          let access = url.startAccessingSecurityScopedResource()
          defer { if access { url.stopAccessingSecurityScopedResource() } }
          let data = try Data(contentsOf: url)
          let state = try Backup.decode(data)
          recoveryData = data
          recoverySummary =
            "Cette sauvegarde contient \(state.recipes.count) recettes, \(state.meals.count) repas et \(state.shopping.count) articles. Elle remplacera les données locales."
          confirmRecovery = true
        } catch { bootstrap.error = error.localizedDescription }
      }
      .confirmationDialog(
        "Restaurer cette sauvegarde ?", isPresented: $confirmRecovery, titleVisibility: .visible
      ) {
        Button("Restaurer et remplacer", role: .destructive) {
          if let data = recoveryData { bootstrap.recover(data) }
          recoveryData = nil
        }
        Button("Annuler", role: .cancel) { recoveryData = nil }
      } message: {
        Text(recoverySummary)
      }
  }
}
enum HubTab: String, CaseIterable, Identifiable {
  case home = "Accueil"
  case recipes = "Recettes"
  case week = "Semaine"
  case shopping = "Courses"
  case more = "Plus"
  var id: String { rawValue }
  var symbol: String {
    switch self {
    case .home: return "house"
    case .recipes: return "book.closed"
    case .week: return "calendar"
    case .shopping: return "basket"
    case .more: return "square.grid.2x2"
    }
  }
}
struct HubRootView: View {
  @EnvironmentObject private var store: HubStore
  @Environment(\.horizontalSizeClass) private var sizeClass
  @Environment(\.scenePhase) private var phase
  @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
  @State private var tab: HubTab = .home
  @State private var sidebar: HubTab? = .home
  private var appearance: ColorScheme? {
    store.state.settings.appearance == "Clair"
      ? .light : store.state.settings.appearance == "Sombre" ? .dark : nil
  }
  var body: some View {
    Group {
      if sizeClass == .regular {
        NavigationSplitView {
          List(HubTab.allCases, selection: $sidebar) { t in
            Label(t.rawValue, systemImage: t.symbol).padding(.vertical, 10).tag(t)
          }
          .navigationTitle("Hub Cuisine").scrollContentBackground(.hidden).background(HC.background)
          .safeAreaInset(edge: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
              Text("LE CARNET DE").font(.caption).tracking(2)
              Text(store.state.settings.displayName).font(HC.title(.title))
              Text("Des idées à l’assiette.").font(.subheadline).foregroundStyle(HC.secondary)
            }.frame(maxWidth: .infinity, alignment: .leading).padding(24)
          }
        } detail: {
          NavigationStack { content(sidebar ?? .home) }
        }
      } else {
        TabView(selection: $tab) {
          ForEach(HubTab.allCases) { t in
            NavigationStack { content(t) }.tabItem { Label(t.rawValue, systemImage: t.symbol) }.tag(
              t
            ).badge(t == .shopping ? store.state.shopping.filter { !$0.isChecked }.count : 0)
          }
        }
      }
    }.hcPage().preferredColorScheme(appearance)
      .environment(
        \.hcReduceMotion, systemReduceMotion || store.state.settings.reduceMotion
      )
      .sheet(isPresented: Binding(get: { !store.state.settings.hasOnboarded }, set: { _ in })) {
        OnboardingView().interactiveDismissDisabled()
      }
      .alert(
        "Hub Cuisine",
        isPresented: Binding(
          get: { store.errorMessage != nil }, set: { if !$0 { store.errorMessage = nil } })
      ) {
        Button("Compris") { store.errorMessage = nil }
      } message: {
        Text(store.errorMessage ?? "")
      }
      .overlay(alignment: .bottom) {
        if let toast = store.toast {
          HStack {
            Text(toast).font(.subheadline)
            Spacer()
            if store.canUndo { Button("Annuler") { store.undo() }.fontWeight(.bold) }
            Button {
              store.toast = nil
            } label: {
              Image(systemName: "xmark").frame(width: 44, height: 44)
            }.accessibilityLabel("Fermer le message")
          }.padding(.leading, 16).foregroundStyle(HC.cream).background(
            HC.cacao, in: RoundedRectangle(cornerRadius: 16)
          ).padding(.horizontal).padding(.bottom, sizeClass == .regular ? 16 : 66)
        }
      }
      .task { await TimerService.synchronize { store.state.timers } }
      .onChange(of: phase) { _, value in
        if value == .active { Task { await TimerService.synchronize { store.state.timers } } }
      }
  }
  @ViewBuilder private func content(_ tab: HubTab) -> some View {
    switch tab {
    case .home: HomeView()
    case .recipes: RecipeLibraryView()
    case .week: WeekView()
    case .shopping: ShoppingView()
    case .more: MoreView()
    }
  }
}
struct OnboardingView: View {
  @EnvironmentObject private var store: HubStore
  @State private var name = "Brendon"
  @State private var portions = 2
  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 28) {
          Image(systemName: "fork.knife.circle").font(.system(size: 70, weight: .ultraLight))
            .foregroundStyle(HC.accent)
          Text("Les bonnes idées\nse cuisinent ici.").font(HC.title(.largeTitle))
          Text("Ton carnet de recettes, tes menus et tes courses. Tout reste sur ton appareil.")
            .foregroundStyle(HC.secondary)
          VStack(alignment: .leading, spacing: 18) {
            TextField("Prénom", text: $name).textContentType(.givenName).textFieldStyle(
              .roundedBorder)
            Stepper("\(portions) portions par défaut", value: $portions, in: 1...24)
          }.hcCard()
          HCPrimaryButton(title: "Ouvrir mon carnet", symbol: "book") {
            store.change {
              $0.settings.displayName =
                name.trimmingCharacters(in: .whitespaces).isEmpty ? "Brendon" : name
              $0.settings.defaultServings = portions
              $0.settings.hasOnboarded = true
            }
          }
          Text(
            "Aucun compte, aucun abonnement. Les autorisations te seront demandées au moment utile."
          ).font(.footnote).foregroundStyle(HC.secondary)
        }.padding(28).frame(maxWidth: 580)
      }.frame(maxWidth: .infinity).hcPage().navigationTitle("Bienvenue")
    }
  }
}
