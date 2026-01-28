{.emit: """

import { Marked } from 'marked';
import { markedHighlight } from 'marked-highlight';
import markedAlert from 'marked-alert';
import markedFootnote from 'marked-footnote';

import hljs from 'highlight.js/lib/common';
import nim from 'highlight.js/lib/languages/nim';
hljs.registerLanguage('nim', nim);

""".}

import std/[jsffi]

type
  MarkedRenderer = object
    code: proc(code: cstring, infoString: cstring, escaped: bool): cstring
  MarkedHighlightOptions = object
    langPrefix, emptyLangClass: cstring
    highlight: proc(code: cstring, lang: cstring): cstring
  HighlightResponse = object
    value: cstring
  MarkedExtension = object
    pedantic, gfm: bool
    renderer: MarkedRenderer
  Marked {.importc.} = object

type Hljs = object ## highlight js module
let hljs {.importjs: "hljs".}: Hljs

proc getLanguage(hljs: Hljs, lang: cstring): bool {.importjs: "#.getLanguage(#)"}
proc highlight(hljs: Hljs, code: cstring, o: JsObject): HighlightResponse {.importjs: "#.highlight(#, #)"}
proc highlighter(code: cstring, lang: cstring): cstring =
  let language =
    if lang != cstring"" and hljs.getLanguage(lang): lang
    else: cstring"plaintext"
  result = hljs.highlight(code, JsObject{language: language}).value
proc markedHighlight(options: MarkedHighlightOptions): MarkedExtension {.importjs: "markedHighlight(#)".}
proc markedAlert(): MarkedExtension {.importc.}
proc markedFootnote(): MarkedExtension {.importc.}

# proc newMarked(opts: MarkedExtension): Marked {.importjs: "new Marked(#)".}
proc newMarked(): Marked {.importjs: "new Marked()"}
proc use(m: Marked, ext: MarkedExtension) {.importjs: "#.use(#)".}
proc parse*(marked: Marked, txt: cstring): cstring {.importjs: "#.parse(#)".}

var marked* {.exportc.} = newMarked()

let highlightExt = markedHighlight(
  MarkedHighlightOptions(
    emptyLangClass: "hljs",
    langPrefix: "hljs-language-",
    highlight: highlighter
  )
)

proc renderCode(code: cstring, infoString: cstring, escaped: bool): cstring {.exportc.} =
  ## post-process marked-highlight render to add "not-prose" class to prevent styling overlap with @unocss/preset-typography
  let rendered = highlightExt.renderer.code(code, infoString, escaped)
  result = cstring("""<pre class="not-prose p-5 rounded-md bg-[#e1e1e1] overflow-auto"""" & ($rendered)[4..^1])

marked.use(highlightExt)
marked.use(markedAlert())
marked.use(markedFootnote())
marked.use(MarkedExtension(gfm: true, renderer: MarkedRenderer(code: renderCode)))

