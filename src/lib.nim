import std/[strutils, sequtils, jsconsole, sugar, jsffi, asyncjs]
export strutils, sequtils, jsconsole, sugar, jsffi, asyncjs

import ./lib/[html, icons, esm]

proc jsonParse*(s: cstring): JsObject {.importjs: "JSON.parse(#)"}

export html, icons, esm


