# swift-bypass-accessing

## Installation

### [Swift Package Manager](https://swift.org/package-manager/)

```swift
// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

let package = Package(
  name: "ExamplePackage",
  platforms: [
    .macOS(.v12), .iOS(.v15), .tvOS(.v15), .watchOS(.v8), .macCatalyst(.v15),
  ],
  targets: [
    .target(
      name: "Example",
      dependencies: [
        .product(name: "BypassAccessing", package: "swift-bypass-accessing")
      ]
    ),
    .testTarget(
      name: "ExampleTests",
      dependencies: [
        "Example"
      ]
    ),
  ]
)
```

## Usage

```swift
import BypassAccessing

struct Declaration {
  @BypassAccess
  private let property: String = "property"

  @BypassAccess
  private func function() -> String {
    #function
  }
}
```

### Tests

```swift
import Testing
import BypassAccessing
@testable import Example

struct Tests {
  @Test
  func test() {
    let declaration = Declaration()

    #if DEBUG
    #expect(declaration.___property == "property")

    #expect(declaration.___function() == "function()")
    #endif
  }
}
```

## Author

[Yutaro Muta](https://github.com/yutailang0119)
