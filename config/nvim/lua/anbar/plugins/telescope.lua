return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-live-grep-args.nvim",
      "nvim-telescope/telescope-ui-select.nvim",
      "nvim-telescope/telescope-project.nvim",
      "nvim-telescope/telescope-symbols.nvim",
      "nvim-telescope/telescope-fzf-native.nvim",
      "nvim-telescope/telescope-media-files.nvim",
    },
    config = function()
      local telescope = require("telescope")
      local actions = require("telescope.actions")
      telescope.setup({
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown({}),
          },
        },
        defaults = {
          mappings = {
            i = {
              ["<C-k>"] = actions.move_selection_previous,
              ["<C-j>"] = actions.move_selection_next,
              ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
            },
          },
          file_ignore_patterns = {
            "node_modules",
            "yarn.lock",
            ".git",
            ".sl",
            "_build",
            ".next",
          },
          hidden = true,
        },
      })
      require("telescope").load_extension("live_grep_args")
      require("telescope").load_extension("ui-select")
      require("telescope").load_extension("project")
      require("telescope").load_extension("fzf")
      require("telescope").load_extension("media_files")
    end,
    keys = {
      {
        "<leader>ff",
        "<cmd>lua require('telescope.builtin').find_files(require('telescope.themes').get_dropdown({previewer = false }))<CR>",
        desc = "Find file",
      },
      {
        "<leader>fb",
        ":Telescope file_browser<CR>",
        desc = "File browser",
      },
      {
        "<leader>fg",
        ":Telescope live_grep_args<CR>",
        desc = "Live grep with args",
      },
      {
        "<leader>fs",
        "<cmd>lua require('telescope.builtin').symbols(require('telescope.themes').get_dropdown({previewer = true }))<CR>",
        desc = "Insert symbols",
      },
      {
        "<leader>fs",
        "<cmd>lua require('telescope.builtin').symbols(require('telescope.themes').get_dropdown({previewer = true }))<CR>",
        desc = "Insert symbols",
      },
      {
        "<leader>ft",
        ":TodoTelescope<CR>",
        desc = "Show todos list",
      },
      {
        "<leader>fc",
        ":Telescope neoclip<CR>",
        desc = "Show todos list",
      },
    },
  },
  {
    "AckslD/nvim-neoclip.lua",
    dependencies = {
      { "nvim-telescope/telescope.nvim" },
    },
    config = function()
      require("neoclip").setup()
    end,
  },
  {
    "nvim-telescope/telescope-file-browser.nvim",
    dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
    config = function()
      require("telescope").load_extension("file_browser")
    end,
  },
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = "make",
  },
}
