.DEFAULT_GOAL := test

NEOVIM_VERSION ?= v0.9.5
NEOVIM_RUNNER_VERSION ?= v0.10.0

NVIM_TS_SHA ?= ba921c9a

FILTER=.*

export XDG_DATA_HOME ?= $(HOME)/.data

nvim-treesitter:
	git clone  \
      	--filter=blob:none \
		https://github.com/nvim-treesitter/nvim-treesitter
	cd nvim-treesitter && git checkout $(NVIM_TS_SHA)

nvim-test:
	git clone https://github.com/lewis6991/nvim-test
	nvim-test/bin/nvim-test --init \
		--runner_version $(NEOVIM_RUNNER_VERSION) \
		--target_version $(NEOVIM_VERSION)

.PHONY: test
test: nvim-test nvim-treesitter
	nvim-test/bin/nvim-test test \
		--runner_version $(NEOVIM_RUNNER_VERSION) \
		--target_version $(NEOVIM_VERSION) \
		--lpath=$(PWD)/lua/?.lua \
		--filter="$(FILTER)" \
		--verbose

.PHONY: parsers
parsers: nvim-test nvim-treesitter
	$(XDG_DATA_HOME)/nvim-test/nvim-runner-$(NEOVIM_RUNNER_VERSION)/bin/nvim \
		--clean -u NONE -c 'source install_parsers.lua'

lint:
	luacheck lua
