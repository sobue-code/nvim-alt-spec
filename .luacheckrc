-- luacheck configuration for nvim-alt-spec

-- Neovim globals
globals = { "vim" }

-- Allow unused self
self = false

-- Maximum line length
max_line_length = 120

-- Ignore whitespace issues
ignore = {
    "631", -- line is too long (handled by max_line_length)
}

-- Standard library
std = "luajit"

-- Allow defining modules
allow_defined_top = true

-- Unused args in callbacks are okay
unused_secondaries = false
