run:
	emacs --load templ-mode.el \
		--eval '(setq confirm-kill-emacs nil)' \
		--eval '(delete-other-windows)' \
		--eval "(setq templ-mode-command 'tool)" \
		examples/blog.templ
