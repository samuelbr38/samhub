return function(App)
    local Config = App.Config
    local S = Config.SAMHUB
    local GuiService = game:GetService("GuiService")
    local HttpService = game:GetService("HttpService")
    local okVIM, VIM = pcall(game.GetService, game, "VirtualInputManager")
    if not okVIM then VIM = nil end

    local Utils = {}

    function Utils.Sinal()
        local funcoes = {}
        local sinal = {}

        function sinal:Connect(fn)
            table.insert(funcoes, fn)
            return {
                Disconnect = function()
                    local i = table.find(funcoes, fn)
                    if i then table.remove(funcoes, i) end
                end,
            }
        end

        function sinal:Fire(...)
            for _, fn in ipairs(table.clone(funcoes)) do
                task.spawn(fn, ...)
            end
        end

        return sinal
    end

    function Utils.Maid()
        local itens = {}
        local maid = {}

        function maid:Add(item)
            table.insert(itens, item)
            return item
        end

        function maid:Clean()
            for i = #itens, 1, -1 do
                local item = itens[i]
                itens[i] = nil
                local tipo = typeof(item)
                if tipo == "RBXScriptConnection" then
                    item:Disconnect()
                elseif tipo == "Instance" then
                    item:Destroy()
                elseif tipo == "function" then
                    pcall(item)
                elseif tipo == "table" and item.Disconnect then
                    item:Disconnect()
                end
            end
        end

        return maid
    end

    Utils.StatusMudou = Utils.Sinal()
    Utils.EstadoMudou = Utils.Sinal()
    Utils.Trabalho = Utils.Sinal()

    function Utils.trabalhando()
        Utils.Trabalho:Fire()
    end

    Utils.registro = {}
    Utils.RegistroMudou = Utils.Sinal()

    function Utils.log(texto, tipo)
        table.insert(Utils.registro, 1, { hora = os.date("%H:%M:%S"), texto = tostring(texto), tipo = tipo or "info" })
        while #Utils.registro > 120 do table.remove(Utils.registro) end
        Utils.RegistroMudou:Fire()
    end

    function Utils.aviso(texto)
        warn("[SAMHUB] " .. tostring(texto))
        Utils.log("⚠ " .. tostring(texto), "aviso")
    end

    function Utils.textoRegistro()
        local linhas = {}
        for i = #Utils.registro, 1, -1 do
            local r = Utils.registro[i]
            table.insert(linhas, "[" .. r.hora .. "] " .. r.texto)
        end
        return table.concat(linhas, "\n")
    end

    Utils.Notificou = Utils.Sinal()
    function Utils.notificar(texto, tipo)
        Utils.log(texto, tipo or "info")
        Utils.Notificou:Fire(texto, tipo or "info")
    end

    function Utils.setStatus(texto, tipo)
        tipo = tipo or "info"
        if Config.Estado.status ~= texto then Utils.log(texto, tipo) end
        Config.Estado.status = texto
        Config.Estado.statusTipo = tipo
        Utils.StatusMudou:Fire(texto, tipo)
    end

    local function existe(nome)
        local ok, valor = pcall(function()
            return (typeof(getgenv) == "function" and getgenv()[nome]) or getfenv(0)[nome]
        end)
        return ok and typeof(valor) == "function"
    end

    Utils.recursos = {
        getconnections = existe("getconnections"),
        firesignal = existe("firesignal"),
        fireproximityprompt = existe("fireproximityprompt"),
        fireclickdetector = existe("fireclickdetector"),
        gethui = existe("gethui"),
        arquivos = existe("writefile") and existe("readfile"),
        clipboard = existe("setclipboard"),
        vim = VIM ~= nil,
    }
    Utils.temArquivos = Utils.recursos.arquivos

    function Utils.nomeExecutor()
        if existe("identifyexecutor") then
            local ok, nome, versao = pcall(identifyexecutor)
            if ok and nome then return tostring(nome) .. (versao and (" " .. tostring(versao)) or "") end
        end
        return "desconhecido"
    end

    function Utils.salvarJSON(arquivo, dados)
        if not Utils.temArquivos then return false end
        return (pcall(function()
            writefile(arquivo, HttpService:JSONEncode(dados))
        end))
    end

    function Utils.lerJSON(arquivo)
        if not Utils.temArquivos then return nil end
        if existe("isfile") and not isfile(arquivo) then return nil end
        local ok, dados = pcall(function()
            return HttpService:JSONDecode(readfile(arquivo))
        end)
        return ok and dados or nil
    end

    function Utils.salvarTexto(arquivo, texto)
        if not Utils.temArquivos then return false end
        return (pcall(writefile, arquivo, texto))
    end

    function Utils.copiar(texto)
        if not Utils.recursos.clipboard then return false end
        return (pcall(setclipboard, texto))
    end

    function Utils.esperar()
        local minimo = S.DELAY_MIN
        local maximo = math.max(S.DELAY_MIN, S.DELAY_MAX)
        task.wait(minimo + math.random() * (maximo - minimo))
    end

    function Utils.limpar(texto)
        texto = string.gsub(texto or "", "<[^>]->", "")
        return (string.gsub(texto, "^%s*(.-)%s*$", "%1"))
    end

    function Utils.normalizar(texto)
        local t = string.lower(Utils.limpar(texto))
        t = string.gsub(t, "%s*%(%w+%)$", "")
        t = string.gsub(t, "%s+", " ")
        return t
    end

    function Utils.textoDe(obj)
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            return obj.Text
        end
        for _, d in ipairs(obj:GetDescendants()) do
            if d:IsA("TextLabel") or d:IsA("TextButton") then return d.Text end
        end
        return ""
    end

    function Utils.escaparPadrao(texto)
        return (string.gsub(texto, "[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0"))
    end

    function Utils.escaparRich(texto)
        texto = string.gsub(texto, "&", "&amp;")
        texto = string.gsub(texto, "<", "&lt;")
        texto = string.gsub(texto, ">", "&gt;")
        return texto
    end

    function Utils.temPalavra(texto, palavra)
        if palavra == "" then return false end
        return string.find(texto, "%f[%w_]" .. Utils.escaparPadrao(palavra) .. "%f[^%w_]") ~= nil
    end

    function Utils.temAlguma(texto, lista)
        for _, p in ipairs(lista) do
            if string.find(texto, string.lower(p), 1, true) then return true end
        end
        return false
    end

    function Utils.visivel(obj)
        while obj do
            if obj:IsA("GuiObject") and not obj.Visible then return false end
            if obj:IsA("LayerCollector") then return obj.Enabled end
            obj = obj.Parent
        end
        return true
    end

    function Utils.naTela(obj)
        if not obj:IsA("GuiObject") or not Utils.visivel(obj) then return false end
        local tam, pos = obj.AbsoluteSize, obj.AbsolutePosition
        if tam.X < 2 or tam.Y < 2 then return false end
        local camera = workspace.CurrentCamera
        local tela = camera and camera.ViewportSize or Vector2.new(1920, 1080)
        if pos.X + tam.X < 0 or pos.Y + tam.Y < 0 or pos.X > tela.X or pos.Y > tela.Y then
            return false
        end
        local atual = obj
        while atual and not atual:IsA("LayerCollector") do
            if atual:IsA("CanvasGroup") and atual.GroupTransparency > 0.95 then return false end
            atual = atual.Parent
        end
        return true
    end

    function Utils.textos(raiz)
        local partes = {}
        for _, d in ipairs(raiz:GetDescendants()) do
            if (d:IsA("TextLabel") or d:IsA("TextButton")) and Utils.visivel(d) then
                table.insert(partes, Utils.limpar(d.Text))
            end
        end
        return table.concat(partes, " | ")
    end

    function Utils.assinatura(raiz)
        local visiveis = 0
        for _, d in ipairs(raiz:GetDescendants()) do
            if d:IsA("GuiObject") and Utils.visivel(d) then visiveis += 1 end
        end
        return visiveis .. "#" .. Utils.textos(raiz)
    end

    local function normalizados(lista)
        local r = {}
        for _, v in ipairs(type(lista) == "table" and lista or { lista }) do
            r[Utils.normalizar(v)] = true
        end
        return r
    end

    local function alvoDoTexto(obj)
        local atual = obj
        while atual do
            if atual:IsA("GuiButton") then return atual end
            if atual:IsA("LayerCollector") then break end
            atual = atual.Parent
        end
        if obj.Parent and obj.Parent:IsA("GuiObject") then return obj.Parent end
        return obj
    end
    Utils.alvoDoTexto = alvoDoTexto

    function Utils.acharBotao(pai, textos, nomes)
        local alvos = normalizados(textos or {})
        for _, d in ipairs(pai:GetDescendants()) do
            if (d:IsA("TextButton") or d:IsA("TextLabel")) and alvos[Utils.normalizar(d.Text)] and Utils.naTela(d) then
                local botao = alvoDoTexto(d)
                if Utils.naTela(botao) then return botao end
            end
        end
        if nomes then
            for _, d in ipairs(pai:GetDescendants()) do
                if d:IsA("GuiButton") and Utils.naTela(d) then
                    local nome = string.lower(d.Name)
                    if not string.find(nome, "^un") then
                        for _, n in ipairs(nomes) do
                            if string.find(nome, n, 1, true) then return d end
                        end
                    end
                end
            end
        end
        return nil
    end

    local Players = game:GetService("Players")
    local mouse = Players.LocalPlayer:GetMouse()

    local function playerGui()
        return Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
    end

    Utils.esconderMenuSeCobrir = nil
    Utils.metodoClique = nil
    Utils.ultimoClique = 0
    Utils.ignorarTextoAoRedor = nil

    function Utils.temProibida(texto)
        texto = string.lower(Utils.limpar(texto or ""))
        for _, p in ipairs(Config.NUNCA_CLICAR or {}) do
            if Utils.temPalavra(texto, p) then return p end
        end
        return nil
    end

    local function paraTela(pontoGui)
        return pontoGui + GuiService:GetGuiInset()
    end

    local function objetosNoPonto(p)
        local pg = playerGui()
        if not pg then return {} end
        local ok, lista = pcall(pg.GetGuiObjectsAtPosition, pg, p.X, p.Y)
        return ok and lista or {}
    end

    local function pontoSeguro(p, alvo)
        local objetos = objetosNoPonto(p)
        local primeiroBotao, alvoNoPonto = nil, false
        for _, o in ipairs(objetos) do
            local liberado = alvo ~= nil and Utils.ignorarTextoAoRedor == alvo
            if not liberado and (o:IsA("TextLabel") or o:IsA("TextButton")) and Utils.temProibida(o.Text) then
                return false, "texto proibido no ponto: " .. o.Text
            end
            if not primeiroBotao and o:IsA("GuiButton") then primeiroBotao = o end
            if alvo and (o == alvo or alvo:IsAncestorOf(o) or o:IsAncestorOf(alvo)) then alvoNoPonto = true end
        end
        if alvo == nil then
            if primeiroBotao then return false, "tem botão da interface no ponto: " .. primeiroBotao.Name end
            return true
        end
        if primeiroBotao then
            local relacionado = primeiroBotao == alvo or alvo:IsAncestorOf(primeiroBotao) or primeiroBotao:IsAncestorOf(alvo)
            if not relacionado then return false, "outro botão no ponto: " .. primeiroBotao:GetFullName() end
            if Utils.temProibida(Utils.textoDe(primeiroBotao)) then return false, "botão proibido" end
            return true
        end
        if alvoNoPonto then return true end
        return false, "o alvo não está nesse ponto"
    end

    local function moverPara(pGui)
        if not VIM then return nil end
        local tela = paraTela(pGui)
        local x, y = tela.X, tela.Y
        for _ = 1, 4 do
            pcall(function() VIM:SendMouseMoveEvent(x, y, game) end)
            task.wait(0.06)
            local erro = pGui - Vector2.new(mouse.X, mouse.Y)
            if erro.Magnitude <= 3 then return Vector2.new(x, y) end
            x += erro.X
            y += erro.Y
        end
        return nil
    end

    local function pontoLivre()
        local camera = workspace.CurrentCamera
        if not camera then return nil end
        local v = camera.ViewportSize
        for _, f in ipairs({ Vector2.new(0.5, 0.35), Vector2.new(0.25, 0.5), Vector2.new(0.75, 0.5), Vector2.new(0.5, 0.65) }) do
            local p = Vector2.new(v.X * f.X, v.Y * f.Y)
            local livre = true
            for _, o in ipairs(objetosNoPonto(p)) do
                if o:IsA("GuiButton") then livre = false break end
            end
            if livre then return paraTela(p) end
        end
        return nil
    end

    local cliqueAtual = 0
    local function afastarMouse(meu)
        if not VIM or meu ~= cliqueAtual then return end
        local tela = pontoLivre()
        if tela then pcall(function() VIM:SendMouseMoveEvent(tela.X, tela.Y, game) end) end
    end

    local tocando = false
    local function soltarDeVerdade()
        if not VIM or tocando then return end
        local tela = pontoLivre()
        if not tela then return end
        pcall(function()
            VIM:SendMouseMoveEvent(tela.X, tela.Y, game)
            task.wait(0.03)
            VIM:SendMouseButtonEvent(tela.X, tela.Y, 0, false, game, 0)
        end)
    end

    local function clicarPonto(pGui, alvo)
        if not VIM then return false end
        cliqueAtual += 1
        local meu = cliqueAtual
        tocando = true
        local restaurar = Utils.esconderMenuSeCobrir and Utils.esconderMenuSeCobrir(pGui)
        if restaurar then task.wait(0.05) end
        local function fim(resultado)
            tocando = false
            if restaurar then task.delay(0.15, restaurar) end
            return resultado
        end

        local ok, motivo = pontoSeguro(pGui, alvo)
        if not ok then
            Utils.aviso("clique cancelado: " .. tostring(motivo))
            return fim(false)
        end
        local tela = moverPara(pGui)
        if not tela then
            Utils.aviso("clique cancelado: não consegui pôr o mouse no lugar certo")
            return fim(false)
        end
        ok, motivo = pontoSeguro(Vector2.new(mouse.X, mouse.Y), alvo)
        if not ok then
            Utils.aviso("clique cancelado (onde o mouse está): " .. tostring(motivo))
            return fim(false)
        end

        Utils.ultimoClique = os.clock()
        local feito = pcall(function()
            VIM:SendMouseButtonEvent(tela.X, tela.Y, 0, true, game, 0)
            task.wait(0.1)
            VIM:SendMouseButtonEvent(tela.X, tela.Y, 0, false, game, 0)
        end)
        if alvo then task.delay(0.2, afastarMouse, meu) end
        return fim(feito)
    end

    function Utils.clicarNaTela(x, y)
        return clicarPonto(Vector2.new(x, y) - GuiService:GetGuiInset(), nil)
    end

    function Utils.apertarTecla(tecla)
        if not VIM then return false end
        Utils.ultimoClique = os.clock()
        return (pcall(function()
            VIM:SendKeyEvent(true, tecla, false, game)
            task.wait(0.05)
            VIM:SendKeyEvent(false, tecla, false, game)
        end))
    end

    local function conexoesDe(sinal)
        local ok, lista = pcall(getconnections, sinal)
        return (ok and type(lista) == "table") and lista or {}
    end

    function Utils.temClique(botao)
        if not Utils.recursos.getconnections or not botao or not botao:IsA("GuiButton") then return nil end
        local n = #conexoesDe(botao.Activated) + #conexoesDe(botao.MouseButton1Click)
            + #conexoesDe(botao.MouseButton1Down) + #conexoesDe(botao.MouseButton1Up)
        return n > 0
    end

    local function dispararTodas(lista, ...)
        local args = table.pack(...)
        for _, c in ipairs(lista) do
            pcall(function() c:Fire(table.unpack(args, 1, args.n)) end)
        end
    end

    local function centroDe(botao)
        return botao.AbsolutePosition + botao.AbsoluteSize / 2
    end

    local function cliqueConexoes(botao, deu)
        if not Utils.recursos.getconnections or not botao:IsA("GuiButton") then return false end
        local ativado, clique = conexoesDe(botao.Activated), conexoesDe(botao.MouseButton1Click)
        local baixo, cima = conexoesDe(botao.MouseButton1Down), conexoesDe(botao.MouseButton1Up)
        if #baixo + #cima + #ativado + #clique == 0 then return false end
        Utils.ultimoClique = os.clock()
        if #ativado + #clique > 0 then
            if #ativado > 0 then
                dispararTodas(ativado)
                task.wait(0.4)
                if deu() or #clique == 0 then return true end
            end
            dispararTodas(clique)
            return true
        end
        local c = centroDe(botao)
        dispararTodas(baixo, c.X, c.Y)
        task.wait(0.08)
        dispararTodas(cima, c.X, c.Y)
        task.wait(0.05)
        dispararTodas(conexoesDe(botao.MouseLeave), c.X, c.Y)
        task.delay(0.1, soltarDeVerdade)
        return true
    end
    local function cliqueFiresignal(botao, deu)
        if not Utils.recursos.firesignal or Utils.recursos.getconnections or not botao:IsA("GuiButton") then return false end
        Utils.ultimoClique = os.clock()
        pcall(firesignal, botao.Activated)
        task.wait(0.4)
        if deu() then return true end
        pcall(firesignal, botao.MouseButton1Click)
        return true
    end

    local function cliqueSelecao(botao)
        if not VIM or not botao:IsA("GuiButton") then return false end
        local anterior = GuiService.SelectedObject
        local eraSelecionavel = botao.Selectable
        local function devolver()
            pcall(function()
                botao.Selectable = eraSelecionavel
                if anterior and anterior.Parent and anterior ~= botao then
                    GuiService.SelectedObject = anterior
                else
                    GuiService.SelectedObject = nil
                end
            end)
        end
        local selecionou = pcall(function()
            botao.Selectable = true
            GuiService.SelectedObject = botao
        end)
        task.wait(0.03)
        if not selecionou or GuiService.SelectedObject ~= botao then
            devolver()
            return false
        end
        Utils.ultimoClique = os.clock()
        local ok = pcall(function()
            VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
            task.wait(0.06)
            VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
        end)
        task.delay(0.1, devolver)
        return ok
    end

    function Utils.limparSelecao(raiz)
        pcall(function()
            local sel = GuiService.SelectedObject
            if sel and (not raiz or sel == raiz or raiz:IsAncestorOf(sel) or not sel.Parent or not Utils.naTela(sel)) then
                GuiService.SelectedObject = nil
            end
        end)
    end

    local function fotoGeometria(botao)
        local foto, n = {}, 0
        local function guardar(o)
            if n >= 40 then return end
            if o:IsA("GuiObject") then
                foto[o] = { Size = o.Size, Position = o.Position, Rotation = o.Rotation }
                n += 1
            elseif o:IsA("UIScale") then
                foto[o] = { Scale = o.Scale }
                n += 1
            end
        end
        pcall(function()
            guardar(botao)
            for _, d in ipairs(botao:GetDescendants()) do guardar(d) end
        end)
        return foto
    end

    local PROPS_VISUAIS = { "ImageColor3", "BackgroundColor3", "ImageTransparency", "BackgroundTransparency",
        "Image", "ImageRectOffset", "TextColor3", "Visible" }
    local function fotoVisual(botao)
        local foto, n = {}, 0
        pcall(function()
            local lista = botao:GetDescendants()
            table.insert(lista, 1, botao)
            for _, o in ipairs(lista) do
                if n >= 25 then break end
                if o:IsA("GuiObject") then
                    local v = {}
                    for _, k in ipairs(PROPS_VISUAIS) do
                        local ok, valor = pcall(function() return o[k] end)
                        if ok then v[k] = valor end
                    end
                    foto[o] = v
                    n += 1
                end
            end
        end)
        return foto
    end

    local function encolheu(agora, antes)
        if agora == antes then return true end
        if antes == 0 then return false end
        local r = agora / antes
        return r >= 0.6 and r < 1
    end
    local function soApertado(agora, antes, prop)
        if prop == "Scale" then return encolheu(agora, antes) end
        if prop == "Rotation" then return math.abs(agora - antes) <= 10 end
        if typeof(agora) ~= "UDim2" then return false end
        if prop == "Size" then
            local menor = (agora.X.Scale < antes.X.Scale or agora.X.Offset < antes.X.Offset
                or agora.Y.Scale < antes.Y.Scale or agora.Y.Offset < antes.Y.Offset)
            return menor and encolheu(agora.X.Scale, antes.X.Scale) and encolheu(agora.Y.Scale, antes.Y.Scale)
                and encolheu(agora.X.Offset, antes.X.Offset) and encolheu(agora.Y.Offset, antes.Y.Offset)
        end
        return math.abs(agora.X.Scale - antes.X.Scale) <= 0.03 and math.abs(agora.Y.Scale - antes.Y.Scale) <= 0.03
            and math.abs(agora.X.Offset - antes.X.Offset) <= 12 and math.abs(agora.Y.Offset - antes.Y.Offset) <= 12
    end

    local function mouseEmCima(obj)
        local p, t = obj.AbsolutePosition, obj.AbsoluteSize
        local m = Vector2.new(mouse.X, mouse.Y)
        return m.X >= p.X and m.X <= p.X + t.X and m.Y >= p.Y and m.Y <= p.Y + t.Y
    end

    local function destravarBotao(botao, foto)
        if not botao or not botao.Parent or not botao:IsA("GuiObject") then return end
        pcall(function()
            if GuiService.SelectedObject == botao then GuiService.SelectedObject = nil end
        end)
        if Utils.recursos.getconnections then
            dispararTodas(conexoesDe(botao.MouseLeave), 0, 0)
        elseif Utils.recursos.firesignal then
            pcall(firesignal, botao.MouseLeave, 0, 0)
        end
        if os.clock() - (Utils.ultimoClique or 0) > 0.4 then soltarDeVerdade() end
        pcall(function()
            local estado = botao.GuiState
            if botao.Interactable and (estado == Enum.GuiState.Press or (estado == Enum.GuiState.Hover and not mouseEmCima(botao))) then
                botao.Interactable = false
                task.wait()
                botao.Interactable = true
            end
        end)
        if not foto then return end
        local primeiro = {}
        for o, props in pairs(foto) do
            if o.Parent and (o == botao or o:IsDescendantOf(botao)) then
                local v = {}
                for k in pairs(props) do v[k] = o[k] end
                primeiro[o] = v
            end
        end
        task.wait(0.2)
        local restaurou = false
        for o, props in pairs(foto) do
            local v1 = primeiro[o]
            if v1 and o.Parent then
                for k, antes in pairs(props) do
                    local ok, agora = pcall(function() return o[k] end)
                    if ok and agora ~= antes and agora == v1[k] and soApertado(agora, antes, k) then
                        if pcall(function() o[k] = antes end) then restaurou = true end
                    end
                end
            end
        end
        if restaurou and os.clock() - (Utils.ultimoClique or 0) > 0.4 then soltarDeVerdade() end
    end

    local recentes = {}
    local destravando = setmetatable({}, { __mode = "k" })
    local function aindaApertado(foto)
        for o, props in pairs(foto) do
            if o.Parent then
                for k, antes in pairs(props) do
                    local ok, agora = pcall(function() return o[k] end)
                    if ok and agora ~= antes and soApertado(agora, antes, k) then return true end
                end
            end
        end
        return false
    end
    local SINAIS = { "Activated", "MouseButton1Click", "MouseButton1Down", "MouseButton1Up", "MouseEnter",
        "MouseLeave", "InputBegan", "InputEnded", "SelectionGained", "SelectionLost" }
    local function resumoConexoes(botao)
        if not Utils.recursos.getconnections then return "(sem getconnections)" end
        local partes = {}
        for _, nome in ipairs(SINAIS) do
            local ok, sinal = pcall(function() return botao[nome] end)
            local n = ok and #conexoesDe(sinal) or 0
            if n > 0 then table.insert(partes, nome .. "=" .. n) end
        end
        return #partes > 0 and table.concat(partes, " ") or "nenhuma"
    end
    local function caminho(o, raiz)
        if o == raiz then return "(botão)" end
        local ok, nome = pcall(function() return o:GetFullName() end)
        local base = ok and nome or o.Name
        local ok2, nomeRaiz = pcall(function() return raiz:GetFullName() end)
        if ok2 and string.sub(base, 1, #nomeRaiz) == nomeRaiz then return "." .. string.sub(base, #nomeRaiz + 2) end
        return base
    end
    local function diferencas(foto, raiz, linhas)
        for o, props in pairs(foto or {}) do
            if o.Parent then
                for k, antes in pairs(props) do
                    local ok, agora = pcall(function() return o[k] end)
                    if ok and agora ~= antes then
                        table.insert(linhas, "   " .. caminho(o, raiz) .. "." .. k .. ": " .. tostring(antes) .. " -> " .. tostring(agora))
                    end
                end
            end
        end
    end
    local function textoDiagnostico(r)
        local b = r.botao
        local linhas = {}
        local function add(s) table.insert(linhas, s) end
        local okNome, nome = pcall(function() return b:GetFullName() end)
        add("• " .. (okNome and nome or tostring(b)) .. "  [" .. tostring(Utils.textoDe(b) or "") .. "]")
        add(string.format("   clicado há %.0fs com: %s", os.clock() - r.t, table.concat(r.metodos or {}, ", ")))
        pcall(function()
            add("   estado=" .. tostring(b.GuiState) .. " interactable=" .. tostring(b.Interactable)
                .. " active=" .. tostring(b.Active) .. " autoCor=" .. tostring(b.AutoButtonColor)
                .. " selecionado=" .. tostring(GuiService.SelectedObject == b) .. " mouseEmCima=" .. tostring(mouseEmCima(b))
                .. " naTela=" .. tostring(Utils.naTela(b)))
        end)
        add("   conexões: " .. resumoConexoes(b))
        local antes = #linhas
        diferencas(r.foto, b, linhas)
        diferencas(r.visual, b, linhas)
        if #linhas == antes then add("   (nada mudou desde antes do clique)") end
        return table.concat(linhas, "\n")
    end

    function Utils.diagnosticoBotoes()
        local partes = { "SAMHUB v" .. tostring(App.Config.VERSAO) .. " · botões apertados pelo script (mais novo primeiro)" }
        local n = 0
        for i = #recentes, 1, -1 do
            local r = recentes[i]
            if r.botao.Parent then
                table.insert(partes, textoDiagnostico(r))
                n += 1
                if n >= 6 then break end
            end
        end
        if n == 0 then table.insert(partes, "(nenhum botão apertado nos últimos 90 segundos)") end
        return table.concat(partes, "\n")
    end

    function Utils.destravarRecentes()
        if os.clock() - (Utils.ultimoClique or 0) < 1.5 then return end
        local agora = os.clock()
        for i = #recentes, 1, -1 do
            local r = recentes[i]
            if agora - r.t > 90 or not r.botao.Parent then
                table.remove(recentes, i)
            elseif not destravando[r.botao] then
                local ok, estado = pcall(function() return r.botao.GuiState end)
                local preso = ok and (estado == Enum.GuiState.Press or (estado == Enum.GuiState.Hover and not mouseEmCima(r.botao)))
                if preso or aindaApertado(r.foto) then
                    r.tentativas = (r.tentativas or 0) + 1
                    if r.tentativas > 3 and not r.avisado then
                        r.avisado = true
                        Utils.log("BOTÃO TRAVADO (não consegui soltar):\n" .. textoDiagnostico(r), "aviso")
                        Utils.notificar("Um botão ficou apertado. Diagnóstico > BOTÕES TRAVADOS > copie e me mande", "aviso")
                    end
                    destravando[r.botao] = true
                    task.spawn(function()
                        pcall(destravarBotao, r.botao, r.foto)
                        destravando[r.botao] = nil
                    end)
                end
            end
        end
    end

    function Utils.destravar(botao)
        task.spawn(destravarBotao, botao, nil)
    end

    local function trazerParaVista(botao)
        local rolagem = botao:FindFirstAncestorWhichIsA("ScrollingFrame")
        if not rolagem then return end
        for _ = 1, 3 do
            local topo = rolagem.AbsolutePosition
            local base = topo + rolagem.AbsoluteWindowSize
            local p, t = botao.AbsolutePosition, botao.AbsoluteSize
            local dx, dy = 0, 0
            if p.Y < topo.Y then dy = p.Y - topo.Y - 4 elseif p.Y + t.Y > base.Y then dy = p.Y + t.Y - base.Y + 4 end
            if p.X < topo.X then dx = p.X - topo.X - 4 elseif p.X + t.X > base.X then dx = p.X + t.X - base.X + 4 end
            if dx == 0 and dy == 0 then return end
            pcall(function() rolagem.CanvasPosition = rolagem.CanvasPosition + Vector2.new(dx, dy) end)
            task.wait(0.1)
        end
    end

    local function cliqueMouse(botao)
        return clicarPonto(centroDe(botao), botao)
    end

    local METODOS = {
        { nome = "toque", fn = cliqueMouse },
        { nome = "conexões", fn = cliqueConexoes },
        { nome = "seleção", fn = cliqueSelecao },
        { nome = "firesignal", fn = cliqueFiresignal },
    }

    local toqueIgnorado = 0

    local clicarSemDestravar
    function Utils.clicar(botao, raiz, confirmar, espera, maxDisparos)
        if not botao or not botao.Parent then return false, nil, 0 end
        local foto, visual = fotoGeometria(botao), fotoVisual(botao)
        local ok, nome, disparos, metodos = clicarSemDestravar(botao, raiz, confirmar, espera, maxDisparos)
        if (disparos or 0) > 0 then
            for i = #recentes, 1, -1 do
                if recentes[i].botao == botao then table.remove(recentes, i) end
            end
            table.insert(recentes, { botao = botao, foto = foto, visual = visual, t = os.clock(), metodos = metodos })
            if #recentes > 30 then table.remove(recentes, 1) end
            task.delay(0.6, destravarBotao, botao, foto)
            task.delay(2, destravarBotao, botao, foto)
        end
        return ok, nome, disparos
    end

    local ultimoAperto = setmetatable({}, { __mode = "k" })
    function clicarSemDestravar(botao, raiz, confirmar, espera, maxDisparos)
        raiz = raiz or botao:FindFirstAncestorWhichIsA("LayerCollector") or botao
        maxDisparos = math.min(maxDisparos or 2, 2)
        local desde = os.clock() - (ultimoAperto[botao] or -10)
        if desde < 1.2 then task.wait(1.2 - desde) end
        if not botao.Parent then return false, nil, 0 end
        if not Utils.naTela(botao) then
            local rolagem = Utils.visivel(botao) and botao:FindFirstAncestorWhichIsA("ScrollingFrame")
            if not (rolagem and Utils.naTela(rolagem)) then return false, nil, 0 end
            trazerParaVista(botao)
            if not Utils.naTela(botao) then return false, nil, 0 end
        end

        local proibida = Utils.temProibida(Utils.textoDe(botao))
        if proibida then
            Utils.aviso("clique bloqueado por segurança (" .. proibida .. "): " .. botao:GetFullName())
            return false, nil, 0
        end

        local ordem = table.clone(METODOS)
        if toqueIgnorado >= 3 then
            table.insert(ordem, table.remove(ordem, 1))
        end

        local disparos, ultimo, toqueFalhou = 0, nil, false
        local metodos = {}
        local function sucesso(nome)
            Utils.metodoClique = nome
            if nome == "toque" then
                toqueIgnorado = 0
            elseif toqueFalhou then
                toqueIgnorado += 1
            end
            return true, nome, disparos, metodos
        end

        for _, metodo in ipairs(ordem) do
            if disparos >= maxDisparos then break end
            if disparos > 0 then
                if confirmar and confirmar() then return sucesso(ultimo) end
                if not confirmar and (not botao.Parent or not Utils.naTela(botao)) then return sucesso(ultimo) end
                if not botao.Parent then break end
            end
            local pular = metodo.nome == "seleção" and disparos > 0
            local antes = Utils.assinatura(raiz)
            local function deu()
                if confirmar then return confirmar() and true or false end
                return not botao.Parent or not Utils.naTela(botao) or Utils.assinatura(raiz) ~= antes
            end
            if not pular and metodo.fn(botao, deu) then
                disparos += 1
                ultimo = metodo.nome
                ultimoAperto[botao] = os.clock()
                table.insert(metodos, metodo.nome)
                local t = 0
                while t < (espera or 1.5) do
                    if deu() then return sucesso(metodo.nome) end
                    task.wait(0.15)
                    t += 0.15
                end
                if deu() then return sucesso(metodo.nome) end
                if metodo.nome == "toque" then toqueFalhou = true end
            end
        end
        return false, nil, disparos, metodos
    end

    function Utils.temPerigo(texto)
        texto = string.lower(Utils.limpar(texto or ""))
        for _, p in ipairs(Config.PALAVRAS_PERIGO or {}) do
            if Utils.temPalavra(texto, p) then return p end
        end
        return nil
    end

    Utils.TEXTO_NAO = { "No", "Cancel", "Não", "Nao", "Cancelar", "Nope", "Back", "Voltar" }

    function Utils.dialogoPerigoso()
        local pg = playerGui()
        if not pg then return nil end
        for _, d in ipairs(pg:GetDescendants()) do
            if d:IsA("TextLabel") and not d:FindFirstAncestorWhichIsA("GuiButton")
                and Utils.temPerigo(d.Text) and Utils.naTela(d) then
                local quadro = d.Parent
                for _ = 1, 5 do
                    if not quadro or quadro:IsA("LayerCollector") then break end
                    local nao = Utils.acharBotao(quadro, Utils.TEXTO_NAO)
                    if nao then return quadro, nao, Utils.limpar(d.Text) end
                    quadro = quadro.Parent
                end
            end
        end
        return nil
    end

    function Utils.cancelarDialogoPerigoso()
        local quadro, nao, texto = Utils.dialogoPerigoso()
        if not nao then return false end
        Utils.aviso("janela perigosa cancelada: " .. tostring(texto))
        Utils.clicar(nao, quadro)
        Utils.setStatus("Cancelei uma janela perigosa: \"" .. tostring(texto) .. "\"", "erro")
        return true
    end

    function Utils.clicarPorTexto(pai, textos, nomes)
        local botao = Utils.acharBotao(pai, textos, nomes)
        if not botao then return false end
        return Utils.clicar(botao, pai)
    end

    return Utils
end
