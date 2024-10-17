local log = require "obsidian.log"
local util = require "obsidian.util"

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

---@param notes obsidian.Note[]
---
---@return table<string, obsidian.Note[]>
local function map_title_to_notes(notes)
  local title_to_notes = {}
  for _, note in ipairs(notes) do
    local title = note.title
    if title then
      title_to_notes[title] = title_to_notes[title] or {}
      table.insert(title_to_notes[title], note)
    end
    for _, alias in ipairs(note.aliases) do
      if alias ~= title then
        title_to_notes[alias] = title_to_notes[alias] or {}
        table.insert(title_to_notes[alias], note)
      end
    end
  end

  for title, notes_share_title in pairs(title_to_notes) do
    title_to_notes[title] = util.tbl_unique(notes_share_title)
  end

  return title_to_notes
end

---@param client obsidian.Client
return function(client)
  local picker = client:picker()
  if not picker then
    log.err "No picker configured"
    return
  end

  client:find_notes_async("", function(notes)
    local title_to_notes = map_title_to_notes(notes)
    vim.schedule(function()
      picker:pick(vim.tbl_keys(title_to_notes), {
        prompt_title = "Titles",
        callback = function(title)
          local selected_notes = title_to_notes[title]
          if #selected_notes == 1 then
            util.open_buffer(selected_notes[1].path)
          else
            local entries = vim.tbl_map(convert_note_to_picker_entry, selected_notes)
            vim.schedule(function()
              picker:pick(entries, {
                prompt_title = title,
                callback = function(value)
                  util.open_buffer(value.path)
                end,
              })
            end)
          end
        end,
      })
    end)
  end)
end
