--[[
    CIELO ROBLOX - todo en una sola ventana (para Xeno)

    CIELO:   pone tu foto como cielo. Las fotos se agregan con la app "Cielo Roblox"
             del PC (arrastrando la foto o con clic para abrirla).
    COLORES: pinta los bloques del mapa del color que elijas en la rueda.
    SKINS y WRAPS (solo en Rivals): cualquier skin o wrap en tu arma, con sus sonidos,
             sus animaciones y su imagen en la barra de armas. Cada una con vista previa y
             su propia opacidad (en 0% el arma no se ve).
    DAÑO:    encima de la mira, una barrita que se llena con cada golpe hasta eliminar
             al que le pegas, con la vida que le queda. Se configura en la página DAÑO.
    FPS:     contador de FPS y botones para aligerar el juego (sombras, efectos de luz,
             terreno, luces del mapa): como bajar los gráficos.
    Todo es local: solo lo ves tú; los demás siguen viendo el juego normal.

    Tecla + (o -) = abrir / achicar la ventana (achicada queda un iconito del cielo)
    F8 = cielo on/off     F6 = colores on/off
    La ventana se mueve desde la cabecera y cambia de tamaño desde la esquina de abajo.
    Abierta, suelta el mouse (para poder usarla); achicada se juega normal.
    La × la esconde entera: todo sigue puesto. Si lo ejecutas otra vez, reemplaza al anterior.
    La app pone autoexec.lua en la carpeta autoexec de Xeno: al entrar a Rivals se ejecuta
    solo y empieza achicada (el iconito).
]]

-- versión: sube en cada cambio (la lista está en CAMBIOS.txt)
local VERSION = "v7.01"

-- (v6.97) PERFIL: con que forma se arma este script. "completo" = el del usuario (todo); "sky" = ZENITH SKY CHANGER (solo CIELO y COLORES) y "skins" = ZENITH SKIN CHANGER (solo SKINS y
-- WRAPS), las dos versiones PUBLICAS: tienen su propia carpeta, su ventana y su tecla, asi se pueden tener las dos a la vez. herramientas/publicar.py cambia la linea de abajo y, ademas,
-- quita el codigo de los modulos que no van (en lugar de dejarlo apagado) y los cambia por NADA.
local PERFIL = "sky"
local PERFILES = {
    completo = {
        nombre = "Cielo", marca = "CIELO", carpeta = "CieloRoblox", gui = "CieloUI", claves = { "CieloPersonalizado", "SkinsRivals" }, globales = "Cielo", inicial = "cielo",
        secciones = { cielo = true, colores = true, skins = true, wraps = true, dano = true, fps = true, optimizar = true, jugadores = true, config = true },
        teclas = "+ o - la achica a un iconito (y la vuelve a abrir). F8 cielo, F6 colores.",
    },
    sky = {
        nombre = "Zenith Sky Changer", marca = "ZENITH", carpeta = "ZenithSky", gui = "ZenithSkyUI", claves = { "ZenithSkyChanger" }, globales = "ZenithSky", inicial = "cielo",
        secciones = { cielo = true, colores = true, config = true },
        teclas = "+ la achica a un iconito (y la vuelve a abrir). F8 cielo, F6 colores.",
    },
    skins = {
        nombre = "Zenith Skin Changer", marca = "ZENITH", icono = "zenith_skins_icono.png", carpeta = "ZenithSkins", gui = "ZenithSkinsUI", claves = { "ZenithSkinChanger" }, globales = "ZenithSkins", inicial = "skins",
        secciones = { skins = true, wraps = true, config = true },
        teclas = "la tecla - la achica a un iconito (y la vuelve a abrir).",
        -- la paleta de la espada que eligio el usuario (violeta noche, lila claro, verde lima de la guarda): v6.98
        gradiente = { Color3.fromRGB(248, 232, 255), Color3.fromRGB(176, 128, 255), Color3.fromRGB(168, 236, 124) },
        paleta = {
            fondo = Color3.fromRGB(8, 6, 24), panel = Color3.fromRGB(24, 17, 58), panel2 = Color3.fromRGB(46, 34, 100), linea = Color3.fromRGB(76, 58, 142),
            acento = Color3.fromRGB(168, 236, 124), durazno = Color3.fromRGB(190, 146, 255), texto = Color3.fromRGB(244, 236, 255),
            tenue = Color3.fromRGB(172, 156, 214), oscuro = Color3.fromRGB(14, 10, 36),
        },
    },
}
local PF = PERFILES[PERFIL]
local CARPETA = PF.carpeta
-- (v7.00) CONFIGURACION e IDIOMAS: CFG = config.txt; DIC = las traducciones del idioma elegido (nil = español); traducir() cambia un texto en español por el del idioma
local CFG = {}
local DIC = nil
local traducir = function(s) return s end
-- lo que no va en este perfil: los modulos que se quitan se cambian por esto (cualquier funcion existe y no hace nada)
local NADA = setmetatable({
    estado = function() return {} end, cuantas = function() return 0, 0 end, enRivals = function() return false end,
}, { __index = function() return function() end end })
local TECLA_CIELO = Enum.KeyCode.F8
local TECLA_COLORES = Enum.KeyCode.F6
-- tecla + para la ventana. Según el teclado (español, latino, inglés o el del
-- teclado numérico) Roblox la ve con distinto nombre, así que van todas
local TECLAS_VENTANA = {
    [Enum.KeyCode.Equals] = true, [Enum.KeyCode.Plus] = true,
    [Enum.KeyCode.KeypadPlus] = true, [Enum.KeyCode.RightBracket] = true,
}
-- la tecla - (la de SKINS cuando iba aparte) también abre la ventana, directo en SKINS
local TECLAS_SKINS = { [Enum.KeyCode.Minus] = true, [Enum.KeyCode.KeypadMinus] = true }
-- (v6.97) ZENITH SKIN CHANGER usa la tecla - para su ventana; el SKY, la +; asi se pueden tener los dos
if PERFIL == "skins" then
    TECLAS_VENTANA, TECLAS_SKINS = TECLAS_SKINS, {}
elseif PERFIL == "sky" then
    TECLAS_SKINS = {}
end
-- (v7.00) la tecla de la ventana se puede elegir en CONFIGURACION (config.txt: tecla=mas|menos|insert|rshift|home)
local TECLAS_ELEGIBLES = {
    { "mas", "+", { Enum.KeyCode.Equals, Enum.KeyCode.Plus, Enum.KeyCode.KeypadPlus, Enum.KeyCode.RightBracket } },
    { "menos", "-", { Enum.KeyCode.Minus, Enum.KeyCode.KeypadMinus } },
    { "insert", "Insert", { Enum.KeyCode.Insert } },
    { "rshift", "Right Shift", { Enum.KeyCode.RightShift } },
    { "home", "Home", { Enum.KeyCode.Home } },
}
local NOMBRE_TECLA = (PERFIL == "skins") and "-" or "+"

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")
local Terrain = workspace:FindFirstChildOfClass("Terrain")
local jugador = Players.LocalPlayer

-- si ya había uno corriendo (este, o el SKINS de antes que iba aparte), se apaga
-- antes de guardar "lo original". Se busca en los tres lugares posibles: según el
-- executor, getgenv() puede no ser el mismo entre una ejecución y otra
local env = (getgenv and getgenv()) or _G
local registros = { env, shared, _G }
for _, tabla in ipairs(registros) do
    if type(tabla) == "table" then
        for _, clave in ipairs(PF.claves) do
            local anterior = rawget(tabla, clave)
            if anterior then
                pcall(anterior.Limpiar)
                rawset(tabla, clave, nil)
            end
        end
    end
end

-- skins.lua (la pestaña vieja de Xeno) pide abrir la ventana directo en SKINS, y el
-- autoexec (se ejecuta solo al entrar a Rivals) pide empezar achicada, en el iconito
local pestanaInicial, inicioAchicado = nil, false
for _, tabla in ipairs(registros) do
    if type(tabla) == "table" then
        if rawget(tabla, PF.globales .. "PestanaInicial") then
            pestanaInicial = rawget(tabla, PF.globales .. "PestanaInicial")
            rawset(tabla, PF.globales .. "PestanaInicial", nil)
        end
        if rawget(tabla, PF.globales .. "InicioAchicado") then
            inicioAchicado = true
            rawset(tabla, PF.globales .. "InicioAchicado", nil)
        end
    end
end

local function contenedoresGui()
    local lista = {}
    if gethui then pcall(function() table.insert(lista, gethui()) end) end
    pcall(function() table.insert(lista, game:GetService("CoreGui")) end)
    pcall(function() table.insert(lista, jugador:FindFirstChildOfClass("PlayerGui")) end)
    return lista
end

-- y por si quedó alguna ventana de una versión vieja que no se dejó apagar
-- (la del cielo o la de SKINS), se borra igual
local function borrarVentanasViejas(menos)
    for _, contenedor in ipairs(contenedoresGui()) do
        pcall(function()
            for _, hijo in ipairs(contenedor:GetChildren()) do
                if (hijo.Name == PF.gui or (PERFIL == "completo" and hijo.Name == "SkinsUI")) and hijo ~= menos then hijo:Destroy() end
            end
        end)
    end
end
borrarVentanasViejas(nil)

local function aviso(texto)
    warn("[Cielo] " .. texto)
    if CFG.avisos == "0" then return end -- CONFIGURACION: avisos en pantalla apagados
    pcall(StarterGui.SetCore, StarterGui, "SendNotification", {
        Title = PF.nombre .. " " .. VERSION,
        Text = traducir(texto),
        Duration = 5,
    })
end

-- Funciones del executor ----------------------------------------------------

local cargarAsset = getcustomasset or getsynasset
local disponibles = {
    readfile = readfile, writefile = writefile, listfiles = listfiles,
    isfolder = isfolder, makefolder = makefolder, getcustomasset = cargarAsset,
}
local faltan = {}
for _, nombreFuncion in ipairs({ "readfile", "writefile", "listfiles", "isfolder", "makefolder", "getcustomasset" }) do
    if type(disponibles[nombreFuncion]) ~= "function" then
        table.insert(faltan, nombreFuncion)
    end
end
if #faltan > 0 then
    aviso("A tu executor le falta: " .. table.concat(faltan, ", "))
    return
end

-- Archivos -------------------------------------------------------------------

local function ruta(...)
    return table.concat({ CARPETA, ... }, "/")
end

local function leer(r)
    local ok, texto = pcall(readfile, r)
    if ok and type(texto) == "string" then
        return texto
    end
    return nil
end

local function escribir(r, texto)
    pcall(writefile, r, texto)
end

local function esCarpeta(r)
    local ok, si = pcall(isfolder, r)
    return ok and si == true
end

if not esCarpeta(CARPETA) then pcall(makefolder, CARPETA) end
if not esCarpeta(ruta("cielos")) then pcall(makefolder, ruta("cielos")) end

-- Configuracion (v7.00) --------------------------------------------------------
for linea in (leer(ruta("config.txt")) or ""):gmatch("[^\r\n]+") do
    local clave, valor = linea:match("^(%w+)=(.*)$")
    if clave then CFG[clave] = valor end
end
local function guardarConfig()
    local t = {}
    for clave, valor in pairs(CFG) do table.insert(t, clave .. "=" .. tostring(valor)) end
    table.sort(t)
    escribir(ruta("config.txt"), table.concat(t, "\n"))
end
local IDIOMAS = { { "en", "English" }, { "es", "Español (México)" }, { "ru", "Русский" }, { "pt", "Português (Brasil)" } }
local IDIOMA = CFG.idioma
local idiomaValido = false
for _, par in ipairs(IDIOMAS) do if par[1] == IDIOMA then idiomaValido = true end end
if not idiomaValido then
    -- sin eleccion: el de Roblox (es, pt, ru o ingles); el script del usuario sigue en español
    local ok, id = pcall(function() return game:GetService("LocalizationService").RobloxLocaleId end)
    id = ok and tostring(id):lower():sub(1, 2) or ""
    IDIOMA = (PERFIL == "completo") and "es" or ((id == "es" or id == "pt" or id == "ru") and id or "en")
end
if IDIOMA ~= "es" then
    local ok, tabla = pcall(function() return loadstring(leer(ruta("idiomas.lua")) or "return {}", "=idiomas")() end)
    DIC = (ok and type(tabla) == "table") and tabla[IDIOMA] or nil
end
if DIC then
    local fragmentos = {}
    for clave in pairs(DIC) do
        if #clave >= 8 then table.insert(fragmentos, clave) end
    end
    table.sort(fragmentos, function(a, b) return #a > #b end)
    -- el texto entero, o (si es una frase armada con pedazos, "En la mano: " + el arma) cada pedazo conocido
    traducir = function(s)
        if type(s) ~= "string" or s == "" then return s end
        local t = DIC[s]
        if t then return t end
        for _, clave in ipairs(fragmentos) do
            local i, j = s:find(clave, 1, true)
            if i then s = s:sub(1, i - 1) .. DIC[clave] .. s:sub(j + 1) end
        end
        return s
    end
end

-- Ventana ----------------------------------------------------------------------
-- Grande (más de un tercio de la pantalla), se mueve desde la cabecera, cambia de
-- tamaño desde la esquina de abajo y con "–" se vuelve un iconito del cielo.

local C = {
    fondo = Color3.fromRGB(19, 15, 27),
    panel = Color3.fromRGB(34, 27, 46),
    panel2 = Color3.fromRGB(49, 39, 66),
    linea = Color3.fromRGB(58, 46, 78),
    acento = Color3.fromRGB(195, 155, 255),
    durazno = Color3.fromRGB(255, 201, 163),
    texto = Color3.fromRGB(241, 234, 249),
    tenue = Color3.fromRGB(164, 151, 181),
    oscuro = Color3.fromRGB(24, 17, 34),
}
if PF.paleta then
    for clave, color in pairs(PF.paleta) do C[clave] = color end
end

-- (v6.92) la letra de toda la ventana es Nunito (redonda, como la maqueta C): el codigo sigue pidiendo Gotham, Gotham Bold... y aqui se cambia por Nunito con el mismo peso
local FAMILIA_LETRA = (IDIOMA == "ru") and "rbxasset://fonts/families/SourceSansPro.json" or "rbxasset://fonts/families/Nunito.json" -- (v7.00) Nunito no tiene cirilico
local PESOS_LETRA = {
    [Enum.Font.Gotham] = Enum.FontWeight.Regular, [Enum.Font.GothamMedium] = Enum.FontWeight.Medium,
    [Enum.Font.GothamBold] = Enum.FontWeight.Bold, [Enum.Font.GothamBlack] = Enum.FontWeight.ExtraBold,
}
local function ponerLetra(obj, valor)
    local peso = PESOS_LETRA[valor]
    if not peso then
        obj.Font = valor
        return
    end
    local ok = pcall(function() obj.FontFace = Font.new(FAMILIA_LETRA, peso) end)
    if not ok then pcall(function() obj.Font = Enum.Font.Nunito end) end
end

local function crear(clase, props, hijos)
    local obj = Instance.new(clase)
    for clave, valor in pairs(props or {}) do
        if clave == "Font" then
            ponerLetra(obj, valor)
        elseif clave ~= "Parent" then
            obj[clave] = valor
        end
    end
    for _, hijo in ipairs(hijos or {}) do hijo.Parent = obj end
    -- (v7.00) idioma: el texto en español se cambia por el del idioma elegido, y lo mismo cada vez que el codigo lo cambie
    if DIC then
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            local function aplicar()
                local t = traducir(obj.Text)
                if t ~= obj.Text then obj.Text = t end
            end
            aplicar()
            obj:GetPropertyChangedSignal("Text"):Connect(aplicar)
        elseif obj:IsA("TextBox") then
            obj.PlaceholderText = traducir(obj.PlaceholderText)
        end
    end
    if props and props.Parent then obj.Parent = props.Parent end
    return obj
end

local function esquina(px)
    return crear("UICorner", { CornerRadius = UDim.new(0, px) })
end

local function trazo(color, grosor, transparencia)
    return crear("UIStroke", {
        Color = color, Thickness = grosor, Transparency = transparencia or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end

-- oscurece la parte de abajo de una imagen para que se lea el texto encima
local function sombraAbajo(padre, radio)
    return crear("Frame", {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0),
        BorderSizePixel = 0, Parent = padre,
    }, {
        esquina(radio),
        crear("UIGradient", {
            Rotation = 90,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.55, 1),
                NumberSequenceKeypoint.new(1, 0.25),
            }),
        }),
    })
end

local function padreGui()
    if gethui then
        local ok, contenedor = pcall(gethui)
        if ok and contenedor then return contenedor end
    end
    local ok, coreGui = pcall(function()
        local cg = game:GetService("CoreGui")
        local prueba = Instance.new("Folder")
        prueba.Parent = cg
        prueba:Destroy()
        return cg
    end)
    if ok and coreGui then return coreGui end
    return jugador:WaitForChild("PlayerGui")
end

-- las imágenes que deja la app: el iconito y la franja de la cabecera ("nubes moradas")
local function imagenPropia(archivo)
    local ok, id = pcall(cargarAsset, ruta(archivo))
    return (ok and type(id) == "string") and id or ""
end
-- (v6.99) cada perfil carga SU icono con un nombre propio: getcustomasset del ejecutor se acuerda del nombre del archivo, y si dos carpetas tienen un "icono.png" distinto sale el del primero que se cargo
local IMG_ICONO = imagenPropia(PF.icono or "icono.png")
local IMG_BANNER = imagenPropia("banner.png")

-- El material que tenían las partes que el optimizador alisó (SmoothPlastic). Las reglas de COLORES se
-- guardan por material, así que miran aquí para seguir encontrando sus bloques.
local materialOriginal = setmetatable({}, { __mode = "k" })
local function materialDe(parte)
    return (materialOriginal[parte] or parte.Material).Name
end

local LATERAL = 108                    -- ancho del riel de la izquierda (v6.92, rediseno C; v6.93: 68 -> 86; v6.95: 108, con el nombre de cada seccion escrito)
local CABECERA = 58                    -- alto de la barra de arriba (v6.92: ya no lleva la franja de nubes)
local MINIMO = Vector2.new(720, 700)   -- lo más chica que se puede achicar arrastrando (la barra de la izquierda cabe justo)

local vivo = true
local conexionesUI = {}
local alCambiarVentana = {} -- avisos para las páginas: se cambió de página, se achicó...
local alCambiarEstado = {}  -- avisos cuando se prende o apaga el cielo o los colores

-- Una barrita chica para elegir un número arrastrando: el título y el valor arriba, la barra
-- abajo. alCambiar(v) mientras se arrastra; alSoltar(v) al soltar (ahí se guarda o se aplica).
-- Devuelve una función para pintarla con otro valor.
local function barrita(padre, posicion, ancho, titulo, minimo, maximo, valor, alCambiar, alSoltar)
    local marco = crear("Frame", {
        Position = posicion, Size = ancho, BackgroundTransparency = 1, Parent = padre,
    })
    crear("TextLabel", {
        Size = UDim2.new(0.65, 0, 0, 14), Text = titulo, Font = Enum.Font.GothamBold, TextSize = 11,
        TextColor3 = C.tenue, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Parent = marco,
    })
    local etiqueta = crear("TextLabel", {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0.35, 0, 0, 14),
        Text = "", Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = C.acento,
        TextXAlignment = Enum.TextXAlignment.Right, BackgroundTransparency = 1, Parent = marco,
    })
    local pista = crear("TextButton", {
        Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, 0, 0, 8), Text = "", AutoButtonColor = false,
        BackgroundColor3 = C.panel2, Parent = marco,
    }, { crear("UICorner", { CornerRadius = UDim.new(1, 0) }) })
    local lleno = crear("Frame", {
        Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = pista,
    }, {
        crear("UICorner", { CornerRadius = UDim.new(1, 0) }),
        crear("UIGradient", { Color = ColorSequence.new(C.acento, C.durazno) }),
    })
    local perilla = crear("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(14, 14),
        BackgroundColor3 = C.texto, Parent = pista,
    }, { crear("UICorner", { CornerRadius = UDim.new(1, 0) }), trazo(C.oscuro, 2, 0) })
    local actual = valor
    local function pintar(v)
        actual = v
        local f = (v - minimo) / (maximo - minimo)
        lleno.Size = UDim2.fromScale(f, 1)
        perilla.Position = UDim2.fromScale(f, 0.5)
        etiqueta.Text = tostring(v) .. "%"
    end
    pintar(valor)
    local arrastrando = false
    local function leerMouse()
        local x = UserInputService:GetMouseLocation().X
        local f = math.clamp((x - pista.AbsolutePosition.X) / math.max(pista.AbsoluteSize.X, 1), 0, 1)
        local v = math.floor(minimo + f * (maximo - minimo) + 0.5)
        if v ~= actual then
            pintar(v)
            alCambiar(v)
        end
    end
    pista.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            arrastrando = true
            leerMouse()
        end
    end)
    table.insert(conexionesUI, UserInputService.InputChanged:Connect(function(input)
        if arrastrando and input.UserInputType == Enum.UserInputType.MouseMovement then leerMouse() end
    end))
    table.insert(conexionesUI, UserInputService.InputEnded:Connect(function(input)
        if arrastrando and input.UserInputType == Enum.UserInputType.MouseButton1 then
            arrastrando = false
            if alSoltar then alSoltar(actual) end
        end
    end))
    return pintar
end

-- Los botones que dejan algo "como estaba": el primer toque pide confirmación (el botón queda rojo
-- 3 segundos) y el segundo lo hace. Así un clic sin querer no borra nada.
local function conConfirmacion(boton, accion, textoSeguro)
    local texto, fondo, color, tam = boton.Text, boton.BackgroundColor3, boton.TextColor3, boton.TextSize
    local armado = 0
    local function volver()
        armado = 0
        boton.Text, boton.BackgroundColor3, boton.TextColor3, boton.TextSize = texto, fondo, color, tam
    end
    boton.MouseButton1Click:Connect(function()
        if armado > 0 and os.clock() - armado < 3 then
            volver()
            accion()
            return
        end
        armado = os.clock()
        local esta = armado
        boton.Text = textoSeguro or "¿Seguro? Toca otra vez"
        boton.TextSize = boton:GetAttribute("TamArmado") or boton.TextSize
        boton.BackgroundColor3 = Color3.fromRGB(255, 120, 140)
        boton.TextColor3 = C.oscuro
        task.delay(3, function()
            if armado == esta then volver() end
        end)
    end)
end

local function avisarEstado()
    for _, alCambiar in ipairs(alCambiarEstado) do pcall(alCambiar) end
end

local gui = crear("ScreenGui", {
    Name = PF.gui, ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 100,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})

local ventana = crear("Frame", {
    Name = "Ventana", Active = true, BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = gui,
}, {
    esquina(20), trazo(C.acento, 1, 0.5),
    crear("UIGradient", { Rotation = 150, Color = ColorSequence.new(C.fondo:Lerp(Color3.new(1, 1, 1), 0.07), C.fondo) }),
})
local escalaUI = crear("UIScale", { Scale = math.clamp((tonumber(CFG.escala) or 100) / 100, 0.8, 1.3), Parent = ventana }) -- (v7.00) CONFIGURACION: tamaño de la ventana

-- (v6.92, rediseno C: riel de iconos, barra de arriba limpia y tarjetas grandes; colores de la A)
-- la barra de arriba (desde aqui se arrastra la ventana): el nombre de la pagina, el arma, la version y los botones
local cabecera = crear("Frame", {
    Name = "Cabecera", Active = true, Position = UDim2.fromOffset(LATERAL, 0), Size = UDim2.new(1, -LATERAL, 0, CABECERA),
    BackgroundTransparency = 1, Parent = ventana,
})
local tituloPagina = crear("TextLabel", {
    Text = "Cielo", Font = Enum.Font.GothamBlack, TextSize = 23, TextColor3 = C.texto,
    TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, BackgroundTransparency = 1,
    Position = UDim2.fromOffset(18, 5), Size = UDim2.new(1, -330, 0, 28), Parent = cabecera,
})
-- (v6.95) lo que sirve la seccion, escrito debajo del nombre
if PF.gradiente then -- el titulo de la pagina con el degradado de la espada
    crear("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, PF.gradiente[1]), ColorSequenceKeypoint.new(0.55, PF.gradiente[2]), ColorSequenceKeypoint.new(1, PF.gradiente[3]),
        }),
    }).Parent = tituloPagina
end
local descripcionPagina = crear("TextLabel", {
    Text = "", Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = C.tenue,
    TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, BackgroundTransparency = 1,
    Position = UDim2.fromOffset(18, 33), Size = UDim2.new(1, -330, 0, 18), Parent = cabecera,
})
local derechaTop = crear("Frame", {
    AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -92, 0.5, 0), Size = UDim2.fromOffset(0, 28),
    AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Parent = cabecera,
}, {
    crear("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center,
        HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8),
    }),
})
local contextoTop = crear("TextLabel", { -- el arma en la mano (solo en SKINS y WRAPS)
    LayoutOrder = 1, Text = "", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C.tenue,
    BackgroundColor3 = C.panel, Size = UDim2.fromOffset(0, 28), AutomaticSize = Enum.AutomaticSize.X, Visible = false,
    Parent = derechaTop,
}, { esquina(14), trazo(C.linea, 1, 0), crear("UIPadding", { PaddingLeft = UDim.new(0, 13), PaddingRight = UDim.new(0, 13) }) })
local pildoraVersion = crear("TextLabel", {
    LayoutOrder = 2, Text = VERSION, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.tenue, BackgroundColor3 = C.panel,
    Size = UDim2.fromOffset(0, 26), AutomaticSize = Enum.AutomaticSize.X, Parent = derechaTop,
}, { esquina(13), trazo(C.linea, 1, 0), crear("UIPadding", { PaddingLeft = UDim.new(0, 11), PaddingRight = UDim.new(0, 11) }) })

local function botonCabecera(texto, x, tamTexto)
    local boton = crear("TextButton", {
        Text = texto, Font = Enum.Font.GothamBold, TextSize = tamTexto, TextColor3 = C.texto,
        BackgroundColor3 = C.panel, AutoButtonColor = false,
        Size = UDim2.fromOffset(34, 34), Position = UDim2.new(1, x, 0.5, -17), Parent = cabecera,
    }, { esquina(12), trazo(C.linea, 1, 0) })
    boton.MouseEnter:Connect(function() boton.BackgroundColor3 = C.panel2 end)
    boton.MouseLeave:Connect(function() boton.BackgroundColor3 = C.panel end)
    return boton
end
local botonMinimizar = botonCabecera("–", -88, 20)
local botonCerrar = botonCabecera("×", -48, 22)

-- el riel de la izquierda: el logo arriba, las ocho secciones (solo iconos; el nombre sale al pasar el mouse) y abajo los atajos
local riel = crear("Frame", {
    Name = "Riel", Size = UDim2.new(0, LATERAL, 1, 0), BackgroundColor3 = C.panel, BorderSizePixel = 0, Parent = ventana,
}, { esquina(20) })
crear("Frame", { -- tapa el redondeo del lado de adentro
    Position = UDim2.new(1, -20, 0, 0), Size = UDim2.new(0, 20, 1, 0), BackgroundColor3 = C.panel, BorderSizePixel = 0, Parent = riel,
})
crear("Frame", { -- la raya que separa el riel del contenido
    Position = UDim2.new(1, -1, 0, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = C.linea, BorderSizePixel = 0, Parent = riel,
})
local logoRiel = crear("ImageLabel", {
    Image = IMG_ICONO, ScaleType = Enum.ScaleType.Crop, BackgroundColor3 = C.panel2, BorderSizePixel = 0,
    Position = UDim2.fromOffset((LATERAL - 46) / 2, 8), Size = UDim2.fromOffset(46, 46), Parent = riel,
}, { esquina(15), trazo(C.acento, 1.5, 0.3) })
if IMG_ICONO == "" then
    crear("TextLabel", {
        Text = "☁️", Font = Enum.Font.GothamBold, TextSize = 20, BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1), Parent = logoRiel,
    })
end
crear("TextLabel", {
    Text = PF.marca, Font = Enum.Font.GothamBlack, TextSize = 12, TextColor3 = C.acento, BackgroundTransparency = 1,
    Position = UDim2.fromOffset(0, 55), Size = UDim2.new(1, 0, 0, 16), Parent = riel,
})
logoRiel:SetAttribute("Tip", PF.nombre .. " " .. VERSION .. "  ·  solo lo ves tú")

local navegacion = crear("Frame", {
    Position = UDim2.fromOffset(0, 76), Size = UDim2.new(1, 0, 0, 470), BackgroundTransparency = 1, Parent = riel,
}, {
    crear("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2), HorizontalAlignment = Enum.HorizontalAlignment.Center,
    }),
})
local function separadorRiel(orden)
    if PERFIL ~= "completo" then return end
    crear("Frame", {
        LayoutOrder = orden, Size = UDim2.fromOffset(72, 1), BackgroundColor3 = C.linea, BorderSizePixel = 0, Parent = navegacion,
    })
end

-- los atajos de abajo (cielo, colores y daño prendidos o apagados; "todo como estaba"): botones cuadrados, el estado se ve en el color
local atajos = crear("Frame", {
    AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -12), Size = UDim2.new(1, 0, 0, 4 * 30 + 3 * 3),
    BackgroundTransparency = 1, Parent = riel,
}, {
    crear("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 3), HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
    }),
})
local function atajo(orden)
    return crear("TextButton", {
        LayoutOrder = orden, Size = UDim2.fromOffset(96, 30), Font = Enum.Font.GothamBold, TextSize = 11,
        Text = "", AutoButtonColor = false, BackgroundColor3 = C.panel2, Parent = atajos,
    }, { esquina(12) })
end
local atajoCielo = atajo(1)
local atajoColores = atajo(2)
local atajoDano = atajo(3)
-- deja todo como estaba el juego (con confirmacion; se conecta al final, cuando ya estan los modulos)
local atajoTodo = atajo(4)
atajoTodo.Text = "🔄 Como estaba"
atajoTodo.TextColor3 = C.texto
atajoTodo:SetAttribute("TamArmado", 10)
atajoTodo:SetAttribute("Tip", "Deja TODO como estaba: cielo, colores, armas y graficos (toca dos veces)")
trazo(Color3.fromRGB(255, 120, 140), 1, 0.4).Parent = atajoTodo

-- el globo de ayuda: el nombre de lo que tiene el mouse encima (atributo "Tip")
local globo = crear("Frame", {
    Visible = false, ZIndex = 80, AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(0, 28),
    AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = C.oscuro, BorderSizePixel = 0, Parent = ventana,
}, { esquina(9), trazo(C.acento, 1, 0.5), crear("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }) })
local globoTexto = crear("TextLabel", {
    ZIndex = 81, Text = "", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.texto, BackgroundTransparency = 1,
    Size = UDim2.fromOffset(0, 28), AutomaticSize = Enum.AutomaticSize.X, Parent = globo,
})
local function conGlobo(boton)
    boton.MouseEnter:Connect(function()
        local texto = boton:GetAttribute("Tip")
        if not texto then return end
        globoTexto.Text = texto
        globo.Position = UDim2.fromOffset(LATERAL + 8, boton.AbsolutePosition.Y - ventana.AbsolutePosition.Y + boton.AbsoluteSize.Y / 2)
        globo.Visible = true
    end)
    boton.MouseLeave:Connect(function() globo.Visible = false end)
end
-- (v6.97) en cada perfil solo estan los atajos de lo que trae
atajoCielo.Visible = PF.secciones.cielo == true
atajoColores.Visible = PF.secciones.colores == true
atajoDano.Visible = PF.secciones.dano == true
for _, b in ipairs({ logoRiel, atajoCielo, atajoColores, atajoDano, atajoTodo }) do
    if b:IsA("GuiObject") then
        b.Active = true
        conGlobo(b)
    end
end

-- el contenido: una página por sección
local zonaPaginas = crear("Frame", {
    Name = "Contenido", Position = UDim2.fromOffset(LATERAL, CABECERA),
    Size = UDim2.new(1, -LATERAL, 1, -CABECERA), BackgroundTransparency = 1, Parent = ventana,
}, {
    crear("UIPadding", {
        PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18),
        PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 16),
    }),
})

local function pagina(nombrePagina)
    return crear("Frame", {
        Name = nombrePagina, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        Visible = false, Parent = zonaPaginas,
    })
end

local paginaCielo = pagina("Cielo")
local paginaColores = pagina("Colores")
local paginaSkins = pagina("Skins") -- SKINS y WRAPS usan la misma página
local paginaDano = pagina("Dano")   -- la configuración del contador de daño
local paginaFps = pagina("Fps")     -- rendimiento: contador de FPS y lo que se puede aligerar
local paginaOptimizar = pagina("Optimizar") -- el super optimizador para servers llenos
local paginaJugadores = pagina("Jugadores") -- la gente del server, para reportar
local paginaConfig = pagina("Config")     -- (v7.00) idioma y opciones de la ventana
local paginas = {
    cielo = paginaCielo, colores = paginaColores, skins = paginaSkins, wraps = paginaSkins, dano = paginaDano,
    fps = paginaFps, optimizar = paginaOptimizar, jugadores = paginaJugadores, config = paginaConfig,
}
local paginaActual = PF.inicial
local estadoVentana = "abierta" -- "abierta", "icono" (achicada) u "oculta" (con la ×)
local botonesPestana = {}
local refrescarVentana -- más abajo

local function abierta()
    return estadoVentana == "abierta"
end

local TITULOS_PAGINA = {
    cielo = "Cielo", colores = "Colores", skins = "Skins", wraps = "Wraps", dano = "Daño", fps = "FPS", optimizar = "Optimizar", jugadores = "Jugadores", config = "Configuración",
}
local ALTO_PESTANA = (PERFIL == "completo") and 46 or 54 -- (v7.00) con 9 secciones los botones son un poco mas bajos
-- (v6.95) para qué sirve cada seccion: se ve debajo del nombre en la barra de arriba y en el globo al pasar el mouse
local DESCRIPCION_PAGINA = {
    cielo = "Pon una foto tuya como cielo del juego",
    colores = "Pinta los bloques del mapa de otro color",
    skins = "Cambia el aspecto de tus armas con skins",
    wraps = "Ponle un forro (material o diseño) a tus armas",
    dano = "Contador de daño en pantalla",
    fps = "Contador de FPS y ajustes para ir mas fluido",
    optimizar = "Modo para servers llenos: baja detalles para que no se trabe",
    jugadores = "La gente del server, para reportar a alguien",
    config = "Idioma y opciones de la ventana",
}
local function pestana(nombrePestana, simbolo, texto, orden)
    if not PF.secciones[nombrePestana] then return end -- (v6.97) esta seccion no va en este perfil
    local boton = crear("TextButton", {
        LayoutOrder = orden, Text = "", AutoButtonColor = false, Size = UDim2.fromOffset(96, ALTO_PESTANA),
        BackgroundColor3 = C.panel2, BackgroundTransparency = 1, Parent = navegacion,
    }, { esquina(14) })
    boton:SetAttribute("Tip", DESCRIPCION_PAGINA[nombrePestana] or texto)
    local marca = crear("Frame", { -- (ya no hay marca al lado: la pestana activa se pinta entera)
        Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1, Visible = false, Parent = boton,
    })
    crear("TextLabel", { -- el icono
        Text = simbolo, Font = Enum.Font.GothamBold, TextSize = 24, TextColor3 = C.texto,
        BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 2), Size = UDim2.new(1, 0, 0, ALTO_PESTANA - 22), Parent = boton,
    })
    local etiqueta = crear("TextLabel", { -- el nombre
        Text = TITULOS_PAGINA[nombrePestana] or texto, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C.tenue,
        BackgroundTransparency = 1, Position = UDim2.fromOffset(0, ALTO_PESTANA - 19), Size = UDim2.new(1, 0, 0, 17), Parent = boton,
    })
    boton.MouseEnter:Connect(function()
        if paginaActual ~= nombrePestana then boton.BackgroundTransparency = 0.6 end
    end)
    boton.MouseLeave:Connect(function()
        if paginaActual ~= nombrePestana then boton.BackgroundTransparency = 1 end
    end)
    conGlobo(boton)
    boton.MouseButton1Click:Connect(function()
        paginaActual = nombrePestana
        refrescarVentana()
    end)
    botonesPestana[nombrePestana] = { boton = boton, marca = marca, etiqueta = etiqueta }
end
pestana("cielo", "☁️", "CIELO", 1)
pestana("colores", "🎨", "COLORES", 2)
separadorRiel(3)
pestana("skins", "🔫", "SKINS", 4)
pestana("wraps", "✨", "WRAPS", 5)
pestana("dano", "🎯", "DAÑO", 6)
separadorRiel(7)
pestana("fps", "⚡", "FPS", 8)
pestana("optimizar", "🚀", "OPTIMIZAR", 9)
separadorRiel(10)
pestana("jugadores", "👥", "JUGADORES", 11)
separadorRiel(12)
pestana("config", "⚙️", "CONFIGURACION", 13) -- (v7.00) en todos los perfiles

-- la esquina de abajo a la derecha: arrastrarla cambia el tamaño
local asaTamano = crear("TextButton", {
    Text = "◢", FontFace = Font.fromEnum(Enum.Font.GothamBold), TextSize = 14, TextColor3 = C.tenue, AutoButtonColor = false,
    BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -4, 1, -4),
    Size = UDim2.fromOffset(20, 20), ZIndex = 10, Parent = ventana,
})

-- la ventana achicada: el iconito del cielo. Se puede mover; con un clic vuelve la ventana
local LADO_ICONO = 40
local burbuja = crear("ImageButton", {
    Name = "Iconito", Image = IMG_ICONO, ScaleType = Enum.ScaleType.Crop, AutoButtonColor = false,
    Visible = false, BackgroundColor3 = C.panel2, Size = UDim2.fromOffset(LADO_ICONO, LADO_ICONO), Parent = gui,
}, { esquina(12), trazo(C.acento, 1.5, 0.2) })
if IMG_ICONO == "" then
    crear("TextLabel", {
        Text = "☁️", Font = Enum.Font.GothamBold, TextSize = 20, BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1), Parent = burbuja,
    })
end

-- Mouse: con la ventana abierta se suelta (en Rivals y juegos de primera persona queda
-- trabado al centro); achicada o escondida se devuelve como estaba. Se fuerza cada cuadro
-- después de los scripts del juego, porque muchos lo vuelven a trabar solos.
local mouseDelJuego = nil -- { comportamiento, icono } de antes de soltarlo

local function primeraPersona()
    -- (v7.01) solo cuenta la camara pegada a la cabeza: CameraMode / CameraMaxZoomDistance tambien valen en el lobby de Rivals
    local camara = workspace.CurrentCamera
    local personaje = jugador.Character
    if not (camara and personaje) then return false end
    for _, nombreParte in ipairs({ "Head", "HumanoidRootPart" }) do
        local parte = personaje:FindFirstChild(nombreParte)
        if parte and parte:IsA("BasePart") and (camara.CFrame.Position - parte.Position).Magnitude < 3.5 then
            return true
        end
    end
    return false
end

local function soltarRender(nombreRender)
    pcall(function() RunService:UnbindFromRenderStep(nombreRender) end)
end

local function mouseLibre(libre)
    if libre and not mouseDelJuego then
        soltarRender("CieloTrabarMouse")
        mouseDelJuego = { UserInputService.MouseBehavior, UserInputService.MouseIconEnabled }
        RunService:BindToRenderStep("CieloSoltarMouse", Enum.RenderPriority.Last.Value + 1, function()
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            UserInputService.MouseIconEnabled = true
        end)
    elseif not libre and mouseDelJuego then
        soltarRender("CieloSoltarMouse")
        local comportamiento, icono = mouseDelJuego[1], mouseDelJuego[2]
        mouseDelJuego = nil

        -- (v7.01) solo se devuelve LockCenter (primera persona) o Default. LockCurrentPosition es el
        -- de "mantener clic derecho para girar": si se guardaba y se devolvia, el mouse quedaba trabado
        -- girando la camara sin clic. El juego lo vuelve a poner solo cuando aprietas el clic derecho.
        -- Trabado = el juego lo tenia en LockCenter, o el cursor invisible, o la camara pegada a la cabeza
        -- (aunque haya quedado suelto por culpa de otra cosa)
        local cerca = primeraPersona()
        local trabar = comportamiento == Enum.MouseBehavior.LockCenter or icono == false or cerca
        pcall(escribir, ruta("raton_log.txt"), string.format("antes=%s icono=%s camaraCerca=%s -> %s",
            tostring(comportamiento), tostring(icono), tostring(cerca), trabar and "LockCenter" or "Default"))
        comportamiento = trabar and Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default
        UserInputService.MouseBehavior = comportamiento
        UserInputService.MouseIconEnabled = icono

        -- por si el juego lo vuelve a soltar justo después, se vigila 2 segundos
        if trabar then
            local hasta = os.clock() + 2
            RunService:BindToRenderStep("CieloTrabarMouse", Enum.RenderPriority.Last.Value + 1, function()
                if os.clock() > hasta then
                    soltarRender("CieloTrabarMouse")
                elseif UserInputService.MouseBehavior == Enum.MouseBehavior.Default then
                    UserInputService.MouseBehavior = comportamiento
                end
            end)
        end
    end
end

refrescarVentana = function()
    ventana.Visible = estadoVentana == "abierta"
    burbuja.Visible = estadoVentana == "icono"
    mouseLibre(estadoVentana == "abierta")
    local visible = paginas[paginaActual]
    for _, p in ipairs({ paginaCielo, paginaColores, paginaSkins, paginaDano, paginaFps, paginaOptimizar, paginaJugadores, paginaConfig }) do
        p.Visible = p == visible
    end
    for nombrePestana, b in pairs(botonesPestana) do
        local activa = nombrePestana == paginaActual
        b.boton.BackgroundColor3 = activa and C.acento or C.panel2
        b.boton.BackgroundTransparency = activa and 0 or 1
        b.etiqueta.TextColor3 = activa and C.oscuro or C.tenue
        b.marca.Visible = false
    end
    tituloPagina.Text = TITULOS_PAGINA[paginaActual] or ""
    descripcionPagina.Text = DESCRIPCION_PAGINA[paginaActual] or ""
    contextoTop.Visible = (paginaActual == "skins" or paginaActual == "wraps") and contextoTop.Text ~= ""
    for _, alCambiar in ipairs(alCambiarVentana) do
        local ok, fallo = pcall(alCambiar)
        if not ok then warn("[Cielo] " .. tostring(fallo)) end
    end
end

local function abrirVentana(nombrePagina)
    estadoVentana = "abierta"
    if nombrePagina then paginaActual = nombrePagina end
    refrescarVentana()
end

local function achicarVentana()
    estadoVentana = "icono"
    refrescarVentana()
end

local function sobreVentana(p)
    local a, t = ventana.AbsolutePosition, ventana.AbsoluteSize
    return ventana.Visible and p.X >= a.X and p.X <= a.X + t.X and p.Y >= a.Y and p.Y <= a.Y + t.Y
end

-- Dónde está y de qué tamaño (se guarda en ventana.txt para la próxima vez) -------------

local function pantalla()
    local camara = workspace.CurrentCamera
    return camara and camara.ViewportSize or Vector2.new(1280, 720)
end

local function entre(v, minimo, maximo)
    if maximo < minimo then maximo = minimo end
    return math.max(minimo, math.min(maximo, v))
end

local geo = {}
do
    local n = {}
    for v in (leer(ruta("ventana.txt")) or ""):gmatch("-?%d+") do table.insert(n, tonumber(v)) end
    if #n >= 6 then geo = { x = n[1], y = n[2], w = n[3], h = n[4], bx = n[5], by = n[6] } end
end

local function guardarGeo()
    escribir(ruta("ventana.txt"), table.concat({ geo.x, geo.y, geo.w, geo.h, geo.bx, geo.by }, " "))
end

-- que todo quepa en la pantalla (y los tamaños de la primera vez)
local function acomodar()
    local p = pantalla()
    geo.w = math.floor(entre(geo.w or p.X * 0.42, math.min(MINIMO.X, p.X - 16), p.X - 16))
    geo.h = math.floor(entre(geo.h or p.Y * 0.78, math.min(MINIMO.Y, p.Y - 16), p.Y - 16))
    geo.x = math.floor(entre(geo.x or (p.X - geo.w - 28), 8, p.X - geo.w - 8))
    geo.y = math.floor(entre(geo.y or ((p.Y - geo.h) / 2), 8, p.Y - geo.h - 8))
    geo.bx = math.floor(entre(geo.bx or (p.X - 90), 8, p.X - LADO_ICONO - 8))
    geo.by = math.floor(entre(geo.by or (p.Y * 0.3), 8, p.Y - LADO_ICONO - 8))
    ventana.Size = UDim2.fromOffset(geo.w, geo.h)
    ventana.Position = UDim2.fromOffset(geo.x, geo.y)
    burbuja.Position = UDim2.fromOffset(geo.bx, geo.by)
end

-- arrastrar algo con el mouse: alMover recibe cuánto se movió desde que se apretó
local function arrastrable(asa, alEmpezar, alMover, alSoltar)
    asa.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local inicio = input.Position
        local movido = false
        alEmpezar()
        local mover = UserInputService.InputChanged:Connect(function(cambio)
            if cambio.UserInputType == Enum.UserInputType.MouseMovement
                or cambio.UserInputType == Enum.UserInputType.Touch then
                local d = cambio.Position - inicio
                if movido or d.Magnitude > 4 then
                    movido = true
                    alMover(Vector2.new(d.X, d.Y))
                end
            end
        end)
        local fin
        fin = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                mover:Disconnect()
                fin:Disconnect()
                alSoltar(movido)
            end
        end)
    end)
end

do
    local x0, y0, w0, h0, bx0, by0 = 0, 0, 0, 0, 0, 0
    -- mover la ventana desde la cabecera
    arrastrable(cabecera, function() x0, y0 = geo.x, geo.y end, function(d)
        local p = pantalla()
        geo.x = math.floor(entre(x0 + d.X, 0, p.X - geo.w))
        geo.y = math.floor(entre(y0 + d.Y, 0, p.Y - geo.h))
        ventana.Position = UDim2.fromOffset(geo.x, geo.y)
    end, function(movido)
        if movido then guardarGeo() end
    end)
    -- cambiar el tamaño desde la esquina
    arrastrable(asaTamano, function() w0, h0 = geo.w, geo.h end, function(d)
        local p = pantalla()
        geo.w = math.floor(entre(w0 + d.X, math.min(MINIMO.X, p.X - 16), p.X - geo.x - 4))
        geo.h = math.floor(entre(h0 + d.Y, math.min(MINIMO.Y, p.Y - 16), p.Y - geo.y - 4))
        ventana.Size = UDim2.fromOffset(geo.w, geo.h)
    end, function(movido)
        if movido then guardarGeo() end
    end)
    -- el iconito: arrastrado se mueve; con un clic (sin moverlo) vuelve la ventana
    arrastrable(burbuja, function() bx0, by0 = geo.bx, geo.by end, function(d)
        local p = pantalla()
        geo.bx = math.floor(entre(bx0 + d.X, 4, p.X - LADO_ICONO - 4))
        geo.by = math.floor(entre(by0 + d.Y, 4, p.Y - LADO_ICONO - 4))
        burbuja.Position = UDim2.fromOffset(geo.bx, geo.by)
    end, function(movido)
        if movido then
            guardarGeo()
        else
            abrirVentana()
        end
    end)
end

-- ============================================================================
-- CRISTAL (el reflejo del cielo)
-- ============================================================================
-- Cada superficie grande del mapa lleva encima una capa de vidrio (material Glass) apenas más
-- grande que ella. El vidrio de Roblox refleja según el ángulo (está en su shader: mezcla el cielo
-- con 0.8 × (1 − N·V)² × fuerza): mirado de frente o hacia los pies casi no refleja, y lejos,
-- donde el piso se ve de canto, refleja mucho. Como un cristal, no un espejo. La fuerza sale de la
-- Transparency de la capa (0.5 = toda, 1 = nada). Solo llevan capa las superficies que más se ven
-- (grandes y cerca), hasta MAX_CAPAS, y se revisan de a poco para no trabar el juego.

local moduloCristal = (function()
    local MAX_CAPAS = 200
    local HOLGURA = 0.08          -- studs entre la superficie y su capa (menos: parpadea de lejos)
    local REVISAR_POR_CUADRO = 300
    local NUEVAS_POR_CUADRO = 10
    local PAUSA = 0.5             -- segundos entre una vuelta por la lista y la siguiente

    local encendido = false
    local fuerza = 0.6
    local carpeta = nil
    local lista = {}                                       -- { p, centro, radio, area }
    local anotadas = setmetatable({}, { __mode = "k" })    -- parte -> true (ya está en la lista)
    local excluidas = setmetatable({}, { __mode = "k" })   -- partes con carteles (SurfaceGui)
    local capas = {}                                       -- parte -> { capa, conexiones }
    local cuantas = 0
    local umbral = 0.02
    local indice = 1
    local proximaVuelta = 0
    local conexiones = {}
    local generacion = 0
    local ultimoFallo = nil

    local function transparencia()
        return 1 - 0.5 * fuerza
    end

    local function esPersonajeOVista(p)
        local camara = workspace.CurrentCamera
        if camara and p:IsDescendantOf(camara) then return true end
        local vms = workspace:FindFirstChild("ViewModels")
        if vms and p:IsDescendantOf(vms) then return true end
        local modelo = p:FindFirstAncestorOfClass("Model")
        while modelo do
            if modelo:FindFirstChildOfClass("Humanoid") then return true end
            modelo = modelo:FindFirstAncestorOfClass("Model")
        end
        return false
    end

    -- lo que puede llevar capa: fijo, opaco, grande (la cara mayor de al menos 16 studs²) y de una
    -- forma que la capa copie. Nada con SpecialMesh (ya no es una caja) ni con carteles: con los
    -- gráficos altos lo que no es opaco no se ve a través del vidrio, y el cartel desaparecería.
    local function areaDe(p)
        if not (p:IsA("Part") or p:IsA("WedgePart") or p:IsA("CornerWedgePart")
            or p:IsA("MeshPart") or p:IsA("UnionOperation")) then return nil end
        if not p.Anchored or p.Transparency > 0.02 then return nil end
        local m = p.Material
        if m == Enum.Material.Glass or m == Enum.Material.ForceField or m == Enum.Material.Neon then return nil end
        local s = p.Size
        local area = s.X * s.Y * s.Z / math.min(s.X, s.Y, s.Z)
        if area < 16 then return nil end
        if p:FindFirstChildWhichIsA("DataModelMesh") or p:FindFirstChildWhichIsA("SurfaceGui") then return nil end
        if esPersonajeOVista(p) then return nil end
        return area
    end

    local function anotar(p)
        if anotadas[p] or excluidas[p] then return end
        local ok, area = pcall(areaDe, p)
        if not ok or not area then return end
        anotadas[p] = true
        table.insert(lista, { p = p, centro = p.Position, radio = p.Size.Magnitude / 2, area = area })
    end

    local function quitarCapa(p)
        local datos = capas[p]
        if not datos then return end
        capas[p] = nil
        cuantas = cuantas - 1
        for _, con in ipairs(datos.conexiones) do con:Disconnect() end
        pcall(function() datos.capa:Destroy() end)
    end

    local function quitarTodas()
        local partes = {}
        for p in pairs(capas) do table.insert(partes, p) end
        for _, p in ipairs(partes) do quitarCapa(p) end
        cuantas = 0
    end

    -- un cartel del juego pegado a una parte (desde PlayerGui o desde el mapa): esa va sin vidrio
    local function excluirCartel(gui)
        local p = gui.Adornee or gui.Parent
        if p and p:IsA("BasePart") then
            excluidas[p] = true
            quitarCapa(p)
        end
    end

    local function ponerCapa(p)
        if excluidas[p] or p.Transparency > 0.02 or p.LocalTransparencyModifier > 0.02 then return false end
        if not p:IsDescendantOf(workspace) then return false end -- el mapa guardado fuera, hasta la ronda
        local capa
        if p:IsA("MeshPart") or p:IsA("UnionOperation") then
            -- la misma malla, sin nada de lo que lleva adentro ni sus etiquetas (que el juego no la
            -- confunda con la de verdad)
            local ok, copia = pcall(p.Clone, p)
            if not ok or not copia then
                excluidas[p] = true -- no se deja copiar (Archivable apagado): no se vuelve a intentar
                return false
            end
            copia:ClearAllChildren()
            pcall(function()
                for _, etiqueta in ipairs(copia:GetTags()) do copia:RemoveTag(etiqueta) end
                for nombreAtributo in pairs(copia:GetAttributes()) do copia:SetAttribute(nombreAtributo, nil) end
            end)
            if copia:IsA("MeshPart") then pcall(function() copia.TextureID = "" end) end
            if copia:IsA("UnionOperation") then pcall(function() copia.UsePartColor = true end) end
            capa = copia
        elseif p:IsA("WedgePart") then
            capa = Instance.new("WedgePart")
        elseif p:IsA("CornerWedgePart") then
            capa = Instance.new("CornerWedgePart")
        else
            capa = Instance.new("Part")
            capa.Shape = p.Shape
            capa.TopSurface, capa.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
        end
        capa.Name = "CieloCristal"
        capa.Material = Enum.Material.Glass
        pcall(function() capa.MaterialVariant = "" end)
        capa.Color = Color3.new(1, 1, 1)
        capa.Reflectance = 0
        capa.Transparency = transparencia()
        capa.CastShadow = false
        capa.Anchored = true
        capa.CanCollide = false
        capa.CanTouch = false
        capa.CanQuery = false
        pcall(function() capa.AudioCanCollide = false end)
        capa.Massless = true
        capa.Locked = true
        local extra = Vector3.new(2 * HOLGURA, 2 * HOLGURA, 2 * HOLGURA)
        capa.Size = p.Size + extra
        capa.CFrame = p.CFrame
        capa.Parent = carpeta
        capas[p] = {
            capa = capa,
            conexiones = {
                p:GetPropertyChangedSignal("CFrame"):Connect(function() capa.CFrame = p.CFrame end),
                p:GetPropertyChangedSignal("Size"):Connect(function() capa.Size = p.Size + extra end),
                p:GetPropertyChangedSignal("Transparency"):Connect(function()
                    if p.Transparency > 0.02 then quitarCapa(p) end
                end),
                p.AncestryChanged:Connect(function()
                    if not p:IsDescendantOf(workspace) then quitarCapa(p) end
                end),
            },
        }
        cuantas = cuantas + 1
        return true
    end

    -- Cada cuadro revisa un tramo de la lista: puntaje = cara mayor / (distancia + 10)². Las que pasan
    -- el umbral llevan capa; al terminar la vuelta el umbral se corre para quedar cerca de MAX_CAPAS.
    local function paso()
        if not encendido or #lista == 0 then return end
        local camara = workspace.CurrentCamera
        if not camara then return end
        if not carpeta or not carpeta.Parent then
            -- se perdió la carpeta (cámara nueva o la borraron): de cero
            quitarTodas()
            carpeta = Instance.new("Folder")
            carpeta.Name = "CieloCristal"
            carpeta.Parent = camara
        elseif carpeta.Parent ~= camara then
            carpeta.Parent = camara
        end
        if indice == 1 and os.clock() < proximaVuelta then return end
        local pos = camara.CFrame.Position
        local nuevas = 0
        for _ = 1, REVISAR_POR_CUADRO do
            local n = #lista
            if indice > n then
                indice = 1
                proximaVuelta = os.clock() + PAUSA
                if cuantas >= MAX_CAPAS then
                    umbral = umbral * 1.3
                elseif cuantas < MAX_CAPAS * 0.75 then
                    umbral = math.max(umbral / 1.2, 1e-6)
                end
                return
            end
            local r = lista[indice]
            local p = r.p
            if p.Parent == nil then
                -- ya no está en el mapa: afuera de la lista (el último pasa a su lugar)
                quitarCapa(p)
                anotadas[p] = nil
                lista[indice] = lista[n]
                lista[n] = nil
            else
                r.centro = p.Position -- por si el mapa se movió a su lugar después de anotarlo
                local d = math.max(0, (r.centro - pos).Magnitude - r.radio) + 10
                local puntaje = r.area / (d * d)
                if capas[p] then
                    if puntaje < umbral * 0.7 then quitarCapa(p) end
                elseif puntaje >= umbral and cuantas < MAX_CAPAS and nuevas < NUEVAS_POR_CUADRO then
                    if ponerCapa(p) then nuevas = nuevas + 1 end
                end
                indice = indice + 1
            end
        end
    end

    local function quitar()
        if not encendido then return end
        encendido = false
        generacion = generacion + 1
        for _, con in ipairs(conexiones) do con:Disconnect() end
        table.clear(conexiones)
        quitarTodas()
        if carpeta then
            pcall(function() carpeta:Destroy() end)
            carpeta = nil
        end
        table.clear(lista)
        table.clear(anotadas)
        table.clear(excluidas)
    end

    -- f de 0 a 1. Si ya estaba puesto, solo cambia la fuerza (sin rearmar nada)
    local function poner(f)
        fuerza = math.clamp(f, 0, 1)
        if fuerza <= 0 then
            quitar()
            return
        end
        if encendido then
            local t = transparencia()
            for _, datos in pairs(capas) do datos.capa.Transparency = t end
            return
        end
        encendido = true
        generacion = generacion + 1
        local esta = generacion
        umbral, indice, proximaVuelta = 0.02, 1, 0

        table.insert(conexiones, RunService.Heartbeat:Connect(function()
            local ok, fallo = pcall(paso)
            if not ok and tostring(fallo) ~= ultimoFallo then
                ultimoFallo = tostring(fallo)
                warn("[Cristal] " .. ultimoFallo)
            end
        end))
        -- lo que llega después (mapa nuevo, ronda nueva)
        table.insert(conexiones, workspace.DescendantAdded:Connect(function(obj)
            if obj:IsA("BasePart") then
                task.defer(function()
                    if encendido and esta == generacion and obj.Parent then anotar(obj) end
                end)
            elseif obj:IsA("SurfaceGui") then
                task.defer(function()
                    if encendido and esta == generacion then excluirCartel(obj) end
                end)
            end
        end))
        local pg = jugador:FindFirstChildOfClass("PlayerGui")
        if pg then
            table.insert(conexiones, pg.DescendantAdded:Connect(function(obj)
                if obj:IsA("SurfaceGui") then
                    task.defer(function()
                        if encendido and esta == generacion then excluirCartel(obj) end
                    end)
                end
            end))
        end
        -- lo que ya está, de a poco (todo de un tirón traba el juego)
        task.spawn(function()
            if pg then
                for _, obj in ipairs(pg:GetDescendants()) do
                    if obj:IsA("SurfaceGui") then excluirCartel(obj) end
                end
            end
            for i, obj in ipairs(workspace:GetDescendants()) do
                if i % 500 == 0 then
                    task.wait()
                    if not encendido or esta ~= generacion or not vivo then return end
                end
                if obj:IsA("BasePart") then
                    anotar(obj)
                elseif obj:IsA("SurfaceGui") then
                    excluirCartel(obj)
                end
            end
        end)
    end

    return { poner = poner, quitar = quitar }
end)()

-- ============================================================================
-- CIELO Y COLORES
-- ============================================================================

local moduloCielo = (function()
    -- Archivos: la app del PC deja cada foto en CieloRoblox/cielos/<id>/ ya cortada
    -- en caras, y escribe en CieloRoblox/actual.txt cuál está elegida.

    local opciones = {
        unir = true,       -- bordes sin costuras (espejo + degradado) en vez de la foto repetida
        sinSol = true,
        sinNiebla = true,  -- la bruma/niebla del juego tapa el cielo
        sinNubes = true,
        reflejo = true,    -- capa de cristal: el mapa refleja el cielo de lejos (moduloCristal)
        luz = true,        -- la luz ambiente se tiñe un poco con los colores del cielo
    }
    local OPCIONES_DE_ENTRADA = table.clone(opciones) -- para "Como estaba"

    local function cargarOpciones()
        local texto = leer(ruta("opciones.txt"))
        if not texto then return end
        for clave, valor in texto:gmatch("(%w+)=(%d)") do
            if opciones[clave] ~= nil then
                opciones[clave] = valor == "1"
            end
        end
    end

    local function guardarOpciones()
        local lineas = {}
        for clave, valor in pairs(opciones) do
            table.insert(lineas, clave .. "=" .. (valor and "1" or "0"))
        end
        escribir(ruta("opciones.txt"), table.concat(lineas, "\n"))
    end

    -- cuánto refleja el cristal y cuánto se tiñe la luz (en %; se cambian con barritas en CIELO).
    -- El "reflejo=" de antes (el espejo de la v4.4) ya no se lee.
    local ajustes = { cristal = 60, luz = 30 }
    local AJUSTES_DE_ENTRADA = table.clone(ajustes)
    pcall(function()
        for clave, valor in (leer(ruta("ajustes_cielo.txt")) or ""):gmatch("(%a+)=(%d+)") do
            if ajustes[clave] ~= nil then ajustes[clave] = math.clamp(tonumber(valor), 0, 100) end
        end
    end)
    local function guardarAjustes()
        escribir(ruta("ajustes_cielo.txt"), ("cristal=%d\nluz=%d"):format(ajustes.cristal, ajustes.luz))
    end

    local assets = {}
    local function asset(id, cual)
        local r = ruta("cielos", id, id .. "_" .. cual .. ".png")
        if not assets[r] then
            local ok, res = pcall(cargarAsset, r)
            if ok and type(res) == "string" and res ~= "" then
                assets[r] = res
            end
        end
        return assets[r]
    end

    local function nombre(id)
        local texto = leer(ruta("cielos", id, "nombre.txt"))
        if not texto then return id end
        texto = texto:gsub("^%s+", ""):gsub("%s+$", "")
        return texto ~= "" and texto or id
    end

    local function listarCielos()
        local lista = {}
        local ok, rutas = pcall(listfiles, ruta("cielos"))
        if ok and type(rutas) == "table" then
            for _, r in ipairs(rutas) do
                local id = tostring(r):gsub("\\", "/"):match("([^/]+)/*$")
                if id and id:match("^c%d+$") then
                    table.insert(lista, id)
                end
            end
        end
        table.sort(lista, function(a, b) return a > b end) -- las más nuevas primero
        return lista
    end

    -- Forzar propiedades ------------------------------------------------------
    -- Pone un valor y lo vuelve a poner si el juego lo cambia (ciclos de día/noche,
    -- scripts que cambian el cielo...). Guarda lo último que el juego quiso poner
    -- para devolvérselo al apagar.

    local CARAS = { "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp" }

    local forzados = {}
    local conexiones = {}
    local carasActivas = {}
    local creado = nil
    local activo = false

    local function forzar(obj, prop, valor)
        local ok, original = pcall(function() return obj[prop] end)
        if not ok or not pcall(function() obj[prop] = valor end) then return end
        local registro = { obj = obj, prop = prop, original = original }
        local puesto = obj[prop] -- lo que Roblox guardó de verdad
        registro.con = obj:GetPropertyChangedSignal(prop):Connect(function()
            local actual = obj[prop]
            if actual ~= puesto then
                registro.original = actual
                obj[prop] = valor
                puesto = obj[prop]
            end
        end)
        table.insert(forzados, registro)
    end

    local function tomar(obj)
        if obj:IsA("Sky") then
            for cara, imagen in pairs(carasActivas) do
                forzar(obj, cara, imagen)
            end
            if opciones.sinSol then forzar(obj, "CelestialBodiesShown", false) end
            forzar(obj, "StarCount", 0)
        elseif obj:IsA("Atmosphere") and opciones.sinNiebla then
            forzar(obj, "Density", 0)
            forzar(obj, "Haze", 0)
            forzar(obj, "Glare", 0)
        elseif obj:IsA("Clouds") and opciones.sinNubes then
            forzar(obj, "Enabled", false)
        end
    end

    -- si el juego no tiene cielo propio (o lo borra), ponemos uno nuestro
    local function asegurarCielo()
        if activo and not Lighting:FindFirstChildOfClass("Sky") then
            creado = Instance.new("Sky")
            creado.Name = "CieloPersonalizado"
            tomar(creado)
            creado.Parent = Lighting
        end
    end

    local function activar()
        if activo then return end
        activo = true

        for _, obj in ipairs(Lighting:GetChildren()) do tomar(obj) end
        if Terrain then
            for _, obj in ipairs(Terrain:GetChildren()) do tomar(obj) end
        end
        asegurarCielo()

        -- la niebla vieja (la de Lighting, sin Atmosphere) también tapa el cielo
        if opciones.sinNiebla then
            forzar(Lighting, "FogEnd", 100000)
        end

        table.insert(conexiones, Lighting.ChildAdded:Connect(function(obj)
            if obj ~= creado then tomar(obj) end
        end))
        table.insert(conexiones, Lighting.ChildRemoved:Connect(function(obj)
            if obj:IsA("Sky") then task.defer(asegurarCielo) end
        end))
        if Terrain then
            table.insert(conexiones, Terrain.ChildAdded:Connect(tomar))
        end
    end

    local function desactivar()
        if not activo then return end
        activo = false

        for _, con in ipairs(conexiones) do con:Disconnect() end
        table.clear(conexiones)

        for i = #forzados, 1, -1 do
            local r = forzados[i]
            r.con:Disconnect()
            pcall(function() r.obj[r.prop] = r.original end)
        end
        table.clear(forzados)

        if creado then
            creado:Destroy()
            creado = nil
        end
    end

    -- Los colores que más hay en cada cielo (los saca la app: <id>_colores.txt, de más a menos)
    local coloresDeCielo = {}
    local function coloresDe(id)
        if not id then return {} end
        if not coloresDeCielo[id] then
            local lista = {}
            for hex in (leer(ruta("cielos", id, id .. "_colores.txt")) or ""):gmatch("#(%x%x%x%x%x%x)") do
                local ok, c = pcall(Color3.fromHex, hex)
                if ok then table.insert(lista, c) end
            end
            coloresDeCielo[id] = lista
        end
        return coloresDeCielo[id]
    end

    -- Luz del cielo: la luz ambiente (la de adentro y la de afuera) y la del sol se corren un poco
    -- hacia los colores del cielo. Muy poco: es tinte, no filtro, y no cuesta nada.
    local function aplicarLuz(id)
        local cols = coloresDe(id)
        if #cols == 0 or ajustes.luz <= 0 then return end
        local c1, c2 = cols[1], cols[2] or cols[1]
        local fuerza = ajustes.luz / 100
        forzar(Lighting, "Ambient", Lighting.Ambient:Lerp(c1, fuerza))
        forzar(Lighting, "OutdoorAmbient", Lighting.OutdoorAmbient:Lerp(c2, fuerza))
        forzar(Lighting, "ColorShift_Top", Lighting.ColorShift_Top:Lerp(c1, fuerza * 0.8))
    end

    -- Cristal: va aparte (moduloCristal). Se prende con el cielo propio y la opción "reflejo"; si
    -- ya estaba prendido solo cambia la fuerza, así prender o apagar otra cosa no lo rearma.
    local function aplicarCristal()
        if activo and opciones.reflejo and ajustes.cristal > 0 then
            moduloCristal.poner(ajustes.cristal / 100)
        else
            moduloCristal.quitar()
        end
    end

    -- Qué cielo va -------------------------------------------------------------

    local function carasDe(id)
        if opciones.unir then
            -- frente/atrás normales y lados en espejo: los bordes calzan solos,
            -- y arriba/abajo son el color al que se funde la foto
            local frente, lado = asset(id, "frente"), asset(id, "lado")
            local arriba, abajo = asset(id, "arriba"), asset(id, "abajo")
            if frente and lado and arriba and abajo then
                return {
                    SkyboxFt = frente, SkyboxBk = frente,
                    SkyboxLf = lado, SkyboxRt = lado,
                    SkyboxUp = arriba, SkyboxDn = abajo,
                }
            end
        end
        local foto = asset(id, "foto")
        if not foto then return nil end
        local caras = {}
        for _, cara in ipairs(CARAS) do caras[cara] = foto end
        return caras
    end

    local cieloElegido = nil -- id de la foto elegida (nil = el cielo del juego)
    local encendido = true
    local ultimoLeido = nil  -- lo último que vimos en actual.txt
    local actualizarUI = function() end
    local alCambiarCielo = function() end -- (más abajo) el modo combinado de COLORES usa el cielo elegido

    local function aplicar()
        desactivar()
        if not vivo then return end
        if encendido and cieloElegido then
            local caras = carasDe(cieloElegido)
            if caras then
                carasActivas = caras
                activar()
                if opciones.luz then aplicarLuz(cieloElegido) end
            else
                aviso("No pude cargar esa foto (¿la borraste?).")
            end
        end
        aplicarCristal()
        actualizarUI()
        alCambiarCielo()
    end

    local function elegir(id)
        cieloElegido = id
        encendido = true
        ultimoLeido = id or "original"
        escribir(ruta("actual.txt"), ultimoLeido)
        aplicar()
    end

    local function alternar()
        if cieloElegido then
            encendido = not encendido
            aplicar()
        end
    end

    -- Colores de los bloques ----------------------------------------------------
    -- Cada regla dice qué bloques pintar y de qué color:
    --   "color"  = los del mismo material y un color parecido al bloque que elegiste
    --   "grises" = todo lo gris o blanco
    -- Se guardan por juego (GameId), así lo de un juego no se mete en otro.

    local ARCHIVO_COLORES = ruta("colores_" .. tostring(game.GameId) .. ".txt")
    local TOLERANCIAS = { { 0.03, "exacto" }, { 0.10, "parecido" }, { 0.20, "amplio" } }
    local MATERIALES = {
        SmoothPlastic = "Liso", Plastic = "Plástico", Concrete = "Concreto", Brick = "Ladrillo",
        Wood = "Madera", WoodPlanks = "Tablas", Metal = "Metal", DiamondPlate = "Metal",
        Slate = "Pizarra", Granite = "Granito", Marble = "Mármol", Pebble = "Piedras",
        Cobblestone = "Adoquín", Fabric = "Tela", Sand = "Arena", Grass = "Pasto", Ice = "Hielo",
        Glass = "Vidrio", Neon = "Neón", Foil = "Lámina", CorrodedMetal = "Óxido",
    }

    local reglas = {}
    local reglaElegida = nil                 -- la que cambia la rueda (nil = el pincel)
    local pincel = Color3.fromHex("FF69B4")  -- color con el que nacen las reglas nuevas
    local coloresEncendidos = true
    local modoColores = "normal"             -- o "combinado": el morado del cielo con zonas del amarillo
    local intensidadZonas = 100              -- % de las zonas sobre el fondo (100 = nítidas, sin mezclarse)
    local coloresPropios = {}                -- [id del cielo] = { fondo, zona } cambiados con la rueda
    local objetivoMezcla = nil               -- "fondo" o "zona": lo que cambia la rueda (modo combinado)
    local eligiendo = false                  -- esperando un clic en un bloque
    local pintadas = setmetatable({}, { __mode = "k" }) -- bloque -> lo que tenía antes
    local dibujarColores = function() end

    local function guardarColores()
        local lineas = {
            "encendido=" .. (coloresEncendidos and "1" or "0"),
            "pincel=" .. pincel:ToHex(),
            "modo=" .. modoColores,
            "intensidad=" .. intensidadZonas,
        }
        for id, propios in pairs(coloresPropios) do
            if propios.fondo then table.insert(lineas, "fondo_" .. id .. "=" .. propios.fondo:ToHex()) end
            if propios.zona then table.insert(lineas, "zona_" .. id .. "=" .. propios.zona:ToHex()) end
        end
        for _, r in ipairs(reglas) do
            table.insert(lineas, table.concat({
                r.tipo, r.base and r.base:ToHex() or "-", r.material or "-",
                tostring(r.nivel), r.color:ToHex(), r.activa and "1" or "0",
            }, "|"))
        end
        escribir(ARCHIVO_COLORES, table.concat(lineas, "\n"))
    end

    local function cargarColores()
        local texto = leer(ARCHIVO_COLORES)
        if not texto then return end
        for linea in texto:gmatch("[^\r\n]+") do
            -- ("mezcla=" era la intensidad de la mezcla vieja: ya no se lee, las zonas van nítidas)
            local clave, valor = linea:match("^([%w_]+)=(.+)$")
            local cual, id = (clave or ""):match("^(%a+)_(c%d+)$")
            if clave == "encendido" then
                coloresEncendidos = valor == "1"
            elseif clave == "pincel" then
                pcall(function() pincel = Color3.fromHex(valor) end)
            elseif clave == "modo" then
                modoColores = valor == "combinado" and "combinado" or "normal"
            elseif clave == "intensidad" then
                intensidadZonas = math.clamp(tonumber(valor) or 100, 10, 100)
            elseif (cual == "fondo" or cual == "zona") and id then
                pcall(function()
                    coloresPropios[id] = coloresPropios[id] or {}
                    coloresPropios[id][cual] = Color3.fromHex(valor)
                end)
            else
                local p = string.split(linea, "|")
                if #p == 6 and (p[1] == "color" or p[1] == "grises") then
                    local ok, r = pcall(function()
                        return {
                            tipo = p[1],
                            base = p[1] == "color" and Color3.fromHex(p[2]) or nil,
                            material = p[1] == "color" and p[3] or nil,
                            nivel = math.clamp(tonumber(p[4]) or 2, 1, 3),
                            color = Color3.fromHex(p[5]),
                            activa = p[6] == "1",
                        }
                    end)
                    if ok then table.insert(reglas, r) end
                end
            end
        end
    end

    local function distancia(a, b)
        local dr, dg, db = a.R - b.R, a.G - b.G, a.B - b.B
        return math.sqrt(dr * dr + dg * dg + db * db) / 1.7320508
    end

    local function esGris(c)
        local _, s, v = c:ToHSV()
        return s <= 0.12 and v >= 0.15
    end

    local function reglaPara(parte, colorOriginal)
        for _, r in ipairs(reglas) do
            if r.activa then
                if r.tipo == "grises" then
                    if esGris(colorOriginal) then return r end
                elseif materialDe(parte) == r.material
                    and distancia(colorOriginal, r.base) <= TOLERANCIAS[r.nivel][1] then
                    return r
                end
            end
        end
        return nil
    end

    local function esPersonaje(parte)
        local modelo = parte:FindFirstAncestorOfClass("Model")
        while modelo do
            if modelo:FindFirstChildOfClass("Humanoid") then return true end
            modelo = modelo:FindFirstAncestorOfClass("Model")
        end
        return false
    end

    -- el arma en primera persona vive en la cámara; los personajes no se pintan
    local function excluida(parte)
        local camara = workspace.CurrentCamera
        return parte:IsA("Terrain") or parte.Transparency >= 0.95
            or (camara ~= nil and parte:IsDescendantOf(camara)) or esPersonaje(parte)
    end

    -- Modo combinado: el bloque se pinta del morado del cielo (el fondo) y lleva en sus caras las
    -- zonas: una textura blanca con transparencia (<id>_zonas.png, la arma la app: 35 % del dibujo,
    -- con bordes nítidos) teñida del amarillo. Se repite cada MEZCLA studs y arranca según dónde está
    -- el bloque, así el dibujo sigue de un bloque al de al lado.
    local MEZCLA = 24
    local MAX_MEZCLAS = 4000 -- tope de caras con mezcla, para no cargar de más el juego
    local mezclasPuestas = 0
    local CARAS_BLOQUE = {
        Enum.NormalId.Top, Enum.NormalId.Bottom, Enum.NormalId.Front,
        Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right,
    }

    local function mezclaActual()
        if modoColores ~= "combinado" or not cieloElegido then return nil end
        return asset(cieloElegido, "zonas")
    end

    -- Los dos colores del modo combinado: los que eligió con la rueda o, si no, los que sacó la app
    -- del cielo (<id>_zonas.txt: primero el fondo, el morado que más hay; después el amarillo de la luz)
    local zonasDeCielo = {}
    local function zonasDe(id)
        if not zonasDeCielo[id] then
            local hexes = {}
            for hex in (leer(ruta("cielos", id, id .. "_zonas.txt")) or ""):gmatch("#(%x%x%x%x%x%x)") do
                table.insert(hexes, hex)
            end
            local okFondo, fondo = pcall(Color3.fromHex, hexes[1] or "")
            local okZona, zona = pcall(Color3.fromHex, hexes[2] or "")
            zonasDeCielo[id] = {
                fondo = (hexes[1] and okFondo) and fondo or coloresDe(id)[1] or Color3.fromHex("AF6B9B"),
                zona = (hexes[2] and okZona) and zona or Color3.fromHex("F5D184"),
            }
        end
        local propios = coloresPropios[id] or {}
        return propios.fondo or zonasDeCielo[id].fondo, propios.zona or zonasDeCielo[id].zona
    end

    local function quitarMezcla(datos)
        if not datos.mezcla then return end
        for _, t in ipairs(datos.mezcla) do pcall(function() t:Destroy() end) end
        mezclasPuestas = mezclasPuestas - #datos.mezcla
        datos.mezcla, datos.mezclaDe = nil, nil
    end

    local function ponerMezcla(parte, datos, imagen, zona)
        if datos.mezclaDe == imagen then
            for _, t in ipairs(datos.mezcla) do
                t.Color3 = zona
                t.Transparency = 1 - intensidadZonas / 100
            end
            return
        end
        quitarMezcla(datos)
        datos.mezcla, datos.mezclaDe = {}, imagen
        local s, p = parte.Size, parte.Position
        for _, cara in ipairs(CARAS_BLOQUE) do
            -- las medidas de la cara y dónde empieza en el mundo
            local ancho, alto, u0, v0
            if cara == Enum.NormalId.Top or cara == Enum.NormalId.Bottom then
                ancho, alto, u0, v0 = s.X, s.Z, p.X - s.X / 2, p.Z - s.Z / 2
            elseif cara == Enum.NormalId.Front or cara == Enum.NormalId.Back then
                ancho, alto, u0, v0 = s.X, s.Y, p.X - s.X / 2, p.Y - s.Y / 2
            else
                ancho, alto, u0, v0 = s.Z, s.Y, p.Z - s.Z / 2, p.Y - s.Y / 2
            end
            if ancho * alto >= 4 and mezclasPuestas < MAX_MEZCLAS then
                local t = Instance.new("Texture")
                t.Name = "CieloMezcla"
                t.Texture = imagen
                t.Face = cara
                t.StudsPerTileU, t.StudsPerTileV = MEZCLA, MEZCLA
                t.OffsetStudsU, t.OffsetStudsV = u0 % MEZCLA, v0 % MEZCLA
                t.ZIndex = 5
                t.Color3 = zona -- la textura es blanca: el tinte le da el amarillo
                t.Transparency = 1 - intensidadZonas / 100
                t.Parent = parte
                table.insert(datos.mezcla, t)
                mezclasPuestas = mezclasPuestas + 1
            end
        end
    end

    local function pintar(parte, regla)
        local datos = pintadas[parte]
        if not datos then
            datos = { color = parte.Color, texturas = {} }
            pintadas[parte] = datos
            -- los dibujos repetidos (Texture) tapan el color del bloque: también se tiñen
            for _, hijo in ipairs(parte:GetChildren()) do
                if hijo:IsA("Texture") and hijo.Name ~= "CieloMezcla" then datos.texturas[hijo] = hijo.Color3 end
            end
        end
        datos.regla = regla
        local imagen = mezclaActual()
        -- el color del bloque: el de la regla, o en el modo combinado el fondo (morado) con las zonas
        local base, zona = regla.color, nil
        if imagen then base, zona = zonasDe(cieloElegido) end
        parte.Color = base
        for textura in pairs(datos.texturas) do
            textura.Color3 = base
        end
        if imagen then
            ponerMezcla(parte, datos, imagen, zona)
        else
            quitarMezcla(datos)
        end
    end

    local function restaurar(parte)
        local datos = pintadas[parte]
        if not datos then return end
        pintadas[parte] = nil
        quitarMezcla(datos)
        pcall(function()
            parte.Color = datos.color
            for textura, color in pairs(datos.texturas) do textura.Color3 = color end
        end)
    end

    local function evaluar(parte)
        local datos = pintadas[parte]
        local regla = nil
        if coloresEncendidos and #reglas > 0 then
            regla = reglaPara(parte, datos and datos.color or parte.Color)
            if regla and excluida(parte) then regla = nil end
        end
        if regla then
            pintar(parte, regla)
        elseif datos then
            restaurar(parte)
        end
    end

    local function aplicarColores()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then evaluar(obj) end
        end
    end

    -- solo cambió el color de una regla: basta con repintar lo que ya tiene
    local function recolorear(regla)
        for parte, datos in pairs(pintadas) do
            if datos.regla == regla then pintar(parte, regla) end
        end
    end

    -- cambió el fondo o las zonas con la rueda: se repinta todo lo pintado, a lo más cada 0,05 s
    -- (mientras arrastra llegan muchos cambios seguidos)
    local repintePendiente = false
    local function repintarMezcla()
        if repintePendiente then return end
        repintePendiente = true
        task.delay(0.05, function()
            repintePendiente = false
            if not vivo then return end
            for parte, datos in pairs(pintadas) do
                if datos.regla then pcall(pintar, parte, datos.regla) end
            end
        end)
    end

    local function restaurarTodo()
        local lista = {}
        for parte in pairs(pintadas) do table.insert(lista, parte) end
        for _, parte in ipairs(lista) do restaurar(parte) end
    end

    local function alternarColores()
        coloresEncendidos = not coloresEncendidos
        aplicarColores()
        guardarColores()
        dibujarColores()
    end

    local function agregarReglaDesde(parte)
        local datos = pintadas[parte]
        local base = datos and datos.color or parte.Color
        for _, r in ipairs(reglas) do
            if r.tipo == "color" and r.material == materialDe(parte)
                and distancia(base, r.base) <= TOLERANCIAS[r.nivel][1] then
                reglaElegida = r
                aviso("Esos bloques ya estaban: los marqué para cambiarles el color.")
                return
            end
        end
        local regla = {
            tipo = "color", base = base, material = materialDe(parte),
            nivel = 2, color = pincel, activa = true,
        }
        table.insert(reglas, regla)
        reglaElegida = regla
        aplicarColores()
        guardarColores()
    end

    local function agregarGrises()
        for _, r in ipairs(reglas) do
            if r.tipo == "grises" then
                reglaElegida = r
                return
            end
        end
        local regla = { tipo = "grises", nivel = 2, color = pincel, activa = true }
        table.insert(reglas, regla)
        reglaElegida = regla
        aplicarColores()
        guardarColores()
    end

    -- dispara un rayo desde el mouse y toma el bloque que toque
    local function elegirConClic(posicion)
        eligiendo = false
        local camara = workspace.CurrentCamera
        local rayo = camara:ViewportPointToRay(posicion.X, posicion.Y)
        local fuera = { camara }
        if jugador.Character then table.insert(fuera, jugador.Character) end

        local parte = nil
        for _ = 1, 12 do -- se salta paredes invisibles
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = fuera
            local resultado = workspace:Raycast(rayo.Origin, rayo.Direction * 3000, params)
            if not resultado then break end
            if resultado.Instance.Transparency < 0.9 then
                parte = resultado.Instance
                break
            end
            table.insert(fuera, resultado.Instance)
        end

        if not parte or parte:IsA("Terrain") then
            aviso("Ahí no hay ningún bloque.")
        elseif esPersonaje(parte) then
            aviso("Eso es un personaje; elige un bloque del mapa.")
        else
            agregarReglaDesde(parte)
        end
        dibujarColores()
    end

    -- Página CIELO ---------------------------------------------------------------
    -- arriba el cielo puesto en grande, el botón de prender/apagar y las opciones;
    -- abajo tus fotos

    local vista = crear("ImageLabel", {
        Name = "Vista", Size = UDim2.new(1, 0, 0, 150), BackgroundColor3 = C.panel, BorderSizePixel = 0,
        ScaleType = Enum.ScaleType.Crop, Image = "", Parent = paginaCielo,
    }, { esquina(14) })
    local vistaSombra = sombraAbajo(vista, 14)
    local vistaNombre = crear("TextLabel", {
        Text = "", Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = C.texto,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        BackgroundTransparency = 1, Position = UDim2.new(0, 16, 1, -36), Size = UDim2.new(1, -32, 0, 24),
        Parent = vista,
    })
    local vistaVacia = crear("TextLabel", {
        Text = "Cielo original del juego", Font = Enum.Font.GothamMedium, TextSize = 15,
        TextColor3 = C.tenue, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = vista,
    })

    local botonCielo = crear("TextButton", {
        Name = "Encender", Position = UDim2.fromOffset(0, 162), Size = UDim2.new(1, 0, 0, 42),
        Font = Enum.Font.GothamBold, TextSize = 14, Text = "", AutoButtonColor = false,
        BackgroundColor3 = C.acento, Parent = paginaCielo,
    }, { esquina(10) })

    local zonaOpciones = crear("Frame", {
        Position = UDim2.fromOffset(0, 214), Size = UDim2.new(1, 0, 0, 76), BackgroundTransparency = 1,
        Parent = paginaCielo,
    }, {
        crear("UIGridLayout", {
            CellSize = UDim2.new(1 / 3, -6, 0, 34), CellPadding = UDim2.fromOffset(8, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    })

    -- cuánto refleja el cristal y cuánto se tiñe la luz (se aplica al soltar la barrita; el cristal
    -- solo cambia su fuerza, no se rearma)
    local pintarCristal = barrita(paginaCielo, UDim2.fromOffset(0, 300), UDim2.new(0.5, -10, 0, 28), "Cristal (reflejo de lejos)", 0, 100,
        ajustes.cristal, function(v) ajustes.cristal = v end, function()
            guardarAjustes()
            aplicarCristal()
            actualizarUI()
        end)
    local pintarLuz = barrita(paginaCielo, UDim2.new(0.5, 10, 0, 300), UDim2.new(0.5, -10, 0, 28), "Luz del cielo", 0, 60,
        ajustes.luz, function(v) ajustes.luz = v end, function()
            guardarAjustes()
            aplicar()
        end)

    -- quitar o poner el reflejo de una vez (lo mismo que el chip "Reflejo de cristal") y dejar lo
    -- del cielo como estaba el juego
    local filaCielo = crear("Frame", {
        Position = UDim2.fromOffset(0, 340), Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1,
        Parent = paginaCielo,
    }, {
        crear("UIGridLayout", {
            CellSize = UDim2.new(0.5, -5, 1, 0), CellPadding = UDim2.fromOffset(10, 0),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    })
    local botonReflejo = crear("TextButton", {
        LayoutOrder = 1, Font = Enum.Font.GothamBold, TextSize = 12, Text = "", AutoButtonColor = false,
        BackgroundColor3 = C.panel, TextColor3 = C.texto, Parent = filaCielo,
    }, { esquina(9), trazo(C.acento, 1, 0.5) })
    local botonCieloComoEstaba = crear("TextButton", {
        LayoutOrder = 2, Font = Enum.Font.GothamBold, TextSize = 12, Text = "🔄  Cielo como estaba",
        AutoButtonColor = false, BackgroundColor3 = C.panel, TextColor3 = C.texto, Parent = filaCielo,
    }, { esquina(9), trazo(Color3.fromRGB(255, 120, 140), 1, 0.4) })

    botonReflejo.MouseButton1Click:Connect(function()
        if opciones.reflejo and ajustes.cristal > 0 then
            opciones.reflejo = false
        else
            opciones.reflejo = true
            if ajustes.cristal <= 0 then
                ajustes.cristal = AJUSTES_DE_ENTRADA.cristal
                pintarCristal(ajustes.cristal)
                guardarAjustes()
            end
        end
        guardarOpciones()
        aplicarCristal()
        actualizarUI()
    end)

    -- el cielo del juego, y las opciones y barritas como vienen (las fotos no se tocan)
    local function restablecerCielo()
        for clave, valor in pairs(OPCIONES_DE_ENTRADA) do opciones[clave] = valor end
        guardarOpciones()
        for clave, valor in pairs(AJUSTES_DE_ENTRADA) do ajustes[clave] = valor end
        guardarAjustes()
        pintarCristal(ajustes.cristal)
        pintarLuz(ajustes.luz)
        elegir(nil) -- con el cielo del juego se van también el cristal, la luz y la niebla forzada
    end
    conConfirmacion(botonCieloComoEstaba, function()
        restablecerCielo()
        aviso("Cielo como estaba: el del juego, sin reflejo ni luz del cielo. Tus fotos siguen ahí.")
    end)

    local tituloGaleria = crear("TextLabel", {
        Position = UDim2.fromOffset(0, 382), Size = UDim2.new(1, 0, 0, 16),
        Text = "TUS FOTOS", Font = Enum.Font.GothamBold, TextSize = 12,
        TextColor3 = C.tenue, TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1, Parent = paginaCielo,
    })

    local galeria = crear("ScrollingFrame", {
        Name = "Galeria", Position = UDim2.fromOffset(0, 404), Size = UDim2.new(1, 0, 1, -430),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 5, ScrollBarImageColor3 = C.acento,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = paginaCielo,
    }, {
        crear("UIPadding", {
            PaddingTop = UDim.new(0, 3), PaddingLeft = UDim.new(0, 3),
            PaddingRight = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3),
        }),
        crear("UIGridLayout", {
            CellSize = UDim2.new(0.25, -8, 0, 104), CellPadding = UDim2.fromOffset(10, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    })

    crear("TextLabel", {
        AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 18),
        Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C.tenue,
        Text = "Agrega fotos con la app Cielo Roblox del PC (arrastrar o abrir)  ·  F8 prende/apaga el cielo",
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        BackgroundTransparency = 1, Parent = paginaCielo,
    })

    -- tarjetas de la galería
    local tarjetas = {}

    local function marcarTarjetas()
        local elegido = cieloElegido or ""
        for id, t in pairs(tarjetas) do
            t.trazo.Transparency = (id == elegido) and 0 or 1
        end
    end

    local function nuevaTarjeta(id, orden)
        local boton = crear("ImageButton", {
            Name = id ~= "" and id or "Original", LayoutOrder = orden,
            BackgroundColor3 = C.panel, BorderSizePixel = 0, AutoButtonColor = false,
            ScaleType = Enum.ScaleType.Crop, Image = "", Parent = galeria,
        }, { esquina(10) })
        local borde = trazo(C.acento, 2, 1)
        borde.Parent = boton

        if id == "" then
            crear("TextLabel", {
                Text = "Original\ndel juego", Font = Enum.Font.GothamBold, TextSize = 13,
                TextColor3 = C.tenue, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
                Parent = boton,
            })
        else
            boton.Image = asset(id, "mini") or ""
            sombraAbajo(boton, 10)
            crear("TextLabel", {
                Text = nombre(id), Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = C.texto,
                TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
                BackgroundTransparency = 1, Position = UDim2.new(0, 8, 1, -22),
                Size = UDim2.new(1, -16, 0, 16), Parent = boton,
            })
        end

        boton.MouseEnter:Connect(function()
            if id ~= (cieloElegido or "") then borde.Transparency = 0.5 end
        end)
        boton.MouseLeave:Connect(marcarTarjetas)
        boton.MouseButton1Click:Connect(function()
            elegir(id ~= "" and id or nil)
        end)

        tarjetas[id] = { boton = boton, trazo = borde }
    end

    local function reconstruirGaleria(lista)
        if not vivo then return end
        for _, t in pairs(tarjetas) do t.boton:Destroy() end
        tarjetas = {}
        nuevaTarjeta("", 0)
        for i, id in ipairs(lista) do
            nuevaTarjeta(id, i)
        end
        tituloGaleria.Text = #lista > 0
            and ("TUS FOTOS  (" .. #lista .. ")")
            or "TUS FOTOS  (todavía ninguna)"
        marcarTarjetas()
    end

    -- opciones (botones que se prenden y apagan)
    local chips = {}
    local function chip(clave, texto, orden)
        local boton = crear("TextButton", {
            LayoutOrder = orden, Text = texto, Font = Enum.Font.GothamMedium, TextSize = 12,
            AutoButtonColor = false, Parent = zonaOpciones,
        }, { esquina(9), trazo(C.acento, 1, 0.5) })
        boton.MouseButton1Click:Connect(function()
            opciones[clave] = not opciones[clave]
            guardarOpciones()
            aplicar()
        end)
        chips[clave] = boton
    end
    chip("unir", "Unir bordes", 1)
    chip("sinSol", "Sin sol ni luna", 2)
    chip("sinNiebla", "Sin niebla", 3)
    chip("sinNubes", "Sin nubes", 4)
    chip("reflejo", "Reflejo de cristal", 5)
    chip("luz", "Luz del cielo", 6)

    actualizarUI = function()
        if not vivo then return end

        if cieloElegido then
            vista.Image = asset(cieloElegido, "foto") or asset(cieloElegido, "mini") or ""
            vista.ImageTransparency = encendido and 0 or 0.6
            vistaNombre.Text = nombre(cieloElegido) .. (encendido and "" or "  (apagado)")
            vistaVacia.Visible = false
            vistaSombra.Visible = true
        else
            vista.Image = ""
            vistaNombre.Text = ""
            vistaVacia.Visible = true
            vistaSombra.Visible = false
        end

        if not cieloElegido then
            botonCielo.Text = "ELIGE UNA FOTO ABAJO"
            botonCielo.BackgroundColor3 = C.panel2
            botonCielo.TextColor3 = C.tenue
        elseif encendido then
            botonCielo.Text = "CIELO ENCENDIDO   ·   F8"
            botonCielo.BackgroundColor3 = C.acento
            botonCielo.TextColor3 = C.oscuro
        else
            botonCielo.Text = "CIELO APAGADO   ·   F8"
            botonCielo.BackgroundColor3 = C.panel2
            botonCielo.TextColor3 = C.texto
        end

        for clave, boton in pairs(chips) do
            local on = opciones[clave]
            boton.BackgroundColor3 = on and C.acento or C.panel
            boton.TextColor3 = on and C.oscuro or C.tenue
        end
        botonReflejo.Text = (opciones.reflejo and ajustes.cristal > 0) and "×  Quitar reflejo" or "+  Poner reflejo"

        marcarTarjetas()
        avisarEstado()
    end

    botonCielo.MouseButton1Click:Connect(alternar)

    -- Página COLORES -------------------------------------------------------------
    -- a la izquierda la rueda y el color; a la derecha qué se pinta

    local hsv = { h = 0, s = 0, v = 1 } -- lo que marca la rueda

    -- en el modo combinado, con "Fondo" o "Zonas" marcado, la rueda cambia ese color
    local function editandoMezcla()
        return objetivoMezcla ~= nil and modoColores == "combinado" and cieloElegido ~= nil
    end

    local function colorActual()
        if editandoMezcla() then
            local fondo, zona = zonasDe(cieloElegido)
            return objetivoMezcla == "fondo" and fondo or zona
        end
        return reglaElegida and reglaElegida.color or pincel
    end

    local izquierda = crear("Frame", {
        Size = UDim2.new(0, 236, 1, 0), BackgroundTransparency = 1, Parent = paginaColores,
    })
    local derecha = crear("Frame", {
        Position = UDim2.fromOffset(254, 0), Size = UDim2.new(1, -254, 1, 0),
        BackgroundTransparency = 1, Parent = paginaColores,
    })

    local botonColores = crear("TextButton", {
        Name = "Encender", Size = UDim2.new(1, 0, 0, 42),
        Font = Enum.Font.GothamBold, TextSize = 13, Text = "", AutoButtonColor = false,
        BackgroundColor3 = C.acento, Parent = izquierda,
    }, { esquina(10) })

    local rueda = crear("ImageButton", {
        Name = "Rueda", Position = UDim2.fromOffset(10, 56), Size = UDim2.fromOffset(216, 216),
        BackgroundTransparency = 1, AutoButtonColor = false, Image = "", Parent = izquierda,
    })
    pcall(function() rueda.Image = cargarAsset(ruta("rueda.png")) end)
    local marcador = crear("Frame", {
        Name = "Marcador", AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(18, 18),
        Position = UDim2.fromScale(0.5, 0.5), Parent = rueda,
    }, {
        crear("UICorner", { CornerRadius = UDim.new(1, 0) }),
        trazo(Color3.new(1, 1, 1), 2, 0),
    })

    local barraBrillo = crear("TextButton", {
        Name = "Brillo", Position = UDim2.fromOffset(0, 286), Size = UDim2.new(1, 0, 0, 16), Text = "",
        AutoButtonColor = false, BackgroundColor3 = Color3.new(1, 1, 1), Parent = izquierda,
    }, { esquina(8) })
    local gradienteBrillo = crear("UIGradient", { Parent = barraBrillo })
    local perilla = crear("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(1, 0.5),
        Size = UDim2.fromOffset(20, 20), BackgroundColor3 = C.texto, Parent = barraBrillo,
    }, {
        crear("UICorner", { CornerRadius = UDim.new(1, 0) }),
        trazo(C.oscuro, 2, 0),
    })

    local muestra = crear("Frame", {
        Name = "Muestra", Position = UDim2.fromOffset(0, 316), Size = UDim2.fromOffset(52, 52), Parent = izquierda,
    }, { esquina(10), trazo(C.acento, 1, 0.6) })
    local cajaHex = crear("TextBox", {
        Position = UDim2.fromOffset(62, 316), Size = UDim2.new(1, -62, 0, 30),
        BackgroundColor3 = C.panel, TextColor3 = C.durazno, PlaceholderText = "#FF69B4",
        Font = Enum.Font.Code, TextSize = 15, Text = "", ClearTextOnFocus = false, Parent = izquierda,
    }, { esquina(8) })
    crear("TextLabel", {
        Position = UDim2.fromOffset(62, 350), Size = UDim2.new(1, -62, 0, 16),
        Text = "escribe un color o toca uno", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.tenue,
        TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Parent = izquierda,
    })
    local paleta = crear("Frame", {
        Position = UDim2.fromOffset(0, 380), Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1, Parent = izquierda,
    }, {
        crear("UIGridLayout", {
            CellSize = UDim2.fromOffset(25, 25), CellPadding = UDim2.fromOffset(4, 4),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    })

    local tituloReglas = crear("TextLabel", {
        Position = UDim2.fromOffset(0, 7), Size = UDim2.new(1, -260, 0, 16), Text = "QUÉ SE PINTA",
        Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.tenue, TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1, Parent = derecha,
    })
    -- NORMAL: cada regla con su color. COMBINADO: la mezcla líquida de los colores del cielo
    local selectorModo = crear("Frame", {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(212, 30),
        BackgroundColor3 = C.panel, Parent = derecha,
    }, { esquina(9) })
    local function botonModo(texto, x)
        return crear("TextButton", {
            Position = UDim2.new(x, x == 0 and 3 or 1, 0, 3), Size = UDim2.new(0.5, -4, 1, -6),
            Font = Enum.Font.GothamBold, TextSize = 11, Text = texto, AutoButtonColor = false,
            BackgroundColor3 = C.panel2, Parent = selectorModo,
        }, { esquina(7) })
    end
    local botonNormal = botonModo("NORMAL", 0)
    local botonCombinado = botonModo("COMBINADO", 0.5)
    local muestraMezcla = crear("ImageLabel", { -- las zonas del cielo elegido, al lado del selector
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -218, 0, 0), Size = UDim2.fromOffset(30, 30),
        ScaleType = Enum.ScaleType.Crop, BackgroundColor3 = C.oscuro, Image = "", Visible = false, Parent = derecha,
    }, { esquina(8) })
    -- los dos colores (se tocan para cambiarlos con la rueda) y cuánto se notan las zonas
    local filaMezcla = crear("Frame", {
        Position = UDim2.fromOffset(0, 38), Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1,
        Visible = false, Parent = derecha,
    })
    local function botonMuestra(texto, x)
        local boton = crear("TextButton", {
            Position = UDim2.fromOffset(x, 0), Size = UDim2.fromOffset(66, 28), Text = texto,
            Font = Enum.Font.GothamBold, TextSize = 11, AutoButtonColor = false, Parent = filaMezcla,
        }, { esquina(8) })
        local borde = trazo(C.texto, 2, 1)
        borde.Parent = boton
        return boton, borde
    end
    local botonFondo, bordeFondo = botonMuestra("Fondo", 0)
    local botonZona, bordeZona = botonMuestra("Zonas", 72)
    -- los dos colores de vuelta a los que sacó la app del cielo
    local botonColoresDelCielo = crear("TextButton", {
        Position = UDim2.fromOffset(144, 0), Size = UDim2.fromOffset(28, 28), Text = "🔄",
        Font = Enum.Font.GothamBold, TextSize = 15, AutoButtonColor = false, BackgroundColor3 = C.panel2,
        TextColor3 = C.texto, Parent = filaMezcla,
    }, { esquina(8) })
    local pintarBarritaMezcla = barrita(filaMezcla, UDim2.fromOffset(182, 0), UDim2.new(1, -182, 0, 28), "Intensidad", 10, 100,
        intensidadZonas, function(v) intensidadZonas = v end, function()
            guardarColores()
            for _, datos in pairs(pintadas) do
                for _, t in ipairs(datos.mezcla or {}) do t.Transparency = 1 - intensidadZonas / 100 end
            end
        end)

    -- las muestras con sus colores (texto oscuro o claro según el color) y la marcada con borde
    local function pintarMuestras()
        if not cieloElegido then return end
        local fondo, zona = zonasDe(cieloElegido)
        for _, par in ipairs({ { botonFondo, bordeFondo, fondo, "fondo" }, { botonZona, bordeZona, zona, "zona" } }) do
            local boton, borde, color, cual = par[1], par[2], par[3], par[4]
            local luminancia = 0.299 * color.R + 0.587 * color.G + 0.114 * color.B
            boton.BackgroundColor3 = color
            boton.TextColor3 = luminancia > 0.55 and C.oscuro or C.texto
            borde.Transparency = objetivoMezcla == cual and 0 or 1
        end
        muestraMezcla.BackgroundColor3 = fondo
        muestraMezcla.ImageColor3 = zona
    end
    local listaReglas = crear("ScrollingFrame", {
        Name = "Reglas", Position = UDim2.fromOffset(0, 38), Size = UDim2.new(1, 0, 1, -144),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 5, ScrollBarImageColor3 = C.acento,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = derecha,
    }, {
        crear("UIPadding", {
            PaddingTop = UDim.new(0, 2), PaddingLeft = UDim.new(0, 2),
            PaddingRight = UDim.new(0, 2), PaddingBottom = UDim.new(0, 2),
        }),
        crear("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5) }),
    })
    local reglasVacio = crear("TextLabel", {
        LayoutOrder = 0, Size = UDim2.new(1, -4, 0, 60), BackgroundTransparency = 1,
        Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C.tenue, TextWrapped = true,
        Text = "Nada todavía. Elige unos bloques con los botones de abajo.", Parent = listaReglas,
    })

    local filaBotones = crear("Frame", {
        AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, -56), Size = UDim2.new(1, 0, 0, 38),
        BackgroundTransparency = 1, Parent = derecha,
    }, {
        crear("UIGridLayout", {
            CellSize = UDim2.new(1 / 3, -6, 1, 0), CellPadding = UDim2.fromOffset(8, 0),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    })
    local function botonAccion(texto, orden)
        return crear("TextButton", {
            LayoutOrder = orden, Text = texto, Font = Enum.Font.GothamBold, TextSize = 12, TextWrapped = true,
            AutoButtonColor = false, BackgroundColor3 = C.panel, TextColor3 = C.texto, Parent = filaBotones,
        }, { esquina(9), trazo(C.acento, 1, 0.5) })
    end
    local botonElegir = botonAccion("+ Elegir con clic", 1)
    local botonGrises = botonAccion("+ Todo lo gris", 2)
    local botonColoresComoEstaba = botonAccion("🔄  Como estaban", 3)
    botonColoresComoEstaba:FindFirstChildOfClass("UIStroke").Color = Color3.fromRGB(255, 120, 140)

    crear("TextLabel", {
        AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 46),
        Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.tenue,
        Text = "Elige con clic y toca un bloque: se pintan todos los iguales. La rueda pinta lo que "
            .. "esté marcado en la lista (clic en una fila para marcarla).  F6 prende/apaga los colores.",
        TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
        BackgroundTransparency = 1, Parent = derecha,
    })

    local function dibujarSelector()
        local c = colorActual()
        local angulo = hsv.h * 2 * math.pi
        marcador.Position = UDim2.fromScale(
            0.5 + math.cos(angulo) * hsv.s * 0.5,
            0.5 - math.sin(angulo) * hsv.s * 0.5
        )
        marcador.BackgroundColor3 = c
        rueda.ImageColor3 = Color3.fromHSV(0, 0, 0.35 + 0.65 * hsv.v)
        gradienteBrillo.Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.fromHSV(hsv.h, hsv.s, 1))
        perilla.Position = UDim2.fromScale(hsv.v, 0.5)
        muestra.BackgroundColor3 = c
        if not cajaHex:IsFocused() then
            cajaHex.Text = "#" .. c:ToHex():upper()
        end
    end

    -- lleva la rueda al color actual (al cambiar de fila, al cargar...)
    local function sincronizarSelector()
        local h, s, v = colorActual():ToHSV()
        if s > 0.001 then hsv.h = h end
        hsv.s, hsv.v = s, v
        dibujarSelector()
    end

    local nuevosDeFila = {} -- regla -> cuadrito del color nuevo en su fila

    local function ponerColor(c, guardar)
        if editandoMezcla() then
            coloresPropios[cieloElegido] = coloresPropios[cieloElegido] or {}
            coloresPropios[cieloElegido][objetivoMezcla] = c
            pintarMuestras()
            repintarMezcla()
        elseif reglaElegida then
            reglaElegida.color = c
            recolorear(reglaElegida)
            local cuadro = nuevosDeFila[reglaElegida]
            if cuadro then cuadro.BackgroundColor3 = c end
        else
            pincel = c
        end
        dibujarSelector()
        if guardar then guardarColores() end
    end

    local function ponerColorExterno(c)
        ponerColor(c, true)
        sincronizarSelector()
    end

    local filas = {}

    local function reconstruirReglas()
        for _, fila in ipairs(filas) do fila:Destroy() end
        filas = {}
        nuevosDeFila = {}
        reglasVacio.Visible = #reglas == 0

        for i, r in ipairs(reglas) do
            local fila = crear("TextButton", {
                LayoutOrder = i, Text = "", AutoButtonColor = false,
                Size = UDim2.new(1, -4, 0, 36), BackgroundColor3 = C.panel, Parent = listaReglas,
            }, { esquina(9), trazo(C.acento, 1.5, r == reglaElegida and 0 or 1) })

            crear("Frame", {
                Position = UDim2.new(0, 10, 0.5, -9), Size = UDim2.fromOffset(18, 18),
                BackgroundColor3 = r.base or Color3.fromRGB(150, 150, 150), Parent = fila,
            }, { esquina(5) })
            crear("TextLabel", {
                Text = "›", Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = C.tenue,
                BackgroundTransparency = 1, Position = UDim2.fromOffset(30, 0),
                Size = UDim2.new(0, 12, 1, 0), Parent = fila,
            })
            nuevosDeFila[r] = crear("Frame", {
                Position = UDim2.new(0, 44, 0.5, -9), Size = UDim2.fromOffset(18, 18),
                BackgroundColor3 = r.color, Parent = fila,
            }, { esquina(5), trazo(C.texto, 1, 0.7) })

            local titulo = r.tipo == "grises" and "Todo lo gris"
                or ((MATERIALES[r.material] or r.material) .. " #" .. r.base:ToHex():upper())
            crear("TextLabel", {
                Text = titulo, Font = Enum.Font.GothamMedium, TextSize = 12,
                TextColor3 = r.activa and C.texto or C.tenue,
                TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
                BackgroundTransparency = 1, Position = UDim2.fromOffset(70, 0),
                Size = UDim2.new(1, -196, 1, 0), Parent = fila,
            })

            local function botonFila(texto, x, ancho)
                return crear("TextButton", {
                    Text = texto, Font = Enum.Font.GothamBold, TextSize = 10, AutoButtonColor = false,
                    BackgroundColor3 = C.panel2, TextColor3 = C.tenue,
                    Position = UDim2.new(1, x, 0.5, -11), Size = UDim2.fromOffset(ancho, 22), Parent = fila,
                }, { esquina(6) })
            end

            if r.tipo == "color" then
                local botonTolerancia = botonFila(TOLERANCIAS[r.nivel][2], -122, 58)
                botonTolerancia.MouseButton1Click:Connect(function()
                    r.nivel = r.nivel % #TOLERANCIAS + 1
                    aplicarColores()
                    guardarColores()
                    reconstruirReglas()
                end)
            end

            local botonActiva = botonFila(r.activa and "ON" or "OFF", -60, 30)
            if r.activa then
                botonActiva.BackgroundColor3 = C.acento
                botonActiva.TextColor3 = C.oscuro
            end
            botonActiva.MouseButton1Click:Connect(function()
                r.activa = not r.activa
                aplicarColores()
                guardarColores()
                reconstruirReglas()
            end)

            local botonBorrar = botonFila("×", -26, 22)
            botonBorrar.TextSize = 14
            botonBorrar.MouseButton1Click:Connect(function()
                table.remove(reglas, table.find(reglas, r))
                if reglaElegida == r then reglaElegida = nil end
                aplicarColores()
                guardarColores()
                reconstruirReglas()
                sincronizarSelector()
            end)

            fila.MouseButton1Click:Connect(function()
                reglaElegida = (reglaElegida ~= r) and r or nil
                objetivoMezcla = nil
                pintarMuestras()
                reconstruirReglas()
                sincronizarSelector()
            end)

            table.insert(filas, fila)
        end

        tituloReglas.Text = #reglas > 0 and ("QUÉ SE PINTA  (" .. #reglas .. ")") or "QUÉ SE PINTA"
    end

    dibujarColores = function()
        if not vivo then return end
        if coloresEncendidos then
            botonColores.Text = "COLORES ENCENDIDOS  ·  F6"
            botonColores.BackgroundColor3 = C.acento
            botonColores.TextColor3 = C.oscuro
        else
            botonColores.Text = "COLORES APAGADOS  ·  F6"
            botonColores.BackgroundColor3 = C.panel2
            botonColores.TextColor3 = C.texto
        end
        if eligiendo then
            botonElegir.Text = "Toca un bloque…"
            botonElegir.BackgroundColor3 = C.acento
            botonElegir.TextColor3 = C.oscuro
        else
            botonElegir.Text = "+ Elegir con clic"
            botonElegir.BackgroundColor3 = C.panel
            botonElegir.TextColor3 = C.texto
        end
        local combinado = modoColores == "combinado"
        botonNormal.BackgroundTransparency = combinado and 1 or 0
        botonNormal.TextColor3 = combinado and C.tenue or C.acento
        botonCombinado.BackgroundTransparency = combinado and 0 or 1
        botonCombinado.TextColor3 = combinado and C.acento or C.tenue
        local imagen = cieloElegido and asset(cieloElegido, "zonas")
        muestraMezcla.Image = imagen or ""
        muestraMezcla.Visible = imagen ~= nil
        -- los colores y la barrita solo en el modo combinado (y la lista se corre para darles lugar)
        filaMezcla.Visible = combinado
        if not combinado then objetivoMezcla = nil end
        pintarMuestras()
        pintarBarritaMezcla(intensidadZonas)
        listaReglas.Position = UDim2.fromOffset(0, combinado and 74 or 38)
        listaReglas.Size = UDim2.new(1, 0, 1, combinado and -180 or -144)
        reconstruirReglas()
        sincronizarSelector()
        avisarEstado()
    end

    botonColores.MouseButton1Click:Connect(alternarColores)

    local function cambiarModo(modo)
        if modoColores == modo then return end
        if modo == "combinado" and not (cieloElegido and asset(cieloElegido, "zonas")) then
            aviso("Para el modo combinado elige una foto tuya en CIELO (y abre una vez la app: ella arma las zonas).")
            return
        end
        modoColores = modo
        guardarColores()
        aplicarColores()
        dibujarColores()
    end
    botonNormal.MouseButton1Click:Connect(function() cambiarModo("normal") end)
    botonCombinado.MouseButton1Click:Connect(function() cambiarModo("combinado") end)

    -- tocar "Fondo" o "Zonas" hace que la rueda cambie ese color (otro toque lo suelta)
    local function marcarMuestra(cual)
        objetivoMezcla = (objetivoMezcla ~= cual) and cual or nil
        if objetivoMezcla then reglaElegida = nil end
        pintarMuestras()
        reconstruirReglas()
        sincronizarSelector()
    end
    botonFondo.MouseButton1Click:Connect(function() marcarMuestra("fondo") end)
    botonZona.MouseButton1Click:Connect(function() marcarMuestra("zona") end)

    botonColoresDelCielo.MouseButton1Click:Connect(function()
        if not cieloElegido then return end
        coloresPropios[cieloElegido] = nil
        pintarMuestras()
        repintarMezcla()
        sincronizarSelector()
        guardarColores()
        aviso("Fondo y zonas otra vez con los colores de tu cielo.")
    end)

    -- los bloques con sus colores de siempre y sin reglas; lo demás de COLORES como viene
    local function restablecerColores()
        restaurarTodo()
        table.clear(reglas)
        table.clear(coloresPropios)
        reglaElegida, objetivoMezcla, eligiendo = nil, nil, false
        pincel = Color3.fromHex("FF69B4")
        coloresEncendidos = true
        modoColores = "normal"
        intensidadZonas = 100
        guardarColores()
        dibujarColores()
    end
    conConfirmacion(botonColoresComoEstaba, function()
        restablecerColores()
        aviso("Bloques como estaban: con sus colores de siempre y sin reglas.")
    end, "¿Seguro? Otra vez")

    -- si cambia el cielo, la mezcla es otra: se repinta
    alCambiarCielo = function()
        if modoColores == "combinado" then pcall(aplicarColores) end
        dibujarColores()
    end

    botonElegir.MouseButton1Click:Connect(function()
        eligiendo = not eligiendo
        dibujarColores()
    end)

    botonGrises.MouseButton1Click:Connect(function()
        agregarGrises()
        dibujarColores()
    end)

    for i, hex in ipairs({ "000000", "FFFFFF", "FF69B4", "C39BFF", "64BCE3", "FF3B3B", "3BD671", "FFD23F" }) do
        local boton = crear("TextButton", {
            LayoutOrder = i, Text = "", AutoButtonColor = false,
            BackgroundColor3 = Color3.fromHex(hex), Parent = paleta,
        }, { esquina(7), trazo(C.tenue, 1, 0.5) })
        boton.MouseButton1Click:Connect(function()
            ponerColorExterno(Color3.fromHex(hex))
        end)
    end

    cajaHex.FocusLost:Connect(function()
        local hex = cajaHex.Text:match("^%s*#?(%x%x%x%x%x%x)%s*$")
        if hex then
            ponerColorExterno(Color3.fromHex(hex))
        else
            dibujarSelector() -- vuelve a mostrar el color que había
        end
    end)

    -- arrastrar en la rueda y en la barra de brillo
    do
        local enRueda, enBrillo = false, false

        local function leerRueda()
            local m = UserInputService:GetMouseLocation()
            local centro = rueda.AbsolutePosition + rueda.AbsoluteSize / 2
            local dx, dy = m.X - centro.X, m.Y - centro.Y
            hsv.h = (math.atan2(-dy, dx) / (2 * math.pi)) % 1
            hsv.s = math.clamp(math.sqrt(dx * dx + dy * dy) / (rueda.AbsoluteSize.X / 2), 0, 1)
            ponerColor(Color3.fromHSV(hsv.h, hsv.s, hsv.v), false)
        end

        local function leerBrillo()
            local m = UserInputService:GetMouseLocation()
            hsv.v = math.clamp((m.X - barraBrillo.AbsolutePosition.X) / barraBrillo.AbsoluteSize.X, 0, 1)
            ponerColor(Color3.fromHSV(hsv.h, hsv.s, hsv.v), false)
        end

        rueda.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                enRueda = true
                if hsv.v < 0.05 then hsv.v = 1 end -- desde el negro, la rueda vuelve a encender el color
                leerRueda()
            end
        end)
        barraBrillo.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                enBrillo = true
                leerBrillo()
            end
        end)
        table.insert(conexionesUI, UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
            if enRueda then leerRueda() elseif enBrillo then leerBrillo() end
        end))
        table.insert(conexionesUI, UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 and (enRueda or enBrillo) then
                enRueda, enBrillo = false, false
                guardarColores()
            end
        end))
    end

    -- bloques que aparecen después (mapa nuevo, ronda nueva...)
    table.insert(conexionesUI, workspace.DescendantAdded:Connect(function(obj)
        if #reglas == 0 or not coloresEncendidos then return end
        if obj:IsA("BasePart") then
            -- se espera un instante: quien lo creó suele ponerle el color justo después
            task.defer(function()
                if vivo and obj.Parent then evaluar(obj) end
            end)
        elseif obj:IsA("Texture") and obj.Name ~= "CieloMezcla" then
            task.defer(function()
                local parte = obj.Parent
                local datos = parte and pintadas[parte]
                if vivo and datos and datos.regla then
                    if datos.texturas[obj] == nil then datos.texturas[obj] = obj.Color3 end
                    obj.Color3 = parte.Color
                end
            end)
        end
    end))

    -- mira si desde el PC llegaron fotos nuevas o cambió la elegida
    local firmaGaleria = nil
    local function revisar()
        local texto = leer(ruta("actual.txt"))
        if vivo and texto then
            texto = texto:gsub("%s+", "")
            if texto ~= ultimoLeido then
                ultimoLeido = texto
                cieloElegido = texto:match("^c%d+$") -- "original" o vacío = el cielo del juego
                encendido = true
                aplicar()
            end
        end

        local lista = listarCielos()
        local firma = table.concat(lista, ",")
        if vivo and firma ~= firmaGaleria then
            firmaGaleria = firma
            reconstruirGaleria(lista)
        end
    end

    local function iniciar()
        cargarOpciones()
        cargarColores()
        actualizarUI()
        dibujarColores()
        pcall(revisar)
        pcall(aplicarColores)
    end

    local function limpiar()
        desactivar()
        moduloCristal.quitar()
        restaurarTodo()
    end

    return {
        iniciar = iniciar, revisar = revisar, limpiar = limpiar,
        alternar = alternar, alternarColores = alternarColores,
        restablecerCielo = restablecerCielo, restablecerColores = restablecerColores,
        eligiendo = function() return eligiendo end, elegirConClic = elegirConClic,
        estado = function()
            return { hayFoto = cieloElegido ~= nil, cielo = cieloElegido ~= nil and encendido,
                colores = coloresEncendidos }
        end,
    }
end)()

-- ============================================================================
-- SKINS Y WRAPS (Rivals)
-- ============================================================================

local moduloSkins = NADA -- (modulo que no va en esta version)

-- ============================================================================
-- PROYECTILES (v5.0): lo que tiras o disparas con una skin elegida se ve como el de la skin
-- ============================================================================
-- Rivals dibuja lo que vuela clonando un modelo por nombre (el de tu skin de verdad o, si no
-- tiene, el del arma) de PlayerScripts.Assets.Throwables (granadas, molotovs...) o de
-- Assets.Projectiles (cohetes, flechas, dagas...), directo en workspace, y lo mueve en cada cuadro
-- con PivotTo (y ScaleTo). Lo sacado de su código (Throwable.ReplicateFromServer y
-- Gun._ProjectileEffect, explorador 19). Acá se mete adentro de ese clon el modelo de la skin
-- elegida y se esconde lo original: el juego lo sigue moviendo, agrandando y escondiendo al final
-- como si fuera el suyo. Además:
--   - rayos (Energy Rifle...): se tiñen con la plantilla del rayo de la skin (Assets.Misc)
--   - balas normales (TracerEffect): con el color de trazadora de la skin
--   - explosión normal (una Part invisible con Misc.ExplosionEffect.Attachment): se cambia por la
--     plantilla de la skin, escalada igual, con sus sonidos
-- Solo lo tuyo: lo que nace a pocos studs de tu cámara. Lo de los demás no se toca.

local moduloProyectiles = NADA -- (modulo que no va en esta version)

-- ============================================================================
-- CONTADOR DE DAÑO (debajo de la mira)
-- ============================================================================

local moduloContador = NADA -- (modulo que no va en esta version)

-- ============================================================================
-- RENDIMIENTO (página ⚡ FPS)
-- ============================================================================

-- Un contador de FPS (con el promedio y el peor cuadro de los últimos segundos) y botones para
-- aligerar el juego: todo es como bajar los gráficos, solo en tu pantalla. Lo que se cambia se
-- fuerza (si el juego lo vuelve a poner, se vuelve a quitar) y se devuelve al apagarlo.
local moduloRendimiento = NADA -- (modulo que no va en esta version)

-- ============================================================================
-- SUPER OPTIMIZADOR (página 🚀 OPTIMIZAR)
-- ============================================================================
-- Para servers llenos (20+ jugadores, arcade, free for all). Todo es solo en tu pantalla y se devuelve
-- al apagarlo: materiales lisos, menos detalle lejos, partículas que se apagan cuando están lejos o a
-- tus espaldas (con una lista para elegir cuáles sí y cuáles no) y algunos ajustes de gráficos.
-- La granada de humo y la niebla nunca se esconden de frente: taparlas dejaría ver a través de ellas.

local moduloOptimizador = NADA -- (modulo que no va en esta version)

-- ============================================================================
-- JUGADORES: la gente del server con su @usuario exacto, para reportar bien
-- ============================================================================
-- Solo lee la lista de jugadores (la misma que ve cualquiera con Tab): no toca nada del juego.
-- Los que salen se quedan en la lista (el que hace trampa suele irse rápido) y los que marcas
-- con 🚩 se guardan en jugadores_marcados.txt: si vuelven a caer en tu server, avisa.

local moduloJugadores = NADA -- (modulo que no va en esta version)

-- ============================================================================
-- Atajos, teclas y arranque
-- ============================================================================

-- los atajos de la barra de la izquierda muestran si el cielo y los colores están prendidos
local function refrescarAtajos()
    local e = moduloCielo.estado()
    if not PF.secciones.cielo then return end -- (v6.97) ZENITH SKIN CHANGER no tiene cielo ni colores
    if not e.hayFoto then
        atajoCielo.Text = "☁️ Sin foto"
        atajoCielo:SetAttribute("Tip", "Cielo: todavia no hay foto (ve a la seccion Cielo y agrega una)")
        atajoCielo.BackgroundColor3 = C.panel2
        atajoCielo.TextColor3 = C.tenue
    else
        atajoCielo.Text = e.cielo and "☁️ Cielo ON" or "☁️ Cielo OFF"
        atajoCielo:SetAttribute("Tip", "Prende o apaga la foto de cielo")
        atajoCielo.BackgroundColor3 = e.cielo and C.acento or C.panel2
        atajoCielo.TextColor3 = e.cielo and C.oscuro or C.tenue
    end
    atajoColores.Text = e.colores and "🎨 Colores ON" or "🎨 Colores OFF"
    atajoColores:SetAttribute("Tip", "Prende o apaga los colores de los bloques")
    atajoColores.BackgroundColor3 = e.colores and C.acento or C.panel2
    atajoColores.TextColor3 = e.colores and C.oscuro or C.tenue
    local dano = PF.secciones.dano and moduloContador.activo()
    atajoDano.Text = dano and "🎯 Daño ON" or "🎯 Daño OFF"
    atajoDano:SetAttribute("Tip", "Prende o apaga el contador de daño")
    atajoDano.BackgroundColor3 = dano and C.acento or C.panel2
    atajoDano.TextColor3 = dano and C.oscuro or C.tenue
end
table.insert(alCambiarEstado, refrescarAtajos)
atajoCielo.MouseButton1Click:Connect(function() moduloCielo.alternar() end)
atajoColores.MouseButton1Click:Connect(function() moduloCielo.alternarColores() end)
atajoDano.MouseButton1Click:Connect(function() moduloContador.alternar() end)

-- todo como estaba el juego: el cielo (y con él el reflejo y la luz), los bloques, las armas y los
-- gráficos. El contador de daño y el de FPS son herramientas, no cambian cómo se ve el juego: quedan
conConfirmacion(atajoTodo, function()
    pcall(moduloCielo.restablecerCielo)
    pcall(moduloCielo.restablecerColores)
    pcall(moduloSkins.restablecer)
    pcall(moduloOptimizador.restablecer)
    pcall(moduloRendimiento.restablecer)
    refrescarAtajos()
    aviso("Todo como estaba: cielo del juego, sin reflejo, bloques y armas originales, gráficos del juego. El contador de daño sigue igual.")
end, "¿Seguro? Otra vez")

table.insert(conexionesUI, UserInputService.InputBegan:Connect(function(input)
    -- el clic para elegir bloque va antes que todo: los shooters marcan el clic como usado
    if moduloCielo.eligiendo() and input.UserInputType == Enum.UserInputType.MouseButton1 then
        local posicion = UserInputService:GetMouseLocation()
        if not sobreVentana(posicion) then moduloCielo.elegirConClic(posicion) end
        return
    end
    -- no se mira si el juego ya usó la tecla: hay juegos que las marcan todas.
    -- Solo se ignora si estás escribiendo (chat, buscador, cuadro del color...)
    if UserInputService:GetFocusedTextBox() then return end
    if PF.secciones.cielo and input.KeyCode == TECLA_CIELO then
        moduloCielo.alternar()
    elseif PF.secciones.colores and input.KeyCode == TECLA_COLORES then
        moduloCielo.alternarColores()
    elseif TECLAS_VENTANA[input.KeyCode] or TECLAS_SKINS[input.KeyCode] then
        if abierta() then
            achicarVentana() -- a jugar: queda el iconito y el mouse vuelve al juego
        elseif TECLAS_SKINS[input.KeyCode] and paginas[paginaActual] ~= paginaSkins then
            abrirVentana("skins")
        else
            abrirVentana()
        end
    end
end))

-- si cambia el tamaño de la pantalla, la ventana y el iconito se acomodan
pcall(function()
    table.insert(conexionesUI, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(acomodar))
end)

botonMinimizar.MouseButton1Click:Connect(achicarVentana)

-- la × esconde todo (hasta el iconito): lo puesto se queda, y la tecla + la vuelve a abrir
botonCerrar.MouseButton1Click:Connect(function()
    estadoVentana = "oculta"
    refrescarVentana()
    aviso(string.format(traducir("Ventana oculta: la tecla %s la vuelve a abrir. Todo sigue puesto."), NOMBRE_TECLA))
end)

local function limpiar()
    vivo = false
    for _, con in ipairs(conexionesUI) do con:Disconnect() end
    table.clear(conexionesUI)
    mouseLibre(false)
    soltarRender("CieloTrabarMouse")
    pcall(moduloCielo.limpiar)
    pcall(moduloSkins.limpiar)
    pcall(moduloProyectiles.limpiar)
    pcall(moduloContador.limpiar)
    pcall(moduloOptimizador.limpiar)
    pcall(moduloRendimiento.limpiar)
    pcall(moduloJugadores.limpiar)
    gui:Destroy()
end

for _, tabla in ipairs(registros) do
    if type(tabla) == "table" then
        pcall(rawset, tabla, PF.claves[1], { Limpiar = limpiar, Version = VERSION })
    end
end

-- ============================================================================
-- CONFIGURACION (v7.00): idioma, tamaño de la ventana, tecla, arrancar achicada, avisos, y la ventana en su lugar
-- ============================================================================
do
    -- la tecla elegida (por defecto, la de cada perfil)
    local function aplicarTecla()
        for _, par in ipairs(TECLAS_ELEGIBLES) do
            if par[1] == CFG.tecla then
                NOMBRE_TECLA = par[2]
                table.clear(TECLAS_VENTANA)
                for _, k in ipairs(par[3]) do TECLAS_VENTANA[k] = true end
                if PERFIL == "completo" then
                    table.clear(TECLAS_SKINS)
                end
            end
        end
    end
    aplicarTecla()
    if CFG.achicada == "1" and not inicioAchicado then inicioAchicado = true end

    local desplazable = crear("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 5, ScrollBarImageColor3 = C.acento,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, Parent = paginaConfig,
    }, {
        crear("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }),
        crear("UIPadding", { PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10) }),
    })
    local orden = 0
    local function siguiente() orden = orden + 1 return orden end
    local function titulo(texto)
        crear("TextLabel", {
            LayoutOrder = siguiente(), Text = texto, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.acento, TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22), Parent = desplazable,
        })
    end
    local function nota(texto)
        crear("TextLabel", {
            LayoutOrder = siguiente(), Text = texto, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C.tenue, TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34), Parent = desplazable,
        })
    end
    -- una fila de botones para elegir uno: opciones = { { valor, texto }... }; alElegir(valor)
    local function selector(opciones, actual, alElegir, columnas)
        local filas = math.ceil(#opciones / (columnas or #opciones))
        local marco = crear("Frame", {
            LayoutOrder = siguiente(), Size = UDim2.new(1, 0, 0, filas * 38 - 4), BackgroundTransparency = 1, Parent = desplazable,
        })
        local botones = {}
        local function pintar(valor)
            for v, b in pairs(botones) do
                b.BackgroundColor3 = (v == valor) and C.acento or C.panel2
                b.TextColor3 = (v == valor) and C.oscuro or C.texto
            end
        end
        local porFila = columnas or #opciones
        for i, op in ipairs(opciones) do
            local fila, col = math.floor((i - 1) / porFila), (i - 1) % porFila
            local b = crear("TextButton", {
                Text = op[2], Font = Enum.Font.GothamBold, TextSize = 13, AutoButtonColor = false, BackgroundColor3 = C.panel2, TextColor3 = C.texto,
                Position = UDim2.new(col / porFila, col == 0 and 0 or 3, 0, fila * 38), Size = UDim2.new(1 / porFila, col == 0 and -3 or -6, 0, 34), Parent = marco,
            }, { esquina(12) })
            botones[op[1]] = b
            b.MouseButton1Click:Connect(function()
                pintar(op[1])
                alElegir(op[1])
            end)
        end
        pintar(actual)
        return pintar
    end
    local function boton(texto, alTocar)
        local b = crear("TextButton", {
            LayoutOrder = siguiente(), Text = texto, Font = Enum.Font.GothamBold, TextSize = 13, AutoButtonColor = false, BackgroundColor3 = C.panel2, TextColor3 = C.texto,
            Size = UDim2.new(1, 0, 0, 36), Parent = desplazable,
        }, { esquina(12), trazo(C.linea, 1, 0) })
        b.MouseButton1Click:Connect(function() alTocar(b) end)
        return b
    end

    -- IDIOMA (obligatorio): al elegir uno la ventana se reinicia sola, ya en ese idioma, y vuelve a esta pagina
    titulo("Idioma")
    nota("Elige el idioma de la ventana. Se reinicia sola para aplicarlo.")
    selector(IDIOMAS, IDIOMA, function(valor)
        if valor == IDIOMA then return end
        CFG.idioma = valor
        guardarConfig()
        pcall(rawset, env, PF.globales .. "PestanaInicial", "config")
        task.defer(function()
            local ok, codigo = pcall(readfile, CARPETA .. "/cielo.lua")
            limpiar()
            if ok and type(codigo) == "string" and codigo ~= "" then
                local funcion = loadstring(codigo, "=cielo_reinicio")
                if funcion then funcion() end
            end
        end)
    end, 2)

    titulo("Ventana")
    nota("Tamaño de la ventana")
    selector({ { "90", "Pequeña" }, { "100", "Normal" }, { "115", "Grande" } }, tostring(math.floor(escalaUI.Scale * 100 + 0.5)), function(valor)
        CFG.escala = valor
        guardarConfig()
        escalaUI.Scale = tonumber(valor) / 100
        acomodar()
    end)
    nota("Tecla para abrir y achicar la ventana")
    local opcionesTecla = {}
    for _, par in ipairs(TECLAS_ELEGIBLES) do table.insert(opcionesTecla, { par[1], par[2] }) end
    local teclaActual = CFG.tecla
    if not teclaActual then
        for _, par in ipairs(TECLAS_ELEGIBLES) do
            if par[2] == NOMBRE_TECLA then teclaActual = par[1] end
        end
    end
    selector(opcionesTecla, teclaActual, function(valor)
        CFG.tecla = valor
        guardarConfig()
        aplicarTecla()
    end, 5)
    local botonAchicada, botonAvisos
    local function pintarSiNo(b, texto, activo)
        b.Text = texto .. ":  " .. traducir(activo and "ON" or "OFF")
        b.BackgroundColor3 = activo and C.acento or C.panel2
        b.TextColor3 = activo and C.oscuro or C.texto
    end
    botonAchicada = boton("", function(b)
        CFG.achicada = (CFG.achicada == "1") and "0" or "1"
        guardarConfig()
        pintarSiNo(b, "Empezar achicada al entrar a Rivals", CFG.achicada == "1")
    end)
    pintarSiNo(botonAchicada, "Empezar achicada al entrar a Rivals", CFG.achicada == "1")
    botonAvisos = boton("", function(b)
        CFG.avisos = (CFG.avisos == "0") and "1" or "0"
        guardarConfig()
        pintarSiNo(b, "Avisos en pantalla", CFG.avisos ~= "0")
    end)
    pintarSiNo(botonAvisos, "Avisos en pantalla", CFG.avisos ~= "0")
    boton("Poner la ventana en su lugar", function()
        geo.x, geo.y, geo.w, geo.h = nil, nil, nil, nil
        acomodar()
        guardarGeo()
    end)

    titulo("Acerca de")
    nota(PF.nombre .. " " .. VERSION)
    nota("Solo cosmético: sin aimbot, daño automático, velocidad, vuelo ni teletransporte. No envía nada a ningún lado.")
end

gui.Parent = padreGui()
borrarVentanasViejas(gui)
acomodar()
if pestanaInicial and paginas[pestanaInicial] then paginaActual = pestanaInicial end
if inicioAchicado then estadoVentana = "icono" end
moduloCielo.iniciar()
moduloSkins.iniciar()
moduloProyectiles.iniciar()
moduloContador.iniciar()
moduloRendimiento.iniciar()
pcall(moduloOptimizador.iniciar)
pcall(moduloJugadores.iniciar)
refrescarVentana()
refrescarAtajos()

local enRivals = ""
if moduloSkins.enRivals() then
    local cuantasSkins, cuantosWraps = moduloSkins.cuantas()
    enRivals = " " .. string.format(traducir("SKINS: %d skins y %d wraps."), cuantasSkins, cuantosWraps)
end
if inicioAchicado then
    aviso(VERSION .. traducir(" se abrió sola al entrar a Rivals (queda el iconito). ") .. string.format(traducir("La tecla %s abre la ventana."), NOMBRE_TECLA))
else
    local mensaje = string.format(traducir("La tecla %s achica la ventana a un iconito y la vuelve a abrir."), NOMBRE_TECLA)
    if PF.secciones.cielo then mensaje = mensaje .. " " .. traducir("F8 cielo, F6 colores.") end
    aviso(VERSION .. " " .. traducir("lista.") .. " " .. mensaje .. enRivals)
end

-- si desde la app llegó una foto o cambió el cielo elegido: leer archivos por Xeno puede trabar
-- un instante, así que se mira cada segundo solo con la ventana abierta en CIELO; si no, cada 15
task.spawn(function()
    local ultimaVez = 0
    while vivo do
        task.wait(1)
        local cada = (abierta() and paginaActual == "cielo") and 1 or 15
        if vivo and os.clock() - ultimaVez >= cada then
            ultimaVez = os.clock()
            local ok, fallo = pcall(moduloCielo.revisar)
            if not ok then warn("[Cielo] " .. tostring(fallo)) end
        end
    end
end)

task.spawn(function()
    while vivo do
        local ok, fallo = pcall(moduloSkins.revisar)
        if not ok then warn("[Skins] " .. tostring(fallo)) end
        task.wait(0.25)
    end
end)
