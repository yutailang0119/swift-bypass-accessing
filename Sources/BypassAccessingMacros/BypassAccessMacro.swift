import SwiftSyntax
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
      let staticModifier: TokenSyntax? = function.modifiers.isInstance ? nil : .keyword(.static)
      let mainActorAttribute: AttributeSyntax? = function.attributes.isMainActor ? .mainActor : nil
      let tryOperator: TokenSyntax? = function.signature.effectSpecifiers.flatMap { $0.isThrows ? .keyword(.try) : nil }
      let awaitOperator: TokenSyntax? = function.signature.effectSpecifiers.flatMap {
        $0.isAsync ? .keyword(.await) : nil
      }

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
