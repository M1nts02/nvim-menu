local M = {}

local function get_flag(flag)
  if flag == nil then
    return " "
  end

  local result = flag
  if type(flag) == "function" then
    result = flag()
  end

  if type(result) == "string" then
    return result
  elseif type(result) == "boolean" then
    return result and "✔︎" or " "
  end
  return " "
end

local function field_format(config, item, flag)
  local format = config.format
  local desc_len = config.max_desc_width
  local key_len = config.max_key_width
  local flag_len = config.flag_len
  local line = ""

  line = string.gsub(format, "${KEY}", function()
    return string.format("%-" .. key_len .. "s", item[1].key)
  end)

  line = string.gsub(line, "${FLAG}", function()
    return string.format("%-" .. flag_len .. "s", flag)
  end)

  line = string.gsub(line, "${DESC}", function()
    return string.format("%-" .. desc_len .. "s", item[1].desc)
  end)

  return line
end

local function get_width(config, item, flag)
  local line = field_format(config, item, flag)
  return #line
end

-- Highlight ${KEY}, ${FLAG}, ${DESC} variables in specified lines
local function highlight_lines(bufnr, lines, config, start_line)
  -- Create namespace
  local ns_id = vim.api.nvim_create_namespace "nvim-menu-highlight"

  -- Clear previous highlights
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

  -- Get format configuration
  local format = config.format
  local desc_len = config.max_desc_width
  local key_len = config.max_key_width
  local flag_len = config.flag_len

  -- Add highlights for each line
  for line_idx, item in ipairs(lines) do
    if item[1].hidden ~= true then
      local flag = get_flag(item[1].flag)

      -- Replicate field_format logic to precisely calculate positions
      local current_pos = 1
      local i = 1

      while i <= #format do
        if string.sub(format, i, i + 5) == "${KEY}" then
          -- KEY part
          local key_text = string.format("%-" .. key_len .. "s", item[1].key)
          -- Add KEY highlight
          vim.api.nvim_buf_add_highlight(
            bufnr,
            ns_id,
            "NvimMenuKey",
            start_line + line_idx - 1,
            current_pos - 1,
            current_pos + #key_text - 1
          )
          current_pos = current_pos + #key_text
          i = i + 6
        elseif string.sub(format, i, i + 6) == "${FLAG}" then
          -- FLAG part
          local flag_text = string.format("%-" .. flag_len .. "s", flag)
          -- Add FLAG highlight
          vim.api.nvim_buf_add_highlight(
            bufnr,
            ns_id,
            "NvimMenuFlag",
            start_line + line_idx - 1,
            current_pos - 1,
            current_pos + #flag_text - 1
          )
          current_pos = current_pos + #flag_text
          i = i + 7
        elseif string.sub(format, i, i + 6) == "${DESC}" then
          -- DESC part
          local desc_text = string.format("%-" .. desc_len .. "s", item[1].desc)
          -- Add DESC highlight
          vim.api.nvim_buf_add_highlight(
            bufnr,
            ns_id,
            "NvimMenuDesc",
            start_line + line_idx - 1,
            current_pos - 1,
            current_pos + #desc_text - 1
          )
          current_pos = current_pos + #desc_text
          i = i + 7
        else
          -- Regular text, record start position
          local text_start = current_pos
          -- Find end position of continuous regular text
          while
            i <= #format
            and string.sub(format, i, i + 5) ~= "${KEY}"
            and string.sub(format, i, i + 6) ~= "${FLAG}"
            and string.sub(format, i, i + 6) ~= "${DESC}"
          do
            i = i + 1
            current_pos = current_pos + 1
          end
          -- Add highlight for regular text
          if current_pos > text_start then
            vim.api.nvim_buf_add_highlight(
              bufnr,
              ns_id,
              "NvimMenuNormal",
              start_line + line_idx - 1,
              text_start - 1,
              current_pos - 1
            )
          end
        end
      end
    end
  end
end

function M.create(menu)
  local buf_id = vim.api.nvim_create_buf(true, true)
  -- vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf_id })
  vim.api.nvim_set_option_value("modifiable", true, { buf = buf_id })
  local width = get_width(menu.config, menu.items[1], string.format("%-" .. menu.config.flag_len .. "s", " "))

  local lines = {}
  local visible_items = {}
  for k, v in pairs(menu.items) do
    if v[1].hidden ~= true then
      local flag = get_flag(v[1].flag)
      local line = field_format(menu.config, v, flag)
      table.insert(lines, line)
      table.insert(visible_items, v)
    end
  end
  vim.api.nvim_buf_set_lines(buf_id, 0, -1, true, lines)

  -- 应用高亮
  highlight_lines(buf_id, visible_items, menu.config, 0)

  return buf_id, width
end

function M.update(buf_id, menu)
  vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, {})

  local lines = {}
  local visible_items = {}
  for k, v in pairs(menu.items) do
    if v[1].hidden ~= true then
      local flag = get_flag(v[1].flag)
      local line = field_format(menu.config, v, flag)
      table.insert(lines, line)
      table.insert(visible_items, v)
    end
  end
  vim.api.nvim_buf_set_lines(buf_id, 0, -1, true, lines)

  -- 应用高亮
  highlight_lines(buf_id, visible_items, menu.config, 0)
end

function M.delete_buffer(buf_id)
  if buf_id == nil then
    return nil
  end

  if vim.api.nvim_buf_is_valid(buf_id) and type(buf_id) == "number" then
    pcall(vim.api.nvim_buf_delete, buf_id, { force = true })
  end
end

return M
