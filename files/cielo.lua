--[[
    Zenith Sky Changer - small loader
    The real script is cielo_main.lua. This loads it and, if something fails,
    shows the error on screen instead of staying silent.
    In Xeno it runs with:  loadstring(readfile("ZenithSky/cielo.lua"))()
]]

local function report(text)
    warn("[Zenith Sky Changer] " .. text)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Zenith Sky Changer: error",
            Text = text:sub(1, 180),
            Duration = 30,
        })
    end)
end

local readOk, code = pcall(readfile, "ZenithSky/cielo_main.lua")
if not readOk or type(code) ~= "string" or code == "" then
    report("Could not read ZenithSky/cielo_main.lua. Run the loader again.")
    return
end

local fn, err = loadstring(code, "=cielo")
if not fn then
    report("It does not compile: " .. tostring(err))
    return
end

local ok, problem = xpcall(fn, function(e)
    return tostring(e) .. "\n" .. debug.traceback()
end)
if not ok then
    report(tostring(problem))
end
