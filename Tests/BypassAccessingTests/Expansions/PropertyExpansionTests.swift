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
      macros: testMacros,
      indentationWidth: .spaces(2)
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
      macros: testMacros,
      indentationWidth: .spaces(2)
    )

    assertMacroExpansion(
      """
      struct User {
        @BypassAccess
        private let name = "yutailang0119"
      }
      """,
      expandedSource: """
        struct User {
          private let name = "yutailang0119"
        }
        """,
      diagnostics: [
        DiagnosticSpec(
          message: "'@BypassAccess' attribute require TypeAnnotation",
          line: 2,
          column: 3,
          severity: .error
        )
      ],
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
            get {
              name
            }
          }
          #endif
        }
        """,
      macros: testMacros,
      indentationWidth: .spaces(2)
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
      macros: testMacros,
      indentationWidth: .spaces(2)
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
          static var ___name: String {
            name
          }
          #endif
        }
        """,
      macros: testMacros,
      indentationWidth: .spaces(2)
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
          static var ___name: String {
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
      macros: testMacros,
      indentationWidth: .spaces(2)
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
        @MainActor private var name: String {
          get {
            "yutailang0119"
          }
        }
      }
      """,
      expandedSource: """
        struct User {
          @MainActor private var name: String {
            get {
              "yutailang0119"
            }
          }

          #if DEBUG
          @MainActor var ___name: String {
            get {
              name
            }
          }
          #endif
        }
        """,
      macros: testMacros,
      indentationWidth: .spaces(2)
    )
    #else
    throw XCTSkip("macros are only supported when running tests for the host platform")
    #endif
  }

  func testAccessors() throws {
    #if canImport(BypassAccessingMacros)
    assertMacroExpansion(
      """
      struct User {
        @BypassAccess
        private var name: String {
          get throws {
            "yutailang0119"
          }
        }
      }
      """,
      expandedSource: """
        struct User {
          private var name: String {
            get throws {
              "yutailang0119"
            }
          }

          #if DEBUG
          var ___name: String {
            get throws {
              try name
            }
          }
          #endif
        }
        """,
      macros: testMacros,
      indentationWidth: .spaces(2)
    )

    assertMacroExpansion(
      """
      struct User {
        @BypassAccess
        private var name: String {
          get async {
            "yutailang0119"
          }
        }
      }
      """,
      expandedSource: """
        struct User {
          private var name: String {
            get async {
              "yutailang0119"
            }
          }

          #if DEBUG
          var ___name: String {
            get async {
              await name
            }
          }
          #endif
        }
        """,
      macros: testMacros,
      indentationWidth: .spaces(2)
    )

    assertMacroExpansion(
      """
      struct User {
        @BypassAccess
        private var name: String {
          get async throws {
            "yutailang0119"
          }
        }
      }
      """,
      expandedSource: """
        struct User {
          private var name: String {
            get async throws {
              "yutailang0119"
            }
          }

          #if DEBUG
          var ___name: String {
            get async throws {
              try await name
            }
          }
          #endif
        }
        """,
      macros: testMacros,
      indentationWidth: .spaces(2)
    )
    #else
    throw XCTSkip("macros are only supported when running tests for the host platform")
    #endif
  }
}
