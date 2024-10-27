import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct BypassAccessingPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    BypassAccessMacro.self
  ]
}
