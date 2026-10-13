--[[
    CIELO ROBLOX - cargador
    El script de verdad está en cielo_main.lua. Esto lo carga y, si algo falla,
    lo muestra en pantalla en vez de quedarse callado.
    En Xeno se ejecuta con:  loadstring(readfile("ZenithSky/cielo.lua"))()
]]

local function avisar(texto)
    warn("[Cielo] " .. texto)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Cielo: error",
            Text = texto:sub(1, 180),
            Duration = 30,
        })
    end)
end

local leido, codigo = pcall(readfile, "ZenithSky/cielo_main.lua")
if not leido or type(codigo) ~= "string" or codigo == "" then
    avisar("No pude leer ZenithSky/cielo_main.lua. Vuelve a ejecutar el cargador / Run the loader again.")
    return
end

local funcion, fallo = loadstring(codigo, "=cielo")
if not funcion then
    avisar("No compila: " .. tostring(fallo))
    return
end

local bien, problema = xpcall(funcion, function(e)
    return tostring(e) .. "\n" .. debug.traceback()
end)
if not bien then
    avisar(tostring(problema))
end
