local log = require "obsidian.log"
local util = require "obsidian.util"

---@param client obsidian.Client
---@param callback fun(alias_to_notes: table<string, obsidian.Note[]>)
local find_alias = function(client, callback)
  client:find_notes_async("", function(notes)
    local alias_to_notes = {}
    for _, note in ipairs(notes) do
      for _, alias in ipairs(note.aliases) do
        alias_to_notes[alias] = alias_to_notes[alias] or {}
        table.insert(alias_to_notes[alias], note)
      end
    end
    callback(alias_to_notes)
  end)
end

---@param note obsidian.Note
---
---@return obsidian.PickerEntry
local function convert_note_to_picker_entry(note)
  return {
    value = note,
    display = note:display_name(),
    ordinal = note:display_name(),
    filename = tostring(note.path),
  }
end

---@param client obsidian.Client
return function(client)
  local picker = client:picker()
  if not picker then
    log.err "No picker configured"
    return
  end

  find_alias(client, function(alias_to_notes)
    vim.schedule(function()
      picker:pick(vim.tbl_keys(alias_to_notes), {
        prompt_title = "Aliases",
        callback = function(alias)
          local notes = alias_to_notes[alias]
          if #notes == 1 then
            util.open_buffer(notes[1].path)
          else
            local entries = vim.tbl_map(convert_note_to_picker_entry, notes)
            vim.schedule(function()
              picker:pick(entries, {
                prompt_title = alias,
                callback = function(note)
                  util.open_buffer(note.path)
                end,
              })
            end)
          end
        end,
      })
    end)
  end)
end
