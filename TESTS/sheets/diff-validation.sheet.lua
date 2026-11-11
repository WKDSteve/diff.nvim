-- Live check: typos and contradictions at the command line, section 17 (task diff.nvim/manual-checklist-run; ALL/manual-test-checklists/diff.md).
return {
  id = "diff.validation",
  feature = "diff.validation",
  title = "diff.nvim: an unknown key warns and is ignored, an unknown view or a source= with base= is an error and opens nothing",
  task = "diff.nvim/manual-checklist-run",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      require("diff").setup(_G.NO_PICKERS)
      _G.conflict_repo()
      _G.open("c.txt")]],
    },
    { keys = ":Diff veiw=inline target=git:HEAD<CR>" },
    { wait = [[_G.noted("[diff] Unknown arg key(s): veiw -- ignoring (accepted: ")]] },
    { wait = [[#_G.diffwins() == 2]], note = "the diff still opens" },
    {
      expect = [[vim.bo.filetype ~= "diff" and vim.fn.winlayout()[1] == "row"]],
      note = "with the default view",
    },
    { lua = [[_G.only(); _G.open("c.txt")]] },

    { keys = ":DiffBuffers target=1<CR>" },
    {
      wait = [[_G.noted("Unknown arg key(s): target -- ignoring (accepted: view, output)")]],
      note = "the same warning",
    },
    { lua = [[_G.only(); _G.open("c.txt")]] },

    { keys = ":Diff view=diagonal target=git:HEAD<CR>" },
    { wait = [[_G.noted('Unknown view="diagonal"  (valid: ')]] },
    { expect = [[#_G.wins() == 1 and #_G.diffwins() == 0]], note = "nothing opens" },
    { lua = [[_G.only(); _G.open("c.txt")]] },

    { keys = ":Diff target=git:MERGE_HEAD base=git:HEAD source=clipboard<CR>" },
    {
      wait = [[_G.noted('base= (three-way diff) only supports source=current, got source="clipboard"')]],
    },
    { expect = [[#_G.wins() == 1 and #_G.diffwins() == 0]], note = "no window" },
    { keys = ":Diff target=git:MERGE_HEAD base=git:HEAD source=current<CR>" },
    { wait = [[#_G.diffwins() == 3]], note = "source=current spelled out is accepted" },
  },
}
