local M = {}
local window = require "nvim-menu.window"
local buffer = require "nvim-menu.buffer"

local Menu = {
  menus = {},
  status = {
    buf_id = nil,
    win_id = nil,
    config = {},
  },
}
local Status = Menu.status

local function quit()
  buffer.delete_buffer(Status.buf_id)
  window.exit_window(Status.win_id)
  Status.buf_id = nil
  Status.win_id = nil
end

-- TODO: open menu
function M.open(name)
  if Status.buf_id == nil then
    Status.buf_id, Status.config = buffer.create(Menu.menus[name])
  end

  Menu.menus[name].config.max_width = Status.config.width
  Status.win_id = window.open_window(Status.buf_id, Menu.menus[name].config)
  vim.api.nvim_command "redraw"

  vim.schedule(function()
    local loop = true
    while loop do
      local key = vim.fn.keytrans(vim.fn.getcharstr())
      local index = Menu.menus[name].key_list[key]
      local item

      -- quit
      if key == "<Esc>" then
        loop = false

      -- run
      elseif index ~= nil then
        item = Menu.menus[name].items[index]
        loop = not (item[3].quit == nil and Menu.menus[name].config.quit or item[3].quit)

        -- if quit = true
        if loop == false then
          quit()
          item[2]()
          return

        -- if quit = false
        else
          item[2]()
          buffer.update(Status.buf_id, Menu.menus[name])
          vim.api.nvim_command "redraw"
        end

      -- if not define keymap
      elseif Menu.menus[name].config.foreign_keys == true then
        loop = not Menu.menus[name].config.quit

        local current_window_id = vim.api.nvim_get_current_win()
        vim.api.nvim_win_call(current_window_id, function()
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, false, true), "n", true)
        end)

        if loop == true then
          window.exit_window(Status.win_id)
          Status.win_id = nil
          M.open(name)
          return
        end
      else
        loop = not Menu.menus[name].config.quit
      end
    end

    quit()
  end)
end

-- TODO: add menu
function M.add(name, menu)
  menu.config.flag_len = menu.config.flag_len == nil and 1 or menu.config.flag_len
  menu.config.format = menu.config.format == nil and "[${KEY}] ${DESC} ${FLAG}" or menu.config.format
  menu.config.quit = menu.config.quit == nil and true or menu.config.quit
  menu.foreign_keys = menu.foreign_keys == nil and false or menu.foreign_keys
  menu.key_list = {}
  menu.window = menu.window == nil and {} or menu.window

  local max_desc_width = 0
  local max_key_width = 0
  local count = 0
  for k, v in pairs(menu.items) do
    -- get height and width
    local desc_width = #v[3].desc
    local key_width = #v[1]
    max_desc_width = desc_width > max_desc_width and desc_width or max_desc_width
    max_key_width = key_width > max_key_width and key_width or max_key_width
    count = count + 1

    -- get keys index
    menu.key_list[v[1]] = k
  end

  menu.config.count = count
  menu.config.max_desc_width = max_desc_width
  menu.config.max_key_width = max_key_width

  Menu.menus[name] = menu
end

-- TODO: get current status
function M.get_status()
  local res = {}
  if Status.buf_id ~= nil then
    res.enabled = true
    res.buf_id = Status.buf_id
    res.foreign_keys = Status.config.foreign_keys
  else
    res.enabled = false
  end
  return res
end

return M
