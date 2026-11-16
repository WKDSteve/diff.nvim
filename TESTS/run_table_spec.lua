-- Test code: when something here comes back nil -- a result, a buffer, a
-- fixture read -- this file must crash and name it. The nil guards LuaLS asks
-- for below would hide the very failure it exists to report.
---@diagnostic disable: need-check-nil
-- TESTS/run_table_spec.lua — the arguments of a run as a table.
--
-- `require("diff").run()` took only the `key=value` string of `:Diff`, whose
-- grammar ends a value at the first blank: a path with a blank in it could not
-- be given at all. The table form carries the same keys and takes a value as
-- it is. Checked here: the pure conversion (`resolve.args_from_table`), and
-- real runs through the front door with paths the string cannot express.

return function(H)
  local eq, ok = H.eq, H.ok
  local diff = require("diff")
  local resolve = require("diff.core.resolve")
  local scratch = require("diff.core.scratch")

  ---@param fn fun(): nil
  ---@return string[]
  local function notices(fn)
    local out = {}
    local saved = vim.notify
    -- Test double over a typed surface; restored before returning.
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.notify = function(msg)
      out[#out + 1] = tostring(msg)
    end
    local call_ok, err = pcall(fn)
    vim.notify = saved
    ok(call_ok, "call did not throw: " .. tostring(err))
    return out
  end

  local function reset()
    scratch.cleanup_all()
    vim.cmd("silent! only")
  end

  ---@param buf integer
  ---@return string
  local function text_of(buf)
    return table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
  end

  -- args_from_table --------------------------------------------------------
  do
    local kv, unknown, err = resolve.args_from_table({
      source = "notes/old draft.md",
      target = "notes/new draft.md",
      view = "inline",
    }, { "target", "source", "base", "view", "output" })
    eq(kv.source, "notes/old draft.md", "a value with a blank is kept whole")
    eq(kv.target, "notes/new draft.md", "... on the other side too")
    eq(kv.view, "inline", "the other keys come through")
    eq(#unknown, 0, "known keys are not reported")
    eq(err, nil, "and nothing is wrong")
  end
  do
    local kv, unknown = resolve.args_from_table({ target = 7, veiw = "inline", zzz = "x" }, {
      "target",
      "view",
    })
    eq(kv.target, "7", "a buffer number becomes its text, as the string form yields it")
    eq(kv.veiw, "inline", "an unrecognized key is still kept in the table")
    eq(table.concat(unknown, ","), "veiw,zzz", "the unrecognized keys are named, sorted")
  end
  do
    local _, unknown = resolve.args_from_table({ anything = "x" })
    eq(#unknown, 0, "without a list of known keys nothing is reported")
  end
  for _, case in ipairs({
    { { target = "" }, "target", "an empty string" },
    { { target = true }, "target", "a boolean" },
    { { target = {} }, "target", "a table" },
    { { target = 1.5 }, "target", "a fraction" },
    { { target = math.huge }, "target", "infinity" },
    { { target = 0 / 0 }, "target", "not a number" },
    { { "a.lua" }, "1", "a positional entry" },
  }) do
    local _, _, err = resolve.args_from_table(case[1], { "target" })
    ok(type(err) == "string", case[3] .. " is no value")
    ok(
      tostring(err):find("arg " .. case[2] .. " ", 1, true) ~= nil,
      "... and the message names it: " .. tostring(err)
    )
  end
  do
    ---@diagnostic disable-next-line: param-type-mismatch
    local kv, unknown, err = resolve.args_from_table("target=x", { "target" })
    eq(next(kv), nil, "what is no table yields no arguments")
    eq(#unknown, 0, "... no unknown keys")
    eq(err, nil, "... and no error")
  end

  -- real runs: two files whose paths the string form cannot carry -------------
  local dir = H.tmpdir()
  local old_file = dir .. "old notes/first draft.md"
  local new_file = dir .. "new notes/second draft.md"
  H.write_file(old_file, { "one", "two", "three" })
  H.write_file(new_file, { "one", "TWO", "three" })

  -- the string form really cannot: the value ends at the first blank
  do
    reset()
    local result, err
    local shown = notices(function()
      diff.run("source=" .. old_file .. " target=" .. new_file, {
        on_done = function(r, e)
          result, err = r, e
        end,
      })
    end)
    eq(result, nil, "the string form produces nothing for a path with a blank")
    ok(type(err) == "string", "... and says why: " .. tostring(err))
    ok(#shown > 0, "... to the user as well")
  end

  do
    reset()
    local result, err
    local shown = notices(function()
      diff.run({ source = old_file, target = new_file, view = "vsplit" }, {
        on_done = function(r, e)
          result, err = r, e
        end,
      })
    end)
    ok(result ~= nil, "the table form runs with the same paths: " .. tostring(err))
    eq(#shown, 0, "... without a message: " .. table.concat(shown, " | "))
    eq(result.view, "vsplit", "... in the view that was named")
    eq(#result.buffers, 2, "... with a buffer for each side")
    eq(text_of(result.buffers[1]), "one\ntwo\nthree", "the first is the source file")
    eq(text_of(result.buffers[2]), "one\nTWO\nthree", "the second is the target file")
    eq(#result.windows, 2, "... each in a window of its own")
    for _, win in ipairs(result.windows) do
      ok(vim.wo[win].diff, "... in diff mode")
    end
  end

  -- output= and the other keys work the same in the table
  do
    reset()
    local result
    local shown = notices(function()
      diff.run({ source = old_file, target = new_file, output = "stat" }, {
        on_done = function(r)
          result = r
        end,
      })
    end)
    ok(result ~= nil, "output = stat runs from a table")
    eq(#result.windows, 0, "... and opens no window")
    ok(
      table.concat(shown, "\n"):find("+1", 1, true) ~= nil,
      "... and reports the change: " .. table.concat(shown, " | ")
    )
  end

  -- two folders with blanks: the directory diff
  do
    reset()
    local result, err
    notices(function()
      diff.run({ source = dir .. "old notes", target = dir .. "new notes" }, {
        on_done = function(r, e)
          result, err = r, e
        end,
      })
    end)
    ok(result ~= nil, "two folders with blanks go to the directory diff: " .. tostring(err))
    eq(#result.buffers, 1, "... which shows its summary in one buffer")
    local summary = text_of(result.buffers[1])
    ok(summary:find("first draft.md", 1, true) ~= nil, "... naming the file only the source has")
    ok(summary:find("second draft.md", 1, true) ~= nil, "... and the one only the target has")
  end

  -- a path with a dollar sign is taken as it is in the table, even when it names a set variable;
  -- the string form keeps expanding it
  do
    local lit = dir .. "lit/"
    H.write_file(lit .. "$DIFF_TAB_DOLLAR.md", { "one", "literal", "three" })
    H.write_file(lit .. "decoy.md", { "one", "decoy", "three" })
    H.write_file(lit .. "plain.md", { "one", "two", "three" })
    H.write_file(lit .. "$DIFF_TAB_DIR/same.md", { "literal dir" })
    H.write_file(lit .. "decoydir/other.md", { "decoy dir" })
    local saved_file, saved_dir = vim.env.DIFF_TAB_DOLLAR, vim.env.DIFF_TAB_DIR
    vim.env.DIFF_TAB_DOLLAR = "decoy"
    vim.env.DIFF_TAB_DIR = "decoydir"

    ---@param args string|table
    ---@return DiffNvim.Result|nil, string|nil
    local function run(args)
      reset()
      local result, err
      notices(function()
        diff.run(args, {
          on_done = function(r, e)
            result, err = r, e
          end,
        })
      end)
      return result, err
    end

    local result, err =
      run({ source = old_file, target = lit .. "$DIFF_TAB_DOLLAR.md", view = "vsplit" })
    ok(result ~= nil, "a target with a dollar sign runs from a table: " .. tostring(err))
    eq(
      text_of(result.buffers[2]),
      "one\nliteral\nthree",
      "... and it is the file of that name, not the one the variable names"
    )

    result, err = run({ source = lit .. "$DIFF_TAB_DOLLAR.md", target = old_file, view = "vsplit" })
    ok(result ~= nil, "the same as a source: " .. tostring(err))
    eq(text_of(result.buffers[1]), "one\nliteral\nthree", "... the source is the file of that name")

    result, err = run({ source = lit .. "$DIFF_TAB_DIR", target = dir .. "new notes" })
    ok(result ~= nil, "a folder with a dollar sign goes to the directory diff: " .. tostring(err))
    local summary = text_of(result.buffers[1])
    ok(summary:find("same.md", 1, true) ~= nil, "... of that folder: " .. summary)
    ok(summary:find("other.md", 1, true) == nil, "... not of the one the variable names")

    result, err =
      run("view=vsplit source=" .. lit .. "plain.md target=" .. lit .. "$DIFF_TAB_DOLLAR.md")
    ok(result ~= nil, "the string form runs too: " .. tostring(err))
    eq(
      text_of(result.buffers[2]),
      "one\ndecoy\nthree",
      "... and keeps expanding the variable, as :Diff always did"
    )

    vim.env.DIFF_TAB_DOLLAR = saved_file
    vim.env.DIFF_TAB_DIR = saved_dir
  end

  -- an unknown key is reported, the run goes on (as with the string)
  do
    reset()
    local result
    local shown = notices(function()
      diff.run({ source = old_file, target = new_file, veiw = "inline", output = "stat" }, {
        on_done = function(r)
          result = r
        end,
      })
    end)
    ok(result ~= nil, "a run with an unknown key still runs")
    ok(
      table.concat(shown, "\n"):find("Unknown arg key(s): veiw", 1, true) ~= nil,
      "... and names the key: " .. table.concat(shown, " | ")
    )
  end

  -- a value that is none: nothing runs, and no picker opens for the missing target
  do
    reset()
    local result, err, calls = nil, nil, 0
    local shown = notices(function()
      ---@diagnostic disable-next-line: assign-type-mismatch
      diff.run({ source = old_file, target = true }, {
        on_done = function(r, e)
          result, err, calls = r, e, calls + 1
        end,
      })
    end)
    eq(result, nil, "a value that is none produces nothing")
    eq(calls, 1, "... on_done hears about it once")
    ok(tostring(err):find("arg target ", 1, true) ~= nil, "... with the key: " .. tostring(err))
    ok(table.concat(shown, "\n"):find("arg target ", 1, true) ~= nil, "... shown to the user")
    eq(#vim.api.nvim_list_wins(), 1, "... and nothing was opened")
  end

  reset()
  vim.fn.delete(dir, "rf")
end
