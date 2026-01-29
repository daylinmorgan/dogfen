import std/[jsffi, sugar, dom]
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
proc presetWind4*(): UnocssPreset {.esm: unocss, importc.}
proc presetTypography*(o: TypographyOptions): UnocssPreset {.esm: unocss, importc.}

proc extractAll(r: UnocssRuntime) {.importcpp.}
proc update(r: UnocssRuntime) {.importcpp.}
proc startUnocss(r: UnocssRuntime) =
    r.extractAll()
    r.update()

var dogfenDomReady* = false

proc ready(r: UnocssRuntime): bool =
  result = false
  if not dogfenDomReady:
    document.addEventListener("dogfenDomReady", (_: Event) => r.startUnocss())
  else:
    r.startUnocss()

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
        },
      },
      # manually trigger first extraction since we update the dom after initial load
      ready: ready
    }
  )
