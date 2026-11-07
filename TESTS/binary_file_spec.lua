-- TESTS/binary_file_spec.lua -- a file with NUL bytes is a text diff of its bytes, not a Lua error.
--
-- `readfile()` returns a NUL as "\\n" inside a line, and `nvim_buf_set_lines` raises on that: a PNG pair with
-- `diff.image_compare = false` (and :DiffOrig on such a file) ended in a stack trace.

return function(H)
  local eq, ok = H.eq, H.ok
  local diff = require("diff")
  diff.setup({ use_pickers_nvim = false, diff = { image_compare = false } })

  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, "p")
  local a, b = dir .. "/a.png", dir .. "/b.png"
  vim.fn.writefile(vim.fn.eval("0z89504E47000102"), a)
  vim.fn.writefile(vim.fn.eval("0z89504E47000103"), b)

  local resolve = require("diff.core.resolve")
  eq(
    resolve.resolve_lines(a, "target")[1],
    "\137PNG\0\1\2",
    "a NUL is spelled as a buffer spells it"
  )

  local function reset()
    vim.cmd("silent! DiffClear")
    vim.cmd("silent! only")
    vim.cmd("enew!")
  end

  local result, err
  local function on_done(r, e)
    result, err = r, e
  end

  diff.run(("source=%s target=%s"):format(a, b), { on_done = on_done })
  ok(result ~= nil and err == nil, "side by side: a result, no error")
  eq(#result.buffers, 2, "side by side: both sides are scratch buffers")
  eq(
    vim.api.nvim_buf_get_lines(result.buffers[2], 0, -1, false)[1],
    "\137PNG\0\1\3",
    "the target shows its bytes"
  )
  reset()

  result, err = nil, nil
  diff.run(("source=%s target=%s view=inline"):format(a, b), { on_done = on_done })
  ok(result ~= nil and err == nil, "inline: a result, no error")
  local text = table.concat(vim.api.nvim_buf_get_lines(result.buffers[1], 0, -1, false), "\n")
  ok(text:find("+\137PNG\0\1\3", 1, true) ~= nil, "inline: one added line, not cut at the NUL")
  reset()

  vim.cmd.edit(vim.fn.fnameescape(a))
  require("diff.features.origin").run()
  local snap = vim.fn.bufnr("DiffOrig")
  ok(snap ~= -1, ":DiffOrig opens its snapshot")
  eq(
    vim.api.nvim_buf_get_lines(snap, 0, -1, false)[1],
    "\137PNG\0\1\2",
    ":DiffOrig shows the bytes"
  )
  reset()
  vim.fn.delete(dir, "rf")
end
