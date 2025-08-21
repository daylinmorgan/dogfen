task watch, "watch src and run build":
  exec "watchexec -w src -- nim build"

task build, "build app":
  when not defined(release):
    selfExec "js src/dogfen.nim"
    exec "bun run bundle"
  else:
    selfExec "js -d:release src/dogfen.nim"
    exec "bun run bundle:prod"


# begin Nimble config (version 2)
when withDir(thisDir(), system.fileExists("nimble.paths")):
  include "nimble.paths"
# end Nimble config
