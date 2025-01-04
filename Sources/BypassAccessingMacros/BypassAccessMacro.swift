import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct BypassAccessMacro: PeerMacro {
  public static func expansion(
    of node: SwiftSyntax.AttributeSyntax,
    providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
    in context: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws -> [SwiftSyntax.DeclSyntax] {
    if let variable = declaration.as(VariableDeclSyntax.self) {
      guard let identifier = variable.identifier else {
        throw MacroExpansionErrorMessage("'@BypassAccess' require Identifier")
      }
      guard let type = variable.type else {
        throw MacroExpansionErrorMessage("'@BypassAccess' require TypeAnnotation")
      }

      let attributes = variable.attributes.filter {
        switch $0 {
        case .attribute(let attribute):
          if let identifier = attribute.attributeName.as(IdentifierTypeSyntax.self) {
            return identifier.name.tokenKind != .identifier("BypassAccess")
          } else {
            return true
          }
        case .ifConfigDecl:
          return true
        }
      }

      let accessors: AccessorBlockSyntax.Accessors
      switch variable.bindingSpecifier.tokenKind {
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
      case .keyword(.var) where variable.isComputed && variable.accessorsMatching({ $0 == .keyword(.set) }).isEmpty:
        let effectSpecifiers = variable.accessorsMatching({ $0 == .keyword(.get) }).first?.effectSpecifiers

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

        accessors = .accessors(
          AccessorDeclListSyntax {
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
        )
      case .keyword(.var):
        let effectSpecifiers = variable.accessorsMatching({ $0 == .keyword(.get) }).first?.effectSpecifiers

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

        accessors = .accessors(
          AccessorDeclListSyntax {
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
            AccessorDeclSyntax(
              accessorSpecifier: .keyword(.set),
              effectSpecifiers: effectSpecifiers,
              body: CodeBlockSyntax(
                statements: CodeBlockItemListSyntax {
                  CodeBlockItemSyntax(
                    item: .expr(
                      ExprSyntax(
                        InfixOperatorExprSyntax(
                          leftOperand: DeclReferenceExprSyntax(baseName: .identifier(identifier.text)),
                          operator: AssignmentExprSyntax(equal: .equalToken()),
                          rightOperand: DeclReferenceExprSyntax(baseName: .identifier("newValue")))
                      )
                    )
                  )
                }
              )
            )
          }
        )
      default:
        throw MacroExpansionErrorMessage("'@BypassAccess' cannot be applied to this variable")
      }

      return [
        DeclSyntax(
          IfConfigDeclSyntax(
            clauses: IfConfigClauseListSyntax {
              IfConfigClauseSyntax(
                poundKeyword: .poundIfToken(),
                condition: DeclReferenceExprSyntax(baseName: .identifier("DEBUG")),
                elements: .decls(
                  MemberBlockItemListSyntax {
                    MemberBlockItemSyntax(
                      decl: VariableDeclSyntax(
                        attributes: attributes,
                        modifiers: variable.modifiers.filter {
                          $0.name.tokenKind != .keyword(.private)
                        },
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
                    )
                  }
                )
              )
            },
            poundEndif: .poundEndifToken()
          )
        )
      ]
    } else if let function = declaration.as(FunctionDeclSyntax.self) {
      let attributes = function.attributes.filter {
        switch $0 {
        case .attribute(let attribute):
          if let identifier = attribute.attributeName.as(IdentifierTypeSyntax.self) {
            return identifier.name.tokenKind != .identifier("BypassAccess")
          } else {
            return true
          }
        case .ifConfigDecl:
          return true
        }
      }

      let expression: any ExprSyntaxProtocol = {
        var expr: any ExprSyntaxProtocol = FunctionCallExprSyntax(
          calledExpression: DeclReferenceExprSyntax(
            baseName: function.name
          ),
          leftParen: .leftParenToken(),
          arguments: LabeledExprListSyntax {
            function.signature.parameterClause.parameters.map {
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

        if function.signature.effectSpecifiers?.isAsync ?? false {
          expr = AwaitExprSyntax(expression: expr)
        }

        if function.signature.effectSpecifiers?.isThrows ?? false {
          expr = TryExprSyntax(expression: expr)
        }

        return expr
      }()

      return [
        DeclSyntax(
          IfConfigDeclSyntax(
            clauses: IfConfigClauseListSyntax {
              IfConfigClauseSyntax(
                poundKeyword: .poundIfToken(),
                condition: DeclReferenceExprSyntax(baseName: .identifier("DEBUG")),
                elements: .decls(
                  MemberBlockItemListSyntax {
                    MemberBlockItemSyntax(
                      decl: FunctionDeclSyntax(
                        attributes: attributes,
                        modifiers: function.modifiers.filter {
                          $0.name.tokenKind != .keyword(.private)
                        },
                        name: .identifier("___\(function.name.text)"),
                        genericParameterClause: function.genericParameterClause,
                        signature: function.signature,
                        genericWhereClause: function.genericWhereClause,
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
                    )
                  }
                )
              )
            },
            poundEndif: .poundEndifToken()
          )
        )
      ]
    } else if let initializer = declaration.as(InitializerDeclSyntax.self) {
      let attributes = initializer.attributes.filter {
        switch $0 {
        case .attribute(let attribute):
          if let identifier = attribute.attributeName.as(IdentifierTypeSyntax.self) {
            return identifier.name.tokenKind != .identifier("BypassAccess")
          } else {
            return true
          }
        case .ifConfigDecl:
          return true
        }
      }

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
            initializer.signature.parameterClause.parameters.map {
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

        if initializer.signature.effectSpecifiers?.isAsync ?? false {
          expr = AwaitExprSyntax(expression: expr)
        }

        if initializer.signature.effectSpecifiers?.isThrows ?? false {
          expr = TryExprSyntax(expression: expr)
        }

        return expr
      }()

      let returnType: any TypeSyntaxProtocol = {
        let type = IdentifierTypeSyntax(name: .keyword(.Self))
        if initializer.optionalMark?.tokenKind == .postfixQuestionMark {
          return OptionalTypeSyntax(wrappedType: type)
        } else if initializer.optionalMark?.tokenKind == .exclamationMark {
          return ImplicitlyUnwrappedOptionalTypeSyntax(wrappedType: type)
        } else {
          return type
        }
      }()

      return [
        DeclSyntax(
          IfConfigDeclSyntax(
            clauses: IfConfigClauseListSyntax {
              IfConfigClauseSyntax(
                poundKeyword: .poundIfToken(),
                condition: DeclReferenceExprSyntax(baseName: .identifier("DEBUG")),
                elements: .decls(
                  MemberBlockItemListSyntax {
                    MemberBlockItemSyntax(
                      decl: FunctionDeclSyntax(
                        attributes: attributes,
                        modifiers: {
                          var ms = initializer.modifiers.filter {
                            $0.name.tokenKind != .keyword(.private)
                          }
                          ms.append(DeclModifierSyntax(name: .keyword(.static)))
                          return ms
                        }(),
                        name: .identifier("___init"),
                        genericParameterClause: initializer.genericParameterClause,
                        signature: FunctionSignatureSyntax(
                          parameterClause: initializer.signature.parameterClause,
                          effectSpecifiers: initializer.signature.effectSpecifiers,
                          returnClause: ReturnClauseSyntax(type: returnType)
                        ),
                        genericWhereClause: initializer.genericWhereClause,
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
                    )
                  }
                )
              )
            },
            poundEndif: .poundEndifToken()
          )
        )
      ]
    } else {
      throw MacroExpansionErrorMessage("'@BypassAccess' cannot be applied to this declaration")
    }
  }
}
