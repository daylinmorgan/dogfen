{.emit:"""import {
  compressToEncodedURIComponent,
  decompressFromEncodedURIComponent,
} from 'lz-string';"""
.}

proc compressToEncodedURIComponent*(s: cstring): cstring {.importc.}
proc decompressFromEncodedURIComponent*(s: cstring): cstring  {.importc.}



