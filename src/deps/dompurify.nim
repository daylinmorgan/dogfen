import ./esm

esm dompurify, DOMPurify

proc sanitize*(html: cstring): cstring {.importjs: "DOMPurify.sanitize(#)".}


