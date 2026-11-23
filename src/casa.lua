return function(App)
    local Config, Utils = App.Config, App.Utils
    local S = Config.SAMHUB
    local Players = game:GetService("Players")
    local Eu = Players.LocalPlayer
    local PlayerGui = Eu:WaitForChild("PlayerGui")

    local Casa = {}
    local ocupado = false

    local TECLAS_NUMERO = { "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine" }

    local function raizPersonagem()
        local personagem = Eu.Character
        return personagem and personagem:FindFirstChild("HumanoidRootPart")
    end

    local function posicaoDe(obj)
        if not obj then return nil end
        if obj:IsA("BasePart") then return obj.Position end
        if obj:IsA("Attachment") then return obj.WorldPosition end
        if obj:IsA("Model") then
            local ok, cf = pcall(obj.GetPivot, obj)
            return ok and cf.Position or nil
        end
        return nil
    end

    local function nomesAcima(obj, niveis)
        local partes, atual = {}, obj
        for _ = 1, niveis do
            if not atual or atual == workspace or atual == game then break end
            table.insert(partes, atual.Name)
            atual = atual.Parent
        end
        return string.lower(table.concat(partes, " "))
    end

    function Casa.acharCaixaCorreio()
        local raiz = raizPersonagem()
        if not raiz then return nil end
        local melhor

        local function considerar(tipo, objeto, posicao)
            if not posicao then return end
            local distancia = (posicao - raiz.Position).Magnitude
            if distancia <= S.DISTANCIA_CAIXA_CORREIO and (not melhor or distancia < melhor.distancia) then
                melhor = { tipo = tipo, objeto = objeto, posicao = posicao, distancia = distancia }
            end
        end

        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("ProximityPrompt") then
                local texto = string.lower(d.ObjectText .. " " .. d.ActionText) .. " " .. nomesAcima(d, 4)
                if Utils.temAlguma(texto, S.PALAVRAS_CAIXA_CORREIO) then
                    considerar("prompt", d, posicaoDe(d.Parent))
                end
            elseif d:IsA("ClickDetector") then
                if Utils.temAlguma(nomesAcima(d, 4), S.PALAVRAS_CAIXA_CORREIO) then
                    considerar("clique", d, posicaoDe(d.Parent))
                end
            elseif (d:IsA("Model") or d:IsA("BasePart")) and string.find(string.lower(d.Name), "mail", 1, true) then
                considerar("peca", d, posicaoDe(d))
            end
        end
        return melhor
    end

    local function botaoListar()
        return Utils.acharBotao(PlayerGui, S.TEXTO_LISTAR_CASA)
    end

    local function esperarBotao(segundos)
        local botao, t = botaoListar(), 0
        while not botao and t < segundos do
            task.wait(0.25)
            t += 0.25
            botao = botaoListar()
        end
        return botao
    end

    local function abrirCaixa(caixa)
        if caixa.tipo == "prompt" and Utils.recursos.fireproximityprompt then
            if pcall(fireproximityprompt, caixa.objeto) then return true end
        elseif caixa.tipo == "clique" and Utils.recursos.fireclickdetector then
            if pcall(fireclickdetector, caixa.objeto) then return true end
        end
        local camera = workspace.CurrentCamera
        if not camera then return false end
        local ponto, naFrente = camera:WorldToViewportPoint(caixa.posicao)
        if not naFrente then return false end
        return Utils.clicarNaTela(ponto.X, ponto.Y)
    end

    local function apertarListar(botao)
        local ok, metodo = Utils.clicar(botao)
        if ok then return true, metodo end
        local numero = tonumber(string.match(Utils.limpar(Utils.textoDe(botao)), "%((%d)%)%s*$"))
        if numero and TECLAS_NUMERO[numero] then
            Utils.apertarTecla(Enum.KeyCode[TECLAS_NUMERO[numero]])
            task.wait(0.6)
            if not botaoListar() then return true, "tecla " .. numero end
        end
        return false, nil
    end

    local function listar()
        local botao = botaoListar()

        if not botao then
            local caixa = Casa.acharCaixaCorreio()
            if caixa then
                Utils.setStatus(string.format("Abrindo a caixa de correio (%.0f studs)...", caixa.distancia), "espera")
                abrirCaixa(caixa)
                botao = esperarBotao(3)
            end
        end

        if not botao then
            Utils.setStatus("Toque na sua caixa de correio: eu aperto o List for Trade sozinho", "aviso")
            botao = esperarBotao(S.ESPERA_CAIXA_CORREIO)
        end

        if not botao then
            Utils.setStatus("Não apareceu o List for Trade. A casa já está à venda?", "aviso")
            return false
        end

        task.wait(0.3)
        local ok, metodo = apertarListar(botao)
        if ok then
            Utils.setStatus("Casa à venda (" .. tostring(metodo) .. ")! A placa FOR TRADE apareceu.", "ok")
        else
            Utils.setStatus("Achei o List for Trade, mas o clique não funcionou", "erro")
        end
        return ok
    end

    function Casa.listarParaTroca()
        if ocupado then return false end
        ocupado = true
        local ok, resultado = pcall(listar)
        ocupado = false
        if not ok then
            warn("[SAMHUB] casa: " .. tostring(resultado))
            Utils.setStatus("Erro ao colocar a casa à venda (veja F9)", "erro")
            return false
        end
        return resultado
    end

    function Casa.diagnostico()
        local caixa = Casa.acharCaixaCorreio()
        return {
            caixaCorreio = caixa ~= nil,
            tipo = caixa and caixa.tipo or nil,
            distancia = caixa and caixa.distancia or nil,
            botaoListar = botaoListar() ~= nil,
        }
    end

    return Casa
end
