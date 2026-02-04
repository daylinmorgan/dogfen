import std/[dom, os, strutils, sequtils, macros, asyncjs, sugar]
export dom

proc addToHead*(el: Element) =
  document.getElementsByTagName("head")[0].appendChild(el)

proc setViewPort*() =
  var el = document.createElement("meta")
  el.setAttr("name", "viewport")
  el.setAttr("content", "width=device-width, initial-scale=1.0")
  addToHead el


proc addStylesheet*(content: string) =
  var style = document.createElement("style")
  style.innerHtml = content
  addToHead style

proc addStaticStyleSheet*(path: static string) =
  const css = staticRead getProjectPath() / path
  addStyleSheet css

proc addScript*(src: string) =
  var script = document.createElement("script")
  script.setAttr("src", src)
  addToHead script

proc addStylesheetByHref*(href: string) =
  var style = document.createElement("link")
  style.setAttribute("rel", "stylesheet")
  style.setAttribute("type", "text/css")
  style.setAttribute("href", href)
  addToHead style

proc blobHtml*(str: cstring): Blob {.importjs: "new Blob([#], {type: 'text/html'})".}
proc createUrl*(blob: Blob): cstring {.importc: "window.URL.createObjectURL".}
proc revokeObjectUrl*(url: cstring) {.importc: "window.URL.revokeObjectURL".}
proc getFileName*(): string =
  ($window.location.pathname).splitPath().tail

func clone*(e: Element, deep = true): Element =
  Element(Node(e).cloneNode(deep))

proc newElement*(identifier: cstring, id: cstring ="", class: cstring = "", innerHtml: cstring = ""): Element =
  result = document.createElement(identifier)
  if id != "":
    result.id = id
  if class != "":
    result.className = class
  if innerHtml != "":
    result.innerHtml = innerHtml

# NOTE: this only appends children
proc withChildren*(e: Element, children: varargs[Element]): Element =
  result = e
  for c in children:
    result.appendChild(c)

type
  ElementKind* = enum
    H1, Div, Ul, Li, Span, Button, A, Link, Img

proc new*(ek: ElementKind, id: cstring = "", class: cstring = "", innerHtml: cstring = "", textContent: cstring = ""): Element =
  result = document.createElement(($ek).toLowerAscii().cstring)
  if id != "":
    result.id = id
  if class != "":
    result.className = class
  if innerHtml != "":
    result.innerHtml = innerHtml
  if textContent != "":
    result.textContent = textContent

proc withClass*(e: Element, class: cstring): Element =
  result = e
  result.class = class

proc withHtml*(e: Element, innerHtml: cstring): Element =
  result = e
  result.innerHtml = innerHtml

proc withText*(e: Element, text: cstring): Element =
  result = e
  result.textContent = text

proc withText*(e: Element, text: string): Element =
  result = e.withText(cstring(text))

proc withOnClick*(e: Element, p: proc(e: Event)): Element =
  result = e
  result.onClick = p

proc withAttrs*[
  P: (string, cstring) | (string, string)
](e: Element, pairs: openArray[P]): Element =
  result = e
  for (k, v) in pairs:
    result.setAttr(cstring(k), cstring(v))

proc withAttr*(e: Element, k: cstring, v: cstring): Element =
  result = e
  result.setAttr(k,v)

proc withAttr*(e: Element, k: string, v: string): Element =
  result = e
  result.setAttr(cstring(k),  cstring(v))

proc withId*(e: Element, id: cstring | string): Element =
  e.withAttr("id", id)

macro with*(e: Element, body: untyped): untyped =
  ## rename commands/calls on a series lines to a chain of `with{Name}` procs
  ##
  ##  o.with:
  ##    task("thing")
  ##    task3("thing3")
  ## becomes:
  ## task3(task(o, "thing"), "thing3")

  result = e # initialize the result with the original expression (the receiver)
  expectKind body, nnkStmtList
  for node in body:
    # We only care about calls or commands (e.g., class(...) or class ...)
    expectKind node, {nnkCall, nnkCommand}
    let name = node[0].strVal()
    let withName = ident("with" & name.capitalizeAscii())
    # Create a new call: withName(result, args...)
    let newCall = newCall(withName, result)
    for i in 1 ..< node.len:
      newCall.add(node[i])
    # Update result to be this new call to maintain the chain
    result = newCall

proc variant*(prefix: string, css: string): string =
  ## generate css variants with common prefix
  " " & css.splitWhitespace.mapIt(prefix & ":" &  it).join(" ") & " "

proc clipboardWriteText*(n: Navigator, txt: cstring) {.async, importjs: "#.clipboard.writeText(#)"}
proc setHtmlTimeout*(e: Element, innerHtml: cstring, timeout: int = 1000) =
  let current = e.innerHtml
  e.innerHtml = innerHtml
  discard setTimeout(() => ( e.innerHtml = current), timeout)


