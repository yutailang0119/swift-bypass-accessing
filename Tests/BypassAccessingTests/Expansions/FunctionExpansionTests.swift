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
            greet()
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
            greet(first: f, _: second)
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
            greet(to: target)
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

  func testModifiers() throws {
    #if canImport(BypassAccessingMacros)
    assertMacroExpansion(
      """
      struct User {
        @BypassAccess
        private static func greet() {}
      }
      """,
      expandedSource: """
        struct User {
          private static func greet() {}

          #if DEBUG
          static func ___greet() {
            greet()
          }
          #endif
        }
        """,
      macros: testMacros,
      indentationWidth: .spaces(2)
    )

    assertMacroExpansion(
      """
      class UserGroup {
        @BypassAccess
        private class func max() {}
      }
      """,
      expandedSource: """
        class UserGroup {
          private class func max() {}

          #if DEBUG
          class func ___max() {
            max()
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
        fileprivate func greet() {}
      }
      """,
      expandedSource: """
        struct User {
          fileprivate func greet() {}

          #if DEBUG
          func ___greet() {
            greet()
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
        private mutating func modify() {}
      }
      """,
      expandedSource: """
        struct User {
          private mutating func modify() {}

          #if DEBUG
          mutating func ___modify() {
            modify()
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
        @MainActor private func greet() {}
      }
      """,
      expandedSource: """
        struct User {
          @MainActor private func greet() {}

          #if DEBUG
          @MainActor func ___greet() {
            greet()
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
        private func greet() throws {}
      }
      """,
      expandedSource: """
        struct User {
          private func greet() throws {}

          #if DEBUG
          func ___greet() throws {
            try greet()
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
        private func greet() async {}
      }
      """,
      expandedSource: """
        struct User {
          private func greet() async {}

          #if DEBUG
          func ___greet() async {
            await greet()
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
        private func greet() async throws {}
      }
      """,
      expandedSource: """
        struct User {
          private func greet() async throws {}

          #if DEBUG
          func ___greet() async throws {
            try await greet()
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

  func testTypeSpecifiers() throws {
    #if canImport(BypassAccessingMacros)
    assertMacroExpansion(
      """
      struct User {
        @BypassAccess
        private func nickname(_ name: inout String) {
          name += "-san"
        }
      }
      """,
      expandedSource: """
        struct User {
          private func nickname(_ name: inout String) {
            name += "-san"
          }

          #if DEBUG
          func ___nickname(_ name: inout String) {
            nickname(_: &name)
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

  func testGenerics() throws {
    #if canImport(BypassAccessingMacros)
    assertMacroExpansion(
      """
      struct User {
        @BypassAccess
        private func greet<I: BinaryInteger>(times: I) -> String {
          "He\\(Array(repeating: "ll", count: Int(times)).joined())o"
        }
      }
      """,
      expandedSource: """
        struct User {
          private func greet<I: BinaryInteger>(times: I) -> String {
            "He\\(Array(repeating: "ll", count: Int(times)).joined())o"
          }

          #if DEBUG
          func ___greet<I: BinaryInteger>(times: I) -> String {
            greet(times: times)
          }
          #endif
        }
        """,
      macros: testMacros,
      indentationWidth: .spaces(2)
    )

    assertMacroExpansion(
      """
      struct User<Element> {
        @BypassAccess
        private func number() -> Element where Element == Int {
          119
        }
      }
      """,
      expandedSource: """
        struct User<Element> {
          private func number() -> Element where Element == Int {
            119
          }

          #if DEBUG
          func ___number() -> Element where Element == Int {
            number()
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
