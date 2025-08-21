import std/[dom]

{.
  emit:
    """
import { basicSetup } from "codemirror";
import { EditorView } from "@codemirror/view";
import { markdown } from "@codemirror/lang-markdown";
"""
.}

type EditorView = object
  dom: Element

proc newEditorView*(
  doc: cstring, parent: Element
): EditorView {.
  importjs:
    """
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
"""
.}
