-- Live check: :DiffHistory, section 14 (task diff.nvim/manual-checklist-run; ALL/manual-test-checklists/diff.md).
return {
  id = "diff.history",
  title = "diff.nvim: :DiffHistory lists newest first, diffs a commit against its parent, follows a rename, passes view and output",
  task = "diff.nvim/manual-checklist-run",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      require("diff").setup(_G.NO_PICKERS)
      _G.history_repo()
      _G.open("a.txt")]],
    },
    { keys = ":DiffHistory<CR>" },
    { wait = [[_G.dialog("step-5")]], note = "the picker" },
    {
      expect = [[(function()
        local t, last = _G.text(), 0
        for _, c in ipairs({ "step-5", "step-4", "step-3", "step-2", "step-1" }) do
          local at = t:find(c, 1, true)
          if not at or at < last then return false end
          last = at
        end
        return true
      end)()]],
      note = "newest first",
    },
    { keys = "<CR>", note = "pick c5" },
    { wait = [[#_G.diffwins() == 2]], note = "default output=buffer, view=vsplit" },
    {
      expect = [[_G.has(_G.text(_G.buf_named("[Diff:source]")), "version 4")]],
      note = "the parent",
    },
    {
      expect = [[_G.has(_G.text(_G.buf_named("[Diff:target]")), "version 5")]],
      note = "the commit",
    },
    { lua = [[_G.only(); _G.open("many.txt")]] },

    { keys = ":DiffHistory new.txt<CR>", note = "from an unrelated buffer" },
    { wait = [[_G.dialog("step-4")]] },
    {
      expect = [[_G.dialog("step-2") and _G.dialog("step-1") and not _G.dialog("step-5") and not _G.dialog("step-3")]],
      note = "the named file's commits, across the rename",
    },
    { keys = "j<CR>", note = "c2, before the rename" },
    { wait = [[#_G.diffwins() == 2]], note = "a real diff, not a could-not-resolve" },
    {
      expect = [[_G.has(_G.text(_G.buf_named("[Diff:target]")), "changed in c2")]],
      note = "the file under its old name",
    },
    {
      expect = [[_G.has(_G.text(_G.buf_named("[Diff:source]")), "rename line 3")]],
      note = "against its parent",
    },
    { lua = [[_G.only(); _G.open("a.txt")]] },

    { keys = ":DiffHistory view=inline<CR>" },
    { wait = [[_G.dialog("step-5")]] },
    { keys = "<CR>" },
    { wait = [[vim.bo.filetype == "diff"]], note = "inline" },
    { expect = [[_G.has(_G.text(), "+version 5") and #_G.diffwins() == 0]] },
    { lua = [[_G.only(); _G.open("a.txt")]] },
    { keys = ":DiffHistory output=stat<CR>" },
    { wait = [[_G.dialog("step-5")]] },
    { keys = "<CR>" },
    { wait = [[_G.noted("+1 -1, 1 hunk")]], note = "reported only" },
    { expect = [[#_G.wins() == 1 and #_G.diffwins() == 0]] },
    { lua = [[_G.only(); _G.open("a.txt")]] },

    { keys = ":DiffHistory<CR>" },
    { wait = [[_G.dialog("step-1")]] },
    { keys = "jjjj<CR>", note = "the oldest, the commit that added the file" },
    { wait = [[#require("lib.nvim.notify.popup").history("diff") > 0]], note = "an error" },
    {
      expect = [[#_G.diffwins() == 0 and _G.buf_named("[Diff:target]") == nil]],
      note = "no diff against an empty tree",
    },
    { lua = [[_G.only(); _G.open("a.txt"); _G.set_diff({ history_max_entries = 3 })]] },

    { keys = ":DiffHistory<CR>" },
    { wait = [[_G.dialog("step-5")]] },
    {
      expect = [[_G.dialog("step-3") and not _G.dialog("step-2")]],
      note = "only the three newest",
    },
    { keys = "<Esc>" },
    { wait = [[_G.noted("[diff] Diff cancelled")]], note = "cancel" },
    { lua = [[_G.only(); _G.open("a.txt")]] },

    -- The command layer refuses the typo as a path, on two lines: room for them instead of a hit-enter prompt.
    { lua = [[vim.o.cmdheight = 3]] },
    { keys = ":DiffHistory veiw=inline<CR>", ignore_errmsg = true },
    {
      expect = [[_G.has(vim.fn.execute("messages"), "'veiw=inline' is not a readable file")]],
      note = "refused",
    },
    {
      expect = [[#_G.wins() == 1 and vim.api.nvim_win_get_config(0).relative == ""]],
      note = "no picker",
    },
    {
      expect = [[(function()
        local c = vim.fn.getcompletion("DiffHistory ", "cmdline")
        return vim.tbl_contains(c, "many.txt") and vim.tbl_contains(c, "view=") and vim.tbl_contains(c, "output=")
      end)()]],
      note = "<Tab> completes a path and the keys",
    },
  },
}
