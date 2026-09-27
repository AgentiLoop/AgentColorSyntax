import Testing
import AppKit
@testable import AgentColorSyntax

@Suite("Test output highlighting")
struct TestOutputTests {
    private let font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)

    private let passing = """
    ✔ Test "ASCII path: home / top dir / filename are distinct" passed
    ✔ Test "Tilde path" passed
    ✔ Suite "colorizePath" passed
    ✔ Test run with 8 tests in 2 suites passed after 0.018 seconds.
    """

    private let failing = """
    ✘ Test "👤 user prompt is bold" recorded an issue at ActivityLogLineTests.swift:47:9: Expectation failed: font(s) == bold
    ✘ Test "👤 user prompt is bold" failed after 0.016 seconds with 1 issue.
    """

    private func color(_ s: NSAttributedString, at word: String) -> NSColor? {
        let loc = (s.string as NSString).range(of: word).location
        guard loc != NSNotFound else { return nil }
        return s.attribute(.foregroundColor, at: loc, effectiveRange: nil) as? NSColor
    }

    @Test("Fenced swift-testing output is detected regardless of language tag")
    func detected() {
        #expect(CodeBlockHighlighter.looksLikeTestOutput(passing))
        #expect(CodeBlockHighlighter.looksLikeTestOutput(failing))
        #expect(!CodeBlockHighlighter.looksLikeTestOutput("let x = \"a\"\nprint(x)"))
    }

    @Test("Test names are plain text, not string-red")
    func namesPlain() {
        let s = CodeBlockHighlighter.highlight(code: passing, language: nil, font: font)
        #expect(color(s, at: "Tilde path") == CodeBlockTheme.text)
        #expect(color(s, at: "ASCII path") == CodeBlockTheme.text)
        #expect(color(s, at: "ASCII path") != CodeBlockTheme.string)
    }

    @Test("✔/passed share the pass color; ✘/failed share the fail color; they differ")
    func passFail() {
        let p = CodeBlockHighlighter.highlight(code: passing, language: "swift", font: font)
        let f = CodeBlockHighlighter.highlight(code: failing, language: "swift", font: font)
        #expect(color(p, at: "✔") == color(p, at: "passed"))
        #expect(color(f, at: "✘") == color(f, at: "failed after"))
        #expect(color(p, at: "✔") != color(f, at: "✘"))
        #expect(color(f, at: "Expectation failed:") == color(f, at: "✘"))
    }
}
