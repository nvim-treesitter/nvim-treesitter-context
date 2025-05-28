.DEFAULT_GOAL := test

export XDG_DATA_HOME ?= $(HOME)/.data

# ------------------------------------------------------------------------------
# nvim-treesitter
# ------------------------------------------------------------------------------

NVIM_TS_SHA ?= 61b0a05e
NVIM_TS := deps/nvim-treesitter

.PHONY: nvim-treesitter
nvim-treesitter: $(NVIM_TS)

$(NVIM_TS):
	git clone  \
      	--filter=blob:none \
		https://github.com/nvim-treesitter/nvim-treesitter $@
	cd $@ && git checkout $(NVIM_TS_SHA)

# ------------------------------------------------------------------------------
# Nvim-test
# ------------------------------------------------------------------------------

FILTER=.*

export NVIM_TEST_VERSION ?= v0.11.1
export NVIM_RUNNER_VERSION ?= v0.11.1

NVIM_TEST := deps/nvim-test
NVIM_TEST_REV = v1.1.0

.PHONY: nvim-test
nvim-test: $(NVIM_TEST)

$(NVIM_TEST):
	git clone \
		--filter=blob:none \
		--branch $(NVIM_TEST_REV) \
		https://github.com/lewis6991/nvim-test $@
	$(NVIM_TEST)/bin/nvim-test --init

.PHONY: test
test: $(NVIM_TEST) $(NVIM_TS)
	$(NVIM_TEST)/bin/nvim-test test \
		--runner_version $(NVIM_RUNNER_VERSION) \
		--target_version $(NVIM_TEST_VERSION) \
		--lpath=$(PWD)/lua/?.lua \
		--filter="$(FILTER)" \
		--verbose

.PHONY: parsers
parsers: $(NVIM_TEST) $(NVIM_TS)
	$(XDG_DATA_HOME)/nvim-test/nvim-runner-$(NVIM_RUNNER_VERSION)/bin/nvim \
		-l test/helpers.lua install

# ------------------------------------------------------------------------------
# LuaLS
# ------------------------------------------------------------------------------

ifeq ($(shell uname -m),arm64)
    LUALS_ARCH ?= arm64
else
    LUALS_ARCH ?= x64
endif

LUALS_VERSION := 3.13.6
LUALS := deps/lua-language-server-$(LUALS_VERSION)-$(shell uname -s)-$(LUALS_ARCH)
LUALS_TARBALL := $(LUALS).tar.gz
LUALS_URL := https://github.com/LuaLS/lua-language-server/releases/download/$(LUALS_VERSION)/$(notdir $(LUALS_TARBALL))

.PHONY: luals
luals: $(LUALS)

$(LUALS):
	wget --directory-prefix=$(dir $@) $(LUALS_URL)
	mkdir -p $@
	tar -xf $(LUALS_TARBALL) -C $@
	rm -rf $(LUALS_TARBALL)

.PHONY: luals-check
luals-check: $(LUALS) $(NVIM_TEST)
	VIMRUNTIME=$(XDG_DATA_HOME)/nvim-test/nvim-test-$(NVIM_TEST_VERSION)/share/nvim/runtime \
		$(LUALS)/bin/lua-language-server \
			--configpath=../.luarc.json \
			--check=lua

# ------------------------------------------------------------------------------
# Stylua
# ------------------------------------------------------------------------------
ifeq ($(shell uname -s),Darwin)
    STYLUA_PLATFORM := macos-aarch64
else
    STYLUA_PLATFORM := linux-x86_64
endif

# ------------------------------------------------------------------------------
# Stylua
# ------------------------------------------------------------------------------

STYLUA_VERSION := v2.1.0
STYLUA_ZIP := stylua-$(STYLUA_PLATFORM).zip
STYLUA_URL := https://github.com/JohnnyMorganz/StyLua/releases/download/$(STYLUA_VERSION)/$(STYLUA_ZIP)
STYLUA := deps/stylua

.INTERMEDIATE: $(STYLUA_ZIP)
$(STYLUA_ZIP):
	wget $(STYLUA_URL)

.PHONY: stylua
stylua: $(STYLUA)

$(STYLUA): $(STYLUA_ZIP)
	unzip $< -d $(dir $@)

LUA_FILES := $(shell git ls-files 'lua/*.lua' 'test/*_spec.lua')

.PHONY: stylua-check
stylua-check: $(STYLUA)
	$(STYLUA) --check $(LUA_FILES)
	@! grep -n -- '---.*nil' $(LUA_FILES) \
		|| (echo "Error: Found 'nil' in annotation, please use '?'" && exit 1)
	@! grep -n -- '---@' $(LUA_FILES) \
		|| (echo "Error: Found '---@' in Lua files, please use '--- @'" && exit 1)

.PHONY: stylua-run
stylua-run: $(STYLUA)
	$(STYLUA) $(LUA_FILES)
	perl -pi -e 's/---@/--- @/g' $(LUA_FILES)
