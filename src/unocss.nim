import std/jsffi

type
  UnocssConfig* = ref object
    presets*: seq[JsObject]
  RuntimeOptions* = ref object
    defaults*: UnocssConfig

{.emit: """
const initUnocssRuntime = require("@unocss/runtime").default;
const presetWind3 = require("@unocss/preset-wind3").default;
const presetTypography = require("@unocss/preset-typography").default;
"""
.}

proc initUnocssRuntime*(options: RuntimeOptions) {.importc.}
proc presetWind3*(): JsObject {.importc.}
proc presetTypography*(): JsObject {.importc.}

