import SwiftUI
import AppKit

// MARK: - Native Syntax Highlighting Text Editor with Line Numbers Gutter
public struct NativeCodeEditorView: View {
    @Binding var text: String
    var onSave: (() -> Void)?

    @State private var lineCount: Int = 1

    public init(text: Binding<String>, onSave: (() -> Void)? = nil) {
        self._text = text
        self.onSave = onSave
    }

    public var body: some View {
        HStack(spacing: 0) {
            // Line Numbers Gutter
            lineNumbersGutter()
                .frame(width: 46)
                .background(Color(red: 0.04, green: 0.06, blue: 0.10))
                .overlay(
                    Rectangle()
                        .frame(width: 1)
                        .foregroundColor(Color.white.opacity(0.08)),
                    alignment: .trailing
                )

            // Text Area
            CodeTextViewRepresentable(text: $text, onSave: onSave)
                .background(Color(red: 0.05, green: 0.08, blue: 0.13))
        }
        .onAppear {
            updateLineCount()
        }
        .onChange(of: text) { _, _ in
            updateLineCount()
        }
    }

    private func updateLineCount() {
        let count = text.components(separatedBy: .newlines).count
        self.lineCount = max(count, 1)
    }

    private func lineNumbersGutter() -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .trailing, spacing: 3.5) {
                ForEach(1...lineCount, id: \.self) { num in
                    Text("\(num)")
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.3))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, 8)
                }
            }
            .padding(.top, 8)
        }
        .disabled(true)
    }
}

// MARK: - AppKit NSTextView Wrapper with Real-time Syntax Highlighting
struct CodeTextViewRepresentable: NSViewRepresentable {
    @Binding var text: String
    var onSave: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        let textView = NSTextView()
        textView.autoresizingMask = [.width]
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.textColor = .white
        textView.insertionPointColor = NSColor(red: 0.0, green: 0.96, blue: 0.83, alpha: 1.0)
        textView.font = NSFont.monospacedSystemFont(ofSize: 12.5, weight: .regular)

        textView.delegate = context.coordinator
        context.coordinator.textView = textView

        // Apply initial text and syntax highlighting
        textView.string = text
        context.coordinator.applySyntaxHighlighting()

        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
            context.coordinator.applySyntaxHighlighting()
        }
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: CodeTextViewRepresentable
        weak var textView: NSTextView?

        init(_ parent: CodeTextViewRepresentable) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let tv = textView else { return }
            parent.text = tv.string
            applySyntaxHighlighting()
        }

        func applySyntaxHighlighting() {
            guard let tv = textView, let storage = tv.textStorage else { return }
            let code = tv.string
            let fullRange = NSRange(location: 0, length: code.utf16.count)

            storage.beginEditing()

            // Base font and color
            let baseFont = NSFont.monospacedSystemFont(ofSize: 12.5, weight: .regular)
            storage.setAttributes([
                .font: baseFont,
                .foregroundColor: NSColor.white.withAlphaComponent(0.9)
            ], range: fullRange)

            // 1. Strings in Aqua / Cyan ("...")
            highlightPattern(in: storage, text: code, pattern: "\"[^\"]*\"", color: NSColor(red: 0.0, green: 0.96, blue: 0.83, alpha: 1.0))

            // 2. Numbers & Unit keywords (587, 80ms, 60Hz)
            highlightPattern(in: storage, text: code, pattern: "\\b\\d+(\\.\\d+)?(ms|Hz|fps)?\\b", color: NSColor(red: 0.75, green: 0.52, blue: 1.0, alpha: 1.0))

            // 3. Looping Keywords
            let keywords = "\\b(define app|create window|set|let|mut|val|fn|import|use python|draw card|draw button|spawn sprite|spawn platform|spawn coin|play tone|syscall|repeat|loop|if|then|print|echo|as|at|size|with|title|text|action|version)\\b"
            highlightPattern(in: storage, text: code, pattern: keywords, color: NSColor(red: 0.22, green: 0.74, blue: 0.97, alpha: 1.0), bold: true)

            // 4. Operators and Pipelines (->, |>, :=, ++)
            highlightPattern(in: storage, text: code, pattern: "(->|\\|>|:=|\\+\\+|==|!=|<=|>=)", color: NSColor(red: 1.0, green: 0.65, blue: 0.15, alpha: 1.0), bold: true)

            // 5. Comments (# and //)
            highlightPattern(in: storage, text: code, pattern: "(#.*|//.*)", color: NSColor(red: 0.39, green: 0.45, blue: 0.55, alpha: 1.0))

            storage.endEditing()
        }

        private func highlightPattern(in storage: NSTextStorage, text: String, pattern: String, color: NSColor, bold: Bool = false) {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }
            let range = NSRange(location: 0, length: text.utf16.count)
            let font = bold
                ? NSFont.monospacedSystemFont(ofSize: 12.5, weight: .bold)
                : NSFont.monospacedSystemFont(ofSize: 12.5, weight: .regular)

            regex.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
                if let matchRange = match?.range {
                    storage.addAttribute(.foregroundColor, value: color, range: matchRange)
                    if bold {
                        storage.addAttribute(.font, value: font, range: matchRange)
                    }
                }
            }
        }
    }
}
