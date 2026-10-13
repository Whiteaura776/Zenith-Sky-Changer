--[[
    Zenith Sky Changer - loader
    -------------------------------------------------------------------------------------------------
    This is only a loader. It downloads the real script and its images/sounds from the project's
    GitHub repository (the file list is in manifest.json, every file is checked by its size) into
    your executor's workspace folder "ZenithSky/", and then runs it. It only WRITES inside that
    folder, it does not send anything anywhere (no telemetry, no webhooks, no keys, no accounts).
    Zenith Sky Changer is COSMETIC ONLY: it only changes how the game looks on your own screen.
    It has no aimbot, no auto-damage, no speed/jump/fly, no teleport, no kill aura.

    assets.pack (if present) is just the project's images and sounds one after another; manifest.json
    lists each one with its size. This loader cuts them into separate files.
    Local files it keeps in ZenithSky/ (all stay on your PC): window settings (ventana.txt), your
    choices (the skins / sky you picked) and debug logs (*_log.txt).
]]

local BASE = "https://raw.githubusercontent.com/Whiteaura776/Zenith-Sky-Changer/main/"
local CARPETA = "ZenithSky"
local BATCH = 6 -- downloads at the same time

local function notify(title, text, seconds)
    warn("[Zenith Sky Changer] " .. text)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", { Title = title, Text = text:sub(1, 180), Duration = seconds or 6 })
    end)
end

-- the executor must be able to write files
if not (writefile and readfile and isfile) then
    notify("Zenith Sky Changer", "Your executor lacks writefile / readfile / isfile.", 15)
    return
end
if makefolder and isfolder and not isfolder(CARPETA) then pcall(makefolder, CARPETA) end

-- downloads an address and returns the exact content (uses request if it exists: it is binary-safe; otherwise HttpGet)
local function fetch(url)
    local req = request or http_request or (syn and syn.request) or (http and http.request)
    if req then
        local ok, r = pcall(req, { Url = url, Method = "GET" })
        if ok and r and type(r.Body) == "string" and (r.StatusCode == nil or r.StatusCode == 200) then return r.Body end
    end
    local ok, text = pcall(function() return game:HttpGet(url) end)
    if ok and type(text) == "string" then return text end
    return nil
end

-- 1) the file list and its version
local manifestText = fetch(BASE .. "manifest.json")
local parsed, manifest = pcall(function() return game:GetService("HttpService"):JSONDecode(manifestText or "") end)
if not (parsed and type(manifest) == "table" and type(manifest.files) == "table") then
    notify("Zenith Sky Changer", "Could not download the file list. Check your internet and try again.", 15)
    return
end

-- 2) what is missing, or everything if the version changed
local oldVersion = ""
if isfile(CARPETA .. "/version_instalada.txt") then
    local ok, v = pcall(readfile, CARPETA .. "/version_instalada.txt")
    if ok and type(v) == "string" then oldVersion = v end
end
local pending = {}
-- is the file on disk and complete? (a file inside an assets.pack is checked through the files inside it)
local function onDisk(name, size)
    local path = CARPETA .. "/" .. name
    if not isfile(path) then return false end
    local ok, content = pcall(readfile, path)
    return ok and type(content) == "string" and #content == size
end
for _, entry in ipairs(manifest.files) do
    local current = false
    if oldVersion == manifest.version then
        if entry.pack then
            current = true
            for _, inner in ipairs(entry.pack) do
                if not onDisk(inner.name, inner.size) then current = false break end
            end
        else
            current = onDisk(entry.name, entry.size)
        end
    end
    if not current then table.insert(pending, entry) end
end

-- 3) the download (BATCH files at a time), 3 tries per file
if #pending > 0 then
    notify("Zenith Sky Changer", "Installing " .. tostring(manifest.version) .. ": " .. #pending .. " files...", 8)
    local failed = {}
    local i = 1
    while i <= #pending do
        local running = 0
        for j = i, math.min(i + BATCH - 1, #pending) do
            local entry = pending[j]
            running = running + 1
            task.spawn(function()
                local ok = false
                for _ = 1, 3 do
                    local body = fetch(BASE .. "files/" .. entry.name)
                    if body and #body == entry.size then
                        if entry.pack then
                            -- assets.pack: the images and sounds one after another (the list and sizes are in manifest.json); each one is saved as its own file
                            ok = true
                            local from = 1
                            for _, inner in ipairs(entry.pack) do
                                if not pcall(writefile, CARPETA .. "/" .. inner.name, body:sub(from, from + inner.size - 1)) then ok = false end
                                from = from + inner.size
                            end
                        else
                            ok = pcall(writefile, CARPETA .. "/" .. entry.name, body)
                        end
                        if ok then break end
                    end
                    task.wait(0.5)
                end
                if not ok then table.insert(failed, entry.name) end
                running = running - 1
            end)
        end
        while running > 0 do task.wait(0.1) end
        i = i + BATCH
    end
    if #failed > 0 then
        notify("Zenith Sky Changer", #failed .. " downloads failed (" .. table.concat(failed, ", "):sub(1, 90) .. "). Try again.", 20)
        return
    end
    pcall(writefile, CARPETA .. "/version_instalada.txt", tostring(manifest.version))
end

-- 4) run it (cielo.lua is the small loader inside the package: it reads cielo_main.lua and reports any error)
local ok, code = pcall(readfile, CARPETA .. "/cielo.lua")
if not (ok and type(code) == "string" and code ~= "") then
    notify("Zenith Sky Changer", "Missing file ZenithSky/cielo.lua. Try again.", 15)
    return
end
local fn, err = loadstring(code, "=cielo_loader")
if not fn then
    notify("Zenith Sky Changer", "It does not compile: " .. tostring(err), 20)
    return
end
fn()
