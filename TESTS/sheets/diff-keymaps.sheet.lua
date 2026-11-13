-- Live check: no keys by default, opts.keymaps shortcuts, section 13 (task diff.nvim/manual-checklist-run; ALL/manual-test-checklists/diff.md).
return {
  id = "diff.keymaps",
  feature = "diff.keymaps",
  title = "diff.nvim: only gh is bound by default; a shortcut runs its command, one for a disabled feature is refused",
  task = "diff.nvim/manual-checklist-run",
  requires = {
    {
      lua = "vim.g.diff_sheets_ui_nvim ~= nil",
      reason = "ui.nvim not found by TESTS/minimal_init.lua",
    },
  },
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      vim.g.mapleader = " "
      require("diff").setup(_G.NO_PICKERS)
      _G.history_repo()
      _G.open("a.txt")
      _G.bound = function()
        local out = {}
        for _, m in ipairs(vim.api.nvim_get_keymap("n")) do
          if m.desc and m.desc:find("[diff]", 1, true) then
            out[#out + 1] = m.lhs
          end
        end
        return out
      end]],
    },
    { expect = [[vim.deep_equal(_G.bound(), { "gh" })]], note = "the plugin imposes nothing else" },

    { lua = [[_G.reload({ use_pickers_nvim = false, keymaps = { diff_head = "<leader>xh" } })]] },
    { expect = [[vim.fn.maparg("<leader>xh", "n") ~= ""]] },
    { keys = " xh", note = "runs :Diff target=git:HEAD" },
    { wait = [[#_G.diffwins() == 2 and _G.buf_named("[Diff:target]") ~= nil]] },
    { expect = [[_G.has(_G.text(_G.buf_named("[Diff:target]")), "version 5")]] },
    { lua = [[_G.only(); _G.open("a.txt"); vim.keymap.del("n", "<leader>xh")]] },

    {
      lua = [[_G.reload({
        use_pickers_nvim = false,
        features = { diff_history = false },
        keymaps = { diff_history = "<leader>xy" },
      })]],
    },
    { wait = [[_G.noted("diff_history")]], note = "a refusal at setup" },
    {
      expect = [[vim.fn.maparg("<leader>xy", "n") == ""]],
      note = "no key that errors on first press",
    },
  },
}
