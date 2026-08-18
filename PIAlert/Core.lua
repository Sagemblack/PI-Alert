PIAlertCore = PIAlertCore or {}

PIAlertCore.SoundKeys = {
  raidwarning = true,
  readycheck = true,
  alarm = true,
  tell = true,
  auction = true,
  custom = true,
}

PIAlertCore.Channels = {
  Master = true,
  SFX = true,
  Dialog = true,
  Ambience = true,
  Music = true,
}

PIAlertCore.Presets = {
  moan = "Interface\\AddOns\\WeakAuras\\PowerAurasMedia\\Sounds\\moan.ogg",
}

function PIAlertCore.NormalizeSettings(saved)
  saved = type(saved) == "table" and saved or {}
  local enabled = true
  if type(saved.enabled) == "boolean" then
    enabled = saved.enabled
  end

  return {
    enabled = enabled,
    sound = PIAlertCore.SoundKeys[saved.sound] and saved.sound or "raidwarning",
    channel = PIAlertCore.Channels[saved.channel] and saved.channel or "Master",
    customPath = type(saved.customPath) == "string" and saved.customPath or "",
    visual = saved.visual ~= false,
  }
end

function PIAlertCore.NewDetector()
  local detector = {
    active = false,
    enabled = true,
  }

  function detector:SetEnabled(enabled)
    self.enabled = enabled == true
  end

  function detector:Update(isActive)
    isActive = isActive == true
    local shouldAlert = self.enabled and isActive and not self.active
    self.active = isActive
    return shouldAlert
  end

  return detector
end
