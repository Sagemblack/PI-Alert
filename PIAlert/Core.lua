PIAlertCore = PIAlertCore or {}

PIAlertCore.SoundKeys = {
  raidwarning = true, readycheck = true, alarm = true, tell = true, auction = true, custom = true,
}
PIAlertCore.Channels = { Master = true, SFX = true, Dialog = true, Ambience = true, Music = true }
PIAlertCore.Presets = { moan = "Interface\\AddOns\\WeakAuras\\PowerAurasMedia\\Sounds\\moan.ogg" }
PIAlertCore.Positions = { CENTER = true, TOP = true, BOTTOM = true }
PIAlertCore.Fonts = { GameFontNormalHuge = true, GameFontHighlightHuge = true, NumberFontNormalHuge = true }
PIAlertCore.Colors = {
  PURPLE = { r = 1, g = 0.82, b = 1, a = 1 },
  GOLD = { r = 1, g = 0.82, b = 0, a = 1 },
  RED = { r = 1, g = 0.15, b = 0.15, a = 1 },
  GREEN = { r = 0.25, g = 1, b = 0.25, a = 1 },
  WHITE = { r = 1, g = 1, b = 1, a = 1 },
}

local function clamp(value, low, high)
  return math.max(low, math.min(high, value))
end

function PIAlertCore.NormalizeSettings(saved)
  saved = type(saved) == "table" and saved or {}
  local enabled = true
  if type(saved.enabled) == "boolean" then enabled = saved.enabled end
  local text = type(saved.alertText) == "string" and saved.alertText:match("^%s*(.-)%s*$") or ""
  local groupText = type(saved.groupAlertText) == "string" and saved.groupAlertText:match("^%s*(.-)%s*$") or ""
  if #groupText == 0 or #groupText > 100 or not groupText:find("{name}", 1, true) then
    groupText = "POWER INFUSION: {name}"
  end
  local color = type(saved.visualColor) == "table" and saved.visualColor or {}
  return {
    enabled = enabled,
    sound = PIAlertCore.SoundKeys[saved.sound] and saved.sound or "raidwarning",
    channel = PIAlertCore.Channels[saved.channel] and saved.channel or "Master",
    customPath = type(saved.customPath) == "string" and saved.customPath or "",
    visual = saved.visual ~= false,
    groupTracking = saved.groupTracking == true,
    groupTextEnabled = saved.groupTextEnabled ~= false,
    groupSoundEnabled = saved.groupSoundEnabled ~= false,
    groupAlertText = groupText,
    groupSound = PIAlertCore.SoundKeys[saved.groupSound] and saved.groupSound or "readycheck",
    groupChannel = PIAlertCore.Channels[saved.groupChannel] and saved.groupChannel or "Master",
    groupCustomPath = type(saved.groupCustomPath) == "string" and saved.groupCustomPath or "",
    alertText = #text > 0 and #text <= 80 and text or "POWER INFUSION",
    alertDuration = type(saved.alertDuration) == "number" and saved.alertDuration >= 1 and saved.alertDuration <= 10 and saved.alertDuration or 3,
    alertScale = type(saved.alertScale) == "number" and saved.alertScale >= 0.5 and saved.alertScale <= 2 and saved.alertScale or 1,
    alertPosition = PIAlertCore.Positions[saved.alertPosition] and saved.alertPosition or "CENTER",
    visualFont = PIAlertCore.Fonts[saved.visualFont] and saved.visualFont or "GameFontNormalHuge",
    visualColorName = PIAlertCore.Colors[saved.visualColorName] and saved.visualColorName or "PURPLE",
    visualColor = {
      r = type(color.r) == "number" and clamp(color.r, 0, 1) or 1,
      g = type(color.g) == "number" and clamp(color.g, 0, 1) or 0.82,
      b = type(color.b) == "number" and clamp(color.b, 0, 1) or 1,
      a = type(color.a) == "number" and clamp(color.a, 0, 1) or 1,
    },
  }
end

function PIAlertCore.RenderGroupAlertText(template, name)
  template = type(template) == "string" and template or "POWER INFUSION: {name}"
  name = type(name) == "string" and name ~= "" and name or "Unknown"
  return (template:gsub("{name}", function() return name end))
end

function PIAlertCore.NewDetector()
  local detector = { active = false, enabled = true }
  function detector:SetEnabled(enabled) self.enabled = enabled == true end
  function detector:Update(isActive)
    isActive = isActive == true
    local shouldAlert = self.enabled and isActive and not self.active
    self.active = isActive
    return shouldAlert
  end
  return detector
end

function PIAlertCore.NewGroupDetector()
  local detector = { active = {}, enabled = true }
  function detector:SetEnabled(enabled)
    self.enabled = enabled == true
    if not self.enabled then self.active = {} end
  end
  function detector:Update(unit, isActive)
    if type(unit) ~= "string" then return false end
    isActive = isActive == true
    local shouldAlert = self.enabled and isActive and not self.active[unit]
    self.active[unit] = isActive
    return shouldAlert
  end
  return detector
end
