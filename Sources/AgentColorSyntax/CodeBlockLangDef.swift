import AppKit

// MARK: - Language Definition

public struct LangDef: @unchecked Sendable {
    public let keywords: Set<String>
    public let declKeywords: Set<String>
    public let types: Set<String>
    public let selfKw: Set<String>
    public let sysFuncs: Set<String>
    public let commentPrefix: String?
    public let blockComStart: String?
    public let blockComEnd: String?
    public let hasAttrs: Bool
    public let hasPreproc: Bool
    public let stringRegex: NSRegularExpression?
    /// Compiled once per language instead of per highlight call.
    public let blockCommentRegex: NSRegularExpression?
    public let lineCommentRegex: NSRegularExpression?

    public init(kw: [String] = [], decl: [String] = [], types: [String] = [], selfKw: [String] = [],
         sys: [String] = [], comment: String? = "//", blockStart: String? = "/*", blockEnd: String? = "*/",
         attrs: Bool = false, preproc: Bool = false, strPat: String = #""(?:\\.|[^"\\])*""#) {
        self.keywords = Set(kw)
        self.declKeywords = Set(decl)
        self.types = Set(types)
        self.selfKw = Set(selfKw)
        self.sysFuncs = Set(sys)
        self.commentPrefix = comment
        self.blockComStart = blockStart
        self.blockComEnd = blockEnd
        self.hasAttrs = attrs
        self.hasPreproc = preproc
        self.stringRegex = try? NSRegularExpression(pattern: strPat)
        if let blockStart, let blockEnd {
            let e1 = NSRegularExpression.escapedPattern(for: blockStart)
            let e2 = NSRegularExpression.escapedPattern(for: blockEnd)
            self.blockCommentRegex = try? NSRegularExpression(pattern: "\(e1)[\\s\\S]*?\(e2)", options: .dotMatchesLineSeparators)
        } else {
            self.blockCommentRegex = nil
        }
        if let comment {
            let esc = NSRegularExpression.escapedPattern(for: comment)
            self.lineCommentRegex = try? NSRegularExpression(pattern: "\(esc).*$", options: .anchorsMatchLines)
        } else {
            self.lineCommentRegex = nil
        }
    }
}
