-- Live check: http(s) sources with the real curl against a server in the child, section 8
-- (task diff.nvim/manual-checklist-run; ALL/manual-test-checklists/diff.md). Nothing leaves the machine.
return {
  id = "diff.url",
  title = "diff.nvim: a URL is fetched in the background, a non-2xx is an error, output=stat works on it",
  task = "diff.nvim/manual-checklist-run",
  requires = { { lua = [[vim.fn.executable("curl") == 1]], reason = "no curl on this machine" } },
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      require("diff").setup(_G.NO_PICKERS)
      _G.sandbox()
      vim.env.no_proxy = "127.0.0.1"
      vim.env.NO_PROXY = "127.0.0.1"
      _G.write("local.txt", { "one", "two", "three" })
      _G.open("local.txt")
      _G.serve()]],
    },
    -- One command line: what runs right after :Diff does not find the window, the fetch is still under way.
    {
      keys = [[:execute "Diff source=local.txt target=" .. luaeval("_G.url('/slow')") | lua _G.right_after = #_G.diffwins()<CR>]],
    },
    { expect = [[_G.right_after == 0]], note = "control is back before the diff exists" },
    { wait = [[#_G.diffwins() == 2]], timeout = 5000, note = "the diff once the fetch resolved" },
    {
      expect = [[_G.has(_G.text(_G.buf_named("[Diff:target]")), "SERVED")]],
      note = "the body of the response",
    },
    {
      expect = [[_G.has(_G.text(_G.buf_named("[Diff:source]")), "three")]],
      note = "the local file",
    },
    { lua = [[_G.only(); _G.open("local.txt")]] },

    { keys = [[:execute "Diff source=local.txt target=" .. luaeval("_G.url('/missing')")<CR>]] },
    { wait = [[_G.noted("404")]], timeout = 5000, note = "a clear error" },
    {
      expect = [[#_G.diffwins() == 0 and _G.buf_named("[Diff:target]") == nil]],
      note = "the error page is not diffed",
    },
    { lua = [[_G.only(); _G.open("local.txt")]] },

    {
      keys = [[:execute "Diff source=local.txt output=stat target=" .. luaeval("_G.url('/slow')")<CR>]],
    },
    {
      wait = [[_G.noted("+1 -1, 1 hunk")]],
      timeout = 5000,
      note = "the stat of the downloaded file",
    },
    { expect = [[#_G.wins() == 1 and #_G.diffwins() == 0]], note = "no window" },
  },
}
