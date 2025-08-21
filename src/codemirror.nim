import std/[jsffi, dom]


{.emit:"""
const basicSetup = require("codemirror").basicSetup
const EditorView = require("@codemirror/view").EditorView
const markdown = require("@codemirror/lang-markdown").markdown
""".}

type
  EditorView = object
    dom: Element

proc newEditorView*(
  doc: cstring, parent: Element
): EditorView {.importjs: """
new EditorView({
  doc: #,
  parent: #,
  extensions: [
    basicSetup,
    markdown(),
    EditorView.updateListener.of(function(v) {
      if (v.docChanged) {renderDoc(v.state.doc.toString())}
      })
  ]
})
"""}


