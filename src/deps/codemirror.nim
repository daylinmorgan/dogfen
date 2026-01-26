import std/[dom, jsffi]

{.
  emit:
    """
import { basicSetup } from "codemirror";
import { EditorView } from "@codemirror/view";
import { markdown } from "@codemirror/lang-markdown";
"""
.}

type
  Text* {.importc.} = ref object
    length*: int
  EditorState* {.importc.} = ref object
    doc*: Text
  EditorView* {.importc.} = ref object
    dom*: Element
    state*: EditorState

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

var editor* {.exportc.}: EditorView

proc toString*(doc: Text): cstring {.importjs: "#.toString()"}
proc dispatch(view: EditorView, o: JsObject) {.importjs: "#.dispatch(#)"}
proc replaceContent*(view: EditorView, text: cstring) =
  view.dispatch(js{
    changes: js{
      `from`: 0,
      to: view.state.doc.length,
      insert: text
    }
  })
