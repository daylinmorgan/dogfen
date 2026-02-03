import std/[dom, jsffi, strformat, sugar, uri, jsfetch, asyncjs, strutils, jsconsole]
import ./deps/[unocss, markedjs, codemirror, lz_string, dompurify]
import ./lib/[html, icons]

const
  sourceURL =
    when defined(release): "https://unpkg.dev/dogfen" else: "index.js"
  oneLiner =
    fmt"""<!DOCTYPE html><html><body><script src="{sourceUrl}"></script><textarea style="display:none;">"""
  buttonClass* =
    "flex items-center justify-center w-10 h-10 bg-blue-400 rounded-md hover:bg-blue-500 transition-colors border-none cursor-pointer"
  newMd = staticRead("static/new.md")

var newHtml : cstring


proc loadingAnimation*: Element =
  Div.new().with:
    id "loading"
    class "flex mx-auto"
    attr "un-cloak", ""
    children Div.new().withClass "lds-dual-ring"

proc toggleEditor() {.exportc} =
  document
    .getElementbyId("editor")
    .classList
    .toggle("hidden")

proc editBtnElement*: Element =
  Button.new().with:
    id "edit-btn"
    class "btn-small"
    attr "type", "button"
    html editIcon
    onClick (e: Event) => toggleEditor()

proc getCurrentDoc(): cstring =
  editor.state.doc.toString()

proc downloadPageAction(html: string, filename: string) =
  let blob = blobHtml(cstring(html))
  let url = createUrl(blob)
  let link = A.new().withAttrs({
      "href": $url,
      "download": filename
    })

  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
  revokeObjectURL(url)

proc downloadPageOffline() {.async.} =
  let response = await fetch(cstring"https://unpkg.dev/dogfen")
  let scriptSrc = await response.text()
  let fullHtml = "<!DOCTYPE html><html><body>" & "\n<script>" & $scriptSrc & "</script>\n" &
    """<textarea style="display:none;">""" &  $getcurrentDoc()
  downloadPageAction(fullHtml, getFileName())

proc downloadPage() =
  let fullHtml = oneLiner & $getCurrentDoc()
  downloadPageAction(fullHtml, getFileName())

var menuOpen: bool
proc toggle(b: var bool) {.inline.} = b = not b

proc toggleMenu(_: Event) =
  toggle menuOpen
  let btn = document.getElementById("menu-btn")
  btn.innerHtml = cstring(if menuOpen: closeIcon else: menuIcon)
  document.getElementById("menu").classList.toggle "hidden"

proc menuBtn: Element =
  Button.new().with:
    class buttonClass
    html menuIcon
    id "menu-btn"
    attr "type", "button"
    onClick: toggleMenu

proc copyInputBoxToClipboard(e: Event) =
  let doc = getCurrentDoc()
  discard navigator.clipboardWriteText(doc).then(
    () => (e.target.Element.setHtmlTimeout("copied!")),
    (_: Error) => (e.target.Element.setHtmlTimeout("copy failed!")),
  )

proc copyShareUrlToClipboard(e: Event) =
  var uri = parseUri("https://dogfen.dayl.in") ? {"raw": "true"}
  uri.anchor = $compressToEncodedURIComponent(getCurrentDoc())
  discard navigator.clipboardWriteText(cstring($uri)).then(
    () => e.target.Element.setHtmlTimeout("copied!"),
    (_: Error) => e.target.Element.setHtmlTimeout("copy failed!")
  )

proc newMenuItem(text: cstring, onClick: proc(e: Event)): Element =
  let inner = Div.new().with:
    class("py-2 px-1 cursor-pointer hover:bg-gray-300 rounded")
    text text
    onClick onClick
  result = Li.new().withChildren(inner)

# proc appendChildren(e: Element, sons: varargs[Element]) =
#   for s in sons:
#     e.appendChild(s)

proc divider: Element =
  Div.new().withClass("border b-1 border-solid")

proc menuList: Element =
  # NOTE: Does this even need to be a list?
  var list =
    Ul.new().with:
      class "list-none flex flex-col min-w-60 pl-0"
      children: @[
        newMenuItem("toggle editor", (_: Event) => toggleEditor()),
        newMenuItem("toggle preview", (_: Event) => (document.getElementById("preview").classList.toggle("hidden"))),
        divider(),
        newMenuItem("save document", proc(e: Event) =
          e.currentTarget.Element.setHtmlTimeout("saving")
          downloadPage()
        ),
        newMenuItem("save document (offline)", proc(e: Event) =
          e.currentTarget.Element.setHtmlTimeout("saving")
          discard downloadPageOffline()
        ),
        divider(),
        newMenuItem("share url", copyShareUrlToClipboard),
        newMenuItem("copy markdown", copyInputBoxToClipboard),
      ]

  Div.new().with:
    id "menu"
    class "absolute right-0 hidden text-right bg-gray-100 px-5 shadow-xl rounded-md z-99"
    children list

proc menuElement: Element =
  Div.new().with:
    class "relative inline-block"
    children menuBtn(), menuList()

proc newHeader(): Element =
  Div.new().with:
    class "flex flex-row mx-5 gap-5 text-md mb-1 items-center"
    children(
      H1.new(class = "text-lg font-black", textContent = "dogfen"),
      Div.new(class = "flex-grow"), # spacer element
      editBtnElement(),
      menuElement()
    )


proc renderDoc(doc: cstring = "") {.async, exportc.} =
  var html = newHtml
  if doc != "":
    let parseMarked = await(marked.parse(doc))
    html = sanitize(parseMarked)

  document
    .getElementbyId("preview")
    .innerHtml = html

let proseClasses = (
  "prose overflow-auto hyphens-auto " &
  variant("prose-table", "table-auto border border-1 border-solid border-collapse") &
  variant("prose-td", "p-2 border border-solid border-1") &
  variant("prose-th", "p-2 border border-solid border-1")
)


type Config = object
  href: string
  raw: cstring
  readOnly: bool
  lang: cstring
  code: cstring

proc renderError(msg: string): cstring =
  const pre = """<span class="bg-red block text-5xl text-black"> DOGFEN ERROR </span>"""
  cstring(pre & msg)

proc errorFromUri(uri: string, e: Error): cstring =
  renderError(
    "failed to fetch data from: " &
    "[" & uri & "]" & "(" & uri &  ")\\" &
    "\nsee below for error:\n\n" &
    """<div class="b-3 b-solid b-red p-5">""" & $e.message & "</div>"
  )


proc initFromUri(_: typedesc[Config]): Config =
  let uri = parseUri($window.location.href)
  for k, v in uri.query.decodeQuery():
    if k == "href":
      result.href = v
    elif k == "raw":
      # TODO: return an "error" display like with errorFromUri if this doesn't work as expected..
      result.raw = decompressFromEncodedURIComponent(uri.anchor.cstring)
      if result.raw.isNull:
        console.log "raw decrompression resulted in empty string"
    elif k == "read-only":
      result.readOnly = true
    elif k == "lang":
      result.lang = v.cstring
    elif k == "code":
      result.code = v.cstring

  if result.lang.isNull:
    result.lang = "en"

proc getFromUri(uri: string): Future[cstring] {.async.} =
  var cs = "".cstring
  await fetch(uri.cstring)
    .then((r: Response) => r.text())
    .then((t: cstring) => (cs = t))
    .catch((e: Error) => (cs = errorFromUri(uri, e)))
  result = cs

# a debug func to test network latency
# proc promiseWait(): Future[void] {.async,importjs: """ new Promise(resolve => setTimeout(resolve, 5000)) """.}

# proc domReady() =
#   dogfenDomReady = true
#   document.dispatchEvent(newEvent"dogfenDomReady")

proc extractTitle(doc: cstring): string =
  for l in ($doc).splitLines():
    # pick the first header-like thing
    # BUG: in code samples this makes the header a comment
    if l.strip().startsWith("#"):
      return l.replace("#","").strip()

proc setTitle(start: cstring) =
  var parts: seq[string] = @["dogfen"]
  parts.add getFileName().replace(".html")
  if not start.isNull:
    parts.add extractTitle(start)
  else:
    document.title = "dogfen"
  # use raw mode info here somehow?
  document.title = cstring(parts.join(" - "))

proc getStart(cfg: var Config): Future[cstring] {.async.} =
  let textarea = document.querySelector("textarea").withId("inputbox")

  # what to do if a textarea doesn't exist.. is that an error?
  var start: cstring
  if not cfg.raw.isNull:
    start = cfg.raw
  elif cfg.href != "":
    start = await getFromUri(cfg.href)
  else:
    if not textarea.getAttribute("read-only").isNull:
      cfg.readOnly = true
    if not textarea.getAttribute("code").isNull:
      cfg.code = textarea.getAttribute("code")
    let lang = textarea.getAttribute("lang")
    if not lang.isNull:
      cfg.lang = lang
    start = textarea.value

  # TODO: make syntax highlight mode more sophisticated
  if not cfg.code.isNull:
    start = "```" & cfg.code & "\n" & start & "\n```"

  assert not start.isNil # use returns or set a default error string
  result = start

# proc handleKeyboardShortcut(e: Event) =
#   let keyEvent = KeyboardEvent(e)
#   if keyEvent.shiftKey and keyEvent.key == "E":
#     toggleEditor()

proc setupDocument() {.async.} =
  newHtml = await marked.parse(newMd)
  var cfg = Config.initFromUri()

  document.body.className = "p-0 m-0 flex w-100%"
  document.body.appendChild(loadingAnimation())

  let editorDom =
    Div.new().with:
      id "editor"
      class "max-w-95% lg:max-w-45% min-h-50 hidden py-1 border-1 border-dashed rounded lg:mx-0 z-0 w-90%"

  let start = await cfg.getStart()

  cfg.readOnly = cfg.readOnly or defined(readOnly)

  setTitle start

  when not defined(readOnly):
    editor = newEditorView(start, editorDom)

  let preview =
    Div.new().with:
      id "preview"
      class "lg:max-w-65ch max-w-90% p-2 border border-2 border-solid rounded shadow-lg w-65ch lg:min-h-50 lg:min-w-40% " & proseClasses
      attr "lang", cfg.lang

  let doc=
    Div.new().with:
      id "doc"
      class "h-full flex flex-col items-center lg:items-start lg:flex-row gap-5 mx-auto lg:justify-center w-full px-2"
      children editorDom, preview

  let footer =
    Div.new().with:
      class "mx-auto text-xs p-5"
      html """self-rendering document powered by <a class="underline decoration-dotted" href=https://dogfen.dayl.in>dogfen</a>"""

  let header = newHeader()

  if cfg.readOnly:
    header.classList.toggle("hidden")
    header.classList.toggle("flex")
    doc.classList.toggle("mt-5")

  let content = Div.new().with:
    class "min-h-100vh flex flex-col bg-gray-100 w-full"
    attr "un-cloak", ""
    children header, doc, footer

  document.body.appendChild(content)

  await renderDoc(start)

  # BUG: would trigger when codemirror was focused
  # if not cfg.readOnly:
  #   document.body.addEventListener("keydown", handleKeyboardShortcut)

proc setStyles() =
  addStaticStyleSheet "static/styles.css"
  addStaticStyleSheet "static/normalize.css"
  addStaticStyleSheet "static/highlight.min.css"
  addToHead Link.new()
    .withAttr("rel", "icon")
    .withAttr("href", getDataUri(favicon, "image/svg+xml"))
  initUnocss()

proc startApp() =
  setViewPort()
  setStyles()
  let readyState {.importjs: "document.readyState"}: cstring
  if readyState == "loading":
    # Still parsing, wait for the event
    document.addEventListener("DOMContentLoaded", (_: Event) => (discard setupDocument()))
  else:
    discard setupDocument() # DOMContentLoaded already fired, just run setup
  echo "doc powered by dogfen: https://github.com/daylinmorgan/dogfen"


startApp()
