.DEFAULT_GOAL := test

NEOVIM_BRANCH := v0.9.1

FILTER=.*

NEOVIM := neovim-$(NEOVIM_BRANCH)

.PHONY: neovim
neovim: $(NEOVIM)

neovim-nightly:
	$(MAKE) NEOVIM_BRANCH=nightly neovim-nightly

$(NEOVIM):
	git clone --depth 1 https://github.com/neovim/neovim --branch $(NEOVIM_BRANCH) $@
	$(MAKE) -C $@

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


ARCH := $(shell uname -m | sed 's/x86_64/x64/')
PLATFORM := $(shell uname -s)

LUALS_VERSION := 3.7.0
LUALS_BASE_URL := https://github.com/LuaLS/lua-language-server/releases/download
LUALS_URL := $(LUALS_BASE_URL)/$(LUALS_VERSION)/lua-language-server-$(LUALS_VERSION)-$(PLATFORM)-$(ARCH).tar.gz

luals:
	wget $(LUALS_URL) -O luals.tar.gz
	$(RM) -f luals
	mkdir luals
	tar -C luals -zxvf luals.tar.gz
	$(RM) -f luals.tar.gz

check-luals: luals neovim-nightly
	@VIMRUNTIME=$(PWD)/neovim-nightly/runtime && \
	./luals/bin/lua-language-server \
		--logpath . \
		--configpath $(PWD)/.luarc.json \
		--check $(PWD)/lua \
		| tee luals_out.log
	@grep --silent 'no problems found' luals_out.log \
		|| cat check.json

