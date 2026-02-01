import std/[sequtils, strutils, tables]
import std/[asyncjs, strutils, jsconsole, sugar, jsffi]
import ./esm


const baseUrl = "https://esm.sh/"
const officialPath = "highlight.js@11.11.1/lib/languages/"
const notsupported = [
  "Toit", # 404
  "TTCN-3", # not on npm or esm :/
  "Zig", # highlighter doesn't appear to load correctly?
]

type Lang = object
  name: string
  aliases: seq[string]
  path: string

proc langToOfficialName(l: Lang): string =
  const official = staticRead("../static/marked-highlight-official-languages.txt").splitLines()
  case l.name
  of "STEP Part 21": return "step21"
  else:
    for s in official:
      if l.name.toLowerAscii() == s: return s
      for a in l.aliases:
        if a == s: return s

  assert false, "failed to convert " & $l & " to official langugage"

proc setEsmLink(l: var Lang, s: string)=
  if s != "":
    echo l, s
    assert s.contains("https://github.com")
    let ss = s.split("https://github.com/")
    l.path = "gh/" & ss[1].strip().replace(")", "")
  else:
    l.path = officialPath  & l.langToOfficialName

proc init(T: typedesc[Lang], row: string): T =
  let s = row.strip().split("|").mapIt(it.strip())
  assert s.len > 4 # this table needs a good linting
  result.name = s[1]
  result.aliases = s[2].split(",").mapIt(it.strip())
  if result.name notin notSupported:
    result.setEsmLink(s[3])

proc parseLanguagesDoc(): seq[Lang] =
  let lines = staticRead("../static/highlightjs_SUPPORTED_LANGUAGES.md").splitLines
  let begin = lines.find("<!-- LANGLIST -->")
  let ending = lines.find("<!-- LANGLIST_END -->")
  assert begin != 0
  assert ending != 0
  for row in lines[begin+3..<ending]:
    let lang = Lang.init(row)
    if lang.name notin notSupported:
      result.add lang

# make this a 'path' and then make the dynammic load concat the string to baseUrl

proc genLookUp(langs: seq[Lang]): Table[cstring, cstring] =
  for lang in langs:
    result[lang.name.cstring] = lang.path.cstring
    for a in lang.aliases:
      result[a.cstring] = lang.path.cstring

const supportedLanguages = parseLanguagesDoc().genLookUp()


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
  let link = baseUrl & supportedLanguages[name]
  await esmImportDefault(link, HljsLanguage)
    .then((lang: HljsLanguage) => hljs.registerLanguage(name, lang))

proc highlighter*(code: cstring, lang: cstring): Future[cstring] {.async.} =
  var language = cstring"plaintext" # default to plaintext
  if lang != cstring"":
    if hljs.getLanguage(lang): # language already registered
      language = lang
    else:
      if lang in supportedLanguages:
        await loadLanguageDynamic(lang)
          .then(() => (language = lang))
          .catch((e: Error) => console.log("failed to dynamically load ", lang, "for highlight.js: ", e.message))
    return hljs.highlight(code, JsObject{language: language}).value

  return code


