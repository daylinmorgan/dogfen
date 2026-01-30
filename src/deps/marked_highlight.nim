import std/[asyncjs, strutils, jsconsole, sugar, jsffi]
import ./esm

proc getOfficialLanguages: seq[string] {.compileTime.}=
  const t = staticRead "./languages.txt"
  for line in t.splitLines:
    result.add line

const officialLanguages* = getOfficialLanguages()
# TODO: add support for known 3rd-party languages

type
  Hljs = ref object of JsRoot ## highlight js module
  HljsLanguage = ref object of JsRoot

let hljs {.esm: "default:highlight.js/lib/common", importc.}: Hljs
let nim {.esm: "default:highlight.js/lib/languages/nim", importc.}: HljsLanguage

proc registerLanguage(hljs: Hljs, name: cstring, language: HljsLanguage) {.importcpp.}

hljs.registerLanguage("nim", nim)

type
  MarkedHighlightOptions* = object
    async: bool
    langPrefix, emptyLangClass: cstring
    highlight: proc(code: cstring, lang: cstring): Future[cstring]
  HighlightResponse = object
    value: cstring


# getLanguage is not actually a bool but I think because of JS truthy rules it's fine for now
proc getLanguage(hljs: Hljs, lang: cstring): bool {.importcpp.}
proc highlight(hljs: Hljs, code: cstring, o: JsObject): HighlightResponse {.importcpp.}

proc loadLanguageDynamic(name: cstring) {.async.} =
  console.log "fetching missing language"
  await esmImportDefault("https://esm.sh/highlight.js@11.11.1/lib/languages/" & name, HljsLanguage).then(
    (lang: HljsLanguage) => hljs.registerLanguage(name, lang)
  )

proc highlighter*(code: cstring, lang: cstring): Future[cstring] {.async.} =
  var language = cstring"plaintext" # default to plaintext
  if lang != cstring"":
    if hljs.getLanguage(lang):
      language = lang
    else:
      if $lang in officialLanguages:
        await loadLanguageDynamic(lang)
          .then(() => (language = lang))
          .catch((e: Error) => console.log("failed to dynamically load ", lang, "for highlight.js: ", e.message))

    return hljs.highlight(code, JsObject{language: language}).value

  return code


