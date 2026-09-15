import SwiftUI
import UIKit

private struct HCReduceMotionKey: EnvironmentKey {
  static let defaultValue = false
}
extension EnvironmentValues {
  var hcReduceMotion: Bool {
    get { self[HCReduceMotionKey.self] }
    set { self[HCReduceMotionKey.self] = newValue }
  }
}

enum HC {
  static func color(_ light: UInt32, _ dark: UInt32) -> Color {
    func ui(_ n: UInt32) -> UIColor {
      UIColor(
        red: CGFloat((n >> 16) & 255) / 255, green: CGFloat((n >> 8) & 255) / 255,
        blue: CGFloat(n & 255) / 255, alpha: 1)
    }
    return Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? ui(dark) : ui(light) })
  }
  static let background = color(0xF8F4EE, 0x160F0A)
  static let surface = color(0xFFFFFF, 0x24180F)
  static let secondarySurface = color(0xF1E8DC, 0x302116)
  static let ink = color(0x1C120A, 0xF7F0E7)
  static let secondary = color(0x75675C, 0xC9B8A7)
  static let accent = color(0x875020, 0xD69A62)
  static let gold = Color(red: 0.84, green: 0.68, blue: 0.29)
  static let line = color(0xE6D9CB, 0x4A3527)
  static let success = color(0x46684D, 0xA6C5A6)
  static let danger = color(0xA34F3F, 0xEEAE9E)
  static let cacao = Color(red: 0.086, green: 0.059, blue: 0.039)
  static let cream = Color(red: 0.97, green: 0.94, blue: 0.91)
  static let spacing: [CGFloat] = [4, 8, 12, 16, 24, 32, 40]
  static let cardRadius: CGFloat = 22
  static func title(_ style: Font.TextStyle = .title) -> Font {
    .system(style, design: .serif, weight: .semibold)
  }
}
enum Haptics {
  @MainActor static func light() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
}
struct HCSurface: ViewModifier {
  var padding: CGFloat = 20
  func body(content: Content) -> some View {
    content.padding(padding).background(
      HC.surface, in: RoundedRectangle(cornerRadius: HC.cardRadius)
    )
    .overlay(RoundedRectangle(cornerRadius: HC.cardRadius).stroke(HC.line, lineWidth: 0.7))
    .shadow(color: HC.cacao.opacity(0.035), radius: 12, x: 0, y: 5)
  }
}
extension View {
  func hcCard(_ padding: CGFloat = 20) -> some View { modifier(HCSurface(padding: padding)) }
  func hcPage() -> some View { background(HC.background).foregroundStyle(HC.ink).tint(HC.accent) }
}
struct HCPrimaryButton: View {
  var title: String
  var symbol: String = "arrow.right"
  var action: () -> Void
  var body: some View {
    Button(action: action) {
      Label(title, systemImage: symbol).font(.body.weight(.semibold)).frame(
        maxWidth: .infinity, minHeight: 28
      ).padding(12)
    }.buttonStyle(HCButtonStyle(primary: true))
  }
}
struct HCSecondaryButton: View {
  var title: String
  var symbol: String
  var action: () -> Void
  var body: some View {
    Button(action: action) {
      Label(title, systemImage: symbol).font(.body.weight(.medium)).frame(minHeight: 28).padding(10)
    }.buttonStyle(HCButtonStyle(primary: false))
  }
}
struct HCButtonStyle: ButtonStyle {
  var primary: Bool
  @Environment(\.hcReduceMotion) private var reduceMotion
  @Environment(\.isEnabled) private var enabled
  func makeBody(configuration: Configuration) -> some View {
    configuration.label.foregroundStyle(primary ? HC.cream : HC.accent)
      .background(primary ? HC.cacao : HC.secondarySurface, in: RoundedRectangle(cornerRadius: 16))
      .opacity(enabled ? (configuration.isPressed ? 0.8 : 1) : 0.45)
      .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
      .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: configuration.isPressed)
  }
}
struct HCIconButton: View {
  var symbol: String
  var label: String
  var action: () -> Void
  var body: some View {
    Button(action: action) { Image(systemName: symbol).frame(width: 44, height: 44) }.buttonStyle(
      .plain
    ).background(HC.surface.opacity(0.95), in: Circle()).accessibilityLabel(label)
  }
}
struct HCSectionHeader: View {
  var title: String
  var subtitle: String? = nil
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title).font(HC.title(.title2))
      if let subtitle { Text(subtitle).font(.subheadline).foregroundStyle(HC.secondary) }
    }.frame(maxWidth: .infinity, alignment: .leading).accessibilityAddTraits(.isHeader)
  }
}
struct HCFilterChip: View {
  var title: String
  var active: Bool
  var action: () -> Void
  var body: some View {
    Button(action: action) {
      HStack(spacing: 6) {
        if active { Image(systemName: "checkmark") }
        Text(title)
      }.font(.subheadline.weight(.medium)).padding(.horizontal, 16).frame(minHeight: 44).background(
        active ? HC.ink : HC.surface, in: Capsule()
      ).foregroundStyle(active ? HC.background : HC.secondary).overlay(
        Capsule().stroke(HC.line, lineWidth: active ? 0 : 1))
    }.buttonStyle(.plain).accessibilityAddTraits(active ? .isSelected : [])
  }
}
struct HCCategoryCard: View {
  var category: RecipeCategory
  var count: Int
  var active: Bool
  var action: () -> Void
  var body: some View {
    Button(action: action) {
      VStack(alignment: .leading, spacing: 8) {
        Text(category.emoji).font(.title)
        Text(category.rawValue).font(.headline)
        Text("\(count) recettes").font(.caption).foregroundStyle(HC.secondary)
      }.frame(minWidth: 105, alignment: .leading).hcCard(16).overlay(
        RoundedRectangle(cornerRadius: HC.cardRadius).stroke(
          active ? HC.accent : .clear, lineWidth: 2))
    }.buttonStyle(.plain).accessibilityAddTraits(active ? .isSelected : [])
  }
}
struct HCPhotoHero: View {
  var recipe: Recipe
  var height: CGFloat = 240
  private var local: UIImage? { recipe.photoData.flatMap(UIImage.init(data:)) }
  var body: some View {
    GeometryReader { geometry in
      ZStack {
        HC.secondarySurface
        if let local {
          Image(uiImage: local).resizable().scaledToFill()
        } else if !recipe.photoAsset.isEmpty {
          Image(recipe.photoAsset, bundle: .module).resizable().scaledToFill()
        } else {
          VStack(spacing: 12) {
            Image(systemName: "fork.knife.circle").font(.system(size: 60, weight: .ultraLight))
            Text("Le goût des bonnes choses").font(HC.title(.headline))
          }.foregroundStyle(HC.accent)
        }
      }.frame(width: geometry.size.width, height: height).clipped()
    }.frame(height: height).accessibilityHidden(true)
  }
}
struct HCRecipeCard: View {
  @EnvironmentObject private var store: HubStore
  var recipe: Recipe
  var horizontal = false
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      ZStack(alignment: .topTrailing) {
        HCPhotoHero(recipe: recipe, height: horizontal ? 145 : 185)
        HCIconButton(
          symbol: recipe.isFavorite ? "heart.fill" : "heart",
          label: recipe.isFavorite ? "Retirer des favoris" : "Ajouter aux favoris"
        ) { store.favorite(recipe.id) }.foregroundStyle(HC.accent).padding(10)
      }
      VStack(alignment: .leading, spacing: 9) {
        Text(recipe.category.rawValue.uppercased()).font(.caption.weight(.semibold)).tracking(1.5)
          .foregroundStyle(HC.accent)
        Text(recipe.name).font(HC.title(.title3)).fixedSize(horizontal: false, vertical: true)
        ViewThatFits(in: .horizontal) {
          HStack {
            Label("\(recipe.timeMinutes) min", systemImage: "clock")
            Spacer()
            Label("\(recipe.servings)", systemImage: "person.2")
            if recipe.rating > 0 { Label(Quantity.number(recipe.rating), systemImage: "star.fill") }
          }
          VStack(alignment: .leading) {
            Label("\(recipe.timeMinutes) min · \(recipe.servings) portions", systemImage: "clock")
            Text(recipe.difficulty.rawValue)
          }
        }.font(.caption).foregroundStyle(HC.secondary)
        Text(([recipe.difficulty.rawValue] + Array(recipe.tags.prefix(2))).joined(separator: " · "))
          .font(.caption).foregroundStyle(HC.secondary).fixedSize(horizontal: false, vertical: true)
      }.padding(16)
    }.background(HC.surface).clipShape(RoundedRectangle(cornerRadius: 22)).overlay(
      RoundedRectangle(cornerRadius: 22).stroke(HC.line, lineWidth: 0.7))
  }
}
struct HCEmptyState: View {
  var title: String
  var message: String
  var symbol = "tray"
  var body: some View {
    VStack(spacing: 14) {
      Image(systemName: symbol).font(.system(size: 40, weight: .light)).foregroundStyle(HC.accent)
      Text(title).font(HC.title(.title2))
      Text(message).foregroundStyle(HC.secondary).multilineTextAlignment(.center)
    }.frame(maxWidth: .infinity).padding(32)
  }
}
struct HCErrorState: View {
  var message: String
  var retry: (() -> Void)? = nil
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Label("À vérifier", systemImage: "exclamationmark.circle").font(.headline)
      Text(message).fixedSize(horizontal: false, vertical: true)
      if let retry { Button("Réessayer", action: retry).frame(minHeight: 44) }
    }.foregroundStyle(HC.danger).hcCard()
  }
}
struct HCSkeleton: View {
  var body: some View {
    HStack(spacing: 12) {
      ProgressView()
      Text("Préparation en cours…").foregroundStyle(HC.secondary)
    }.frame(maxWidth: .infinity, minHeight: 72).hcCard()
  }
}
struct HCIngredientRow: View {
  var ingredient: Ingredient
  var checked: Bool
  var action: () -> Void
  var body: some View {
    Button(action: action) {
      HStack(alignment: .top, spacing: 12) {
        Image(systemName: checked ? "checkmark.circle.fill" : "circle").font(.title2)
          .foregroundStyle(checked ? HC.success : HC.accent)
        VStack(alignment: .leading, spacing: 5) {
          Text(ingredient.name).strikethrough(checked)
          Text(ingredient.quantity).font(.subheadline).foregroundStyle(HC.secondary)
        }
        Spacer()
      }.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading).padding(12).background(
        HC.secondarySurface, in: RoundedRectangle(cornerRadius: 14))
    }.buttonStyle(.plain).accessibilityLabel(
      "\(ingredient.name), \(ingredient.quantity), \(checked ? "coché" : "à préparer")")
  }
}
struct HCShoppingRow: View {
  var item: ShoppingItem
  var check: () -> Void
  var edit: () -> Void
  var body: some View {
    HStack(spacing: 8) {
      Button(action: check) {
        Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
          .font(.title2).foregroundStyle(item.isChecked ? HC.success : HC.accent)
          .frame(width: 44, height: 44)
      }.buttonStyle(.plain).accessibilityLabel(item.isChecked ? "À racheter" : "Marquer acheté")
      Button(action: edit) {
        VStack(alignment: .leading, spacing: 4) {
          Text(item.ingredient.name).font(.body.weight(.medium)).strikethrough(item.isChecked)
          Text(item.ingredient.quantity).foregroundStyle(HC.secondary).font(.subheadline)
          if !item.sourceNames.isEmpty {
            Text(item.sourceNames.joined(separator: ", ")).font(.caption).foregroundStyle(
              HC.secondary)
          }
        }.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
      }.buttonStyle(.plain)
    }.padding(.vertical, 6)
  }
}
struct HCMealSlot: View {
  var slot: MealSlot
  var entry: MealPlanEntry?
  var recipe: Recipe?
  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Text(slot.rawValue.uppercased()).font(.caption.weight(.semibold)).tracking(1)
        Spacer()
        Image(systemName: entry == nil ? "plus" : "ellipsis")
      }.foregroundStyle(HC.secondary)
      if let recipe {
        HCPhotoHero(recipe: recipe, height: 95).clipShape(RoundedRectangle(cornerRadius: 12))
        Text(recipe.name).font(HC.title(.headline))
      } else {
        Label(
          entry?.kind.rawValue ?? "Choisir un repas",
          systemImage: entry?.kind == .outside
            ? "fork.knife" : entry?.kind == .leftovers ? "refrigerator" : "plus.circle"
        ).font(.body)
      }
      if let entry {
        Text("\(entry.servings) portions" + (entry.note.isEmpty ? "" : " · \(entry.note)")).font(
          .caption
        ).foregroundStyle(HC.secondary)
      }
    }.frame(maxWidth: .infinity, minHeight: 70, alignment: .leading).padding(14).background(
      HC.secondarySurface, in: RoundedRectangle(cornerRadius: 16))
  }
}
struct HCStatCard: View {
  var value: String
  var title: String
  var symbol: String
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Image(systemName: symbol).foregroundStyle(HC.accent)
      Text(value).font(HC.title(.largeTitle))
      Text(title).font(.subheadline).foregroundStyle(HC.secondary)
    }.frame(maxWidth: .infinity, alignment: .leading).hcCard()
  }
}
struct HCTimerCard: View {
  var timer: CookingTimer
  var stop: () -> Void
  var body: some View {
    TimelineView(.periodic(from: .now, by: 1)) { context in
      let left = timer.remaining(at: context.date)
      HStack {
        VStack(alignment: .leading, spacing: 8) {
          Text(timer.name).font(.headline)
          Text(left == 0 ? "C’est prêt !" : String(format: "%02d:%02d", left / 60, left % 60)).font(
            .system(.largeTitle, design: .rounded, weight: .semibold)
          ).monospacedDigit()
          ProgressView(
            value: Double(max(0, timer.duration - left)), total: Double(max(1, timer.duration))
          ).tint(HC.gold)
        }
        Spacer()
        Button(action: stop) {
          Image(systemName: left == 0 ? "checkmark.circle.fill" : "xmark.circle").font(.title2)
            .frame(width: 44, height: 44)
        }.accessibilityLabel(left == 0 ? "Terminer le minuteur" : "Arrêter le minuteur")
      }.padding(20).foregroundStyle(HC.cream).background(
        HC.cacao, in: RoundedRectangle(cornerRadius: 22))
    }
  }
}
