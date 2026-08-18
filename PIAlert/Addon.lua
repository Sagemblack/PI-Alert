local addonName = ... or "PIAlert"
local POWER_INFUSION_SPELL_ID = 10060
local PREFIX = "|cff9b59ffPI Alert:|r "
local MOAN_PRESET_PATH = PIAlertCore.Presets.moan

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
    local willPlay = PlaySoundFile(PIAlertDB.customPath, PIAlertDB.channel)
    if not willPlay then
      Print("WoW could not play the custom sound. Reload after the file exists, then check the path: " .. PIAlertDB.customPath)
    end
    return willPlay
  end

  local getSoundKit = soundKits[PIAlertDB.sound]
  local soundKitID = getSoundKit and getSoundKit()
  if not soundKitID then
    Print("The selected sound is unavailable; using Raid Warning.")
    soundKitID = SOUNDKIT.RAID_WARNING
  end
  return PlaySound(soundKitID, PIAlertDB.channel)
end

local function ShowVisualAlert()
  if PIAlertDB.visual ~= false and RaidNotice_AddMessage and RaidWarningFrame then
    RaidNotice_AddMessage(RaidWarningFrame, "POWER INFUSION", ChatTypeInfo.RAID_WARNING)
  end
end

local function HasPowerInfusion()
  return C_UnitAuras.GetPlayerAuraBySpellID(POWER_INFUSION_SPELL_ID) ~= nil
end

local function ScanPlayerAuras()
  if detector:Update(HasPowerInfusion()) then
    ShowVisualAlert()
    PlaySelectedSound()
  end
end

local function ShowHelp()
  Print("/pialert on|off — enable or disable alerts")
  Print("/pialert sound raidwarning|readycheck|alarm|tell|auction|custom")
  Print("/pialert channel Master|SFX|Dialog|Ambience|Music")
  Print("/pialert custom Interface\\AddOns\\YourMedia\\sound.ogg")
  Print("/pialert preset moan — use WeakAuras' moan.ogg")
  Print("/pialert visual on|off — toggle the on-screen alert")
  Print("/pialert status — show current settings")
  Print("/pialert options — open the settings panel")
  Print("/pialert test — preview the selected sound")
end

local function ShowStatus()
  local sound = PIAlertDB.sound == "custom" and (PIAlertDB.customPath ~= "" and PIAlertDB.customPath or "(no custom path)") or PIAlertDB.sound
  Print("enabled=" .. tostring(PIAlertDB.enabled) .. ", visual=" .. tostring(PIAlertDB.visual ~= false) .. ", sound=" .. sound .. ", channel=" .. PIAlertDB.channel)
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
  elseif command == "preset" then
    if argument == "moan" then
      PIAlertDB.customPath = MOAN_PRESET_PATH
      PIAlertDB.sound = "custom"
      Print("WeakAuras moan preset selected. Reload WoW if the sound was added while logged in.")
    else
      Print("unknown preset: " .. argument)
    end
  elseif command == "visual" then
    if argument == "on" or argument == "off" then
      PIAlertDB.visual = argument == "on"
      Print("visual alert " .. argument .. ".")
    else
      Print("visual alert is " .. (PIAlertDB.visual ~= false and "on" or "off") .. ". Use /pialert visual on|off")
    end
  elseif command == "status" then
    ShowStatus()
  elseif command == "options" then
    local opened = false
    if PIAlertCore.OpenSettings then
      opened = PIAlertCore.OpenSettings()
    end
    if opened == false and Settings and Settings.OpenToCategory then
      if PIAlertCore.SettingsCategory then
        opened = Settings.OpenToCategory(PIAlertCore.SettingsCategory)
      else
        opened = Settings.OpenToCategory("PIAlert")
      end
    end
    if opened == false then
      Print("Settings panel is unavailable until the WoW UI finishes loading.")
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

local function CreateSettingsPanel()
  if not Settings or not Settings.RegisterCanvasLayoutCategory then
    return
  end

  local panel = CreateFrame("Frame")
  panel.name = "PI Alert"

  local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("PI Alert")

  local description = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
  description:SetText("Power Infusion sound and visual alert settings")

  local enabled = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
  enabled:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -18)
  enabled.Text:SetText("Enable PI Alert")
  enabled:SetScript("OnClick", function(self)
    SlashCmdList.PIALERT(self:GetChecked() and "on" or "off")
  end)

  local visual = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
  visual:SetPoint("TOPLEFT", enabled, "BOTTOMLEFT", 0, -8)
  visual.Text:SetText("Show POWER INFUSION on-screen alert")
  visual:SetScript("OnClick", function(self)
    SlashCmdList.PIALERT(self:GetChecked() and "visual on" or "visual off")
  end)

  local testButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  testButton:SetPoint("TOPLEFT", visual, "BOTTOMLEFT", 0, -18)
  testButton:SetSize(140, 24)
  testButton:SetText("Test Sound")
  testButton:SetScript("OnClick", function() SlashCmdList.PIALERT("test") end)

  local presetButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  presetButton:SetPoint("LEFT", testButton, "RIGHT", 10, 0)
  presetButton:SetSize(180, 24)
  presetButton:SetText("Use WeakAuras Moan")
  presetButton:SetScript("OnClick", function() SlashCmdList.PIALERT("preset moan") end)

  panel:SetScript("OnShow", function()
    enabled:SetChecked(PIAlertDB and PIAlertDB.enabled == true)
    visual:SetChecked(PIAlertDB and PIAlertDB.visual ~= false)
  end)

  local category = Settings.RegisterCanvasLayoutCategory(panel, "PI Alert")
  category.ID = "PIAlert"
  Settings.RegisterAddOnCategory(category)
  PIAlertCore.SettingsCategory = category
  PIAlertCore.OpenSettings = function()
    return Settings.OpenToCategory(category.ID)
  end
end

CreateSettingsPanel()
