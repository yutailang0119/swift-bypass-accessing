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

  func filter(_ tokenKind: TokenKind) -> AttributeListSyntax {
    self.filter {
      switch $0 {
      case .attribute(let attribute):
        if let identifier = attribute.attributeName.as(IdentifierTypeSyntax.self) {
          return identifier.name.tokenKind != tokenKind
        } else {
          return true
        }
      case .ifConfigDecl:
        return true
      }
    }
  }
}

extension AttributeSyntax {
  static var mainActor: Self {
    self.init(attributeName: TypeSyntax(stringLiteral: "MainActor"))
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

  func filter(_ tokenKind: TokenKind) -> DeclModifierListSyntax {
    self.filter {
      $0.name.tokenKind != tokenKind
    }
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

extension TypeSpecifierListSyntax {
  var isInout: Bool {
    for specifier in self {
      for token in specifier.tokens(viewMode: .all) {
        if token.tokenKind == .keyword(.inout) {
          return true
        }
      }
    }
    return false
  }
}
