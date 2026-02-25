# nvim-alt-spec

Neovim plugin for working with ALT Linux RPM spec files.

## Features

- **Add changelog entries** with `,ac` keybinding (LocalLeader + ac)
- **Cleanup spec files** with `,cs` keybinding (LocalLeader + cs)
- Automatic EVR (Epoch-Version-Release) detection using `describe-specfile` or `rpm`
- Smart detection of version changes - only adds changelog when EVR actually changed
- If EVR unchanged, cursor jumps to Version line for editing
- Configurable templates for changelog entries
- Packager detection from `~/.rpmmacros`, hasher config, or git config
- C locale date formatting per ALT Linux guidelines

## Requirements

- Neovim >= 0.8.0
- `describe-specfile` (from gear) or `rpm` for EVR parsing
- `cleanup_spec` (from rpm-utils) for spec cleanup

## Installation

### Using lazy.nvim with GitHub

```lua
{
  "sobue-code/nvim-alt-spec",
  ft = "spec",
  config = function()
    require("alt-spec").setup()
  end,
}
```

### Using lazy.nvim with local path

```lua
{
  dir = "/path/to/nvim-alt-spec",
  name = "alt-spec",
  ft = "spec",
  config = function()
    require("alt-spec").setup()
  end,
}
```

## Configuration

```lua
require("alt-spec").setup({
  -- Packager name (if nil, auto-detected from ~/.rpmmacros, hasher, or git)
  packager = nil,
  
  -- Method to get EVR: "gear" (recommended) or "rpm"
  evr_method = "gear",
  
  -- Keymap for triggering changelog
  changelog_keymap = "<LocalLeader>ac",
  
  -- Keymap for cleanup_spec
  cleanup_keymap = "<LocalLeader>cs",
  
  -- Prepend new entries to existing changelog header
  prepend = false,
  
  -- Template for first changelog entry (no previous entries)
  first_entry_template = "Initial build.",
  
  -- Template for version change entries
  -- Available placeholders: <old_evr>, <new_evr>
  version_change_template = "<old_evr> -> <new_evr>",
})
```

## Usage

### Add Changelog Entry

1. Open a `.spec` file
2. Update `Version` or `Release` in the spec
3. Press `,ac` (LocalLeader + ac)
4. A new changelog entry will be added automatically

If EVR hasn't changed, the cursor will jump to the Version line for editing.

### Cleanup Spec File

1. Open a `.spec` file
2. Press `,cs` (LocalLeader + cs)
3. The spec file will be cleaned up using `cleanup_spec`

## Example Output

First entry:
```
* Mon Feb 24 2025 Your Name <email@example.com> 1.0.0-alt1
- Initial build.
```

Version update:
```
* Mon Feb 24 2025 Your Name <email@example.com> 1.1.0-alt1
- 1.0.0-alt1 -> 1.1.0-alt1
```

With epoch:
```
* Mon Feb 24 2025 Your Name <email@example.com> 1:2.0.0-alt1
- 1:1.0.0-alt1 -> 1:2.0.0-alt1
```

## Commands

| Command | Description |
|---------|-------------|
| `:SpecChangelog` | Add changelog entry |
| `:SpecCleanup` | Cleanup spec file |

## Keymaps

| Keymap | Description |
|--------|-------------|
| `,ac` | Add changelog entry |
| `,cs` | Cleanup spec file |

## Packager Detection Order

1. `packager` config option
2. `~/.rpmmacros` (`%packager` macro)
3. Hasher config (`~/.hasher/config`)
4. Git config (`user.name` + `user.email`)

## License

GPL-3.0-or-later
