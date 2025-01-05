local M = {}

-- TODO
-- local function highhight_lines()
--   local col_start = 0
--   local col_end = -1
--   local end_line = start_line + #lines - 1
--   for line = start_line, end_line do
--     vim.api.nvim_buf_add_highlight(
--       bufnr, ns_id, hl_group, line, col_start, col_end
--     )
--   end
-- end

local function field_format(config, item, flag)
  local format = config.format
  local desc_len = config.max_desc_width
  local key_len = config.max_key_width
  local flag_len = config.flag_len
  local line = ""

  line = string.gsub(format, "${KEY}", function()
    return string.format("%-" .. key_len .. "s", item[1])
  end)

  line = string.gsub(line, "${FLAG}", function()
    return string.format("%-" .. flag_len .. "s", flag)
  end)

  line = string.gsub(line, "${DESC}", function()
    return string.format("%-" .. desc_len .. "s", item[3].desc)
  end)

  return line
end

local function get_width(config, item, flag)
  local line = field_format(config, item, flag)
  return #line
end

local function get_flag(flag)
  if flag == nil then
    return " "
  end

  local result
  if type(flag) == "function" then
    result = flag()
  end

  if type(result) == "string" then
    return result
  elseif type(result) == "boolean" then
    return result and "✔︎" or " "
  end
end

function M.create(menu)
  local buf_id = vim.api.nvim_create_buf(true, true)
  -- vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf_id })
  vim.api.nvim_set_option_value("modifiable", true, { buf = buf_id })
  local width = get_width(menu.config, menu.items[1], string.format("%-" .. menu.config.flag_len .. "s", " "))

  local lines = {}
  for k, v in pairs(menu.items) do
    if v[3].hidden == true then
      goto continue
    end
    local flag = get_flag(v[3].flag)
    local line = field_format(menu.config, v, flag)
    table.insert(lines, line)

    ::continue::
  end
  vim.api.nvim_buf_set_lines(buf_id, 0, -1, true, lines)

  return buf_id, { width = width }
end

function M.update(buf_id, menu)
  vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, {})

  local lines = {}
  for k, v in pairs(menu.items) do
    if v[3].hidden == true then
      goto continue
    end

    local flag = get_flag(v[3].flag)
    local line = field_format(menu.config, v, flag)
    table.insert(lines, line)

    ::continue::
  end
  vim.api.nvim_buf_set_lines(buf_id, 0, -1, true, lines)
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
