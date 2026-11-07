-- Live check: image pairs without a real gallery, section 9 (task diff.nvim/manual-checklist-run; ALL/manual-test-checklists/diff.md).
return {
  id = "diff.image",
  title = "diff.nvim: an image pair warns without images.nvim, image_compare = false is a text diff, SVG is text",
  task = "diff.nvim/manual-checklist-run",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      require("diff").setup(_G.NO_PICKERS)
      _G.sandbox()
      vim.fn.writefile(vim.fn.eval("0z89504E470D0A1A0A0001"), "a.png")
      vim.fn.writefile(vim.fn.eval("0z89504E470D0A1A0A0002"), "b.png")
      _G.write("a.svg", { "<svg>", "<rect/>", "</svg>" })
      _G.write("b.svg", { "<svg>", "<circle/>", "</svg>" })
      _G.write("start.txt", { "x" })
      _G.open("start.txt")]],
    },
    { keys = ":Diff source=a.png target=b.png<CR>" },
    { wait = [[_G.noted("images.nvim is not installed")]], note = "a clear warning" },
    { expect = [[#_G.diffwins() == 0 and #_G.wins() == 1]], note = "no raw-byte diff" },

    { lua = [[_G.forget(); _G.set_diff({ image_compare = false })]] },
    { keys = ":Diff source=a.png target=b.png<CR>" },
    { wait = [[#_G.diffwins() == 2]], note = "the raw-byte path, restored on request" },
    { expect = [[not _G.noted("images.nvim")]] },
    { lua = [[_G.only(); _G.open("start.txt"); _G.set_diff({ image_compare = true })]] },

    -- A gallery that only records: whether a real one reads well is the person's check, see `manual`.
    {
      lua = [[_G.shown = {}
      package.loaded["images"] = { gallery = function(paths) _G.shown[#_G.shown + 1] = paths end }]],
    },
    { keys = ":Diff source=a.svg target=b.svg<CR>" },
    { wait = [[#_G.diffwins() == 2]], note = "SVG goes through the text pipeline" },
    { expect = [[#_G.shown == 0]], note = "no gallery" },
    { expect = [[_G.has(_G.text(_G.buf_named("[Diff:target]")), "<circle/>")]] },
    { lua = [[_G.only(); _G.open("start.txt")]] },
    { keys = ":Diff source=a.png target=b.png view=inline output=stat<CR>" },
    { wait = [[#_G.shown == 1]], note = "the raster pair reaches the gallery" },
    { expect = [[#_G.shown[1] == 2 and _G.has(_G.shown[1][2], "b.png")]] },
    { expect = [[#_G.wins() == 1 and not _G.noted("hunk")]], note = "view= and output= ignored" },
  },
  manual = {
    "With the real images.nvim: :Diff target=<some>.png source=<other>.png shows the side-by-side gallery",
  },
}
