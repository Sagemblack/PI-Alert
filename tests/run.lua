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

dofile("PIAlert/Core.lua")

test("alerts once when Power Infusion is gained", function()
  local detector = PIAlertCore.NewDetector()
  equal(detector:Update(false), false)
  equal(detector:Update(true), true)
  equal(detector:Update(true), false)
end)

test("alerts again after Power Infusion expires and is gained again", function()
  local detector = PIAlertCore.NewDetector()
  equal(detector:Update(true), true)
  equal(detector:Update(false), false)
  equal(detector:Update(true), true)
end)

test("does not alert while disabled", function()
  local detector = PIAlertCore.NewDetector()
  detector:SetEnabled(false)
  equal(detector:Update(true), false)
end)

test("normalizes invalid saved settings to safe defaults", function()
  local settings = PIAlertCore.NormalizeSettings({
    enabled = "yes",
    sound = "missing",
    channel = "Loudest",
  })
  equal(settings.enabled, true)
  equal(settings.sound, "raidwarning")
  equal(settings.channel, "Master")
end)

test("preserves valid saved settings", function()
  local settings = PIAlertCore.NormalizeSettings({
    enabled = false,
    sound = "readycheck",
    channel = "Dialog",
  })
  equal(settings.enabled, false)
  equal(settings.sound, "readycheck")
  equal(settings.channel, "Dialog")
end)

test("normalizes v0.2.5 alert and group settings with safe defaults", function()
  local settings = PIAlertCore.NormalizeSettings({
    groupTracking = true,
    alertText = "  PI!  ",
    alertDuration = 5,
    alertScale = 1.5,
    alertPosition = "TOP",
    visualColor = { r = 0.2, g = 0.3, b = 0.4, a = 0.8 },
  })
  equal(settings.groupTracking, true)
  equal(settings.alertText, "PI!")
  equal(settings.alertDuration, 5)
  equal(settings.alertScale, 1.5)
  equal(settings.alertPosition, "TOP")
  equal(settings.visualColor.r, 0.2)
end)

test("rejects unsafe visual customization values", function()
  local settings = PIAlertCore.NormalizeSettings({
    alertText = string.rep("x", 200),
    alertDuration = -1,
    alertScale = 99,
    alertPosition = "NOWHERE",
    visualColor = { r = 3, g = -1, b = "bad", a = 4 },
  })
  equal(settings.alertText, "POWER INFUSION")
  equal(settings.alertDuration, 3)
  equal(settings.alertScale, 1)
  equal(settings.alertPosition, "CENTER")
  equal(settings.visualColor.r, 1)
  equal(settings.visualColor.g, 0)
  equal(settings.visualColor.b, 1)
  equal(settings.visualColor.a, 1)
end)

test("normalizes independent group alert settings and renders the recipient name", function()
  local settings = PIAlertCore.NormalizeSettings({
    groupTracking = true,
    groupTextEnabled = false,
    groupSoundEnabled = true,
    groupAlertText = "PI ON {name}!",
    groupSound = "alarm",
    groupChannel = "Dialog",
  })
  equal(settings.groupTextEnabled, false)
  equal(settings.groupSoundEnabled, true)
  equal(settings.groupAlertText, "PI ON {name}!")
  equal(settings.groupSound, "alarm")
  equal(settings.groupChannel, "Dialog")
  equal(PIAlertCore.RenderGroupAlertText(settings.groupAlertText, "Priestfriend"), "PI ON Priestfriend!")
end)

test("group alert template always retains a recipient placeholder", function()
  local settings = PIAlertCore.NormalizeSettings({ groupAlertText = "Power Infusion" })
  equal(settings.groupAlertText, "POWER INFUSION: {name}")
end)

test("group detector alerts once per unit and can be disabled", function()
  local detector = PIAlertCore.NewGroupDetector()
  equal(detector:Update("party1", true), true)
  equal(detector:Update("party1", true), false)
  equal(detector:Update("party2", true), true)
  equal(detector:Update("party1", false), false)
  detector:SetEnabled(false)
  equal(detector:Update("party1", true), false)
end)

io.write(string.format("\n%d tests, %d failures\n", tests, failures))
os.exit(failures == 0 and 0 or 1)
