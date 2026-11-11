-- Live check: the exit key and :DiffExit, section 10 (task diff.nvim/manual-checklist-run; ALL/manual-test-checklists/diff.md).
return {
  id = "diff.exit",
  feature = "diff.exit",
  title = "diff.nvim: <Esc><Esc> leaves a diff of the plugin, a native :diffthis only with native_diffthis; :DiffExit always",
  task = "diff.nvim/manual-checklist-run",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      require("diff").setup(_G.NO_PICKERS)
      _G.sandbox()
      _G.write("a.txt", { "one", "two" })
      _G.write("b.txt", { "one", "TWO" })
      _G.open("a.txt")
      _G.native = function()
        _G.only()
        _G.open("a.txt")
        vim.cmd("diffthis")
        vim.cmd("vsplit b.txt")
        vim.cmd("diffthis")
      end]],
    },
    { keys = ":Diff target=b.txt<CR>" },
    { wait = [[#_G.diffwins() == 2]] },
    { keys = "<Esc><Esc>" },
    { wait = [[#_G.diffwins() == 0]], note = "the key exits diffmode" },

    { keys = ":DiffExit<CR>", note = "outside any diff" },
    { wait = [[_G.noted("[diff] Not in diff mode")]] },

    { lua = [[_G.native()]], note = "a native pair, scope = buffer, no watcher" },
    { expect = [[#_G.diffwins() == 2 and vim.fn.maparg("<Esc><Esc>", "n") == ""]] },
    { keys = "<Esc><Esc>" },
    { lua = "vim.wait(200)" },
    { expect = [[#_G.diffwins() == 2]], note = "the documented gap: nothing happens" },
    { keys = ":DiffExit<CR>" },
    { wait = [[#_G.diffwins() == 0]], note = ":DiffExit works there all the same" },

    {
      lua = [[_G.reload({ use_pickers_nvim = false, exit = { native_diffthis = true } }); _G.native()]],
    },
    { wait = [[vim.fn.maparg("<Esc><Esc>", "n") ~= ""]], note = "the OptionSet watcher bound it" },
    { keys = "<Esc><Esc>" },
    { wait = [[#_G.diffwins() == 0]], note = "with native_diffthis the key works there" },

    { lua = [[_G.reload({ use_pickers_nvim = false, exit = { scope = false } }); _G.native()]] },
    { keys = ":DiffExit<CR>" },
    { wait = [[#_G.diffwins() == 0]], note = ":DiffExit with exit.scope = false" },
  },
}
