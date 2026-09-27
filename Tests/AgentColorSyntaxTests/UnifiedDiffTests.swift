import Testing
import AppKit
@testable import AgentColorSyntax

@Suite("Unified diff highlighting")
struct UnifiedDiffTests {
    private let font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)

    private let gitDiff = """
    diff --git a/Package.resolved b/Package.resolved
    index 9d8b2ce4..be58c69d 100644
    --- a/Package.resolved
    +++ b/Package.resolved
    @@ -24,8 +24,8 @@
           "kind" : "remoteSourceControl",
    -        "revision" : "5a5e994ad75768bd3593708016c3af19ef3edb12",
    -        "version" : "1.2.8"
    +        "revision" : "bf2ad909ca6032adec835f6cfb1ecfc5b66d36a3",
    +        "version" : "1.2.9"
           }
    """

    private func attr(_ s: NSAttributedString, _ key: NSAttributedString.Key, at text: String) -> Any? {
        let loc = (s.string as NSString).range(of: text).location
        guard loc != NSNotFound else { return nil }
        return s.attribute(key, at: loc, effectiveRange: nil)
    }

    @Test("git diff output is detected; line-numbered D1F diffs are not")
    func detection() {
        #expect(CodeBlockHighlighter.looksLikeUnifiedDiff(gitDiff))
        #expect(!CodeBlockHighlighter.looksLikeUnifiedDiff("12 -\told\n12 +\tnew"))
    }

    @Test("- lines red, + lines green, context plain, @@ distinct, headers bold")
    func colors() {
        let s = CodeBlockHighlighter.highlight(code: gitDiff, language: "diff", font: font)
        let removed = attr(s, .foregroundColor, at: "-        \"version\" : \"1.2.8\"") as? NSColor
        let added = attr(s, .foregroundColor, at: "+        \"version\" : \"1.2.9\"") as? NSColor
        let context = attr(s, .foregroundColor, at: "\"kind\"") as? NSColor
        let hunk = attr(s, .foregroundColor, at: "@@ -24") as? NSColor
        #expect(removed != nil && added != nil && removed != added)
        #expect(context == CodeBlockTheme.text)
        #expect(removed != context && added != context)
        #expect(hunk != context && hunk != removed && hunk != added)
        #expect(attr(s, .backgroundColor, at: "-        \"version\"") != nil)
        #expect(attr(s, .backgroundColor, at: "\"kind\"") == nil)
        let bold = NSFont.monospacedSystemFont(ofSize: 12, weight: .bold)
        #expect(attr(s, .font, at: "--- a/") as? NSFont == bold)
        #expect(attr(s, .font, at: "+++ b/") as? NSFont == bold)
        // The "--- a/" header must not get removed-line red.
        #expect(attr(s, .foregroundColor, at: "--- a/") as? NSColor != removed)
    }

    @Test("isUnifiedDiffLine accepts diff lines and rejects log lines")
    func lineClassifier() {
        #expect(CodeBlockHighlighter.isUnifiedDiffLine("+x"))
        #expect(CodeBlockHighlighter.isUnifiedDiffLine(" ctx"))
        #expect(CodeBlockHighlighter.isUnifiedDiffLine("@@ -1 +1 @@"))
        #expect(CodeBlockHighlighter.isUnifiedDiffLine("index abc..def 100644"))
        #expect(!CodeBlockHighlighter.isUnifiedDiffLine("[18:52:01] 🔧 xcode(build)"))
        #expect(!CodeBlockHighlighter.isUnifiedDiffLine(""))
    }
}
