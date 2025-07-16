# templ-mode

Emacs (30.1+) major mode for editing [Templ](https://templ.guide/) template files.

Templ is a language for writing HTML user interfaces in Go. This mode provides syntax highlighting, formatting, and LSP support for `.templ` files in Emacs.

> [!NOTE]
> This mode depends on and extends [go-mode](https://github.com/dominikh/go-mode.el). It will not work with other Go-related modes.

> [!NOTE]
> This mode does **not** depend on tree-sitter.

## Installation

Download `templ-mode.el` and place it in your Emacs load path.

## Usage

### Basic Usage

The mode automatically activates for `.templ` files. It extends `go-mode` with additional syntax highlighting for:

- `templ` keywords and function definitions.
- `@` directives for component calls.
- HTML-like tags within templates.

### Formatting

Use <kbd>M-x</kbd> `templ-fmt` <kbd>RET</kbd> to format the current buffer using `templ fmt`.

### Configuration

By default, `templ-mode` looks for the `templ` binary in your PATH. You can customize this:

```elisp
;; Use a specific path to the templ binary
(setq templ-mode-command "/path/to/templ")

;; Or use templ as a Go tool (requires templ to be installed as a Go tool)
(setq templ-mode-command 'tool)
```

When using `'tool`, the mode will run `go tool templ` from your project root as returned by `(project-root (project-current))`.

Go tools were introduced in Go 1.24. Read more about them [here](https://tip.golang.org/doc/go1.24#tools).

### LSP Support

The mode automatically configures Eglot to work with the Templ LSP server. To start the server, use <kbd>M-x</kbd> `eglot` <kbd>RET</kbd> in a `.templ` buffer.

## Related Packages

- [templ-ts-mode](https://github.com/danderson/templ-ts-mode): Uses tree-sitter instead of the older regexp-based approach for font-locking.
- [poly-templ](https://github.com/rcy/poly-templ): Uses [polymode](https://github.com/polymode/polymode) to implement Templ syntax highlighting.

## License

Distributed under the GNU General Public License, version 3.

See [LICENSE](LICENSE) for more information.
