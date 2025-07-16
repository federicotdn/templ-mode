run:
	emacs --load templ-mode.el \
		--eval '(delete-other-windows)' \
		--eval "(setq templ-mode-command 'tool)" \
		examples/blog.templ
