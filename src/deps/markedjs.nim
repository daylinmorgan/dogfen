import ./[marked_highlight]
import ../lib

type
  MarkedRenderer = object
    code: proc(code: cstring, infoString: cstring, escaped: bool): cstring
  MarkedHighlightOptions = object
    async: bool
    langPrefix, emptyLangClass: cstring
    highlight: proc(code: cstring, lang: cstring): Future[cstring]
  MarkedEmojiOptions = object
    emojis: seq[cstring] 
    # renderer: proc(token: JsObject): cstring
  MarkedExtension = object
    pedantic, gfm: bool
    renderer: MarkedRenderer

esm marked:
  type Marked = ref object of JsRoot

# TODO: modify the markedAlert renderer to use less space
proc markedAlert(): MarkedExtension {.esm: "default:marked-alert", importc.}
proc markedFootnote(): MarkedExtension {.esm: "default:marked-footnote", importc.}

# proc newMarked(opts: MarkedExtension): Marked {.importjs: "new Marked(#)".}
proc newMarked(): Marked {.importjs: "new Marked()"}
proc use(m: Marked, ext: MarkedExtension) {.importcpp.}
proc parse*(marked: Marked, txt: cstring): Future[cstring] {.importcpp.}
proc markedHighlight*(options: MarkedHighlightOptions): MarkedExtension {.esm: "marked-highlight", importc.}
proc markedEmoji(options: MarkedEmojiOptions): MarkedExtension {.esm: "./deps/marked_emoji.js", importc.}
when defined(katex):
  proc markedKatex(): MarkedExtension {.esm: "default:marked-katex-extension", importc.}

let highlightExt* = markedHighlight(
  MarkedHighlightOptions(
    emptyLangClass: "hljs",
    langPrefix: "hljs-language-",
    async: true,
    highlight: highlighter
  )
)

proc renderCode(code: cstring, infoString: cstring, escaped: bool): cstring {.exportc.} =
  ## post-process marked-highlight render to add "not-prose" class to prevent styling overlap with @unocss/preset-typography
  let rendered = highlightExt.renderer.code(code, infoString, escaped)
  result = cstring("""<pre class="not-prose p-5 rounded-md shadow-lg overflow-auto"""" & ($rendered)[4..^1])

var marked* {.exportc.} = newMarked()

# proc fetchIconNames(icons: string = "openmoji"): Future[seq[cstring]] {.async.} =
#   var names: seq[cstring]
#   let emojis = await fetch(fmt"https://esm.sh/@iconify-json/{icons}/icons.json".cstring).then(
#     (r: Response) => r.json()
#   )
#   for k, _ in emojis.aliases.pairs:
#     names.add k
#   for  k, _ in emojis.icons.pairs:
#     names.add k
#   return names

# replaces the above proc
const emojiNames = staticRead("../static/icons.txt").splitLines().mapIt(it.cstring)

# doesn't NEED to be async anymore
proc initMarked*() {.async.} =
  marked.use(highlightExt)
  marked.use(markedAlert())
  marked.use(markedFootnote())
  marked.use(markedEmoji(
    MarkedEmojiOptions(
      emojis: emojiNames,
    )
  ))
  when defined(katex):
    marked.use(markedKatex())
  marked.use(MarkedExtension(gfm: true, renderer: MarkedRenderer(code: renderCode)))


