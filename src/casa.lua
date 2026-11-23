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

    local function posicaoSalva(placa)
        local o = S.OFFSET_CAIXA
        if not (placa and type(o) == "table" and #o == 3) then return nil end
        return placa.referencia:PointToWorldSpace(Vector3.new(o[1], o[2], o[3]))
    end

    local function guardarPosicao(placa, raiz, avisar)
        local o = placa.referencia:PointToObjectSpace(raiz.Position)
        S.OFFSET_CAIXA = { o.X, o.Y, o.Z }
        if App.salvarAjustes then App.salvarAjustes() end
        if avisar then Utils.setStatus("Aprendi onde fica a sua caixa de correio! 📮", "ok") end
    end

    function Casa.salvarPosicaoCaixa()
        local _, raiz = personagem()
        local placa = Casa.acharPlaca()
        if not raiz or not placa then
            Utils.setStatus("Não achei a placa da sua casa para salvar a posição", "erro")
            return false
        end
        guardarPosicao(placa, raiz, true)
        return true
    end

    local function botao(textos)
        return Utils.acharBotao(PlayerGui, textos)
    end

    local TEXTOS_MENU_CAIXA = {}
    for _, t in ipairs(S.TEXTO_LISTAR_CASA) do table.insert(TEXTOS_MENU_CAIXA, t) end
    for _, t in ipairs(S.TEXTO_DESLISTAR) do table.insert(TEXTOS_MENU_CAIXA, t) end

    local function menuDaCaixa()
        return botao(TEXTOS_MENU_CAIXA)
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

    local function aprenderSeAberto()
        if not menuDaCaixa() then return end
        local _, raiz = personagem()
        local placa = placaRapida()
        if not raiz or not placa then return end
        local atual = posicaoSalva(placa)
        if not atual or distanciaXZ(atual, raiz.Position) > 3 then
            guardarPosicao(placa, raiz, atual == nil)
        end
    end

    local vigiando = false
    function Casa.iniciarVigia()
        if vigiando then return end
        vigiando = true
        task.spawn(function()
            while vigiando do
                task.wait(1.5)
                pcall(aprenderSeAberto)
            end
        end)
    end

    function Casa.pararVigia()
        vigiando = false
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

    local function eDaCaixa(label, salva)
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
            if not pos or (pos - raiz.Position).Magnitude > 20 then return nil end
            local caminho = nomesAcima(alvo, 5)
            if Utils.temAlguma(caminho, PALAVRAS_PORTA) then return nil end
            if string.find(caminho, "mail", 1, true) then return pos end
            if salva and distanciaXZ(pos, salva) < 7 then return pos end
            return nil
        end

        if Utils.naTela(label) and salva and distanciaXZ(raiz.Position, salva) <= 5 then
            return salva
        end
        return nil
    end

    local function acharE(salva)
        for label in pairs(candidatosE) do
            local ok, pos = pcall(eDaCaixa, label, salva)
            if ok and pos then return label, pos end
        end
        return nil
    end

    function Casa.botaoEVisivel()
        coletarE(false)
        return acharE(posicaoSalva(placaRapida())) ~= nil
    end

    function Casa.andarAte(destino, portas)
        local humanoide, raiz = personagem()
        if not humanoide or not raiz then return false, "sem personagem" end
        local alvo = Vector3.new(destino.X, raiz.Position.Y, destino.Z)
        local inicio, ultimaPos, parado, ultimoComando = os.clock(), raiz.Position, 0, os.clock()
        humanoide:MoveTo(alvo)

        while distanciaXZ(raiz.Position, destino) > 2.5 do
            task.wait(0.15)
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
        porta = "Parei: ia passar perto da porta. Vá até a caixa de correio por fora.",
        teleporte = "Fui teleportado (entrei em algum lugar?). Volte para a frente da casa.",
        tempo = "Não consegui chegar na caixa de correio a tempo.",
    }

    function Casa.irAteCaixa()
        local _, raiz = personagem()
        if not raiz then return nil, "Personagem não carregou" end
        local placa = Casa.acharPlaca()
        placaGuardada, placaHora = placa, os.clock()
        local salva = posicaoSalva(placa)

        candidatosE = {}
        coletarE(true)
        local e, pos = acharE(salva)
        if e then return e, pos end

        if not salva then
            return nil, "Ainda não sei onde fica sua caixa de correio. Vá até ela e toque nela UMA vez: eu aprendo e continuo sozinho."
        end
        local distancia = distanciaXZ(raiz.Position, salva)
        if distancia <= 4 then return nil, nil end
        if not S.ANDAR_ATE_CAIXA then return nil, "Vá até a sua caixa de correio" end
        if distancia > S.DISTANCIA_MAX_ANDAR then
            return nil, string.format("Você está longe da sua casa (%.0f studs). Chegue mais perto.", distancia)
        end

        Utils.setStatus(string.format("Indo até a caixa de correio (%.0f studs)...", distancia), "espera")
        local ok, motivo = Casa.andarAte(salva, portasDa(placa))
        if not ok then return nil, MENSAGENS_ANDAR[motivo] or "Não consegui chegar na caixa de correio." end
        coletarE(false)
        return acharE(salva)
    end

    local function tocarNoMundo(posicao)
        local camera = workspace.CurrentCamera
        if not camera or not posicao then return false end
        local ponto, naFrente = camera:WorldToViewportPoint(posicao)
        if not naFrente then return false end
        return Utils.clicarNaTela(ponto.X, ponto.Y)
    end

    function Casa.abrirMenu()
        if menuAberto() then
            aprenderSeAberto()
            return true
        end

        local e, info = Casa.irAteCaixa()
        local _, raiz = personagem()
        local salva = posicaoSalva(placaRapida())
        local noLugar = salva and raiz and distanciaXZ(raiz.Position, salva) <= 4

        if e or noLugar then
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
        local abriu = esperar(menuAberto, S.ESPERA_CAIXA_CORREIO) ~= nil
        if abriu then aprenderSeAberto() end
        return abriu
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
        local placa = placaRapida()
        local salva = posicaoSalva(placa)
        return {
            placa = placa ~= nil,
            distanciaPlaca = (placa and raiz) and distanciaXZ(raiz.Position, placa.posicao) or nil,
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
