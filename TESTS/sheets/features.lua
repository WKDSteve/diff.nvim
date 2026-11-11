-- TESTS/sheets/features.lua -- the functionalities of diff.nvim as its user meets them; `testing sheets report` says
-- which ones have a feature sheet (`feature = "<id>"`) and in which state, and K16 warns about a sheet that names an id
-- not listed here. Data: read with an empty environment like a sheet (testing.nvim docs/SHEETS.md).
-- The list follows docs/FEATURES.md and ALL/manual-test-checklists/diff.md.
return {
  {
    id = "diff.compare",
    title = "Bare :Diff asks for the other side and diffs the buffer, or a range of it, against a file or a buffer",
    surface = { "command:Diff" },
    docs = "docs/FEATURES.md",
  },
  {
    id = "diff.stat",
    title = "output=stat says +N -M and the hunks without opening a window, or fills a list with them",
    surface = { "command:Diff" },
    docs = "docs/FEATURES.md",
  },
  {
    id = "diff.views",
    title = "view=vsplit, split and tab open a native diff in that layout where :diffget works",
    surface = { "command:Diff", "config:diff.default_view" },
    docs = "docs/FEATURES.md",
  },
  {
    id = "diff.inline",
    title = "view=inline and float show a unified diff with word-level highlights",
    surface = { "command:Diff" },
    docs = "docs/FEATURES.md",
  },
  {
    id = "diff.git",
    title = "git:{rev} diffs against a revision of the file without touching the work tree",
    surface = { "command:Diff" },
    docs = "docs/FEATURES.md",
  },
  {
    id = "diff.history",
    title = ":DiffHistory lists the commits of a file and diffs one against its parent",
    surface = { "command:DiffHistory" },
    docs = "docs/FEATURES.md",
  },
  {
    id = "diff.directory",
    title = "Two directories give a per-file summary of what differs",
    surface = { "command:Diff" },
    docs = "docs/FEATURES.md",
  },
  {
    id = "diff.url",
    title = "An http(s) URL is fetched in the background and diffed like a file",
    surface = { "command:Diff" },
    docs = "docs/url-sources.md",
  },
  {
    id = "diff.image",
    title = "Two images are compared through images.nvim, SVG stays a text diff",
    surface = { "config:diff.image_compare" },
    docs = "docs/FEATURES.md",
  },
  {
    id = "diff.three-way",
    title = "base= opens a three-way diff for a merge conflict where only the result takes changes",
    surface = { "command:Diff" },
    docs = "docs/three-way-diff.md",
  },
  {
    id = "diff.buffers",
    title = ":DiffBuffers diffs against another open buffer, :DiffClear closes every diff window of the plugin",
    surface = { "command:DiffBuffers", "command:DiffClear" },
    docs = "docs/FEATURES.md",
  },
  {
    id = "diff.orig",
    title = ":DiffOrig diffs the buffer against its saved version on disk",
    surface = { "command:DiffOrig" },
    docs = "docs/FEATURES.md",
  },
  {
    id = "diff.exit",
    title = "<Esc><Esc> or :DiffExit leaves a diff, and a native :diffthis too when native_diffthis is on",
    surface = { "command:DiffExit", "binding:<Esc><Esc>", "config:exit.native_diffthis" },
    docs = "docs/FEATURES.md",
  },
  {
    id = "diff.keymaps",
    title = "Optional keymap shortcuts run the commands; one for a switched-off feature is refused",
    surface = { "config:keymaps" },
    docs = "docs/FEATURES.md",
  },
  {
    id = "diff.profile",
    title = ":DiffProfile {name} switches 'diffopt' to a bundle, and a live diff follows",
    surface = { "command:DiffProfile" },
    docs = "docs/FEATURES.md",
  },
  {
    id = "diff.gh",
    title = "gh peeks the gitsigns hunk under the cursor",
    surface = { "binding:gh" },
    docs = "docs/FEATURES.md",
  },
  {
    id = "diff.statusline",
    title = "require('diff').status() shows the number of open diffs in the statusline",
    docs = "docs/FEATURES.md",
  },
  {
    id = "diff.validation",
    title = "A typo in an argument or a setup() option is reported, nothing breaks and the default applies",
    docs = "docs/FEATURES.md",
  },
  {
    id = "diff.picker",
    title = "The picker for an omitted side is pickers.nvim's fuzzy engine when it is installed",
    surface = { "config:use_pickers_nvim", "config:select_fn" },
    docs = "docs/FEATURES.md",
  },
  {
    id = "diff.rename",
    title = "Every command can be renamed through commands.*",
    surface = { "config:commands" },
    docs = "docs/FEATURES.md",
  },
}
