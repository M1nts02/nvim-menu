local M = {}
local window = require "nvim-menu.window"
local buffer = require "nvim-menu.buffer"

local Menu = {
  menus = {},
  status = {
    name = nil,
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
  Status.name = nil
  Status.config = {}
end

-- TODO: open menu
local function open_menu(name, opt)
  if Status.buf_id == nil then
    Status.buf_id, Status.config.width = buffer.create(Menu.menus[name])
  end

  for i, v in pairs(Menu.menus[name].config) do
    Status.config[i] = Status.config[i] or v
  end

  Status.win_id = window.open_window(Status.buf_id, Status.config)
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
        loop = not (item[1].quit == nil and Status.config.quit or item[1].quit)

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
      elseif Status.config.foreign_keys == true then
        loop = not Status.config.quit

        local current_window_id = vim.api.nvim_get_current_win()
        vim.api.nvim_win_call(current_window_id, function()
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, false, true), "n", true)
        end)

        if loop == true then
          window.exit_window(Status.win_id)
          Status.win_id = nil
          M.open(name, opt)
          return
        end
      else
        loop = not Status.config.quit
      end
    end

    quit()
  end)
end

-- TODO: open helper
local function open_helper(name, opt)
  if Status.buf_id == nil then
    Status.buf_id, Status.config.width = buffer.create(Menu.menus[name])
  end

  for i, v in pairs(Menu.menus[name].config) do
    Status.config[i] = Status.config[i] or v
  end

  Status.win_id = window.open_window(Status.buf_id, Status.config)
  vim.api.nvim_command "redraw"
end

function M.open(name, opt)
  opt = opt or {}
  opt.type = opt.type or Menu.menus[name].config.type
  vim.notify("opt" .. opt.type)

  for i, v in pairs(opt) do
    Status.config[i] = v
  end

  Status.name = name
  if opt.type == "menu" then
    open_menu(name, opt)
  elseif opt.type == "helper" then
    open_helper(name, opt)
  end
end

-- TODO: add menu
function M.add(name, menu)
  menu.config.flag_len = menu.config.flag_len == nil and 1 or menu.config.flag_len
  menu.config.format = menu.config.format == nil and "[${KEY}] ${DESC} ${FLAG}" or menu.config.format
  menu.config.quit = menu.config.quit == nil and true or menu.config.quit
  menu.config.type = menu.config.type or "menu"
  menu.foreign_keys = menu.foreign_keys == nil and false or menu.foreign_keys
  menu.key_list = {}

  local max_desc_width = 0
  local max_key_width = 0
  local count = 0
  for k, v in pairs(menu.items) do
    -- get height and width
    local desc_width = #v[1].desc
    local key_width = #v[1].key
    max_desc_width = desc_width > max_desc_width and desc_width or max_desc_width
    max_key_width = key_width > max_key_width and key_width or max_key_width
    count = count + 1

    -- get keys index
    menu.key_list[v[1].key] = k
  end

  menu.config.count = count
  menu.config.max_desc_width = max_desc_width
  menu.config.max_key_width = max_key_width

  Menu.menus[name] = menu
end

-- TODO: close helper
function M.close()
  quit()
end
-- TODO: refresh helper
function M.refresh()
  if Status.buf_id ~= nil then
    local name = Status.name

    buffer.update(Status.buf_id, Menu.menus[name])
    window.exit_window(Status.win_id)
    Status.win_id = nil

    M.open(name, Status.config)
  end
end

-- TODO: get current status
function M.get_status()
  local res = {}
  if Status.buf_id ~= nil then
    res.enabled = true
    for i, v in pairs(Status) do
      res[i] = v
    end
  else
    res.enabled = false
  end
  return res
end

return M
