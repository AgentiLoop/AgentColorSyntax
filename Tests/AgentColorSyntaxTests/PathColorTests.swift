import Testing
import AppKit
@testable import AgentColorSyntax

@Suite("colorizePath")
struct PathColorTests {
    private func colored(_ path: String) -> (NSMutableAttributedString, NSFont) {
        let font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        let bold = NSFont.monospacedSystemFont(ofSize: 12, weight: .bold)
        let s = NSMutableAttributedString(string: path, attributes: [.font: font])
        CodeBlockHighlighter.colorizePath(s, pathRange: NSRange(location: 0, length: s.length), path: path, bold: bold)
        return (s, bold)
    }

    private func color(_ s: NSAttributedString, at utf16Offset: Int) -> NSColor? {
        s.attribute(.foregroundColor, at: utf16Offset, effectiveRange: nil) as? NSColor
    }

    @Test("ASCII path: home / top dir / filename are distinct")
    func asciiPath() {
        let (s, bold) = colored("/Users/todd/Documents/GitHub/Agent/README.md")
        #expect(color(s, at: 0) == CodeBlockHighlighter.pathHome)
        #expect(color(s, at: 12) == CodeBlockHighlighter.pathTopDir)              // "Documents/"
        #expect(color(s, at: s.length - 1) == CodeBlockHighlighter.pathFilename)
        #expect(s.attribute(.font, at: s.length - 1, effectiveRange: nil) as? NSFont == bold)
    }

    @Test("Non-BMP characters before the filename don't shift the ranges")
    func emojiPath() {
        // "🎉" is 2 UTF-16 units but 1 Character — the old Character-based math was off by one here.
        let path = "/Users/todd/Docs 🎉/Agent/READ🎉ME.md"
        let (s, bold) = colored(path)
        let ns = path as NSString
        let filenameStart = ns.range(of: "/", options: .backwards).location + 1
        #expect(color(s, at: filenameStart) == CodeBlockHighlighter.pathFilename)
        #expect(color(s, at: filenameStart - 1) == CodeBlockHighlighter.pathMiddle)
        #expect(s.attribute(.font, at: ns.length - 1, effectiveRange: nil) as? NSFont == bold)
    }

    @Test("Tilde path")
    func tildePath() {
        let (s, _) = colored("~/Library/Caches/x.txt")
        #expect(color(s, at: 0) == CodeBlockHighlighter.pathHome)
        #expect(color(s, at: 2) == CodeBlockHighlighter.pathTopDir)
        #expect(color(s, at: s.length - 1) == CodeBlockHighlighter.pathFilename)
    }
}
