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

io.write(string.format("\n%d tests, %d failures\n", tests, failures))
os.exit(failures == 0 and 0 or 1)
