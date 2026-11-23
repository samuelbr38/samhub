return function(App)
    local Config = App.Config
    local S = Config.SAMHUB
    local GuiService = game:GetService("GuiService")
    local HttpService = game:GetService("HttpService")
    local okVIM, VIM = pcall(game.GetService, game, "VirtualInputManager")

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

    Utils.temArquivos = typeof(writefile) == "function" and typeof(readfile) == "function"

    function Utils.salvarJSON(arquivo, dados)
        if not Utils.temArquivos then return false end
        return (pcall(function()
            writefile(arquivo, HttpService:JSONEncode(dados))
        end))
    end

    function Utils.lerJSON(arquivo)
        if not Utils.temArquivos then return nil end
        if typeof(isfile) == "function" and not isfile(arquivo) then return nil end
        local ok, dados = pcall(function()
            return HttpService:JSONDecode(readfile(arquivo))
        end)
        return ok and dados or nil
    end

    function Utils.copiar(texto)
        if typeof(setclipboard) == "function" then
            return (pcall(setclipboard, texto))
        end
        return false
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

    function Utils.visivel(obj)
        while obj do
            if obj:IsA("GuiObject") and not obj.Visible then return false end
            if obj:IsA("LayerCollector") then return obj.Enabled end
            obj = obj.Parent
        end
        return true
    end

    local function listaTextos(t)
        local lista = {}
        for _, v in ipairs(type(t) == "table" and t or { t }) do
            lista[string.lower(v)] = true
        end
        return lista
    end

    local function botaoDe(obj)
        while obj do
            if obj:IsA("GuiButton") then return obj end
            if obj:IsA("LayerCollector") then return nil end
            obj = obj.Parent
        end
        return nil
    end

    function Utils.acharBotao(pai, textos)
        local alvos = listaTextos(textos)
        for _, d in ipairs(pai:GetDescendants()) do
            if (d:IsA("TextButton") or d:IsA("TextLabel"))
                and alvos[string.lower(Utils.limpar(d.Text))]
                and Utils.visivel(d) then
                local botao = botaoDe(d)
                if botao then return botao end
            end
        end
        return nil
    end

    local function dispararSinal(sinal)
        if typeof(getconnections) ~= "function" then return false end
        local ok, conexoes = pcall(getconnections, sinal)
        if not ok or not conexoes or #conexoes == 0 then return false end
        for _, c in ipairs(conexoes) do
            pcall(function() c:Fire() end)
        end
        return true
    end

    local function cliqueFisico(botao)
        if not okVIM or not VIM then return false end
        local tela = botao:FindFirstAncestorWhichIsA("ScreenGui")
        local inset = (tela and tela.IgnoreGuiInset) and Vector2.zero or GuiService:GetGuiInset()
        local centro = botao.AbsolutePosition + botao.AbsoluteSize / 2 + inset
        return (pcall(function()
            VIM:SendMouseButtonEvent(centro.X, centro.Y, 0, true, game, 0)
            task.wait(0.05)
            VIM:SendMouseButtonEvent(centro.X, centro.Y, 0, false, game, 0)
        end))
    end

    function Utils.clicar(botao)
        for _, nome in ipairs({ "Activated", "MouseButton1Click", "MouseButton1Down" }) do
            if dispararSinal(botao[nome]) then return true end
        end
        return cliqueFisico(botao)
    end

    function Utils.clicarPorTexto(pai, textos)
        local botao = Utils.acharBotao(pai, textos)
        return botao ~= nil and Utils.clicar(botao)
    end

    return Utils
end
