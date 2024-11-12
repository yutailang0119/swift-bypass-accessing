import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosTestSupport
import XCTest

final class PropertyExpansionTests: XCTestCase {
  func testStored() throws {
    #if canImport(BypassAccessingMacros)
    assertMacroExpansion(
      """
      struct User {
        @BypassAccess
        private let name: String = "yutailang0119"
      }
      """,
      expandedSource: """
        struct User {
          private let name: String = "yutailang0119"

          #if DEBUG
          var ___name: String {
            name
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
        private var name: String = "yutailang0119"
      }
      """,
      expandedSource: """
        struct User {
          private var name: String = "yutailang0119"

          #if DEBUG
          var ___name: String {
            get {
              name
            }
            set {
              name = newValue
            }
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

  func testComputed() throws {
    #if canImport(BypassAccessingMacros)
    assertMacroExpansion(
      """
      struct User {
        @BypassAccess
        private var name: String {
          "yutailang0119"
        }
      }
      """,
      expandedSource: """
        struct User {
          private var name: String {
            "yutailang0119"
          }

          #if DEBUG
          var ___name: String {
            get   {
                name
            }
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
        private var name: String {
          get {
            "yutailang0119"
          }
          set {
            print(newValue)
          }
        }
      }
      """,
      expandedSource: """
        struct User {
          private var name: String {
            get {
              "yutailang0119"
            }
            set {
              print(newValue)
            }
          }

          #if DEBUG
          var ___name: String {
            get {
              name
            }
            set {
              name = newValue
            }
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

  func testStatic() throws {
    #if canImport(BypassAccessingMacros)
    assertMacroExpansion(
      """
      struct User {
        @BypassAccess
        private static let name: String = "yutailang0119"
      }
      """,
      expandedSource: """
        struct User {
          private static let name: String = "yutailang0119"

          #if DEBUG
          static
          var ___name: String {
            name
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
        private static var name: String = "yutailang0119"
      }
      """,
      expandedSource: """
        struct User {
          private static var name: String = "yutailang0119"

          #if DEBUG
          static
          var ___name: String {
            get {
              name
            }
            set {
              name = newValue
            }
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
