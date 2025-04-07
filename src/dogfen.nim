import std/jsffi
import std/dom
import std/strformat
import ./[unocss, markedjs]

const sourceURL = when defined(release): "https://unpkg.dev/dogfen" else: "index.js"
const oneLiner = fmt"""<!DOCTYPE html><html><style>[un-cloak]{{display:none;}}</style><body un-cloak><script src="{sourceUrl}"></script><textarea>"""

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


addStylesheet("[un-cloak]{display: none;}")

addStylesheetByHref("https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/default.min.css")
setViewPort()

proc createObjectURL(URL: JsObject, blob: JsObject): cstring {.importjs: "#.createObjectURL(#)"}

proc onInputChange() =
  let inputbox = document.getElementbyId("inputbox")
  let preview = document.getElementbyId("preview")

  preview.innerHtml = marked.parse(inputbox.value)

  let saveBtn = document.getElementbyId("save-btn")

  let  html {.exportc.}: cstring = oneLiner & "\n" & inputbox.value
  # TODO: no emit
  {.emit:"""const blob = new Blob([html], { type: "text/html" });""" .}

  let blob {.importc.}: JsObject
  let URL {.importc.}: JsObject

  let blobUrl: cstring = URL.createObjectURL(blob)
  saveBtn.setAttr("href", blobUrl)

proc setupHeader(): Element =
  let header = document.createElement("div")
  header.className = "flex flex-row mx-15 items-center gap-5"

  let h1 = document.createElement("h1")
  h1.innerHTML = "Dogfen"

  let saveBtn = document.createElement("a")
  saveBtn.setAttr("id", "save-btn")
  saveBtn.setAttr("download", "dogfen.html")
  saveBtn.innerHtml = "save"
  savebtn.className = "bg-blue px-5 py-2 rounded"
  header.appendChild(h1)
  header.appendChild(saveBtn)
  result = header

proc setupDocument() =
  document.body.className = "min-h-85vh flex flex-col"
  document.body.setAttr("un-cloak", "")

  let container = document.createElement("div")
  container.className =
    "h-full w-full bg-gray-100 flex flex-col md:flex-row gap-5 justify-center"

  let textarea = document.querySelector("textarea")
  textarea.setAttr("id", "inputbox")
  textarea.style.removeProperty("display")

  let preview = document.createElement("div")
  preview.setAttr("id", "preview")

  textarea.className = "w-1/3 p-4 border-dashed rounded"
  preview.className =
    "min-w-1/2 p-4 border border-2 border-red prose border-solid rounded bg-white"

  document.body.appendChild(preview)

  container.appendChild(textarea)
  container.appendChild(preview)
  let header = setupHeader()
  document.body.appendChild(header)
  document.body.appendChild(container)
  initUnocssRuntime(
  RuntimeOptions{defaults: UnocssConfig{presets: @[presetWind3(), presetTypography()]}}
  )
proc domReady(_: Event) =
  setupDocument()
  let inputbox = document.getElementbyId("inputbox")
  let preview = document.getElementbyId("preview")
  preview.innerHtml = marked.parse(inputbox.value)
  inputbox.addEventListener(
    "input",
    proc(_: Event) =
      onInputChange(),
  )

document.addEventListener("DOMContentLoaded", domReady)

echo "doc powered by dogfen: https://github.com/daylinmorgan/dogfen"
