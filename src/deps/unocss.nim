import std/[jsffi]
import ./esm

type
  UnocssTransformer = ref object
  UnocssPreset = ref object
  UnocssConfig* = ref object
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

proc initUnocssRuntime*(options: RuntimeOptions) {.esm: "default:@unocss/runtime", importc.}
proc presetWind4*(): UnocssPreset {.esm: "@unocss/preset-wind4", importc.}
proc presetTypography*(o: TypographyOptions): UnocssPreset {.esm: "@unocss/preset-typography", importc.}


#[
proc extractAll(r: UnocssRuntime) {.importcpp.}
proc update(r: UnocssRuntime) {.importcpp.}

proc startUnocss(r: UnocssRuntime) =
    r.extractAll()
    r.update()

var dogfenDomReady* = false

# # BUG: this wasnt actually observing the content and I don't know that it's necessary.
# proc ready(r: UnocssRuntime): bool =
#   result = false
#   if not dogfenDomReady:
#     document.addEventListener("dogfenDomReady", (_: Event) => (r.startUnocss(); document.addEventListener("DOMContentLoaded", (_: Event) => r.startUnocss())))
#   else:
#     r.startUnocss()
#     document.addEventListener("DOMContentLoaded", (_: Event) => r.startUnocss())
]#

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
          presetWind4(),
          presetTypography(typoOpts)
        ],
        shortcuts: js{
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
      # manually trigger first extraction since we update the dom after initial load
#      ready: ready
    }
  )
