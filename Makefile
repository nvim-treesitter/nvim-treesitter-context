.DEFAULT_GOAL := test

NEOVIM_VERSION ?= v0.9.5
NEOVIM_RUNNER_VERSION ?= v0.10.0

NVIM_TS_SHA ?= 894cb3c

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

# ------------------------------------------------------------------------------
# Stylua
# ------------------------------------------------------------------------------
ifeq ($(shell uname -s),Darwin)
    STYLUA_PLATFORM := macos-aarch64
else
    STYLUA_PLATFORM := linux-x86_64
endif

STYLUA_VERSION := v2.0.2
STYLUA_ZIP := stylua-$(STYLUA_PLATFORM).zip
STYLUA_URL := https://github.com/JohnnyMorganz/StyLua/releases/download/$(STYLUA_VERSION)/$(STYLUA_ZIP)

.INTERMEDIATE: $(STYLUA_ZIP)
$(STYLUA_ZIP):
	wget $(STYLUA_URL)

stylua: $(STYLUA_ZIP)
	unzip $<

.PHONY: stylua-check
stylua-check: stylua
	./stylua --check lua/**/*.lua

.PHONY: stylua-run
stylua-run: stylua
	./stylua \
		lua/**/*.lua \
		lua/*.lua \
		test/*_spec.lua
