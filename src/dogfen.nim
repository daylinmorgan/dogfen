import std/[dom, jsffi, os, strformat, sugar, uri]
import ./[unocss, markedjs, icons, codemirror]

const sourceURL = when defined(release): "https://unpkg.dev/dogfen" else: "index.js"
const oneLiner = fmt"""<!DOCTYPE html><html><body><script src="{sourceUrl}"></script><textarea style="display:none;">"""
const buttonClass = "text-black bg-blue p-2 rounded h-5 flex items-center"

proc addToHead(el: Element) =
  document.getElementsByTagName("head")[0].appendChild(el)

proc setViewPort() =
  var el = document.createElement("meta")
  el.setAttr("name", "viewport")
  el.setAttr("content", "width=device-width, initial-scale=1.0")
  addToHead el

proc addStylesheet(content: string) =
  var style = document.createElement("style")
  style.innerHtml = content
  addToHead style

proc addStylesheetByHref(href: string) =
  var style = document.createElement("link")
  style.setAttribute("rel", "stylesheet")
  style.setAttribute("type", "text/css")
  style.setAttribute("href", href)
  addToHead style

# add some more keyboard shortcuts?
proc handleKeyboardShortcut(e: Event) =
  let keyEvent = KeyboardEvent(e)

  if keyEvent.key == "?" or (keyEvent.keyCode == 191 and keyEvent.shiftKey):
    window.alert("You typed a question mark!")

proc newSaveBtn: Element =
  let fileName =
    parseUri($window.document.URL).path.splitPath().tail
  result = document.createElement("a")
  result.innerHtml = saveIcon
  result.className = buttonClass
  result.setAttr("id", "save-btn")
  result.setAttr("download", fileName.cstring)

# TODO: add dropdown to save button with additional options:
#  - save markdown (with comment header)
#  - save offline doc?
#    - fetch stylesheets and js

proc newEditBtn: Element =
  result = document.createElement("div")
  result.setAttr("id", "edit-btn")
  result.innerHtml = editIcon
  result.className = buttonClass
  result.addEventListener("click",
    (_: Event) => (
      document
        .getElementbyId("editor")
        .classList
        .toggle("hidden")
    ))

proc newHeader(): Element =
  let header = document.createElement("div")
  header.className = "flex flex-row mx-15 items-center gap-5 text-md"

  # TODO: replace with a cooler logo/header
  let h1 = document.createElement("h1")
  h1.innerHTML = "Dogfen"
  h1.className = "text-sm"


  let spacer = document.createElement("div")
  spacer.className = "flex-grow"

  header.appendChild(h1)
  header.appendChild(spacer)
  header.appendChild(newSaveBtn())
  header.appendChild(newEditBtn())

  result = header

proc blobHtml(str: cstring): Blob {.importjs: "new Blob([#], {type: 'text/html'})".}
proc createUrl(blob: Blob): cstring {.importc: "window.URL.createObjectURL".}

proc renderDoc(doc: cstring = "") {.exportc.} =
  document
    .getElementbyId("preview")
    .innerHtml = marked.parse(doc)

  let url = createUrl(blobHtml(cstring(oneLiner & "\n" & $doc)))

  document
    .getElementbyId("save-btn")
    .setAttr("href", url)


proc setupDocument =
  document.body.className = "min-h-85vh flex flex-col bg-gray-100"
  document.body.setAttr("un-cloak", "")

  let container = document.createElement("div")
  container.setAttr("id", "doc")
  container.className =
    "h-full w-full flex flex-col md:flex-row gap-5 justify-center"

  let editor= document.createElement("div")
  editor.setAttr("id", "editor")
  editor.classList.toggle "hidden"
  container.appendChild(editor)

  let textarea = document.querySelector("textarea")
  discard newEditorView(textarea.value, editor) # editor view needs to be attached to "renderDoc"
  textarea.setAttr("id", "inputbox")
  # textarea.style.removeProperty("display")

  let preview = document.createElement("div")
  preview.setAttr("id", "preview")

  textarea.className = "w-1/3 p-4 border-dashed rounded hidden"
  preview.className =
    "min-w-1/2 p-4 border border-2 border-red prose border-solid rounded bg-white"

  document.body.appendChild(preview)
  let footer = document.createElement("div")
  footer.className = "mx-auto text-xs p-5"
  footer.innerHTML = "self-rendering document powered by dogfen"

  container.appendChild(preview)
  let header = newHeader()

  if not textarea.getAttribute("read-only").isNull:
    header.classList.toggle("hidden")
    header.classList.toggle("flex") # flex -> display: flex;

  document.body.appendChild(header)
  document.body.appendChild(container)
  document.body.appendChild(footer)
  textarea.addEventListener(
    "input", (_: Event) => renderDoc()
  )

  # intial render
  renderDoc(textarea.value)

proc domReady(_: Event) =
  setupDocument()

  document.body.addEventListener("keyup", handleKeyboardShortcut)

proc main =
  addStylesheet "[un-cloak]{display: none;}"
  addStylesheetByHref "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/default.min.css"
  addStylesheetByHref "https://unpkg.com/@unocss/reset/normalize.css"
  initUnocss()
  setViewPort()

  echo "doc powered by dogfen: https://github.com/daylinmorgan/dogfen"
  document.addEventListener("DOMContentLoaded", domReady)

main()
