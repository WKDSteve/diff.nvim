-- .testing.lua -- configuration of testing.nvim for this project.
-- Written by `testing migrate`; edit freely (it is never overwritten). Every key is optional; the
-- keys are documented in testing.nvim's docs/CONFIG.md. Loading this file executes it (same trust
-- as running the specs).
return {
  -- Lua module root of the project.
  plugin = "diff",
  -- How the spec files are run: "auto" = sniffed per file, "h" = on the project's own TESTS/harness.lua,
  -- "script" = a self-running script in its own process.
  dialect = { ["TESTS/sheets_spec.lua"] = "busted", ["*"] = "h" },
  -- Dependencies (directory names) put on the runtimepath: $<NAME>_DIR, .deps/<name>, ../<name>,
  -- stdpath('data')/lazy/<name>.
  -- ui.nvim is declared in TESTS/minimal_init.lua only: everything here goes on the runtimepath of the specs, where it
  -- would turn their vim.notify doubles into toasts. The test sheets add it in their child editor.
  deps = { "lib.nvim" },
  -- The way ui.nvim reaches the children from the worktree of `ci commit`, where it is no sibling.
  env_allow = { "UI_NVIM_DIR" },
  -- "none" = all specs in one nvim, "file" = one nvim per spec file
  -- (nothing leaks from one file into the next). "file" because several specs leave buffers and
  -- windows behind (the state guard reports them in a shared process).
  isolated = "file",
  -- All test sheets run in one spec file, one child editor each: the defaults of 10 s per case and 60 s per file
  -- are reached under load (fileops, 2026-11-07).
  timeouts = { case_ms = 30000, file_ms = 300000 },

  -- Guards (docs/GUARDS.md of testing.nvim): every net is an error; the suite passes them with the
  -- allowlist below, so nothing is left at warn.
  guards = {
    fs = "error",
    state = "error", -- setup() state cannot leak: isolated = "file" gives each spec file its own editor
    scheduled_error = "error",
    prompt = "error",
    deprecation = "error",
    process_net = "error",
  },
  -- What the specs do on purpose (each entry is legitimate behavior, not a leak).
  guard_allow = {
    fs = {
      -- on_done_spec points tempname() at an unwritable drive to make writefile fail for real
      -- (a deliberate negative probe of output = "file").
      "Z:/definitely/not/writable",
    },
    spawn = {
      -- git_spec runs the real git against this repository (git show <rev>:<path>).
      "git",
      -- sheets_spec.lua: every test sheet (TESTS/sheets/) runs in a child editor.
      "nvim",
    },
  },
  -- The runner counts which commands, keymaps and autocommands the specs exercise (docs/SURFACE.md of testing.nvim);
  -- `scripts/test.sh surface` compares that with surface.baseline.json (a regression gate, not a percentage).
  surface = { track = true },
  -- gated: a failed conformance check makes `scripts/test.sh conformance` exit 1 (docs/CONFORMANCE.md of testing.nvim)
  conformance = { gate = true },
}
