import AppKit

// MARK: - Diff Block Highlighting

extension CodeBlockHighlighter {

    /// Line-numbered diff: "123 -\tcode" or "123 +\tcode" or "123\tcode" (compiled once)
    private static let lineNumDiffRx = try? NSRegularExpression(
        pattern: #"^(\d+)(\s[+-])?\t(.*)$"#, options: .anchorsMatchLines)
    /// Simple diff: "- code" or "+ code" (compiled once)
    private static let simpleDiffRx = try? NSRegularExpression(
        pattern: #"^([+-])\s(.*)$"#, options: .anchorsMatchLines)

    /// Highlight a diff code block with red/green backgrounds for removed/added lines,
    /// and line numbers for context. Format: "LINE_NUM -\tcode" or "LINE_NUM +\tcode" or "LINE_NUM\tcode"
    public static func highlightDiffBlock(code: String, font: NSFont) -> NSAttributedString {
        if looksLikeUnifiedDiff(code) { return highlightUnifiedDiff(code: code, font: font) }
        let text = CodeBlockTheme.text
        let result = NSMutableAttributedString(string: code, attributes: [
            .font: font, .foregroundColor: text
        ])
        let isDark = CodeBlockTheme.isDark

        let removedBg = isDark
            ? NSColor(red: 0.4, green: 0.1, blue: 0.1, alpha: 1.0)    // dark red
            : NSColor(red: 1.0, green: 0.85, blue: 0.85, alpha: 1.0)
        let addedBg = isDark
            ? NSColor(red: 0.1, green: 0.3, blue: 0.1, alpha: 1.0)    // dark green
            : NSColor(red: 0.85, green: 1.0, blue: 0.85, alpha: 1.0)
        let lineNumColor = isDark
            ? NSColor(red: 0.5, green: 0.5, blue: 0.55, alpha: 1)     // dim
            : NSColor(red: 0.45, green: 0.45, blue: 0.5, alpha: 1)
        let removedText = isDark
            ? NSColor(red: 1.0, green: 0.7, blue: 0.7, alpha: 1)      // light red text
            : NSColor(red: 0.6, green: 0.0, blue: 0.0, alpha: 1)
        let addedText = isDark
            ? NSColor(red: 0.7, green: 1.0, blue: 0.7, alpha: 1)      // light green text
            : NSColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1)

        let ns = code as NSString
        let r = NSRange(location: 0, length: ns.length)

        // Try line-numbered format first
        var matched = false
        lineNumDiffRx?.enumerateMatches(in: code, range: r) { m, _, _ in
            guard let m else { return }
            matched = true
            let fullRange = m.range

            // Color line number dim
            let numRange = m.range(at: 1)
            result.addAttribute(.foregroundColor, value: lineNumColor, range: numRange)

            // Check for +/- marker
            if m.range(at: 2).length > 0 {
                let marker = ns.substring(with: m.range(at: 2)).trimmingCharacters(in: .whitespaces)
                if marker == "-" {
                    result.addAttribute(.backgroundColor, value: removedBg, range: fullRange)
                    result.addAttribute(.foregroundColor, value: removedText, range: m.range(at: 3))
                } else if marker == "+" {
                    result.addAttribute(.backgroundColor, value: addedBg, range: fullRange)
                    result.addAttribute(.foregroundColor, value: addedText, range: m.range(at: 3))
                }
            }
        }

        // Fallback to simple diff format if no line-numbered matches
        if !matched {
            simpleDiffRx?.enumerateMatches(in: code, range: r) { m, _, _ in
                guard let m else { return }
                let fullRange = m.range
                let marker = ns.substring(with: m.range(at: 1))
                if marker == "-" {
                    result.addAttribute(.backgroundColor, value: removedBg, range: fullRange)
                    result.addAttribute(.foregroundColor, value: removedText, range: fullRange)
                } else if marker == "+" {
                    result.addAttribute(.backgroundColor, value: addedBg, range: fullRange)
                    result.addAttribute(.foregroundColor, value: addedText, range: fullRange)
                }
            }
        }

        return result
    }

    // MARK: - Unified (git) diff

    /// Header lines that can appear inside a git diff between hunks.
    private static let unifiedHeaderPrefixes = [
        "diff --git ", "index ", "--- ", "+++ ", "new file mode", "deleted file mode",
        "old mode", "new mode", "similarity index", "rename from", "rename to", "Binary files"
    ]

    /// True for `git diff` / `diff -u` output: a `diff --git` header, or `---`/`+++` file headers plus an `@@` hunk.
    public static func looksLikeUnifiedDiff(_ code: String) -> Bool {
        let t = code.drop(while: { $0 == "\n" || $0 == " " })
        if t.hasPrefix("diff --git ") { return true }
        return code.contains("\n@@ ") && code.contains("--- ") && code.contains("+++ ")
    }

    /// True if `line` can belong to a unified diff (header, hunk, context, add, remove, "\ No newline").
    public static func isUnifiedDiffLine(_ line: Substring) -> Bool {
        guard let c = line.first else { return false }
        if c == " " || c == "+" || c == "-" || c == "\\" { return true }
        if line.hasPrefix("@@") { return true }
        return unifiedHeaderPrefixes.contains(where: { line.hasPrefix($0) })
    }

    /// git-style coloring: file headers bold, `@@` hunks cyan, `-` lines red, `+` lines green (with tinted background).
    public static func highlightUnifiedDiff(code: String, font: NSFont) -> NSAttributedString {
        let isDark = CodeBlockTheme.isDark
        let result = NSMutableAttributedString(string: code, attributes: [
            .font: font, .foregroundColor: CodeBlockTheme.text
        ])
        let bold = NSFont.monospacedSystemFont(ofSize: font.pointSize, weight: .bold)
        let removedBg = isDark ? NSColor(red: 0.4, green: 0.1, blue: 0.1, alpha: 0.6) : NSColor(red: 1.0, green: 0.88, blue: 0.88, alpha: 1)
        let addedBg = isDark ? NSColor(red: 0.1, green: 0.3, blue: 0.1, alpha: 0.6) : NSColor(red: 0.88, green: 1.0, blue: 0.88, alpha: 1)
        let removedText = isDark ? NSColor(red: 1.0, green: 0.55, blue: 0.55, alpha: 1) : NSColor(red: 0.7, green: 0.0, blue: 0.0, alpha: 1)
        let addedText = isDark ? NSColor(red: 0.55, green: 0.95, blue: 0.55, alpha: 1) : NSColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1)
        let hunk = isDark ? NSColor(red: 0.4, green: 0.85, blue: 0.85, alpha: 1) : NSColor(red: 0.0, green: 0.5, blue: 0.5, alpha: 1)
        let meta = isDark ? NSColor(red: 0.6, green: 0.6, blue: 0.65, alpha: 1) : NSColor(red: 0.4, green: 0.4, blue: 0.45, alpha: 1)

        let ns = code as NSString
        var loc = 0
        while loc < ns.length {
            let lr = ns.lineRange(for: NSRange(location: loc, length: 0))
            var body = lr
            if body.length > 0, ns.character(at: NSMaxRange(body) - 1) == 10 { body.length -= 1 }
            let line = ns.substring(with: body)
            if line.hasPrefix("diff --git ") || line.hasPrefix("--- ") || line.hasPrefix("+++ ") {
                result.addAttributes([.foregroundColor: CodeBlockTheme.text, .font: bold], range: body)
            } else if line.hasPrefix("@@") {
                result.addAttribute(.foregroundColor, value: hunk, range: body)
            } else if line.hasPrefix("-") {
                result.addAttributes([.foregroundColor: removedText, .backgroundColor: removedBg], range: body)
            } else if line.hasPrefix("+") {
                result.addAttributes([.foregroundColor: addedText, .backgroundColor: addedBg], range: body)
            } else if unifiedHeaderPrefixes.contains(where: { line.hasPrefix($0) }) || line.hasPrefix("\\") {
                result.addAttribute(.foregroundColor, value: meta, range: body)
            }
            loc = NSMaxRange(lr)
        }
        return result
    }
}
