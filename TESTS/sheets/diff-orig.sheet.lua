-- Live check: :DiffOrig and :DiffClear, section 6 (task diff.nvim/manual-checklist-run; ALL/manual-test-checklists/diff.md).
return {
  id = "diff.orig",
  feature = "diff.orig",
  title = "diff.nvim: :DiffOrig is a native split whatever default_view says, :DiffClear leaves nothing behind",
  task = "diff.nvim/manual-checklist-run",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      require("diff").setup({ use_pickers_nvim = false, diff = { default_view = "inline" } })
      _G.sandbox()
      _G.write("a.txt", { "saved one", "saved two" })
      _G.open("a.txt")
      vim.api.nvim_buf_set_lines(0, 1, 2, false, { "unsaved two" })]],
    },
    { keys = ":DiffOrig<CR>" },
    {
      wait = [[#_G.diffwins() == 2]],
      note = "native diffmode, default_view = inline does not apply",
    },
    { expect = [[vim.fn.winlayout()[1] == "row"]], note = "a vertical split" },
    {
      expect = [[_G.text(_G.buf_named("[DiffOrig]")) == "saved one\nsaved two"]],
      note = "the saved version",
    },
    {
      expect = [[_G.text(vim.fn.bufnr("a.txt")) == "saved one\nunsaved two"]],
      note = "the edit stays",
    },
    { keys = ":DiffClear<CR>" },
    { wait = [[#_G.diffwins() == 0]], note = "diffmode off in every window" },
    {
      expect = [[_G.buf_named("[DiffOrig]") == nil]],
      note = "the snapshot buffer is gone, hidden or listed",
    },
    { expect = [[#_G.wins() == 1 and _G.has(vim.api.nvim_buf_get_name(0), "a.txt")]] },
  },
}
