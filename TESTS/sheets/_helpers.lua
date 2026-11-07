-- TESTS/sheets/_helpers.lua -- what the diff.nvim test sheets need in their child editor. Not a sheet
-- (`testing.sheet` only reads *.sheet.lua); a sheet's first step runs it with `dofile`, the child's cwd is the
-- project root. The directory is in the spec's @cache-inputs, so a change here re-runs the sheets.

-- ui.nvim holds the `ui.kit` the pickers and prompts of :Diff use. TESTS/minimal_init.lua finds it (a missing one is
-- fatal, so this is never a skip that does not run on CI) and leaves it to the sheets, the specs run without it.
vim.opt.rtp:append(vim.g.diff_sheets_ui_nvim)

vim.opt.shortmess:append("I")
vim.o.swapfile = false
vim.o.hidden = true

---Whether a toast of diff.nvim so far holds `text` (plain), read from the history behind `:Lib notify history`.
---@param text string
---@return boolean
function _G.noted(text)
  for _, entry in ipairs(require("lib.nvim.notify.popup").history("diff")) do
    if tostring(entry.message):find(text, 1, true) then
      return true
    end
  end
  return false
end

---Forget the toasts so far.
function _G.forget()
  require("lib.nvim.notify.popup").clear("diff")
end

---`text` holds `part` (plain), or an error that shows the text.
---@param text string
---@param part string
---@return boolean
function _G.has(text, part)
  if not tostring(text):find(part, 1, true) then
    error(("no %s in %s"):format(vim.inspect(part), vim.inspect(text)), 0)
  end
  return true
end

---The lines of a buffer (default the current one) as one string, joined by a newline.
---@param buf integer|nil
---@return string
function _G.text(buf)
  return table.concat(vim.api.nvim_buf_get_lines(buf or 0, 0, -1, false), "\n")
end

---The normal (not floating) windows of this tab.
---@return integer[]
function _G.wins()
  return vim.tbl_filter(function(w)
    return vim.api.nvim_win_get_config(w).relative == ""
  end, vim.api.nvim_tabpage_list_wins(0))
end

---The windows of this tab in diffmode.
---@return integer[]
function _G.diffwins()
  return vim.tbl_filter(function(w)
    return vim.wo[w].diff
  end, vim.api.nvim_tabpage_list_wins(0))
end

---The buffer whose name holds `part` (plain), or nil.
---@param part string
---@return integer|nil
function _G.buf_named(part)
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_name(b):find(part, 1, true) then
      return b
    end
  end
  return nil
end

---The focused float is a dialog of the kit and its text holds `part`.
---@param part string
---@return boolean
function _G.dialog(part)
  return vim.api.nvim_win_get_config(0).relative ~= "" and _G.text():find(part, 1, true) ~= nil
end

---A fresh temp directory as the cwd of the editor: the sheets name their files relative to it.
---@return string
function _G.sandbox()
  local dir = vim.fs.normalize(vim.fn.tempname())
  vim.fn.mkdir(dir, "p")
  vim.fn.chdir(dir)
  return dir
end

---Write a file below the cwd, parents included.
---@param path string
---@param lines string[]
function _G.write(path, lines)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  vim.fn.writefile(lines, path)
end

---Edit a file.
---@param path string
function _G.open(path)
  vim.cmd.edit(vim.fn.fnameescape(path))
end

---Run git in the cwd; a failure raises unless `allow_fail`. Identity, signing and line endings are fixed here so the
---throwaway history is the same on every machine.
---@param args string[]
---@param allow_fail boolean|nil
---@return string stdout
function _G.git(args, allow_fail)
  local cmd = {
    "git",
    "-c",
    "user.name=sheet",
    "-c",
    "user.email=sheet@example.invalid",
    "-c",
    "commit.gpgsign=false",
    "-c",
    "core.autocrlf=false",
    "-c",
    "init.defaultBranch=main",
  }
  vim.list_extend(cmd, args)
  local res = vim.system(cmd, { text = true }):wait()
  if res.code ~= 0 and not allow_fail then
    error(table.concat(args, " ") .. ": " .. tostring(res.stderr), 0)
  end
  return res.stdout or ""
end

---Commit everything in the cwd.
---@param msg string
function _G.commit(msg)
  _G.git({ "add", "." })
  _G.git({ "commit", "-q", "-m", msg })
end

---The lines of a.txt in version `n`: line 3 names the version.
---@param n integer
---@return string[]
function _G.version(n)
  return { "alpha", "beta", "version " .. n, "gamma", "delta" }
end

---A throwaway repository in a fresh sandbox, five commits:
---  a.txt changes in every one (version 1 to 5); old.txt changes in c2 and becomes new.txt in c4.
---  many.txt comes in c5, so it has one commit only.
---@return string dir
function _G.history_repo()
  local dir = _G.sandbox()
  _G.git({ "init", "-q" })
  local moved = {}
  for i = 1, 12 do
    moved[i] = "rename line " .. i
  end
  _G.write("a.txt", _G.version(1))
  _G.write("old.txt", moved)
  _G.commit("step-1")
  moved[3] = "changed in c2"
  _G.write("a.txt", _G.version(2))
  _G.write("old.txt", moved)
  _G.commit("step-2")
  _G.write("a.txt", _G.version(3))
  _G.commit("step-3")
  _G.git({ "mv", "old.txt", "new.txt" })
  _G.write("a.txt", _G.version(4))
  _G.commit("step-4")
  _G.write("a.txt", _G.version(5))
  _G.write("many.txt", { "only one commit" })
  _G.commit("step-5")
  return dir
end

---A repository in the middle of a real merge conflict on c.txt: ours says "ours", theirs says "theirs", the ancestor
---"ancestor".
---@return string dir
function _G.conflict_repo()
  local dir = _G.sandbox()
  _G.git({ "init", "-q" })
  _G.write("c.txt", { "top", "ancestor", "bottom" })
  _G.commit("base")
  _G.git({ "checkout", "-q", "-b", "theirs" })
  _G.write("c.txt", { "top", "theirs", "bottom" })
  _G.commit("theirs")
  _G.git({ "checkout", "-q", "main" })
  _G.write("c.txt", { "top", "ours", "bottom" })
  _G.commit("ours")
  _G.git({ "merge", "theirs" }, true)
  return dir
end

---Load diff.nvim anew with these options, as a scratch config would: `setup()` is one-shot by design.
---@param opts table|nil
---@param keep_gh boolean|nil  A `gh` mapped by the "user" stays
function _G.reload(opts, keep_gh)
  for name in pairs(package.loaded) do
    if name == "diff" or name:match("^diff%.") then
      package.loaded[name] = nil
    end
  end
  for _, cmd in ipairs({
    "Diff",
    "DiffClear",
    "DiffBuffers",
    "DiffOrig",
    "DiffHistory",
    "DiffExit",
    "DiffProfile",
  }) do
    pcall(vim.api.nvim_del_user_command, cmd)
  end
  if not keep_gh then
    pcall(vim.keymap.del, "n", "gh")
  end
  vim.g.loaded_diff = nil
  require("diff").setup(opts or {})
end

---Set a `diff.*` option for the next commands, through the validation of `setup()`.
---@param opts table
function _G.set_diff(opts)
  require("diff.config").setup({ diff = opts })
end

---Close everything down to one empty window, for the next layout check.
function _G.only()
  pcall(function()
    require("diff").clear()
  end)
  vim.cmd("silent! tabonly")
  vim.cmd("silent! only")
  vim.cmd("silent! diffoff!")
  _G.forget()
end

---The lines of the quickfix list, as `text` of each entry.
---@return integer count
function _G.qf_count()
  return #vim.fn.getqflist()
end

---A small HTTP server in this editor, on a free local port: `/slow` answers after 300 ms with a file that differs from
---local.txt in line 2, anything else is a 404. The real curl fetches from it, nothing leaves the machine.
function _G.serve()
  local server = assert(vim.uv.new_tcp())
  assert(server:bind("127.0.0.1", 0))
  assert(server:listen(16, function()
    local client = assert(vim.uv.new_tcp())
    server:accept(client)
    client:read_start(function(_, data)
      if not data then
        return
      end
      client:read_stop()
      local path = data:match("^GET (%S+)")
      local body = path == "/slow" and "one\nSERVED\nthree\n" or "<html>not found</html>\n"
      local status = path == "/slow" and "200 OK" or "404 Not Found"
      local answer = ("HTTP/1.1 %s\r\nContent-Length: %d\r\nConnection: close\r\n\r\n%s"):format(
        status,
        #body,
        body
      )
      local timer = assert(vim.uv.new_timer())
      timer:start(path == "/slow" and 300 or 0, 0, function()
        timer:close()
        client:write(answer, function()
          client:close()
        end)
      end)
    end)
  end))
  _G.port = server:getsockname().port
end

---The URL of `path` on the server of `_G.serve`.
---@param path string
---@return string
function _G.url(path)
  return ("http://127.0.0.1:%d%s"):format(_G.port, path)
end

-- Every sheet without its own wish uses the kit's dialogs, not whatever pickers.nvim a developer has beside the repo.
_G.NO_PICKERS = { use_pickers_nvim = false }
