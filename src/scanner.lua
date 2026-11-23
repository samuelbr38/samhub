return function(App)
    local Config, Utils = App.Config, App.Utils
    local S = Config.SAMHUB
    local Players = game:GetService("Players")
    local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

    local Scanner = {}

    local function textoValido(texto)
        local l = string.lower(texto)
        if l == "" or #texto > S.TAMANHO_MAX_NOME then return false end
        if Config.IGNORAR[l] or Config.PLACEHOLDERS[l] then return false end
        if string.find(l, "^[%d%s%.,%$/:%%x+-]+$") then return false end
        if string.find(l, "%d+%s*/%s*%d+") then return false end
        return true
    end

    function Scanner.tipo(texto)
        local l = string.lower(texto)
        for _, par in ipairs(Config.TIPOS) do
            if string.find(l, par[1], 1, true) then return par[2] end
        end
        return "🏠 Casa"
    end

    local function icone(texto)
        return string.match(Scanner.tipo(texto), "^(%S+)") or "🏠"
    end

    local function textosDoCartao(cartao)
        local textos = {}
        for _, d in ipairs(cartao:GetDescendants()) do
            if d:IsA("TextLabel") and Utils.visivel(d) then
                local dentroDeBotao = false
                local atual = d.Parent
                while atual and atual ~= cartao do
                    if atual:IsA("GuiButton") then dentroDeBotao = true break end
                    atual = atual.Parent
                end
                local texto = Utils.limpar(d.Text)
                if not dentroDeBotao and textoValido(texto) then
                    local tamanho = d.TextScaled and d.AbsoluteSize.Y or d.TextSize
                    table.insert(textos, { texto = texto, tamanho = tamanho, y = d.AbsolutePosition.Y })
                end
            end
        end
        table.sort(textos, function(a, b)
            if a.tamanho ~= b.tamanho then return a.tamanho > b.tamanho end
            return a.y < b.y
        end)
        return textos
    end

    local function cartoesDe(lista)
        local filhos = {}
        for _, f in ipairs(lista:GetChildren()) do
            if f:IsA("GuiObject") and f.Visible then table.insert(filhos, f) end
        end
        if #filhos == 1 and (filhos[1]:FindFirstChildWhichIsA("UIGridLayout") or filhos[1]:FindFirstChildWhichIsA("UIListLayout")) then
            return cartoesDe(filhos[1])
        end
        local cartoes = {}
        for _, f in ipairs(filhos) do
            if #textosDoCartao(f) > 0 then table.insert(cartoes, f) end
        end
        table.sort(cartoes, function(a, b)
            if a.LayoutOrder ~= b.LayoutOrder then return a.LayoutOrder < b.LayoutOrder end
            if a.AbsolutePosition.Y ~= b.AbsolutePosition.Y then return a.AbsolutePosition.Y < b.AbsolutePosition.Y end
            return a.AbsolutePosition.X < b.AbsolutePosition.X
        end)
        return cartoes
    end

    local function acharLista(painel)
        for _, d in ipairs(painel:GetDescendants()) do
            if d:IsA("GuiObject") and Utils.visivel(d)
                and (d:IsA("ScrollingFrame") or d:FindFirstChildWhichIsA("UIGridLayout")) then
                if #cartoesDe(d) > 0 then return d end
            end
        end
        return nil
    end

    function Scanner.acharPainel()
        if S.CONTAINER_CASAS then
            local painel = PlayerGui:FindFirstChild(S.CONTAINER_CASAS, true)
            if painel then return painel, acharLista(painel) or painel end
            return nil
        end
        for _, d in ipairs(PlayerGui:GetDescendants()) do
            if d:IsA("TextLabel") and Config.TITULOS_LISTA_CASAS[string.lower(Utils.limpar(d.Text))] and Utils.naTela(d) then
                local atual = d.Parent
                while atual and not atual:IsA("LayerCollector") do
                    local lista = acharLista(atual)
                    if lista then return atual, lista end
                    atual = atual.Parent
                end
            end
        end
        return nil
    end

    local function lerCartoes(lista)
        local casas, contagem = {}, {}
        for _, cartao in ipairs(cartoesDe(lista)) do
            local textos = textosDoCartao(cartao)
            local nome = textos[1].texto
            local extras = {}
            for i = 2, math.min(#textos, 3) do
                if textos[i].texto ~= nome then table.insert(extras, textos[i].texto) end
            end
            contagem[nome] = (contagem[nome] or 0) + 1
            local nomeUnico = contagem[nome] > 1 and (nome .. " (" .. contagem[nome] .. ")") or nome
            local tudo = nome .. " " .. table.concat(extras, " ")
            table.insert(casas, {
                nome = nomeUnico,
                nomeOriginal = nome,
                detalhe = table.concat(extras, " · "),
                icone = icone(tudo),
                cartao = cartao,
            })
        end
        return casas
    end
    Scanner.lerCartoes = lerCartoes

    local function pareceCasa(texto)
        if not textoValido(texto) then return false end
        local l = string.lower(texto)
        if string.find(l, "[%?!:]") then return false end
        for _, palavra in ipairs(Config.PALAVRAS_CASA) do
            if string.find(l, palavra, 1, true) then return true end
        end
        return false
    end

    local function lerPorPalavras()
        local casas, vistos = {}, {}
        for _, d in ipairs(PlayerGui:GetDescendants()) do
            if d:IsA("TextLabel") and Utils.naTela(d) then
                local nome = Utils.limpar(d.Text)
                local chave = string.lower(nome)
                if not vistos[chave] and pareceCasa(nome) then
                    vistos[chave] = true
                    table.insert(casas, { nome = nome, nomeOriginal = nome, detalhe = "", icone = icone(nome) })
                end
            end
        end
        table.sort(casas, function(a, b) return a.nome < b.nome end)
        return casas
    end

    function Scanner.escanear()
        local _, lista = Scanner.acharPainel()
        local casas, modo
        if lista then
            casas, modo = lerCartoes(lista), "cartões"
        else
            casas, modo = lerPorPalavras(), "palavras-chave"
        end

        if #casas > 0 then
            Utils.setStatus(#casas .. " casa(s) encontrada(s) (" .. modo .. ")", "info")
        else
            Utils.setStatus("Nenhuma casa. Abra a lista MY HOMES no jogo e escaneie de novo.", "aviso")
        end

        Config.Estado.todasAsCasas = casas
        local existentes = {}
        for _, c in ipairs(casas) do existentes[c.nome] = true end
        for nome in pairs(Config.Estado.casasSelecionadas) do
            if not existentes[nome] then Config.Estado.casasSelecionadas[nome] = nil end
        end

        Utils.EstadoMudou:Fire()
        return casas
    end

    return Scanner
end
