-- LuaRocks configuration

rocks_trees = {
   { name = "user", root = home .. "/.luarocks" };
   { name = "system", root = "/home/runner/work/nvim-treesitter-context/nvim-treesitter-context/.luarocks" };
}
lua_interpreter = "lua";
variables = {
   LUA_DIR = "/home/runner/work/nvim-treesitter-context/nvim-treesitter-context/.lua";
   LUA_BINDIR = "/home/runner/work/nvim-treesitter-context/nvim-treesitter-context/.lua/bin";
}
