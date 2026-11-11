-- Live check: directory diff, section 7 (task diff.nvim/manual-checklist-run; ALL/manual-test-checklists/diff.md).
return {
  id = "diff.directory",
  feature = "diff.directory",
  title = "diff.nvim: two directories give a per-file summary without hidden segments; view= is ignored, stat rolls up",
  task = "diff.nvim/manual-checklist-run",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      require("diff").setup(_G.NO_PICKERS)
      _G.sandbox()
      _G.write("d1/same.txt", { "same" })
      _G.write("d2/same.txt", { "same" })
      _G.write("d1/changed.txt", { "one", "two" })
      _G.write("d2/changed.txt", { "one", "TWO", "three" })
      _G.write("d1/gone.txt", { "gone" })
      _G.write("d2/sub/added.txt", { "added", "twice" })
      _G.write("d1/.git/config", { "hidden left" })
      _G.write("d2/.git/config", { "hidden right" })
      _G.write("d2/.hg/store", { "hidden too" })
      _G.write("start.txt", { "x" })
      _G.open("start.txt")]],
    },
    { keys = ":Diff source=d1 target=d2<CR>" },
    { wait = [[_G.buf_named("[DirDiff]") ~= nil]] },
    {
      lua = [[_G.summary = _G.text(_G.buf_named("[DirDiff]"))]],
    },
    {
      expect = [[_G.summary:find("M%s+%+2%s+%-1%s+changed%.txt") ~= nil]],
      note = "M + added - removed + path",
    },
    { expect = [[_G.summary:find("D%s+%+0%s+%-1%s+gone%.txt") ~= nil]] },
    { expect = [[_G.summary:find("A%s+%+2%s+%-0%s+sub/added%.txt") ~= nil]] },
    {
      expect = [[_G.has(_G.summary, "3 files changed, +4 -2") and not _G.summary:find("same.txt", 1, true)]],
    },
    {
      expect = [[not _G.summary:find(".git", 1, true) and not _G.summary:find(".hg", 1, true)]],
      note = "hidden segments are out",
    },
    { expect = [[#_G.diffwins() == 0]], note = "no meaningless diffmode" },
    { lua = [[_G.only(); _G.open("start.txt")]] },

    { keys = ":Diff source=d1 target=d2 view=vsplit<CR>" },
    { wait = [[_G.buf_named("[DirDiff]") ~= nil]], note = "the same summary" },
    { expect = [[#_G.diffwins() == 0 and not _G.noted("view")]], note = "view= silently ignored" },
    { lua = [[_G.only(); _G.open("start.txt"); _G.set_diff({ stat_list = "qf" })]] },

    { keys = ":Diff source=d1 target=d2 output=stat<CR>" },
    { wait = [[_G.noted("3 files changed, +4 -2")]], note = "the roll-up" },
    {
      expect = [[_G.buf_named("[DirDiff]") == nil and #_G.diffwins() == 0]],
      note = "no summary window",
    },
    { expect = [[_G.qf_count() == 3]], note = "one entry per changed file" },
    { expect = [[vim.iter(vim.fn.getqflist()):all(function(e) return e.valid == 1 end)]] },
    { keys = ":cfirst<CR>" },
    { expect = [[vim.fn.expand("%:t") ~= "start.txt"]], note = "it jumps" },
  },
}
