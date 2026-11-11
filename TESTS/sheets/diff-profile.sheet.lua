-- Live check: :DiffProfile and diff.diffopt_profile, section 15 (task diff.nvim/manual-checklist-run; ALL/manual-test-checklists/diff.md).
return {
  id = "diff.profile",
  feature = "diff.profile",
  title = "diff.nvim: :DiffProfile replaces 'diffopt' with one of four bundles, a live diff follows, a bad name changes nothing",
  task = "diff.nvim/manual-checklist-run",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      _G.untouched = vim.o.diffopt
      require("diff").setup(_G.NO_PICKERS)
      _G.sandbox()
      _G.write("a.txt", { "one", "two  words", "three" })
      _G.write("b.txt", { "one", "two words", "three" })
      _G.open("a.txt")]],
    },
    { expect = [[vim.o.diffopt == _G.untouched]], note = "no profile configured: left alone" },
    {
      expect = [[vim.deep_equal((function()
        local c = vim.fn.getcompletion("DiffProfile ", "cmdline")
        table.sort(c)
        return c
      end)(), { "context", "minimal", "review", "strict" })]],
      note = "<Tab> completes exactly four",
    },
    { keys = ":DiffProfile minimal<CR>" },
    { wait = [[_G.noted("[diff] diff profile: minimal")]] },
    { lua = [[_G.minimal = vim.o.diffopt; _G.has(_G.minimal, "iwhite")]] },
    { keys = ":DiffProfile context<CR>" },
    { wait = [[_G.noted("[diff] diff profile: context")]] },
    { expect = [[vim.o.diffopt ~= _G.minimal and _G.has(vim.o.diffopt, "algorithm:patience")]] },
    { lua = [[_G.context = vim.o.diffopt]] },
    { keys = ":DiffProfile review<CR>" },
    { wait = [[_G.noted("[diff] diff profile: review")]] },
    { expect = [[vim.o.diffopt ~= _G.context and vim.o.diffopt ~= _G.minimal]] },
    { lua = [[_G.review = vim.o.diffopt]] },
    { keys = ":DiffProfile strict<CR>" },
    { wait = [[_G.noted("[diff] diff profile: strict")]] },
    { expect = [[vim.o.diffopt ~= _G.review and _G.has(vim.o.diffopt, "algorithm:myers")]] },
    {
      expect = [[not vim.o.diffopt:find("iwhite", 1, true)]],
      note = "strict does not ignore whitespace",
    },

    -- A live native diff follows the global option: the whitespace-only line is a change under strict only.
    { keys = ":DiffProfile minimal<CR>" },
    { keys = ":Diff target=b.txt<CR>" },
    { wait = [[#_G.diffwins() == 2]] },
    {
      expect = [[vim.api.nvim_win_call(vim.fn.bufwinid("a.txt"), function() return vim.fn.diff_hlID(2, 1) end) == 0]],
      note = "minimal: no change",
    },
    { keys = ":DiffProfile strict<CR>" },
    {
      wait = [[vim.api.nvim_win_call(vim.fn.bufwinid("a.txt"), function() return vim.fn.diff_hlID(2, 1) end) ~= 0]],
      note = "strict: the line is a change now",
    },
    { lua = [[_G.only(); _G.open("a.txt"); _G.was = vim.o.diffopt]] },

    -- A two-line refusal: room for it instead of a hit-enter prompt.
    { lua = [[vim.o.cmdheight = 3]] },
    { keys = ":DiffProfile nosuch<CR>", ignore_errmsg = true },
    {
      expect = [[_G.has(vim.fn.execute("messages"), "expected one of context|minimal|review|strict")]],
      note = "command-level enum check",
    },
    { expect = [[vim.o.diffopt == _G.was]], note = "a rejection changes nothing" },
    {
      expect = [[not vim.fn.execute("messages"):find("stack traceback", 1, true)]],
      note = "no Lua stack trace",
    },

    -- Options at setup. The reload is a scratch config with this one option.
    {
      lua = [[vim.o.diffopt = _G.untouched; _G.reload({ diff = { diffopt_profile = "review" } })]],
    },
    { expect = [[vim.o.diffopt == _G.review]], note = "the review value right after setup" },

    {
      lua = [[vim.o.diffopt = _G.untouched; _G.forget(); _G.reload({ use_pickers_nvim = false, diff = { diffopt_profile = "nosuch" } })]],
    },
    {
      wait = [[_G.noted('[diff] diff.diffopt_profile = "nosuch"')]],
      note = "the error toast at setup",
    },
    { expect = [[vim.o.diffopt == _G.untouched]] },
    { expect = [[vim.fn.maparg("gh", "n") ~= ""]], note = "gh is there, setup went on" },
    { keys = ":Diff target=b.txt<CR>", note = ":Diff still works" },
    { wait = [[#_G.diffwins() == 2]] },
    { keys = "<Esc><Esc>", note = "the exit key too" },
    { wait = [[#_G.diffwins() == 0]] },
    { lua = [[_G.only(); _G.open("a.txt")]] },

    {
      lua = [[_G.reload({ features = { diffopt_profile = false }, diff = { diffopt_profile = "review" } })]],
    },
    { expect = [[vim.fn.exists(":DiffProfile") == 0]], note = "the command does not exist" },
    { keys = ":DiffProfile review<CR>", ignore_errmsg = true },
    { expect = [[_G.has(vim.v.errmsg, "E492")]] },
    { expect = [[vim.o.diffopt == _G.untouched]], note = "the option is not applied either" },
  },
}
