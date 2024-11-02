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

extension VariableDeclSyntax {
  private var identifierPattern: IdentifierPatternSyntax? {
    bindings.first?.pattern.as(IdentifierPatternSyntax.self)
  }

  var identifier: TokenSyntax? {
    bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier
  }

  var type: TypeSyntax? {
    bindings.first?.typeAnnotation?.type
  }

  func accessorsMatching(_ predicate: (TokenKind) -> Bool) -> [AccessorDeclSyntax] {
    let accessors: [AccessorDeclListSyntax.Element] = bindings.compactMap { patternBinding in
      switch patternBinding.accessorBlock?.accessors {
      case .accessors(let accessors):
        return accessors
      default:
        return nil
      }
    }.flatMap { $0 }
    return accessors.compactMap { accessor in
      if predicate(accessor.accessorSpecifier.tokenKind) {
        return accessor
      } else {
        return nil
      }
    }
  }

  var isComputed: Bool {
    if accessorsMatching({ $0 == .keyword(.get) }).count > 0 {
      return true
    } else {
      return bindings.contains { binding in
        if case .getter = binding.accessorBlock?.accessors {
          return true
        } else {
          return false
        }
      }
    }
  }
}

extension FunctionEffectSpecifiersSyntax {
  var isAsync: Bool {
    asyncSpecifier != nil
  }

  var isThrows: Bool {
    throwsClause != nil
  }
}
