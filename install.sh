#!/usr/bin/env bash
set -e

NVIM_CONFIG="$HOME/.config/nvim"

# 移除已有的 nvim 配置（软链接或目录）
if [ -L "$NVIM_CONFIG" ]; then
  rm "$NVIM_CONFIG"
  echo "已移除旧软链接: $NVIM_CONFIG"
elif [ -d "$NVIM_CONFIG" ]; then
  echo "已存在 $NVIM_CONFIG 目录，请手动备份后删除再运行此脚本"
  exit 1
fi

# 创建目录结构
mkdir -p "$NVIM_CONFIG/lua/plugins"

# 写入 init.lua
cat > "$NVIM_CONFIG/init.lua" << 'EOF'
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "

require("lazy").setup("plugins")
EOF

# 写入插件配置
cat > "$NVIM_CONFIG/lua/plugins/init.lua" << 'EOF'
return {
  -- 主题
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    config = function() vim.cmd.colorscheme("catppuccin") end,
  },

  -- 语法高亮
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = "BufRead",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "lua", "python", "javascript", "typescript", "json", "yaml", "html", "css", "bash", "markdown" },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },

  -- 文件树
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = { { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "文件树" } },
    config = function() require("nvim-tree").setup() end,
  },

  -- 模糊搜索
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "查找文件" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "全局搜索" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "缓冲区" },
    },
  },

  -- 状态栏
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy",
    config = function() require("lualine").setup() end,
  },

  -- LSP
  {
    "neovim/nvim-lspconfig",
    event = "BufRead",
    dependencies = {
      { "williamboman/mason.nvim", config = function() require("mason").setup() end },
      { "williamboman/mason-lspconfig.nvim" },
    },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "pyright" },
      })
      local lspconfig = require("lspconfig")
      lspconfig.lua_ls.setup({
        settings = { Lua = { diagnostics = { globals = { "vim" } } } },
      })
      lspconfig.pyright.setup({})
    end,
  },

  -- 自动补全
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        snippet = {
          expand = function(args) require("luasnip").lsp_expand(args.body) end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
        }, {
          { name = "buffer" },
          { name = "path" },
        }),
      })
    end,
  },

  -- 自动括号
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function() require("nvim-autopairs").setup() end,
  },

  -- Git 标记
  {
    "lewis6991/gitsigns.nvim",
    event = "BufRead",
    config = function() require("gitsigns").setup() end,
  },

  -- 注释
  {
    "numToStr/Comment.nvim",
    keys = { { "gcc", mode = "n" }, { "gc", mode = "v" } },
    config = function() require("Comment").setup() end,
  },
}
EOF

# 安装插件
echo "正在安装插件..."
nvim --headless "+Lazy! sync" +qa

echo "安装完成！启动 nvim 即可使用。"
