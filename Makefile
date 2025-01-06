.DEFAULT_GOAL := test

NVIM_TEST_VERSION ?= v0.10.2
NVIM_RUNNER_VERSION ?= v0.10.2

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
		--runner_version $(NVIM_RUNNER_VERSION) \
		--target_version $(NVIM_TEST_VERSION)

.PHONY: test
test: nvim-test nvim-treesitter
	nvim-test/bin/nvim-test test \
		--runner_version $(NVIM_RUNNER_VERSION) \
		--target_version $(NVIM_TEST_VERSION) \
		--lpath=$(PWD)/lua/?.lua \
		--filter="$(FILTER)" \
		--verbose

.PHONY: parsers
parsers: nvim-test nvim-treesitter
	$(XDG_DATA_HOME)/nvim-test/nvim-runner-$(NVIM_RUNNER_VERSION)/bin/nvim \
		--clean -u NONE -c 'source install_parsers.lua'

lint:
	luacheck lua

# ------------------------------------------------------------------------------
# LuaLS
# ------------------------------------------------------------------------------

ifeq ($(shell uname -m),arm64)
    LUALS_ARCH ?= arm64
else
    LUALS_ARCH ?= x64
endif

LUALS_VERSION := 3.13.2
LUALS_TARBALL := lua-language-server-$(LUALS_VERSION)-$(shell uname -s)-$(LUALS_ARCH).tar.gz
LUALS_URL := https://github.com/LuaLS/lua-language-server/releases/download/$(LUALS_VERSION)/$(LUALS_TARBALL)

.INTERMEDIATE: $(LUALS_TARBALL)
$(LUALS_TARBALL):
	wget $(LUALS_URL)

luals: $(LUALS_TARBALL)
	mkdir luals
	tar -xf $< -C luals

export VIMRUNTIME=$(XDG_DATA_HOME)/nvim-test/nvim-test-$(NVIM_TEST_VERSION)/share/nvim/runtime
.PHONY: luals-check
luals-check: luals nvim-test
	@ls $(VIMRUNTIME) > /dev/null
	VIMRUNTIME=$(XDG_DATA_HOME)/nvim-test/nvim-test-$(NVIM_TEST_VERSION)/share/nvim/runtime \
		luals/bin/lua-language-server \
			--logpath=luals_check \
			--configpath=../.luarc.json \
			--check=lua
	@grep '^\[\]$$' luals_check/check.json

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

LUA_FILES := \
    lua/**/*.lua \
    lua/*.lua \
    test/*_spec.lua

.PHONY: stylua-check
stylua-check: stylua
	./stylua --check $(LUA_FILES)
	@! grep -n -- '---.*nil' $(LUA_FILES) \
		|| (echo "Error: Found 'nil' in annotation, please use '?'" && exit 1)
	@! grep -n -- '---@' $(LUA_FILES) \
		|| (echo "Error: Found '---@' in Lua files, please use '--- @'" && exit 1)

.PHONY: stylua-run
stylua-run: stylua
	./stylua $(LUA_FILES)
	sed -i -r 's/---@/--- @/g' $(LUA_FILES)
