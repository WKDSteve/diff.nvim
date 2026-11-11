-- Live check: status() and on_done, section 12 (task diff.nvim/manual-checklist-run; ALL/manual-test-checklists/diff.md).
return {
  id = "diff.api",
  feature = "diff.statusline",
  title = "diff.nvim: status() counts the active diffs in a live statusline, on_done fires once, also on a cancel",
  task = "diff.nvim/manual-checklist-run",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      require("diff").setup(_G.NO_PICKERS)
      _G.history_repo()
      _G.write("b.txt", { "one" })
      _G.write("c.txt", { "two" })
      _G.open("a.txt")
      vim.o.statusline = "[%{v:lua.require'diff'.status()}]"
      _G.line = function()
        return vim.api.nvim_eval_statusline(vim.o.statusline, {}).str
      end
      _G.calls = {}
      _G.on_done = function(r, e)
        _G.calls[#_G.calls + 1] = { result = r, err = e }
      end]],
    },
    {
      expect = [[require("diff").status() == "" and _G.line() == "[]"]],
      note = "no diff: empty, hidden",
    },
    { keys = ":Diff target=b.txt<CR>" },
    { wait = [[#_G.diffwins() == 2]] },
    {
      expect = [[require("diff").status() == "diff:1" and _G.line() == "[diff:1]"]],
      note = "one active scratch buffer",
    },
    { keys = ":Diff target=c.txt view=inline<CR>" },
    { wait = [[require("diff").status() == "diff:2"]], note = "a second one counts" },
    { expect = [[_G.line() == "[diff:2]"]], note = "live" },
    { keys = ":DiffClear<CR>" },
    { wait = [[require("diff").status() == "" and _G.line() == "[]"]], note = "and gone again" },
    { lua = [[_G.only(); _G.open("a.txt")]] },

    {
      keys = [[:lua require("diff").run("target=git:HEAD~1 output=stat", { on_done = _G.on_done })<CR>]],
    },
    { wait = [[#_G.calls == 1]], note = "once the git show resolved" },
    { lua = "vim.wait(200)" },
    {
      expect = [[#_G.calls == 1 and _G.calls[1].err == nil and _G.calls[1].result.output == "stat"]],
      note = "exactly once",
    },

    { keys = [[:lua require("diff").run("", { on_done = _G.on_done })<CR>]] },
    { wait = [[_G.dialog("clipboard")]] },
    { keys = "<Esc>" },
    { wait = [[#_G.calls == 2]] },
    { lua = "vim.wait(200)" },
    {
      expect = [[#_G.calls == 2 and _G.calls[2].result == nil and _G.has(_G.calls[2].err, "cancelled")]],
      note = "nil and the reason",
    },
  },
}
