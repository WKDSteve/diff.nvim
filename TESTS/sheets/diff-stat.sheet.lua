-- Live check: output=stat and its lists, section 2 (task diff.nvim/manual-checklist-run; ALL/manual-test-checklists/diff.md).
return {
  id = "diff.stat",
  title = "diff.nvim: output=stat says +N -M, K hunks without a window; stat_list adds to or replaces a list",
  task = "diff.nvim/manual-checklist-run",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      require("diff").setup(_G.NO_PICKERS)
      _G.history_repo()
      _G.write("b.txt", { "alpha", "CHANGED", "version 5", "gamma", "delta" })
      _G.open("a.txt")]],
    },
    { keys = ":Diff target=git:HEAD~1 output=stat<CR>" },
    { wait = [[_G.noted("+1 -1, 1 hunk")]], note = "version 5 against version 4" },
    { expect = [[_G.noted("buf:") and _G.noted("-> git:HEAD~1")]], note = "<source> -> <target>" },
    { expect = [[#_G.wins() == 1]], note = "no window" },
    {
      expect = [[#_G.diffwins() == 0 and _G.qf_count() == 0]],
      note = "no window, no list by default",
    },

    -- stat_list = "qf": a target with a place of its own gives entries that really jump.
    { lua = [[_G.set_diff({ stat_list = "qf" }); _G.forget()]] },
    { keys = ":Diff target=b.txt output=stat<CR>" },
    { wait = [[_G.qf_count() == 1]], note = "the hunk is in the quickfix list" },
    { expect = [[vim.fn.getqflist()[1].valid == 1 and vim.fn.getqflist()[1].lnum == 1]] },
    { keys = ":cfirst<CR>", note = "jump" },
    {
      expect = [[vim.api.nvim_buf_get_name(0):find("b.txt", 1, true) ~= nil and vim.fn.line(".") == 1]],
    },
    { lua = [[_G.open("a.txt")]] },

    -- stat_list = "loc": the same in the location list of the window.
    { lua = [[vim.fn.setqflist({}, "r"); _G.set_diff({ stat_list = "loc" })]] },
    { keys = ":Diff target=b.txt output=stat<CR>" },
    { wait = [[#vim.fn.getloclist(0) == 1]], note = "the hunk is in the location list" },
    { expect = [[vim.fn.getloclist(0)[1].valid == 1 and _G.qf_count() == 0]] },

    -- Modes: add accumulates on the current list, replace keeps only the latest run.
    {
      lua = [[vim.fn.setqflist({}, "f"); _G.set_diff({ stat_list = "qf", stat_list_mode = "add" })]],
    },
    { keys = ":Diff target=b.txt output=stat<CR>" },
    { wait = [[_G.qf_count() == 1]] },
    { keys = ":Diff target=b.txt output=stat<CR>" },
    { wait = [[_G.qf_count() == 2]], note = "add: both runs" },
    { lua = [[_G.set_diff({ stat_list = "qf", stat_list_mode = "replace" })]] },
    { keys = ":Diff target=b.txt output=stat<CR>" },
    {
      wait = [[vim.fn.getqflist({ nr = "$" }).nr == 2 and _G.qf_count() == 1]],
      note = "replace: a new list, one run",
    },
  },
}
