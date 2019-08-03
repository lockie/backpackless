require("love.event")
local fennel = require("lib.fennel")
local view = require("lib.fennelview")
local event, channel = ...
local function display(s)
  io.write(s)
  return io.flush()
end
local function prompt()
  return display("\n>> ")
end
local function read_chunk()
  local input = io.read()
  if input then
    return (input .. "\n")
  end
end
local input = ""
local function _0_(...)
  if channel then
    local bytestream, clearstream = fennel.granulate(read_chunk)
    local read = read
    local function _0_()
      local c = (bytestream() or 10)
      input = (input .. string.char(c))
      return c
    end
    read = fennel.parser(_0_)
    while true do
      prompt()
      input = ""
      do
        local ok, ast = pcall(read)
        if not ok then
          display(("Parse error:" .. ast .. "\n"))
        else
          love.event.push(event, input)
          display(channel:demand())
        end
      end
    end
    return nil
  end
end
_0_(...)
local function start_repl()
  local code = love.filesystem.read("lib/stdio.fnl")
  local luac = luac
  if code then
    luac = love.filesystem.newFileData(fennel.compileString(code), "io")
  else
    luac = love.filesystem.read("lib/stdio.lua")
  end
  local thread = love.thread.newThread(luac)
  local io_channel = love.thread.newChannel()
  thread:start("eval", io_channel)
  local function _2_(input)
    local ok, val = pcall(fennel.eval, input)
    local function _3_()
      if ok then
        return view(val)
      else
        return val
      end
    end
    return io_channel:push(_3_())
  end
  love.handlers.eval = _2_
  return nil
end
return {start = start_repl}
