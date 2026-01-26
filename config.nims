task watch, "watch src and run build":
  exec "watchexec -w src -- nim build"

task build, "build app":
  when defined(release) or defined(minify):
    selfExec "js -d:release src/dogfen.nim"
  else:
    selfExec "js src/dogfen.nim"

  when not defined(minify):
    exec "bun run bundle"
  else:
    exec "bun run bundle:min"


# begin Nimble config (version 2)
when withDir(thisDir(), system.fileExists("nimble.paths")):
  include "nimble.paths"
# end Nimble config
