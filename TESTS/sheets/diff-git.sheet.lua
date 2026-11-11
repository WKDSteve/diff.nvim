-- Live check: git:{rev} specifiers, section 3 (task diff.nvim/manual-checklist-run; ALL/manual-test-checklists/diff.md).
return {
  id = "diff.git",
  feature = "diff.git",
  title = "diff.nvim: git:{rev} leaves the work tree alone, a range is two revisions, a rename fails until the path is given",
  task = "diff.nvim/manual-checklist-run",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      require("diff").setup(_G.NO_PICKERS)
      _G.history_repo()
      _G.write("a.txt", { "alpha", "beta", "uncommitted", "gamma", "delta" })
      _G.status = _G.git({ "status", "--porcelain" })
      _G.head = _G.git({ "rev-parse", "HEAD" })
      _G.open("a.txt")]],
    },
    { keys = ":Diff target=git:HEAD<CR>" },
    { wait = [[#_G.diffwins() == 2]], note = "the diff" },
    {
      expect = [[_G.has(_G.text(_G.buf_named("[Diff:target]")), "version 5")]],
      note = "the last commit",
    },
    { expect = [[_G.has(_G.status, " M a.txt")]], note = "really uncommitted" },
    {
      expect = [[_G.git({ "status", "--porcelain" }) == _G.status and _G.git({ "rev-parse", "HEAD" }) == _G.head]],
      note = "nothing checked out, nothing stashed",
    },
    { expect = [[vim.fn.readfile("a.txt")[3] == "uncommitted"]], note = "the file untouched" },
    { lua = [[_G.only(); _G.open("a.txt")]] },

    { keys = ":Diff target=git:HEAD~3..HEAD~1<CR>", note = "no source= needed" },
    { wait = [[_G.buf_named("[Diff:source]") ~= nil and _G.buf_named("[Diff:target]") ~= nil]] },
    { expect = [[_G.has(_G.text(_G.buf_named("[Diff:source]")), "version 2")]], note = "HEAD~3" },
    { expect = [[_G.has(_G.text(_G.buf_named("[Diff:target]")), "version 4")]], note = "HEAD~1" },
    { expect = [[#_G.diffwins() == 2]], note = "both sides scratch, in diffmode" },
    { lua = [[_G.only()]] },

    -- The rename: no path-following.
    { lua = [[_G.open("new.txt")]] },
    { keys = ":Diff target=git:HEAD~2<CR>", note = "a commit from before the rename" },
    { wait = [[_G.noted("new.txt")]], note = "an error that names it" },
    {
      expect = [[#_G.wins() == 1 and #_G.diffwins() == 0 and not _G.buf_named("[Diff:target]")]],
      note = "no diff",
    },
    { lua = [[_G.only(); _G.open("new.txt")]] },

    { keys = ":Diff target=git:HEAD~2:old.txt<CR>", note = "the old path, explicit" },
    { wait = [[_G.buf_named("[Diff:target]") ~= nil and #_G.diffwins() == 2]] },
    {
      expect = [[_G.has(_G.text(_G.buf_named("[Diff:target]")), "changed in c2")]],
      note = "the old file at that commit",
    },
    { expect = [[vim.wo[vim.fn.bufwinid("new.txt")].diff]], note = "against the current buffer" },
  },
}
