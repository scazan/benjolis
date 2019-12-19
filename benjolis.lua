local ControlSpec = require "controlspec"
engine.name = 'Benjolis'

local encoders = {
  0, 0, 0
}

local buttons = {
  0, 0, 0
}

local midiDevice

local function midi_event(data)
  local msg = midi.to_msg(data)

  if (msg.type == 'cc') then
    -- onExternalEncoder(msg.cc + 1, (msg.val - 64))
  end
end

function init()
  midiDevice = midi.connect(1)

  midiDevice.event = midi_event

  -- show engine commands available
  engine.list_commands()
  
  params:add{type = "number", id = "midi_device", name = "MIDI Device", min = 1, max = 4, default = 1, action = function(value)
    midi_in_device.event = nil
    midi_in_device = midi.connect(value)
    midi_in_device.event = midi_event
  end}
  
  local spec = ControlSpec.new(0,127, "lin", 0, 1, "");
  local channels = {"All"}
  for i = 1, 16 do table.insert(channels, i) end
  params:add{type = "option", id = "midi_channel", name = "MIDI Channel", options = channels}
  
  params:add_separator()
  
  params:add{type = "control", controlspec = spec, id = "setFreq1", name = "frequency 1", action = engine.setFreq1}
  params:add{type = "control", controlspec = spec, id = "setFreq2", name = "frequency 2", action = engine.setFreq2}
  params:add{type = "control", controlspec = spec, id = "setFiltFreq", name = "filter frequency", action = engine.setFiltFreq}
  params:add{type = "control", controlspec = spec, id = "setFilterType", name = "filter type", action = engine.setFilterType}
  params:add_separator()
  params:add{type = "control", controlspec = spec, id = "setLoop", name = "loop", action = engine.setLoop}
  params:add{type = "control", controlspec = spec, id = "setRunglerFilt", name = "rungler filter frequency", action = engine.setRunglerFilt}
  params:add{type = "control", controlspec = spec, id = "setQ", name = "set Q", action = engine.setQ}
  params:add_separator()
  params:add{type = "control", controlspec = spec, id = "setRungler1", name = "set rungler 1 frequency", action = engine.setRungler1}
  params:add{type = "control", controlspec = spec, id = "setRungler2", name = "set rungler 2 frequency", action = engine.setRungler2}
  params:add{type = "control", controlspec = spec, id = "setScale", name = "set scale", action = engine.setScale}
  params:add_separator()
  params:add{type = "control", controlspec = spec, id = "setOutSignal", name = "out signal", action = engine.setOutSignal}
  params:add{type = "control", controlspec = spec, id = "setGain", name = "gain", action = engine.setGain}
  
end
  
-- encoder function
function enc(n, delta)
  encoders[n] = encoders[n] + delta

  if (encoders[n] > 100) then
    encoders[n] = 100
  else
    if (encoders[n] < 0) then
      encoders[n] = 0
    end
  end

  print(encoders[n])
  if ((n == 2)) then
    engine.setFiltFreq(encoders[n] / 100)
  else
    engine.setRungler1(encoders[n] / 100)
  end
  -- redraw screen
  redraw()
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
  -- screen: turn on anti-alias
  screen.aa(1)
  screen.line_width(1.0)
  -- clear screen
  screen.clear()
  -- set pixel brightness (0-15)
  screen.level(15)

  local glissSymbol = "O";
  if (glissMode) then
    glissSymbol = "|"; 
  end
  screen.move(45, 15)
  screen.text(glissSymbol)
  screen.move(35, 15)
  screen.text(glissSymbol)
  screen.move(45, 25)
  screen.text(glissSymbol)
  screen.move(35, 25)
  screen.text(glissSymbol)
  
  local glissSymbolLow = "O";
  if (glissModeLow) then
    glissSymbolLow = "|"; 
  end
  screen.move(85, 35)
  screen.text(glissSymbolLow)
  screen.move(75, 35)
  screen.text(glissSymbolLow)
  screen.move(85, 45)
  screen.text(glissSymbolLow)
  screen.move(75, 45)
  screen.text(glissSymbolLow)

  -- show timer
  screen.move(0, 56)
  screen.text("benjolis")

  -- refresh screen
  screen.update()
end