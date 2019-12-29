-- Benjolis
--
-- A norns version of Alejandro Olarte's Benjolis SC patch
-- Instrument inspired from Rob Hordijk's Benjolin, it requires sc3-plugins (PulseDPW, SVF and DFM1)
-- 
-- UI:
-- Use buttons 2 and 3 to
-- cycle through pairs of dials.
-- 
-- Use encoders 2 and 3 to
-- adjust the left and right
-- dials of the selected
-- pair.
-- 
-- Use encoder 1 to 
-- control volume.
-- 
-- If you hold button 1 (shift)
-- and use button 2, you will
-- have a momentary mute.
-- 
-- If you hold button 1 (shift)
-- and use button 3, you will
-- have a mute that toggles.
--
-- Thanks to Alejandro Olarte
-- for the SynthDef


local UI = require "ui"
local ControlSpec = require "controlspec"
engine.name = 'Benjolis'

local dials = {}
local numDials = 12

local dialValues = {
  0, 0,   0, 0,   0, 0,
  0, 0,   0, 0,   0, 0,
}

local controlPairIndex = 1
local paramsInList = {}

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
  params:add{type = "control", controlspec = ControlSpec.new( 0.0, 1.0, "lin", 0, 1), id = "setAmp", name = "amp", action = engine.setAmp}
  
  -- screen: turn on anti-alias
  screen.aa(1)
  screen.line_width(1.0)
  
  -- IDs and short names
  paramsInList = {
      {"setFreq1", "f1", "hz"},
      {"setFreq2", "f2", "hz"},
      {"setFiltFreq", "flt", "hz"},
      {"setFilterType", "typ", ""},
      {"setRungler1", "r1", "hz"},
      {"setRungler2", "r2", "hz"},
      {"setRunglerFilt", "rflt", "hz"},
      {"setQ", "Q", ""},
      {"setScale", "scl", ""},
      {"setOutSignal", "out", ""},
      {"setLoop", "loop", ""},
      {"setAmp", "vol", ""},
  }
  
  -- GUI
  addDials()
  
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
  
function addDials()
  -- make all the dials
  local dialSpacer = 20
  local row = 0
  local numColumns = 6
  
  for i=1,numDials do
    local xOffset = 5 + (dialSpacer * ((i-1) % numColumns)) 
    local yOffset = 5 + (row * 30)
    local extraSpace = 0;
    
    if ((i % 2) == 1) then
      xOffset = xOffset + 5
    end
    
    dials[i] = UI.Dial.new(xOffset, yOffset, 12, dialValues[i], 0, 1, 0.01, 0, nil, paramsInList[i][3], paramsInList[i][2])
    
    if ((i % numColumns) == 0) then
      row = row + 1
      end
  end
end
    
-- encoder function
function enc(n, delta)
    local dialGroupIndex = (controlPairIndex * 2) - 1
    
    if n == 1 then
      dialValues[12] = util.clamp(dialValues[12] + util.clamp(delta, -0.01, 0.01), 0, 1)
      dials[12]:set_value(dialValues[12])
      params:set_raw("setAmp", dialValues[12])
    elseif n == 2 then
      dialValues[dialGroupIndex] = util.clamp(dialValues[dialGroupIndex] + util.clamp(delta, -0.01, 0.01), 0, 1)
      dials[dialGroupIndex]:set_value(dialValues[dialGroupIndex])
      params:set_raw(paramsInList[dialGroupIndex][1], dialValues[dialGroupIndex])
    elseif n == 3 then
      dialGroupIndex = dialGroupIndex + 1 
      
      dialValues[dialGroupIndex] = util.clamp(dialValues[dialGroupIndex] + util.clamp(delta, -0.01, 0.01), 0, 1)
      dials[dialGroupIndex]:set_value(dialValues[dialGroupIndex])
      params:set_raw(paramsInList[dialGroupIndex][1], dialValues[dialGroupIndex])
    end
      
  screen_dirty = true
end

-- key function
function key(n, z)
  if (shift == 1) then
    print("shift", n, z)
  else
    if ((z == 1) and (n == 2)) then
      controlPairIndex = util.clamp(controlPairIndex - 1, 1, 6)
    elseif ((z == 1) and (n == 3)) then
      controlPairIndex = util.clamp(controlPairIndex + 1, 1, 6)
    end
  end

  screen_dirty = true
  redraw()
end

-- screen redraw function
function redraw()
  -- clear screen
  screen.clear()
  
  -- set pixel brightness (0-15)
  screen.level(1)
  
  local indexToDraw = 1
  local markerXOffset = 21 + ((controlPairIndex-1) * 40)
  for i=1,numDials do
    dials[i]:redraw()
    dials[i].active = false
    
    if (indexToDraw == controlPairIndex) then
      local rowIndex = 1
      local markerXCurrentOffset = markerXOffset
      if (controlPairIndex > 3) then
        rowIndex = 2
        markerXCurrentOffset = markerXOffset - ((4-1) * 40)
      end
    --  screen.level(15)
     -- screen.move(markerXCurrentOffset, 4 + ((rowIndex-1) * 30))
      --screen.text("▼")
    end
    
    
    if (i%2 == 1) then
      indexToDraw = indexToDraw + 1
    end
  end
  
  dials[(controlPairIndex) * 2].active = true
  dials[(controlPairIndex * 2) - 1].active = true
  
  screen.update()
end
