local addonName = ... or "PIAlert"
local POWER_INFUSION_SPELL_ID = 10060
local PREFIX = "|cff9b59ffPI Alert:|r "

local detector = PIAlertCore.NewDetector()
local frame = CreateFrame("Frame")

local soundKits = {
  raidwarning = function() return SOUNDKIT.RAID_WARNING end,
  readycheck = function() return SOUNDKIT.READY_CHECK end,
  alarm = function() return SOUNDKIT.ALARM_CLOCK_WARNING_3 end,
  tell = function() return SOUNDKIT.TELL_MESSAGE end,
  auction = function() return SOUNDKIT.AUCTION_WINDOW_OPEN end,
}

local function Print(message)
  DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. message)
end

local function PlaySelectedSound()
  if not PIAlertDB then
    return false
  end

  if PIAlertDB.sound == "custom" then
    if PIAlertDB.customPath == "" then
      Print("No custom sound path is configured.")
      return false
    end
    return PlaySoundFile(PIAlertDB.customPath, PIAlertDB.channel)
  end

  local getSoundKit = soundKits[PIAlertDB.sound]
  local soundKitID = getSoundKit and getSoundKit()
  if not soundKitID then
    Print("The selected sound is unavailable; using Raid Warning.")
    soundKitID = SOUNDKIT.RAID_WARNING
  end
  return PlaySound(soundKitID, PIAlertDB.channel)
end

local function HasPowerInfusion()
  return C_UnitAuras.GetPlayerAuraBySpellID(POWER_INFUSION_SPELL_ID) ~= nil
end

local function ScanPlayerAuras()
  if detector:Update(HasPowerInfusion()) then
    PlaySelectedSound()
  end
end

local function ShowHelp()
  Print("/pialert on|off — enable or disable alerts")
  Print("/pialert sound raidwarning|readycheck|alarm|tell|auction|custom")
  Print("/pialert channel Master|SFX|Dialog|Ambience|Music")
  Print("/pialert custom Interface\\AddOns\\YourMedia\\sound.ogg")
  Print("/pialert test — preview the selected sound")
end

local function HandleSlashCommand(input)
  input = (input or ""):match("^%s*(.-)%s*$")
  local command, argument = input:match("^(%S+)%s*(.-)$")
  command = command and command:lower() or ""

  if command == "on" then
    PIAlertDB.enabled = true
    detector:SetEnabled(true)
    Print("enabled.")
  elseif command == "off" then
    PIAlertDB.enabled = false
    detector:SetEnabled(false)
    Print("disabled.")
  elseif command == "sound" then
    argument = argument:lower()
    if PIAlertCore.SoundKeys[argument] then
      PIAlertDB.sound = argument
      Print("sound set to " .. argument .. ".")
    else
      Print("unknown sound: " .. argument)
    end
  elseif command == "channel" then
    local normalized = argument:sub(1, 1):upper() .. argument:sub(2):lower()
    if normalized == "Sfx" then
      normalized = "SFX"
    end
    if PIAlertCore.Channels[normalized] then
      PIAlertDB.channel = normalized
      Print("channel set to " .. normalized .. ".")
    else
      Print("unknown channel: " .. argument)
    end
  elseif command == "custom" then
    if argument == "" then
      Print("custom path: " .. (PIAlertDB.customPath ~= "" and PIAlertDB.customPath or "not set"))
    else
      PIAlertDB.customPath = argument
      Print("custom sound path saved. Select it with /pialert sound custom")
    end
  elseif command == "test" then
    PlaySelectedSound()
  else
    ShowHelp()
  end
end

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("UNIT_AURA")

frame:SetScript("OnEvent", function(_, event, ...)
  if event == "ADDON_LOADED" then
    local loadedAddon = ...
    if loadedAddon ~= addonName then
      return
    end
    PIAlertDB = PIAlertCore.NormalizeSettings(PIAlertDB)
    detector:SetEnabled(PIAlertDB.enabled)
  elseif event == "PLAYER_ENTERING_WORLD" then
    ScanPlayerAuras()
  elseif event == "UNIT_AURA" then
    local unit = ...
    if unit == "player" then
      ScanPlayerAuras()
    end
  end
end)

SLASH_PIALERT1 = "/pialert"
SLASH_PIALERT2 = "/pia"
SlashCmdList.PIALERT = HandleSlashCommand
