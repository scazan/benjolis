-- Benjolis
--
-- a norns version of 
-- Alejandro Olarte's Benjolis
-- SC patch
--
-- UI:
-- use K2 and K3 to
-- cycle through pairs of dials.
--
-- use E2 and E3 to
-- adjust the left and right
-- dials of the pair.
--
-- use E1 to 
-- control volume.
--
-- if you hold K1 (shift)
-- and use K2, you will
-- have a momentary mute.
--
-- if you hold K1 (shift)
-- and use K3, you will
-- have a mute that toggles.
--
-- CONTROLS:
-- at the bottom of the params
-- menu there are four MIDI
-- mappings that you can
-- enable.
--
-- first choose the external
-- device.
--
-- then there are three options
-- for each mapping:
-- - enable mapping
-- - MIDI channel
-- - note mapping
--
-- enable mapping is, itself,
-- MIDI mappable and simply
-- enables this mapping or not.
--
-- MIDI channel sets the
-- incoming MIDI channel
-- for this mapping to 
-- listen to.
--
-- note mapping sets which
-- param this will be
-- mapped to.
--
-- thanks to Alejandro Olarte
-- for the SynthDef.
-- norns version: @scazan


local UI = require "ui"
local ControlSpec = require "controlspec"
local MusicUtil = require "musicutil"

engine.name = 'Benjolis'

local dials = {}
local numDials = 12

local controlPairIndex = 1
local paramsInList = {}

local SCREEN_FRAMERATE = 15
local screen_refresh_metro

-- https://stackoverflow.com/questions/11669926/is-there-a-lua-equivalent-of-scalas-map-or-cs-select-function
function map(f, t)
  local t1 = {}
  local t_len = #t
  for i = 1, t_len do
    t1[i] = f(t[i])
  end
  return t1
end

function init()
  -- screen: turn on anti-alias
  screen.aa(1)
  screen.line_width(1.0)

  -- IDs and short names
  paramsInList = {
    {"setFreq1", "f1", "hz", "freq 1"},
    {"setFreq2", "f2", "hz", "freq 2"},
    {"setFiltFreq", "flt", "hz", "filter freq"},
    {"setFilterType", "typ", "", "filter type"},
    {"setRungler1", "r1", "", "rungler 1 freq"},
    {"setRungler2", "r2", "", "rungler 2 freq"},
    {"setRunglerFilt", "rflt", "hz", "rungler filter"},
    {"setQ", "Q", "", "Q"},
    {"setScale", "scl", "", "scale"},
    {"setOutSignal", "out", "", "out signal"},
    {"setLoop", "loop", "", "loop"},
    {"setAmp", "vol", "", "amp"},
    {"setPan", "pan", "", "pan"},
  }

  -- add parameters from the engine
  addParams()

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

local midiNoteParamMappings = {nil, nil, nil, nil}
local midiChannels = {1, 1, 1, 1}
local midiNoteParamMappingEnableds = {false, false, false, false}
function handleMIDINote(data)
  local msg = midi.to_msg(data)
  if (msg.type == "note_on") then
    for i,enabled in pairs(midiNoteParamMappingEnableds) do
      if (enabled) then
        local midiNoteParamMapping = midiNoteParamMappings[i]
        -- local midiChannel = params:get("midi_channel") - 1
        local midiChannel = midiChannels[i] - 1
        
        -- check for "all" midi channels. if we are "all" then pretend this is the "correct" channel
        if (midiChannel == 0) then
          midiChannel = msg.ch
        end
        
        if (msg.ch == midiChannel) then
          if (midiNoteParamMapping ~= nil and midiNoteParamMapping ~= 1) then
            local paramMetadata = paramsInList[midiNoteParamMapping-1]
            
            if (paramMetadata[3] == "hz") then
              -- convert to hz
              local freq = MusicUtil.note_num_to_freq(msg.note)
              params:set(paramMetadata[1], freq)
            else
              -- otherwise treat it as a control message 0-1
              params:set_raw(paramMetadata[1], msg.note/127)
            end
          end
        end
    
      end
    end
  end
end

local midiInDevice = {}
local midiInChannel = 0

-- bind all engine calls to set screen dirty
local bindUIToCallback = function(callback)
  local setDirty = function(arg)
    screen_dirty = true
    callback(arg)
  end
  
  return setDirty
end

function addParams()
  params:add{type = "control", controlspec = ControlSpec.new(20.0, 14000.0, "exp", 0, 70, "Hz"), id = "setFreq1", name = "freq 1", action = bindUIToCallback(engine.setFreq1)}
  params:add{type = "control", controlspec = ControlSpec.new(0.1, 14000.0, "exp", 0, 4, "Hz"), id = "setFreq2", name = "freq 2", action = bindUIToCallback(engine.setFreq2)}
  params:add{type = "control", controlspec = ControlSpec.new(20.0, 20000.0, "exp", 0, 40, "Hz"), id = "setFiltFreq", name = "filter freq", action = bindUIToCallback(engine.setFiltFreq)}
  params:add{type = "control", controlspec = ControlSpec.new(0, 3, "lin", 1, 0, ""), id = "setFilterType", name = "filter type", action = bindUIToCallback(engine.setFilterType)}
  params:add_separator()

  params:add{type = "control", controlspec = ControlSpec.new( 0.0, 1.0, "lin", 0, 1), id = "setLoop", name = "loop", action = bindUIToCallback(engine.setLoop)}
  params:add{type = "control", controlspec = ControlSpec.new( 0.01, 9.0, "lin", 0, 1), id = "setRunglerFilt", name = "rungler filter freq", action = bindUIToCallback(engine.setRunglerFilt)}
  params:add{type = "control", controlspec = ControlSpec.new( 0.001, 1.0, "lin", 0, 0.02), id = "setQ", name = "Q", action = bindUIToCallback(engine.setQ)}
  params:add_separator()

  params:add{type = "control", controlspec = ControlSpec.new( 0.001, 1.0, "lin", 0, 0.16), id = "setRungler1", name = "rungler 1 freq", action = bindUIToCallback(engine.setRungler1)}
  params:add{type = "control", controlspec = ControlSpec.new( 0.001, 1.0, "lin", 0, 0.001), id = "setRungler2", name = "rungler 2 freq", action = bindUIToCallback(engine.setRungler2)}
  params:add{type = "control", controlspec = ControlSpec.new( 0.0, 1.0, "lin", 0, 1), id = "setScale", name = "scale", action = bindUIToCallback(engine.setScale)}
  params:add_separator()

  params:add{type = "control", controlspec = ControlSpec.new( 0.0, 6.0, "lin", 1, 6), id = "setOutSignal", name = "out signal", action = bindUIToCallback(engine.setOutSignal)}
  params:add{type = "control", controlspec = ControlSpec.new( 0.0, 6.0, "lin", 1, 6), id = "setGain", name = "gain", action = bindUIToCallback(engine.setGain)}
  params:add{type = "control", controlspec = ControlSpec.new( 0.0, 1.0, "lin", 0, 0), id = "setAmp", name = "amp", action = bindUIToCallback(engine.setAmp)}
  params:add{type = "control", controlspec = ControlSpec.new( -1, 1, "lin", 0.001, 0), id = "setPan", name = "pan", action = bindUIToCallback(engine.setPan)}
  params:add_separator()
  
  addMIDIParams()
end

function addMIDIParams() 
  local bindMIDIDevice = function(value)
    midiInDevice.event = nil
    midiInDevice = midi.connect(value)
    midiInDevice.event = handleMIDINote
  end

  -- set default midi device to 1
  bindMIDIDevice(1)
  params:add{type = "number", id = "midi_device", name = "MIDI Device", min = 1, max = 4, default = 1, action = bindMIDIDevice}
  params:add_separator()

  local channels = {"all"}
  for i = 1, 16 do table.insert(channels, i) end

  local paramNames = map(function(list) return list[4] end, paramsInList)
  table.insert(paramNames, 1, "--")

  -- common functions
  local getParamEnabler = function(index)
    return function(value)
      if (value == 1) then
        midiNoteParamMappingEnableds[index] = true
      else
        midiNoteParamMappingEnableds[index] = false
      end
    end
  end

  local getMappingSetter = function(index)
    return function(value)
      midiNoteParamMappings[index] = value
    end
  end
  
  local getMappingChannelSetter = function(index)
    return function(value)
      midiChannels[index] = value
    end
  end
  
  -- MIDI Note Mappings
  local createMIDIMapper = function(index)
    params:add{type = "control", controlspec = ControlSpec.new( 0, 1, "lin", 1, 0, ""), id = "mappingEnable"..index, name = "enable mapping "..index, action = getParamEnabler(index)}
    params:add{type = "option", id = "midi_channel"..index, name = "MIDI Channel", options = channels, action = getMappingChannelSetter(index)}
    params:add{
      type = "option",
      id = "noteMapping"..index,
      name = "note mapping "..index,
      options = paramNames,
      action = getMappingSetter(index)
    }
    params:add_separator()
  end

  for i=1,4 do
    createMIDIMapper(i)
  end
end

function addDials()
  -- make all the dials
  local dialSpacer = 22
  local row = 0
  local numColumns = 6

  for i=1,numDials do
    local xOffset = 1 + (dialSpacer * ((i-1) % numColumns)) 
    local yOffset = 8 + (row * 30)
    local extraSpace = 0;

    if ((i % 2) == 1) then
      xOffset = xOffset + 5
    end

    dials[i] = UI.Dial.new(xOffset, yOffset, 12, params:get_raw(paramsInList[i][1]), 0, 1, 0.01, 0, nil, paramsInList[i][3], paramsInList[i][2])

    -- handle markers for type knob
    if (i == 4) then
      for k=1,3 do
        dials[i]:set_marker_position(k, (k/3) - (1/6))
      end
    end

    -- handle markers for out knob
    if (i == 10) then
      for k=1,6 do
        dials[i]:set_marker_position(k, (k/6) - (1/12))
      end
    end

    if ((i % numColumns) == 0) then
      row = row + 1
    end
  end
end

function setParam(paramID, dialGroupIndex, deltaValue)
  params:set_raw(paramID, params:get_raw(paramID) + deltaValue)
end

-- encoder function
function enc(n, delta)
    local dialGroupIndex = (controlPairIndex * 2) - 1
    local deltaValue = util.clamp(delta, -0.01, 0.01)

    if n == 1 then
      setParam("setAmp", 12, deltaValue)
    elseif n == 2 then
      local paramID = paramsInList[dialGroupIndex][1]

      setParam(paramID, dialGroupIndex, deltaValue)
    elseif n == 3 then
      local paramID = paramsInList[dialGroupIndex+1][1]

      setParam(paramID, dialGroupIndex+1, deltaValue)
    end

end

local stashedVol = 0
local muted = false
local shift = 0
-- key function
function key(n, z)
  if (n == 1) then
    shift = z
  elseif (shift == 1) then
    if (n == 2) then
      -- momentary mute state
      if (z == 1) then
        stashedVol = params:get_raw("setAmp")
        params:set_raw("setAmp", 0)
      else
        params:set_raw("setAmp", stashedVol)
        stashedVol = 0
      end
    elseif ((n == 3) and (z == 0)) then
      -- togglable mute state
      if (muted) then
        params:set_raw("setAmp", stashedVol)
        stashedVol = 0
        muted = false
      else
        stashedVol = params:get_raw("setAmp")
        params:set_raw("setAmp", 0)
        muted = true
      end
    end
  else
    if ((z == 1) and (n == 2)) then
      controlPairIndex = util.clamp(controlPairIndex - 1, 1, 6)
    elseif ((z == 1) and (n == 3)) then
      controlPairIndex = util.clamp(controlPairIndex + 1, 1, 6)
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

  -- draw Dials
  for i=1,numDials do
    dials[i]:redraw()
    dials[i]:set_value(params:get_raw(paramsInList[i][1]))
    dials[i].active = false
  end

  -- activate the currently selected pair
  dials[(controlPairIndex) * 2].active = true
  dials[(controlPairIndex * 2) - 1].active = true

  screen.update()
end
