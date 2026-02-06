# dogfen

## usage

Add the below oneliner to an existing markdown document:

```html
<!doctype html><script type=module src=https://esm.sh/dogfen></script><textarea style=display:none>

# Header 1

## Header 2

|col 1 | col 2 |
|---|---|
|cell 1 | cell 2 |
```

or start writing a [new](https://dogfen.dayl.in/new) one!

See a [demo](https://dogfen.dayl.in/demo) of (some) of the supported syntax.

## Specifying Content

### local file

As shown above to render a document you should prepend it with the following line, taking care to ensure the content is in the `<textarea>` and open in a browser:

```html
<!doctype html><script type=module src=https://esm.sh/dogfen></script><textarea style=display:none>
```

If you want to modify the content using a different editor but still preview in your browser add the `live` attribute to the `<textarea>` (optionally, you can provide a value for the attribute in seconds to set the polling rate, by default it's 2.5s):

```html
<!doctype html><script type=module src=https://esm.sh/dogfen></script><textarea style=display:none live read-only>
```

### fetch from href

Use a query parameter to set the content with the raw text data fetched from a url:

Example: <https://dogfen.dayl.in/read-only?href=https://raw.githubusercontent.com/daylinmorgan/dogfen/refs/heads/main/README.md>

> [!Note]
> This base url (<https://dogfen.dayl.in/read-only>) loads a lighter bundle (without codemirror), you could also specifying this with a query parameter (`?read-only`)


### shareable url

It's also possible to generate shareable urls:

Example: <https://dogfen.dayl.in?raw#BYUwNmD2AEDukCcwBMg>

> [!NOTE]
> This has the typical caveats of embedding data in a url, i.e. for big documents host the data at a public link and use `?href=`

### code

If you wish to share a code snippet rather than markdown you may use the `code={lang}` attribute or query parameter to treat the entire document as a code snippet

Example: <https://dogfen.dayl.in/read-only?code=nim&href=https://raw.githubusercontent.com/daylinmorgan/dogfen/refs/heads/main/src/dogfen.nim>

## alternative versions

### katex

If you need support for katex rendering append `/katex` to the src url to get a bundle with katex

### read-only

If you are using read-only mode and won't need the editor append `/read-only` (or `/katex/read-only`) to the src url to get a bundle without codemirror

## converter

You could define a shell helper function to quickly convert a markdown doc to a dogfen doc.

```sh
dogfen() {
  echo '<!doctype html><script type=module src=https://esm.sh/dogfen></script><textarea style=display:none>'
  [ -z "$1"] && cat "$1"
}
```

```sh
dogfen README.md > README.dogfen.html
```

## related projects

- [texme](https://github.com/susam/texme)
- [zeromd](https://github.com/zerodevx/zero-md)
