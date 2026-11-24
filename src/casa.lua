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

    local function portasDa(placa)
        local lista = {}
        if not placa or not placa.terreno then return lista end
        for _, d in ipairs(placa.terreno:GetDescendants()) do
            if (d:IsA("BasePart") or d:IsA("Model")) and Utils.temAlguma(string.lower(d.Name), PALAVRAS_PORTA) then
                local p = posicaoDe(d)
                if p then table.insert(lista, p) end
            end
        end
        return lista
    end

    local tipoAtual = nil

    local function modeloDaCasa(placa)
        if not placa or not placa.peca then return nil end
        local melhor, tamanhoMelhor, maiorLado = nil, nil, 0
        local atual = placa.peca
        while atual and atual ~= workspace and atual ~= game do
            if atual:IsA("Model") then
                local ok, _, tamanho = pcall(atual.GetBoundingBox, atual)
                if ok and tamanho then
                    local lado = math.max(tamanho.X, tamanho.Z)
                    if lado <= 250 and lado > maiorLado then
                        melhor, tamanhoMelhor, maiorLado = atual, tamanho, lado
                    end
                end
            end
            atual = atual.Parent
        end
        return melhor, tamanhoMelhor
    end

    local function chaveDaCasa(placa)
        local _, tamanho = modeloDaCasa(placa)
        if not tamanho then return "padrao" end
        local function arredondar(v) return math.floor(v / 6 + 0.5) * 6 end
        local a, b = arredondar(tamanho.X), arredondar(tamanho.Z)
        return string.format("%dx%d", math.max(a, b), math.min(a, b))
    end

    local function assinaturaDe(obj)
        local pai = obj.Parent
        local avo = pai and pai.Parent
        return {
            nome = obj.Name,
            classe = obj.ClassName,
            pai = pai and pai.Name or "",
            avo = avo and avo.Name or "",
        }
    end

    local function bateAssinatura(obj, a)
        if obj.Name ~= a.nome or obj.ClassName ~= a.classe then return false end
        local pai = obj.Parent
        if (pai and pai.Name or "") ~= a.pai then return false end
        local avo = pai and pai.Parent
        return (avo and avo.Name or "") == a.avo
    end

    function Casa.acharCaixaPorObjeto(placa)
        local a = S.CAIXA_OBJETO
        if type(a) ~= "table" or type(a.nome) ~= "string" or not placa then return nil end
        local centro = placa.referencia.Position
        local melhor, menor = nil, S.DISTANCIA_CAIXA_CORREIO
        local modelo = modeloDaCasa(placa)
        for _, lugar in ipairs({ modelo or false, workspace }) do
            if lugar then
                for _, d in ipairs(lugar:GetDescendants()) do
                    if bateAssinatura(d, a) then
                        local p = posicaoDe(d)
                        if p and (p - centro).Magnitude < menor then melhor, menor = d, (p - centro).Magnitude end
                    end
                end
                if melhor then break end
            end
        end
        return melhor and posicaoDe(melhor), melhor
    end

    local function aprenderObjeto(obj)
        if not obj or not obj.Parent then return end
        if Utils.temAlguma(nomesAcima(obj, 4), PALAVRAS_PORTA) then return end
        local nova = assinaturaDe(obj)
        local velha = S.CAIXA_OBJETO
        if type(velha) == "table" and velha.nome == nova.nome and velha.pai == nova.pai and velha.avo == nova.avo then
            return
        end
        S.CAIXA_OBJETO = nova
        if App.salvarAjustes then App.salvarAjustes() end
        Utils.setStatus("Aprendi qual é a caixa de correio ('" .. nova.nome .. "'). Agora acho ela em qualquer casa! 📮", "ok")
    end

    local function aprendidaPara(chave)
        local o = S.CAIXAS[chave]
        if type(o) == "table" and type(o.x) == "number" then return o end
        local a1, b1 = string.match(chave, "^(%d+)x(%d+)$")
        a1, b1 = tonumber(a1), tonumber(b1)
        if not a1 then return nil end
        local melhor, menor = nil, 13
        for outra, valor in pairs(S.CAIXAS) do
            local a2, b2 = string.match(outra, "^(%d+)x(%d+)$")
            a2, b2 = tonumber(a2), tonumber(b2)
            if a2 and type(valor) == "table" and type(valor.x) == "number" then
                local diferenca = math.abs(a1 - a2) + math.abs(b1 - b2)
                if diferenca < menor then melhor, menor = valor, diferenca end
            end
        end
        return melhor
    end

    local function posicaoSalva(placa)
        if not placa or type(S.CAIXAS) ~= "table" then return nil end
        local o = aprendidaPara(chaveDaCasa(placa))
        if not o then return nil end
        return placa.referencia:PointToWorldSpace(Vector3.new(o.x, o.y, o.z))
    end

    local function guardarPosicao(placa, raiz)
        if type(S.CAIXAS) ~= "table" then S.CAIXAS = {} end
        local o = placa.referencia:PointToObjectSpace(raiz.Position)
        S.CAIXAS[chaveDaCasa(placa)] = { x = o.X, y = o.Y, z = o.Z, tipo = tipoAtual }
        if App.salvarAjustes then App.salvarAjustes() end
    end

    local function candidatosMail(placa)
        local lista = {}
        if not placa then return lista end
        local centro = placa.referencia.Position
        local vistos = {}
        for _, d in ipairs((modeloDaCasa(placa) or placa.terreno or workspace):GetDescendants()) do
            if (d:IsA("Model") or d:IsA("BasePart")) and string.find(string.lower(d.Name), "mail", 1, true)
                and not Utils.temAlguma(nomesAcima(d, 4), PALAVRAS_PORTA) then
                local topo = d
                while topo.Parent and topo.Parent ~= workspace and string.find(string.lower(topo.Parent.Name), "mail", 1, true) do
                    topo = topo.Parent
                end
                if not vistos[topo] then
                    vistos[topo] = true
                    local p = posicaoDe(topo)
                    if p and (p - centro).Magnitude < S.DISTANCIA_CAIXA_CORREIO then
                        table.insert(lista, { obj = topo, pos = p })
                    end
                end
            end
        end
        return lista
    end

    function Casa.caixasPerto(placa)
        local posicoes = {}
        for _, c in ipairs(candidatosMail(placa)) do table.insert(posicoes, c.pos) end
        return posicoes
    end

    function Casa.esquecerCaixas()
        S.CAIXAS = {}
        S.CAIXA_OBJETO = nil
        if App.salvarAjustes then App.salvarAjustes() end
        Utils.setStatus("Esqueci a caixa de correio. Vou procurar sozinho de novo.", "info")
    end

    local function botao(textos)
        return Utils.acharBotao(PlayerGui, textos)
    end

    local TEXTOS_MENU_CAIXA = {}
    for _, t in ipairs(S.TEXTO_LISTAR_CASA) do table.insert(TEXTOS_MENU_CAIXA, t) end
    for _, t in ipairs(S.TEXTO_DESLISTAR) do table.insert(TEXTOS_MENU_CAIXA, t) end

    local function menuDaCaixa()
        return botao(TEXTOS_MENU_CAIXA) and botao(S.TEXTO_MENU_CAIXA_EXTRA)
    end

    local function menuAberto()
        return menuDaCaixa() or botao(S.TEXTO_TROCAR_CASA)
    end

    local placaGuardada, placaHora = nil, 0
    local function placaRapida()
        if os.clock() - placaHora > 20 or not (placaGuardada and placaGuardada.peca.Parent) then
            placaGuardada, placaHora = Casa.acharPlaca(), os.clock()
        end
        return placaGuardada
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

    local function alvoDoE(label)
        if not label.Parent then
            candidatosE[label] = nil
            return nil
        end
        local tela = label:FindFirstAncestorWhichIsA("LayerCollector")
        if not tela or not tela:IsA("BillboardGui") or not tela.Enabled or not Utils.visivel(label) then return nil end
        local _, raiz = personagem()
        local alvo = tela.Adornee or tela.Parent
        local pos = posicaoDe(alvo)
        if not raiz or not pos or (pos - raiz.Position).Magnitude > 20 then return nil end
        if Utils.temAlguma(nomesAcima(alvo, 5), PALAVRAS_PORTA) then return nil end
        return alvo, pos
    end

    local function acharE(esperado)
        local a = S.CAIXA_OBJETO
        for label in pairs(candidatosE) do
            local ok, alvo, pos = pcall(alvoDoE, label)
            if ok and alvo then
                local caminho = nomesAcima(alvo, 5)
                if string.find(caminho, "mail", 1, true)
                    or (type(a) == "table" and bateAssinatura(alvo, a))
                    or (esperado and distanciaXZ(pos, esperado) < 7) then
                    return label, pos, alvo
                end
            end
        end
        return nil
    end

    function Casa.botaoEVisivel()
        coletarE(false)
        local placa = placaRapida()
        local esperado = Casa.acharCaixaPorObjeto(placa) or posicaoSalva(placa)
        return acharE(esperado) ~= nil
    end

    local ultimoAlvo = nil

    local function aprenderSeAberto()
        if not menuDaCaixa() then return end
        local _, raiz = personagem()
        local placa = placaRapida()
        if not raiz or not placa then return end

        local obj = ultimoAlvo and os.clock() - ultimoAlvo.hora < 15 and ultimoAlvo.obj.Parent and ultimoAlvo.obj
        if not obj then
            local menor = 12
            for _, c in ipairs(candidatosMail(placa)) do
                local d = distanciaXZ(c.pos, raiz.Position)
                if d < menor then obj, menor = c.obj, d end
            end
        end
        if obj then aprenderObjeto(obj) end

        local atual = posicaoSalva(placa)
        if not atual or distanciaXZ(atual, raiz.Position) > 3 then guardarPosicao(placa, raiz) end
    end

    local vigiando = false
    local conexoesVigia = {}

    function Casa.iniciarVigia()
        if vigiando then return end
        vigiando = true
        table.insert(conexoesVigia, PlayerGui.DescendantAdded:Connect(registrarE))
        coletarE(false)
        task.spawn(function()
            local ultimaColeta = os.clock()
            while vigiando do
                task.wait(0.4)
                pcall(function()
                    if menuDaCaixa() then
                        aprenderSeAberto()
                    else
                        for label in pairs(candidatosE) do
                            local alvo = alvoDoE(label)
                            if alvo then
                                ultimoAlvo = { obj = alvo, hora = os.clock() }
                                break
                            end
                        end
                    end
                    if os.clock() - ultimaColeta > 4 then
                        ultimaColeta = os.clock()
                        coletarE(false)
                    end
                    if os.clock() - Utils.ultimoClique < 12 then
                        Utils.cancelarDialogoPerigoso()
                    end
                end)
            end
        end)
    end

    function Casa.pararVigia()
        vigiando = false
        for _, c in ipairs(conexoesVigia) do c:Disconnect() end
        conexoesVigia = {}
    end

    function Casa.salvarPosicaoCaixa()
        local _, raiz = personagem()
        local placa = Casa.acharPlaca()
        if not raiz or not placa then
            Utils.setStatus("Não achei a placa da sua casa para salvar a posição", "erro")
            return false
        end
        guardarPosicao(placa, raiz)
        local menor, obj = 12, nil
        for _, c in ipairs(candidatosMail(placa)) do
            local d = distanciaXZ(c.pos, raiz.Position)
            if d < menor then obj, menor = c.obj, d end
        end
        if obj then aprenderObjeto(obj) else Utils.setStatus("Posição da caixa salva para esse tamanho de casa", "ok") end
        return true
    end

    function Casa.andarAte(destino, portas, perto, parar)
        local humanoide, raiz = personagem()
        if not humanoide or not raiz then return false, "sem personagem" end
        perto = perto or 2.5
        local alvo = Vector3.new(destino.X, raiz.Position.Y, destino.Z)
        local inicio, ultimaPos, parado, ultimoComando = os.clock(), raiz.Position, 0, os.clock()
        humanoide:MoveTo(alvo)

        while distanciaXZ(raiz.Position, destino) > perto do
            task.wait(0.15)
            if parar and parar() then
                humanoide:MoveTo(raiz.Position)
                return true, "parou"
            end
            if (raiz.Position - ultimaPos).Magnitude > 40 then return false, "teleporte" end
            for _, p in ipairs(portas or {}) do
                if distanciaXZ(raiz.Position, p) < 5 and distanciaXZ(destino, p) >= 5 then
                    humanoide:MoveTo(raiz.Position)
                    return false, "porta"
                end
            end
            if (raiz.Position - ultimaPos).Magnitude < 0.2 then parado += 0.15 else parado = 0 end
            ultimaPos = raiz.Position
            if parado > 1 or os.clock() - ultimoComando > 5 then
                if parado > 1 then humanoide.Jump = true end
                humanoide:MoveTo(alvo)
                parado, ultimoComando = 0, os.clock()
            end
            if os.clock() - inicio > S.TEMPO_MAX_ANDANDO then
                humanoide:MoveTo(raiz.Position)
                return false, "tempo"
            end
        end
        humanoide:MoveTo(raiz.Position)
        return true
    end

    local MENSAGENS_ANDAR = {
        porta = "Parei: ia passar perto da porta.",
        teleporte = "Fui teleportado (entrei em algum lugar?). Volte para a frente da casa.",
        tempo = "Demorei demais para chegar na caixa de correio.",
    }

    local function longeDePorta(portas)
        local _, raiz = personagem()
        if not raiz then return false end
        for _, p in ipairs(portas) do
            if distanciaXZ(raiz.Position, p) < 8 then return false end
        end
        return true
    end

    function Casa.irAteCaixa()
        local _, raiz = personagem()
        if not raiz then return nil, "Personagem não carregou" end
        local placa = Casa.acharPlaca()
        placaGuardada, placaHora = placa, os.clock()
        if not placa then return nil, "Não achei a sua casa (a placa com o seu nome)" end

        local destinos = {}
        local function adicionar(pos, confiavel, nome)
            if not pos then return end
            for _, d in ipairs(destinos) do
                if distanciaXZ(d.pos, pos) < 4 then return end
            end
            table.insert(destinos, { pos = pos, confiavel = confiavel, nome = nome })
        end
        adicionar(Casa.acharCaixaPorObjeto(placa), true, "caixa aprendida")
        adicionar(posicaoSalva(placa), true, "lugar aprendido")
        local candidatos = candidatosMail(placa)
        table.sort(candidatos, function(a, b)
            return distanciaXZ(a.pos, raiz.Position) < distanciaXZ(b.pos, raiz.Position)
        end)
        for i = 1, math.min(#candidatos, S.MAX_CANDIDATOS_CAIXA) do
            adicionar(candidatos[i].pos, false, "procurando (" .. candidatos[i].obj.Name .. ")")
        end

        candidatosE = {}
        coletarE(true)
        for _, d in ipairs(destinos) do
            local e, pos = acharE(d.pos)
            if e then return e, pos, true end
        end
        if #destinos == 0 then
            return nil, "Não achei a caixa de correio sozinho. Toque nela UMA vez: eu aprendo para sempre 📮"
        end
        if not S.ANDAR_ATE_CAIXA then return nil, "Vá até a sua caixa de correio" end

        local portas = portasDa(placa)
        for _, d in ipairs(destinos) do
            local distancia = distanciaXZ(raiz.Position, d.pos)
            if distancia > S.DISTANCIA_MAX_ANDAR then
                return nil, string.format("Você está longe da sua casa (%.0f studs). Chegue mais perto.", distancia)
            end
            Utils.setStatus(string.format("Indo até a caixa de correio: %s (%.0f studs)...", d.nome, distancia), "espera")

            local achado, posE
            local ultimaColeta = 0
            local ok, motivo = Casa.andarAte(d.pos, portas, 4, function()
                if os.clock() - ultimaColeta > 1 then
                    ultimaColeta = os.clock()
                    coletarE(false)
                end
                achado, posE = acharE(d.pos)
                return achado ~= nil
            end)
            if achado then return achado, posE, true end
            if not ok and (motivo == "teleporte" or motivo == "porta") then
                return nil, MENSAGENS_ANDAR[motivo]
            end
            if ok and d.confiavel and longeDePorta(portas) then return nil, d.pos, true end
        end
        return nil, "Não achei a caixa de correio sozinho. Toque nela UMA vez: eu aprendo para sempre 📮"
    end

    local function tocarNoMundo(posicao)
        local camera = workspace.CurrentCamera
        if not camera or not posicao then return false end
        local ponto, naFrente = camera:WorldToViewportPoint(posicao)
        if not naFrente then return false end
        return Utils.clicarNaTela(ponto.X, ponto.Y)
    end

    function Casa.abrirMenu(espera)
        if menuAberto() then
            aprenderSeAberto()
            return true
        end

        local e, info, confiavel = Casa.irAteCaixa()
        if e then
            local ok, alvo = pcall(alvoDoE, e)
            if ok and alvo then ultimoAlvo = { obj = alvo, hora = os.clock() } end
        end

        if e or confiavel then
            Utils.setStatus("Apertando E na caixa de correio...", "espera")
            Utils.apertarTecla(S.TECLA_INTERAGIR)
            if esperar(menuAberto, 2) then
                aprenderSeAberto()
                return true
            end
            if e then
                local tela = e:FindFirstAncestorWhichIsA("LayerCollector")
                if tela and tela:IsA("ScreenGui") then
                    Utils.clicar(e:FindFirstAncestorWhichIsA("GuiButton") or e)
                elseif typeof(info) == "Vector3" then
                    tocarNoMundo(info)
                end
                if esperar(menuAberto, 2) then
                    aprenderSeAberto()
                    return true
                end
            end
        end

        Utils.setStatus((type(info) == "string" and info) or "Toque na sua caixa de correio: eu continuo sozinho", "aviso")
        local abriu = esperar(menuAberto, espera or S.ESPERA_CAIXA_CORREIO) ~= nil
        if abriu then aprenderSeAberto() end
        return abriu
    end

    local function apertarItem(item)
        local numero = tonumber(string.match(Utils.limpar(Utils.textoDe(item)), "%((%d)%)%s*$"))
        if numero and TECLAS_NUMERO[numero] then
            local tela = item:FindFirstAncestorWhichIsA("LayerCollector")
            local antes = tela and Utils.assinatura(tela)
            Utils.apertarTecla(Enum.KeyCode[TECLAS_NUMERO[numero]])
            local mudou = esperar(function()
                return not item.Parent or not Utils.naTela(item) or (tela ~= nil and Utils.assinatura(tela) ~= antes)
            end, 1.2)
            if mudou then return true, "tecla " .. numero end
        end
        return Utils.clicar(item)
    end

    local function confirmarDialogo(segundos, palavras)
        palavras = palavras or { "trade", "list" }
        local alvos = {}
        for _, t in ipairs(S.CONFIRMAR_LISTAGEM) do alvos[Utils.normalizar(t)] = true end
        local function achar()
            for _, d in ipairs(PlayerGui:GetDescendants()) do
                if (d:IsA("TextLabel") or d:IsA("TextButton")) and alvos[Utils.normalizar(d.Text)] and Utils.naTela(d) then
                    local botaoConfirmar = d:IsA("TextButton") and d or d:FindFirstAncestorWhichIsA("GuiButton")
                    local quadro = botaoConfirmar and botaoConfirmar.Parent
                    for _ = 1, 6 do
                        if not quadro or quadro:IsA("LayerCollector") then break end
                        if Utils.temAlguma(string.lower(Utils.textos(quadro)), palavras) then
                            return { botaoConfirmar, quadro }
                        end
                        quadro = quadro.Parent
                    end
                end
            end
            return nil
        end
        local achado = esperar(achar, segundos or 2.5)
        if not achado then return false end
        local botaoConfirmar, quadro = achado[1], achado[2]
        local proibida = Utils.temPerigo(Utils.textos(quadro))
        if proibida then
            Utils.aviso("não confirmei (" .. proibida .. "): " .. Utils.textos(quadro))
            Utils.cancelarDialogoPerigoso()
            Utils.setStatus("Apareceu uma janela de '" .. proibida .. "'. NÃO confirmei e cancelei.", "erro")
            return false
        end
        Utils.setStatus("Confirmando...", "espera")
        return Utils.clicar(botaoConfirmar, quadro)
    end

    local function vendaNaTela(painel)
        if botao(S.TEXTO_DESLISTAR) then return true end
        local t = string.lower(Utils.textos(painel))
        return string.find(t, "listed for trade", 1, true) ~= nil
    end

    local function corDe(obj)
        local partes = {}
        local function anotar(o)
            if (o:IsA("ImageButton") or o:IsA("ImageLabel")) and o.Image ~= "" and o.ImageTransparency < 1 then
                table.insert(partes, tostring(o.ImageColor3))
            end
            if o:IsA("GuiObject") and not o:IsA("TextLabel") and o.BackgroundTransparency < 1 then
                table.insert(partes, tostring(o.BackgroundColor3))
            end
        end
        anotar(obj)
        for _, d in ipairs(obj:GetDescendants()) do
            if d:IsA("GuiObject") and Utils.visivel(d) then anotar(d) end
        end
        return table.concat(partes, "|")
    end

    local function selecionada(casas)
        if #casas == 0 or not casas[1].cartao.Parent then return nil end
        local contagem, cores = {}, {}
        for _, filho in ipairs(casas[1].cartao.Parent:GetChildren()) do
            if filho:IsA("GuiObject") and filho.Visible then
                local c = corDe(filho)
                cores[filho] = c
                contagem[c] = (contagem[c] or 0) + 1
            end
        end
        local unica
        for _, casa in ipairs(casas) do
            if contagem[cores[casa.cartao] or ""] == 1 then
                if unica then return nil end
                unica = casa
            end
        end
        return unica
    end

    local function painelAberto(painel)
        return painel and painel.Parent ~= nil and Utils.naTela(painel)
    end

    local function botaoNoCanto(painel)
        local pos, tam = painel.AbsolutePosition, painel.AbsoluteSize
        local canto = Vector2.new(pos.X + tam.X, pos.Y)
        local melhor, menor = nil, math.huge
        for _, d in ipairs(painel:GetDescendants()) do
            if d:IsA("GuiButton") and Utils.naTela(d) then
                local texto = Utils.normalizar(Utils.textoDe(d))
                if texto == "" or texto == "x" then
                    local centro = d.AbsolutePosition + d.AbsoluteSize / 2
                    local perto = (canto.X - centro.X) < tam.X * 0.15 and (centro.Y - canto.Y) < tam.Y * 0.15
                    local distancia = (centro - canto).Magnitude
                    if perto and distancia < menor then melhor, menor = d, distancia end
                end
            end
        end
        return melhor
    end

    local function fecharPainel(painel)
        for _ = 1, 3 do
            if not painelAberto(painel) then return true end
            local x = Utils.acharBotao(painel, { "X", "✕", "×", "Close", "Fechar" }, { "close", "exit", "fechar", "xbutton" })
                or botaoNoCanto(painel)
            if not x then break end
            Utils.clicar(x, painel)
            esperar(function() return not painelAberto(painel) end, 1.5)
        end
        if painelAberto(painel) then
            Utils.aviso("não consegui fechar o painel " .. painel:GetFullName())
            return false
        end
        return true
    end

    local function abrirListaHomes()
        local painel, lista = App.Scanner.acharPainel()
        if not lista then
            if not Casa.abrirMenu() then
                Utils.setStatus("Não consegui abrir a caixa de correio", "aviso")
                return nil
            end
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
            painel, lista = achado and achado[1], achado and achado[2]
        end
        if not lista then
            Utils.setStatus("A lista HOMES não abriu", "aviso")
            return nil
        end
        local casas = App.Scanner.lerCartoes(lista)
        if #casas == 0 then
            Utils.setStatus("Não achei as casinhas na lista HOMES", "aviso")
            return nil
        end
        task.wait(0.4)
        return painel, lista, casas
    end

    local function alvoDe(nome)
        for _, c in ipairs(E.todasAsCasas) do
            if c.nome == nome then
                return { nome = c.nome, nomeOriginal = c.nomeOriginal or c.nome, tipo = c.tipoCasa }
            end
        end
        return { nome = nome, nomeOriginal = (string.gsub(nome, "%s*%(%d+%)$", "")), tipo = nil }
    end

    local function candidatasDe(casas, alvo)
        local base = Utils.normalizar(alvo.nomeOriginal or alvo.nome)
        local lista = {}
        for _, c in ipairs(casas) do
            if Utils.normalizar(c.nomeOriginal or c.nome) == base then table.insert(lista, c) end
        end
        return lista
    end

    local function escolherNoPainel(painel, casas, casa)
        if selecionada(casas) == casa then return end
        local antes = Utils.assinatura(painel)
        Utils.clicar(casa.cartao, painel)
        esperar(function() return Utils.assinatura(painel) ~= antes end, 1.5)
        task.wait(0.3)
    end

    local function casaMarcada()
        for nome in pairs(E.casasSelecionadas) do return nome end
        return nil
    end

    local function verificarCasa(alvo)
        local painel, _, casas = abrirListaHomes()
        if not painel then return nil end
        local candidatas = candidatasDe(casas, alvo)
        if #candidatas == 0 then
            fecharPainel(painel)
            return nil, casas
        end
        local aVenda = false
        for _, casa in ipairs(candidatas) do
            escolherNoPainel(painel, casas, casa)
            if vendaNaTela(painel) then
                aVenda = true
                break
            end
        end
        fecharPainel(painel)
        return aVenda, casas
    end

    local function descobrirAVenda()
        local painel, _, casas = abrirListaHomes()
        if not painel then return nil end

        local atual = selecionada(casas)
        if atual and vendaNaTela(painel) then
            fecharPainel(painel)
            return atual, casas
        end
        for i, casa in ipairs(casas) do
            Utils.setStatus(string.format("Olhando casa %d de %d: %s", i, #casas, casa.nome), "espera")
            if casa.cartao.Parent and Utils.naTela(casa.cartao) then
                escolherNoPainel(painel, casas, casa)
                if vendaNaTela(painel) then
                    local agora = selecionada(casas)
                    if agora == nil or agora == casa then
                        fecharPainel(painel)
                        return casa, casas
                    end
                end
            end
        end
        fecharPainel(painel)
        return nil, casas
    end

    function Casa.conferirVenda()
        if ocupado then return nil end
        ocupado = true
        local alvo = casaMarcada()
        local ok, a, b
        if alvo then
            Utils.trabalhando()
            ok, a, b = pcall(verificarCasa, alvoDe(alvo))
        else
            Utils.trabalhando()
            ok, a, b = pcall(descobrirAVenda)
        end
        ocupado = false
        if not ok then
            Utils.aviso("conferir: " .. tostring(a))
            Utils.setStatus("Erro ao conferir a venda (veja Registro)", "erro")
            return nil
        end

        local casas = b
        if casas and #casas > 0 and not alvo then E.todasAsCasas = casas end

        if alvo then
            if a == true then
                Utils.setStatus("'" .. alvo .. "' está à venda ✅", "ok")
            elseif a == false then
                Utils.setStatus("'" .. alvo .. "' NÃO está à venda", "erro")
            else
                Utils.setStatus("Não achei '" .. alvo .. "' na lista HOMES", "aviso")
            end
            return a
        end

        if a then
            E.casasSelecionadas = { [a.nome] = true }
            Utils.setStatus("Casa à venda: " .. a.nome .. " (marcada na lista)", "ok")
        elseif casas then
            Utils.setStatus("Nenhuma casa mostrou 'Unlist from Trade'", "aviso")
        end
        Utils.EstadoMudou:Fire()
        return a
    end

    local function listarCasaAtual(espera)
        if not Casa.abrirMenu(espera) then
            Utils.setStatus("A caixa de correio não abriu. Chegue perto dela e aperte E.", "aviso")
            return false
        end

        if botao(S.TEXTO_DESLISTAR) and not botao(S.TEXTO_LISTAR_CASA) then
            Utils.setStatus("A casa atual já está à venda (aparece Unlist from Trade)", "ok")
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
            confirmarDialogo(2.5)
            Utils.setStatus("Casa atual à venda (" .. tostring(metodo) .. ")", "ok")
        else
            Utils.aviso(string.format("List for Trade não respondeu: %s [%s] texto=%q",
                itemListar:GetFullName(), itemListar.ClassName, Utils.textoDe(itemListar)))
            Utils.setStatus("Achei o List for Trade, mas nem a tecla nem o clique funcionaram (veja Registro)", "erro")
        end
        return ok
    end

    local function localizarCasa(painel, lista, casas, alvo)
        local candidatas = candidatasDe(casas, alvo)
        if #candidatas == 0 then return nil end
        if not alvo.tipo then
            local ordem = tonumber(string.match(alvo.nome, "%((%d+)%)%s*$")) or 1
            return candidatas[ordem]
        end
        local jaAVenda
        for _, c in ipairs(candidatas) do
            escolherNoPainel(painel, casas, c)
            local lido = App.Scanner.lerTipo(painel, lista, c.nomeOriginal)
            if lido and Utils.normalizar(lido) == Utils.normalizar(alvo.tipo) then return c, lido end
            if not lido and vendaNaTela(painel) then jaAVenda = jaAVenda or c end
        end
        return jaAVenda
    end

    local function pertoDaCasa()
        local _, raiz = personagem()
        local placa = Casa.acharPlaca()
        if not raiz or not placa then return false end
        return (raiz.Position - placa.posicao).Magnitude <= S.DISTANCIA_MAX_ANDAR
    end

    local function prepararCasa(alvo)
        local painel, lista, casas = abrirListaHomes()
        if not painel then return false end

        Utils.setStatus("Procurando a casa '" .. alvo.nome .. "'" .. (alvo.tipo and (" (" .. alvo.tipo .. ")") or "") .. "...", "espera")
        local casa, lido = localizarCasa(painel, lista, casas, alvo)
        if not casa then
            local nomes = {}
            for _, c in ipairs(casas) do table.insert(nomes, c.nome) end
            Utils.setStatus("Não achei '" .. alvo.nome .. "'" .. (alvo.tipo and (" (" .. alvo.tipo .. ")") or "")
                .. " na lista HOMES (tem: " .. table.concat(nomes, ", ") .. ")", "erro")
            fecharPainel(painel)
            return false
        end
        escolherNoPainel(painel, casas, casa)
        tipoAtual = lido or alvo.tipo or tipoAtual

        if vendaNaTela(painel) then
            fecharPainel(painel)
            Utils.setStatus("'" .. casa.nome .. "' já está à venda ✅", "ok")
            return true
        end

        local listarAqui = Utils.acharBotao(painel, S.TEXTO_LISTAR_CASA)
        if listarAqui and Utils.clicar(listarAqui, painel) then
            confirmarDialogo(2.5)
            if esperar(function() return vendaNaTela(painel) end, 3) then
                fecharPainel(painel)
                Utils.setStatus("'" .. casa.nome .. "' à venda ✅", "ok")
                return true
            end
        end

        local mudar = Utils.acharBotao(painel, S.TEXTO_MUDAR_PARA_CASA)
        if mudar then
            Utils.setStatus("Indo para a casa '" .. casa.nome .. "' (Go!)...", "espera")
            local _, raiz = personagem()
            local antes = raiz and raiz.Position
            local placaAntes = Casa.acharPlaca()
            local modeloAntes = modeloDaCasa(placaAntes)
            local chaveAntes = chaveDaCasa(placaAntes)

            local ultimaBusca, resposta = 0, false
            local function trocou()
                if resposta then return true end
                local _, r = personagem()
                if r and antes and (r.Position - antes).Magnitude > 15 then resposta = true end
                if modeloAntes and not modeloAntes.Parent then resposta = true end
                if not resposta and os.clock() - ultimaBusca > 1 then
                    ultimaBusca = os.clock()
                    local placa = Casa.acharPlaca()
                    if placa and (modeloDaCasa(placa) ~= modeloAntes or chaveDaCasa(placa) ~= chaveAntes) then
                        resposta = true
                    end
                end
                return resposta
            end

            local apertou = Utils.clicar(mudar, painel, trocou, 4)
            task.wait(0.4)
            if Utils.cancelarDialogoPerigoso() then
                Utils.setStatus("Algo deu errado no Go! (apareceu janela de vender). Cancelei e parei.", "erro")
                return false
            end
            confirmarDialogo(1.5, { "move", "change", "go to" })
            if not apertou then esperar(trocou, 2) end
            if Utils.cancelarDialogoPerigoso() then
                Utils.setStatus("Apareceu janela de vender depois do Go!. Cancelei e parei.", "erro")
                return false
            end

            task.wait(0.8)
            fecharPainel(painel)
            placaGuardada = nil
            if trocou() then
                Utils.setStatus("Casa trocada para '" .. casa.nome .. "'. Indo pôr à venda...", "espera")
            else
                Utils.setStatus("'" .. casa.nome .. "' já parece ser a casa atual. Indo pôr à venda...", "espera")
            end
            return "mudou"
        end

        App.Mapeador.mapearObjeto(painel, "PAINEL HOMES (" .. casa.nome .. ")", "samhub_mapa_homes.txt")
        Utils.setStatus("Não achei como colocar '" .. casa.nome .. "' à venda nesse painel. Mapa copiado: me mande.", "erro")
        fecharPainel(painel)
        return false
    end

    local function listar(pedido)
        local alvo
        if pedido then
            alvo = { nome = pedido.casa, nomeOriginal = pedido.nomeOriginal or pedido.casa, tipo = pedido.tipo }
        else
            local marcada = casaMarcada()
            if not marcada then
                Utils.setStatus("Marque na lista qual casa vai vender", "aviso")
                return false
            end
            alvo = alvoDe(marcada)
        end
        local nomeAlvo = alvo.nome

        local resultado = prepararCasa(alvo)
        if resultado == true then return true end
        if resultado ~= "mudou" then return false end

        task.wait(1)
        placaGuardada = nil
        if not pertoDaCasa() then
            Utils.setStatus("Fui para '" .. nomeAlvo .. "', mas estou longe da casa. Toque na caixa de correio: eu continuo sozinho 📮", "aviso")
        end

        if not listarCasaAtual(S.ESPERA_SAIR_CASA) then return false end

        if not S.CONFERIR_VENDA then return true end
        task.wait(1.5)
        local aVenda = verificarCasa(alvo)
        if aVenda == true then
            Utils.setStatus("'" .. nomeAlvo .. "' à venda ✅", "ok")
            return true
        end
        Utils.setStatus("Listei, mas '" .. nomeAlvo .. "' não aparece como à venda. Confira na lista HOMES.", "erro")
        return false
    end

    function Casa.listarParaTroca(pedido)
        if ocupado then return false end
        ocupado = true
        Utils.trabalhando()
        local ok, resultado = pcall(listar, pedido)
        ocupado = false
        if not ok then
            Utils.aviso("casa: " .. tostring(resultado))
            Utils.setStatus("Erro ao colocar a casa à venda (veja Registro)", "erro")
            return false
        end
        return resultado
    end

    function Casa.diagnostico()
        local _, raiz = personagem()
        local placa = placaRapida()
        local salva = posicaoSalva(placa)
        local posObj = Casa.acharCaixaPorObjeto(placa)
        local tamanhos = 0
        for _ in pairs(type(S.CAIXAS) == "table" and S.CAIXAS or {}) do tamanhos += 1 end
        return {
            objeto = posObj ~= nil,
            distanciaObjeto = (posObj and raiz) and distanciaXZ(raiz.Position, posObj) or nil,
            candidatos = #candidatosMail(placa),
            placa = placa ~= nil,
            distanciaPlaca = (placa and raiz) and distanciaXZ(raiz.Position, placa.posicao) or nil,
            chave = placa and chaveDaCasa(placa) or nil,
            tamanhos = tamanhos,
            salva = salva ~= nil,
            distanciaSalva = (salva and raiz) and distanciaXZ(raiz.Position, salva) or nil,
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
            local modelo = modeloDaCasa(placa)
            add("  modelo da casa: %s", modelo and modelo:GetFullName() or "nil")
        else
            add("Placa: não achei")
        end
        add("Tamanho da casa atual: %s", placa and chaveDaCasa(placa) or "?")
        for chave, o in pairs(type(S.CAIXAS) == "table" and S.CAIXAS or {}) do
            add("  caixa aprendida para %s: (%.1f, %.1f, %.1f) %s", chave, o.x or 0, o.y or 0, o.z or 0, tostring(o.tipo or ""))
        end

        local a = S.CAIXA_OBJETO
        add("Objeto da caixa aprendido: %s", type(a) == "table" and (a.avo .. " > " .. a.pai .. " > " .. a.nome .. " [" .. a.classe .. "]") or "nenhum")
        local posObj, obj = Casa.acharCaixaPorObjeto(placa)
        add("  achado nesta casa: %s %s", obj and obj:GetFullName() or "não", v(posObj))
        add("Peças com 'mail' perto da casa:")
        for _, c in ipairs(candidatosMail(placa)) do add("  %s [%s] em %s", c.obj:GetFullName(), c.obj.ClassName, v(c.pos)) end

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
        Utils.setStatus("Mapa da caixa" .. (copiou and " copiado: cole no chat" or " salvo em samhub_mapa_caixa.txt"), "info")
    end

    return Casa
end
