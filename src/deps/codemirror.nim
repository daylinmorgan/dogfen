import std/[dom, jsffi]
import ./esm

esm codemirror, {basicSetup}
esm "@codemirror/lang-markdown", { markdown }

type
  Text* {.importc.} = ref object
    length*: int
  EditorState* {.importc.} = ref object
    doc*: Text

esm "@codemirror/view":
  type
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

proc toString*(doc: Text): cstring {.importcpp.}
proc dispatch(view: EditorView, o: JsObject) {.importcpp.}
proc replaceContent*(view: EditorView, text: cstring) =
  view.dispatch(js{
    changes: js{
      `from`: 0,
      to: view.state.doc.length,
      insert: text
    }
  })
