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

    function Utils.setStatus(texto, tipo)
        tipo = tipo or "info"
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

    Utils.esconderMenuSeCobrir = nil
    Utils.metodoClique = nil

    local function centroDe(botao)
        local tela = botao:FindFirstAncestorWhichIsA("ScreenGui")
        local inset = (tela and tela.IgnoreGuiInset) and Vector2.zero or GuiService:GetGuiInset()
        return botao.AbsolutePosition + botao.AbsoluteSize / 2 + inset
    end

    function Utils.clicarNaTela(x, y)
        if not VIM then return false end
        local ponto = Vector2.new(x, y)
        local restaurar = Utils.esconderMenuSeCobrir and Utils.esconderMenuSeCobrir(ponto)
        if restaurar then task.wait(0.03) end
        local ok = pcall(function()
            VIM:SendMouseMoveEvent(x, y, game)
            task.wait(0.03)
            VIM:SendMouseButtonEvent(x, y, 0, true, game, 0)
            task.wait(0.06)
            VIM:SendMouseButtonEvent(x, y, 0, false, game, 0)
        end)
        if restaurar then task.delay(0.15, restaurar) end
        return ok
    end

    function Utils.apertarTecla(tecla)
        if not VIM then return false end
        return (pcall(function()
            VIM:SendKeyEvent(true, tecla, false, game)
            task.wait(0.05)
            VIM:SendKeyEvent(false, tecla, false, game)
        end))
    end

    local function cliqueMouse(botao)
        local p = centroDe(botao)
        return Utils.clicarNaTela(p.X, p.Y)
    end

    local function cliqueSelecao(botao)
        if not VIM or not botao:IsA("GuiButton") then return false end
        local anterior = GuiService.SelectedObject
        local ok = pcall(function()
            botao.Selectable = true
            GuiService.SelectedObject = botao
            task.wait(0.03)
            VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
            task.wait(0.05)
            VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
        end)
        task.delay(0.1, function()
            pcall(function() GuiService.SelectedObject = anterior end)
        end)
        return ok
    end

    local function cliqueConexoes(botao)
        if not Utils.recursos.getconnections or not botao:IsA("GuiButton") then return false end
        for _, nome in ipairs({ "Activated", "MouseButton1Click", "MouseButton1Down" }) do
            local ok, conexoes = pcall(getconnections, botao[nome])
            if ok and conexoes and #conexoes > 0 then
                for _, c in ipairs(conexoes) do
                    pcall(function() c:Fire() end)
                end
                return true
            end
        end
        return false
    end

    local function cliqueFiresignal(botao)
        if not Utils.recursos.firesignal or not botao:IsA("GuiButton") then return false end
        return (pcall(firesignal, botao.MouseButton1Click))
    end

    local METODOS = {
        { nome = "mouse", fn = cliqueMouse },
        { nome = "seleção", fn = cliqueSelecao },
        { nome = "conexões", fn = cliqueConexoes },
        { nome = "firesignal", fn = cliqueFiresignal },
    }

    function Utils.clicar(botao, raiz)
        raiz = raiz or botao:FindFirstAncestorWhichIsA("LayerCollector") or botao
        local ordem = {}
        for _, m in ipairs(METODOS) do
            if m.nome == Utils.metodoClique then table.insert(ordem, 1, m) else table.insert(ordem, m) end
        end

        if not botao.Parent or not Utils.naTela(botao) then return false, nil end

        local textoBotao = string.lower(Utils.limpar(Utils.textoDe(botao)))
        for _, proibida in ipairs(Config.NUNCA_CLICAR or {}) do
            if Utils.temPalavra(textoBotao, proibida) then
                warn("[SAMHUB] clique bloqueado por segurança: " .. textoBotao)
                return false, nil
            end
        end

        for i, metodo in ipairs(ordem) do
            if i > 1 and (not botao.Parent or not Utils.naTela(botao)) then
                return true, Utils.metodoClique
            end
            local antes = Utils.assinatura(raiz)
            if metodo.fn(botao) then
                local t = 0
                while t < 1.5 do
                    task.wait(0.15)
                    t += 0.15
                    if not botao.Parent or not Utils.naTela(botao) or Utils.assinatura(raiz) ~= antes then
                        Utils.metodoClique = metodo.nome
                        return true, metodo.nome
                    end
                end
            end
        end
        return false, nil
    end

    function Utils.clicarPorTexto(pai, textos, nomes)
        local botao = Utils.acharBotao(pai, textos, nomes)
        if not botao then return false end
        return Utils.clicar(botao, pai)
    end

    return Utils
end
