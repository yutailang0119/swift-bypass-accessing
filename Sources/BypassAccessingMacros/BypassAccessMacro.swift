import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct BypassAccessMacro: PeerMacro {
  public static func expansion(
    of node: SwiftSyntax.AttributeSyntax,
    providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
    in context: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws -> [SwiftSyntax.DeclSyntax] {
    [
      DeclSyntax(
        IfConfigDeclSyntax(
          clauses: try IfConfigClauseListSyntax {
            IfConfigClauseSyntax(
              poundKeyword: .poundIfToken(),
              condition: DeclReferenceExprSyntax(baseName: .identifier("DEBUG")),
              elements: .decls(
                try MemberBlockItemListSyntax {
                  MemberBlockItemSyntax(
                    decl: try decl(providingPeersOf: declaration)
                  )
                }
              )
            )
          },
          poundEndif: .poundEndifToken()
        )
      )
    ]
  }
}

private extension BypassAccessMacro {
  static func decl(
    providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol
  ) throws -> any SwiftSyntax.DeclSyntaxProtocol {
    if let variable = declaration.as(VariableDeclSyntax.self) {
      return try variable.decl()
    } else if let function = declaration.as(FunctionDeclSyntax.self) {
      return function.decl()
    } else if let initializer = declaration.as(InitializerDeclSyntax.self) {
      return initializer.decl()
    } else {
      throw MacroExpansionErrorMessage("'@BypassAccess' cannot be applied to this declaration")
    }
  }
}

private extension VariableDeclSyntax {
  func decl() throws -> VariableDeclSyntax {
    guard let identifier = identifier else {
      throw MacroExpansionErrorMessage("'@BypassAccess' require Identifier")
    }
    guard let type = type else {
      throw MacroExpansionErrorMessage("'@BypassAccess' require TypeAnnotation")
    }

    let accessors: AccessorBlockSyntax.Accessors
    switch bindingSpecifier.tokenKind {
    case .keyword(.let):
      accessors = .getter(
        CodeBlockItemListSyntax {
          CodeBlockItemSyntax(
            item: .expr(
              ExprSyntax(
                DeclReferenceExprSyntax(baseName: .identifier(identifier.text))
              )
            )
          )
        }
      )
    case .keyword(.var):
      let effectSpecifiers = accessorsMatching({ $0 == .keyword(.get) }).first?.effectSpecifiers
      let expression: any ExprSyntaxProtocol = {
        var expr: any ExprSyntaxProtocol = DeclReferenceExprSyntax(baseName: .identifier(identifier.text))
        if effectSpecifiers?.asyncSpecifier != nil {
          expr = AwaitExprSyntax(expression: expr)
        }
        if effectSpecifiers?.throwsClause != nil {
          expr = TryExprSyntax(expression: expr)
        }
        return expr
      }()

      var accessorDeclList = AccessorDeclListSyntax {
        AccessorDeclSyntax(
          accessorSpecifier: .keyword(.get),
          effectSpecifiers: effectSpecifiers,
          body: CodeBlockSyntax(
            statements: CodeBlockItemListSyntax {
              CodeBlockItemSyntax(
                item: .expr(
                  ExprSyntax(expression)
                )
              )
            }
          )
        )
      }

      if !(isComputed && accessorsMatching({ $0 == .keyword(.set) }).isEmpty) {
        accessorDeclList.append(
          AccessorDeclSyntax(
            accessorSpecifier: .keyword(.set),
            effectSpecifiers: accessorsMatching({ $0 == .keyword(.set) }).first?.effectSpecifiers,
            body: CodeBlockSyntax(
              statements: CodeBlockItemListSyntax {
                CodeBlockItemSyntax(
                  item: .expr(
                    ExprSyntax(
                      InfixOperatorExprSyntax(
                        leftOperand: DeclReferenceExprSyntax(baseName: .identifier(identifier.text)),
                        operator: AssignmentExprSyntax(equal: .equalToken()),
                        rightOperand: DeclReferenceExprSyntax(baseName: .identifier("newValue"))
                      )
                    )
                  )
                )
              }
            )
          )
        )
      }
      accessors = .accessors(accessorDeclList)
    default:
      throw MacroExpansionErrorMessage("'@BypassAccess' cannot be applied to this variable")
    }

    return VariableDeclSyntax(
      attributes: attributes.filter(.identifier("BypassAccess")),
      modifiers: modifiers.filter(.keyword(.private)),
      bindingSpecifier: .keyword(.var),
      bindings: PatternBindingListSyntax {
        PatternBindingSyntax(
          pattern: IdentifierPatternSyntax(identifier: .identifier("___\(identifier.text)")),
          typeAnnotation: TypeAnnotationSyntax(type: type),
          accessorBlock: AccessorBlockSyntax(
            accessors: accessors
          )
        )
      }
    )
    .trimmed
  }
}

private extension FunctionDeclSyntax {
  func decl() -> FunctionDeclSyntax {
    let expression: any ExprSyntaxProtocol = {
      var expr: any ExprSyntaxProtocol = FunctionCallExprSyntax(
        calledExpression: DeclReferenceExprSyntax(
          baseName: name
        ),
        leftParen: .leftParenToken(),
        arguments: LabeledExprListSyntax {
          signature.parameterClause.parameters.map {
            var expression: any ExprSyntaxProtocol = DeclReferenceExprSyntax(baseName: $0.secondName ?? $0.firstName)
            if $0.type.as(AttributedTypeSyntax.self)?.specifiers.isInout ?? false {
              expression = InOutExprSyntax(expression: expression)
            }
            return LabeledExprListSyntax.Element(
              label: $0.firstName.trimmed,
              colon: .colonToken(trailingTrivia: .space),
              expression: expression
            )
          }
        },
        rightParen: .rightParenToken()
      )
      if signature.effectSpecifiers?.asyncSpecifier != nil {
        expr = AwaitExprSyntax(expression: expr)
      }
      if signature.effectSpecifiers?.throwsClause != nil {
        expr = TryExprSyntax(expression: expr)
      }
      return expr
    }()

    return FunctionDeclSyntax(
      attributes: attributes.filter(.identifier("BypassAccess")),
      modifiers: modifiers.filter(.keyword(.private)),
      name: .identifier("___\(name.text)"),
      genericParameterClause: genericParameterClause,
      signature: signature,
      genericWhereClause: genericWhereClause,
      body: CodeBlockSyntax(
        statements: CodeBlockItemListSyntax {
          CodeBlockItemSyntax(
            item: .expr(
              ExprSyntax(expression)
            )
          )
        }
      )
    )
    .trimmed
  }
}

private extension InitializerDeclSyntax {
  func decl() -> FunctionDeclSyntax {
    let expression: any ExprSyntaxProtocol = {
      var expr: any ExprSyntaxProtocol = FunctionCallExprSyntax(
        calledExpression: MemberAccessExprSyntax(
          base: DeclReferenceExprSyntax(
            baseName: .keyword(.Self)
          ),
          declName: DeclReferenceExprSyntax(
            baseName: .keyword(.`init`)
          )
        ),
        leftParen: .leftParenToken(),
        arguments: LabeledExprListSyntax {
          signature.parameterClause.parameters.map {
            var expression: any ExprSyntaxProtocol = DeclReferenceExprSyntax(baseName: $0.secondName ?? $0.firstName)
            if $0.type.as(AttributedTypeSyntax.self)?.specifiers.isInout ?? false {
              expression = InOutExprSyntax(expression: expression)
            }
            return LabeledExprListSyntax.Element(
              label: $0.firstName.trimmed,
              colon: .colonToken(trailingTrivia: .space),
              expression: expression
            )
          }
        },
        rightParen: .rightParenToken()
      )
      if signature.effectSpecifiers?.asyncSpecifier != nil {
        expr = AwaitExprSyntax(expression: expr)
      }
      if signature.effectSpecifiers?.throwsClause != nil {
        expr = TryExprSyntax(expression: expr)
      }
      return expr
    }()

    let returnType: any TypeSyntaxProtocol = {
      let type = IdentifierTypeSyntax(name: .keyword(.Self))
      if optionalMark?.tokenKind == .postfixQuestionMark {
        return OptionalTypeSyntax(wrappedType: type)
      } else if optionalMark?.tokenKind == .exclamationMark {
        return ImplicitlyUnwrappedOptionalTypeSyntax(wrappedType: type)
      } else {
        return type
      }
    }()

    return FunctionDeclSyntax(
      attributes: attributes.filter(.identifier("BypassAccess")),
      modifiers: {
        var modifiers = modifiers.filter(.keyword(.private))
        modifiers.append(DeclModifierSyntax(name: .keyword(.static)))
        return modifiers
      }(),
      name: .identifier("___init"),
      genericParameterClause: genericParameterClause,
      signature: FunctionSignatureSyntax(
        parameterClause: signature.parameterClause,
        effectSpecifiers: signature.effectSpecifiers,
        returnClause: ReturnClauseSyntax(type: returnType)
      ),
      genericWhereClause: genericWhereClause,
      body: CodeBlockSyntax(
        statements: CodeBlockItemListSyntax {
          CodeBlockItemSyntax(
            item: .expr(
              ExprSyntax(expression)
            )
          )
        }
      )
    )
    .trimmed
  }
}
