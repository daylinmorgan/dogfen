import std/[strformat]

proc tryExec(cmd: string) =
  echo "cmd: " & cmd
  let (output, code) = gorgeEx cmd
  if code != 0 or defined(verbose):
    echo output
  if code != 0:
    quit 1

proc build(flags: string = "", bundle: string = "") =
  tryExec fmt"nim js -d:release {flags} src/dogfen.nim"
  tryExec "bun run bundle" & (if bundle != "": ":" & bundle else: "")

task build, "build app":
  const flags {.strdefine.} = ""
  exec fmt"nim js {flags} src/dogfen.nim"

task watch, "watch src and run build":
  exec "watchexec -w src -- nim build"

task buildAll, "build all versions":
  build()
  build(bundle = "min")
  build("-d:readOnly", "read")
  build("-d:katex", "katex")
  build("-d:katex -d:readOnly", "katex-read")


# begin Nimble config (version 2)
when withDir(thisDir(), system.fileExists("nimble.paths")):
  include "nimble.paths"
# end Nimble config
