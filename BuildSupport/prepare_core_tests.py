#!/usr/bin/env python3
"""Copy the existing business tests into an ordinary Foundation-only Swift package."""
from pathlib import Path
import shutil

root = Path(__file__).resolve().parent.parent
app = root / 'BrendonHubCuisine.swiftpm'
core = root / 'build/CorePackage'
core.mkdir(parents=True, exist_ok=True)
shutil.copytree(app / 'Sources/Core', core / 'Sources/Core', dirs_exist_ok=True)
shutil.copytree(app / 'Tests', core / 'Tests', dirs_exist_ok=True)
(core / 'Resources').mkdir(exist_ok=True)
shutil.copyfile(app / 'Resources/LegacyRecipes.json', core / 'Resources/LegacyRecipes.json')
(core / 'Package.swift').write_text('''// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "HubCuisineCore", platforms: [.macOS(.v10_15)], targets: [
  .target(name: "HubCuisineCore", path: "Sources/Core"),
  .testTarget(name: "HubCuisineCoreTests", dependencies: ["HubCuisineCore"], path: "Tests")
])
''')
print('Core package prepared with the original tests and seven demo recipes.')
