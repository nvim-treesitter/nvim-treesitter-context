.DEFAULT_GOAL := test

NEOVIM_VERSION := 0.9.5

NVIM_TS_SHA := 883c72cd

FILTER=.*

nvim-treesitter:
	git clone  \
      	--filter=blob:none \
		https://github.com/nvim-treesitter/nvim-treesitter
	cd nvim-treesitter && git checkout $(NVIM_TS_SHA)

nvim-test:
	git clone https://github.com/lewis6991/nvim-test
	nvim-test/bin/nvim-test --init

.PHONY: test
test: nvim-test nvim-treesitter
	nvim-test/bin/nvim-test test \
		--runner_version $(NEOVIM_VERSION) \
		--target_version $(NEOVIM_VERSION) \
		--lpath=$(PWD)/lua/?.lua \
		--filter=$(FILTER) \
		--verbose

lint:
	luacheck lua
