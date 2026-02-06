import ./[marked_highlight]
import ../lib

type
  MarkedRenderer = object
    code: proc(code: cstring, infoString: cstring, escaped: bool): cstring
  MarkedHighlightOptions = object
    async: bool
    langPrefix, emptyLangClass: cstring
    highlight: proc(code: cstring, lang: cstring): Future[cstring]
  EmojiToken = ref object of JsRoot
    `type`: cstring
    raw: cstring
    name: cstring
    emoji: cstring
  MarkedEmojiOptions = object
    emojis: JsObject
    renderer: proc(token: EmojiToken): cstring
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
# proc markedEmoji(options: MarkedEmojiOptions): MarkedExtension {.esm: "./deps/marked_emoji.js", importc.}
proc markedEmoji(options: MarkedEmojiOptions): MarkedExtension {.esm: "marked-emoji", importc.}
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

proc emojiRenderer(token: EmojiToken): cstring = return token.emoji

{.emit:"""import emojis from './static/emojis.json' with { type: 'json' };"""}
let emojis {.importc.}: JsObject

var marked* {.exportc.} = newMarked()

# doesn't NEED to be async anymore
proc initMarked*(start: cstring) {.async.} =
  marked.use(highlightExt)
  marked.use(markedAlert())
  marked.use(markedFootnote())
  marked.use(markedEmoji(MarkedEmojiOptions(emojis: emojis, renderer: emojiRenderer)))
  when defined(katex):
    marked.use(markedKatex())
  marked.use(MarkedExtension(gfm: true, renderer: MarkedRenderer(code: renderCode)))


export marked_highlight
