import std/jsffi

let hljs {.exportc.} = require("highlight.js")

type
  MarkedHighlightOptions = object
    langPrefix, emptyLangClass: string
    highlight: proc(code: string, lang: string): string

  HighlightResponse = object
    value: string

proc getLanguage(hljs: JsObject, lang: string): bool {.importjs: "#.getLanguage(#)"}
proc highlight(hljs: JsObject, code: string, o: JsObject): HighlightResponse {.importjs: "#.highlight(#, #)"}
proc highlighter(code: string, lang: string): string =
  let language = if hljs.getLanguage(lang): lang else: "plaintext"
  hljs.highlight(code, JsObject{ language: language }).value

proc markedHighlight(options: MarkedHighlightOptions): JsObject {.importjs: "require(\"marked-highlight\").markedHighlight(#)".}
let Marked {.exportc.} = require("marked").Marked
proc newMarked(opts: JsObject): JsObject {.importjs: "Marked(#)".}

let marked* {.exportc.} = jsNew newMarked(
  markedHighlight(MarkedHighlightOptions(
     emptyLangClass: "hljs",
     langPrefix: "hljs language-",
     highlight: highlighter))
)
marked.use(JsObject{pedantic: false, gfm: true})


proc parse*(marked: JsObject, txt: cstring): cstring {.importjs:"#.parse(#)"}
