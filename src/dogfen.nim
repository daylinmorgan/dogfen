import std/[dom, jsffi, strformat, sugar]
import std/[jsfetch, asyncjs]
import ./deps/[unocss, markedjs, codemirror]
import ./lib/[html, icons]


const
  sourceURL =
    when defined(release): "https://unpkg.dev/dogfen" else: "index.js"
  oneLiner =
    fmt"""<!DOCTYPE html><html><body><script src="{sourceUrl}"></script><textarea style="display:none;">"""
  buttonClass* =
    "flex items-center justify-center w-10 h-10 bg-blue-400 rounded-md hover:bg-blue-500 transition-colors border-none cursor-pointer"

proc loadingElement*: Element =
  Div.new().with:
    class "flex mx-auto lds-dual-ring"

proc toggleEditor(_: Event) =
  document
    .getElementbyId("editor")
    .classList
    .toggle("hidden")

proc editBtnElement*: Element =
  Button.new().with:
    id "edit-btn"
    class buttonClass
    attr "type", "button"
    html editIcon
    onClick toggleEditor

proc getCurrentDoc(): cstring =
  document.getElementById("inputbox").textContent

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

proc saveOfflineMenuItem: Element =
  Span.new().with:
    text "save document (offline)"
    onClick proc(e: Event) =
      e.currentTarget.Element.setHtmlTimeout("saving")
      discard downloadPageOffline()

proc saveMenuItem: Element =
  Span.new().with:
    text "save document"
    onClick proc(e: Event) =
      e.currentTarget.Element.setHtmlTimeout("saving")
      downloadPage()

proc copyInputBoxToClipboard(e: Event) =
  let doc = getCurrentDoc()
  discard navigator.clipboardWriteText(doc).then(
    () => (document.getElementById("clipboard-select").setHtmlTimeout("copied!")),
    (_: Error) => (document.getElementById("clipboard-select").setHtmlTimeout("copy failed")),
  )

proc copyToClipboard: Element =
  Span.new.with:
    id "clipboard-select"
    text "copy to clipboard"
    onClick copyInputBoxToClipboard

proc menuList: Element =
  let list =
    Ul.new().with:
      class "list-none flex flex-col min-w-60 pl-0"
  for i in [saveMenuItem(), saveOfflineMenuItem(), copyToClipboard()]:
    let li = Li.new().with:
        class("py-2 px-1 border-blue border-1 border-solid cursor-pointer hover:bg-gray-300")
        children i
    list.appendChild li

  Div.new().with:
    id "menu"
    class "absolute right-0 hidden text-right bg-gray-100 px-5 shadow-xl"
    children list

proc menuElement: Element =
  Div.new().with:
    class "relative inline-block"
    children menuBtn(), menuList()

proc newHeader(): Element =
  Div.new().with:
    class "flex flex-row mx-15 items-center gap-5 text-md mb-1"
    children(
      H1.new(class = "text-sm", textContent = "Dogfen"),
      Div.new(class = "flex-grow"), # spacer element
      editBtnElement(),
      menuElement()
    )

proc renderDoc(doc: cstring = "") {.exportc.} =
  document
    .getElementbyId("preview")
    .innerHtml = marked.parse(doc)

let proseClasses = (
  "prose " &
  variant("prose-table", "table-auto border border-1 border-solid border-collapse") &
  variant("prose-td", "p-2 border border-solid border-1") &
  variant("prose-th", "p-2 border border-solid border-1")
)

proc setupDocument =
  document.body.className = "min-h-85vh flex flex-col bg-gray-100"

  let editor =
    Div.new().with:
      id "editor"
      class "w-40% hidden p-4 border-1 border-dashed rounded hidden"

  let textarea = document.querySelector("textarea").withId("inputbox")
  discard newEditorView(textarea.value, editor) # editor view needs to be attached to "renderDoc"

  let preview =
    Div.new().with:
      id "preview"
      # Add shadow?
      class "min-w-1/2 p-4 border border-2 border-solid rounded bg-white " & proseClasses

  let container =
    Div.new().with:
      id "doc"
      class "h-full w-full flex flex-col md:flex-row gap-5 justify-center"
      children editor, preview

  let footer =
    Div.new().with:
      class "mx-auto text-xs p-5"
      text "self-rendering document powered by dogfen"

  let header = newHeader()

  if not textarea.getAttribute("read-only").isNull:
    header.classList.toggle("hidden")
    header.classList.toggle("flex")

  document.body.appendChild(header)
  document.body.appendChild(container)
  document.body.appendChild(footer)

  # TODO: implement some useful actions as keyboard shortcuts?
  # document.body.addEventListener("keyup", handleKeyboardShortcut)

  # intial render
  renderDoc(textarea.value)
  document.body.setAttr("un-cloak", "")

proc domReady(_: Event) =
  setupDocument()

proc setStyles() =
  addStylesheet "[un-cloak]{display: none;}"
  addStaticStyleSheet "static/normalize.css"
  addStaticStyleSheet "static/highlight.min.css"
  addStaticStyleSheet "static/styles.css"
  initUnocss()

proc startApp() =
  setStyles()
  setViewPort()
  let documentReadyState {.importc: "document.readyState"}: cstring
  if documentReadyState == "loading":
    # Still parsing, wait for the event
    document.addEventListener("DOMContentLoaded", domReady)
  else:
    setupDocument() # DOMContentLoaded already fired, just run setup
  echo "doc powered by dogfen: https://github.com/daylinmorgan/dogfen"

startApp() 
