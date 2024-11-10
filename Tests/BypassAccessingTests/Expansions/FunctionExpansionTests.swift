import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosTestSupport
import XCTest

final class FunctionExpansionTests: XCTestCase {
  func testPlain() throws {
    #if canImport(BypassAccessingMacros)
    assertMacroExpansion(
      """
      struct User {
        @BypassAccess
        private func greet() {}
      }
      """,
      expandedSource: """
        struct User {
          private func greet() {}

          #if DEBUG
          func ___greet() {
              greet(

            )
          }
          #endif
        }
        """,
      macros: testMacros
    )

    assertMacroExpansion(
      """
      struct User {
        @BypassAccess
        private func greet(first f: String, _ second: @escaping () -> String) {
          print("Hello \\(f) \\(second())")
        }
      }
      """,
      expandedSource: """
        struct User {
          private func greet(first f: String, _ second: @escaping () -> String) {
            print("Hello \\(f) \\(second())")
          }

          #if DEBUG
          func ___greet(first f: String, _ second: @escaping () -> String) {
              greet(
              first: f,
              _: second
            )
          }
          #endif
        }
        """,
      macros: testMacros
    )

    assertMacroExpansion(
      """
      struct User {
        @BypassAccess
        private func greet(to target: String = "World") -> String {
          "Hello \\(target)"
        }
      }
      """,
      expandedSource: """
        struct User {
          private func greet(to target: String = "World") -> String {
            "Hello \\(target)"
          }

          #if DEBUG
          func ___greet(to target: String = "World") -> String {
              greet(
              to: target
            )
          }
          #endif
        }
        """,
      macros: testMacros
    )
    #else
    throw XCTSkip("macros are only supported when running tests for the host platform")
    #endif
  }
}
