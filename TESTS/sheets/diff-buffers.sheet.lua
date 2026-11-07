-- Live check: :DiffBuffers and :DiffClear, section 11 (task diff.nvim/manual-checklist-run; ALL/manual-test-checklists/diff.md).
return {
  id = "diff.buffers",
  title = "diff.nvim: :DiffBuffers lists the other listed buffers, :DiffClear closes its own windows and no others",
  task = "diff.nvim/manual-checklist-run",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      require("diff").setup(_G.NO_PICKERS)
      _G.sandbox()
      _G.write("a.txt", { "one", "two" })
      _G.write("b.txt", { "one", "TWO" })
      _G.write("c.txt", { "ONE", "two" })
      _G.write("unlisted.txt", { "not offered" })
      _G.open("c.txt")
      _G.open("b.txt")
      _G.open("a.txt")
      local u = vim.fn.bufadd("unlisted.txt")
      vim.fn.bufload(u)
      vim.bo[u].buflisted = false]],
    },
    { keys = ":DiffBuffers<CR>" },
    { wait = [[_G.dialog("b.txt")]], note = "the picker" },
    {
      expect = [[_G.dialog("c.txt") and not _G.dialog("a.txt")]],
      note = "the other buffers, not the current one",
    },
    { expect = [[not _G.dialog("unlisted.txt")]], note = "listed ones only" },
    { keys = "<Esc>" },
    { wait = [[_G.noted("[diff] Diff cancelled")]] },
    { expect = [[#_G.diffwins() == 0]] },

    { keys = ":DiffBuffers<CR>" },
    { wait = [[_G.dialog("b.txt")]] },
    { keys = "<CR>", note = "pick the first" },
    { wait = [[#_G.diffwins() == 2]] },
    {
      expect = [[vim.wo[vim.fn.bufwinid("a.txt")].diff]],
      note = "the current buffer is the source",
    },
    { lua = [[_G.only(); _G.open("a.txt")]] },

    -- Several diffs at once, and a window of nobody's: `tabnew` keeps them apart.
    { keys = ":Diff target=b.txt<CR>" },
    { wait = [[#_G.diffwins() == 2]] },
    { lua = [[vim.cmd("tabnew c.txt"); vim.cmd("split")]] },
    { keys = ":DiffOrig<CR>" },
    {
      wait = [[#_G.diffwins() == 2 and _G.buf_named("[DiffOrig]") ~= nil]],
      note = "a second diff",
    },
    { expect = [[#vim.api.nvim_list_tabpages() == 2]] },
    { keys = ":DiffClear<CR>" },
    {
      wait = [[_G.buf_named("[DiffOrig]") == nil and _G.buf_named("[Diff:target]") == nil]],
      note = "all closed",
    },
    {
      expect = [[vim.iter(vim.api.nvim_list_wins()):all(function(w) return not vim.wo[w].diff end)]],
      note = "diffmode off everywhere",
    },
    {
      expect = [[#vim.fn.win_findbuf(vim.fn.bufnr("c.txt")) >= 1 and #vim.fn.win_findbuf(vim.fn.bufnr("a.txt")) >= 1]],
      note = "unrelated windows stay",
    },
  },
  manual = {
    "With pickers.nvim and use_pickers_nvim = true: bare :Diff, <Esc> in a real engine: the cancel toast may be absent, the command has not hung",
  },
}
