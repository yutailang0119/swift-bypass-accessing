import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

public struct BypassAccessMacro: PeerMacro {
  public static func expansion(
    of node: SwiftSyntax.AttributeSyntax,
    providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
    in context: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws -> [SwiftSyntax.DeclSyntax] {
    if let variable = declaration.as(VariableDeclSyntax.self) {
      return []
    } else if let function = declaration.as(FunctionDeclSyntax.self) {
      let staticModifier: TokenSyntax? = function.modifiers.isInstance ? nil : .keyword(.static)
      let mainActorAttribute: AttributeSyntax? =
        function.attributes.isMainActor ? AttributeSyntax(attributeName: TypeSyntax(stringLiteral: "MainActor")) : nil
      let tryOperator: TokenSyntax? = function.signature.effectSpecifiers.flatMap { $0.isThrows ? .keyword(.try) : nil }
      let awaitOperator : TokenSyntax? = function.signature.effectSpecifiers.flatMap { $0.isAsync ? .keyword(.await) : nil }

      let functionDecl = try FunctionDeclSyntax(
        """
        \(mainActorAttribute) \(staticModifier)
        func ___\(function.name)\(function.genericParameterClause)\(function.signature.trimmed) \(function.genericWhereClause){
          \(tryOperator) \(awaitOperator) \(function.name)(
            \(
                raw: function.signature.parameterClause.parameters
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
    } else if let initializer = declaration.as(InitializerDeclSyntax.self) {
      let mainActorAttribute: AttributeSyntax? =
        initializer.attributes.isMainActor
        ? AttributeSyntax(attributeName: TypeSyntax(stringLiteral: "MainActor")) : nil
      let tryOperator: TokenSyntax? = initializer.signature.effectSpecifiers.flatMap { $0.isThrows ? .keyword(.try) : nil }
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
      let error = MacroExpansionErrorMessage("'@BypassAccess' cannot be applied to this declaration")
      context.diagnose(
        Diagnostic(
          node: node,
          message: error
        )
      )
      throw error
    }
  }
}
