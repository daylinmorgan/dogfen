import std/[jsffi]
import ./esm

type
  Hljs = ref object of JsRoot ## highlight js module
  HljsLanguage = ref object of JsRoot

let hljs {.esm: "default:highlight.js/lib/common", importc.}: Hljs
let nim {.esm: "default:highlight.js/lib/languages/nim", importc.}: HljsLanguage

proc registerLanguage(hljs: Hljs, name: cstring, language: HljsLanguage) {.importcpp.}

hljs.registerLanguage("nim", nim)

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

esm marked:
  type Marked = ref object of JsRoot

proc getLanguage(hljs: Hljs, lang: cstring): bool {.importcpp.}
proc highlight(hljs: Hljs, code: cstring, o: JsObject): HighlightResponse {.importcpp.}
proc highlighter(code: cstring, lang: cstring): cstring =
  let language =
    if lang != cstring"" and hljs.getLanguage(lang): lang
    else: cstring"plaintext"
  result = hljs.highlight(code, JsObject{language: language}).value
proc markedHighlight(options: MarkedHighlightOptions): MarkedExtension {.esm: "marked-highlight", importc.}
proc markedAlert(): MarkedExtension {.esm: "default:marked-alert", importc.}
proc markedFootnote(): MarkedExtension {.esm: "default:marked-footnote", importc.}

# proc newMarked(opts: MarkedExtension): Marked {.importjs: "new Marked(#)".}
proc newMarked(): Marked {.importjs: "new Marked()"}
proc use(m: Marked, ext: MarkedExtension) {.importcpp.}
proc parse*(marked: Marked, txt: cstring): cstring {.importcpp.}


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
