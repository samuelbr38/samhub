return function(App)
    local Config, Utils = App.Config, App.Utils
    local S = Config.SAMHUB
    local Players = game:GetService("Players")
    local Eu = Players.LocalPlayer
    local PlayerGui = Eu:WaitForChild("PlayerGui")

    local Casa = {}

    local function posicaoDe(obj)
        local pai = obj.Parent
        if not pai then return nil end
        if pai:IsA("BasePart") then return pai.Position end
        if pai:IsA("Attachment") then return pai.WorldPosition end
        if pai:IsA("Model") then return pai:GetPivot().Position end
        local parte = pai:FindFirstChildWhichIsA("BasePart", true)
        return parte and parte.Position or nil
    end

    local function textoDoPrompt(prompt)
        local partes = { prompt.ObjectText, prompt.ActionText, prompt.Name }
        local atual = prompt.Parent
        for _ = 1, 3 do
            if not atual or atual == workspace then break end
            table.insert(partes, atual.Name)
            atual = atual.Parent
        end
        return string.lower(table.concat(partes, " "))
    end

    function Casa.acharCaixaCorreio()
        local personagem = Eu.Character
        local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
        local melhor, menor = nil, math.huge
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("ProximityPrompt") and Utils.temAlguma(textoDoPrompt(d), S.PALAVRAS_CAIXA_CORREIO) then
                local pos = posicaoDe(d)
                local dist = (pos and raiz) and (pos - raiz.Position).Magnitude or 1e6
                if dist < menor then melhor, menor = d, dist end
            end
        end
        return melhor, melhor and menor or nil
    end

    local function botaoListar()
        return Utils.acharBotao(PlayerGui, S.TEXTO_LISTAR_CASA)
    end

    local function ativarPrompt(prompt)
        if Utils.recursos.fireproximityprompt then
            return (pcall(fireproximityprompt, prompt))
        end
        return (pcall(function()
            prompt:InputHoldBegin()
            task.wait(prompt.HoldDuration + 0.1)
            prompt:InputHoldEnd()
        end))
    end

    function Casa.listarParaTroca()
        local botao = botaoListar()

        if not botao then
            local prompt, distancia = Casa.acharCaixaCorreio()
            if not prompt then
                Utils.setStatus("Não achei a caixa de correio. Vá até a frente da sua casa e clique nela.", "aviso")
                return false
            end
            Utils.setStatus(string.format("Abrindo a caixa de correio (%.0f studs)...", distancia or 0), "espera")
            ativarPrompt(prompt)

            local t = 0
            repeat
                task.wait(0.25)
                t += 0.25
                botao = botaoListar()
            until botao or t >= 4
        end

        if not botao then
            Utils.setStatus("A caixa de correio abriu, mas não achei 'List for Trade'. A casa já está à venda?", "aviso")
            return false
        end

        Utils.esperar()
        local ok, metodo = Utils.clicar(botao)
        if ok then
            Utils.setStatus("Casa colocada à venda (" .. tostring(metodo) .. "). Placa FOR TRADE na frente!", "ok")
        else
            Utils.setStatus("Não consegui clicar em 'List for Trade'", "erro")
        end
        return ok
    end

    function Casa.diagnostico()
        local prompt, distancia = Casa.acharCaixaCorreio()
        return {
            caixaCorreio = prompt ~= nil,
            distancia = distancia,
            botaoListar = botaoListar() ~= nil,
        }
    end

    return Casa
end
