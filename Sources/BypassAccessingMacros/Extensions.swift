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
