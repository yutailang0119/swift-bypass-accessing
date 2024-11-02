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
    } else if let initializer = declaration.as(InitializerDeclSyntax.self) {
      return []
    } else if let function = declaration.as(FunctionDeclSyntax.self) {
      return []
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
