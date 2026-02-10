import std/[uri]
import ./deps/[unocss, markedjs, codemirror, lz_string, dompurify]
import ./lib

const newMd = staticRead("static/new.md")
const sourceUrl = when defined(katex): "https://esm.sh/dogfen/katex" else: "https://esm.sh/dogfen"
let version =  require("../package.json").version.to(cstring)
var newHtml: cstring

type Config = object
  href: string
  raw: cstring
  readOnly: bool
  lang: cstring
  code: cstring
  editor: bool    ## if true editor is open to start
  preview: bool   ## if true preview is open at start
  live: bool

var cfg: Config

proc isCodeMode: bool =
  if cfg.code != nil:
    result = cfg.code != ""

proc loadingAnimation*: Element =
  Div.new().with:
    id "loading"
    class "flex mx-auto"
    attr "un-cloak", ""
    children(
      Div.new().withClass("lds-dual-ring").withChildren(
      Img.new(class = "h-10 inner-logo").withAttr("src", getDataUri(scroll, "image/svg+xml")))
    )

proc toggleEditor() {.exportc.} =
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

proc dogFenLine(scriptTag: string = ("<script type=module src=" & sourceUrl & "></script>")): string =
  # using s.add for large string was causing range error?
  var s = "<!doctype html>" & scriptTag & "<textarea style=display:none"
  if isCodeMode():
    s.add " code=" & cfg.code & ">"
  return s & ">"

proc downloadPageOffline() {.async.} =
  let response = await fetch(cstring"https://unpkg.dev/dogfen")
  let scriptSrc = $(await response.text())
  let fullHtml =
    dogFenLine("\n<script type=module>" & scriptSrc & "</script>\n") & $getCurrentDoc()
  downloadPageAction(fullHtml, getFileName())

proc downloadPage() =
  let fullHtml = dogFenLine() & $getCurrentDoc()
  downloadPageAction(fullHtml, getFileName())

var menuOpen: bool
proc toggle(b: var bool) {.inline.} = b = not b

proc toggleMenu(e: Event) =
  toggle menuOpen
  let btn = document.getElementById("menu-btn")
  btn.innerHtml = cstring(if menuOpen: closeIcon else: menuIcon)
  document.getElementById("menu").classList.toggle "hidden"

proc menuBtn: Element =
  Button.new().with:
    class "btn-small"
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

const shareUrl = when defined(katex): "https://dogfen.dayl.in/katex" else: "https://dogfen.dayl.in"

proc copyShareUrlToClipboard(e: Event) =
  var q = {"raw": ""}.toSeq()
  if isCodeMode(): q &= {"code": $cfg.code}
  var uri = parseUri(shareUrl) ? q
  uri.anchor = $compressToEncodedURIComponent(getCurrentDoc())
  discard navigator.clipboardWriteText(cstring($uri)).then(
    () => e.target.Element.setHtmlTimeout("copied!"),
    (_: Error) => e.target.Element.setHtmlTimeout("copy failed!")
  )

proc copyShareUrlToClipboardReadOnly(e: Event) =
  let shareUrl =
    when defined(katex): "https://dogfen.dayl.in/katex/read-only"
    else: "https://dogfen.dayl.in/read-only"
  var q = {"raw": "true", "read-only": ""}.toSeq()
  if isCodeMode(): q &= {"code": $cfg.code}
  var uri = parseUri(shareUrl) ? q

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


proc togglePreview() =
  document.getElementById("preview").classList.toggle("hidden")

proc menuList: Element =
  # NOTE: Does this even need to be a list?
  var list =
    Ul.new().with:
      class "list-none flex flex-col min-w-60 pl-0"
      children(
        newMenuItem("toggle editor", (_: Event) => toggleEditor()),
        newMenuItem("toggle preview", (_: Event) => togglePreview()),
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
        newMenuItem("share url (read-only)", copyShareUrlToClipboardReadOnly),
        newMenuItem("copy markdown", copyInputBoxToClipboard),
      )

  Div.new().with:
    id "menu"
    class "absolute right-0 hidden text-right bg-gray-100 p-2 shadow-xl rounded-md z-99"
    children list

proc menuElement: Element =
  Div.new().with:
    class "relative inline-block"
    children menuBtn(), menuList()

proc headerPieces: seq[Element] =
  result.add @[
    Img.new(class = "h-8").withAttr("src", getDataUri(scroll, "image/svg+xml")),
    H1.new(class = "text-lg font-black", textContent = "dogfen"),
  ]
  if cfg.live:
    result.add Div.new(class="mx-2 live")
  result.add @[
    Div.new(class = "flex-grow"), # spacer element
    Div.new(class = "flex flex-row gap-5").withChildren(
      editBtnElement(), menuElement()
    )
  ]

proc newHeader(): Element =
  Div.new().with:
    class "flex flex-row mx-5 text-md m-2 items-center"
    children headerPieces()

proc renderDoc(doc: cstring = "") {.async, exportc.} =
  var html = newHtml
  if doc != "":
    let parseMarked =
      if not isCodeMode():
        await(marked.parse(doc))
      else:
        let code = await(highlighter(doc, cfg.code))
        """<pre class="p-5 overflow-auto">""" & code & "</pre>"
    html = sanitize(parseMarked)

  document
    .getElementbyId("preview")
    .innerHtml = html

let previewClasses= @[
  "prose overflow-auto hyphens-auto",
  "font-sans",
  "overflow-auto hyphens-auto",
  "[&_p>code]:shadow",
  "[&_div.markdown-alert]:my-5",
  "[&_div.markdown-alert_p]:m-1",
  variant("prose-table", "table-auto border border-1 border-solid border-collapse"),
  variant("prose-td", "p-2 border border-solid border-1"),
  variant("prose-th", "p-2 border border-solid border-1"),
].join(" ").cstring

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
    case k
    of "href":
      result.href = v
    of "raw":
      # TODO: return an "error" display like with errorFromUri if this doesn't work as expected..
      result.raw = decompressFromEncodedURIComponent(uri.anchor.cstring)
      if result.raw.isNull:
        console.log "raw decrompression resulted in empty string"
    of "read-only":
      result.readOnly = true
    of "lang":
      result.lang = v.cstring
    of "code":
      result.code = v.cstring
    of "editor":
      result.editor = try: parseBool(v) except: false
    of "preview":
      result.preview = try: parseBool(v) except: true
    else:
      console.log "unknown query parameter -> k:", k.cstring,"v:", v.cstring

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
proc promiseWait(): Future[void] {.used,async,importjs: """ new Promise(resolve => setTimeout(resolve, 5000)) """.}

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

var lastValue: cstring

proc maybeReload() {.async.} =
  let txt = await fetch(window.location.href).then((r: Response) => r.text())
  let doc = newDomParser().parseFromString(txt, "text/html");
  let textarea = doc.querySelector("textarea")
  let currentValue = if textarea != nil: textarea.textContent else: "".cstring
  if lastValue != "" and lastValue != currentValue:
    console.log("reloading")
    await renderDoc(currentValue)
  lastValue = currentValue

proc setInterval*(action: proc() {.async.}; ms: int): Interval {.importc, nodecl.}

proc liveReload(intervalStr: cstring) =
  try:
    let interval =
      if intervalStr == "": 2500
      else: int(parseFloat($intervalStr) * 1000)
    console.log("staring live reload (refresh rate:", interval, "ms)")
    cfg.live = true
    discard setInterval(maybeReload, interval)
  except:
    console.error("failed to parse 'live' attibute as float: ", intervalStr)

proc getStartFromTextArea(): cstring =
  let textarea = document.querySelector("textarea")
  if textarea == nil:
    document.body.innerHtml = ""
    return renderError(
      """expected a textarea element... see the [README](https://dogfen.dayl.in) for ways to specify content"""
    )

  if not textarea.getAttribute("read-only").isNull:
    cfg.readOnly = true
  if not textarea.getAttribute("code").isNull:
    cfg.code = textarea.getAttribute("code")
  let lang = textarea.getAttribute("lang")
  if not lang.isNull:
    cfg.lang = lang

  result = textarea.value
  let live = textarea.getAttribute("live")
  if live != nil:
    lastValue = result
    liveReload(live)

proc getStart(cfg: var Config): Future[cstring] {.async.} =
  var start: cstring
  if not cfg.raw.isNull:
    start = cfg.raw
  elif cfg.href != "":
    start = await getFromUri(cfg.href)
  else:
    start = getStartFromTextArea()

  assert not start.isNil # use returns or set a default error string
  result = start

  let textarea = document.querySelector("textarea")
  if textarea != nil:
    textarea.remove()

  await initMarked(start)

# proc handleKeyboardShortcut(e: Event) =
#   let keyEvent = KeyboardEvent(e)
#   if keyEvent.shiftKey and keyEvent.key == "E":
#     toggleEditor()

proc newFooter: Element =
  result =
    Div.new().with:
      class "mx-auto text-xs p-5"
      children(
        text("self-rendering document powered by "),
        A.new(
          class="underline decoration-dotted",
          textContent = "dogfen"
        ).withAttr("href", "https://dogfen.dayl.in"),
        Span.new(class="text-slate-400", textContent = "@" & version)
      )


proc newOpenButtons: Element =
  proc newButton: Element =
    Button.new().with:
      class "btn"

  let editorButton = newButton().withText("open editor").withOnClick((e: Event) => toggleEditor())
  let previewButton = newButton().withText("open preview").withOnClick((e: Event) => togglePreview())

  result =
    Div.new().with:
      class "peer-not-[.hidden]/preview:hidden peer-not-[.hidden]/editor:hidden flex flex-row gap-5"

  if not cfg.readOnly:
    result = result.withChildren(editorButton)

  result = result.withChildren(previewButton)

proc setupDocument() {.async.} =
  newHtml = await marked.parse(newMd)
  cfg = Config.initFromUri()

  document.body.className = "p-0 m-0 flex w-100%"
  document.body.appendChild(loadingAnimation())

  let editorDom =
    Div.new().with:
      id "editor"
      class "peer/editor max-w-95% lg:max-w-45% min-h-50 hidden py-1 border-1 border-dashed rounded lg:mx-0 z-0 w-90%"

  let start = await cfg.getStart()

  cfg.readOnly = cfg.readOnly or defined(readOnly)

  setTitle start

  when not defined(readOnly):
    editor =
      if isCodeMode(): newEditorViewCode(start, editorDom)
      else: newEditorView(start, editorDom)

    if cfg.editor:
      editorDom.classList.toggle("hidden")

  let preview =
    Div.new().with:
      id "preview"
      class "peer/preview shadow-lg rounded-md max-w-98% " & (
        if isCodeMode(): "lg:max-w-90% overflow-auto".cstring
        else: "lg:max-w-65ch p-2 border border-2 border-solid w-65ch lg:min-h-50 " & previewClasses
      )
      attr "lang", cfg.lang

  if cfg.preview:
    preview.classList.toggle("hidden")

  let doc =
    Div.new().with:
      id "doc"
      class "h-full flex flex-col items-center lg:items-start lg:flex-row gap-5 mx-auto lg:justify-center w-full px-2"
      children editorDom, preview, newOpenButtons()

  if cfg.readOnly:
    doc.classList.toggle("mt-5")

  let content = Div.new().with:
    class "min-h-100vh flex flex-col bg-gray-100 w-full"
    attr "un-cloak", ""

  if cfg.readOnly and cfg.live:
    content.appendChild(
      Div.new(class="fixed top-1 left-1 live")
    )
  if not cfg.readOnly:
    content.appendChild(newHeader())
  content.appendChild(doc)
  content.appendChild(newFooter())
  document.body.appendChild(content)

  await renderDoc(start)
  # await?
  initUnocss()
  # BUG: would trigger when codemirror was focused
  # if not cfg.readOnly:
  #   document.body.addEventListener("keydown", handleKeyboardShortcut)

proc setStyles() =
  addStaticStyleSheet "static/styles.css"
  addStaticStyleSheet "static/highlight.min.css"
  when defined(katex):
    addStylesheetByHref "https://cdn.jsdelivr.net/npm/katex@0.16.8/dist/katex.min.css"

  addToHead Link.new()
    .withAttr("rel", "icon")
    .withAttr("href", getDataUri(scroll, "image/svg+xml"))

proc startApp() =
  setViewPort()
  setStyles()
  let readyState {.importjs: "document.readyState".}: cstring
  if readyState == "loading":
    # Still parsing, wait for the event
    document.addEventListener("DOMContentLoaded", (_: Event) => (discard setupDocument()))
  else:
    discard setupDocument() # DOMContentLoaded already fired, just run setup
  echo "doc powered by dogfen: https://github.com/daylinmorgan/dogfen"

startApp()
