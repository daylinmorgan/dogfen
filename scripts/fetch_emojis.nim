{.define:ssl.}
import std/[httpclient, json, os, tables, strutils]

const url = "https://raw.githubusercontent.com/github/gemoji/master/db/emoji.json"
const outFile  = currentSourcePath().parentDir().parentDir() / "src/static/emojis.json"
const htmlFile  = currentSourcePath().parentDir().parentDir() / "site/emojis.html"

type Emoji = object
  emoji: string
  aliases: seq[string]
  category: string

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

proc byCategory(emojis: seq[Emoji]): Table[string, seq[string]] =
  for e in emojis:
    for a in e.aliases:
      result.mgetOrPut(e.category, @[]).add a


func toEmojiCategoryHtml(emojis: seq[string]): string =
  for e in emojis:
    result.add """<span class="rounded hyphens-none inline-block m-1 p-1 shadow group relative hover:shadow-blue cursor-default">"""
    result.add """ <span class="absolute -top-75% left-25% group-not-hover:hidden bg-white z-99 rounded shadow">`""" & e & "`</span>"
    result.add " :" & e & ": "
    result.add "</span>\n"

proc genTables(categories: Table[string, seq[string]]): string =
  for c, emojis in categories.pairs:
    result.add "\n\n## " & c & "\n\n"
    result.add toEmojiCategoryHtml(emojis)

proc genEmojisHtml(emojis: seq[Emoji]): string =
  result.add "<!DOCTYPE html><script type=module src=https://esm.sh/dogfen></script><textarea style=display:none>\n\n"
  result.add "# Dogfen unicode emojis\n"
  result.add getEmojis().byCategory().genTables()

let emojis = getEmojis()

writeFile outFile, $(%* emojis.toMap())

when defined(genHtml):
  writeFile htmlFile, emojis.genEmojisHtml()

