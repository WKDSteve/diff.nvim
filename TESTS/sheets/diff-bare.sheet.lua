-- Live check: bare :Diff, section 1 (task diff.nvim/manual-checklist-run; ALL/manual-test-checklists/diff.md).
return {
  id = "diff.bare",
  title = "diff.nvim: bare :Diff asks with ui.kit, a file or a buffer number opens the diff, a range is the source",
  task = "diff.nvim/manual-checklist-run",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      require("diff").setup(_G.NO_PICKERS)
      _G.sandbox()
      _G.write("a.txt", { "one", "two", "three", "four" })
      _G.write("b.txt", { "one", "TWO", "three", "FOUR" })
      _G.open("a.txt")]],
    },
    { keys = ":Diff<CR>" },
    { wait = [[_G.dialog("clipboard")]], note = "the kit's button row" },
    {
      expect = [[_G.dialog("file path") and _G.dialog("buffer number") and not _G.dialog("git:")]],
      note = "three entries, no revision",
    },
    { keys = "<Esc>", note = "cancel" },
    { wait = [[_G.noted("[diff] Diff cancelled")]] },
    { expect = [[#_G.wins() == 1 and #_G.diffwins() == 0]], note = "nothing opened" },

    { lua = [[_G.forget()]] },
    { keys = ":Diff<CR>" },
    { wait = [[_G.dialog("clipboard")]] },
    { input = "f", note = "file path ..." },
    { wait = [[vim.fn.mode() == "i"]], note = "the input prompt" },
    { expect = [[vim.api.nvim_win_get_config(0).relative ~= ""]] },
    { input = "b.txt<CR>" },
    { wait = [[#_G.diffwins() == 2]], note = "the diff" },
    {
      expect = [[#_G.wins() == 2 and vim.fn.winlayout()[1] == "row"]],
      note = "output=buffer, view=vsplit",
    },
    {
      expect = [[_G.buf_named("a.txt") ~= nil and vim.bo[_G.buf_named("a.txt")].buftype == "" and vim.wo[vim.fn.bufwinid("a.txt")].diff]],
      note = "the left side is the buffer it started from",
    },
    {
      lua = [[_G.only(); _G.open("a.txt"); _G.other = vim.fn.bufadd("b.txt"); vim.fn.bufload(_G.other)]],
    },

    { keys = ":Diff<CR>" },
    { wait = [[_G.dialog("clipboard")]] },
    { input = "b", note = "buffer number ..." },
    { wait = [[vim.fn.mode() == "i"]] },
    { lua = [[vim.api.nvim_input(_G.other .. "<CR>")]] },
    { wait = [[#_G.diffwins() == 2]], note = "the diff with that buffer" },
    { lua = [[_G.only(); _G.open("a.txt")]] },

    -- A range: only the selection is the source, the target stays whole.
    { keys = "Vj<Esc>", note = "lines 1 and 2" },
    { keys = ":'<,'>Diff target=b.txt<CR>" },
    { wait = [[_G.buf_named("[Diff:source]") ~= nil and _G.buf_named("[Diff:target]") ~= nil]] },
    {
      expect = [[_G.text(_G.buf_named("[Diff:source]")) == "one\ntwo"]],
      note = "selected lines only",
    },
    {
      expect = [[_G.text(_G.buf_named("[Diff:target]")) == "one\nTWO\nthree\nFOUR"]],
      note = "the target in full",
    },
  },
}
