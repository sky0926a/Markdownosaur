//
//  Markdownosaur.swift
//  Markdownosaur
//
//  Created by Christian Selig on 2021-11-02.
//

import UIKit
import Markdown

public struct MarkdownosaurPreference {
    public struct MarkdownosaurPreferenceFont {
        public var base = UIFont.systemFont(ofSize: 15, weight: .regular)
        public var tableHeader = UIFont.systemFont(ofSize: 15, weight: .bold)
        public var inlineCode = UIFont.monospacedSystemFont(ofSize: 15 - 1.0, weight: .regular)
        public var codeBlock = UIFont.monospacedSystemFont(ofSize: 15 - 1.0, weight: .regular)
        public var orderedListNumeral = UIFont.monospacedDigitSystemFont(ofSize: 15, weight: .regular)
        public var newLine = UIFont.systemFont(ofSize: 15, weight: .regular)
        public lazy var heading1: UIFont = { return headingFont(headingLevel: 1) }()
        public lazy var heading2: UIFont = { return headingFont(headingLevel: 2) }()
        public lazy var heading3: UIFont = { return headingFont(headingLevel: 3) }()
        public lazy var heading4: UIFont = { return headingFont(headingLevel: 4) }()
        public lazy var heading5: UIFont = { return headingFont(headingLevel: 5) }()
        public lazy var heading6: UIFont = { return headingFont(headingLevel: 6) }()
        
        private func headingFont(headingLevel: Int) -> UIFont {
            return base.apply(newTraits: .traitBold, newPointSize: 28.0 - CGFloat(headingLevel * 2))
        }
    }
    
    public struct MarkdownosaurPreferenceSymbol {
        public var singleNewLine = "\n"
        public var doubleNewLine = "\n\n"
        public var tableVerticalLine = "｜"
        public var bullet = "‧"
        public var intentBullet = "。"
        public var checkboxChecked = "☑"
        public var checkboxUnchecked = "☐"
    }
    
    public struct MarkdownosaurPreferenceColor {
        public var inlineCodeForegroundColor =  UIColor.systemGray
        public var inlineCodeBackgroundColor =  UIColor(red: 246/255, green: 248/255, blue: 250/255, alpha: 1)
        public var codeBlockForegroundColor =  UIColor.systemGray
        public var codeBlockBackgroundColor =  UIColor(red: 246/255, green: 248/255, blue: 250/255, alpha: 1)
    }
    
    public var font = MarkdownosaurPreferenceFont()
    public var symbol = MarkdownosaurPreferenceSymbol()
    public var color = MarkdownosaurPreferenceColor()
    
    public static var shared = MarkdownosaurPreference()
}

public struct MarkdownosaurParser {
    private var parser = Markdownosaur()

    public mutating func attributedString(from markdown: String) -> NSAttributedString {
        let document = Document(parsing: markdown)
        return parser.attributedString(from: document)
    }
}

public struct Markdownosaur: MarkupVisitor {
    public var preference = MarkdownosaurPreference.shared

    public init() {}
    
    public mutating func attributedString(from document: Document) -> NSAttributedString {
        return visit(document)
    }
    
    mutating public func defaultVisit(_ markup: Markup) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        for child in markup.children {
            result.append(visit(child))
        }
        
        return result
    }
    
    mutating public func visitText(_ text: Text) -> NSAttributedString {
        return NSAttributedString(string: text.plainText, attributes: [.font: preference.font.base])
    }
    
    mutating public func visitEmphasis(_ emphasis: Emphasis) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        for child in emphasis.children {
            result.append(visit(child))
        }
        
        result.applyEmphasis()
        
        return result
    }
    
    mutating public func visitStrong(_ strong: Strong) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        for child in strong.children {
            result.append(visit(child))
        }
        
        result.applyStrong()
        
        return result
    }
    
    mutating public func visitParagraph(_ paragraph: Paragraph) -> NSAttributedString {
        let result = NSMutableAttributedString()
        print("visitParagraph start")
        for child in paragraph.children {
            let content = visit(child)
            print("visitParagraph content: \(content.string), hasSuccessor: \(child.hasSuccessor)")
            result.append(content)
            if content.string == "" {
                print("visitParagraph content new line")
                result.append(.singleNewline())
            }
        }
        if paragraph.hasSuccessor {
            print("visitParagraph paragraph hasSuccessor")
            if paragraph.isContainedInList {
                result.append(.singleNewline())
            } else {
                result.append(.doubleNewline())
            }
            
        }
        print("visitParagraph end")
        return result
    }
    
    mutating public func visitHeading(_ heading: Heading) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        for child in heading.children {
            result.append(visit(child))
        }
        let newFont: UIFont = {
            switch heading.level {
            case 1: return preference.font.heading1
            case 2: return preference.font.heading2
            case 3: return preference.font.heading3
            case 4: return preference.font.heading4
            case 5: return preference.font.heading5
            case 6: return preference.font.heading6
            default: return preference.font.base
            }
        }()
        result.applyHeading(withLevel: heading.level, font: newFont)
        
        if heading.hasSuccessor {
            result.append(.singleNewline())
        }
        
        return result
    }
    
    mutating public func visitLink(_ link: Link) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        for child in link.children {
            result.append(visit(child))
        }
        
        let url = link.destination != nil ? URL(string: link.destination!) : nil
        
        result.applyLink(withURL: url)
        
        return result
    }
    
    mutating public func visitInlineCode(_ inlineCode: InlineCode) -> NSAttributedString {
        return NSAttributedString(string: inlineCode.code,
                                  attributes: [
                                    .font: preference.font.inlineCode,
                                    .foregroundColor: preference.color.inlineCodeForegroundColor,
                                    .backgroundColor: preference.color.inlineCodeBackgroundColor
                                  ])
    }
    
    public func visitCodeBlock(_ codeBlock: CodeBlock) -> NSAttributedString {
        let result = NSMutableAttributedString(string: codeBlock.code,
                                               attributes: [
                                                .font: preference.font.codeBlock,
                                                .foregroundColor: preference.color.codeBlockForegroundColor,
                                                .backgroundColor: preference.color.codeBlockBackgroundColor
                                               ])
        
        if codeBlock.hasSuccessor {
            result.append(.singleNewline())
        }
    
        return result
    }
    
    mutating public func visitStrikethrough(_ strikethrough: Strikethrough) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        for child in strikethrough.children {
            result.append(visit(child))
        }
        
        result.applyStrikethrough()
        
        return result
    }
    
    mutating public func visitUnorderedList(_ unorderedList: UnorderedList) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        let font = preference.font.base
                
        for listItem in unorderedList.listItems {
            var listItemAttributes: [NSAttributedString.Key: Any] = [:]
            
            let listItemParagraphStyle = NSMutableParagraphStyle()
            
            let baseLeftMargin: CGFloat = 15.0
            let leftMarginOffset = baseLeftMargin + (20.0 * CGFloat(unorderedList.listDepth))
            let spacingFromIndex: CGFloat = 8.0
            var symbolText = preference.symbol.bullet
            if let checkBox = listItem.checkbox {
                switch checkBox {
                case.checked:
                    symbolText = preference.symbol.checkboxChecked
                case .unchecked:
                    symbolText = preference.symbol.checkboxUnchecked
                }
            }
            let bulletWidth = ceil(NSAttributedString(string: symbolText, attributes: [.font: font]).size().width)
            let firstTabLocation = leftMarginOffset + bulletWidth
            let secondTabLocation = firstTabLocation + spacingFromIndex
            
            listItemParagraphStyle.tabStops = [
                NSTextTab(textAlignment: .right, location: firstTabLocation),
                NSTextTab(textAlignment: .left, location: secondTabLocation)
            ]
            
            listItemParagraphStyle.headIndent = secondTabLocation
            
            listItemAttributes[.paragraphStyle] = listItemParagraphStyle
            listItemAttributes[.font] = font
            listItemAttributes[.listDepth] = unorderedList.listDepth
            
            let listItemAttributedString = visit(listItem).mutableCopy() as! NSMutableAttributedString
            listItemAttributedString.insert(NSAttributedString(string: "\t\(symbolText)\t", attributes: listItemAttributes), at: 0)
            
            result.append(listItemAttributedString)
        }
        
        if unorderedList.hasSuccessor {
            result.append(.doubleNewline())
        }
        
        return result
    }
    
    mutating public func visitListItem(_ listItem: ListItem) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        for child in listItem.children {
            result.append(visit(child))
        }
        
        if listItem.hasSuccessor {
            result.append(.singleNewline())
        }
        
        return result
    }
    
    mutating public func visitTable(_ table: Table) -> NSAttributedString {
        let result = NSMutableAttributedString()
        result.append(.verticalLine())
        for child in table.head.children {
            let headItem = NSMutableAttributedString(attributedString: visit(child))
            headItem.addAttribute(.font, value: preference.font.tableHeader)
            result.append(headItem)
            if child.hasSuccessor {
                result.append(.verticalLine())
            }
        }
        result.append(.verticalLine())
        if !table.body.isEmpty {
            result.append(.singleNewline())
        }
        for body in table.body.children {
            result.append(.verticalLine())
            for cell in body.children {
                result.append(visit(cell))
                if cell.hasSuccessor {
                    result.append(.verticalLine())
                }
            }
            result.append(.verticalLine())
            if body.hasSuccessor {
                result.append(.singleNewline())
            }
        }
        if table.hasSuccessor {
            result.append(.doubleNewline())
        }
        
        return result
    }
    
    mutating public func visitOrderedList(_ orderedList: OrderedList) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let font = preference.font.base
        
        for (index, listItem) in orderedList.listItems.enumerated() {
            var listItemAttributes: [NSAttributedString.Key: Any] = [:]
            
            let numeralFont = preference.font.orderedListNumeral
            
            let listItemParagraphStyle = NSMutableParagraphStyle()
            
            // Implement a base amount to be spaced from the left side at all times to better visually differentiate it as a list
            let baseLeftMargin: CGFloat = 15.0
            let leftMarginOffset = baseLeftMargin + (20.0 * CGFloat(orderedList.listDepth))
            
            // Grab the highest number to be displayed and measure its width (yes normally some digits are wider than others but since we're using the numeral mono font all will be the same width in this case)
            let highestNumberInList = orderedList.childCount
            let numeralColumnWidth = ceil(NSAttributedString(string: "\(highestNumberInList).", attributes: [.font: numeralFont]).size().width)
            
            let spacingFromIndex: CGFloat = 8.0
            let firstTabLocation = leftMarginOffset + numeralColumnWidth
            let secondTabLocation = firstTabLocation + spacingFromIndex
            
            listItemParagraphStyle.tabStops = [
                NSTextTab(textAlignment: .right, location: firstTabLocation),
                NSTextTab(textAlignment: .left, location: secondTabLocation)
            ]
            
            listItemParagraphStyle.headIndent = secondTabLocation
            
            listItemAttributes[.paragraphStyle] = listItemParagraphStyle
            listItemAttributes[.font] = font
            listItemAttributes[.listDepth] = orderedList.listDepth

            let listItemAttributedString = visit(listItem).mutableCopy() as! NSMutableAttributedString
            
            // Same as the normal list attributes, but for prettiness in formatting we want to use the cool monospaced numeral font
            var numberAttributes = listItemAttributes
            numberAttributes[.font] = numeralFont
            
            let numberAttributedString = NSAttributedString(string: "\t\(index + 1).\t", attributes: numberAttributes)
            listItemAttributedString.insert(numberAttributedString, at: 0)
            
            result.append(listItemAttributedString)
        }
        
        if orderedList.hasSuccessor {
            result.append(orderedList.isContainedInList ? .singleNewline() : .doubleNewline())
        }
        
        return result
    }
    
    mutating public func visitBlockQuote(_ blockQuote: BlockQuote) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        let font = preference.font.base
        for child in blockQuote.children {
            var quoteAttributes: [NSAttributedString.Key: Any] = [:]
            
            let quoteParagraphStyle = NSMutableParagraphStyle()
            
            let baseLeftMargin: CGFloat = 15.0
            let leftMarginOffset = baseLeftMargin + (20.0 * CGFloat(blockQuote.quoteDepth))
            
            quoteParagraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: leftMarginOffset)]
            
            quoteParagraphStyle.headIndent = leftMarginOffset
            
            quoteAttributes[.paragraphStyle] = quoteParagraphStyle
            quoteAttributes[.font] = font
            quoteAttributes[.listDepth] = blockQuote.quoteDepth
            
            let quoteAttributedString = visit(child).mutableCopy() as! NSMutableAttributedString
            quoteAttributedString.insert(NSAttributedString(string: "\t", attributes: quoteAttributes), at: 0)
            
            quoteAttributedString.addAttribute(.foregroundColor, value: UIColor.systemGray)
            
            result.append(quoteAttributedString)
        }
        
        if blockQuote.hasSuccessor {
            result.append(.doubleNewline())
        }
        
        return result
    }
}

// MARK: - Extensions Land

extension NSMutableAttributedString {
    func applyEmphasis() {
        enumerateAttribute(.font, in: NSRange(location: 0, length: length), options: []) { value, range, stop in
            guard let font = value as? UIFont else { return }
            
            let newFont = font.apply(newTraits: .traitItalic)
            addAttribute(.font, value: newFont, range: range)
        }
    }
    
    func applyStrong() {
        enumerateAttribute(.font, in: NSRange(location: 0, length: length), options: []) { value, range, stop in
            guard let font = value as? UIFont else { return }
            
            let newFont = font.apply(newTraits: .traitBold)
            addAttribute(.font, value: newFont, range: range)
        }
    }
    
    func applyLink(withURL url: URL?) {
        addAttribute(.foregroundColor, value: UIColor.systemBlue)
        
        if let url = url {
            addAttribute(.link, value: url)
        }
    }
    
    func applyBlockquote() {
        addAttribute(.foregroundColor, value: UIColor.systemGray)
    }
    
    func applyHeading(withLevel headingLevel: Int, font: UIFont) {
        enumerateAttribute(.font, in: NSRange(location: 0, length: length), options: []) { value, range, stop in
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 10
//            paragraphStyle.lineHeightMultiple = 1.5
            let attributes: [NSAttributedString.Key : Any] = [
                .font: font,
                .paragraphStyle: paragraphStyle,
                
            ]
            addAttributes(attributes, range: range)
        }
    }
    
    func applyStrikethrough() {
        addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue)
    }
}

extension UIFont {
    func apply(newTraits: UIFontDescriptor.SymbolicTraits, newPointSize: CGFloat? = nil) -> UIFont {
        var existingTraits = fontDescriptor.symbolicTraits
        existingTraits.insert(newTraits)
        
        guard let newFontDescriptor = fontDescriptor.withSymbolicTraits(existingTraits) else { return self }
        return UIFont(descriptor: newFontDescriptor, size: newPointSize ?? pointSize)
    }
}

extension ListItemContainer {
    /// Depth of the list if nested within others. Index starts at 0.
    var listDepth: Int {
        var index = 0

        var currentElement = parent

        while currentElement != nil {
            if currentElement is ListItemContainer {
                index += 1
            }

            currentElement = currentElement?.parent
        }
        
        return index
    }
}

extension BlockQuote {
    /// Depth of the quote if nested within others. Index starts at 0.
    var quoteDepth: Int {
        var index = 0

        var currentElement = parent

        while currentElement != nil {
            if currentElement is BlockQuote {
                index += 1
            }

            currentElement = currentElement?.parent
        }
        
        return index
    }
}

extension NSAttributedString.Key {
    static let listDepth = NSAttributedString.Key("ListDepth")
    static let quoteDepth = NSAttributedString.Key("QuoteDepth")
}

extension NSMutableAttributedString {
    func addAttribute(_ name: NSAttributedString.Key, value: Any) {
        addAttribute(name, value: value, range: NSRange(location: 0, length: length))
    }
    
    func addAttributes(_ attrs: [NSAttributedString.Key : Any]) {
        addAttributes(attrs, range: NSRange(location: 0, length: length))
    }
}

extension Markup {
    /// Returns true if this element has sibling elements after it.
    var hasSuccessor: Bool {
        guard let childCount = parent?.childCount else { return false }
        return indexInParent < childCount - 1
    }
    
    var isContainedInList: Bool {
        var currentElement = parent

        while currentElement != nil {
            if currentElement is ListItemContainer {
                return true
            }

            currentElement = currentElement?.parent
        }
        
        return false
    }
}

extension NSAttributedString {
    private static var preference = MarkdownosaurPreference.shared
    
    static func singleNewline() -> NSAttributedString {
        return NSAttributedString(string: preference.symbol.singleNewLine,
                                  attributes: [.font: preference.font.newLine])
    }
    
    static func doubleNewline() -> NSAttributedString {
        return NSAttributedString(string: preference.symbol.doubleNewLine,
                                  attributes: [.font: preference.font.newLine])
    }
    
    static func verticalLine() -> NSAttributedString {
        return NSAttributedString(string: preference.symbol.tableVerticalLine,
                                  attributes: [.font: preference.font.newLine])
    }
}
