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
local timerScheduled = false
local groupAuras = {}
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
  GetAuraDataByIndex = function(unit, index)
    return groupAuras[unit] and index == 1 and { spellId = 10060 } or nil
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

function UnitName(unit)
  if unit == "party1" then return "Priestfriend" end
  return unit
end

DEFAULT_CHAT_FRAME = { AddMessage = function(_, message) table.insert(messages, message) end }
RaidWarningFrame = {}
ChatTypeInfo = { RAID_WARNING = {} }
function RaidNotice_AddMessage(_, message)
  table.insert(notices, message)
end
SlashCmdList = {}
C_Timer = {
  After = function(_, callback)
    timerScheduled = true
    callback()
  end,
}
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
  PIAlertCore.SettingsCategory = { GetID = function() return 42 end }
  Settings = {
    OpenToCategory = function(categoryID)
      if categoryID == 42 then
        optionsOpened = true
        return true
      end
      return false
    end,
  }
  SlashCmdList.PIALERT("options")
  equal(timerScheduled, true)
  equal(optionsOpened, true)
end)

test("reset restores defaults and reports status", function()
  SlashCmdList.PIALERT("group on")
  SlashCmdList.PIALERT("reset")
  equal(PIAlertDB.enabled, true)
  equal(PIAlertDB.groupTracking, false)
  equal(PIAlertDB.alertText, "POWER INFUSION")
  SlashCmdList.PIALERT("status")
  if not messages[#messages]:find("group=false") then
    error("status did not include group tracking")
  end
end)

test("group tracking shows the recipient name and uses its own sound", function()
  local before = #played
  notices = {}
  SlashCmdList.PIALERT("group on")
  groupAuras.party1 = true
  frame.onEvent(frame, "UNIT_AURA", "party1")
  equal(notices[#notices], "POWER INFUSION: Priestfriend")
  equal(played[#played].value, SOUNDKIT.READY_CHECK)
  groupAuras.party1 = false
  frame.onEvent(frame, "UNIT_AURA", "party1")
  groupAuras.party1 = true
  frame.onEvent(frame, "UNIT_AURA", "party1")
  equal(#played, before + 2)
  SlashCmdList.PIALERT("group off")
end)

test("group text and group sound can be disabled independently", function()
  SlashCmdList.PIALERT("group on")
  PIAlertDB.groupTextEnabled = false
  PIAlertDB.groupSoundEnabled = true
  notices = {}
  local before = #played
  groupAuras.party1 = false
  frame.onEvent(frame, "UNIT_AURA", "party1")
  groupAuras.party1 = true
  frame.onEvent(frame, "UNIT_AURA", "party1")
  equal(#notices, 0)
  equal(#played, before + 1)

  PIAlertDB.groupTextEnabled = true
  PIAlertDB.groupSoundEnabled = false
  groupAuras.party1 = false
  frame.onEvent(frame, "UNIT_AURA", "party1")
  groupAuras.party1 = true
  frame.onEvent(frame, "UNIT_AURA", "party1")
  equal(notices[#notices], "POWER INFUSION: Priestfriend")
  equal(#played, before + 1)
  SlashCmdList.PIALERT("group off")
end)

io.write(string.format("\n%d integration tests, %d failures\n", tests, failures))
os.exit(failures == 0 and 0 or 1)
