import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosTestSupport
import XCTest

final class InitializerExpansionTests: XCTestCase {
  func testPlain() throws {
    #if canImport(BypassAccessingMacros)
    assertMacroExpansion(
      """
      struct User {
        @BypassAccess
        private init() {}
      }
      """,
      expandedSource: """
        struct User {
          private init() {}

          #if DEBUG
          static
          func ___init() -> Self {
              Self.init(

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
        private init(name: String) {
          print(name)
        }
      }
      """,
      expandedSource: """
        struct User {
          private init(name: String) {
            print(name)
          }

          #if DEBUG
          static
          func ___init(name: String) -> Self {
              Self.init(
              name: name
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

  func testFailable() throws {
    #if canImport(BypassAccessingMacros)
    assertMacroExpansion(
      """
      struct User {
        @BypassAccess
        private init?() {
          nil
        }
      }
      """,
      expandedSource: """
        struct User {
          private init?() {
            nil
          }

          #if DEBUG
          static
          func ___init() -> Self? {
              Self.init(

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
        private init!() {
          nil
        }
      }
      """,
      expandedSource: """
        struct User {
          private init!() {
            nil
          }

          #if DEBUG
          static
          func ___init() -> Self! {
              Self.init(

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

  func testAttributes() throws {
    #if canImport(BypassAccessingMacros)
    assertMacroExpansion(
      """
      struct User {
        @BypassAccess
        @MainActor private init() {}
      }
      """,
      expandedSource: """
        struct User {
          @MainActor private init() {}

          #if DEBUG
          @MainActor static
          func ___init() -> Self {
              Self.init(

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
