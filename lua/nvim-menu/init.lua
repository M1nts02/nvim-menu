local M = {}
local window = require "nvim-menu.window"
local buffer = require "nvim-menu.buffer"

-- Define highlight groups
local function define_highlights()
  -- Check and set default highlight groups, only if not defined
  local function set_default_hl(group, link_to)
    -- Try to get current highlight group settings
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
    -- Check if highlight group exists and contains actual highlight properties
    if not ok or not hl or vim.tbl_isempty(hl) then
      -- If highlight group doesn't exist or is undefined, set default link
      vim.api.nvim_set_hl(0, group, { link = link_to, default = true })
    end
  end

  -- Set default highlight groups for various components
  set_default_hl("NvimMenuKey", "Keyword")
  set_default_hl("NvimMenuDesc", "Normal")
  set_default_hl("NvimMenuFlag", "String")
  -- Set default highlight group for normal text
  set_default_hl("NvimMenuNormal", "Normal")
end

-- Define highlight groups on initialization
define_highlights()

local Menu = {
  menus = {},
  menu_stack = {}, -- Stack to keep track of all open menus
  helper_stack = {}, -- Stack to keep track of all open helpers
}

-- Helper function to create a new status table
local function create_status(name, buf_id, win_id, config)
  return {
    name = name,
    buf_id = buf_id,
    win_id = win_id,
    config = vim.deepcopy(config or {}),
  }
end

-- Get current menu status (top of menu stack)
local function get_current_menu_status()
  return Menu.menu_stack[#Menu.menu_stack] or nil
end

-- Get current helper status (top of helper stack)
local function get_current_helper_status()
  return Menu.helper_stack[#Menu.helper_stack] or nil
end

-- Get current status based on type
local function get_current_status(menu_type)
  if menu_type == "menu" then
    return get_current_menu_status()
  elseif menu_type == "helper" then
    return get_current_helper_status()
  end
  -- Default to menu if type not specified
  return get_current_menu_status()
end

local function find_menu_by_name(menu_name)
  -- Search in menu_stack
  for i, menu in ipairs(Menu.menu_stack) do
    if menu.name == menu_name then
      return "menu", Menu.menu_stack, i
    end
  end
  -- Search in helper_stack
  for i, helper in ipairs(Menu.helper_stack) do
    if helper.name == menu_name then
      return "helper", Menu.helper_stack, i
    end
  end
  return nil, nil, nil
end

local function quit(param)
  local stack, index, is_by_name
  local menu_type = "menu" -- Default to menu

  -- Determine if param is a menu name or menu type
  if type(param) == "string" then
    -- Try to find by name first
    local found_type, found_stack, found_index = find_menu_by_name(param)
    if found_stack then
      -- Found by name
      menu_type = found_type
      stack = found_stack
      index = found_index
      is_by_name = true
    else
      -- If not found by name, treat as menu type
      menu_type = param
      stack = menu_type == "menu" and Menu.menu_stack or Menu.helper_stack
      index = #stack
      is_by_name = false
    end
  else
    -- Default to current menu if param is not provided or invalid
    stack = Menu.menu_stack
    index = #stack
    is_by_name = false
  end

  local current = stack[index]
  if not current then
    return
  end

  -- Delete current menu/helper's buffer and window
  buffer.delete_buffer(current.buf_id)
  window.exit_window(current.win_id)

  -- Remove current menu/helper from stack
  table.remove(stack, index)

  -- If there are items left in the stack and we're not closing a specific menu by name,
  -- reopen the previous one (the new top of the stack)
  if #stack > 0 and not is_by_name then
    local previous = stack[#stack]
    -- Reopen the previous menu/helper
    previous.buf_id, previous.config.width = buffer.create(Menu.menus[previous.name])
    previous.win_id = window.open_window(previous.buf_id, previous.config)
    vim.api.nvim_command "redraw"
  end
end

local function open_menu(name, opt)
  -- Get menu configuration
  local menu_config = vim.deepcopy(Menu.menus[name].config)

  -- Create new status and add to stack
  local buf_id, width = buffer.create(Menu.menus[name])
  menu_config.width = width

  -- Apply options
  for i, v in pairs(opt or {}) do
    menu_config[i] = v
  end

  local win_id = window.open_window(buf_id, menu_config)
  vim.api.nvim_command "redraw"

  -- Create and push status to menu stack
  local status = create_status(name, buf_id, win_id, menu_config)
  table.insert(Menu.menu_stack, status)

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
        loop = not (item[1].quit == nil and menu_config.quit or item[1].quit)

        -- if quit = true
        if loop == false then
          quit()
          if item[2] ~= nil and type(item[2]) == "function" then
            item[2]()
          end
          return

        -- if quit = false
        else
          item[2]()
          -- Update current menu's buffer
          local current = get_current_status "menu"
          if current and current.buf_id == buf_id then
            buffer.update(current.buf_id, Menu.menus[name])
            vim.api.nvim_command "redraw"
          end
        end

      -- if not define keymap
      elseif menu_config.foreign_keys == true then
        loop = not menu_config.quit

        local current_window_id = vim.api.nvim_get_current_win()
        vim.api.nvim_win_call(current_window_id, function()
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, false, true), "n", true)
        end)

        if loop == true then
          -- Reopen current menu
          M.open(name, opt)
          return
        end
      else
        loop = not menu_config.quit
      end
    end

    quit()
  end)
end

local function open_helper(name, opt)
  -- Get helper configuration
  local helper_config = vim.deepcopy(Menu.menus[name].config)

  -- Create new status and add to stack
  local buf_id, width = buffer.create(Menu.menus[name])
  helper_config.width = width

  -- Apply options
  for i, v in pairs(opt or {}) do
    helper_config[i] = v
  end

  local win_id = window.open_window(buf_id, helper_config)
  vim.api.nvim_command "redraw"

  -- Create and push status to helper stack
  local status = create_status(name, buf_id, win_id, helper_config)
  table.insert(Menu.helper_stack, status)
end

function M.open(name, opt)
  opt = opt or {}
  opt.type = opt.type or Menu.menus[name].config.type

  if opt.type == "menu" then
    open_menu(name, opt)
  elseif opt.type == "helper" then
    open_helper(name, opt)
  end
end

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
    if v[1].hidden ~= true then
      count = count + 1
    end

    -- get keys index
    menu.key_list[v[1].key] = k
  end

  menu.config.count = count
  menu.config.max_desc_width = max_desc_width
  menu.config.max_key_width = max_key_width

  Menu.menus[name] = menu
end

function M.close(menu_name)
  -- If menu_name is provided, close by name
  if menu_name then
    quit(menu_name)
  else
    -- Default to closing the current menu if no name is provided
    quit "menu"
  end
end

function M.quit_menu()
  -- For backward compatibility, quit current menu
  quit "menu"
end

function M.quit_helper()
  -- For backward compatibility, quit current helper
  quit "helper"
end

function M.refresh(menu_type)
  menu_type = menu_type or "menu"
  local current = get_current_status(menu_type)
  if current then
    local name = current.name

    buffer.update(current.buf_id, Menu.menus[name])
    window.exit_window(current.win_id)
    current.win_id = nil

    M.open(name, current.config)
  end
end

function M.refresh_menu()
  M.refresh "menu"
end

function M.refresh_helper()
  M.refresh "helper"
end

function M.get_status(menu_type)
  menu_type = menu_type or "menu"
  local res = {}
  local current = get_current_status(menu_type)
  if current then
    res.enabled = true
    res.stack_size = menu_type == "menu" and #Menu.menu_stack or #Menu.helper_stack
    res.current = current
    for i, v in pairs(current) do
      res[i] = v
    end
  else
    res.enabled = false
    res.stack_size = 0
  end
  return res
end

return M
