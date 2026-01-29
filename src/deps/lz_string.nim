import ./esm

proc compressToEncodedURIComponent*(s: cstring): cstring {.esm: "lz-string", importc.}
proc decompressFromEncodedURIComponent*(s: cstring): cstring  {.esm: "lz-string", importc.}

