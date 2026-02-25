-- alt-spec/parser.lua - Parser for RPM spec files
local M = {}
local config = require("alt-spec.config")

-- Get EVR using gear's describe-specfile
local function get_evr_gear(filepath)
  local cmd = string.format("set -- $(describe-specfile --epoch %s 2>/dev/null); echo \"$2-$3\"", vim.fn.shellescape(filepath))
  local result = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    return nil
  end
  result = vim.trim(result)
  if result == "" or result == "-" then
    return nil
  end
  return result
end

-- Get EVR using rpm
local function get_evr_rpm(filepath)
  local cmd = string.format("rpm -q --qf '%%|EPOCH?{%{EPOCH}:}|%%{VERSION}-%%{RELEASE}\\n' --specfile %s 2>/dev/null | head -1", vim.fn.shellescape(filepath))
  local result = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    return nil
  end
  result = vim.trim(result)
  if result == "" then
    return nil
  end
  return result
end

-- Get EVR from spec file
function M.get_evr_from_spec(filepath)
  local method = config.options.evr_method
  
  if method == "gear" then
    local evr = get_evr_gear(filepath)
    if evr then
      return evr
    end
    -- Fallback to rpm if gear fails
    return get_evr_rpm(filepath)
  elseif method == "rpm" then
    return get_evr_rpm(filepath)
  else
    -- Default: try gear first, then rpm
    local evr = get_evr_gear(filepath)
    if evr then
      return evr
    end
    return get_evr_rpm(filepath)
  end
end

-- Find line number of a tag (Version, Release, Epoch)
function M.find_tag_line(lines, tag)
  for i, line in ipairs(lines) do
    if line:match("^" .. tag .. ":%s*") then
      return i
    end
  end
  return nil
end

-- Parse spec file content for EVR manually (fallback)
function M.parse_spec_evr(content)
  local epoch, version, release
  
  -- Extract epoch (optional)
  epoch = content:match("Epoch:%s*(%d+)")
  
  -- Extract version
  version = content:match("Version:%s*([^\n]+)")
  if version then
    version = vim.trim(version)
    -- Handle macros
    version = version:gsub("%%{version}", version)
    version = version:gsub("%%{?version}?", version)
  end
  
  -- Extract release
  release = content:match("Release:%s*([^\n]+)")
  if release then
    release = vim.trim(release)
    -- Handle dist macros - just keep the base release
    release = release:gsub("%%{?dist}?", "")
    release = vim.trim(release)
  end
  
  if not version or not release then
    return nil
  end
  
  if epoch then
    return epoch .. ":" .. version .. "-" .. release
  else
    return version .. "-" .. release
  end
end

return M
