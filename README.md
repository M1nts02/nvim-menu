# nvim-menu

A neovim plugin for create menu, inspired by [hydra](https://github.com/anuvyklack/hydra.nvim)

## Example

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
        -- format = "${FLAG} [${KEY}] ${DESC}",
        -- flag_len = 1,
        quit = false,
        foreign_keys = false,
        window = {
          position = "CC",
        },
      },
      items = {
        {
          "c",
          function()
            local enable = (vim.g.cmp_disable == false and vim.b.cmp_disable == false) and true or false
            if enable then
              vim.g.cmp_disable = true
              vim.b.cmp_disable = true
            else
              vim.g.cmp_disable = false
              vim.b.cmp_disable = false
            end
          end,
          {
            desc = "Auto Completion",
            flag = function()
              local enable = (vim.g.cmp_disable == false and vim.b.cmp_disable == false) and true or false
              if enable then
                return true
              else
                return false
              end
            end,
          },
        },
        {
          "l",
          function()
            menu.open "Status line"
          end,
          {
            desc = "Status line",
            quit = true,
            flag = function()
              local s = vim.o.laststatus
              return tostring(s)
            end,
          },
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
          "1",
          function()
            vim.o.laststatus = 1
          end,
          {
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
        },
        {
          "2",
          function()
            vim.o.laststatus = 2
          end,
          {
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
        },
        {
          "3",
          function()
            vim.o.laststatus = 3
          end,
          {
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
        },
        {
          "0",
          function()
            vim.o.laststatus = 0
          end,
          {
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
        },
      },
    })
  end,
  }
})
```
