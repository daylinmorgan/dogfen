import std/[asyncjs]
import ./[esm, marked_highlight]

type
  MarkedRenderer = object
    code: proc(code: cstring, infoString: cstring, escaped: bool): cstring
  MarkedHighlightOptions = object
    async: bool
    langPrefix, emptyLangClass: cstring
    highlight: proc(code: cstring, lang: cstring): Future[cstring]
  MarkedExtension = object
    pedantic, gfm: bool
    renderer: MarkedRenderer

esm marked:
  type Marked = ref object of JsRoot

proc markedAlert(): MarkedExtension {.esm: "default:marked-alert", importc.}
proc markedFootnote(): MarkedExtension {.esm: "default:marked-footnote", importc.}

# proc newMarked(opts: MarkedExtension): Marked {.importjs: "new Marked(#)".}
proc newMarked(): Marked {.importjs: "new Marked()"}
proc use(m: Marked, ext: MarkedExtension) {.importcpp.}
proc parse*(marked: Marked, txt: cstring): Future[cstring] {.importcpp.}
proc markedHighlight*(options: MarkedHighlightOptions): MarkedExtension {.esm: "marked-highlight", importc.}

let highlightExt* = markedHighlight(
  MarkedHighlightOptions(
    emptyLangClass: "hljs",
    langPrefix: "hljs-language-",
    async: true,
    highlight: highlighter
  )
)


var marked* {.exportc.} = newMarked()

proc renderCode(code: cstring, infoString: cstring, escaped: bool): cstring {.exportc.} =
  ## post-process marked-highlight render to add "not-prose" class to prevent styling overlap with @unocss/preset-typography
  let rendered = highlightExt.renderer.code(code, infoString, escaped)
  result = cstring("""<pre class="not-prose p-5 rounded-md shadow-lg overflow-auto"""" & ($rendered)[4..^1])

marked.use(highlightExt)
marked.use(markedAlert())
marked.use(markedFootnote())
marked.use(MarkedExtension(gfm: true, renderer: MarkedRenderer(code: renderCode)))
