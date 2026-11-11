-- Live check: the native views, section 5 (task diff.nvim/manual-checklist-run; ALL/manual-test-checklists/diff.md).
return {
  id = "diff.views",
  feature = "diff.views",
  title = "diff.nvim: view=vsplit, split and tab are native diffmode in their layout, :diffget works in each",
  task = "diff.nvim/manual-checklist-run",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      require("diff").setup(_G.NO_PICKERS)
      _G.sandbox()
      _G.write("a.txt", { "one", "two", "three" })
      _G.write("b.txt", { "one", "TWO", "three" })
      _G.open("a.txt")
      _G.get_and_reset = function()
        vim.api.nvim_set_current_win(vim.fn.bufwinid("a.txt"))
        vim.fn.cursor(2, 1)
      end]],
    },
    { keys = ":Diff target=b.txt view=vsplit<CR>" },
    { wait = [[#_G.diffwins() == 2]] },
    {
      expect = [[vim.fn.winlayout()[1] == "row" and #vim.api.nvim_list_tabpages() == 1]],
      note = "side by side",
    },
    { lua = [[_G.get_and_reset()]] },
    { keys = ":diffget<CR>" },
    {
      expect = [[_G.text(vim.fn.bufnr("a.txt")) == "one\nTWO\nthree"]],
      note = ":diffget in vsplit",
    },
    { keys = "u" },
    { lua = [[_G.only(); _G.open("a.txt")]] },

    { keys = ":Diff target=b.txt view=split<CR>" },
    { wait = [[#_G.diffwins() == 2]] },
    {
      expect = [[vim.fn.winlayout()[1] == "col" and #vim.api.nvim_list_tabpages() == 1]],
      note = "stacked",
    },
    { lua = [[_G.get_and_reset()]] },
    { keys = ":diffget<CR>" },
    {
      expect = [[_G.text(vim.fn.bufnr("a.txt")) == "one\nTWO\nthree"]],
      note = ":diffget in split",
    },
    { keys = "u" },
    { lua = [[_G.only(); _G.open("a.txt")]] },

    { keys = ":Diff target=b.txt view=tab<CR>" },
    { wait = [[#_G.diffwins() == 2]] },
    {
      expect = [[#vim.api.nvim_list_tabpages() == 2 and vim.fn.winlayout()[1] == "row"]],
      note = "a new tab",
    },
    {
      expect = [[#vim.api.nvim_tabpage_list_wins(vim.api.nvim_list_tabpages()[1]) == 1]],
      note = "the old tab is as it was",
    },
    {
      lua = [[vim.fn.win_gotoid(vim.fn.win_findbuf(vim.fn.bufnr("a.txt"))[#vim.fn.win_findbuf(vim.fn.bufnr("a.txt"))]); vim.fn.cursor(2, 1)]],
    },
    { expect = [[vim.wo.diff and vim.api.nvim_buf_get_name(0):find("a.txt", 1, true) ~= nil]] },
    { keys = ":diffget<CR>" },
    { expect = [[_G.text(vim.fn.bufnr("a.txt")) == "one\nTWO\nthree"]], note = ":diffget in tab" },
  },
}
