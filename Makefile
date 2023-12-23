.DEFAULT_GOAL := test

NEOVIM_BRANCH := v0.9.1

FILTER=.*

NEOVIM := neovim-$(NEOVIM_BRANCH)

.PHONY: neovim
neovim: $(NEOVIM)

$(NEOVIM):
	git clone --depth 1 https://github.com/neovim/neovim --branch $(NEOVIM_BRANCH) $@
	make -C $@

nvim-treesitter:
	git clone --depth 1 https://github.com/nvim-treesitter/nvim-treesitter

nvim-treesitter/parser/%.so: nvim-treesitter $(NEOVIM)
	$(RM) -r $@
	VIMRUNTIME=$(NEOVIM)/runtime $(NEOVIM)/build/bin/nvim \
			   --headless \
			   --clean \
			   --cmd 'set rtp+=./nvim-treesitter' \
			   -c "TSInstallSync $*" \
			   -c "q"

export VIMRUNTIME=$(PWD)/$(NEOVIM)/runtime

BUSTED = $$( [ -f $(NEOVIM)/test/busted_runner.lua ] \
        && echo "$(NEOVIM)/build/bin/nvim -ll $(NEOVIM)/test/busted_runner.lua" \
        || echo "$(NEOVIM)/.deps/usr/bin/busted" )

.PHONY: test
test: $(NEOVIM) nvim-treesitter \
	nvim-treesitter/parser/cpp.so \
	nvim-treesitter/parser/lua.so \
	nvim-treesitter/parser/rust.so \
	nvim-treesitter/parser/typescript.so
	$(BUSTED) \
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
