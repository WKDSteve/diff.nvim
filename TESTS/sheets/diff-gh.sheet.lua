-- Live check: gh without gitsigns, and who owns the key, section 16 (task diff.nvim/manual-checklist-run; ALL/manual-test-checklists/diff.md).
return {
  id = "diff.gh",
  feature = "diff.gh",
  title = "diff.nvim: gh is the plugin's map and says when gitsigns is missing; an own gh stays; keymaps = false binds nothing",
  task = "diff.nvim/manual-checklist-run",
  requires = {
    {
      lua = "vim.g.diff_sheets_ui_nvim ~= nil",
      reason = "ui.nvim not found by TESTS/minimal_init.lua",
    },
  },
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      require("diff").setup(_G.NO_PICKERS)
      _G.sandbox()
      _G.write("a.txt", { "one", "two" })
      _G.write("b.txt", { "one", "TWO" })
      _G.open("a.txt")]],
    },
    { expect = [[_G.has(vim.fn.execute("verbose nmap gh"), "[diff] Git hunk peek")]] },
    { keys = "gh", note = "no gitsigns on this runtimepath" },
    { wait = [[_G.noted("[diff] Diff peek requires gitsigns.nvim")]], note = "a toast, no error" },

    {
      lua = [[_G.forget()
      vim.keymap.del("n", "gh")
      vim.keymap.set("n", "gh", "<cmd>let g:mine = 1<cr>")
      _G.reload({}, true)]],
    },
    {
      wait = [[_G.noted("'gh' is already mapped -- not installing the gitsigns hunk peek over it")]],
      note = "setup warns",
    },
    { keys = "gh" },
    { expect = [[vim.g.mine == 1]], note = "the own mapping stays" },

    {
      lua = [[_G.forget(); vim.g.mine = nil; _G.reload({ features = { gitsigns_peek = false } }, true)]],
    },
    { lua = "vim.wait(100)" },
    { expect = [[not _G.noted("already mapped")]], note = "no warning" },
    { keys = "gh" },
    { expect = [[vim.g.mine == 1]], note = "the own gh unchanged" },
    { lua = [[vim.keymap.del("n", "gh")]] },

    { lua = [[_G.reload({ use_pickers_nvim = false, keymaps = false })]] },
    { expect = [[vim.fn.maparg("gh", "n") == ""]], note = "no gh" },
    { keys = ":Diff target=b.txt<CR>" },
    { wait = [[#_G.diffwins() == 2]] },
    { expect = [[vim.fn.maparg("<Esc><Esc>", "n") == ""]], note = "no exit key" },
    { keys = ":DiffExit<CR>" },
    { wait = [[#_G.diffwins() == 0]], note = ":DiffExit still works" },
  },
  manual = {
    "With gitsigns.nvim, cursor on a changed hunk in a git file: gh shows gitsigns' inline hunk preview",
  },
}
