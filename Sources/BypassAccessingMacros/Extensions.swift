import SwiftSyntax

extension AttributeListSyntax {
  var isMainActor: Bool {
    for attribute in self {
      for token in attribute.tokens(viewMode: .all) {
        if token.tokenKind == .identifier("MainActor") {
          return true
        }
      }
    }
    return false
  }
}

extension DeclModifierListSyntax {
  var isInstance: Bool {
    for modifier in self {
      for token in modifier.tokens(viewMode: .all) {
        if token.tokenKind == .keyword(.static) || token.tokenKind == .keyword(.class) {
          return false
        }
      }
    }
    return true
  }
}
