-- Test code: when something here comes back nil -- a registry entry, a plan,
-- a window -- this file must crash and name it. The nil guards LuaLS asks for
-- below would hide the very failure it exists to report.
---@diagnostic disable: need-check-nil
-- TESTS/tree_action_spec.lua — diff.integrations.tree: the action
-- `diff.compare` at lib.nvim.tree.registry, which the own tree of
-- filetree.nvim reads. Checked here are the entry, what it decides to compare
-- for which nodes (`plan`), what it says when there is nothing to compare, and
-- real runs from a window layout like the tree's. That a tree offers a
-- registered action on a key and in its menu is filetree.nvim's own spec.

return function(H)
  local eq, ok = H.eq, H.ok
  local registry = require("lib.nvim.tree.registry")
  local tree = require("diff.integrations.tree")
  local config = require("diff.config")
  local bindings = require("diff.bindings")
  local scratch = require("diff.core.scratch")

  ---@return table|nil
  local function entry()
    return registry.get("action", tree.NAME)
  end

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

  -- `require("diff").setup()` runs once per editor; what it does with the option is
  -- `config.setup` and `bindings.register`, which can be run again.
  ---@param opts? table
  ---@return string[] issues
  local function setup(opts)
    local cfg = config.setup(vim.tbl_deep_extend("force", { keymaps = false }, opts or {}))
    bindings.register(cfg)
    return config.issues()
  end

  local function reset()
    scratch.cleanup_all()
    vim.cmd("silent! only")
    vim.cmd("enew")
  end

  -- fixture: two folders, names with blanks ------------------------------------
  local dir = H.tmpdir()
  local left_dir, right_dir = dir .. "left side", dir .. "right side"
  local left, right = left_dir .. "/a b.txt", right_dir .. "/a b.txt"
  H.write_file(left, { "one", "two" })
  H.write_file(right, { "one", "TWO" })
  H.write_file(right_dir .. "/only here.txt", { "new" })

  -- setup registers it ---------------------------------------------------------
  eq(#setup(), 0, "the defaults raise no issue")
  local action = entry()
  ok(action ~= nil, "setup registers the action at the tree registry")
  ok(vim.deep_equal(action.needs, { "path" }), "it applies to a node with a path")
  eq(action.key, nil, "without a configured key it has none")
  eq(action.mutates, nil, "comparing changes no file")
  ok(type(action.desc) == "string" and action.desc ~= "", "it has a line for the menu")

  -- plan: what is compared for which nodes -------------------------------------
  -- a layout like the tree's: a side window (the "tree") and an editor window with a file
  ---@return integer tree_win, integer editor_win, integer editor_buf
  local function tree_layout()
    reset()
    vim.cmd("edit " .. vim.fn.fnameescape(left))
    local editor_win, editor_buf = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
    vim.cmd("topleft 30vnew")
    vim.bo.buftype = "nofile"
    return vim.api.nvim_get_current_win(), editor_win, editor_buf
  end

  do
    local tree_win, editor_win, editor_buf = tree_layout()
    local ctx = { win = tree_win, alt_buf = editor_buf }

    local plan, why = tree.plan({ { path = left }, { path = right } }, ctx)
    eq(why, nil, "two files: nothing is missing")
    ok(
      vim.deep_equal(plan.args, { source = left, target = right }),
      "two files: the first against the second, in the configured view: " .. vim.inspect(plan.args)
    )
    eq(plan.win, editor_win, "... started from the editor window, not from the tree")

    plan, why = tree.plan({ { path = left_dir }, { path = right_dir } }, ctx)
    eq(why, nil, "two folders: nothing is missing")
    ok(
      vim.deep_equal(plan.args, { source = left_dir, target = right_dir }),
      "two folders: the first against the second"
    )

    plan, why = tree.plan({ { path = right } }, ctx)
    eq(why, nil, "one file: nothing is missing")
    ok(
      vim.deep_equal(plan.args, { source = "current", target = right }),
      "one file: the editor's buffer against it: " .. vim.inspect(plan.args)
    )
    eq(plan.win, editor_win, "... from the editor window")

    -- the editor buffer is somewhere else: any window with a file will do
    plan = tree.plan({ { path = right } }, { win = tree_win })
    eq(plan.win, editor_win, "without the tree's own editor buffer another file window is taken")

    -- what is missing
    plan, why = tree.plan({ { path = left } }, ctx)
    eq(plan, nil, "the file of the editor window against itself is nothing to compare")
    ok(tostring(why):find("file of the editor window", 1, true) ~= nil, "... and says so: " .. why)

    plan, why = tree.plan({ { path = left_dir } }, ctx)
    eq(plan, nil, "one folder has nothing to be compared with")
    ok(tostring(why):find("second folder", 1, true) ~= nil, "... and asks for a second: " .. why)

    plan, why = tree.plan({ { path = left_dir }, { path = right } }, ctx)
    eq(plan, nil, "a folder and a file are not compared")
    ok(
      why:find("left side is a folder", 1, true) ~= nil and why:find("a b.txt is a file", 1, true),
      "... and the message says which is which: " .. why
    )
    plan, why = tree.plan({ { path = right }, { path = left_dir } }, ctx)
    eq(plan, nil, "... in either order")
    ok(why:find("left side is a folder", 1, true) ~= nil, "... still naming the folder: " .. why)

    plan, why = tree.plan({ { path = left }, { path = right }, { path = left_dir } }, ctx)
    eq(plan, nil, "three marked nodes are not compared")
    ok(why:find("3 nodes", 1, true) ~= nil, "... and the message counts them: " .. why)

    plan, why = tree.plan({ { path = left }, { path = dir .. "gone.txt" } }, ctx)
    eq(plan, nil, "a node that is not on disk is not compared")
    ok(why:find("gone.txt", 1, true) ~= nil, "... and is named: " .. why)

    plan, why = tree.plan({ { id = "heading" }, { path = "" } }, ctx)
    eq(plan, nil, "nodes without a path: nothing to run")
    eq(why, nil, "... and nothing to say")
    plan, why = tree.plan(nil, ctx)
    eq(plan, nil, "no nodes: nothing to run")
    eq(why, nil, "... and nothing to say")
  end

  -- the tree's editor buffer is no file (a terminal, a list): it is no side of a comparison
  do
    reset()
    vim.api.nvim_buf_set_name(0, "diff-spec-list")
    vim.bo.buftype = "nofile"
    local special_buf = vim.api.nvim_get_current_buf()
    vim.cmd("topleft 30vnew")
    vim.bo.buftype = "nofile"
    local ctx = { win = vim.api.nvim_get_current_win(), alt_buf = special_buf }
    local none, why = tree.plan({ { path = right } }, ctx)
    eq(none, nil, "one file is not compared with a buffer that is no file")
    ok(why:find("no editor window", 1, true) ~= nil, "... and says so: " .. why)
    local plan = tree.plan({ { path = left }, { path = right } }, ctx)
    eq(plan.win, nil, "two files do not start from its window either")
    eq(plan.args.view, "tab", "... they open in a tab of their own")
  end

  -- a tab page with nothing but the tree
  do
    reset()
    vim.bo.buftype = "nofile"
    local ctx = { win = vim.api.nvim_get_current_win() }
    local plan = tree.plan({ { path = left }, { path = right } }, ctx)
    eq(plan.win, nil, "without an editor window there is none to start from")
    eq(plan.args.view, "tab", "... so two files open in a tab of their own")
    plan = tree.plan({ { path = left_dir }, { path = right_dir } }, ctx)
    eq(plan.args.view, nil, "a directory diff has no view to choose")
    local none, why = tree.plan({ { path = right } }, ctx)
    eq(none, nil, "one file has no editor window to be compared with")
    ok(why:find("no editor window", 1, true) ~= nil, "... and says so: " .. why)
    vim.bo.buftype = ""
  end

  -- run: what the entry does ------------------------------------------------------
  do
    local tree_win, editor_win, editor_buf = tree_layout()
    local ctx = { win = tree_win, alt_buf = editor_buf }
    local runs = {}
    local ran = tree.compare({ { path = left }, { path = right } }, ctx, function(args)
      runs[#runs + 1] = { args = args, win = vim.api.nvim_get_current_win() }
    end)
    eq(ran, true, "compare answers true when it ran")
    eq(#runs, 1, "... once")
    eq(runs[1].win, editor_win, "... with the editor window current")

    vim.api.nvim_set_current_win(tree_win)
    runs = {}
    local said = notices(function()
      ran = tree.compare({ { path = left_dir } }, ctx, function(args)
        runs[#runs + 1] = args
      end)
    end)
    eq(ran, false, "compare answers false when something is missing")
    eq(#runs, 0, "... runs nothing")
    eq(#said, 1, "... says one thing")
    ok(said[1]:find("second folder", 1, true) ~= nil, "... which is what is missing: " .. said[1])
    eq(vim.api.nvim_get_current_win(), tree_win, "... and leaves the cursor in the tree")

    said = notices(function()
      ran = tree.compare({}, ctx)
    end)
    eq(ran, false, "no node: nothing runs")
    eq(#said, 0, "... and nothing is said")
  end

  -- for real: two marked files, through the registered entry
  do
    local tree_win, _, editor_buf = tree_layout()
    local said = notices(function()
      entry().run({ { path = left }, { path = right } }, { win = tree_win, alt_buf = editor_buf })
    end)
    eq(#said, 0, "two files compare without a message: " .. table.concat(said, " | "))
    local shown, right_of_tree = {}, true
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.wo[win].diff then
        shown[#shown + 1] =
          table.concat(vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win), 0, -1, false), ",")
        right_of_tree = right_of_tree and vim.api.nvim_win_get_position(win)[2] > 0
      end
    end
    table.sort(shown)
    ok(
      vim.deep_equal(shown, { "one,TWO", "one,two" }),
      "both files are shown in diff mode: " .. vim.inspect(shown)
    )
    ok(not vim.wo[tree_win].diff, "the tree window is not part of the diff")
    -- a split out of the tree window would stand in its column and push the tree aside
    eq(vim.api.nvim_win_get_position(tree_win)[2], 0, "... and stays at the left edge")
    ok(right_of_tree, "... with both sides of the diff right of it")
  end

  -- for real: one file against the editor's buffer, which stays the live left side
  do
    local tree_win, editor_win, editor_buf = tree_layout()
    notices(function()
      entry().run({ { path = right } }, { win = tree_win, alt_buf = editor_buf })
    end)
    ok(vim.wo[editor_win].diff, "the editor window is in diff mode")
    eq(vim.api.nvim_win_get_buf(editor_win), editor_buf, "... still showing its own buffer")
    ok(not vim.wo[tree_win].diff, "the tree window is not part of the diff")
  end

  -- for real: two marked folders
  do
    local tree_win, _, editor_buf = tree_layout()
    notices(function()
      entry().run(
        { { path = left_dir }, { path = right_dir } },
        { win = tree_win, alt_buf = editor_buf }
      )
    end)
    local summary =
      table.concat(vim.api.nvim_buf_get_lines(vim.api.nvim_get_current_buf(), 0, -1, false), "\n")
    ok(summary:find("a b.txt", 1, true) ~= nil, "two folders: the summary names the changed file")
    ok(summary:find("only here.txt", 1, true) ~= nil, "... and the added one")
    ok(vim.api.nvim_get_current_win() ~= tree_win, "... outside the tree window")
  end

  -- the option ------------------------------------------------------------------------
  reset()
  eq(#setup({ tree = { key = "<leader>dc" } }), 0, "tree = { key = ... } raises no issue")
  eq(entry().key, "<leader>dc", "... and puts the action on that key")
  local count = 0
  for _, e in ipairs(registry.list("action")) do
    if e.name == tree.NAME then
      count = count + 1
    end
  end
  eq(count, 1, "... as one entry, not two")

  setup({ tree = { key = { "<leader>dc", "gC" } } })
  ok(vim.deep_equal(entry().key, { "<leader>dc", "gC" }), "a key may be several keys")

  setup({ tree = { key = false } })
  ok(entry() ~= nil, "a key of false offers the action")
  eq(entry().key, nil, "... without a key")
  setup({ tree = {} })
  ok(entry() ~= nil and entry().key == nil, "an empty table offers it without a key")

  for _, bad in ipairs({ "yes", 7, { key = 7 }, { key = "" }, { key = {} }, { keys = "x" } }) do
    local issues = setup({ tree = bad })
    eq(#issues, 1, "a value that is none is one issue: " .. vim.inspect(bad))
    ok(issues[1]:find("option 'tree'", 1, true) ~= nil, "... naming the option: " .. issues[1])
    ok(entry() ~= nil and entry().key == nil, "... and the default (offered, no key) stays")
  end

  setup({ tree = false })
  eq(entry(), nil, "tree = false takes the action out")
  setup()
  ok(entry() ~= nil, "the default offers it again")

  tree.unregister()
  eq(entry(), nil, "unregister removes it")
  tree.unregister()
  eq(entry(), nil, "... and a second unregister is harmless")
  eq(tree.register(), true, "register() answers true with a registry")
  local remove_other = registry.action({ name = tree.NAME, run = function() end })
  tree.unregister()
  ok(entry() ~= nil, "an entry that replaced ours stays when we unregister")
  remove_other()

  reset()
  vim.fn.delete(dir, "rf")
end
