--[[
    Zenith Sky Changer - loader / cargador
    -------------------------------------------------------------------------------------------------
    EN: This is only a loader. It downloads the real script and its images/sounds from the project's
        GitHub repository (the file list is in manifest.json, every file is checked by its size) into
        your executor's workspace folder "ZenithSky/", and then runs it. It only WRITES inside that
        folder, it does not send anything anywhere (no telemetry, no webhooks, no keys, no accounts).
        Zenith Sky Changer is COSMETIC ONLY: it only changes how the game looks on your own screen.
        It has no aimbot, no auto-damage, no speed/jump/fly, no teleport, no kill aura.
    ES: Esto es solo un cargador. Baja el script de verdad y sus imagenes y sonidos desde el
        repositorio de GitHub del proyecto (la lista esta en manifest.json y cada archivo se
        comprueba por su tamano) a la carpeta "ZenithSky/" de tu ejecutor, y lo ejecuta. Solo
        ESCRIBE en esa carpeta; no envia nada a ningun lado (sin telemetria, sin webhooks, sin keys).
        Zenith Sky Changer es SOLO COSMETICO: solo cambia como se ve el juego en tu pantalla.
        No tiene aimbot, dano automatico, velocidad/salto/vuelo, teletransporte ni aura.

    assets.pack (if present) is just the project's images and sounds one after another; manifest.json lists each one with its size. This loader cuts them into separate files.
    Local files it keeps in ZenithSky/ (all stay on your PC): window settings (ventana.txt), your
    choices (the skins / sky you picked) and debug logs (*_log.txt).
]]

local BASE = "https://raw.githubusercontent.com/Whiteaura776/Zenith-Sky-Changer/main/"
local CARPETA = "ZenithSky"
local LOTE = 6 -- descargas a la vez

local function aviso(titulo, texto, segundos)
    warn("[Cielo] " .. texto)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", { Title = titulo, Text = texto:sub(1, 180), Duration = segundos or 6 })
    end)
end

-- el ejecutor tiene que poder escribir archivos
if not (writefile and readfile and isfile) then
    aviso("Zenith Sky Changer", "Tu ejecutor no tiene writefile / readfile / isfile. / Your executor lacks file functions.", 15)
    return
end
if makefolder and isfolder and not isfolder(CARPETA) then pcall(makefolder, CARPETA) end

-- pide una direccion y devuelve el contenido exacto (con request si existe: es seguro para binarios; si no, HttpGet)
local function pedir(url)
    local peticion = request or http_request or (syn and syn.request) or (http and http.request)
    if peticion then
        local ok, r = pcall(peticion, { Url = url, Method = "GET" })
        if ok and r and type(r.Body) == "string" and (r.StatusCode == nil or r.StatusCode == 200) then return r.Body end
    end
    local ok, texto = pcall(function() return game:HttpGet(url) end)
    if ok and type(texto) == "string" then return texto end
    return nil
end

-- 1) la lista de archivos y su version
local textoManifest = pedir(BASE .. "manifest.json")
local bien, manifest = pcall(function() return game:GetService("HttpService"):JSONDecode(textoManifest or "") end)
if not (bien and type(manifest) == "table" and type(manifest.archivos) == "table") then
    aviso("Zenith Sky Changer", "No pude bajar la lista de archivos. Revisa tu internet o reintenta. / Could not download the file list.", 15)
    return
end

-- 2) lo que falta o cambio de version
local versionAnterior = ""
if isfile(CARPETA .. "/version_instalada.txt") then
    local ok, v = pcall(readfile, CARPETA .. "/version_instalada.txt")
    if ok and type(v) == "string" then versionAnterior = v end
end
local pendientes = {}
-- ¿esta el archivo bien en disco? (el que viene dentro de un assets.pack se comprueba por sus archivos de dentro)
local function enDisco(nombre, tam)
    local ruta = CARPETA .. "/" .. nombre
    if not isfile(ruta) then return false end
    local ok, contenido = pcall(readfile, ruta)
    return ok and type(contenido) == "string" and #contenido == tam
end
for _, a in ipairs(manifest.archivos) do
    local actual = false
    if versionAnterior == manifest.version then
        if a.pack then
            actual = true
            for _, interior in ipairs(a.pack) do
                if not enDisco(interior.n, interior.tam) then actual = false break end
            end
        else
            actual = enDisco(a.n, a.tam)
        end
    end
    if not actual then table.insert(pendientes, a) end
end

-- 3) la descarga (de a LOTE archivos), con 3 intentos por archivo
if #pendientes > 0 then
    aviso("Zenith Sky Changer", "Instalando " .. tostring(manifest.version) .. ": " .. #pendientes .. " archivos... / Installing...", 8)
    local fallaron, hechos = {}, 0
    local i = 1
    while i <= #pendientes do
        local en_curso = 0
        for j = i, math.min(i + LOTE - 1, #pendientes) do
            local a = pendientes[j]
            en_curso = en_curso + 1
            task.spawn(function()
                local ok = false
                for _ = 1, 3 do
                    local cuerpo = pedir(BASE .. "archivos/" .. a.n)
                    if cuerpo and #cuerpo == a.tam then
                        if a.pack then
                            -- assets.pack: las imagenes y los audios uno detras de otro (la lista y los tamaños estan en manifest.json); cada uno se guarda en su archivo
                            ok = true
                            local desde = 1
                            for _, interior in ipairs(a.pack) do
                                if not pcall(writefile, CARPETA .. "/" .. interior.n, cuerpo:sub(desde, desde + interior.tam - 1)) then ok = false end
                                desde = desde + interior.tam
                            end
                        else
                            ok = pcall(writefile, CARPETA .. "/" .. a.n, cuerpo)
                        end
                        if ok then break end
                    end
                    task.wait(0.5)
                end
                if not ok then table.insert(fallaron, a.n) end
                hechos = hechos + 1
                en_curso = en_curso - 1
            end)
        end
        while en_curso > 0 do task.wait(0.1) end
        i = i + LOTE
    end
    if #fallaron > 0 then
        aviso("Zenith Sky Changer", "No se pudieron bajar " .. #fallaron .. " archivos (" .. table.concat(fallaron, ", "):sub(1, 90) .. "). Reintenta. / Some downloads failed, retry.", 20)
        return
    end
    pcall(writefile, CARPETA .. "/version_instalada.txt", tostring(manifest.version))
end

-- 4) ejecutar (cielo.lua, el cargador pequeno de dentro, lee CieloRoblox/cielo_main.lua y avisa si algo falla)
local ok, codigo = pcall(readfile, CARPETA .. "/cielo.lua")
if not (ok and type(codigo) == "string" and codigo ~= "") then
    aviso("Zenith Sky Changer", "Falta ZenithSky/cielo.lua. Reintenta. / Missing file, retry.", 15)
    return
end
local funcion, fallo = loadstring(codigo, "=cielo_cargador")
if not funcion then
    aviso("Zenith Sky Changer", "No compila: " .. tostring(fallo), 20)
    return
end
funcion()
