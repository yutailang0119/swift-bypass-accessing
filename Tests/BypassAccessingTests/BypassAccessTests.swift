import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(BypassAccessingMacros)
import BypassAccessingMacros

let testMacros: [String: Macro.Type] = [
  "BypassAccess": BypassAccessMacro.self
]
#endif

final class BypassAccessTests: XCTestCase {
  func testBypassAccessMacro() throws {
    #if canImport(BypassAccessingMacros)
    assertMacroExpansion(
      """
      """,
      expandedSource: """
        """,
      macros: testMacros
    )
    #else
    throw XCTSkip("macros are only supported when running tests for the host platform")
    #endif
  }
}
