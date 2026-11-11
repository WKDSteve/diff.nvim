-- Live check: view=inline and float with the word diff, section 5 (task diff.nvim/manual-checklist-run; ALL/manual-test-checklists/diff.md).
return {
  id = "diff.inline",
  feature = "diff.inline",
  title = "diff.nvim: view=inline and float show a unified diff, word highlights only on paired lines and on whole codepoints",
  task = "diff.nvim/manual-checklist-run",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      require("diff").setup(_G.NO_PICKERS)
      _G.sandbox()
      local a = { "same", "two words here" }
      local b = { "same", "two WORDS here" }
      for i = 1, 8 do a[#a + 1] = "pad " .. i; b[#b + 1] = "pad " .. i end
      a[#a + 1] = "only one removed"
      b[#b + 1] = "added first"; b[#b + 1] = "added second"; b[#b + 1] = "added third"
      for i = 1, 8 do a[#a + 1] = "fill " .. i; b[#b + 1] = "fill " .. i end
      a[#a + 1] = "h\u{e9}llo w\u{f6}rld \u{1F600} end"
      b[#b + 1] = "h\u{e9}llo w\u{e4}rld \u{1F680} end"
      _G.write("a.txt", a)
      _G.write("b.txt", b)
      _G.open("a.txt")
      -- What the word diff highlighted, by line of the buffer: { [lnum] = { "text", ... } }.
      _G.marks = function()
        local ns = vim.api.nvim_create_namespace("diff_word_diff")
        local out = {}
        for _, m in ipairs(vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, { details = true })) do
          assert(m[4].hl_group == "DiffText", m[4].hl_group)
          local line = vim.api.nvim_buf_get_lines(0, m[2], m[2] + 1, false)[1]
          out[line] = out[line] or {}
          table.insert(out[line], line:sub(m[3] + 1, m[4].end_col))
        end
        return out
      end]],
    },
    { keys = ":Diff target=b.txt view=inline<CR>" },
    { wait = [[vim.bo.filetype == "diff"]], note = "one scratch buffer" },
    {
      expect = [[#_G.diffwins() == 0 and _G.has(_G.text(), "-two words here") and _G.has(_G.text(), "+two WORDS here")]],
    },
    {
      lua = [[_G.m = _G.marks()]],
    },
    {
      expect = [[vim.deep_equal(_G.m["-two words here"], { "words" }) and vim.deep_equal(_G.m["+two WORDS here"], { "WORDS" })]],
      note = "the changed span of a paired line, not the whole line",
    },
    {
      expect = [[_G.m["-only one removed"] == nil and _G.m["+added first"] == nil and _G.m["+added second"] == nil]],
      note = "1 removed against 3 added: no word highlights in that hunk",
    },
    {
      expect = [[_G.has(table.concat(_G.m["-h\u{e9}llo w\u{f6}rld \u{1F600} end"], "|"), "\u{f6}")
        and vim.tbl_contains(_G.m["+h\u{e9}llo w\u{e4}rld \u{1F680} end"], "\u{1F680}")]],
      note = "multi-byte changes are highlighted whole",
    },
    {
      expect = [[vim.iter(vim.tbl_values(_G.m)):flatten():all(function(s)
        local first = s:byte(1)
        return (first < 0x80 or first >= 0xC0) and vim.str_utf_end(s, #s) == 0
      end)]],
      note = "no span splits a codepoint",
    },
    { lua = [[_G.only(); _G.open("a.txt"); vim.cmd("vsplit"); _G.before = vim.fn.winlayout()]] },

    { keys = ":Diff target=b.txt view=float<CR>" },
    {
      wait = [[vim.bo.filetype == "diff" and vim.api.nvim_win_get_config(0).relative ~= ""]],
      note = "a float",
    },
    {
      expect = [[_G.has(_G.text(), "-two words here") and vim.deep_equal(vim.fn.winlayout(), _G.before)]],
      note = "same content, layout untouched",
    },
    { keys = "q" },
    { wait = [[vim.bo.filetype ~= "diff"]], note = "q closes it" },
    {
      expect = [[vim.deep_equal(vim.fn.winlayout(), _G.before)]],
      note = "the layout is as it was",
    },
    { keys = ":Diff target=b.txt view=float<CR>" },
    { wait = [[vim.bo.filetype == "diff"]] },
    { keys = "<Esc>" },
    { wait = [[vim.bo.filetype ~= "diff"]], note = "<Esc> closes it" },
    { expect = [[vim.deep_equal(vim.fn.winlayout(), _G.before)]] },
  },
}
