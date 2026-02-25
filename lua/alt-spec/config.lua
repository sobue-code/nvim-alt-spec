-- alt-spec/config.lua - Configuration module
local M = {}

-- Default configuration
M.defaults = {
  -- Packager name (if nil, will try to detect automatically)
  packager = nil,
  
  -- Method to get EVR: "gear" (uses describe-specfile) or "rpm" (uses rpm -q --specfile)
  evr_method = "gear",
  
  -- Keymap for triggering changelog (localleader is ",")
  -- Set to nil to disable default keymap
  changelog_keymap = "<LocalLeader>ac",
  
  -- Keymap for cleanup_spec
  -- Set to nil to disable default keymap
  cleanup_keymap = "<LocalLeader>cs",
  
  -- Prepend new entries to existing changelog header
  prepend = false,
  
  -- Template for first changelog entry
  first_entry_template = "Initial build.",
  
  -- Template for version change entries
  -- Available placeholders: <old_evr>, <new_evr>
  version_change_template = "<old_evr> -> <new_evr>",
}

M.options = {}

-- Setup configuration
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
  return M.options
end

-- Get current options
function M.get()
  return M.options
end

return M
