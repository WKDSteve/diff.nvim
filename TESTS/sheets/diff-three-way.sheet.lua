-- Live check: three-way diff, section 4 (task diff.nvim/manual-checklist-run; ALL/manual-test-checklists/diff.md).
return {
  id = "diff.three-way",
  title = "diff.nvim: base= in a real conflict: three windows, only the left one takes changes, nonsense views are refused",
  task = "diff.nvim/manual-checklist-run",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      -- The order of the windows follows 'splitright' (docs/three-way-diff.md).
      vim.o.splitright = true
      -- One hunk for the whole conflict, whatever the default of this Neovim says about linematch.
      vim.o.diffopt = "internal,filler"
      require("diff").setup(_G.NO_PICKERS)
      _G.conflict_repo()
      _G.open("c.txt")
      _G.has(_G.text(), "<<<<<<<")
      _G.disk = table.concat(vim.fn.readfile("c.txt"), "\n")]],
    },
    { keys = ":Diff target=git:MERGE_HEAD base=git:HEAD<CR>" },
    { wait = [[#_G.diffwins() == 3]], note = "three windows" },
    {
      lua = [[_G.layout = vim.fn.winlayout()
      _G.names = vim.tbl_map(function(leaf)
        return vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(leaf[2]))
      end, _G.layout[2])
      _G.left = vim.fn.bufnr("c.txt")
      _G.base = _G.buf_named("[Diff:base]")
      _G.tgt = _G.buf_named("[Diff:target]")]],
    },
    {
      expect = [[_G.layout[1] == "row" and #_G.names == 3 and _G.has(_G.names[1], "c.txt")
        and _G.has(_G.names[2], "[Diff:base]") and _G.has(_G.names[3], "[Diff:target]")]],
      note = "working copy, base, incoming, left to right",
    },
    {
      expect = [[vim.bo[_G.left].modifiable and not vim.bo[_G.base].modifiable and not vim.bo[_G.tgt].modifiable]],
      note = "only the left one is editable",
    },
    { expect = [[_G.has(_G.text(_G.base), "ours") and _G.has(_G.text(_G.tgt), "theirs")]] },

    -- :diffget and :diffput go into the working buffer, and into nothing else.
    { lua = [[vim.api.nvim_set_current_win(vim.fn.bufwinid(_G.left)); vim.fn.cursor(3, 1)]] },
    {
      keys = [[:execute "diffput " .. luaeval("_G.tgt")<CR>]],
      ignore_errmsg = true,
      note = "into a read-only side",
    },
    {
      expect = [[_G.text(_G.tgt) == "top\ntheirs\nbottom"]],
      note = "the read-only side is unchanged",
    },
    { keys = [[:execute "diffget " .. luaeval("_G.tgt")<CR>]] },
    {
      expect = [[_G.text(_G.left) == "top\ntheirs\nbottom"]],
      note = "the left buffer took the hunk",
    },
    { expect = [[vim.bo[_G.left].modified]], note = "the buffer you will save" },
    { keys = "u" },
    { lua = [[vim.api.nvim_set_current_win(vim.fn.bufwinid(_G.tgt)); vim.fn.cursor(2, 1)]] },
    { keys = [[:execute "diffput " .. luaeval("_G.left")<CR>]] },
    {
      expect = [[_G.text(_G.left) == "top\ntheirs\nbottom"]],
      note = ":diffput from the right lands there too",
    },
    {
      expect = [[table.concat(vim.fn.readfile("c.txt"), "\n") == _G.disk]],
      note = "nothing written without :write",
    },
    {
      lua = [[vim.api.nvim_buf_call(_G.left, function() vim.cmd("edit!") end); _G.only(); _G.open("c.txt")]],
    },

    -- Refused up front.
    { keys = ":Diff target=git:MERGE_HEAD base=git:HEAD view=inline<CR>" },
    { wait = [[_G.noted('does not support view="inline"')]] },
    { expect = [[#_G.wins() == 1 and #_G.diffwins() == 0]], note = "no window, no two-way diff" },
    { keys = ":Diff target=git:MERGE_HEAD base=git:HEAD output=stat<CR>" },
    { wait = [[_G.noted('only supports output=buffer, got output="stat"')]] },
    { expect = [[#_G.wins() == 1 and #_G.diffwins() == 0]], note = "no window, no stat" },

    -- Mixed specifier kinds: a revision as the base, a file path as the target.
    {
      lua = [[_G.only()
      _G.history_repo()
      _G.write("other.txt", { "alpha", "beta", "from the file", "gamma", "delta" })
      _G.open("a.txt")]],
    },
    { keys = ":Diff base=git:HEAD~4 target=other.txt<CR>" },
    { wait = [[#_G.diffwins() == 3]] },
    {
      expect = [[_G.has(_G.text(_G.buf_named("[Diff:base]")), "version 1")]],
      note = "the revision",
    },
    {
      expect = [[_G.has(_G.text(_G.buf_named("[Diff:target]")), "from the file")]],
      note = "the file",
    },
  },
}
