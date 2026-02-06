import std/[strutils, sequtils, jsconsole, sugar, jsffi, asyncjs, jsfetch]
export strutils, sequtils, jsconsole, sugar, jsffi, asyncjs, jsfetch

import ./lib/[html, icons, esm]

proc jsonParse*(s: cstring): JsObject {.importjs: "JSON.parse(#)"}

export html, icons, esm


