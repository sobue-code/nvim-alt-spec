-- alt-spec.nvim - Plugin initialization
-- This file is loaded by Neovim on startup

if vim.g.loaded_alt_spec then
  return
end
vim.g.loaded_alt_spec = 1

-- Create user commands (available globally)
vim.api.nvim_create_user_command("SpecChangelog", function()
  require("alt-spec").add_changelog()
end, {
  desc = "Add changelog entry to RPM spec file",
})

vim.api.nvim_create_user_command("SpecCleanup", function()
  require("alt-spec").cleanup_spec()
end, {
  desc = "Cleanup RPM spec file",
})

vim.api.nvim_create_user_command("SpecNext", function()
  require("alt-spec").next_section()
end, {
  desc = "Jump to next section in RPM spec file",
})

vim.api.nvim_create_user_command("SpecPrev", function()
  require("alt-spec").prev_section()
end, {
  desc = "Jump to previous section in RPM spec file",
})

-- Set up keybindings for spec files
vim.api.nvim_create_autocmd("FileType", {
  pattern = "spec",
  callback = function()
    -- Changelog
    vim.keymap.set("n", "<Plug>SpecChangelog", function()
      require("alt-spec").add_changelog()
    end, { buffer = true, silent = true, desc = "Add changelog entry" })
    
    -- Default keymap: <LocalLeader>ac (which is ,ac with LocalLeader = ,)
    vim.keymap.set("n", "<LocalLeader>ac", "<Plug>SpecChangelog", { buffer = true, silent = true, desc = "Add changelog entry" })
    
    -- Cleanup
    vim.keymap.set("n", "<Plug>SpecCleanup", function()
      require("alt-spec").cleanup_spec()
    end, { buffer = true, silent = true, desc = "Cleanup spec file" })
    
    -- Default keymap: <LocalLeader>cs (which is ,cs with LocalLeader = ,)
    vim.keymap.set("n", "<LocalLeader>cs", "<Plug>SpecCleanup", { buffer = true, silent = true, desc = "Cleanup spec file" })
    
    -- Section navigation
    vim.keymap.set("n", "<Plug>SpecNext", function()
      require("alt-spec").next_section()
    end, { buffer = true, silent = true, desc = "Next section" })
    
    vim.keymap.set("n", "<Plug>SpecPrev", function()
      require("alt-spec").prev_section()
    end, { buffer = true, silent = true, desc = "Previous section" })
    
    -- Default keymaps: ]s / [s
    vim.keymap.set("n", "]s", "<Plug>SpecNext", { buffer = true, silent = true, desc = "Next section" })
    vim.keymap.set("n", "[s", "<Plug>SpecPrev", { buffer = true, silent = true, desc = "Previous section" })
  end,
})
