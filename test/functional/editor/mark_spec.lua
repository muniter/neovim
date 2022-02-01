local helpers = require('test.functional.helpers')(after_each)
local Screen = require('test.functional.ui.screen')
local meths = helpers.meths
local curbufmeths = helpers.curbufmeths
local clear = helpers.clear
local command = helpers.command
local funcs = helpers.funcs
local eq = helpers.eq
local feed = helpers.feed
local write_file = helpers.write_file
local pcall_err = helpers.pcall_err
local cursor = function() return helpers.meths.win_get_cursor(0) end

describe('named marks', function()
  local file1 = 'Xtestfile-functional-editor-marks'
  local file2 = 'Xtestfile-functional-editor-marks-2'
  before_each(function()
    clear()
    write_file(file1, '1test1\n1test2\n1test3\n1test4', false, false)
    write_file(file2, '2test1\n2test2\n2test3\n2test4', false, false)
  end)
  after_each(function()
    os.remove(file1)
    os.remove(file2)
  end)


  it("can be set", function()
    command("edit " .. file1)
    command("mark a")
    eq({1, 0}, curbufmeths.get_mark("a"))
    feed("jmb")
    eq({2, 0}, curbufmeths.get_mark("b"))
    feed("jmB")
    eq({3, 0}, curbufmeths.get_mark("B"))
    command("4kc")
    eq({4, 0}, curbufmeths.get_mark("c"))
  end)

  it("errors when set out of range with :mark", function()
    command("edit " .. file1)
    local err = pcall_err(helpers.exec_capture, "1000mark x")
    eq("Vim(mark):E16: Invalid range: 1000mark x", err)
  end)

  it("errors when set out of range with :k", function()
    command("edit " .. file1)
    local err = pcall_err(helpers.exec_capture, "1000kx")
    eq("Vim(k):E16: Invalid range: 1000kx", err)
  end)

  it("errors on unknown mark name with :mark", function()
    command("edit " .. file1)
    local err = pcall_err(helpers.exec_capture, "mark #")
    eq("Vim(mark):E191: Argument must be a letter or forward/backward quote", err)
  end)

  it("errors on unknown mark name with '", function()
    command("edit " .. file1)
    local err = pcall_err(helpers.exec_capture, "normal! '#")
    eq("Vim(normal):E78: Unknown mark", err)
  end)

  it("errors on unknown mark name with `", function()
    command("edit " .. file1)
    local err = pcall_err(helpers.exec_capture, "normal! `#")
    eq("Vim(normal):E78: Unknown mark", err)
  end)

  it("errors when moving to a mark that is not set with '", function()
    command("edit " .. file1)
    local err = pcall_err(helpers.exec_capture, "normal! 'z")
    eq("Vim(normal):E20: Mark not set", err)
    err = pcall_err(helpers.exec_capture, "normal! '.")
    eq("Vim(normal):E20: Mark not set", err)
  end)

  it("errors when moving to a mark that is not set with `", function()
    command("edit " .. file1)
    local err = pcall_err(helpers.exec_capture, "normal! `z")
    eq("Vim(normal):E20: Mark not set", err)
    err = pcall_err(helpers.exec_capture, "normal! `>")
    eq("Vim(normal):E20: Mark not set", err)
  end)

  it("errors when moving to a global mark that is not set with '", function()
    command("edit " .. file1)
    local err = pcall_err(helpers.exec_capture, "normal! 'Z")
    eq("Vim(normal):E20: Mark not set", err)
  end)

  it("errors when moving to a global mark that is not set with `", function()
    command("edit " .. file1)
    local err = pcall_err(helpers.exec_capture, "normal! `Z")
    eq("Vim(normal):E20: Mark not set", err)
  end)

  it("can move to them using \'", function()
    command("args " .. file1 .. " " .. file2)
    feed("j")
    feed("ma")
    feed("G'a")
    eq({2, 0}, cursor())
    feed("mA")
    command("next")
    feed("'A")
    eq(1, meths.get_current_buf().id)
    eq({2, 0}, cursor())
  end)

  it("can move to them using `", function()
    command("args " .. file1 .. " " .. file2)
    feed("jll")
    feed("ma")
    feed("G`a")
    eq({2, 2}, cursor())
    feed("mA")
    command("next")
    feed("`A")
    eq(1, meths.get_current_buf().id)
    eq({2, 2}, cursor())
  end)

  it("can move to them using g'", function()
    command("args " .. file1 .. " " .. file2)
    feed("jll")
    feed("ma")
    feed("Gg'a")
    eq({2, 0}, cursor())
    feed("mA")
    command("next")
    feed("g'A")
    eq(1, meths.get_current_buf().id)
    eq({2, 0}, cursor())
  end)

  it("can move to them using g`", function()
    command("args " .. file1 .. " " .. file2)
    feed("jll")
    feed("ma")
    feed("Gg`a")
    eq({2, 2}, cursor())
    feed("mA")
    command("next")
    feed("g`A")
    eq(1, meths.get_current_buf().id)
    eq({2, 2}, cursor())
  end)

  it("errors when it can't find the buffer", function()
    command("args " .. file1 .. " " .. file2)
    feed("mA")
    command("next")
    command("bw! " .. file1 )
    local err = pcall_err(helpers.exec_capture, "normal! 'A")
    eq("Vim(normal):E92: Buffer 1 not found", err)
    os.remove(file1)
  end)

  it("leave a context mark when moving with '", function()
    command("edit " .. file1)
    feed("llmamA")
    feed("10j0")  -- first col, last line
    local pos = cursor()
    feed("'a")
    feed("<C-o>")
    eq(pos, cursor())
    feed("'A")
    feed("<C-o>")
    eq(pos, cursor())
  end)

  it("leave a context mark when moving with `", function()
    command("edit " .. file1)
    feed("llmamA")
    feed("10j0")  -- first col, last line
    local pos = cursor()
    feed("`a")
    feed("<C-o>")
    eq(pos, cursor())
    feed("`A")
    feed("<C-o>")
    eq(pos, cursor())
  end)

  it("leave a context mark when the mark changes buffer with g'", function()
    command("args " .. file1 .. " " .. file2)
    local pos
    feed("GmA")
    command("next")
    pos = cursor()
    command("clearjumps")
    feed("g'A")  -- since the mark is in another buffer, it leaves a context mark
    feed("<C-o>")
    eq(pos, cursor())
  end)

  it("leave a context mark when the mark changes buffer with g`", function()
    command("args " .. file1 .. " " .. file2)
    local pos
    feed("GmA")
    command("next")
    pos = cursor()
    command("clearjumps")
    feed("g`A")  -- since the mark is in another buffer, it leaves a context mark
    feed("<C-o>")
    eq(pos, cursor())
  end)

  it("do not leave a context mark when moving with g'", function()
    command("edit " .. file1)
    local pos
    feed("ma")
    pos = cursor() -- Mark pos
    feed("10j0")  -- first col, last line
    feed("g'a")
    feed("<C-o>") -- should do nothing
    eq(pos, cursor())
    feed("mA")
    pos = cursor() -- Mark pos
    feed("10j0")  -- first col, last line
    feed("g'a")
    feed("<C-o>") -- should do nothing
    eq(pos, cursor())
  end)

  it("do not leave a context mark when moving with g`", function()
    command("edit " .. file1)
    local pos
    feed("ma")
    pos = cursor() -- Mark pos
    feed("10j0")  -- first col, last line
    feed("g`a")
    feed("<C-o>") -- should do nothing
    eq(pos, cursor())
    feed("mA")
    pos = cursor() -- Mark pos
    feed("10j0")  -- first col, last line
    feed("g'a")
    feed("<C-o>") -- should do nothing
    eq(pos, cursor())
  end)

  it("open folds when moving to them", function()
    command("edit " .. file1)
    feed("jzfG") -- Fold from the second line to the end
    command("3mark a")
    feed("G") -- On top of the fold
    assert(funcs.foldclosed('.') ~= -1) -- folded
    feed("'a")
    eq(-1, funcs.foldclosed('.'))

    feed("zc")
    assert(funcs.foldclosed('.') ~= -1) -- folded
    -- TODO: remove this workaround after fixing #15873
    feed("k`a")
    eq(-1, funcs.foldclosed('.'))

    feed("zc")
    assert(funcs.foldclosed('.') ~= -1) -- folded
    feed("kg'a")
    eq(-1, funcs.foldclosed('.'))

    feed("zc")
    assert(funcs.foldclosed('.') ~= -1) -- folded
    feed("kg`a")
    eq(-1, funcs.foldclosed('.'))
  end)

  it("do not open folds when moving to them doesn't move the cursor", function()
    command("edit " .. file1)
    feed("jzfG") -- Fold from the second line to the end
    assert(funcs.foldclosed('.') == 2) -- folded
    feed("ma")
    feed("'a")
    feed("`a")
    feed("g'a")
    feed("g`a")
    -- should still be folded
    eq(2, funcs.foldclosed('.'))
  end)
end)

describe('named marks view', function()
  local file1 = 'Xtestfile-functional-editor-marks'
  local file2 = 'Xtestfile-functional-editor-marks-2'
  local function content()
    local c = {}
    for i=1,30 do
      c[i] = i .. " line"
    end
    return table.concat(c, "\n")
  end
  before_each(function()
    clear()
    write_file(file1, content(), false, false)
    write_file(file2, content(), false, false)
  end)
  after_each(function()
    os.remove(file1)
    os.remove(file2)
  end)

  it('is restored with z\' and z`', function()
      local screen = Screen.new(5, 8)
      screen:attach()
      command("edit " .. file1)
      feed("<C-e>jWma")
      feed("Gz'a") -- move away, come back and use z' to restore the view
      local expected = [[
      2 line      |
      ^3 line      |
      4 line      |
      5 line      |
      6 line      |
      7 line      |
      8 line      |
                  |
      ]]
      screen:expect({grid=expected})
      feed("Gz`a") -- move away and use z` to comeback and restore the view
      screen:expect([[
      2 line      |
      3 ^line      |
      4 line      |
      5 line      |
      6 line      |
      7 line      |
      8 line      |
                  |
      ]])
  end)

  it('is restored with [count]\' and [count]`', function()
      local screen = Screen.new(5, 8)
      screen:attach()
      command("edit " .. file1)
      feed("<C-e>jWma")
      feed("G1'a") -- move away, come back and use <count>'mark to restore the view
      local expected = [[
      2 line      |
      ^3 line      |
      4 line      |
      5 line      |
      6 line      |
      7 line      |
      8 line      |
                  |
      ]]
      screen:expect({grid=expected})
      feed("G1`a") -- move away and use <count>`mark to comeback and restore the view
      screen:expect([[
      2 line      |
      3 ^line      |
      4 line      |
      5 line      |
      6 line      |
      7 line      |
      8 line      |
                  |
      ]])
  end)

  it('is restored across files', function()
    local screen = Screen.new(5, 5)
    screen:attach()
    command("args " .. file1 .. " " .. file2)
    feed("<C-e>mA")
    command("next")
    feed("'A")
    screen:expect([[
    1 line      |
    ^2 line      |
    3 line      |
    4 line      |
                |
    ]])
    feed("z'A")
    screen:expect([[
    ^2 line      |
    3 line      |
    4 line      |
    5 line      |
                |
    ]])
  end)

  it('fallback to standard behavior when view can\'t be recovered', function()
      local screen = Screen.new(10, 10)
      screen:attach()
      command("edit " .. file1)
      feed("7GzbmaG") -- Seven lines from the top
      command("new") -- Screen size for window is now half can't restore
      feed("<C-w>p'az'")
      screen:expect([[
                  |
      ~           |
      ~           |
      ~           |
      [No Name]   |
      6 line      |
      ^7 line      |
      8 line      |
      {MATCH:.*}  |
                  |
      ]])
  end)

  it('can also be used as a motion', function()
    -- Perhaps a user would remap ' to z' so they should work as such
    local screen = Screen.new(5, 5)
    screen:attach()
    command("edit " .. file1)
    command("10")
    feed("ztjma")
    screen:expect([[
    10 line     |
    ^11 line     |
    12 line     |
    13 line     |
                |
    ]])
    feed("Gdz'a")
    screen:expect([[
    ^10 line     |
    ~           |
    ~           |
    ~           |
    {MATCH:.*}|
    ]])
  end)
end)
