# dogfen

## usage

Add the below oneliner to an existing markdown document:

```html
<!DOCTYPE html><html><body><script src="https://unpkg.dev/dogfen"></script><textarea style="display:none;">

# Header 1

## Header 2

|col 1 | col 2 |
|---|---|
|cell 1 | cell 2 |
```

## converter

You could define a shell helper function to quickly convert a markdown doc to a dogfen doc.

```sh
md2dogfen() {
  printf "%s\n\n%s\n" \
    '<!DOCTYPE html><html><body><script src="https://unpkg.dev/dogfen"></script><textarea style="display:none;">' \
    "$(cat $1)"
}
```

```sh
md2dogfen README.md > README.dogfen.html
```

## related projects

- [texme](https://github.com/susam/texme)
