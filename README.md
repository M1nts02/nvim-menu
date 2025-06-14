# nvim-menu

A neovim plugin for create menu, inspired by [hydra](https://github.com/anuvyklack/hydra.nvim)

## Example

<details>
<summary>Menu</summary>

```lua
-- lazy.nvim
require("lazy").setup({
  {
  "M1nts02/nvim-menu",
  keys = {
    {
      "\\",
      function()
        require("nvim-menu").open "Menu"
      end,
      desc = "Menu",
    },
  },
  config = function()
    local menu = require "nvim-menu"
    menu.add("Menu", {
      config = {
        -- format for list
        format = "${FLAG} [${KEY}] ${DESC}",

        -- flag's length
        flag_len = 1,

        -- quit with once key
        quit = false,

        -- don't get unbind key
        foreign_keys = false,

        -- CC: Center,Center
        -- BR: Buttom,Right
        -- TL: Top,Left
        position = "CC",

        -- menu: normal menu
        -- helper: a helper window without keybinds
        type = "menu",
      },
      items = {
        {
          key = "p",
          desc = "Auto pairs",
          flag = function()
            local s = not get_status().g.minipairs_disable
            return s
          end,
        },
        function()
          local s = not get_status().g.minipairs_disable
          update { g = { minipairs_disable = s } }
        end,
        },
        {
          {
            key = "l",
            desc = "Status line",
            quit = true,
            flag = function()
              local s = vim.o.laststatus
              return tostring(s)
            end,
          },
          function()
            menu.open "Status line"
          end,
        },
      },
    })

    menu.add("Status line", {
      config = {
        foreign_keys = true,
        window = {
          position = "CC",
        },
      },
      items = {
        {
          {
            key = "1",
            desc = "Status line 1",
            flag = function()
              local s = vim.o.laststatus == 1
              if s then
                return true
              else
                return false
              end
            end,
          },
          function()
            vim.o.laststatus = 1
          end,
        },
        {
          {
            key = "2",
            desc = "Status line 2",
            flag = function()
              local s = vim.o.laststatus == 2
              if s then
                return true
              else
                return false
              end
            end,
          },
          function()
            vim.o.laststatus = 2
          end,
        },
        {
          {
            key = "3",
            desc = "Status line 3",
            flag = function()
              local s = vim.o.laststatus == 3
              if s then
                return true
              else
                return false
              end
            end,
          },
          function()
            vim.o.laststatus = 3
          end,
        },
        {
          {
            key = "0",
            desc = "Status line 0",
            flag = function()
              local s = vim.o.laststatus == 0
              if s then
                return true
              else
                return false
              end
            end,
          },
          function()
            vim.o.laststatus = 0
          end,
        },
      },
    })
  end,
  }
})
```

</details>

<details>
<summary>Helper(I use it with [debugmaster](https://github.com/miroshQa/debugmaster.nvim))</summary>

```lua
-- lazy.nvim
require("lazy").setup({
  {
  "M1nts02/nvim-menu",
  dependencies = {
    "miroshQa/debugmaster.nvim",
  },
  keys = {
    {
      "<Space>d",
      function()
        local dm = require "debugmaster"
        local menu = require "nvim-menu"
        dm.mode.toggle()
        if require("debugmaster.debug.mode").is_active() then
          menu.open "Debug"
        else
          menu.close()
        end
      end,
      desc = "Debugmaster",
    },
  },
  config = function()
    local menu = require "nvim-menu"

    menu.add("Debug", {
      config = {
        format = "${KEY} ${DESC}",
        position = "RB",
        type = "helper",
        quit = false,
      },
      items = {
        { { key = "t", desc = "Breakpoint" } },
        { { key = "H", desc = "Help" } },
        { { key = "u", desc = "Side panel" } },
        { { key = "c", desc = "Start" } },
        { { key = "o", desc = "Step over" } },
        { { key = "m", desc = "Step into" } },
        { { key = "q", desc = "Step out" } },
        { { key = "r", desc = "Run to cursor" } },
      },
    })

  end,
  }
})
```

</details>
