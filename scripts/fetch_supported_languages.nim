{.define: ssl}
import std/[tables, json, strutils, httpclient, sequtils, os, sugar, tables, httpclient]


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

proc setEsmLink(l: var Lang, s: string)=
  if s != "":
    assert s.contains("https://github.com")
    let ss = s.split("https://github.com/")
    l.path = ss[1].strip().replace(")", "")

proc init(T: typedesc[Lang], row: string): T =
  let s = row.strip().split("|").mapIt(it.strip())
  assert s.len >= 4, "expected at least 4 items\nrow: " & row & "\nsplit: " & $s # this table needs a good linting
  result.name = s[1]
  result.aliases = s[2].split(",").mapIt(it.strip()).filterIt(it != "")
  if result.name notin notSupported:
    result.setEsmLink(s[3])

proc fetchSupportedLanguagesMd(): string =
  let client = newHttpClient()
  try:
    result = client.getContent("https://raw.githubusercontent.com/highlightjs/highlight.js/refs/heads/main/SUPPORTED_LANGUAGES.md")
  finally:
    client.close()

proc fetchOfficialList(): string =
  let client = newHttpClient()
  # TODO: header using  getEnv(GITHUB_TOKEN)
  try:
    result = client.getContent("https://api.github.com/repos/highlightjs/highlight.js/contents/src/languages")
  finally:
    client.close()

type
  RepoContent = object
    `type`: string
    name: string
    path: string

proc getSupportedLanguagesRows(): seq[string] =
  let lines = fetchSupportedLanguagesMd().splitLines()
  let begin = lines.find("<!-- LANGLIST -->")
  let ending = lines.find("<!-- LANGLIST_END -->")
  assert begin != 0
  assert ending != 0
  lines[begin+3..<ending]

proc pathToName(p:  string): string =
  p.replace("src/languages/", "").replace(".js", "")

proc getOfficialList(): seq[string] =
  let res = fetchOfficialList()
  let contents  = parseJson(res).to(seq[RepoContent])
  for c in contents:
    result.add pathToName(c.path)

func parseRows(rows: seq[string]): seq[Lang] =
  for row in rows:
    let lang = Lang.init(row)
    if lang.name notin notSupported:
      result.add lang



type
  SupportedLanguages = object
    paths: Table[string, string] # name -> esm.sh/{path}
    names: Table[string, string] # alias -> name

iterator without(a: openArray[string], s: string): string =
  for item in a:
    if item != s:
      yield item

let officialNames = getOfficialList()

proc toOfficialName(l: Lang): string =
  case l.name
  of "STEP Part 21": return "step21"
  else:
    for s in officialNames:
      if l.name.toLowerAscii() == s: return s
      for a in l.aliases:
        if a == s: return s

  assert false, "failed to convert " & $l & " to official langugage"

const overwrites = {
    "bicep": "Azure/bicep/src/highlightjs/dist/bicep.min.js",
    "svelte": "highlight.svelte",
    "motoko": "gh/rvanasa/highlightjs-motoko/dist/motoko.es.min.js",
    "candid": "gh/rvanasa/highlightjs-motoko/dist/candid.es.min.js",
  }

proc postHook(l: var SupportedLanguages) = 
  for (name, path) in overwrites:
    l.paths[name] = path

  l.names["ml"] = "ocaml" # prefer ocaml over SML

proc init(T: typedesc[SupportedLanguages], langs: seq[Lang]): T =
  for l in langs:
    let name =
      if l.path == "": l.toOfficialName()
      elif l.aliases.len == 0: l.name
      else: l.aliases[0]
    result.paths[name] = if l.path == "": officialPath & name else: "gh/" & l.path
    if l.name.toLowerAscii() != name:
      result.names[l.name.toLowerAscii()] = name
    for a in l.aliases.without(name):
      result.names[a] = name
  result.names["ml"] = "ocaml" # prefer ocaml over SML
  postHook result

let sl = SupportedLanguages.init(getSupportedLanguagesRows().parseRows())

const outFile  = currentSourcePath().parentDir().parentDir() / "src/static/supportedLanguages.json"

writeFile outFile, $(%* sl)

