local UI = require "ui"
local ControlSpec = require "controlspec"
engine.name = 'Benjolis'

local encoders = {
  0, 0, 0
}

local buttons = {
  0, 0, 0
}

local SCREEN_FRAMERATE = 15
local screen_refresh_metro
local screen_dirty = true

function init()
  -- show engine commands available
  engine.list_commands()
  
  params:add{type = "number", id = "midi_device", name = "MIDI Device", min = 1, max = 4, default = 1, action = function(value)
    midi_in_device.event = nil
    midi_in_device = midi.connect(value)
    midi_in_device.event = midi_event
  end}
  
  local spec = ControlSpec.new(0, 1, "lin", 0, 0.5, "");
  local channels = {"All"}
  for i = 1, 16 do table.insert(channels, i) end
  params:add{type = "option", id = "midi_channel", name = "MIDI Channel", options = channels}
  
  params:add_separator()
  
  params:add{type = "control", controlspec = ControlSpec.new( 20.0, 14000.0, "exp", 0, 70, "Hz"), id = "setFreq1", name = "frequency 1", action = engine.setFreq1}
  params:add{type = "control", controlspec = ControlSpec.new( 0.1, 14000.0, "exp", 0, 4, "Hz"), id = "setFreq2", name = "frequency 2", action = engine.setFreq2}
  params:add{type = "control", controlspec = ControlSpec.new( 20.0, 20000.0, "exp", 0, 40, "Hz"), id = "setFiltFreq", name = "filter frequency", action = engine.setFiltFreq}
  params:add{type = "control", controlspec = ControlSpec.new(0, 1, "lin", 1, 0.5, ""), id = "setFilterType", name = "filter type", action = engine.setFilterType}

  params:add_separator()
  params:add{type = "control", controlspec = ControlSpec.new( 0.0, 1.0, "lin", 0, 1), id = "setLoop", name = "loop", action = engine.setLoop}
  params:add{type = "control", controlspec = ControlSpec.new( 0.0, 1.0, "lin", 0, 9), id = "setRunglerFilt", name = "rungler filter frequency", action = engine.setRunglerFilt}
  params:add{type = "control", controlspec = ControlSpec.new( 0.0, 1.0, "lin", 0, 0.82), id = "setQ", name = "set Q", action = engine.setQ}

  params:add_separator()
  params:add{type = "control", controlspec = ControlSpec.new( 0.0, 1.0, "lin", 0, 0.16), id = "setRungler1", name = "set rungler 1 frequency", action = engine.setRungler1}
  params:add{type = "control", controlspec = ControlSpec.new( 0.0, 1.0, "lin", 0, 0), id = "setRungler2", name = "set rungler 2 frequency", action = engine.setRungler2}
  params:add{type = "control", controlspec = ControlSpec.new( 0.0, 1.0, "lin", 0, 1), id = "setScale", name = "set scale", action = engine.setScale}

  params:add_separator()
  params:add{type = "control", controlspec = ControlSpec.new( 0.0, 6.0, "lin", 1, 6), id = "setOutSignal", name = "out signal", action = engine.setOutSignal}
  params:add{type = "control", controlspec = ControlSpec.new( 0.0, 6.0, "lin", 1, 6), id = "setGain", name = "gain", action = engine.setGain}
  
  -- GUI
  
  -- screen: turn on anti-alias
  screen.aa(1)
  screen.line_width(1.0)
  scrolling_list = UI.ScrollingList.new(8, 8, 1, {
    "freqs: "..params:get("setFreq1").."hz : "..params:get("setFreq2").."hz",
    "filter: "..params:get("setFiltFreq").."hz   type: "..params:get("setFilterType"),
    "loop: "..params:get("setLoop"),
    "rungler filter: "..params:get("setRunglerFilt").."hz  Q: "..params:get("setQ"),
    "runglers: "..params:get("setRungler1").."hz : "..params:get("setRungler2").."hz",
    "scale: "..params:get("setScale").." out: "..params:get("setOutSignal"),
  })

  -- Start drawing to screen
  screen_refresh_metro = metro.init()
  screen_refresh_metro.event = function()
    if screen_dirty then
      screen_dirty = false
      redraw()
    end
  end
  screen_refresh_metro:start(1 / SCREEN_FRAMERATE)
  
end
  
-- encoder function
function enc(n, delta)
    if n == 1 then
      scrolling_list:set_index_delta(util.clamp(delta, -1, 1))
    end
    
  screen_dirty = true
end

-- key function
function key(n, z)
  buttons[n] = z
  local shift = buttons[1]

  if (shift == 1) then
    print("shift", n, z)
  else
    if ((z == 0) and (n == 2)) then
    elseif ((z == 0) and (n == 3)) then
    end
  end

  redraw()
end

-- screen redraw function
function redraw()
  -- clear screen
  screen.clear()
  
  -- set pixel brightness (0-15)
  screen.level(1)

  -- show title
  screen.move(95, 8)
  screen.text("benjolis")

  screen.level(15)
  scrolling_list:redraw()
  
  -- refresh screen
  screen.update()
end
