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

      let staticModifier: TokenSyntax? = variable.modifiers.isInstance ? nil : .keyword(.static)
      let mainActorAttribute: AttributeSyntax? = variable.attributes.isMainActor ? .mainActor : nil

      let variableDecl: VariableDeclSyntax
      switch variable.bindingSpecifier.tokenKind {
      case .keyword(.let):
        variableDecl = try VariableDeclSyntax(
          """
          \(mainActorAttribute) \(staticModifier)
          var ___\(raw: identifier.text): \(type.trimmed) {
            \(raw: identifier.text)
          }
          """
        )
      case .keyword(.var) where variable.isComputed && variable.accessorsMatching({ $0 == .keyword(.set) }).isEmpty:
        let accessorEffectSpecifiers = variable.accessorsMatching({ $0 == .keyword(.get) }).first?.effectSpecifiers
        let asyncSpecifier = accessorEffectSpecifiers?.asyncSpecifier
        let throwsSpecifier = accessorEffectSpecifiers?.throwsClause?.throwsSpecifier
        let tryOperator: TokenSyntax? = throwsSpecifier != nil ? .keyword(.try) : nil
        let awaitOperator: TokenSyntax? = asyncSpecifier != nil ? .keyword(.await) : nil

        variableDecl = try VariableDeclSyntax(
          """
          \(mainActorAttribute) \(staticModifier)
          var ___\(raw: identifier.text): \(type.trimmed) {
            get \(asyncSpecifier?.trimmed) \(throwsSpecifier?.trimmed) {
              \(tryOperator) \(awaitOperator) \(raw: identifier.text)
            }
          }
          """
        )
      case .keyword(.var):
        variableDecl = try VariableDeclSyntax(
          """
          \(mainActorAttribute) \(staticModifier)
          var ___\(raw: identifier.text): \(type.trimmed) {
            get {
              \(raw: identifier.text)
            }
            set {
              \(raw: identifier.text) = newValue
            }
          }
          """
        )
      default:
        throw MacroExpansionErrorMessage("'@BypassAccess' cannot be applied to this variable")
      }

      return [
        """
        #if DEBUG
        \(variableDecl.trimmed.formatted())
        #endif
        """
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

      let modifiers = function.modifiers.filter {
        $0.name.tokenKind != .keyword(.private)
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
                        modifiers: modifiers,
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
      let mainActorAttribute: AttributeSyntax? = initializer.attributes.isMainActor ? .mainActor : nil
      let tryOperator: TokenSyntax? = initializer.signature.effectSpecifiers.flatMap {
        $0.isThrows ? .keyword(.try) : nil
      }
      let awaitOperator: TokenSyntax? = initializer.signature.effectSpecifiers
        .flatMap { $0.isAsync ? .keyword(.await) : nil }

      let functionDecl = try FunctionDeclSyntax(
        """
        \(mainActorAttribute) static
        func ___init\(initializer.genericParameterClause)\(initializer.signature.trimmed) -> Self\(initializer.optionalMark) \(initializer.genericWhereClause){
          \(tryOperator) \(awaitOperator) Self.init(
            \(
                raw: initializer.signature.parameterClause.parameters
                    .map {
                      let inoutAmpersand: TokenSyntax? = $0.type.as(AttributedTypeSyntax.self).flatMap { $0.specifiers.isInout ? TokenSyntax(.prefixAmpersand, presence: .present) : nil }
                      return "\($0.firstName.trimmed): \(inoutAmpersand?.text ?? "")\($0.secondName?.trimmed ?? $0.firstName.trimmed)"
                    }
                    .joined(separator: ",\n")
            )
          )
        }
        """
      )
      return [
        """
        #if DEBUG
        \(functionDecl.trimmed.formatted())
        #endif
        """
      ]
    } else {
      throw MacroExpansionErrorMessage("'@BypassAccess' cannot be applied to this declaration")
    }
  }
}
