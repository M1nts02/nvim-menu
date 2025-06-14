local M = {}

local function get_win_pos(height, width, gheight, gwidth, position)
  local v = position:sub(1, 1)
  local s = position:sub(2, 2)
  local row, col

  if v == "T" then -- top
    row = 1
  elseif v == "C" then -- center
    row = (gheight - height) * 0.5
  else -- buttom
    row = gheight - height - 5
  end

  if s == "L" then -- left
    col = 1
  elseif s == "C" then -- center
    col = (gwidth - width) * 0.5
  else -- right
    col = gwidth - width - 1
  end

  return row, col
end

-- TODO
-- local function check_win_size() end

function M.open_window(buf_id, config)
  local gheight = vim.api.nvim_list_uis()[1].height
  local gwidth = vim.api.nvim_list_uis()[1].width

  local width = config.width
  local height = config.count

  local position = config.position
  position = (position == nil or type(position) ~= "string") and "BR" or position

  local row, col = get_win_pos(height, width, gheight, gwidth, position)

  local win_id = vim.api.nvim_open_win(buf_id, false, {
    anchor = "NW",
    border = "single",
    focusable = false,
    relative = "editor",
    style = "minimal",
    row = row,
    col = col,
    height = height,
    width = width,
    zindex = 99,
  })

  vim.wo[win_id].foldenable = false
  vim.wo[win_id].wrap = false
  vim.wo[win_id].list = true
  vim.wo[win_id].listchars = "extends:…"

  return win_id
end

function M.exit_window(win_id)
  if win_id == nil then
    return
  end

  if type(win_id) == "number" and vim.api.nvim_win_is_valid(win_id) then
    pcall(vim.api.nvim_win_close, win_id, true)
  end
end

return M
