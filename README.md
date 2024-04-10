<h1>clip2imgur <img src="./icon.png" height="36" align="right"></h1>

> A simple macOS command line tool for uploading your screenshots from clipboard
> to Imgur

[![Github Actions Status](https://github.com/xiaohk/clip2imgur/workflows/build/badge.svg)](https://github.com/xiaohk/clip2imgur/actions/workflows/build.yml)
[![License](https://img.shields.io/badge/License-MIT-yellowgreen)](https://github.com/xiaohk/clip2imgur/blob/master/LICENSE)
[![pypi](https://img.shields.io/pypi/v/clip2imgur?color=blue)](https://pypi.python.org/pypi/clip2imgur)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.5348350.svg)](https://doi.org/10.5281/zenodo.5348350)

## Usage

<img src="./demo.gif" width=500 style="margin-left:50px"  align="right">

- Press <kbd>control+shift+command+3</kbd> or <kbd>control+shift+command+4</kbd>
  to capture and copy a screenshot.

- Run `clip2imgur` in your terminal, then boom, the image URL is in your
  clipboard.

- If it is your first time to run `clip2imgur`, you can choose to authorize this
  tool, and your image will be posted in your image collection
  (`username.imgur.com/all`).

- You also can choose to post anonymously, but it is hard to get the url later
  and Imgur might delete your posts.

In default setting, the URL of posted image will be copied to your clipboard.
You can use flags to configure it.

```
$ clip2imgur --html
$ clip2imgur -n
```

| short | long         | description                                                                         |
| :---- | :----------- | :---------------------------------------------------------------------------------- |
| `-m`  | `--markdown` | URL will be copied in the Markdown image format.`[](https://i.imgur.com/x.png)`     |
| `-t`  | `--html`     | URL will be copied in the HTML image format.`<img src="https://i.imgur.com/x.png">` |
| `-n`  | `--notcopy`  | Your image URL will not be copied to your clipboard                                 |

Personally I like to include images in Markdown file using the HTML format,
which gives more control of the display. If you forget these flags, you always
can run `clip2imgur -h` to check the usage.

## Change Log

- (4/9/2024): Clip2imgur is rewritten in Python.
- (2/15/2018): Clip2imgur is released. This version is written in Swift.

## Install

This package is built using cross-platform Swift with Swift Package Manager
(SPM), but it currently only supports macOS. There are three ways to install
`clip2imgur`.

### Homebrew

Using `Homebrew` is the recommended and also the easiest way to get `clip2imgur`
installed on your mac. If you don't have `Homebrew` installed, you can simply
run:

```
$ /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

Then, to install `clip2imgur`:

```
$ brew tap xiaohk/clip2imgur
$ brew install clip2imgur
```

### PyPI

If you are familiar with Python, you can install `clip2imgur` with pip.

```
$ pip install clip2imgur
```

## Built With

The latest version (>=v0.9.1) uses Python.

The first version (v0.9.0) was built with:

- [Swift Package Manager](https://swift.org/package-manager/)
- [Rainbow](https://github.com/onevcat/Rainbow)
