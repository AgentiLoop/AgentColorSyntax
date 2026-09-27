import Testing
import AppKit
@testable import AgentColorSyntax

@Suite("Tool output lines")
struct ToolOutputLineTests {
    private let font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    private let bold = NSFont.monospacedSystemFont(ofSize: 12, weight: .bold)

    private func hl(_ line: String) -> NSAttributedString {
        CodeBlockHighlighter.highlightActivityLogLine(line: line, font: font) ?? NSAttributedString()
    }

    private func color(_ s: NSAttributedString, at word: String) -> NSColor? {
        let loc = (s.string as NSString).range(of: word).location
        guard loc != NSNotFound else { return nil }
        return s.attribute(.foregroundColor, at: loc, effectiveRange: nil) as? NSColor
    }

    private func font(_ s: NSAttributedString, at word: String) -> NSFont? {
        let loc = (s.string as NSString).range(of: word).location
        guard loc != NSNotFound else { return nil }
        return s.attribute(.font, at: loc, effectiveRange: nil) as? NSFont
    }

    @Test("git status -sb branch line: local and upstream colored differently, text preserved")
    func gitBranch() {
        #expect(CodeBlockHighlighter.looksLikeGitBranchLine("## main...origin/main [ahead 2]"))
        #expect(!CodeBlockHighlighter.looksLikeGitBranchLine("## Summary"))
        let s = hl("## main...origin/main [ahead 2]")
        #expect(s.string == "## main...origin/main [ahead 2]")
        #expect(font(s, at: "main") == bold)
        #expect(color(s, at: "main") != color(s, at: "origin/main"))
        #expect(color(s, at: "ahead 2") != color(s, at: "##"))
    }

    @Test("BUILD SUCCEEDED green bold, BUILD FAILED red bold, and they differ")
    func buildResult() {
        let ok = hl("[18:53:33] BUILD SUCCEEDED")
        let bad = hl("[18:53:20] BUILD FAILED (failed)")
        #expect(font(ok, at: "BUILD") == bold)
        #expect(font(bad, at: "BUILD") == bold)
        #expect(color(ok, at: "BUILD") != NSColor.labelColor)
        #expect(color(ok, at: "BUILD") != color(bad, at: "BUILD"))
    }

    @Test("grep -n context output: match number bold, context number dim, code syntax-highlighted")
    func grepNumbered() {
        let match = hl("443:    nonisolated func renderMarkdownLine(_ line: String) -> NSAttributedString {")
        let ctx = hl("444-        let nsLine = line as NSString")
        #expect(match.string.hasPrefix("443:    nonisolated"))
        #expect(font(match, at: "443") == bold)
        #expect(font(ctx, at: "444") != bold)
        #expect(color(match, at: "443") != color(ctx, at: "444"))
        #expect(color(ctx, at: "let") == CodeBlockTheme.keyword)
        #expect(color(match, at: "func") == CodeBlockTheme.keyword)
        // Empty context line still recognized
        #expect(hl("446-").string == "446-")
    }

    @Test("Dates and times are not mistaken for grep line numbers")
    func notGrep() {
        #expect(CodeBlockHighlighter.highlightActivityLogLine(line: "2026-04-06 release", font: font) == nil)
    }
}
