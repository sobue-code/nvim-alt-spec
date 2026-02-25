-- alt-spec.nvim - Neovim plugin for working with ALT Linux RPM spec files
-- Author: Based on vim-plugin-spec_alt-ftplugin

local M = {}
local config = require("alt-spec.config")
local parser = require("alt-spec.parser")

-- Get packager name from various sources
local function get_packager()
  -- First check config
  if config.options.packager then
    return config.options.packager
  end

  -- Try rpm macros (~/.rpmmacros)
  local packager = vim.fn.system("rpm --eval '%{?packager}' 2>/dev/null")
  packager = vim.trim(packager or "")
  if packager ~= "" then
    return packager
  end

  -- Try hasher config
  packager = vim.fn.system("eval \"$(hsh --printenv 2>/dev/null)\"; echo ${packager:-}")
  packager = vim.trim(packager or "")
  if vim.v.shell_error == 0 and packager ~= "" then
    return packager
  end

  -- Try git config
  local name = vim.fn.system("git config --get user.name 2>/dev/null")
  local email = vim.fn.system("git config --get user.email 2>/dev/null")
  name = vim.trim(name or "")
  email = vim.trim(email or "")
  if name ~= "" and email ~= "" then
    return name .. " <" .. email .. ">"
  end

  vim.notify("Error: undefined packager. Configure in ~/.rpmmacros, ~/.hasher/config, or ~/.gitconfig", vim.log.levels.ERROR)
  return nil
end

-- Get date in changelog format (C locale)
local function get_date()
  -- Save current locale and switch to C
  local saved_locale = os.setlocale("C", "time")
  local date = os.date("%a %b %d %Y")
  -- Restore locale
  if saved_locale then
    os.setlocale(saved_locale, "time")
  end
  return date
end

-- Find %changelog section
local function find_changelog_line(lines)
  for i, line in ipairs(lines) do
    if line:match("^%%changelog") then
      return i
    end
  end
  return nil
end

-- Get last changelog EVR
local function get_last_changelog_evr(lines, changelog_line)
  if not changelog_line then
    return nil
  end
  
  -- Look for the first changelog entry line (starts with *)
  for i = changelog_line + 1, #lines do
    local line = lines[i]
    local evr = line:match("^%* .+ (.+)$")
    if evr then
      return evr
    end
  end
  return nil
end

-- Parse EVR into components
local function parse_evr(evr)
  if not evr then
    return { epoch = nil, version = nil, release = nil }
  end
  
  local epoch, rest = evr:match("^(%d+):(.+)$")
  if epoch then
    local version, release = rest:match("^(.+)-(.+)$")
    return { epoch = epoch, version = version, release = release }
  else
    local version, release = evr:match("^(.+)-(.+)$")
    return { epoch = nil, version = version, release = release }
  end
end

-- Format EVR for output (omit epoch if nil)
local function format_evr(evr_table)
  if not evr_table then
    return ""
  end
  
  if evr_table.epoch then
    return evr_table.epoch .. ":" .. evr_table.version .. "-" .. evr_table.release
  else
    return (evr_table.version or "") .. "-" .. (evr_table.release or "")
  end
end

-- Generate changelog entry message
-- Returns: message string, or nil if nothing changed
local function generate_entry_message(old_evr, new_evr)
  -- First entry
  if not old_evr then
    return config.options.first_entry_template
  end
  
  local old_parsed = parse_evr(old_evr)
  local new_parsed = parse_evr(new_evr)
  
  -- Check if anything changed
  local epoch_changed = old_parsed.epoch ~= new_parsed.epoch
  local version_changed = old_parsed.version ~= new_parsed.version
  local release_changed = old_parsed.release ~= new_parsed.release
  
  -- If nothing changed, return nil (no changelog needed)
  if not epoch_changed and not version_changed and not release_changed then
    return nil
  end
  
  -- Use version change template
  local result = config.options.version_change_template
  result = result:gsub("<old_evr>", format_evr(old_parsed))
  result = result:gsub("<new_evr>", format_evr(new_parsed))
  return result
end

-- Jump cursor to Version line (in normal mode)
local function jump_to_version_line(lines)
  -- First try to find Version line
  local version_line = parser.find_tag_line(lines, "Version")
  if version_line then
    -- Find the column where the value starts (after "Version:")
    local line = lines[version_line]
    local col = line:find("%S", line:find(":") + 1)
    if col then
      col = col - 1  -- Convert to 0-indexed
    else
      col = 0
    end
    vim.api.nvim_win_set_cursor(0, { version_line, col })
    return true
  end
  return false
end

-- Main function to add changelog entry
function M.add_changelog()
  local buf = vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(buf)
  
  -- Check if this is a spec file
  if not filepath:match("%.spec$") then
    vim.notify("Not a spec file", vim.log.levels.WARN)
    return
  end
  
  local packager = get_packager()
  if not packager then
    return
  end
  
  local date = get_date()
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  
  -- Get current EVR from spec
  local current_evr = parser.get_evr_from_spec(filepath)
  if not current_evr then
    vim.notify("Failed to parse EVR from specfile", vim.log.levels.ERROR)
    return
  end
  
  local changelog_line = find_changelog_line(lines)
  
  -- No %changelog found - ask to create
  if not changelog_line then
    local choice = vim.fn.confirm("Can't find %changelog. Create one?", "&End of file\n&Here\n&Cancel", 3)
    if choice == 1 then
      vim.api.nvim_buf_set_lines(buf, -1, -1, false, { "", "%changelog" })
      changelog_line = #lines + 2
      lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    elseif choice == 2 then
      local row = vim.api.nvim_win_get_cursor(0)[1]
      vim.api.nvim_buf_set_lines(buf, row, row, false, { "%changelog" })
      changelog_line = row + 1
      lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    else
      return
    end
  end
  
  local last_evr = get_last_changelog_evr(lines, changelog_line)
  local header = "* " .. date .. " " .. packager .. " " .. current_evr
  
  -- Check if header already exists
  if lines[changelog_line + 1] == header then
    -- Header exists, just add a new entry line
    local insert_line = changelog_line + 1
    
    -- Find where to insert (after existing entries)
    if not config.options.prepend then
      while lines[insert_line + 1] and not lines[insert_line + 1]:match("^%s*$") and not lines[insert_line + 1]:match("^%*") do
        insert_line = insert_line + 1
      end
    end
    
    vim.api.nvim_buf_set_lines(buf, insert_line, insert_line, false, { "- " })
    vim.api.nvim_win_set_cursor(0, { insert_line + 1, 2 })
    vim.cmd("startinsert!")
    return
  end
  
  -- Generate entry message
  local entry_message = generate_entry_message(last_evr, current_evr)
  
  -- Check if nothing changed - jump to Version line instead
  if not entry_message then
    vim.notify("No changes detected (EVR unchanged). Jumping to Version line.", vim.log.levels.WARN)
    jump_to_version_line(lines)
    return
  end
  
  -- Create new changelog entry
  local new_lines = {
    header,
    "- " .. entry_message,
  }
  
  -- Add empty line if there's content after changelog
  if lines[changelog_line + 1] and lines[changelog_line + 1] ~= "" then
    table.insert(new_lines, "")
  end
  
  vim.api.nvim_buf_set_lines(buf, changelog_line, changelog_line, false, new_lines)
  
  -- Position cursor for editing
  local cursor_line = changelog_line + 2
  local cursor_col = #("- " .. entry_message)
  vim.api.nvim_win_set_cursor(0, { cursor_line, cursor_col })
  vim.cmd("startinsert!")
end

-- Cleanup spec file using cleanup_spec command
function M.cleanup_spec()
  local buf = vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(buf)
  
  -- Check if this is a spec file
  if not filepath:match("%.spec$") then
    vim.notify("Not a spec file", vim.log.levels.WARN)
    return
  end
  
  -- Save current file first
  vim.cmd("write")
  
  -- Run cleanup_spec
  local cmd = "cleanup_spec " .. vim.fn.shellescape(filepath)
  local result = vim.fn.system(cmd)
  
  if vim.v.shell_error ~= 0 then
    vim.notify("cleanup_spec failed: " .. result, vim.log.levels.ERROR)
    return
  end
  
  -- Reload the file
  vim.cmd("edit!")
  vim.notify("Spec file cleaned up", vim.log.levels.INFO)
end

-- Setup function
function M.setup(opts)
  config.setup(opts)
end

return M
