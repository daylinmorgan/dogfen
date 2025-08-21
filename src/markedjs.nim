import std/[jsffi]

let hljs {.exportc.} = require("highlight.js")

type
  MarkedHighlightOptions = object
    langPrefix, emptyLangClass: string
    highlight: proc(code: cstring, lang: cstring): cstring

  HighlightResponse = object
    value: cstring

proc getLanguage(hljs: JsObject, lang: cstring): bool {.importjs: "#.getLanguage(#)"}
proc highlight(hljs: JsObject, code: cstring, o: JsObject): HighlightResponse {.importjs: "#.highlight(#, #)"}
proc highlighter(code: cstring, lang: cstring): cstring =
  let language =
    if lang != cstring"" and hljs.getLanguage(lang): lang
    else: cstring"plaintext"
  result = hljs.highlight(code, JsObject{ language: language}).value


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
