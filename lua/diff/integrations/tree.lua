---@module 'diff.integrations.tree'
--- "Compare" as an action on nodes of a tree view.
---
--- Registers one action at `lib.nvim.tree.registry`. A tree that reads the
--- registry (the own tree of filetree.nvim) offers it on every node that is a
--- file or a folder on disk: in its context menu, in its action list, and on a
--- key when one is configured.
---
---   two nodes marked     the first against the second: file against file
---                        (the configured view), folder against folder (the
---                        directory diff)
---   one node, a file     the file of the editor window against it, with that
---                        window's live buffer as the left-hand side
---
--- Anything else says what is missing instead of guessing a second side. The
--- paths go to `require("diff").run()` as a table, so a name with a blank in it
--- is taken as it is.
---
--- Soft in both directions. The registry is lib.nvim's: without a tree that
--- reads it the entry is never looked at, and without a lib.nvim that has the
--- registry nothing is registered.

local api = vim.api
local fn = vim.fn

local M = {}

M.NAME = "diff.compare"

---What a tree hands an action besides the nodes; only what is read here.
---@class DiffNvim.Tree.Ctx
---@field alt_buf? integer  The editor buffer the tree belongs to
---@field win? integer      The window of the tree

---What `plan` decided to run.
---@class DiffNvim.Tree.Plan
---@field args table<string, string>  The arguments of `require("diff").run()`
---@field win? integer                The window the diff starts from; nil: stay where the cursor is

---@type (fun(): boolean)|nil
local unregister = nil

---@param path string
---@return "dir"|"file"|nil kind  nil: not on disk
local function kind_of(path)
  if fn.isdirectory(path) == 1 then
    return "dir"
  elseif fn.filereadable(path) == 1 then
    return "file"
  end
  return nil
end

---Two spellings of one path, as far as that can be told without the disk.
---@param a string
---@param b string
---@return boolean
local function same_path(a, b)
  a, b = vim.fs.normalize(a), vim.fs.normalize(b)
  if fn.has("win32") == 1 then
    a, b = a:lower(), b:lower()
  end
  return a == b
end

---A path as a message shows it: below the cwd or the home directory where it lies there (a tree
---hands over absolute paths, and a message has one line).
---@param path string
---@return string
local function shown(path)
  return fn.fnamemodify(path, ":~:.")
end

---A window of this tab page that shows a file, to start the diff from: the tree is a narrow
---side window, and a diff split out of it would be as narrow. The window of the editor buffer
---the tree belongs to when it is on screen, else the first window with an ordinary buffer that
---is not the tree's.
---@param ctx DiffNvim.Tree.Ctx
---@return integer|nil win
local function editor_win(ctx)
  local alt = ctx.alt_buf
  -- an ordinary buffer only: a terminal or a scratch list is no side of a file comparison
  if type(alt) == "number" and api.nvim_buf_is_valid(alt) and vim.bo[alt].buftype == "" then
    local win = fn.bufwinid(alt)
    if win ~= -1 and win ~= ctx.win then
      return win
    end
  end
  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
    if
      win ~= ctx.win
      and api.nvim_win_get_config(win).relative == ""
      and vim.bo[api.nvim_win_get_buf(win)].buftype == ""
    then
      return win
    end
  end
  return nil
end

---Decide what to compare. Pure of side effects: nothing is opened and no window changes.
---@param nodes { path?: string }[]|nil  The selection, or the node under the cursor
---@param ctx? DiffNvim.Tree.Ctx
---@return DiffNvim.Tree.Plan|nil plan  nil: nothing to run
---@return string|nil reason            Why not; nil with a nil plan: there was no node with a path
function M.plan(nodes, ctx)
  ctx = type(ctx) == "table" and ctx or {}
  ---@type string[]
  local paths = {}
  for _, node in ipairs(nodes or {}) do
    if type(node) == "table" and type(node.path) == "string" and node.path ~= "" then
      paths[#paths + 1] = node.path
    end
  end
  if #paths == 0 then
    return nil, nil
  end
  if #paths > 2 then
    return nil, ("%d nodes are marked; mark two to compare them"):format(#paths)
  end
  for _, path in ipairs(paths) do
    if not kind_of(path) then
      return nil, ("not a readable file or a folder on disk: %s"):format(shown(path))
    end
  end

  local win = editor_win(ctx)

  if #paths == 2 then
    local a, b = kind_of(paths[1]), kind_of(paths[2])
    if a ~= b then
      local folder = a == "dir" and paths[1] or paths[2]
      local file = a == "dir" and paths[2] or paths[1]
      return nil,
        ("a folder is compared with a folder and a file with a file: %s is a folder, %s is a file"):format(
          shown(folder),
          shown(file)
        )
    end
    ---@type table<string, string>
    local args = { source = paths[1], target = paths[2] }
    -- Two files from a tab page that has no window but the tree: a tab of its own, which needs
    -- no window to split. (A directory diff ignores the view.)
    if a == "file" and not win then
      args.view = "tab"
    end
    return { args = args, win = win }, nil
  end

  -- one node: against the file of the editor window
  local path = paths[1]
  if kind_of(path) == "dir" then
    return nil, ("mark a second folder to compare %s with"):format(shown(path))
  end
  local buf = win and api.nvim_win_get_buf(win) or nil
  local name = buf and api.nvim_buf_get_name(buf) or ""
  if not win or name == "" then
    return nil,
      ("no editor window shows a file to compare %s with; mark two nodes"):format(shown(path))
  end
  if same_path(name, path) then
    return nil,
      ("%s is the file of the editor window; mark a second node to compare it with"):format(
        shown(path)
      )
  end
  return { args = { source = "current", target = path }, win = win }, nil
end

---Compare what `plan` decides on, or say why there is nothing to compare.
---@param nodes { path?: string }[]|nil
---@param ctx? DiffNvim.Tree.Ctx
---@param run? fun(args: table<string, string>)  Default: `require("diff").run`
---@return boolean ran
function M.compare(nodes, ctx, run)
  local plan, reason = M.plan(nodes, ctx)
  if not plan then
    if reason then
      require("diff.util.notify").warn(reason)
    end
    return false
  end
  if plan.win and api.nvim_win_is_valid(plan.win) then
    api.nvim_set_current_win(plan.win)
  end
  run = run or function(args)
    require("diff").run(args)
  end
  run(plan.args)
  return true
end

---Register the action. Without `lib.nvim.tree.registry` (an older lib.nvim) nothing happens.
---@param opts? DiffNvim.Opts.Tree
---@return boolean registered
function M.register(opts)
  local ok, registry = pcall(require, "lib.nvim.tree.registry")
  if not ok or type(registry.action) ~= "function" then
    return false
  end
  M.unregister()
  opts = opts or {}
  unregister = registry.action({
    name = M.NAME,
    desc = "Compare two marked nodes, or this file with the editor's (diff.nvim)",
    key = opts.key or nil,
    needs = { "path" },
    run = function(nodes, ctx)
      M.compare(nodes, ctx)
    end,
  })
  return true
end

---Take the action out again.
---@return nil
function M.unregister()
  if unregister then
    unregister()
    unregister = nil
  end
end

return M
