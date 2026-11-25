return function(App)
    local Config, Utils = App.Config, App.Utils
    local S = Config.SAMHUB
    local Players = game:GetService("Players")
    local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

    local Popups = {}
    local rodando = false
    local conexoes = {}
    local candidatos = setmetatable({}, { __mode = "k" })
    local marcados = setmetatable({}, { __mode = "k" })
    local falhas = setmetatable({}, { __mode = "k" })
    local esperarAte = 0

    local alvosCash = {}
    for _, t in ipairs(S.TEXTO_CASH_OUT) do alvosCash[Utils.normalizar(t)] = true end

    local function registrar(d)
        if (d:IsA("TextLabel") or d:IsA("TextButton")) and alvosCash[Utils.normalizar(d.Text)] then
            candidatos[d] = true
        end
    end

    local function coletar()
        for _, d in ipairs(PlayerGui:GetDescendants()) do registrar(d) end
    end

    local function centro(obj)
        return obj.AbsolutePosition + obj.AbsoluteSize / 2
    end

    local function acharCheque()
        for label in pairs(candidatos) do
            if not label.Parent then
                candidatos[label] = nil
            elseif alvosCash[Utils.normalizar(label.Text)] and Utils.naTela(label) then
                local botao = Utils.alvoDoTexto(label)
                local quadro, doCheque = botao.Parent, nil
                for _ = 1, 8 do
                    if not quadro or quadro:IsA("LayerCollector") then break end
                    local tudo = string.lower(Utils.textos(quadro))
                    if Utils.temAlguma(tudo, S.TEXTOS_NAO_MOSTRAR) then return botao, quadro end
                    if not doCheque and Utils.temAlguma(tudo, S.TEXTOS_CHEQUE) then doCheque = quadro end
                    quadro = quadro.Parent
                end
                if doCheque then return botao, doCheque end
            end
        end
        return nil
    end
    Popups.acharCheque = acharCheque

    local function fotoDe(obj)
        local partes = {}
        local function anotar(o)
            if o:IsA("GuiObject") then
                table.insert(partes, o.Name .. ":" .. tostring(Utils.visivel(o)) .. ":" .. tostring(o.BackgroundColor3)
                    .. ":" .. tostring(o.BackgroundTransparency))
                if o:IsA("ImageLabel") or o:IsA("ImageButton") then
                    table.insert(partes, o.Image .. ":" .. tostring(o.ImageColor3) .. ":" .. tostring(o.ImageTransparency))
                end
                if o:IsA("TextLabel") or o:IsA("TextButton") then table.insert(partes, o.Text) end
            elseif o:IsA("UIStroke") then
                table.insert(partes, tostring(o.Color) .. ":" .. tostring(o.Enabled))
            end
        end
        anotar(obj)
        for _, d in ipairs(obj:GetDescendants()) do anotar(d) end
        return table.concat(partes, "|")
    end

    local function textoCurto(obj)
        return #Utils.limpar(Utils.textoDe(obj)) <= 2
    end

    local function ehDoCash(obj, botaoCash)
        return obj == botaoCash or obj:IsAncestorOf(botaoCash) or botaoCash:IsAncestorOf(obj)
    end

    local function caixaNaoMostrar(quadro, botaoCash)
        for _, d in ipairs(quadro:GetDescendants()) do
            if (d:IsA("TextLabel") or d:IsA("TextButton")) and Utils.naTela(d)
                and Utils.temAlguma(string.lower(Utils.limpar(d.Text)), S.TEXTOS_NAO_MOSTRAR) then
                local linhaBotao = d:IsA("GuiButton") and d or d:FindFirstAncestorWhichIsA("GuiButton")
                if linhaBotao and quadro:IsAncestorOf(linhaBotao) and not ehDoCash(linhaBotao, botaoCash) then
                    return linhaBotao, linhaBotao
                end

                local linha = d.Parent
                for _ = 1, 2 do
                    if not linha or linha == quadro.Parent or linha:IsA("LayerCollector") then break end
                    local melhor, menor = nil, 160
                    for _, b in ipairs(linha:GetDescendants()) do
                        if b:IsA("GuiButton") and b ~= d and Utils.naTela(b) and textoCurto(b) and not ehDoCash(b, botaoCash) then
                            local dist = (centro(b) - centro(d)).Magnitude
                            if dist < menor then melhor, menor = b, dist end
                        end
                    end
                    if melhor then return melhor, linha end
                    linha = linha.Parent
                end

                local area = d.Parent
                local inicioTexto = Vector2.new(d.AbsolutePosition.X, centro(d).Y)
                local melhor, menor = nil, 80
                for _, o in ipairs(area:GetDescendants()) do
                    if o:IsA("GuiObject") and o ~= d and not o:IsA("TextLabel") and Utils.naTela(o) and not ehDoCash(o, botaoCash) then
                        local tam = o.AbsoluteSize
                        local proporcao = tam.X / math.max(tam.Y, 1)
                        if tam.X >= 8 and tam.X <= 60 and proporcao > 0.6 and proporcao < 1.6 then
                            local dist = (centro(o) - inicioTexto).Magnitude
                            if dist < menor then melhor, menor = o, dist end
                        end
                    end
                end
                if melhor then return melhor, area end
                if ehDoCash(area, botaoCash) then return nil end
                return area, area
            end
        end
        return nil
    end

    local function marcarNaoMostrar(quadro, botaoCash)
        if marcados[quadro] then return true end
        local alvo, area = caixaNaoMostrar(quadro, botaoCash)
        if not alvo then
            Utils.aviso("cheque: não achei a caixinha 'Do not show again'")
            return false
        end
        local antes = fotoDe(area)
        local ok = Utils.clicar(alvo, area, function() return fotoDe(area) ~= antes end, 1.2, 2)
        marcados[quadro] = true
        if not ok then Utils.aviso("cheque: cliquei na caixinha, mas não vi ela mudar") end
        return ok
    end

    function Popups.resolverCheque()
        if os.clock() < esperarAte then return false end
        local botao, quadro = acharCheque()
        if not botao then return false end

        Utils.log("cheque do banco na tela: marcando 'não mostrar de novo' e apertando Cash Out", "info")
        local marcou = marcarNaoMostrar(quadro, botao)
        task.wait(0.25)
        if not botao.Parent or not Utils.naTela(botao) then
            botao = acharCheque()
            if not botao then return true end
        end

        local ok = Utils.clicar(botao, quadro, function()
            return not botao.Parent or not Utils.naTela(botao)
        end, 2.5)
        if ok then
            marcados[quadro], falhas[quadro] = nil, nil
            Utils.notificar("💵 Cheque: " .. (marcou and "marquei 'não mostrar de novo' e " or "") .. "apertei Cash Out", "ok")
            return true
        end

        falhas[quadro] = (falhas[quadro] or 0) + 1
        if falhas[quadro] >= 3 then
            falhas[quadro] = nil
            esperarAte = os.clock() + 30
            Utils.notificar("Não consegui apertar o Cash Out do cheque. Aperte você (tento de novo em 30s).", "aviso")
        end
        return false
    end

    function Popups.iniciar()
        if rodando then return end
        rodando = true
        table.insert(conexoes, PlayerGui.DescendantAdded:Connect(registrar))
        coletar()
        task.spawn(function()
            local ultimaColeta = os.clock()
            while rodando do
                task.wait(1)
                if S.AUTO_CASH_OUT then
                    if os.clock() - ultimaColeta > 10 then
                        ultimaColeta = os.clock()
                        coletar()
                    end
                    local ok, err = pcall(Popups.resolverCheque)
                    if not ok then Utils.aviso("cheque: " .. tostring(err)) end
                end
            end
        end)
    end

    function Popups.parar()
        rodando = false
        for _, c in ipairs(conexoes) do c:Disconnect() end
        conexoes = {}
    end

    return Popups
end
