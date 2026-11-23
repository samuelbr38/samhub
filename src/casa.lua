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
    local PALAVRAS_PORTA = { "door", "porta", "entrance", "entrada", "exit" }
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

    local function cframeDe(obj)
        if not obj then return nil end
        if obj:IsA("BasePart") then return obj.CFrame end
        if obj:IsA("Attachment") then return obj.WorldCFrame end
        if obj:IsA("Model") then
            local ok, cf = pcall(obj.GetPivot, obj)
            return ok and cf or nil
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

    local function terrenoDe(obj)
        local terreno, atual = nil, obj
        while atual and atual ~= workspace and atual ~= game do
            if atual:IsA("Model") then terreno = atual end
            atual = atual.Parent
        end
        return terreno
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
                            local peca = placa and (placa.Adornee or placa.Parent)
                            local referencia = cframeDe(peca)
                            if referencia then
                                return {
                                    posicao = referencia:PointToWorldSpace(placa.StudsOffsetWorldSpace),
                                    referencia = referencia,
                                    peca = peca,
                                    placa = placa,
                                    terreno = terrenoDe(peca),
                                }
                            end
                        end
                    end
                end
            end
        end
        return nil
    end

    local function centroDaCasa(placa)
        if not placa then return nil end
        local modelo = placa.peca:IsA("Model") and placa.peca or placa.peca:FindFirstAncestorWhichIsA("Model")
        if modelo then
            local ok, cf, tamanho = pcall(modelo.GetBoundingBox, modelo)
            if ok and cf then
                return cf.Position, math.clamp(math.max(tamanho.X, tamanho.Z) / 2 + 5, 12, 40)
            end
        end
        return placa.referencia.Position, 18
    end

    function Casa.caixasPerto(placa)
        local lista = {}
        if not placa then return lista end
        for _, d in ipairs((placa.terreno or workspace):GetDescendants()) do
            if (d:IsA("Model") or d:IsA("BasePart")) and string.find(string.lower(d.Name), "mail", 1, true) then
                local p = posicaoDe(d)
                if p and (p - placa.referencia.Position).Magnitude < 60 then table.insert(lista, p) end
            end
        end
        return lista
    end

    local function posicaoSalva(placa)
        local o = S.OFFSET_CAIXA
        if not (placa and type(o) == "table" and #o == 3) then return nil end
        return placa.referencia:PointToWorldSpace(Vector3.new(o[1], o[2], o[3]))
    end

    function Casa.salvarPosicaoCaixa()
        local _, raiz = personagem()
        local placa = Casa.acharPlaca()
        if not raiz or not placa then
            Utils.setStatus("Não achei a placa da sua casa para salvar a posição", "erro")
            return false
        end
        local o = placa.referencia:PointToObjectSpace(raiz.Position)
        S.OFFSET_CAIXA = { o.X, o.Y, o.Z }
        if App.salvarAjustes then App.salvarAjustes() end
        Utils.setStatus("Posição da caixa salva! Da próxima vez eu venho direto aqui.", "ok")
        return true
    end

    local candidatosE = {}

    local function registrarE(d)
        if (d:IsA("TextLabel") or d:IsA("TextButton")) and Utils.normalizar(d.Text) == "e" then
            candidatosE[d] = true
        end
    end

    local function coletarE(incluirMundo)
        for _, d in ipairs(PlayerGui:GetDescendants()) do registrarE(d) end
        if incluirMundo then
            for _, d in ipairs(workspace:GetDescendants()) do registrarE(d) end
        end
    end

    local function eDaCaixa(label, conhecidas)
        if not label.Parent then
            candidatosE[label] = nil
            return nil
        end
        local tela = label:FindFirstAncestorWhichIsA("LayerCollector")
        if not tela or not tela.Enabled or not Utils.visivel(label) then return nil end
        local _, raiz = personagem()
        if not raiz then return nil end

        if tela:IsA("BillboardGui") then
            local alvo = tela.Adornee or tela.Parent
            local pos = posicaoDe(alvo)
            if not pos or (pos - raiz.Position).Magnitude > 25 then return nil end
            local caminho = nomesAcima(alvo, 5)
            if Utils.temAlguma(caminho, PALAVRAS_PORTA) then return nil end
            if string.find(caminho, "mail", 1, true) then return pos end
            if #conhecidas == 0 then return pos end
            for _, p in ipairs(conhecidas) do
                if (p - pos).Magnitude < 8 then return pos end
            end
            return nil
        end

        if Utils.naTela(label) then
            if #conhecidas == 0 then return raiz.Position end
            for _, p in ipairs(conhecidas) do
                if distanciaXZ(p, raiz.Position) < 14 then return p end
            end
        end
        return nil
    end

    local function acharE(conhecidas)
        for label in pairs(candidatosE) do
            local ok, pos = pcall(eDaCaixa, label, conhecidas)
            if ok and pos then return label, pos end
        end
        return nil
    end

    function Casa.botaoEVisivel()
        coletarE(false)
        local placa = Casa.acharPlaca()
        local conhecidas = Casa.caixasPerto(placa)
        local salva = posicaoSalva(placa)
        if salva then table.insert(conhecidas, salva) end
        return acharE(conhecidas) ~= nil
    end

    function Casa.andarAte(destino, perto, parar)
        local humanoide, raiz = personagem()
        if not humanoide or not raiz then return false end
        perto = perto or S.DISTANCIA_PERTO
        if distanciaXZ(raiz.Position, destino) <= perto then return true end

        local alvo = Vector3.new(destino.X, raiz.Position.Y, destino.Z)
        local pontos
        local caminho = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true })
        local ok = pcall(function() caminho:ComputeAsync(raiz.Position, alvo) end)
        if ok and caminho.Status == Enum.PathStatus.Success then
            pontos = caminho:GetWaypoints()
        else
            pontos = { { Position = alvo, Action = Enum.PathWaypointAction.Walk } }
        end

        local function deveParar()
            if parar and parar() then
                humanoide:MoveTo(raiz.Position)
                return true
            end
            return false
        end

        for _, ponto in ipairs(pontos) do
            if ponto.Action == Enum.PathWaypointAction.Jump then humanoide.Jump = true end
            humanoide:MoveTo(ponto.Position)
            local t = 0
            while t < 4 do
                task.wait(0.15)
                t += 0.15
                if deveParar() then return true end
                if distanciaXZ(raiz.Position, destino) <= perto then return true end
                if distanciaXZ(raiz.Position, ponto.Position) < 2.5 then break end
            end
            if t >= 4 then humanoide.Jump = true end
        end

        humanoide:MoveTo(alvo)
        local t = 0
        while distanciaXZ(raiz.Position, destino) > perto and t < 5 do
            task.wait(0.15)
            t += 0.15
            if deveParar() then return true end
        end
        return distanciaXZ(raiz.Position, destino) <= perto + 2
    end

    local function pontosEmVolta(centro, raio, origem)
        local pontos = {}
        for i = 0, 11 do
            local angulo = math.rad(i * 30)
            table.insert(pontos, centro + Vector3.new(math.cos(angulo) * raio, 0, math.sin(angulo) * raio))
        end
        local inicio, menor = 1, math.huge
        for i, p in ipairs(pontos) do
            local d = distanciaXZ(p, origem)
            if d < menor then inicio, menor = i, d end
        end
        local ordenados = {}
        for k = 0, #pontos - 1 do
            table.insert(ordenados, pontos[(inicio - 1 + k) % #pontos + 1])
        end
        return ordenados
    end

    function Casa.irAteCaixa()
        local humanoide, raiz = personagem()
        if not raiz then return nil end

        local placa = Casa.acharPlaca()
        local conhecidas = Casa.caixasPerto(placa)
        local salva = posicaoSalva(placa)
        if salva then table.insert(conhecidas, 1, salva) end

        Utils.setStatus("Procurando o botão E da caixa de correio...", "espera")
        candidatosE = {}
        coletarE(true)
        local conexoes = {
            PlayerGui.DescendantAdded:Connect(registrarE),
            workspace.DescendantAdded:Connect(registrarE),
        }
        local function terminar(...)
            for _, c in ipairs(conexoes) do c:Disconnect() end
            return ...
        end

        local achado, posCaixa = acharE(conhecidas)
        if achado then return terminar(achado, posCaixa) end
        if not S.ANDAR_ATE_CAIXA then return terminar(nil) end

        local destinos = {}
        for _, p in ipairs(conhecidas) do table.insert(destinos, p) end
        if placa then table.insert(destinos, placa.posicao) end
        local centro, raio = centroDaCasa(placa)
        if centro then
            for _, p in ipairs(pontosEmVolta(centro, raio, raiz.Position)) do table.insert(destinos, p) end
        end
        if #destinos == 0 then
            Utils.setStatus("Não achei sua casa (a placa com o seu nome)", "aviso")
            return terminar(nil)
        end

        local inicio, ultimaPos, ultimaBusca = os.clock(), raiz.Position, 0
        local entrou = false
        local function parar()
            if (raiz.Position - ultimaPos).Magnitude > 40 then
                entrou = true
                return true
            end
            ultimaPos = raiz.Position
            if os.clock() - ultimaBusca > 1.5 then
                ultimaBusca = os.clock()
                coletarE(false)
            end
            achado, posCaixa = acharE(conhecidas)
            return achado ~= nil or os.clock() - inicio > S.TEMPO_MAX_ANDANDO
        end

        for i, destino in ipairs(destinos) do
            Utils.setStatus(string.format("Andando até aparecer o E da caixa de correio (%d/%d)...", i, #destinos), "espera")
            Casa.andarAte(destino, 3, parar)
            if achado or entrou or os.clock() - inicio > S.TEMPO_MAX_ANDANDO then break end
        end
        if humanoide then humanoide:MoveTo(raiz.Position) end

        if entrou then
            Utils.setStatus("Parece que entrei em algum lugar. Saia, fique do lado da caixa e use 📍 Estou na caixa.", "aviso")
            return terminar(nil)
        end
        return terminar(achado, posCaixa)
    end

    local function botao(textos)
        return Utils.acharBotao(PlayerGui, textos)
    end

    local function menuAberto()
        return botao(S.TEXTO_LISTAR_CASA) or botao(S.TEXTO_DESLISTAR) or botao(S.TEXTO_TROCAR_CASA)
    end

    local function tocarNoMundo(posicao)
        local camera = workspace.CurrentCamera
        if not camera or not posicao then return false end
        local ponto, naFrente = camera:WorldToViewportPoint(posicao)
        if not naFrente then return false end
        return Utils.clicarNaTela(ponto.X, ponto.Y)
    end

    function Casa.abrirMenu()
        if menuAberto() then return true end
        local botaoE, posCaixa = Casa.irAteCaixa()

        if botaoE then
            Utils.setStatus("Achei o E da caixa de correio! Apertando...", "espera")
            Utils.apertarTecla(S.TECLA_INTERAGIR)
            if esperar(menuAberto, 2) then return true end

            local tela = botaoE:FindFirstAncestorWhichIsA("LayerCollector")
            if tela and tela:IsA("ScreenGui") then
                local alvo = botaoE:FindFirstAncestorWhichIsA("GuiButton") or botaoE
                Utils.clicar(alvo)
            else
                tocarNoMundo(posCaixa)
            end
            if esperar(menuAberto, 2) then return true end
        end

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

        if casas and #casas > 0 then E.todasAsCasas = casas end
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
        local _, raiz = personagem()
        local placa = Casa.acharPlaca()
        local salva = posicaoSalva(placa)
        return {
            placa = placa ~= nil,
            distanciaPlaca = (placa and raiz) and distanciaXZ(raiz.Position, placa.posicao) or nil,
            salva = salva ~= nil,
            botaoE = Casa.botaoEVisivel(),
            menuAberto = menuAberto() ~= nil,
        }
    end

    function Casa.mapear()
        local _, raiz = personagem()
        local linhas = {}
        local function add(...) table.insert(linhas, string.format(...)) end
        local function v(p) return p and string.format("(%.1f, %.1f, %.1f)", p.X, p.Y, p.Z) or "nil" end

        add("Você: %s", v(raiz and raiz.Position))
        local placa = Casa.acharPlaca()
        if placa then
            add("Placa: %s presa em %s [%s]", placa.placa:GetFullName(), placa.peca:GetFullName(), placa.peca.ClassName)
            add("  peça em %s · aparece em %s", v(placa.referencia.Position), v(placa.posicao))
            local centro, raio = centroDaCasa(placa)
            add("  centro da casa %s · raio %.0f", v(centro), raio or 0)
        else
            add("Placa: não achei")
        end
        add("Posição salva: %s", S.OFFSET_CAIXA and table.concat(S.OFFSET_CAIXA, ", ") or "nenhuma")

        add("Peças com 'mail' perto da casa:")
        for _, p in ipairs(Casa.caixasPerto(placa)) do add("  %s", v(p)) end

        add("Botões E encontrados:")
        candidatosE = {}
        coletarE(true)
        for label in pairs(candidatosE) do
            local tela = label:FindFirstAncestorWhichIsA("LayerCollector")
            local alvo = tela and tela:IsA("BillboardGui") and (tela.Adornee or tela.Parent)
            add("  %s · tela %s · ligado %s · preso em %s %s", label:GetFullName(),
                tela and tela.ClassName or "?", tostring(tela and tela.Enabled and Utils.visivel(label)),
                alvo and alvo:GetFullName() or "-", v(posicaoDe(alvo)))
        end

        local saida = "===== SAMHUB: MAPA DA CAIXA DE CORREIO =====\n" .. table.concat(linhas, "\n")
        print(saida)
        local copiou = Utils.copiar(saida)
        Utils.salvarTexto("samhub_mapa_caixa.txt", saida)
        Utils.setStatus("Mapa da caixa no F9" .. (copiou and " e copiado" or ""), "info")
    end

    return Casa
end
