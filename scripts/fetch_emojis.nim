{.define:ssl.}
import std/[httpclient, json, os, tables]

const url = "https://raw.githubusercontent.com/github/gemoji/master/db/emoji.json"
const outFile  = currentSourcePath().parentDir().parentDir() / "src/static/emojis.json"

type Emoji = object
  emoji: string
  aliases: seq[string]

proc getEmojis(): seq[Emoji] =
  var client = newHttpClient()
  var response: string
  try:
    response = client.getContent(url)
  finally:
    client.close()
  parseJson(response).to(seq[Emoji])

proc toMap(emojis: seq[Emoji]): Table[string, string] =
  for e in emojis:
    for a in e.aliases:
      result[a] = e.emoji

writeFile outFile,$(%* getEmojis().toMap())

