import std/jsffi

type
  UnocssTransformer = ref object
  UnocssPreset = ref object
  UnocssConfig* = ref object
    presets*: seq[UnocssPreset]
    transformers: seq[UnocssTransformer]
  RuntimeOptions* = ref object
    defaults*: UnocssConfig
  TypographyOptions = ref object
    colorScheme: JsObject
    cssExtend: JsObject

{.
  emit:
    """
import initUnocssRuntime from "@unocss/runtime";
import presetWind3 from "@unocss/preset-wind3";
import presetTypography from "@unocss/preset-typography";
"""
.}

proc initUnocssRuntime*(options: RuntimeOptions) {.importc.}
proc presetWind3*(): UnocssPreset {.importc.}
proc presetTypography*(o: TypographyOptions): UnocssPreset {.importc.}

let typoOpts =
  TypographyOptions(
    cssExtend: js{
      "hr": js{
        "height": cstring"1px",
        "background": cstring"black"
      },
    }
  )

proc initUnocss* =
  initUnocssRuntime(
    RuntimeOptions{
      defaults: UnocssConfig{
        presets: @[
          presetWind3(),
          presetTypography(typoOpts)
        ],
      }
    }
  )
