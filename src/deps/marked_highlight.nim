import std/[tables, json]
import ../lib

const baseUrl = "https://esm.sh/"

type
  SupportedLanguages = object
    paths: Table[string, string] # name -> esm.sh/{path}
    names: Table[string, string] # alias -> name

const supportedLanguages =
  staticRead("../static/supportedLanguages.json")
    .parseJson().to(SupportedLanguages)

proc getPath(langs: SupportedLanguages, name: string): string =
  if name in langs.paths:
    return langs.paths[name]
  if name.toLowerAscii() in langs.names:
    let aliased = langs.names[name.toLowerAscii()]
    return getPath(langs, aliased)

proc nameToImportLink(name: cstring): cstring =
  if name == nil: return
  let path = supportedLanguages.getPath($name)
  if path != "":
    return cstring(baseUrl & path)

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

proc loadLanguageDynamic(name: cstring, link: cstring) {.async.} =
  console.log "fetching missing language: " & name
  await esmImportDefault(link, HljsLanguage)
    .then((lang: HljsLanguage) => hljs.registerLanguage(name, lang))

proc highlighter*(code: cstring, lang: cstring): Future[cstring] {.async.} =
  var language = cstring"plaintext" # default to plaintext
  if lang != cstring"":
    if hljs.getLanguage(lang): # language already registered
      language = lang
    else:
      let link = nameToImportLink(lang)
      if link != nil:
        await loadLanguageDynamic(lang, link)
          .then(() => (language = lang)) .catch((e: Error) => console.error("failed to dynamically load ", lang, "for highlight.js: ", e.message))
    return hljs.highlight(code, JsObject{language: language}).value

  return code


