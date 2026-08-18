local failures = 0
local tests = 0

local function test(name, fn)
  tests = tests + 1
  local ok, err = pcall(fn)
  if ok then
    io.write("PASS: " .. name .. "\n")
  else
    failures = failures + 1
    io.write("FAIL: " .. name .. "\n  " .. tostring(err) .. "\n")
  end
end

local function equal(actual, expected, message)
  if actual ~= expected then
    error((message or "values differ") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
  end
end

local auraActive = false
local played = {}
local notices = {}
local messages = {}
local optionsOpened = false
local frame = { events = {} }

function frame:RegisterEvent(event)
  self.events[event] = true
end

function frame:SetScript(scriptType, callback)
  if scriptType == "OnEvent" then
    self.onEvent = callback
  end
end

function CreateFrame()
  return frame
end

C_UnitAuras = {
  GetPlayerAuraBySpellID = function(spellID)
    equal(spellID, 10060, "Power Infusion spell ID")
    return auraActive and { spellId = spellID } or nil
  end,
}

SOUNDKIT = {
  RAID_WARNING = 8959,
  READY_CHECK = 8960,
  ALARM_CLOCK_WARNING_3 = 8961,
  TELL_MESSAGE = 8962,
  AUCTION_WINDOW_OPEN = 8963,
}

function PlaySound(soundKitID, channel)
  table.insert(played, { kind = "kit", value = soundKitID, channel = channel })
  return true
end

function PlaySoundFile(path, channel)
  table.insert(played, { kind = "file", value = path, channel = channel })
  return true
end

DEFAULT_CHAT_FRAME = { AddMessage = function(_, message) table.insert(messages, message) end }
RaidWarningFrame = {}
ChatTypeInfo = { RAID_WARNING = {} }
function RaidNotice_AddMessage(_, message)
  table.insert(notices, message)
end
SlashCmdList = {}
PIAlertDB = nil

dofile("PIAlert/Core.lua")
dofile("PIAlert/Addon.lua")

frame.onEvent(frame, "ADDON_LOADED", "PIAlert")

test("registers the required WoW events", function()
  equal(frame.events.ADDON_LOADED, true)
  equal(frame.events.PLAYER_ENTERING_WORLD, true)
  equal(frame.events.UNIT_AURA, true)
end)

test("plays the selected sound once when the player gains Power Infusion", function()
  auraActive = false
  frame.onEvent(frame, "PLAYER_ENTERING_WORLD")
  auraActive = true
  frame.onEvent(frame, "UNIT_AURA", "player")
  frame.onEvent(frame, "UNIT_AURA", "player")
  equal(#played, 1)
  equal(played[1].value, SOUNDKIT.RAID_WARNING)
  equal(played[1].channel, "Master")
end)

test("ignores UNIT_AURA events for other units", function()
  auraActive = false
  frame.onEvent(frame, "UNIT_AURA", "target")
  equal(#played, 1)
end)

test("slash command changes sound and test plays it", function()
  SlashCmdList.PIALERT("sound readycheck")
  SlashCmdList.PIALERT("test")
  equal(PIAlertDB.sound, "readycheck")
  equal(played[#played].value, SOUNDKIT.READY_CHECK)
end)

test("custom sound path uses PlaySoundFile", function()
  SlashCmdList.PIALERT("custom Interface\\AddOns\\MyMedia\\pi.ogg")
  SlashCmdList.PIALERT("sound custom")
  SlashCmdList.PIALERT("test")
  equal(played[#played].kind, "file")
  equal(played[#played].value, "Interface\\AddOns\\MyMedia\\pi.ogg")
end)

test("moan preset selects the WeakAuras sound path", function()
  SlashCmdList.PIALERT("preset moan")
  equal(PIAlertDB.sound, "custom")
  equal(PIAlertDB.customPath, "Interface\\AddOns\\WeakAuras\\PowerAurasMedia\\Sounds\\moan.ogg")
end)

test("visual alert can be disabled without disabling the sound alert", function()
  notices = {}
  SlashCmdList.PIALERT("visual off")
  auraActive = false
  frame.onEvent(frame, "UNIT_AURA", "player")
  auraActive = true
  frame.onEvent(frame, "UNIT_AURA", "player")
  equal(#notices, 0)
  equal(played[#played].kind, "file")
  SlashCmdList.PIALERT("visual on")
end)

test("status reports the selected custom path", function()
  SlashCmdList.PIALERT("status")
  local last = messages[#messages]
  if not last:find("moan%.ogg") then
    error("status did not include the custom sound path")
  end
end)

test("options command opens the settings category when available", function()
  PIAlertCore.OpenSettings = nil
  PIAlertCore.SettingsCategory = {}
  Settings = {
    OpenToCategory = function(category)
      if type(category) == "table" then
        optionsOpened = true
        return true
      end
      return false
    end,
  }
  SlashCmdList.PIALERT("options")
  equal(optionsOpened, true)
end)

io.write(string.format("\n%d integration tests, %d failures\n", tests, failures))
os.exit(failures == 0 and 0 or 1)
