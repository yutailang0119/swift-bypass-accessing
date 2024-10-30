import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros

#if canImport(BypassAccessingMacros)
import BypassAccessingMacros

let testMacros: [String: Macro.Type] = [
  "BypassAccess": BypassAccessMacro.self
]
#endif
