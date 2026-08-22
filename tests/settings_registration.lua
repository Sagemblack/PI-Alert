local eventFrame
local settingsRegistered = false

local function noop() end
local function newWidget()
  local widget = {}
  widget.Text = { SetText = noop }
  function widget:RegisterEvent() end
  function widget:SetScript(kind, callback)
    if kind == "OnEvent" then self.onEvent = callback end
  end
  function widget:CreateFontString() return newWidget() end
  function widget:SetPoint() end
  function widget:SetText() end
  function widget:SetSize() end
  function widget:SetWidth() end
  function widget:SetAutoFocus() end
  function widget:GetText() return "" end
  function widget:ClearFocus() end
  function widget:SetChecked() end
  function widget:GetChecked() return false end
  function widget:SetMinMaxValues() end
  function widget:SetValueStep() end
  function widget:SetObeyStepOnDrag() end
  function widget:SetValue() end
  function widget:SetScrollChild() end
  return widget
end

function CreateFrame()
  local widget = newWidget()
  if not eventFrame then eventFrame = widget end
  return widget
end

Settings = {
  RegisterCanvasLayoutCategory = function()
    settingsRegistered = true
    return { GetID = function() return 42 end }
  end,
  RegisterAddOnCategory = noop,
  OpenToCategory = noop,
}

SOUNDKIT = {
  RAID_WARNING = 1,
  READY_CHECK = 2,
  ALARM_CLOCK_WARNING_3 = 3,
  TELL_MESSAGE = 4,
  AUCTION_WINDOW_OPEN = 5,
}
SlashCmdList = {}
DEFAULT_CHAT_FRAME = { AddMessage = noop }
C_UnitAuras = { GetPlayerAuraBySpellID = function() return nil end }
PIAlertDB = nil

dofile("PIAlert/Core.lua")
dofile("PIAlert/Addon.lua")

if settingsRegistered then
  error("Settings registered before PIAlertDB initialization")
end

eventFrame.onEvent(eventFrame, "ADDON_LOADED", "PIAlert")

if not settingsRegistered then
  error("Settings panel was not registered after ADDON_LOADED")
end

io.write("PASS: settings panel registers after SavedVariables initialization\n")
