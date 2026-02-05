import ../lib

type
  UnocssTransformer = ref object
  UnocssPreset = ref object
  UnocssConfig* = ref object
    safelist: seq[cstring]
    presets*: seq[UnocssPreset]
    transformers: seq[UnocssTransformer]
    shortcuts: JsObject
  UnocssRuntime = ref object
  RuntimeOptions* = ref object
    defaults*: UnocssConfig
    ready*: proc(r: UnocssRuntime): bool
    shortcuts: JsObject
  TypographyOptions = ref object
    colorScheme: JsObject
    cssExtend: JsObject
  IconOptions = ref object
    cdn: cstring
    extraProperties: JsObject

proc initUnocssRuntime*(options: RuntimeOptions) {.esm: "default:@unocss/runtime", importc.}
proc presetWind4*(options: JsObject): UnocssPreset {.esm: "@unocss/preset-wind4", importc.}
proc presetTypography*(o: TypographyOptions): UnocssPreset {.esm: "@unocss/preset-typography", importc.}
proc presetIcons*(options: IconOptions): UnocssPreset {.esm: "@unocss/preset-icons", importc.}

let typoOpts =
  TypographyOptions(
    cssExtend: js{
      "hr": js{
        "height": cstring"1px",
        "border-color": cstring"black",
      },
    }
  )

proc initUnocss* =
  initUnocssRuntime(
    RuntimeOptions{
      defaults: UnocssConfig{
        presets: @[
          presetWind4(js{preflights: js{reset: true}}),
          presetTypography(typoOpts),
          presetIcons(IconOptions(
            cdn: "https://esm.sh/",
            extraProperties: js{
                "display": "inline-block".cstring,
                "vertical-align": "middle".cstring,

              }
          ))
        ],
        shortcuts: js{
          "live": "h-3 w-3 rounded-full bg-red-600 animate-pulse".cstring,
          "btn": "flex items-center justify-center p-1 bg-blue-400 rounded-md hover:bg-blue-500 transition-colors border-none cursor-pointer text-black".cstring,
          "btn-small": "btn w-10 h-10".cstring,
          # handle at the renderer level?
          "markdown-alert": "!border-l-2 pl-2".cstring,
          "markdown-alert-note": "b-[#1f6feb]".cstring,
          "markdown-alert-tip": "b-[#238636]".cstring,
          "markdown-alert-important": "b-[#8957e5]".cstring,
          "markdown-alert-warning": "b-[#9e6a03]".cstring,
          "markdown-alert-caution": "b-[#da3633]".cstring,
        },
      },
    }
  )
