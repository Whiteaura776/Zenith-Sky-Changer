--[[
    cielo_fotos.lua - turns a photo (PNG or JPG) into a sky, INSIDE Roblox.
    It does the same as the PC app when you import a photo: crops it square (1024x1024), fades the top and bottom
    into a flat color, makes the mirrored face, the thumbnail, the main colors and the COLORS zones, and saves it all in
    <folder>/cielos/<id>/ with the same names cielo_main.lua uses.

    How it is used (cielo_main.lua does it):   local fotos = loadstring(readfile("<folder>/cielo_fotos.lua"))()(E)
      E.carpeta      = the script's folder (e.g. "ZenithSky")
      E.writefile / E.readfile / E.isfolder / E.makefolder   (the executor's functions)
      E.ceder()      = task.wait(): called now and then so the game does not freeze
      E.AssetService, E.Content, E.getcustomasset, E.Vector2   (to read PNG photos with EditableImage)
    Why EditableImage: in some executors (Xeno) readfile cuts binary files at the byte 0x1A, so a photo cannot be read from its
    bytes. EditableImage reads a PNG of any size by itself. JPG files cannot be read that way, so they need a binary-safe readfile.
    fotos.importar(photoPath, progress) -> true, id   |   false, "message"
      progress(text, fraction 0-1) is called while it works. The texts are Spanish keys: cielo_main.lua translates them.
]]
return function(E)
    local M = {}
    local floor, min, max, abs, sqrt, fmod = math.floor, math.min, math.max, math.abs, math.sqrt, math.fmod
    local band, bxor, rshift = bit32.band, bit32.bxor, bit32.rshift
    local readu8, writeu8 = buffer.readu8, buffer.writeu8
    -- OR of signed integers (bit32.bor returns an unsigned number)
    local function o_(a, b)
        local r = bit32.bor(a, b)
        if r > 0x7FFFFFFF then r = r - 0x100000000 end
        return r
    end

    local POT2 = {}
    for i = 0, 40 do POT2[i] = 2 ^ i end

    -- The COLORS zones (zonas.png) are the same for every sky. They are stored here as base64 because readfile cannot read
    -- binary files in every executor, and writefile can write them.
    local ZONAS_B64 = [==[
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
]==]
    local ALFA64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local VALOR64 = {}
    for i = 1, #ALFA64 do VALOR64[ALFA64:byte(i)] = i - 1 end
    local function base64(texto)
        local salida, acc, bits = {}, 0, 0
        for i = 1, #texto do
            local v = VALOR64[texto:byte(i)]
            if v then
                acc = acc * 64 + v
                bits = bits + 6
                if bits >= 8 then
                    bits = bits - 8
                    local b = floor(acc / POT2[bits])
                    acc = acc - b * POT2[bits]
                    salida[#salida + 1] = string.char(b)
                end
            end
        end
        return table.concat(salida)
    end

    local LADO = 1024        -- size of each face
    local FUNDIDO = 0.28     -- part of the top/bottom that fades into the flat color

    -- yields to the game only when ~20 ms of work have passed: smooth enough and not too slow
    local ultimoCeder = os.clock()
    local function ceder()
        if E.ceder and os.clock() - ultimoCeder > 0.02 then
            E.ceder()
            ultimoCeder = os.clock()
        end
    end

    -- C# Math.Round (halves go to the even number)
    local function redondear(x)
        local f = floor(x)
        local d = x - f
        if d > 0.5 then return f + 1 end
        if d < 0.5 then return f end
        return (f % 2 == 0) and f or f + 1
    end

    local function byte255(v)
        return max(0, min(255, redondear(v)))
    end

    -- ------------------------------------------------------------------ PNG: writing
    local TABLA_CRC
    local function crc32(s, c)
        if not TABLA_CRC then
            TABLA_CRC = {}
            for i = 0, 255 do
                local v = i
                for _ = 1, 8 do
                    if band(v, 1) == 1 then v = bxor(rshift(v, 1), 0xEDB88320) else v = rshift(v, 1) end
                end
                TABLA_CRC[i] = v
            end
        end
        c = c or 0xFFFFFFFF
        local tabla = TABLA_CRC
        for i = 1, #s, 4096 do
            local bytes = { string.byte(s, i, min(i + 4095, #s)) }
            for j = 1, #bytes do
                c = bxor(tabla[band(bxor(c, bytes[j]), 255)], rshift(c, 8))
            end
        end
        return c
    end

    local function u32(n)
        return string.char(band(rshift(n, 24), 255), band(rshift(n, 16), 255), band(rshift(n, 8), 255), band(n, 255))
    end

    local function trozo(tipo, datos)
        local crc = bxor(crc32(datos, crc32(tipo)), 0xFFFFFFFF)
        return u32(#datos) .. tipo .. datos .. u32(crc)
    end

    -- buf = unfiltered pixels, row by row, with 'canales' bytes per pixel (3 = RGB, 4 = RGBA, 2 = gray+alpha)
    local function codificarPNG(ancho, alto, buf, canales)
        local tipoColor = ({ [2] = 4, [3] = 2, [4] = 6 })[canales]
        local ancho_fila = ancho * canales
        local filas = {}
        for y = 0, alto - 1 do
            filas[#filas + 1] = "\0" .. buffer.readstring(buf, y * ancho_fila, ancho_fila)
            if y % 128 == 127 then ceder() end
        end
        local crudo = table.concat(filas)
        local bloques, i = {}, 1
        local largo = #crudo
        while i <= largo do
            local parte = crudo:sub(i, i + 65534)
            local ultimo = (i + 65535 > largo) and 1 or 0
            local n = #parte
            bloques[#bloques + 1] = string.char(ultimo, n % 256, floor(n / 256), (65535 - n) % 256, floor((65535 - n) / 256)) .. parte
            i = i + 65535
        end
        -- Adler-32
        local a, b = 1, 0
        local k = 1
        while k <= largo do
            local fin = min(k + 4095, largo)
            local bytes = { string.byte(crudo, k, fin) }
            for j = 1, #bytes do
                a = a + bytes[j]
                b = b + a
            end
            a = a % 65521
            b = b % 65521
            k = fin + 1
        end
        ceder()
        local zlib = "\120\1" .. table.concat(bloques) .. u32(b * 65536 + a)
        return "\137PNG\13\10\26\10" .. trozo("IHDR", u32(ancho) .. u32(alto) .. string.char(8, tipoColor, 0, 0, 0))
            .. trozo("IDAT", zlib) .. trozo("IEND", "")
    end
    M.codificarPNG = codificarPNG

    -- ------------------------------------------------------------------ images: scaling
    -- weights of a triangle filter (the usual antialiased "bilinear"): for each output pixel, which input pixel it starts at,
    -- how many there are and how much each one weighs
    local function tablaPesos(entrada, salida)
        local escala = entrada / salida
        local suavizado = escala < 1 and 1 or escala
        local inv = 1 / suavizado
        local ini, cnt, pes = {}, {}, {}
        for i = 0, salida - 1 do
            local centro = (i + 0.5) * escala
            local a = max(floor(centro - suavizado + 0.5), 0)
            local b = min(floor(centro + suavizado + 0.5), entrada)
            local n = max(b - a, 1)
            local w, total = {}, 0
            for k = 0, n - 1 do
                local v = 1 - abs((k + a - centro + 0.5) * inv)
                if v < 0 then v = 0 end
                w[k + 1] = v
                total = total + v
            end
            if total > 0 then
                for k = 1, n do w[k] = w[k] / total end
            else
                w[1] = 1
            end
            ini[i + 1], cnt[i + 1], pes[i + 1] = a, n, w
        end
        return ini, cnt, pes
    end

    -- crops the rectangle (x0, y0, cw, ch) of 'img' and scales it to dw x dh (RGB, 3 bytes per pixel). Transparent parts become black.
    local function escalar(img, x0, y0, cw, ch, dw, dh, texto)
        local src, sw, canales = img.buf, img.w, img.canales
        local ix, cx, px = tablaPesos(cw, dw)
        local medio = buffer.create(dw * ch * 3)
        for y = 0, ch - 1 do
            local fila = (y0 + y) * sw + x0
            for x = 0, dw - 1 do
                local a, n, w = ix[x + 1], cx[x + 1], px[x + 1]
                local r, g, b = 0, 0, 0
                for k = 1, n do
                    local p = (fila + a + k - 1) * canales
                    local wk = w[k]
                    if canales == 4 then
                        local al = readu8(src, p + 3)
                        if al < 255 then wk = wk * al / 255 end
                    end
                    r = r + readu8(src, p) * wk
                    g = g + readu8(src, p + 1) * wk
                    b = b + readu8(src, p + 2) * wk
                end
                local o = (y * dw + x) * 3
                writeu8(medio, o, byte255(r))
                writeu8(medio, o + 1, byte255(g))
                writeu8(medio, o + 2, byte255(b))
            end
            if y % 48 == 47 then ceder() end
        end
        local iy, cy, py = tablaPesos(ch, dh)
        local salida = buffer.create(dw * dh * 3)
        for y = 0, dh - 1 do
            local a, n, w = iy[y + 1], cy[y + 1], py[y + 1]
            for x = 0, dw - 1 do
                local r, g, b = 0, 0, 0
                for k = 1, n do
                    local p = ((a + k - 1) * dw + x) * 3
                    local wk = w[k]
                    r = r + readu8(medio, p) * wk
                    g = g + readu8(medio, p + 1) * wk
                    b = b + readu8(medio, p + 2) * wk
                end
                local o = (y * dw + x) * 3
                writeu8(salida, o, byte255(r))
                writeu8(salida, o + 1, byte255(g))
                writeu8(salida, o + 2, byte255(b))
            end
            if y % 48 == 47 then ceder() end
        end
        return { w = dw, h = dh, canales = 3, buf = salida }
    end
    M.escalar = escalar

    -- phone photos carry a tag that says how they are rotated (EXIF 1-8): the whole image is rotated
    local function orientar(img, o)
        if not o or o == 1 then return img end
        local sw, sh, c, src = img.w, img.h, img.canales, img.buf
        local dw, dh = sw, sh
        if o >= 5 then dw, dh = sh, sw end
        local out = buffer.create(dw * dh * c)
        for y = 0, sh - 1 do
            for x = 0, sw - 1 do
                local nx, ny
                if o == 2 then nx, ny = sw - 1 - x, y
                elseif o == 3 then nx, ny = sw - 1 - x, sh - 1 - y
                elseif o == 4 then nx, ny = x, sh - 1 - y
                elseif o == 5 then nx, ny = y, x
                elseif o == 6 then nx, ny = sh - 1 - y, x
                elseif o == 7 then nx, ny = sh - 1 - y, sw - 1 - x
                else nx, ny = y, sw - 1 - x end
                local p, q = (y * sw + x) * c, (ny * dw + nx) * c
                for k = 0, c - 1 do writeu8(out, q + k, readu8(src, p + k)) end
            end
            if y % 64 == 63 then ceder() end
        end
        return { w = dw, h = dh, canales = c, buf = out }
    end

    -- crops the center into a square and scales it to n x n
    local function cuadrado(img, n)
        local lado = min(img.w, img.h)
        local x0, y0 = floor((img.w - lado) / 2), floor((img.h - lado) / 2)
        return escalar(img, x0, y0, lado, lado, n, n)
    end

    -- ------------------------------------------------------------------ the sky
    -- average (integer, like the app) of rows y0..y1-1
    local function promedio(foto, y0, y1)
        local sr, sg, sb, n = 0, 0, 0, 0
        local buf, w = foto.buf, foto.w
        for y = y0, y1 - 1 do
            for x = 0, w - 1 do
                local p = (y * w + x) * 3
                sr = sr + readu8(buf, p)
                sg = sg + readu8(buf, p + 1)
                sb = sb + readu8(buf, p + 2)
                n = n + 1
            end
        end
        return { floor(sr / n), floor(sg / n), floor(sb / n) }
    end

    -- the photo with the top and bottom faded into a flat color
    local function fundir(foto, arriba, abajo)
        local w, alto = foto.w, foto.h
        local out = buffer.create(w * alto * 3)
        buffer.copy(out, 0, foto.buf, 0, w * alto * 3)
        local franja = floor(alto * FUNDIDO)
        for y = 0, alto - 1 do
            local t, c
            if y < franja then
                t = 1 - y / franja
                c = arriba
            elseif y >= alto - franja then
                t = (y - (alto - franja) + 1) / franja
                c = abajo
            end
            if c then
                local suave = t * t * (3 - 2 * t)
                local inv = 1 - suave
                local fila = y * w * 3
                local c1, c2, c3 = c[1] * suave, c[2] * suave, c[3] * suave
                for x = 0, w - 1 do
                    local p = fila + x * 3
                    writeu8(out, p, redondear(readu8(out, p) * inv + c1))
                    writeu8(out, p + 1, redondear(readu8(out, p + 1) * inv + c2))
                    writeu8(out, p + 2, redondear(readu8(out, p + 2) * inv + c3))
                end
            end
            if y % 96 == 95 then ceder() end
        end
        return { w = w, h = alto, canales = 3, buf = out }
    end

    local function espejo(img)
        local w, h = img.w, img.h
        local out = buffer.create(w * h * 3)
        for y = 0, h - 1 do
            local fila = y * w * 3
            for x = 0, w - 1 do
                local p, q = fila + x * 3, fila + (w - 1 - x) * 3
                writeu8(out, q, readu8(img.buf, p))
                writeu8(out, q + 1, readu8(img.buf, p + 1))
                writeu8(out, q + 2, readu8(img.buf, p + 2))
            end
            if y % 128 == 127 then ceder() end
        end
        return { w = w, h = h, canales = 3, buf = out }
    end

    local function liso(color, lado)
        local out = buffer.create(lado * lado * 3)
        for i = 0, lado * lado - 1 do
            writeu8(out, i * 3, color[1])
            writeu8(out, i * 3 + 1, color[2])
            writeu8(out, i * 3 + 2, color[3])
        end
        return { w = lado, h = lado, canales = 3, buf = out }
    end

    -- ------------------------------------------------------------------ colors (k-means) and zones
    local function hex(c)
        return string.format("#%02X%02X%02X", byte255(c[1]), byte255(c[2]), byte255(c[3]))
    end

    -- RGB (0-255) -> { hue 0-360, saturation 0-1, value 0-1 }
    local function aHsv(c)
        local r, g, b = c[1] / 255, c[2] / 255, c[3] / 255
        local mx, mn = max(r, g, b), min(r, g, b)
        local d = mx - mn
        local h = 0
        if d > 1e-9 then
            if mx == r then h = 60 * fmod((g - b) / d, 6)
            elseif mx == g then h = 60 * ((b - r) / d + 2)
            else h = 60 * ((r - g) / d + 4) end
        end
        if h < 0 then h = h + 360 end
        return { h, mx <= 0 and 0 or d / mx, mx }
    end

    local function deHsv(h, s, v)
        h = ((h % 360) + 360) % 360
        local c = v * s
        local x = c * (1 - abs((h / 60) % 2 - 1))
        local m = v - c
        local r, g, b
        if h < 60 then r, g, b = c, x, 0
        elseif h < 120 then r, g, b = x, c, 0
        elseif h < 180 then r, g, b = 0, c, x
        elseif h < 240 then r, g, b = 0, x, c
        elseif h < 300 then r, g, b = x, 0, c
        else r, g, b = c, 0, x end
        return { (r + m) * 255, (g + m) * 255, (b + m) * 255 }
    end

    -- k-means on the photo shrunk to 160x90 (seeds spread by brightness). Returns centers and weights, from most to least
    local function coloresPrincipales(chica, K)
        local AN, AL = chica.w, chica.h
        local n = AN * AL
        local pix = {}
        for i = 0, n - 1 do
            pix[i + 1] = { readu8(chica.buf, i * 3), readu8(chica.buf, i * 3 + 1), readu8(chica.buf, i * 3 + 2) }
        end
        local orden = {}
        for i = 1, n do orden[i] = i end
        table.sort(orden, function(a, b)
            local sa, sb = pix[a][1] + pix[a][2] + pix[a][3], pix[b][1] + pix[b][2] + pix[b][3]
            if sa ~= sb then return sa < sb end
            return a < b
        end)
        local centros = {}
        for i = 0, K - 1 do
            local p = pix[orden[floor(i * (n - 1) / (K - 1)) + 1]]
            centros[i + 1] = { p[1], p[2], p[3] }
        end
        local grupo = {}
        for i = 1, n do grupo[i] = 1 end
        for _ = 1, 40 do
            local cambio = false
            for i = 1, n do
                local p = pix[i]
                local p1, p2, p3 = p[1], p[2], p[3]
                local mejor, elegido = math.huge, 1
                for k = 1, K do
                    local c = centros[k]
                    local d1, d2, d3 = p1 - c[1], p2 - c[2], p3 - c[3]
                    local d = d1 * d1 + d2 * d2 + d3 * d3
                    if d < mejor then mejor = d; elegido = k end
                end
                if grupo[i] ~= elegido then cambio = true; grupo[i] = elegido end
            end
            local suma, cuenta = {}, {}
            for k = 1, K do suma[k] = { 0, 0, 0 }; cuenta[k] = 0 end
            for i = 1, n do
                local g = grupo[i]
                cuenta[g] = cuenta[g] + 1
                local s, p = suma[g], pix[i]
                s[1] = s[1] + p[1]; s[2] = s[2] + p[2]; s[3] = s[3] + p[3]
            end
            for k = 1, K do
                if cuenta[k] > 0 then
                    centros[k] = { suma[k][1] / cuenta[k], suma[k][2] / cuenta[k], suma[k][3] / cuenta[k] }
                end
            end
            ceder()
            if not cambio then break end
        end
        local cuantos = {}
        for k = 1, K do cuantos[k] = 0 end
        for i = 1, n do cuantos[grupo[i]] = cuantos[grupo[i]] + 1 end
        local indices = {}
        for k = 1, K do if cuantos[k] > 0 then indices[#indices + 1] = k end end
        table.sort(indices, function(a, b)
            if cuantos[a] ~= cuantos[b] then return cuantos[a] > cuantos[b] end
            return a < b
        end)
        local centrosOut, pesos = {}, {}
        for _, k in ipairs(indices) do
            centrosOut[#centrosOut + 1] = centros[k]
            pesos[#pesos + 1] = cuantos[k] / n
        end
        return centrosOut, pesos
    end
    M.coloresPrincipales = coloresPrincipales

    -- returns the text of <id>_colores.txt and <id>_zonas.txt
    local function colores(foto)
        local chica = escalar(foto, 0, 0, foto.w, foto.h, 160, 90)
        local centros, pesos = coloresPrincipales(chica, 8)
        local lineas = {}
        for i = 1, #centros do
            lineas[i] = string.format("%s %.1f", hex(centros[i]), pesos[i] * 100)
        end
        local textoColores = table.concat(lineas, "\n") .. "\n"

        -- 12 groups: with 8 the cream of the light got lost inside the peach
        local finos, pesos12 = coloresPrincipales(chica, 12)
        local principal = 0
        for i = 1, #finos do
            local hsv = aHsv(finos[i])
            if hsv[2] >= 0.2 and hsv[3] >= 0.45 and hsv[3] <= 0.9 and (principal == 0 or pesos12[i] > pesos12[principal]) then
                principal = i
            end
        end
        local fondo
        if principal == 0 then
            fondo = finos[1]
        else
            local tonoPrincipal = aHsv(finos[principal])[1]
            local suma, pesoTotal = { 0, 0, 0 }, 0
            for i = 1, #finos do
                local hsv = aHsv(finos[i])
                local dif = abs(hsv[1] - tonoPrincipal)
                dif = min(dif, 360 - dif)
                if not (hsv[2] < 0.2 or hsv[3] < 0.45 or hsv[3] > 0.9 or dif > 30) then
                    for j = 1, 3 do suma[j] = suma[j] + finos[i][j] * pesos12[i] end
                    pesoTotal = pesoTotal + pesos12[i]
                end
            end
            fondo = { suma[1] / pesoTotal, suma[2] / pesoTotal, suma[3] / pesoTotal }
        end

        -- zones: the lightest one. If it is warm it is pushed toward yellow and saturated a little
        local claro = finos[1]
        for _, c in ipairs(finos) do
            if c[1] + c[2] + c[3] > claro[1] + claro[2] + claro[3] then claro = c end
        end
        local hc = aHsv(claro)
        local zona
        if hc[1] <= 70 or hc[1] >= 330 then
            local tono = hc[1] >= 330 and hc[1] - 360 or hc[1]
            zona = deHsv(min(max(tono + 6, 34), 44), min(max(hc[2], 0.46), 0.6), 0.96)
        else
            zona = deHsv(hc[1], min(max(hc[2], 0.3), 0.6), 0.96)
        end
        return textoColores, hex(fondo) .. "\n" .. hex(zona) .. "\n"
    end

    -- ------------------------------------------------------------------ all together
    local function nuevoId()
        local base = "c" .. os.date("%Y%m%d%H%M%S") .. string.format("%03d", floor((os.clock() % 1) * 1000))
        local id, n = base, 1
        while E.isfolder and E.isfolder(E.carpeta .. "/cielos/" .. id) do
            n = n + 1
            id = base .. n
        end
        return id
    end

    -- reads a file as a string (nil if it fails)
    local function leerBinario(ruta)
        local ok, datos = pcall(E.readfile, ruta)
        if ok and type(datos) == "string" then return datos end
        return nil
    end

    -- PNG read by Roblox itself (EditableImage): works for any size and does not need readfile
    local function leerPNGeditable(ruta)
        if not (E.AssetService and E.getcustomasset and E.Content and E.Vector2) then return nil, "no EditableImage" end
        local ok, img = pcall(function()
            return E.AssetService:CreateEditableImageAsync(E.Content.fromUri(E.getcustomasset(ruta)))
        end)
        if not ok then return nil, tostring(img) end
        local tam = img.Size
        local ok2, buf = pcall(function() return img:ReadPixelsBuffer(E.Vector2.new(0, 0), tam) end)
        pcall(function() img:Destroy() end)
        if not ok2 then return nil, tostring(buf) end
        return { w = tam.X, h = tam.Y, canales = 4, buf = buf }
    end

    -- path of a photo -> { w, h, canales, buf, orientacion } or nil, message
    local function abrirFoto(ruta)
        local ext = ruta:lower():match("%.(%w+)$") or ""
        if ext == "png" then
            local img, err = leerPNGeditable(ruta)
            if img then return img end
            -- if readfile is binary-safe (the file ends the way a PNG ends) our own reader can do it
            local datos = leerBinario(ruta)
            if datos and datos:sub(-8, -5) == "IEND" then return M.decodificarPNG(datos, ceder) end
            return nil, "No pude abrir el PNG: " .. tostring(err or "?"):sub(1, 100)
        elseif ext == "jpg" or ext == "jpeg" then
            local datos = leerBinario(ruta)
            if not datos or #datos < 16 then return nil, "No pude leer el archivo." end
            local termina = datos:find("\255\217", math.max(1, #datos - 64), true)
            if datos:byte(1) ~= 0xFF or datos:byte(2) ~= 0xD8 or not termina then
                return nil, "Este ejecutor no deja leer fotos JPG: guárdala como PNG (en Paint: Archivo > Guardar como > PNG) y vuelve a intentar."
            end
            return M.decodificarJPG(datos, ceder, LADO)
        end
        return nil, "Solo se leen fotos PNG o JPG."
    end

    function M.importar(ruta, progreso)
        progreso = progreso or function() end
        local ok, resultado, mensaje = pcall(function()
            progreso("Abriendo la foto...", 0.02)
            local img, err = abrirFoto(ruta)
            if not img then return false, err end
            if img.w < 8 or img.h < 8 then return false, "La foto es demasiado chica." end
            ceder()
            progreso("Recortando y escalando...", 0.15)
            img = orientar(img, img.orientacion)
            local foto = cuadrado(img, LADO)
            img = nil
            progreso("Armando las caras del cielo...", 0.4)
            local franja = floor(LADO * 0.10)
            local arriba, abajo = promedio(foto, 0, franja), promedio(foto, LADO - franja, LADO)
            local frente = fundir(foto, arriba, abajo)
            local lado = espejo(frente)
            local mini = escalar(foto, 0, 0, LADO, LADO, 160, 160)
            progreso("Sacando los colores...", 0.55)
            local textoColores, textoZonas = colores(foto)
            progreso("Guardando...", 0.7)
            local id = nuevoId()
            local carpeta = E.carpeta .. "/cielos/" .. id
            if E.makefolder then
                if not (E.isfolder and E.isfolder(E.carpeta .. "/cielos")) then pcall(E.makefolder, E.carpeta .. "/cielos") end
                E.makefolder(carpeta)
            end
            local function guardar(cual, imagen)
                E.writefile(carpeta .. "/" .. id .. "_" .. cual .. ".png", codificarPNG(imagen.w, imagen.h, imagen.buf, imagen.canales))
                ceder()
            end
            guardar("foto", foto)
            progreso("Guardando...", 0.78)
            guardar("frente", frente)
            guardar("lado", lado)
            guardar("arriba", liso(arriba, 16))
            guardar("abajo", liso(abajo, 16))
            guardar("mini", mini)
            E.writefile(carpeta .. "/" .. id .. "_colores.txt", textoColores)
            E.writefile(carpeta .. "/" .. id .. "_zonas.txt", textoZonas)
            E.writefile(carpeta .. "/" .. id .. "_zonas.png", base64(ZONAS_B64))
            local nombre = ruta:gsub("\\", "/"):match("([^/]+)$") or id
            nombre = nombre:gsub("%.[^.]*$", "")
            E.writefile(carpeta .. "/nombre.txt", nombre) -- written last: this way a half-made sky never shows up
            progreso("Listo", 1)
            return true, id
        end)
        if not ok then
            local texto = (tostring(resultado):gsub("^[^\n]-:%d+:%s*", "")) -- without the leading "file:line:"
            return false, "Error: " .. texto:sub(1, 160)
        end
        return resultado, mensaje
    end

    -- ================================================================== PNG reader
    -- Our own PNG reader (inflate + unfiltering), so nothing from Roblox is needed to read a photo (EditableImage may limit the size).
    -- Reads color types 0, 2, 3, 4, 6 with 1, 2, 4, 8 or 16 bits. It does not read interlaced PNGs.
    local LARGOS_LZ = { 3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31, 35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258 }
    local EXTRA_LZ = { 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0 }
    local DIST_LZ = { 1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, 257, 385, 513, 769, 1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577 }
    local DEXTRA_LZ = { 0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13 }
    local ORDEN_CL = { 16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15 }

    -- canonical Huffman table from the code lengths (lens[0..n-1]); fast = lookup for codes up to 9 bits
    local function tablaInflate(lens, n)
        local cuenta, siguiente = {}, {}
        for i = 0, 15 do cuenta[i] = 0 end
        for i = 0, n - 1 do cuenta[lens[i]] = cuenta[lens[i]] + 1 end
        cuenta[0] = 0
        local codigo = 0
        for len = 1, 15 do
            codigo = (codigo + cuenta[len - 1]) * 2
            siguiente[len] = codigo
        end
        local rapido, primero, indice, simbolos = {}, {}, {}, {}
        local desplazado = {}
        -- symbols ordered by (length, value), as the slow path needs them
        local k = 0
        for len = 1, 15 do
            indice[len] = k
            for i = 0, n - 1 do
                if lens[i] == len then simbolos[k] = i; k = k + 1 end
            end
        end
        local prox = {}
        for len = 1, 15 do prox[len] = siguiente[len] end
        for i = 0, n - 1 do
            local len = lens[i]
            if len > 0 then
                local c = prox[len]
                prox[len] = c + 1
                if len <= 9 then
                    -- reverse the bits of the code (the stream sends them LSB first)
                    local r, v = 0, c
                    for _ = 1, len do r = r * 2 + v % 2; v = floor(v / 2) end
                    for rell = 0, POT2[9 - len] - 1 do rapido[r + rell * POT2[len]] = len * 1024 + i end
                end
            end
        end
        local pri = {}
        local c2 = 0
        for len = 1, 15 do
            c2 = (c2 + cuenta[len - 1]) * 2
            pri[len] = c2
        end
        return { rapido = rapido, cuenta = cuenta, primero = pri, indice = indice, simbolos = simbolos }
    end

    local TABLA_FIJA_LIT, TABLA_FIJA_DIST
    local function tablasFijas()
        if TABLA_FIJA_LIT then return end
        local l = {}
        for i = 0, 143 do l[i] = 8 end
        for i = 144, 255 do l[i] = 9 end
        for i = 256, 279 do l[i] = 7 end
        for i = 280, 287 do l[i] = 8 end
        TABLA_FIJA_LIT = tablaInflate(l, 288)
        local d = {}
        for i = 0, 29 do d[i] = 5 end
        TABLA_FIJA_DIST = tablaInflate(d, 30)
    end

    -- zlib data (a string) -> buffer with 'tamanoFinal' bytes
    local function inflar(z, desde, tamanoFinal, ceder_)
        local byte = string.byte
        local pos = desde + 2 -- skip the zlib header
        local largoZ = #z
        local bitbuf, bitcnt = 0, 0
        local function bits(n)
            while bitcnt < n do
                bitbuf = bitbuf + (byte(z, pos) or 0) * POT2[bitcnt]
                pos = pos + 1
                bitcnt = bitcnt + 8
            end
            local v = bitbuf % POT2[n]
            bitbuf = floor(bitbuf / POT2[n])
            bitcnt = bitcnt - n
            return v
        end
        local function simbolo(t)
            while bitcnt < 15 do
                bitbuf = bitbuf + (byte(z, pos) or 0) * POT2[bitcnt]
                pos = pos + 1
                bitcnt = bitcnt + 8
            end
            local f = t.rapido[bitbuf % 512]
            if f then
                local len = floor(f / 1024)
                bitbuf = floor(bitbuf / POT2[len])
                bitcnt = bitcnt - len
                return f % 1024
            end
            local codigo, primero = 0, 0
            local v = bitbuf
            for len = 1, 15 do
                codigo = codigo * 2 + v % 2
                v = floor(v / 2)
                local cnt = t.cuenta[len]
                if codigo - cnt < primero then
                    bitbuf = floor(bitbuf / POT2[len])
                    bitcnt = bitcnt - len
                    return t.simbolos[t.indice[len] + (codigo - primero)]
                end
                primero = (primero + cnt) * 2
            end
            error("PNG danado (Huffman)")
        end
        local salida = buffer.create(tamanoFinal)
        local op = 0
        local final = false
        while not final do
            final = bits(1) == 1
            local tipo = bits(2)
            if tipo == 0 then
                pos = pos - floor(bitcnt / 8) -- give back the whole bytes the bit buffer had read ahead
                bitbuf, bitcnt = 0, 0
                local len = (byte(z, pos) or 0) + (byte(z, pos + 1) or 0) * 256
                pos = pos + 4
                for i = 0, len - 1 do
                    if op < tamanoFinal then writeu8(salida, op, byte(z, pos + i) or 0) end
                    op = op + 1
                end
                pos = pos + len
            else
                local lit, dist
                if tipo == 1 then
                    tablasFijas()
                    lit, dist = TABLA_FIJA_LIT, TABLA_FIJA_DIST
                elseif tipo == 2 then
                    local nlit, ndist, ncl = bits(5) + 257, bits(5) + 1, bits(4) + 4
                    local lc = {}
                    for i = 0, 18 do lc[i] = 0 end
                    for i = 1, ncl do lc[ORDEN_CL[i]] = bits(3) end
                    local tcl = tablaInflate(lc, 19)
                    local lens, n = {}, 0
                    while n < nlit + ndist do
                        local s = simbolo(tcl)
                        if s < 16 then
                            lens[n] = s; n = n + 1
                        else
                            local rep, valor
                            if s == 16 then rep = 3 + bits(2); valor = lens[n - 1]
                            elseif s == 17 then rep = 3 + bits(3); valor = 0
                            else rep = 11 + bits(7); valor = 0 end
                            for _ = 1, rep do lens[n] = valor; n = n + 1 end
                        end
                    end
                    local ll, dd = {}, {}
                    for i = 0, nlit - 1 do ll[i] = lens[i] end
                    for i = 0, ndist - 1 do dd[i] = lens[nlit + i] end
                    lit, dist = tablaInflate(ll, nlit), tablaInflate(dd, ndist)
                else
                    error("PNG danado (bloque)")
                end
                while true do
                    local s = simbolo(lit)
                    if s < 256 then
                        if op < tamanoFinal then writeu8(salida, op, s) end
                        op = op + 1
                    elseif s == 256 then
                        break
                    else
                        s = s - 257
                        local largo = LARGOS_LZ[s + 1] + bits(EXTRA_LZ[s + 1])
                        local d = simbolo(dist)
                        local distancia = DIST_LZ[d + 1] + bits(DEXTRA_LZ[d + 1])
                        if distancia > op then error("PNG danado (distancia)") end
                        for i = 0, largo - 1 do
                            if op < tamanoFinal then writeu8(salida, op, readu8(salida, op - distancia)) end
                            op = op + 1
                        end
                    end
                    if op % 65536 < 258 then ceder() end
                end
            end
            if pos > largoZ + 8 then error("PNG cortado") end
        end
        return salida
    end

    function M.decodificarPNG(d, ceder_)
        ceder_ = ceder_ or ceder
        local byte = string.byte
        local function u32(p)
            local a, b, c, e = byte(d, p, p + 3)
            return a * 16777216 + b * 65536 + c * 256 + e
        end
        local pos = 9
        local ancho, alto, prof, tipoColor, entrelazado
        local paleta, trans = nil, nil
        local trozos = {}
        while pos < #d do
            local largo = u32(pos)
            local tipo = d:sub(pos + 4, pos + 7)
            local dat = pos + 8
            if tipo == "IHDR" then
                ancho, alto = u32(dat), u32(dat + 4)
                prof, tipoColor, entrelazado = byte(d, dat + 8), byte(d, dat + 9), byte(d, dat + 12)
            elseif tipo == "PLTE" then
                paleta = {}
                for i = 0, floor(largo / 3) - 1 do
                    paleta[i] = { byte(d, dat + i * 3), byte(d, dat + i * 3 + 1), byte(d, dat + i * 3 + 2) }
                end
            elseif tipo == "tRNS" then
                trans = {}
                for i = 0, largo - 1 do trans[i] = byte(d, dat + i) end
            elseif tipo == "IDAT" then
                trozos[#trozos + 1] = d:sub(dat, dat + largo - 1)
            elseif tipo == "IEND" then
                break
            end
            pos = dat + largo + 4
        end
        if not ancho then error("No es un PNG valido") end
        if entrelazado ~= 0 then error("PNG entrelazado: no se puede leer") end
        local canalesPorTipo = { [0] = 1, [2] = 3, [3] = 1, [4] = 2, [6] = 4 }
        local ncan = canalesPorTipo[tipoColor]
        if not ncan then error("PNG con un tipo de color raro: no se puede leer") end
        local bitsPixel = ncan * prof
        local bytesFila = math.ceil(ancho * bitsPixel / 8)
        local bpp = max(1, floor(bitsPixel / 8)) -- bytes per pixel for the filters
        local z = table.concat(trozos)
        local crudo = inflar(z, 1, alto * (bytesFila + 1), ceder_)

        -- unfilter, in place: the row data ends up at crudo[y * (bytesFila + 1) + 1 ..]
        for y = 0, alto - 1 do
            local fila = y * (bytesFila + 1)
            local filtro = readu8(crudo, fila)
            local ini = fila + 1
            local ant = ini - (bytesFila + 1) -- start of the previous row (when y > 0)
            if filtro == 1 then
                for i = bpp, bytesFila - 1 do
                    writeu8(crudo, ini + i, (readu8(crudo, ini + i) + readu8(crudo, ini + i - bpp)) % 256)
                end
            elseif filtro == 2 then
                if y > 0 then
                    for i = 0, bytesFila - 1 do
                        writeu8(crudo, ini + i, (readu8(crudo, ini + i) + readu8(crudo, ant + i)) % 256)
                    end
                end
            elseif filtro == 3 then
                for i = 0, bytesFila - 1 do
                    local izq = i >= bpp and readu8(crudo, ini + i - bpp) or 0
                    local arr = y > 0 and readu8(crudo, ant + i) or 0
                    writeu8(crudo, ini + i, (readu8(crudo, ini + i) + floor((izq + arr) / 2)) % 256)
                end
            elseif filtro == 4 then
                for i = 0, bytesFila - 1 do
                    local a = i >= bpp and readu8(crudo, ini + i - bpp) or 0
                    local b = y > 0 and readu8(crudo, ant + i) or 0
                    local c = (i >= bpp and y > 0) and readu8(crudo, ant + i - bpp) or 0
                    local p = a + b - c
                    local pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                    local pred
                    if pa <= pb and pa <= pc then pred = a elseif pb <= pc then pred = b else pred = c end
                    writeu8(crudo, ini + i, (readu8(crudo, ini + i) + pred) % 256)
                end
            elseif filtro ~= 0 then
                error("PNG danado (filtro)")
            end
            if y % 64 == 63 then ceder_() end
        end

        -- to RGB (3) or RGBA (4)
        local conAlfa = tipoColor == 4 or tipoColor == 6 or (tipoColor == 3 and trans ~= nil)
        local canales = conAlfa and 4 or 3
        local out = buffer.create(ancho * alto * canales)
        if prof == 8 and (tipoColor == 6 or tipoColor == 2) then
            for y = 0, alto - 1 do
                buffer.copy(out, y * ancho * canales, crudo, y * (bytesFila + 1) + 1, bytesFila)
                if y % 128 == 127 then ceder_() end
            end
        else
            local esc = (prof >= 8) and 1 or 255 / (POT2[prof] - 1)
            local function muestra(ini, idx)
                if prof == 8 then return readu8(crudo, ini + idx) end
                if prof == 16 then return readu8(crudo, ini + idx * 2) end -- the high byte is enough
                local porByte = 8 / prof
                local sh = 8 - prof * (idx % porByte + 1)
                return floor(readu8(crudo, ini + floor(idx / porByte)) / POT2[sh]) % POT2[prof]
            end
            for y = 0, alto - 1 do
                local ini = y * (bytesFila + 1) + 1
                for x = 0, ancho - 1 do
                    local o = (y * ancho + x) * canales
                    if tipoColor == 3 then
                        local idx = muestra(ini, x)
                        local c = paleta and paleta[idx] or { 0, 0, 0 }
                        writeu8(out, o, c[1]); writeu8(out, o + 1, c[2]); writeu8(out, o + 2, c[3])
                        if canales == 4 then writeu8(out, o + 3, (trans and trans[idx]) or 255) end
                    elseif tipoColor == 0 or tipoColor == 4 then
                        local v = floor(muestra(ini, x * ncan) * esc + 0.5)
                        writeu8(out, o, v); writeu8(out, o + 1, v); writeu8(out, o + 2, v)
                        if tipoColor == 4 then writeu8(out, o + 3, floor(muestra(ini, x * ncan + 1) * esc + 0.5)) end
                    else
                        writeu8(out, o, floor(muestra(ini, x * ncan) * esc + 0.5))
                        writeu8(out, o + 1, floor(muestra(ini, x * ncan + 1) * esc + 0.5))
                        writeu8(out, o + 2, floor(muestra(ini, x * ncan + 2) * esc + 0.5))
                        if canales == 4 then writeu8(out, o + 3, floor(muestra(ini, x * ncan + 3) * esc + 0.5)) end
                    end
                end
                if y % 32 == 31 then ceder_() end
            end
        end
        return { w = ancho, h = alto, canales = canales, buf = out }
    end

    -- ================================================================== JPG
    -- Roblox cannot read JPG, so here is a reader: normal (baseline) and progressive JPG, with chroma subsampling,
    -- restart markers, grayscale and the phone rotation tag (EXIF). It does not read arithmetic, 12-bit or CMYK JPGs.
    -- A very big photo is read shrunk (1/2, 1/4 or 1/8) to save memory: it always stays at 1024 or more.
    local ZIGZAG = { 0, 1, 8, 16, 9, 2, 3, 10, 17, 24, 32, 25, 18, 11, 4, 5, 12, 19, 26, 33, 40, 48, 41, 34, 27, 20, 13, 6, 7, 14, 21, 28,
        35, 42, 49, 56, 57, 50, 43, 36, 29, 22, 15, 23, 30, 37, 44, 51, 58, 59, 52, 45, 38, 31, 39, 46, 53, 60, 61, 54, 47, 55, 62, 63 }

    local function construirHuffman(cuentas, simbolos)
        local codigo, k = 0, 1
        local maxcode, valptr, mincode, rapido = {}, {}, {}, {}
        for len = 1, 16 do
            valptr[len] = k
            mincode[len] = codigo
            for _ = 1, cuentas[len] do
                if len <= 9 then
                    local base = codigo * POT2[9 - len]
                    for f = 0, POT2[9 - len] - 1 do rapido[base + f] = len * 256 + simbolos[k] end
                end
                codigo = codigo + 1
                k = k + 1
            end
            maxcode[len] = cuentas[len] > 0 and (codigo - 1) or -1
            codigo = codigo * 2
        end
        return { rapido = rapido, maxcode = maxcode, valptr = valptr, mincode = mincode, simbolos = simbolos }
    end

    -- the rotation (1-8) from the EXIF tag inside an APP1 segment
    local function leerOrientacion(d, ini, fin)
        if d:sub(ini, ini + 5) ~= "Exif\0\0" then return nil end
        local t = ini + 6
        local le = d:sub(t, t + 1) == "II"
        local function u16(p)
            local a, b = d:byte(p, p + 1)
            if not b then return nil end
            return le and (a + b * 256) or (a * 256 + b)
        end
        local function u32(p)
            local a, b, c, e = d:byte(p, p + 3)
            if not e then return nil end
            return le and (a + b * 256 + c * 65536 + e * 16777216) or (a * 16777216 + b * 65536 + c * 256 + e)
        end
        local ifd = u32(t + 4)
        if not ifd then return nil end
        local n = u16(t + ifd)
        if not n then return nil end
        for i = 0, n - 1 do
            local e = t + ifd + 2 + i * 12
            if u16(e) == 0x0112 then
                local v = u16(e + 8)
                if v and v >= 1 and v <= 8 then return v end
                return nil
            end
        end
        return nil
    end

    function M.decodificarJPG(d, ceder_, minimo)
        ceder_ = ceder_ or ceder
        local function dbg(...) if E.log then E.log(...) end end -- diagnostics (only when E.log exists)
        local byte = string.byte
        local largoD = #d
        local pos = 3
        local qt, hdc, hac = {}, {}, {}
        local ancho, alto, comps, progresivo
        local reinicio = 0
        local adobe, orientacion
        local hmax, vmax, mcusX, mcusY, escala = 1, 1, 0, 0, 1

        -- ---- bit reader
        local bitbuf, bitcnt, parar = 0, 0, false
        local function rellenar()
            while bitcnt <= 24 do
                local b = 0
                if not parar then
                    b = byte(d, pos) or 0
                    if pos > largoD then
                        parar = true
                    elseif b == 0xFF then
                        local n = byte(d, pos + 1) or 0
                        if n == 0 then pos = pos + 2 else parar = true; b = 0 end
                    else
                        pos = pos + 1
                    end
                end
                bitbuf = bitbuf * 256 + b
                bitcnt = bitcnt + 8
            end
        end
        local function bits(n)
            if n == 0 then return 0 end
            if bitcnt < n then rellenar() end
            bitcnt = bitcnt - n
            local v = floor(bitbuf / POT2[bitcnt])
            bitbuf = bitbuf - v * POT2[bitcnt]
            return v
        end
        local function extender(v, n)
            if v < POT2[n - 1] then return v - POT2[n] + 1 end
            return v
        end
        local function huffman(t)
            if bitcnt < 16 then rellenar() end
            local f = t.rapido[floor(bitbuf / POT2[bitcnt - 9])]
            if f then
                local len = floor(f / 256)
                bitcnt = bitcnt - len
                bitbuf = bitbuf - floor(bitbuf / POT2[bitcnt]) * POT2[bitcnt]
                return f % 256
            end
            local codigo = floor(bitbuf / POT2[bitcnt - 10])
            local len = 10
            bitcnt = bitcnt - 10
            bitbuf = bitbuf - codigo * POT2[bitcnt]
            while len <= 16 do
                local mx = t.maxcode[len]
                if mx >= 0 and codigo <= mx and codigo >= t.mincode[len] then
                    return t.simbolos[t.valptr[len] + codigo - t.mincode[len]]
                end
                codigo = codigo * 2 + bits(1)
                len = len + 1
            end
            error("JPG danado (codigo de Huffman)")
        end
        local function reiniciarBits()
            bitbuf, bitcnt = 0, 0
            if parar then
                parar = false
            end
            -- skip ahead to the RSTn marker
            while pos < largoD do
                if byte(d, pos) == 0xFF then
                    local n = byte(d, pos + 1)
                    if n and n >= 0xD0 and n <= 0xD7 then pos = pos + 2; return end
                    if n and n ~= 0 and n ~= 0xFF then return end
                end
                pos = pos + 1
            end
        end

        -- ---- block output
        local pesosIdct -- IDCT constants
        local blk = {}
        local salida64 = {}
        local function limitar(v)
            v = floor(v + 0.5)
            if v < 0 then return 0 end
            if v > 255 then return 255 end
            return v
        end

        -- 8-point IDCT (the one from stb_image, in floating point): s[0..7] -> 8 values
        local function idct1d(s0, s1, s2, s3, s4, s5, s6, s7)
            local p2, p3 = s2, s6
            local p1 = (p2 + p3) * 0.5411961
            local t2 = p1 + p3 * -1.847759065
            local t3 = p1 + p2 * 0.765366865
            p2, p3 = s0, s4
            local t0, t1 = p2 + p3, p2 - p3
            local x0, x3 = t0 + t3, t0 - t3
            local x1, x2 = t1 + t2, t1 - t2
            t0, t1, t2, t3 = s7, s5, s3, s1
            local p4
            p3, p4 = t0 + t2, t1 + t3
            p1, p2 = t0 + t3, t1 + t2
            local p5 = (p3 + p4) * 1.175875602
            t0 = t0 * 0.298631336
            t1 = t1 * 2.053119869
            t2 = t2 * 3.072711026
            t3 = t3 * 1.501321110
            p1 = p5 + p1 * -0.899976223
            p2 = p5 + p2 * -2.562915447
            p3 = p3 * -1.961570560
            p4 = p4 * -0.390180644
            t3 = t3 + p1 + p4
            t2 = t2 + p2 + p3
            t1 = t1 + p2 + p4
            t0 = t0 + p1 + p3
            return x0 + t3, x1 + t2, x2 + t1, x3 + t0, x3 - t0, x2 - t1, x1 - t2, x0 - t3
        end

        local tmp = {}
        -- coef[0..63] (already multiplied by the quantization, natural order) -> writes the block into the component's plane
        local function escribirBloque(c, bx, by, solo_dc)
            local plano, pw = c.plano, c.pw
            local s = escala
            local lado = 8 / s
            local ox, oy = bx * lado, by * lado
            if s == 8 or solo_dc then
                local v = limitar(blk[0] / 8 + 128)
                if s == 8 then
                    writeu8(plano, oy * pw + ox, v)
                else
                    for y = 0, lado - 1 do
                        local fila = (oy + y) * pw + ox
                        for x = 0, lado - 1 do writeu8(plano, fila + x, v) end
                    end
                end
                return
            end
            -- columns
            for x = 0, 7 do
                local a0, a1, a2, a3, a4, a5, a6, a7 = idct1d(blk[x], blk[8 + x], blk[16 + x], blk[24 + x], blk[32 + x], blk[40 + x], blk[48 + x], blk[56 + x])
                tmp[x], tmp[8 + x], tmp[16 + x], tmp[24 + x], tmp[32 + x], tmp[40 + x], tmp[48 + x], tmp[56 + x] = a0, a1, a2, a3, a4, a5, a6, a7
            end
            -- rows
            for y = 0, 7 do
                local r = y * 8
                local a0, a1, a2, a3, a4, a5, a6, a7 = idct1d(tmp[r], tmp[r + 1], tmp[r + 2], tmp[r + 3], tmp[r + 4], tmp[r + 5], tmp[r + 6], tmp[r + 7])
                salida64[r], salida64[r + 1], salida64[r + 2], salida64[r + 3] = a0, a1, a2, a3
                salida64[r + 4], salida64[r + 5], salida64[r + 6], salida64[r + 7] = a4, a5, a6, a7
            end
            if s == 1 then
                for y = 0, 7 do
                    local fila = (oy + y) * pw + ox
                    for x = 0, 7 do writeu8(plano, fila + x, limitar(salida64[y * 8 + x] / 8 + 128)) end
                end
            else
                local area = s * s * 8
                for y = 0, lado - 1 do
                    local fila = (oy + y) * pw + ox
                    for x = 0, lado - 1 do
                        local suma = 0
                        for dy = 0, s - 1 do
                            local r = (y * s + dy) * 8 + x * s
                            for dx = 0, s - 1 do suma = suma + salida64[r + dx] end
                        end
                        writeu8(plano, fila + x, limitar(suma / area + 128))
                    end
                end
            end
        end

        -- ---- decode one scan
        local function escaneo(ss, se, ah, al, scomps)
            dbg("JPG scan: components", #scomps, "ss", ss, "se", se, "ah", ah, "al", al, "pos", pos)
            local eobrun = 0
            for _, c in ipairs(scomps) do c.pred = 0 end
            local coefTmp = {}
            local function bloqueBaseline(c, bx, by)
                local th, ta = hdc[c.dc], hac[c.ac]
                if not th or not ta then error("JPG sin tabla de Huffman") end
                for i = 0, 63 do coefTmp[i] = 0 end
                local t = huffman(th)
                local diff = t == 0 and 0 or extender(bits(t), t)
                c.pred = c.pred + diff
                coefTmp[0] = c.pred
                local k, ult = 1, 0
                while k < 64 do
                    local rs = huffman(ta)
                    local s, r = rs % 16, floor(rs / 16)
                    if s == 0 then
                        if r < 15 then break end
                        k = k + 16
                    else
                        k = k + r
                        if k > 63 then break end
                        coefTmp[ZIGZAG[k + 1]] = extender(bits(s), s)
                        ult = k
                        k = k + 1
                    end
                end
                local q = qt[c.tq]
                if not q then error("JPG sin tabla de cuantizacion") end
                for i = 0, 63 do
                    local v = coefTmp[i]
                    blk[i] = v ~= 0 and v * q[i] or 0
                end
                escribirBloque(c, bx, by, ult == 0)
                if not c.yaLogueado then
                    c.yaLogueado = true
                    dbg("JPG first block of component", c.id, "pred", c.pred, "coef0", coefTmp[0], "last nonzero k", ult, "q0", q[0], "blk0", blk[0], "plane first px", readu8(c.plano, 0))
                end
            end

            local cb, base
            local function leer(i) return buffer.readi16(cb, (base + i) * 2) end
            local function poner(i, v) buffer.writei16(cb, (base + i) * 2, v) end
            local function bloqueProgresivo(c, bx, by)
                cb = c.coef
                base = (by * c.bwp + bx) * 64
                if ss == 0 then
                    if ah == 0 then
                        local t = huffman(hdc[c.dc])
                        local diff = t == 0 and 0 or extender(bits(t), t)
                        c.pred = c.pred + diff
                        poner(0, c.pred * POT2[al])
                    else
                        if bits(1) == 1 then poner(0, o_(leer(0), POT2[al])) end
                    end
                    return
                end
                local ta = hac[c.ac]
                if ah == 0 then
                    if eobrun > 0 then eobrun = eobrun - 1; return end
                    local k = ss
                    while k <= se do
                        local rs = huffman(ta)
                        local s, r = rs % 16, floor(rs / 16)
                        if s ~= 0 then
                            k = k + r
                            if k > 63 then break end
                            poner(ZIGZAG[k + 1], extender(bits(s), s) * POT2[al])
                            k = k + 1
                        else
                            if r == 15 then
                                k = k + 16
                            else
                                eobrun = POT2[r] - 1
                                if r > 0 then eobrun = eobrun + bits(r) end
                                break
                            end
                        end
                    end
                else
                    local p1, m1 = POT2[al], -POT2[al]
                    local k = ss
                    if eobrun == 0 then
                        while k <= se do
                            local rs = huffman(ta)
                            local s, r = rs % 16, floor(rs / 16)
                            local nuevo = 0
                            local fin = false
                            if s ~= 0 then
                                nuevo = (bits(1) == 1) and p1 or m1
                            elseif r ~= 15 then
                                eobrun = POT2[r]
                                if r > 0 then eobrun = eobrun + bits(r) end
                                fin = true
                            end
                            if fin then break end
                            while k <= se do
                                local nat = ZIGZAG[k + 1]
                                local v = leer(nat)
                                if v ~= 0 then
                                    if bits(1) == 1 then
                                        if band(v, p1) == 0 then
                                            poner(nat, v >= 0 and v + p1 or v + m1)
                                        end
                                    end
                                else
                                    r = r - 1
                                    if r < 0 then break end
                                end
                                k = k + 1
                            end
                            if nuevo ~= 0 and k <= 63 then poner(ZIGZAG[k + 1], nuevo) end
                            k = k + 1
                        end
                    end
                    if eobrun > 0 then
                        while k <= se do
                            local nat = ZIGZAG[k + 1]
                            local v = leer(nat)
                            if v ~= 0 then
                                if bits(1) == 1 then
                                    if band(v, p1) == 0 then poner(nat, v >= 0 and v + p1 or v + m1) end
                                end
                            end
                            k = k + 1
                        end
                        eobrun = eobrun - 1
                    end
                end
            end

            local bloque = progresivo and bloqueProgresivo or bloqueBaseline
            local total, hecho = 0, 0
            local function tocarReinicio()
                if reinicio > 0 and hecho > 0 and hecho % reinicio == 0 then
                    reiniciarBits()
                    for _, c in ipairs(scomps) do c.pred = 0 end
                    eobrun = 0
                end
            end
            if #scomps == 1 then
                local c = scomps[1]
                local bw = math.ceil(math.ceil(ancho * c.h / hmax) / 8)
                local bh = math.ceil(math.ceil(alto * c.v / vmax) / 8)
                for by = 0, bh - 1 do
                    for bx = 0, bw - 1 do
                        tocarReinicio()
                        bloque(c, bx, by)
                        hecho = hecho + 1
                    end
                    if by % 8 == 7 then ceder_() end
                end
            else
                for my = 0, mcusY - 1 do
                    for mx = 0, mcusX - 1 do
                        tocarReinicio()
                        for _, c in ipairs(scomps) do
                            for v = 0, c.v - 1 do
                                for h = 0, c.h - 1 do
                                    bloque(c, mx * c.h + h, my * c.v + v)
                                end
                            end
                        end
                        hecho = hecho + 1
                    end
                    if my % 4 == 3 then ceder_() end
                end
            end
            dbg("JPG scan done: blocks", hecho, "pos", pos, "of", largoD)
            -- stop at the next marker
            while pos < largoD do
                if byte(d, pos) == 0xFF then
                    local n = byte(d, pos + 1)
                    if n and n ~= 0 and not (n >= 0xD0 and n <= 0xD7) and n ~= 0xFF then break end
                end
                pos = pos + 1
            end
            bitbuf, bitcnt, parar = 0, 0, false
        end

        -- ---- the segments
        local function u16(p) return byte(d, p) * 256 + byte(d, p + 1) end
        local terminado = false
        while not terminado and pos < largoD do
            if byte(d, pos) ~= 0xFF then
                pos = pos + 1
            else
                local m = byte(d, pos + 1)
                pos = pos + 2
                if not m then
                    terminado = true
                elseif m == 0xFF then
                    pos = pos - 1
                elseif m == 0xD8 or m == 0x01 or (m and m >= 0xD0 and m <= 0xD7) or m == 0 then
                    -- no data
                elseif m == 0xD9 then
                    terminado = true
                else
                    local largo = u16(pos)
                    local ini, fin = pos + 2, pos + largo - 1
                    if m == 0xE1 then
                        orientacion = orientacion or leerOrientacion(d, ini, fin)
                    elseif m == 0xEE then
                        if d:sub(ini, ini + 4) == "Adobe" then adobe = byte(d, ini + 11) end
                    elseif m == 0xDB then
                        local p = ini
                        while p < fin do
                            local pq = byte(d, p)
                            local prec, id = floor(pq / 16), pq % 16
                            p = p + 1
                            local t = {}
                            for k = 0, 63 do
                                if prec == 0 then t[ZIGZAG[k + 1]] = byte(d, p); p = p + 1
                                else t[ZIGZAG[k + 1]] = u16(p); p = p + 2 end
                            end
                            qt[id] = t
                        end
                    elseif m == 0xC4 then
                        local p = ini
                        while p < fin do
                            local tc = byte(d, p)
                            local clase, id = floor(tc / 16), tc % 16
                            p = p + 1
                            local cuentas, total = {}, 0
                            for i = 1, 16 do cuentas[i] = byte(d, p + i - 1); total = total + cuentas[i] end
                            p = p + 16
                            local simbolos = {}
                            for i = 1, total do simbolos[i] = byte(d, p + i - 1) end
                            p = p + total
                            local h = construirHuffman(cuentas, simbolos)
                            if clase == 0 then hdc[id] = h else hac[id] = h end
                        end
                    elseif m == 0xDD then
                        reinicio = u16(ini)
                    elseif m == 0xC0 or m == 0xC1 or m == 0xC2 then
                        if byte(d, ini) ~= 8 then error("JPG " .. byte(d, ini) .. " bits: no se puede leer") end
                        progresivo = m == 0xC2
                        alto, ancho = u16(ini + 1), u16(ini + 3)
                        local n = byte(d, ini + 5)
                        if n ~= 1 and n ~= 3 then error("JPG " .. n .. " componentes (CMYK): no se puede leer") end
                        comps = {}
                        for i = 0, n - 1 do
                            local b = ini + 6 + i * 3
                            local hv = byte(d, b + 1)
                            comps[i + 1] = { id = byte(d, b), h = floor(hv / 16), v = hv % 16, tq = byte(d, b + 2) }
                            hmax, vmax = max(hmax, comps[i + 1].h), max(vmax, comps[i + 1].v)
                        end
                        if ancho < 1 or alto < 1 then error("JPG sin tamano") end
                        mcusX, mcusY = math.ceil(ancho / (8 * hmax)), math.ceil(alto / (8 * vmax))
                        -- how much it can be shrunk (1, 2, 4 or 8) without going under 'minimo' on the short side
                        escala = 1
                        if minimo then
                            for _, s in ipairs({ 2, 4, 8 }) do
                                if min(ancho, alto) / s >= minimo then escala = s end
                            end
                        end
                        for _, c in ipairs(comps) do
                            c.bwp, c.bhp = mcusX * c.h, mcusY * c.v
                            c.pw, c.ph = c.bwp * 8 / escala, c.bhp * 8 / escala
                            c.plano = buffer.create(c.pw * c.ph)
                            if progresivo then c.coef = buffer.create(c.bwp * c.bhp * 128) end
                        end
                    elseif m == 0xC3 or (m >= 0xC5 and m <= 0xCF and m ~= 0xC8 and m ~= 0xCC and m ~= 0xC4) then
                        error("Ese tipo de JPG (aritmetico / sin perdida) no se puede leer")
                    elseif m == 0xDA then
                        if not comps then error("JPG sin cabecera") end
                        local n = byte(d, ini)
                        local scomps = {}
                        for i = 0, n - 1 do
                            local cid, tt = byte(d, ini + 1 + i * 2), byte(d, ini + 2 + i * 2)
                            local comp
                            for _, c in ipairs(comps) do if c.id == cid then comp = c end end
                            if not comp then error("JPG con una componente desconocida") end
                            comp.dc, comp.ac = floor(tt / 16), tt % 16
                            scomps[#scomps + 1] = comp
                        end
                        local ss, se = byte(d, ini + 1 + n * 2), byte(d, ini + 2 + n * 2)
                        local a = byte(d, ini + 3 + n * 2)
                        pos = fin + 1
                        bitbuf, bitcnt, parar = 0, 0, false
                        escaneo(ss, se, floor(a / 16), a % 16, scomps)
                        fin = pos - 1 -- (it is already at the next marker)
                    end
                    pos = fin + 1
                end
            end
        end
        if not comps then error("No es un JPG valido") end
        dbg("JPG header:", ancho, "x", alto, "components", #comps, "progressive", progresivo, "scale", escala, "hmax", hmax, "vmax", vmax)

        -- progressive: now that all the scans are in, the IDCT of every block is done
        if progresivo then
            for _, c in ipairs(comps) do
                local cb = c.coef
                local bw = math.ceil(math.ceil(ancho * c.h / hmax) / 8)
                local bh = math.ceil(math.ceil(alto * c.v / vmax) / 8)
                local q = qt[c.tq]
                if not q then error("JPG sin tabla de cuantizacion") end
                for by = 0, c.bhp - 1 do
                    for bx = 0, c.bwp - 1 do
                        local base = (by * c.bwp + bx) * 64
                        local solo_dc = true
                        for i = 0, 63 do
                            local v = buffer.readi16(cb, (base + i) * 2)
                            if i > 0 and v ~= 0 then solo_dc = false end
                            blk[i] = v ~= 0 and v * q[i] or 0
                        end
                        escribirBloque(c, bx, by, solo_dc)
                    end
                    if by % 8 == 7 then ceder_() end
                end
                c.coef = nil
            end
        end

        dbg("JPG planes: y", readu8(comps[1].plano, 0), readu8(comps[1].plano, 777), "cb", comps[2] and readu8(comps[2].plano, 0), "cr", comps[3] and readu8(comps[3].plano, 0))
        -- components -> RGB
        local sw, sh = math.ceil(ancho / escala), math.ceil(alto / escala)
        local rgb = buffer.create(sw * sh * 3)
        local gris = #comps == 1
        local esRGB = (adobe == 0) or (#comps == 3 and comps[1].id == 82 and comps[2].id == 71 and comps[3].id == 66)
        local c1, c2, c3 = comps[1], comps[2], comps[3]
        for y = 0, sh - 1 do
            local f1 = floor(y * c1.v / vmax) * c1.pw
            local f2, f3
            if not gris then
                f2 = floor(y * c2.v / vmax) * c2.pw
                f3 = floor(y * c3.v / vmax) * c3.pw
            end
            for x = 0, sw - 1 do
                local o = (y * sw + x) * 3
                local Y = readu8(c1.plano, f1 + floor(x * c1.h / hmax))
                if gris then
                    writeu8(rgb, o, Y); writeu8(rgb, o + 1, Y); writeu8(rgb, o + 2, Y)
                else
                    local cb = readu8(c2.plano, f2 + floor(x * c2.h / hmax))
                    local cr = readu8(c3.plano, f3 + floor(x * c3.h / hmax))
                    if esRGB then
                        writeu8(rgb, o, Y); writeu8(rgb, o + 1, cb); writeu8(rgb, o + 2, cr)
                    else
                        cb, cr = cb - 128, cr - 128
                        writeu8(rgb, o, limitar(Y + 1.402 * cr))
                        writeu8(rgb, o + 1, limitar(Y - 0.344136 * cb - 0.714136 * cr))
                        writeu8(rgb, o + 2, limitar(Y + 1.772 * cb))
                    end
                end
            end
            if y % 64 == 63 then ceder_() end
        end
        return { w = sw, h = sh, canales = 3, buf = rgb, orientacion = orientacion }
    end

    -- for the tests without Roblox
    M._interno = { cuadrado = cuadrado, promedio = promedio, fundir = fundir, espejo = espejo, colores = colores, orientar = orientar, redondear = redondear }

    return M
end
