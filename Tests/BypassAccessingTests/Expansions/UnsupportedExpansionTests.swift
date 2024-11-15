import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosTestSupport
import XCTest

final class UnsupportedExpansionTests: XCTestCase {
  func testUnsupportedDeclaration() throws {
    #if canImport(BypassAccessingMacros)
    assertMacroExpansion(
      """
      @BypassAccess
      struct User {}
      """,
      expandedSource: """
        struct User {}
        """,
      diagnostics: [
        DiagnosticSpec(
          message: "'@BypassAccess' cannot be applied to this declaration",
          line: 1,
          column: 1,
          severity: .error
        )
      ],
      macros: testMacros
    )
    #else
    throw XCTSkip("macros are only supported when running tests for the host platform")
    #endif
  }
}
