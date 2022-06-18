.DEFAULT_GOAL := test

NEOVIM_BRANCH := master

FILTER=.*

NEOVIM := neovim-$(NEOVIM_BRANCH)

.PHONY: neovim
neovim: $(NEOVIM)

$(NEOVIM):
	git clone --depth 1 https://github.com/neovim/neovim --branch $(NEOVIM_BRANCH) $@
	make -C $@

nvim-treesitter:
	git clone --depth 1 https://github.com/nvim-treesitter/nvim-treesitter

nvim-treesitter/parser/lua.so: nvim-treesitter $(NEOVIM)
	VIMRUNTIME=$(NEOVIM)/runtime $(NEOVIM)/build/bin/nvim \
			   --headless \
			   --clean \
			   --cmd 'set rtp+=./nvim-treesitter' \
			   -c "TSInstallSync lua" \
			   -c "q"

nvim-treesitter/parser/rust.so: nvim-treesitter $(NEOVIM)
	VIMRUNTIME=$(NEOVIM)/runtime $(NEOVIM)/build/bin/nvim \
			   --headless \
			   --clean \
			   --cmd 'set rtp+=./nvim-treesitter' \
			   -c "TSInstallSync rust" \
			   -c "q"

export VIMRUNTIME=$(PWD)/$(NEOVIM)/runtime

.PHONY: test
test: $(NEOVIM) nvim-treesitter nvim-treesitter/parser/lua.so nvim-treesitter/parser/rust.so
	$(NEOVIM)/.deps/usr/bin/busted \
		-v \
		--lazy \
		--helper=$(PWD)/test/preload.lua \
		--output test.busted.outputHandlers.nvim \
		--lpath=$(PWD)/$(NEOVIM)/?.lua \
		--lpath=$(PWD)/$(NEOVIM)/build/?.lua \
		--lpath=$(PWD)/$(NEOVIM)/runtime/lua/?.lua \
		--lpath=$(PWD)/nvim-treesitter/lua/?.lua \
		--lpath=$(PWD)/?.lua \
		--lpath=$(PWD)/lua/?.lua \
		--filter=$(FILTER) \
		$(PWD)/test

	-@stty sane

lint:
	luacheck lua
