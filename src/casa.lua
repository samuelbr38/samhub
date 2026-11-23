return function(App)
    local Config, Utils = App.Config, App.Utils
    local S, E = Config.SAMHUB, Config.Estado
    local Players = game:GetService("Players")
    local PathfindingService = game:GetService("PathfindingService")
    local Eu = Players.LocalPlayer
    local PlayerGui = Eu:WaitForChild("PlayerGui")

    local Casa = {}
    local ocupado = false

    local TECLAS_NUMERO = { "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine" }
    local SO_XZ = Vector3.new(1, 0, 1)

    local function personagem()
        local char = Eu.Character
        local humanoide = char and char:FindFirstChildOfClass("Humanoid")
        local raiz = char and char:FindFirstChild("HumanoidRootPart")
        return humanoide, raiz
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

    local function esperar(fn, segundos)
        local resultado, t = fn(), 0
        while not resultado and t < segundos do
            task.wait(0.25)
            t += 0.25
            resultado = fn()
        end
        return resultado
    end

    local function distanciaXZ(a, b)
        return ((a - b) * SO_XZ).Magnitude
    end

    function Casa.acharPlaca()
        local alvos = {}
        for _, padrao in ipairs(S.PADROES_PLACA_CASA) do
            table.insert(alvos, string.format(padrao, string.lower(Eu.Name)))
            table.insert(alvos, string.format(padrao, string.lower(Eu.DisplayName)))
        end
        for _, raizBusca in ipairs({ PlayerGui, workspace }) do
            for _, d in ipairs(raizBusca:GetDescendants()) do
                if d:IsA("TextLabel") then
                    local texto = Utils.normalizar(d.Text)
                    for _, alvo in ipairs(alvos) do
                        if string.find(texto, alvo, 1, true) then
                            local placa = d:FindFirstAncestorWhichIsA("BillboardGui")
                            local pos = placa and (posicaoDe(placa.Adornee) or posicaoDe(placa.Parent))
                            if pos then return pos end
                        end
                    end
                end
            end
        end
        return nil
    end

    function Casa.acharCaixaCorreio(perto)
        local _, raiz = personagem()
        local origem = perto or (raiz and raiz.Position)
        if not origem then return nil end
        local melhor

        local function considerar(tipo, objeto, posicao)
            if not posicao then return end
            local distancia = (posicao - origem).Magnitude
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

    function Casa.andarAte(destino, perto)
        local humanoide, raiz = personagem()
        if not humanoide or not raiz then return false end
        perto = perto or S.DISTANCIA_PERTO
        if distanciaXZ(raiz.Position, destino) <= perto then return true end

        local alvo = Vector3.new(destino.X, raiz.Position.Y, destino.Z)
        local inicio = os.clock()
        local function tempoAcabou() return os.clock() - inicio > S.TEMPO_MAX_ANDANDO end

        Utils.setStatus(string.format("Andando até a sua caixa de correio (%.0f studs)...", distanciaXZ(raiz.Position, destino)), "espera")

        local pontos
        local caminho = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true })
        local ok = pcall(function() caminho:ComputeAsync(raiz.Position, alvo) end)
        if ok and caminho.Status == Enum.PathStatus.Success then
            pontos = caminho:GetWaypoints()
        else
            pontos = { { Position = alvo, Action = Enum.PathWaypointAction.Walk } }
        end

        for _, ponto in ipairs(pontos) do
            if tempoAcabou() then break end
            if ponto.Action == Enum.PathWaypointAction.Jump then humanoide.Jump = true end
            humanoide:MoveTo(ponto.Position)
            local t = 0
            while t < 4 do
                task.wait(0.1)
                t += 0.1
                if distanciaXZ(raiz.Position, destino) <= perto then
                    humanoide:MoveTo(raiz.Position)
                    return true
                end
                if distanciaXZ(raiz.Position, ponto.Position) < 2.5 then break end
            end
            if t >= 4 then humanoide.Jump = true end
        end

        humanoide:MoveTo(alvo)
        local t = 0
        while distanciaXZ(raiz.Position, destino) > perto and t < 6 and not tempoAcabou() do
            task.wait(0.1)
            t += 0.1
        end
        humanoide:MoveTo(raiz.Position)
        return distanciaXZ(raiz.Position, destino) <= perto + 2
    end

    function Casa.irAteCaixa()
        local _, raiz = personagem()
        if not raiz then return false end
        local placa = Casa.acharPlaca()
        local caixa = Casa.acharCaixaCorreio(placa)
        local destino = (caixa and caixa.posicao) or placa
        if not destino then
            Utils.setStatus("Não achei a placa da sua casa nem a caixa de correio por perto", "aviso")
            return false
        end
        if distanciaXZ(raiz.Position, destino) <= S.DISTANCIA_PERTO then return true end
        if not S.ANDAR_ATE_CAIXA then return false end
        return Casa.andarAte(destino)
    end

    local function botao(textos)
        return Utils.acharBotao(PlayerGui, textos)
    end

    local function menuAberto()
        return botao(S.TEXTO_LISTAR_CASA) or botao(S.TEXTO_DESLISTAR) or botao(S.TEXTO_TROCAR_CASA)
    end

    local function tocarNaCaixa(caixa)
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

    function Casa.abrirMenu()
        if menuAberto() then return true end
        Casa.irAteCaixa()

        Utils.setStatus("Apertando E na caixa de correio...", "espera")
        Utils.apertarTecla(S.TECLA_INTERAGIR)
        if esperar(menuAberto, 2) then return true end

        local botaoE = botao({ "E" })
        if botaoE and Utils.clicar(botaoE) and esperar(menuAberto, 2) then return true end

        local caixa = Casa.acharCaixaCorreio()
        if caixa and tocarNaCaixa(caixa) and esperar(menuAberto, 2.5) then return true end

        Utils.setStatus("Toque na caixa de correio (ou aperte E): eu continuo sozinho", "aviso")
        return esperar(menuAberto, S.ESPERA_CAIXA_CORREIO) ~= nil
    end

    local function apertarItem(item)
        local ok, metodo = Utils.clicar(item)
        if ok then return true, metodo end
        local numero = tonumber(string.match(Utils.limpar(Utils.textoDe(item)), "%((%d)%)%s*$"))
        if numero and TECLAS_NUMERO[numero] then
            Utils.apertarTecla(Enum.KeyCode[TECLAS_NUMERO[numero]])
            task.wait(0.6)
            if not item.Parent or not Utils.naTela(item) then return true, "tecla " .. numero end
        end
        return false, nil
    end

    local function textoDeVenda(texto)
        return Utils.temAlguma(string.lower(texto), S.PALAVRAS_A_VENDA)
    end

    local function conferir()
        if not Casa.abrirMenu() then
            Utils.setStatus("Não consegui abrir a caixa de correio para conferir", "aviso")
            return nil
        end

        local atualAVenda = botao(S.TEXTO_DESLISTAR) ~= nil

        local trocar = botao(S.TEXTO_TROCAR_CASA)
        if trocar then
            apertarItem(trocar)
        else
            Utils.apertarTecla(S.TECLA_TROCAR_CASA)
        end

        local achado = esperar(function()
            local p, l = App.Scanner.acharPainel()
            return l and { p, l } or nil
        end, 4)
        local painel, lista = achado and achado[1], achado and achado[2]
        if not lista then
            local msg = atualAVenda and "A casa atual está à venda (vi Unlist from Trade)" or "Não abriu a lista de casas"
            Utils.setStatus(msg, atualAVenda and "ok" or "aviso")
            return nil
        end

        local casas = App.Scanner.lerCartoes(lista)
        Utils.setStatus("Conferindo " .. #casas .. " casa(s)...", "espera")

        for _, casa in ipairs(casas) do
            if textoDeVenda(Utils.textos(casa.cartao)) then return casa, casas end
        end

        for i, casa in ipairs(casas) do
            Utils.setStatus(string.format("Olhando casa %d de %d: %s", i, #casas, casa.nome), "espera")
            if casa.cartao.Parent and Utils.naTela(casa.cartao) then
                Utils.clicar(casa.cartao, painel)
                task.wait(0.8)
                if botao(S.TEXTO_DESLISTAR) or textoDeVenda(Utils.textos(painel)) then
                    return casa, casas
                end
            end
        end
        return nil, casas
    end

    function Casa.conferirVenda()
        if ocupado then return nil end
        ocupado = true
        local ok, casa, casas = pcall(conferir)
        ocupado = false
        if not ok then
            warn("[SAMHUB] conferir: " .. tostring(casa))
            Utils.setStatus("Erro ao conferir a venda (veja F9)", "erro")
            return nil
        end

        if casas and #casas > 0 then
            E.todasAsCasas = casas
        end
        if casa then
            E.casasSelecionadas = { [casa.nome] = true }
            Utils.setStatus("Casa à venda: " .. casa.nome .. " (marcada na lista)", "ok")
        elseif casas then
            Utils.setStatus("Nenhuma casa mostrou 'Unlist from Trade'", "aviso")
        end
        Utils.EstadoMudou:Fire()
        return casa
    end

    local function listar()
        if not Casa.abrirMenu() then
            Utils.setStatus("A caixa de correio não abriu. Chegue perto dela e aperte E.", "aviso")
            return false
        end

        if botao(S.TEXTO_DESLISTAR) and not botao(S.TEXTO_LISTAR_CASA) then
            Utils.setStatus("Esta casa já está à venda (aparece Unlist from Trade)", "ok")
            return true
        end

        local itemListar = esperar(function() return botao(S.TEXTO_LISTAR_CASA) end, 2)
        if not itemListar then
            Utils.setStatus("O menu abriu, mas não achei List for Trade", "aviso")
            return false
        end

        task.wait(0.3)
        local ok, metodo = apertarItem(itemListar)
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
        if resultado and S.CONFERIR_VENDA then
            task.wait(1.5)
            Casa.conferirVenda()
        end
        return resultado
    end

    function Casa.diagnostico()
        local placa = Casa.acharPlaca()
        local caixa = Casa.acharCaixaCorreio(placa)
        local _, raiz = personagem()
        return {
            placa = placa ~= nil,
            distanciaPlaca = (placa and raiz) and distanciaXZ(raiz.Position, placa) or nil,
            caixaCorreio = caixa ~= nil,
            tipo = caixa and caixa.tipo or nil,
            distancia = (caixa and raiz) and distanciaXZ(raiz.Position, caixa.posicao) or nil,
            menuAberto = menuAberto() ~= nil,
        }
    end

    return Casa
end
