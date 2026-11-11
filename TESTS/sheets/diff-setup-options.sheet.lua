-- Live check: invalid setup() options, section 17 (task diff.nvim/manual-checklist-run; ALL/manual-test-checklists/diff.md).
return {
  id = "diff.setup-options",
  feature = "diff.validation",
  title = "diff.nvim: an invalid setup() option does not raise, its default applies, :checkhealth diff lists it",
  task = "diff.nvim/manual-checklist-run",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      _G.sandbox()
      _G.write("a.txt", { "one", "two" })
      _G.write("b.txt", { "one", "TWO" })
      _G.open("a.txt")
      _G.try = function(opts)
        _G.only()
        vim.cmd("silent! tabonly")
        _G.open("a.txt")
        opts.use_pickers_nvim = false
        _G.reload(opts)
      end
      _G.health = function(part)
        local found = _G.has(_G.text(), part)
        vim.cmd("bwipeout!")
        return found
      end]],
    },
    { lua = [[require("diff").setup({ use_pickers_nvim = false })]] },
    { keys = ":checkhealth diff<CR>" },
    {
      wait = [[_G.has(_G.text(), "No unknown or invalid")]],
      timeout = 5000,
      note = "clean options, clean report",
    },
    { lua = [[vim.cmd("bwipeout!")]] },

    { lua = [[_G.try({ features = { diff_orgin = false } })]] },
    { keys = ":checkhealth diff<CR>" },
    {
      wait = [[_G.text():find("did you mean 'features.diff_origin'", 1, true) ~= nil]],
      timeout = 5000,
    },
    { expect = [[_G.health("unknown option 'features.diff_orgin'")]] },

    { lua = [[_G.try({ diff = { default_view = "diagonal" } })]] },
    { keys = ":Diff target=b.txt<CR>" },
    { wait = [[#_G.diffwins() == 2]], note = "the vsplit default" },
    { expect = [[vim.fn.winlayout()[1] == "row"]] },
    { keys = ":checkhealth diff<CR>" },
    { wait = [[_G.text():find("default_view", 1, true) ~= nil]], timeout = 5000 },
    { lua = [[vim.cmd("bwipeout!")]] },

    { lua = [[_G.try({ diff = { default_orig_view = "inline" } })]] },
    { keys = ":checkhealth diff<CR>" },
    { wait = [[_G.text():find("default_orig_view", 1, true) ~= nil]], timeout = 5000 },
    { lua = [[vim.cmd("bwipeout!")]] },

    { lua = [[_G.try({ diff = { ctxlen = -1 } })]] },
    { expect = [[require("diff.config").get().diff.ctxlen == 3]], note = "the default" },
    { keys = ":checkhealth diff<CR>" },
    { wait = [[_G.text():find("ctxlen", 1, true) ~= nil]], timeout = 5000 },
    { lua = [[vim.cmd("bwipeout!")]] },

    { lua = [[_G.try({ commands = { diff = "my_diff" } })]] },
    {
      expect = [[vim.fn.exists(":Diff") == 2 and vim.fn.exists(":my_diff") == 0]],
      note = "the command is still :Diff",
    },
    { keys = ":checkhealth diff<CR>" },
    { wait = [[_G.text():find("commands.diff", 1, true) ~= nil]], timeout = 5000 },
  },
}
