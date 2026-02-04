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

## fetch from a url

Use a query parameter to override any existing textarea with raw text data fetched from a url:

Example: <https://dogfen.dayl.in/?read-only&href=https://raw.githubusercontent.com/daylinmorgan/dogfen/refs/heads/main/README.md>

Note: this link also includes the `read-only` query parameter.

## shareable url

It's also possible to generate shareable urls:

Example: <https://dogfen.dayl.in?raw#BYUwNmD2AEDukCcwBMg>

Note: this has the typical caveats of embedding data in a url, i.e. for big documents host the data at a public link and use `?href=`

## alternative versions

### katex

If you need support for katex rendering append `/katex` to the src url to get a bundle with katex

### readonly

If you are using read-only mode and won't need the editor append `/readonly` to the src url to get a bundle without codemirror

## converter

You could define a shell helper function to quickly convert a markdown doc to a dogfen doc.

```sh
dogfen() {
  (echo '<!doctype html><script type=module src=https://esm.sh/dogfen></script><textarea style=display:none>'; cat "$1")
}
```

```sh
dogfen README.md > README.dogfen.html
```

## related projects

- [texme](https://github.com/susam/texme)
- [zeromd](https://github.com/zerodevx/zero-md)
