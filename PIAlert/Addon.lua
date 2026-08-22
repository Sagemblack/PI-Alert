local addonName = ... or "PIAlert"
local POWER_INFUSION_SPELL_ID = 10060
local PREFIX = "|cff9b59ffPI Alert:|r "
local MOAN_PRESET_PATH = PIAlertCore.Presets.moan
local detector = PIAlertCore.NewDetector()
local groupDetector = PIAlertCore.NewGroupDetector()
local frame = CreateFrame("Frame")
local visualAlertFrame
local visualAlertText
local visualAlertSerial = 0
local CreateSettingsPanel
local soundKits = {
  raidwarning = function() return SOUNDKIT.RAID_WARNING end,
  readycheck = function() return SOUNDKIT.READY_CHECK end,
  alarm = function() return SOUNDKIT.ALARM_CLOCK_WARNING_3 end,
  tell = function() return SOUNDKIT.TELL_MESSAGE end,
  auction = function() return SOUNDKIT.AUCTION_WINDOW_OPEN end,
}
local function Print(message) DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. message) end
local function PlaySelectedSound()
  if not PIAlertDB then return false end
  if PIAlertDB.sound == "custom" then
    if PIAlertDB.customPath == "" then Print("No custom sound path is configured."); return false end
    local ok = PlaySoundFile(PIAlertDB.customPath, PIAlertDB.channel)
    if not ok then Print("WoW could not play the custom sound. Reload after the file exists, then check the path: " .. PIAlertDB.customPath) end
    return ok
  end
  local getSoundKit = soundKits[PIAlertDB.sound]
  local soundKitID = getSoundKit and getSoundKit() or SOUNDKIT.RAID_WARNING
  return PlaySound(soundKitID, PIAlertDB.channel)
end
local function ShowVisualAlert()
  if PIAlertDB.visual == false then return end
  if not UIParent then
    if RaidNotice_AddMessage and RaidWarningFrame then
      RaidNotice_AddMessage(RaidWarningFrame, PIAlertDB.alertText or "POWER INFUSION", ChatTypeInfo.RAID_WARNING)
    end
    return
  end
  if not visualAlertFrame then
    visualAlertFrame = CreateFrame("Frame", "PIAlertVisualAlert", UIParent)
    visualAlertFrame:SetSize(620, 90)
    visualAlertText = visualAlertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    visualAlertText:SetAllPoints(visualAlertFrame)
    visualAlertText:SetJustifyH("CENTER")
  end
  visualAlertText:SetText(PIAlertDB.alertText or "POWER INFUSION")
  if visualAlertText.SetFontObject then visualAlertText:SetFontObject(PIAlertDB.visualFont or "GameFontNormalHuge") end
  local color = PIAlertCore.Colors[PIAlertDB.visualColorName] or PIAlertDB.visualColor or { r = 1, g = 0.82, b = 1, a = 1 }
  visualAlertText:SetTextColor(color.r, color.g, color.b, color.a)
  visualAlertFrame:SetScale(PIAlertDB.alertScale or 1)
  visualAlertFrame:ClearAllPoints()
  local position = PIAlertDB.alertPosition or "CENTER"
  if position == "TOP" then
    visualAlertFrame:SetPoint("TOP", UIParent, "TOP", 0, -140)
  elseif position == "BOTTOM" then
    visualAlertFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 140)
  else
    visualAlertFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  end
  visualAlertSerial = visualAlertSerial + 1
  local serial = visualAlertSerial
  visualAlertFrame:Show()
  if C_Timer and C_Timer.After then
    C_Timer.After(PIAlertDB.alertDuration or 3, function()
      if serial == visualAlertSerial then visualAlertFrame:Hide() end
    end)
  end
end
local function HasPowerInfusion()
  return C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID and C_UnitAuras.GetPlayerAuraBySpellID(POWER_INFUSION_SPELL_ID) ~= nil
end
local function Alert()
  ShowVisualAlert()
  PlaySelectedSound()
end
local function TestVisualAlert()
  if PIAlertDB and PIAlertDB.visual ~= false then
    ShowVisualAlert()
  else
    Print("Visual alerts are disabled. Enable them before previewing the visual alert.")
  end
end
local function ScanPlayerAuras()
  if detector:Update(HasPowerInfusion()) then Alert() end
end
local function IsGroupUnit(unit)
  return type(unit) == "string" and (unit:match("^party%d+$") or unit:match("^raid%d+$")) ~= nil
end
local function HasPowerInfusionOnUnit(unit)
  if not C_UnitAuras then return false end
  if C_UnitAuras.GetAuraDataByIndex then
    for index = 1, 40 do
      local aura = C_UnitAuras.GetAuraDataByIndex(unit, index, "HELPFUL")
      if not aura then break end
      if aura.spellId == POWER_INFUSION_SPELL_ID then return true end
    end
  elseif UnitAura then
    for index = 1, 40 do
      local _, _, _, _, _, _, _, _, _, spellID = UnitAura(unit, index, "HELPFUL")
      if not spellID then break end
      if spellID == POWER_INFUSION_SPELL_ID then return true end
    end
  end
  return false
end
local function ScanGroupUnit(unit)
  if PIAlertDB.groupTracking and IsGroupUnit(unit) and groupDetector:Update(unit, HasPowerInfusionOnUnit(unit)) then Alert() end
end
local function ShowHelp()
  Print("/pialert on|off — enable or disable alerts")
  Print("/pialert sound raidwarning|readycheck|alarm|tell|auction|custom")
  Print("/pialert channel Master|SFX|Dialog|Ambience|Music")
  Print("/pialert custom Interface\\AddOns\\YourMedia\\sound.ogg")
  Print("/pialert preset moan — use WeakAuras' moan.ogg")
  Print("/pialert visual on|off — toggle the on-screen alert")
  Print("/pialert group on|off — track party/raid members (off by default)")
  Print("/pialert reset — restore all settings to safe defaults")
  Print("/pialert status — show current settings")
  Print("/pialert options — open the settings panel")
  Print("/pialert test — preview the selected sound")
  Print("/pialert visualtest — preview the visual alert")
end
local function ShowStatus()
  local sound = PIAlertDB.sound == "custom" and (PIAlertDB.customPath ~= "" and PIAlertDB.customPath or "(no custom path)") or PIAlertDB.sound
  Print("enabled=" .. tostring(PIAlertDB.enabled) .. ", visual=" .. tostring(PIAlertDB.visual ~= false) .. ", group=" .. tostring(PIAlertDB.groupTracking == true) .. ", sound=" .. sound .. ", channel=" .. PIAlertDB.channel .. ", text=\"" .. PIAlertDB.alertText .. "\", duration=" .. PIAlertDB.alertDuration .. ", scale=" .. PIAlertDB.alertScale .. ", position=" .. PIAlertDB.alertPosition)
end
local function OpenSettingsPanel()
  local function open()
    if PIAlertCore.OpenSettings then PIAlertCore.OpenSettings()
    elseif Settings and Settings.OpenToCategory and PIAlertCore.SettingsCategory and PIAlertCore.SettingsCategory.GetID then Settings.OpenToCategory(PIAlertCore.SettingsCategory:GetID())
    else Print("Settings panel is unavailable until the WoW UI finishes loading.") end
  end
  if C_Timer and C_Timer.After then Print("Opening PI Alert settings..."); C_Timer.After(0, open) else open() end
end
local function HandleSlashCommand(input)
  input = (input or ""):match("^%s*(.-)%s*$")
  local command, argument = input:match("^(%S+)%s*(.-)$"); command = command and command:lower() or ""
  if command == "on" or command == "off" then
    PIAlertDB.enabled = command == "on"; detector:SetEnabled(PIAlertDB.enabled); Print(command .. ".")
  elseif command == "sound" then
    argument = argument:lower()
    if PIAlertCore.SoundKeys[argument] then PIAlertDB.sound = argument; Print("sound set to " .. argument .. ".") else Print("unknown sound: " .. argument) end
  elseif command == "channel" then
    local normalized = argument:sub(1,1):upper() .. argument:sub(2):lower(); if normalized == "Sfx" then normalized = "SFX" end
    if PIAlertCore.Channels[normalized] then PIAlertDB.channel = normalized; Print("channel set to " .. normalized .. ".") else Print("unknown channel: " .. argument) end
  elseif command == "custom" then
    if argument == "" then Print("custom path: " .. (PIAlertDB.customPath ~= "" and PIAlertDB.customPath or "not set")) else PIAlertDB.customPath = argument; Print("custom sound path saved. Select it with /pialert sound custom") end
  elseif command == "preset" then
    if argument == "moan" then PIAlertDB.customPath = MOAN_PRESET_PATH; PIAlertDB.sound = "custom"; Print("WeakAuras moan preset selected. Reload WoW if the sound was added while logged in.") else Print("unknown preset: " .. argument) end
  elseif command == "visual" then
    if argument == "on" or argument == "off" then PIAlertDB.visual = argument == "on"; Print("visual alert " .. argument .. ".") else Print("visual alert is " .. (PIAlertDB.visual ~= false and "on" or "off") .. ". Use /pialert visual on|off") end
  elseif command == "group" then
    if argument == "on" or argument == "off" then PIAlertDB.groupTracking = argument == "on"; groupDetector:SetEnabled(PIAlertDB.groupTracking); Print("group tracking " .. argument .. ".") else Print("group tracking is " .. (PIAlertDB.groupTracking and "on" or "off") .. ". Use /pialert group on|off") end
  elseif command == "reset" then
    PIAlertDB = PIAlertCore.NormalizeSettings(nil); detector:SetEnabled(true); groupDetector:SetEnabled(false); Print("settings reset to safe defaults.")
  elseif command == "status" then ShowStatus()
  elseif command == "options" then OpenSettingsPanel()
  elseif command == "visualtest" then TestVisualAlert()
  elseif command == "test" then PlaySelectedSound()
  else ShowHelp() end
end
frame:RegisterEvent("ADDON_LOADED"); frame:RegisterEvent("PLAYER_ENTERING_WORLD"); frame:RegisterEvent("UNIT_AURA")
frame:SetScript("OnEvent", function(_, event, ...)
  if event == "ADDON_LOADED" then
    if (...) ~= addonName then return end
    PIAlertDB = PIAlertCore.NormalizeSettings(PIAlertDB); detector:SetEnabled(PIAlertDB.enabled); groupDetector:SetEnabled(PIAlertDB.groupTracking); CreateSettingsPanel()
  elseif event == "PLAYER_ENTERING_WORLD" then ScanPlayerAuras()
  elseif event == "UNIT_AURA" then local unit = ...; if unit == "player" then ScanPlayerAuras() else ScanGroupUnit(unit) end end
end)
SLASH_PIALERT1 = "/pialert"; SLASH_PIALERT2 = "/pia"; SlashCmdList.PIALERT = HandleSlashCommand
CreateSettingsPanel = function()
  if not Settings or not Settings.RegisterCanvasLayoutCategory then return end
  local panel = CreateFrame("Frame"); panel.name = "PI Alert"
  local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
  scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -28, 0)
  local content = CreateFrame("Frame", nil, scroll)
  content:SetSize(620, 760)
  scroll:SetScrollChild(content)
  local title = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge"); title:SetPoint("TOPLEFT", 16, -16); title:SetText("PI Alert 0.2.5")
  local description = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight"); description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8); description:SetText("Power Infusion sound, visual, and group tracking settings")
  local function checkbox(label, anchor, handler)
    local box = CreateFrame("CheckButton", nil, content, "InterfaceOptionsCheckButtonTemplate"); box:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -8); box.Text:SetText(label); box:SetScript("OnClick", handler); return box
  end
  local enabled = checkbox("Enable PI Alert", description, function(self) HandleSlashCommand(self:GetChecked() and "on" or "off") end)
  local visual = checkbox("Show on-screen alert", enabled, function(self) HandleSlashCommand(self:GetChecked() and "visual on" or "visual off") end)
  local group = checkbox("Track party and raid members (experimental)", visual, function(self) HandleSlashCommand(self:GetChecked() and "group on" or "group off") end)
  local testButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate"); testButton:SetPoint("TOPLEFT", group, "BOTTOMLEFT", 0, -12); testButton:SetSize(140, 24); testButton:SetText("Test Sound"); testButton:SetScript("OnClick", function() HandleSlashCommand("test") end)
  local visualTestButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate"); visualTestButton:SetPoint("LEFT", testButton, "RIGHT", 10, 0); visualTestButton:SetSize(150, 24); visualTestButton:SetText("Test Visual Alert"); visualTestButton:SetScript("OnClick", function() HandleSlashCommand("visualtest") end)
  local presetButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate"); presetButton:SetPoint("TOPLEFT", testButton, "BOTTOMLEFT", 0, -8); presetButton:SetSize(180, 24); presetButton:SetText("Use WeakAuras Moan"); presetButton:SetScript("OnClick", function() HandleSlashCommand("preset moan") end)
  local function dropdown(label, yOffset, values, getter, setter, displayNames)
    local function displayValue(value)
      return displayNames and displayNames[value] or value
    end
    if not (UIDropDownMenu_CreateInfo and UIDropDownMenu_Initialize and UIDropDownMenu_AddButton) then
      local fallback = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
      fallback:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOffset)
      fallback:SetSize(220, 24)
      local function refresh() fallback:SetText(label .. ": " .. tostring(displayValue(getter()))) end
      fallback:SetScript("OnClick", function() local current = getter(); local nextValue = values[1]; for i, value in ipairs(values) do if value == current then nextValue = values[(i % #values) + 1]; break end end; setter(nextValue); refresh() end)
      refresh()
      return fallback
    end
    local caption = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    caption:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOffset + 24)
    caption:SetText(label)
    local menu = CreateFrame("Frame", nil, content, "UIDropDownMenuTemplate")
    menu:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOffset)
    UIDropDownMenu_SetWidth(menu, 190)
    local function refresh()
      UIDropDownMenu_SetSelectedValue(menu, getter())
      UIDropDownMenu_SetText(menu, tostring(displayValue(getter())))
    end
    UIDropDownMenu_Initialize(menu, function(self)
      for _, value in ipairs(values) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = displayValue(value)
        info.value = value
        info.func = function()
          setter(value)
          refresh()
        end
        UIDropDownMenu_AddButton(info)
      end
    end)
    if UIDropDownMenu_SetAnchor then
      UIDropDownMenu_SetAnchor(menu, 0, 0, "TOPLEFT", menu, "BOTTOMLEFT")
    end
    refresh()
    return menu
  end
  local soundButton = dropdown("Alert sound", -250, {"raidwarning", "readycheck", "alarm", "tell", "auction", "custom"}, function() return PIAlertDB.sound end, function(value) PIAlertDB.sound = value end)
  local channelButton = dropdown("Audio channel", -309, {"Master", "SFX", "Dialog", "Ambience", "Music"}, function() return PIAlertDB.channel end, function(value) PIAlertDB.channel = value end)
  local positionButton = dropdown("Alert position", -368, {"CENTER", "TOP", "BOTTOM"}, function() return PIAlertDB.alertPosition end, function(value) PIAlertDB.alertPosition = value end)
  local colorButton = dropdown("Alert color", -427, {"PURPLE", "GOLD", "RED", "GREEN", "WHITE"}, function() return PIAlertDB.visualColorName end, function(value) PIAlertDB.visualColorName = value; PIAlertDB.visualColor = PIAlertCore.Colors[value] end)
  local fontButton = dropdown("Alert font", -486, {"GameFontNormalHuge", "GameFontHighlightHuge", "NumberFontNormalHuge"}, function() return PIAlertDB.visualFont end, function(value) PIAlertDB.visualFont = value end, {
    GameFontNormalHuge = "Classic Huge",
    GameFontHighlightHuge = "Bright Huge",
    NumberFontNormalHuge = "Number Display",
  })
  local function editControl(label, help, yOffset, value, save)
    local caption = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    caption:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOffset + 34)
    caption:SetText(label)
    local description = content:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    description:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOffset + 18)
    description:SetText(help)
    local edit = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
    edit:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOffset)
    edit:SetSize(360, 24)
    edit:SetAutoFocus(false)
    edit:SetText(value or "")
    edit:SetScript("OnEnterPressed", function(self) save(self:GetText()); self:ClearFocus() end)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    return edit
  end
  local textEdit = editControl("Alert text", "Text shown in the on-screen alert.", -560, PIAlertDB and PIAlertDB.alertText, function(value) local normalized = PIAlertCore.NormalizeSettings({alertText=value}); PIAlertDB.alertText = normalized.alertText end)
  local pathEdit = editControl("Custom sound path", "WoW-relative .ogg/.mp3 path, e.g. Interface\\AddOns\\MyMedia\\alert.ogg", -630, PIAlertDB and PIAlertDB.customPath, function(value) PIAlertDB.customPath = value end)
  local duration = CreateFrame("Slider", nil, content, "OptionsSliderTemplate"); duration:SetPoint("TOPLEFT", pathEdit, "BOTTOMLEFT", 0, -24); duration:SetWidth(220); duration:SetMinMaxValues(1, 10); duration:SetValueStep(1); duration:SetObeyStepOnDrag(true); duration:SetScript("OnValueChanged", function(_, value) PIAlertDB.alertDuration = value end)
  local scale = CreateFrame("Slider", nil, content, "OptionsSliderTemplate"); scale:SetPoint("TOPLEFT", duration, "BOTTOMLEFT", 0, -28); scale:SetWidth(220); scale:SetMinMaxValues(0.5, 2); scale:SetValueStep(0.1); scale:SetObeyStepOnDrag(true); scale:SetScript("OnValueChanged", function(_, value) PIAlertDB.alertScale = value end)
  local function refreshSliderLabels()
    if duration.Text then duration.Text:SetText("Alert duration: " .. tostring(PIAlertDB.alertDuration) .. " seconds") end
    if scale.Text then scale.Text:SetText("Alert scale: " .. string.format("%.1fx", PIAlertDB.alertScale)) end
  end
  duration:SetScript("OnValueChanged", function(_, value) PIAlertDB.alertDuration = math.floor(value + 0.5); refreshSliderLabels() end)
  scale:SetScript("OnValueChanged", function(_, value) PIAlertDB.alertScale = value; refreshSliderLabels() end)
  if duration.SetValue then duration:SetValue(PIAlertDB.alertDuration) end
  if scale.SetValue then scale:SetValue(PIAlertDB.alertScale) end
  refreshSliderLabels()
  panel:SetScript("OnShow", function() enabled:SetChecked(PIAlertDB and PIAlertDB.enabled == true); visual:SetChecked(PIAlertDB and PIAlertDB.visual ~= false); group:SetChecked(PIAlertDB and PIAlertDB.groupTracking == true) end)
  local category = Settings.RegisterCanvasLayoutCategory(panel, "PI Alert"); Settings.RegisterAddOnCategory(category); PIAlertCore.SettingsCategory = category; PIAlertCore.OpenSettings = function() Settings.OpenToCategory(category:GetID()) end
end
