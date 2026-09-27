import Testing
import AppKit
@testable import AgentColorSyntax

@Suite("highlightActivityLogLine")
struct ActivityLogLineTests {
    private let font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    private let bold = NSFont.monospacedSystemFont(ofSize: 12, weight: .bold)

    private func hl(_ line: String) -> NSAttributedString {
        let s = CodeBlockHighlighter.highlightActivityLogLine(line: line, font: font)
        #expect(s != nil)
        return s ?? NSAttributedString()
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

    @Test("Plain log line still reds error keywords")
    func errorKeywordRed() {
        let s = hl("[18:30:10] Claude API Error: boom failed")
        #expect(color(s, at: "failed") != NSColor.labelColor)
        #expect(color(s, at: "boom") == NSColor.labelColor)
    }

    @Test("✅ Completed: label is green bold; prose 'Error' is not red")
    func completedLine() {
        let s = hl("[18:34:09] ✅ Completed: Error History now fills in. Tool failed lines don't show.")
        #expect(font(s, at: "Completed:") == bold)
        #expect(color(s, at: "Completed:") != NSColor.labelColor)
        #expect(color(s, at: "Error History") == NSColor.labelColor)
        #expect(color(s, at: "failed") == NSColor.labelColor)
    }

    @Test("👤 user prompt is bold and never red")
    func userPrompt() {
        let s = hl("[18:33:57] 👤 why do we never get history errors?")
        #expect(font(s, at: "errors") == bold)
        #expect(color(s, at: "errors") == NSColor.labelColor)
    }

    @Test("🔒 Jev verdict is dimmed entirely")
    func jevDimmed() {
        let s = hl("[18:32:50] 🔒 Jev: 1% destructive — allowed: git add /Users/x/y.swift (jev-1.13.0)")
        let dim = color(s, at: "[18:32:50]")
        #expect(color(s, at: "Jev:") == dim)
        #expect(color(s, at: "destructive") == dim)
        #expect(color(s, at: "/Users") == dim)
    }

    @Test("Timestamp-less lines are unaffected by the body rules")
    func noTimestamp() {
        let s = hl("/Users/todd/file.swift:12: error: bad")
        #expect(color(s, at: "error") != NSColor.labelColor)
    }
}
