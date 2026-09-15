import XCTest

@testable import HubCuisineCore

final class HubCuisineCoreTests: XCTestCase {
  func testBundledRecipes() throws {
    let project = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
      .deletingLastPathComponent()
    let recipes = try DemoData.decode(
      Data(contentsOf: project.appendingPathComponent("Resources/LegacyRecipes.json")))
    XCTAssertEqual(recipes.count, 7)
    XCTAssertEqual(Set(recipes.map(\.photoAsset)).count, 7)
    XCTAssertFalse(recipes.contains { $0.ingredients.isEmpty || $0.steps.isEmpty })
    var state = HubState()
    state.seedOnce(recipes)
    let restored = try Backup.decode(Backup.encode(state))
    XCTAssertEqual(restored.recipes.count, 7)
    XCTAssertTrue(restored.seeded)
  }

  func testCriticalScenarios() {
    for result in CoreChecks.run() {
      print("\(result.passed ? "PASS" : "FAIL") — \(result.name)")
      XCTAssertTrue(result.passed, "\(result.name): \(result.detail)")
    }
  }
}
