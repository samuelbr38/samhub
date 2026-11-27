return function(App)
    local Config, Utils, Historico = App.Config, App.Utils, App.Historico
    local S, E = Config.SAMHUB, Config.Estado
    local Players = game:GetService("Players")
    local Eu = Players.LocalPlayer
    local PlayerGui = Eu:WaitForChild("PlayerGui")

    local Trade = {}
    Trade.Terminou = Utils.Sinal()
    local rodando = false
    local processando = false

    function Trade.emTrade() return processando end

    local function jogadoresComNome(texto)
        local achados = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Eu and (string.lower(p.Name) == texto or string.lower(p.DisplayName) == texto) then
                table.insert(achados, p)
            end
        end
        return achados
    end

    local function jogadorExato(texto)
        local achados = jogadoresComNome(texto)
        if #achados == 1 then return achados[1] end
        return nil, (#achados > 1 and "nome repetido no servidor (pode ser golpe)" or nil)
    end

    local function jogadorNaFrase(texto)
        local achados = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Eu then
                for _, n in ipairs({ p.Name, p.DisplayName }) do
                    if #n >= 3 and Utils.temPalavra(texto, string.lower(n)) then
                        table.insert(achados, p)
                        break
                    end
                end
            end
        end
        return #achados == 1 and achados[1] or nil
    end

    local function lerTexto(obj)
        local t = string.lower(Utils.limpar(obj.Text))
        return (string.gsub(t, "^@", ""))
    end

    local function idsNaJanela(janela)
        local ids, outros = {}, 0
        for _, d in ipairs(janela:GetDescendants()) do
            if (d:IsA("ImageLabel") or d:IsA("ImageButton")) and Utils.visivel(d) then
                local id = string.match(d.Image, "[?&][uU]ser[iI][dD]=(%d+)")
                    or string.match(d.Image, "type=Avatar%a*&id=(%d+)")
                id = tonumber(id)
                if id and not ids[id] then
                    ids[id] = true
                    if id ~= Eu.UserId then outros += 1 end
                end
            end
        end
        return outros > 0 and ids or nil
    end

    local function appTrade()
        local app = PlayerGui:FindFirstChild(S.NOME_JANELA_TRADE, true)
        if app and Utils.visivel(app) then return app end
        return nil
    end

    local function lerJanela()
        local app = appTrade()
        if not app then return nil end

        local jogador, texto, erro
        local label = app:FindFirstChild(S.NOME_PARCEIRO, true)
        if label and (label:IsA("TextLabel") or label:IsA("TextButton")) and Utils.naTela(label) then
            local lido = lerTexto(label)
            if lido ~= "" and not Config.PLACEHOLDERS[lido] then
                texto = lido
                jogador, erro = jogadorExato(lido)
                jogador = jogador or (not erro and jogadorNaFrase(lido)) or nil
            end
        end

        if not jogador and not erro then
            for _, d in ipairs(app:GetDescendants()) do
                if (d:IsA("TextLabel") or d:IsA("TextButton")) and Utils.naTela(d) then
                    local lido = lerTexto(d)
                    if lido ~= "" and not Config.PLACEHOLDERS[lido] then
                        local achado, e = jogadorExato(lido)
                        if achado or e then
                            jogador, erro, texto = achado, e, lido
                            break
                        end
                    end
                end
            end
        end

        local ids = idsNaJanela(app)
        if ids then
            if jogador and not ids[jogador.UserId] then
                return app, nil, texto, "a foto da janela é de outra pessoa (pode ser golpe)"
            end
            if not jogador then
                local porFoto
                for id in pairs(ids) do
                    local p = id ~= Eu.UserId and Players:GetPlayerByUserId(id)
                    if p then
                        if porFoto then porFoto = false break end
                        porFoto = p
                    end
                end
                if porFoto then return app, porFoto, texto or string.lower(porFoto.Name) end
            end
        end

        if jogador then return app, jogador, texto end
        if texto then return app, nil, texto, erro end
        return nil
    end

    local function janelaTrade()
        return (lerJanela())
    end

    local function fotoOferta(janela)
        local area = janela
        if S.NOME_OFERTA_PARCEIRO then
            area = janela:FindFirstChild(S.NOME_OFERTA_PARCEIRO, true)
            if not area then return nil end
        end
        local partes = {}
        for _, d in ipairs(area:GetDescendants()) do
            if (d:IsA("TextLabel") or d:IsA("ImageLabel")) and Utils.visivel(d) then
                local valor = d:IsA("TextLabel") and Utils.limpar(d.Text) or d.Image
                if valor ~= "" then table.insert(partes, d.Name .. "=" .. valor) end
            end
        end
        table.sort(partes)
        return table.concat(partes, "|")
    end

    local function ofertaEstavel(janela)
        local inicial = fotoOferta(janela)
        local t = 0
        while t < S.TEMPO_ESTAVEL do
            task.wait(0.25)
            t += 0.25
            if janelaTrade() ~= janela then return false, "a janela fechou" end
            if fotoOferta(janela) ~= inicial then return false, "a oferta mudou" end
        end
        return true, inicial
    end

    local function casaNoTrade(janela)
        local nomes = {}
        for nome in pairs(E.casasSelecionadas) do
            local semNumero = string.gsub(nome, " %(%d+%)$", "")
            table.insert(nomes, string.lower(semNumero))
        end
        if #nomes == 0 then return false end
        for _, d in ipairs(janela:GetDescendants()) do
            if d:IsA("TextLabel") and Utils.visivel(d) then
                local t = string.lower(Utils.limpar(d.Text))
                for _, nome in ipairs(nomes) do
                    if t ~= "" and (string.find(t, nome, 1, true) or string.find(nome, t, 1, true)) then
                        return true
                    end
                end
            end
        end
        return false
    end

    local function esperarFechar(janela, timeout)
        local t = 0
        while rodando and janelaTrade() == janela and (not timeout or t < timeout) do
            task.wait(0.25)
            t += 0.25
        end
    end

    local function quemPediu(tudo)
        local nome = string.match(tudo, "([^%s|]+)%s+sent you a trade") or string.match(tudo, "([^%s|]+)%s+wants to trade")
        if nome then return (jogadorExato((string.gsub(nome, "^@", "")))) end
        return jogadorNaFrase(tudo)
    end

    local function acharPedido()
        local comprador = E.userIdAlvo and Players:GetPlayerByUserId(E.userIdAlvo)
        if not comprador then return nil end
        local nomes = { string.lower(comprador.Name), string.lower(comprador.DisplayName) }
        local function citaComprador(texto)
            return Utils.temPalavra(texto, nomes[1]) or Utils.temPalavra(texto, nomes[2])
        end

        local vistos = {}
        for _, d in ipairs(PlayerGui:GetDescendants()) do
            if (d:IsA("TextLabel") or d:IsA("TextButton")) and Utils.naTela(d) then
                local t = string.lower(Utils.limpar(d.Text))
                if citaComprador(t) or Utils.temAlguma(t, S.PALAVRAS_PEDIDO) then
                    local quadro = d.Parent
                    for _ = 1, 8 do
                        if not quadro or quadro:IsA("LayerCollector") or vistos[quadro] then break end
                        vistos[quadro] = true
                        local botao = Utils.acharBotao(quadro, S.TEXTO_ACEITAR, S.NOMES_ACEITAR)
                        if botao then
                            local tudo = string.lower(Utils.textos(quadro))
                            if Utils.temAlguma(tudo, S.PALAVRAS_PEDIDO) and quemPediu(tudo) == comprador then
                                return botao, quadro, comprador
                            end
                            break
                        end
                        quadro = quadro.Parent
                    end
                end
            end
        end
        return nil
    end

    local function podeSerComprador(texto, nomeLido)
        local comprador = E.userIdAlvo and Players:GetPlayerByUserId(E.userIdAlvo)
        local nomes = { string.lower(E.nickAlvo or "") }
        if comprador then
            table.insert(nomes, string.lower(comprador.Name))
            table.insert(nomes, string.lower(comprador.DisplayName))
        end
        local lido = string.gsub(string.lower(nomeLido or ""), "[%.…]+$", "")
        lido = string.gsub(lido, "^@", "")
        for _, n in ipairs(nomes) do
            if n ~= "" then
                if Utils.temPalavra(texto, n) then return true end
                if #lido >= 3 and string.sub(n, 1, #lido) == lido then return true end
            end
        end
        return false
    end

    local function pedidoDeOutro()
        local vistos = {}
        for _, d in ipairs(PlayerGui:GetDescendants()) do
            if (d:IsA("TextLabel") or d:IsA("TextButton")) and Utils.naTela(d) then
                local t = string.lower(Utils.limpar(d.Text))
                if Utils.temAlguma(t, S.TEXTOS_PEDIDO_TRADE) then
                    local quadro = d.Parent
                    for _ = 1, 8 do
                        if not quadro or quadro:IsA("LayerCollector") or vistos[quadro] then break end
                        vistos[quadro] = true
                        local recusar = Utils.acharBotao(quadro, S.TEXTO_RECUSAR_PEDIDO, S.NOMES_RECUSAR)
                        local aceitar = Utils.acharBotao(quadro, S.TEXTO_ACEITAR, S.NOMES_ACEITAR)
                        if recusar and aceitar then
                            local tudo = string.lower(Utils.textos(quadro))
                            local nome = string.match(tudo, "([^%s|]+)%s+sent you a trade")
                                or string.match(tudo, "([^%s|]+)%s+wants to trade") or "?"
                            if podeSerComprador(tudo, nome) then return nil end
                            return recusar, quadro, nome
                        end
                        quadro = quadro.Parent
                    end
                end
            end
        end
        return nil
    end

    local recusadoHa = {}
    local function recusarPedidoDeOutro()
        local botao, quadro, nome = pedidoDeOutro()
        if not botao then return false end
        Utils.trabalhando()
        task.wait(0.3 + math.random() * 0.5)
        if not botao.Parent or not Utils.naTela(botao) then return false end
        local ok = Utils.clicar(botao, quadro)
        if ok then
            Utils.setStatus("Recusei o pedido de " .. nome .. " (não é @" .. E.nickAlvo .. ")", "aviso")
            if os.clock() - (recusadoHa[nome] or -999) > 60 then
                recusadoHa[nome] = os.clock()
                Historico.registrar(nome, nil, "recusado", "pedido de trade (não é o comprador)")
            end
        else
            Utils.setStatus("Não consegui apertar Decline no pedido de " .. nome, "aviso")
        end
        task.wait(0.5)
        return ok
    end

    local function aceitarPedido()
        local botao, quadro, comprador = acharPedido()
        if not botao then return false end
        if App.Casa and App.Casa.ocupado and App.Casa.ocupado() then
            Utils.setStatus("Pedido de @" .. comprador.Name .. ": termino de pôr a casa à venda e já aceito...", "espera")
            return true
        end
        Utils.trabalhando()
        Utils.esperar()
        local ok, metodo = Utils.clicar(botao, quadro)
        if ok then
            Utils.setStatus("Pedido de @" .. comprador.Name .. " aceito (" .. tostring(metodo) .. "). Abrindo trade...", "espera")
            task.wait(1.5)
        else
            Utils.setStatus("Achei o pedido de @" .. comprador.Name .. " mas o clique não funcionou", "erro")
            task.wait(3)
        end
        return ok
    end

    local function avisarEstado()
        Utils.EstadoMudou:Fire()
    end

    local function desativar()
        E.nickAlvo, E.userIdAlvo, E.pausado = "", nil, false
        avisarEstado()
    end

    function Trade.estado()
        if not E.userIdAlvo then return "inativo" end
        return E.pausado and "pausado" or "ativo"
    end

    function Trade.ativar(nick, aoTerminar)
        nick = string.gsub(Utils.limpar(nick), "^@", "")
        Utils.setStatus("Buscando @" .. nick .. "...", "espera")

        task.spawn(function()
            local noServidor
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= Eu and string.lower(p.Name) == string.lower(nick) then noServidor = p end
            end
            local id, nomeReal
            if noServidor then
                id, nomeReal = noServidor.UserId, noServidor.Name
            else
                local ok, resultado = pcall(Players.GetUserIdFromNameAsync, Players, nick)
                if ok and resultado then
                    id, nomeReal = resultado, nick
                    local okNome, nomeCerto = pcall(Players.GetNameFromUserIdAsync, Players, resultado)
                    if okNome and nomeCerto then nomeReal = nomeCerto end
                end
            end

            if id then
                E.nickAlvo, E.userIdAlvo, E.pausado = nomeReal, id, false
                avisarEstado()
                Utils.setStatus("Aguardando trade de @" .. nomeReal
                    .. (Players:GetPlayerByUserId(id) and "" or " (ainda não está no servidor)"), "espera")
            else
                Utils.setStatus("Não achei @" .. nick .. " (confira o nome)", "erro")
            end
            if aoTerminar then aoTerminar(id ~= nil) end
        end)
    end

    function Trade.desativar()
        desativar()
        Utils.setStatus("Desativado", "info")
    end

    function Trade.resetar()
        E.casasSelecionadas = {}
        desativar()
        Utils.setStatus("Pronto para um novo comprador", "info")
    end

    function Trade.alternarPausa()
        if not E.userIdAlvo then
            Utils.setStatus("Ative um comprador primeiro", "aviso")
            return false
        end
        E.pausado = not E.pausado
        avisarEstado()
        if E.pausado then
            Utils.setStatus("Pausado", "aviso")
        else
            Utils.setStatus("Aguardando trade de @" .. E.nickAlvo, "espera")
        end
        return E.pausado
    end

    local function recusar(janela, nome, id, motivo)
        Utils.esperar()
        local clicou = Utils.clicarPorTexto(janela, S.TEXTO_RECUSAR, S.NOMES_RECUSAR)
        Historico.registrar(nome, id, "recusado", motivo)
        if clicou then
            Utils.setStatus("Recusado: " .. nome .. " (" .. motivo .. ")", "aviso")
        else
            Utils.setStatus("Não consegui recusar " .. nome .. ". Feche o trade manualmente.", "aviso")
        end
        esperarFechar(janela)
    end

    local function jaConfirmado(janela)
        return Utils.acharBotao(janela, S.TEXTO_CONFIRMADO) ~= nil
    end

    local function etapaConfirmar(janela)
        return Utils.acharBotao(janela, S.TEXTO_CONFIRMAR) ~= nil or jaConfirmado(janela)
    end

    local function meuAceite(janela)
        if not janela then return nil end
        for _, d in ipairs(janela:GetDescendants()) do
            if d.Name == "MyOffer" and d:IsA("GuiObject") and Utils.naTela(d) then
                local visto = d:FindFirstChild("Accepted")
                if visto and visto:IsA("GuiObject") then
                    local ok, transparencia = pcall(function() return visto.ImageTransparency end)
                    if ok then return visto.Visible and transparencia < 0.9 end
                end
            end
        end
        return nil
    end

    local function desativado(botao)
        local sombra = botao and botao:FindFirstChild("Shadow")
        return sombra ~= nil and sombra:IsA("GuiObject") and not sombra.Visible
    end

    local function aindaAtivo(jogador)
        return E.userIdAlvo ~= nil and jogador ~= nil and jogador.UserId == E.userIdAlvo and not E.pausado
    end

    local function sucessoNaTela()
        for _, d in ipairs(PlayerGui:GetDescendants()) do
            if d:IsA("TextLabel") and Utils.naTela(d) then
                local texto = Utils.limpar(d.Text)
                if Utils.temAlguma(string.lower(texto), S.TEXTOS_SUCESSO) then
                    local quadro = d.Parent
                    for _ = 1, 5 do
                        if not quadro or quadro:IsA("LayerCollector") then break end
                        local botao = Utils.acharBotao(quadro, S.TEXTO_NICE)
                        if botao then return botao, quadro, texto end
                        quadro = quadro.Parent
                    end
                end
            end
        end
        return nil
    end
    Trade.sucessoNaTela = sucessoNaTela

    local function entregaConcluida(nick, userId)
        if App.Casa and App.Casa.esquecerCasaAtual then App.Casa.esquecerCasaAtual() end
        if App.Popups and App.Popups.resolverRecebido then
            task.wait(0.5)
            pcall(App.Popups.resolverRecebido)
        end
        local marcada = next(E.casasSelecionadas)
        local detalhe, problema = "casa entregue ✅", nil
        if S.CONFERIR_ENTREGA and App.Casa and App.Casa.conferirEntrega then
            local manter = App.Fila and App.Fila.temProximo and App.Fila.temProximo() or false
            local saiu, msg = App.Casa.conferirEntrega(marcada, manter)
            if saiu == true then
                detalhe = "casa entregue ✅ (saiu da lista)"
            elseif saiu == false then
                detalhe = "⚠️ trade feito, mas a casa ainda aparece na lista"
                problema = msg
            else
                detalhe = "casa entregue ✅ (lista não conferida)"
                Utils.aviso("não conferi a lista depois do trade: " .. tostring(msg))
            end
        end
        Historico.registrar(nick, userId, "finalizado", detalhe)
        E.casasSelecionadas = {}
        desativar()
        if problema then
            Utils.setStatus("Trade com @" .. nick .. " feito, mas " .. problema .. ". Confira!", "erro")
            Trade.Terminou:Fire("conferir", nick, problema)
        else
            Utils.setStatus("Casa entregue para @" .. nick .. "! ✅", "ok")
            Trade.Terminou:Fire("finalizado", nick)
        end
    end

    local function processar(janela, jogador, texto, erro)
        if not (jogador and jogador.UserId == E.userIdAlvo) then
            local nome = jogador and jogador.Name or texto or "?"
            if not jogador and erro and string.find(erro, "golpe", 1, true) then
                Historico.registrar(nome, nil, "cancelado", erro)
                Utils.setStatus("Trade de '" .. nome .. "': " .. erro .. ". NÃO aceitei. Confira na mão.", "erro")
                return esperarFechar(janela)
            end
            local motivo = jogador and "não é o comprador" or (erro or "não está no servidor")
            if S.RECUSAR_OUTROS then
                return recusar(janela, nome, jogador and jogador.UserId, motivo)
            end
            Utils.setStatus("Ignorando trade de " .. nome .. " (" .. motivo .. ")", "info")
            return esperarFechar(janela)
        end

        if S.VERIFICAR_CASA and not casaNoTrade(janela) then
            return Utils.setStatus("A casa marcada ainda não apareceu no trade", "espera")
        end

        if not etapaConfirmar(janela) then
            Utils.setStatus("Trade com @" .. jogador.Name .. " aberto. Conferindo oferta...", "espera")
            local estavel, foto = ofertaEstavel(janela)
            if not estavel then
                return Utils.setStatus("Esperando: " .. foto, "espera")
            end

            Utils.esperar()
            local botaoAceitar = Utils.acharBotao(janela, S.TEXTO_ACEITAR, S.NOMES_ACEITAR)
            if not botaoAceitar then
                return Utils.setStatus("Não achei o botão Accept (veja a aba Diagnóstico)", "erro")
            end
            local textoAceitar = Utils.limpar(Utils.textoDe(botaoAceitar) or "")
            if meuAceite(janela) == true then
                Utils.setStatus("Já aceitei. Esperando @" .. jogador.Name .. " aceitar...", "espera")
            elseif string.find(textoAceitar, "%d") then
                return Utils.setStatus("Esperando a contagem do Accept terminar...", "espera")
            elseif not aindaAtivo(jogador) then
                return Utils.setStatus("A entrega foi desativada: não aceitei o trade de @" .. jogador.Name, "aviso")
            else
                local aceitou, metodo = Utils.clicar(botaoAceitar, janela, function()
                    return meuAceite(janela) == true or etapaConfirmar(janela)
                        or not botaoAceitar.Parent or not Utils.naTela(botaoAceitar)
                        or (desativado(botaoAceitar) and not string.find(Utils.limpar(Utils.textoDe(botaoAceitar) or ""), "%d"))
                        or (Trade.avisoNaTela ~= nil and Trade.avisoNaTela() ~= nil)
                end, 2.5, 2)
                if not aceitou then
                    if string.find(Utils.limpar(Utils.textoDe(botaoAceitar) or ""), "%d") then
                        return Utils.setStatus("A oferta mudou na hora do Accept. Confiro de novo...", "espera")
                    end
                    E.pausado = true
                    avisarEstado()
                    return Utils.setStatus("O clique no Accept não funcionou com nenhum método. Pausado.", "erro")
                end
                Utils.setStatus("Accept (" .. tostring(metodo) .. "). Esperando a tela de confirmação...", "espera")
            end
        end

        local confirmou, vistoEm = jaConfirmado(janela), nil
        local tentativasConfirm = 0
        local inicio = os.clock()
        while rodando and not confirmou and os.clock() - inicio < S.TIMEOUT_CONFIRMAR + 30 do
            task.wait(0.4)
            if Trade.fecharAvisoDeSeguranca then Trade.fecharAvisoDeSeguranca() end
            if janelaTrade() ~= janela then break end
            if jaConfirmado(janela) then
                confirmou = true
                break
            end
            local botao = Utils.acharBotao(janela, S.TEXTO_CONFIRMAR)
            if not botao and os.clock() - inicio > 1.5 then
                local ac = Utils.acharBotao(janela, S.TEXTO_ACEITAR, S.NOMES_ACEITAR)
                if ac and Utils.naTela(ac) then
                    local t = Utils.limpar(Utils.textoDe(ac) or "")
                    if string.find(t, "%d") or (meuAceite(janela) == false and not desativado(ac)) then
                        return Utils.setStatus("A oferta mudou e o jogo desfez o Accept. Confiro de novo...", "espera")
                    end
                end
            end
            if botao then
                vistoEm = vistoEm or os.clock()
                local falta = S.ESPERA_CONFIRMAR - (os.clock() - vistoEm)
                local texto = Utils.limpar(Utils.textoDe(botao))
                if falta > 0 or string.find(texto, "%d") then
                    Utils.setStatus(string.format("Tela de confirmação: aperto o Confirm em %.0fs...", math.max(falta, 1)), "espera")
                elseif not aindaAtivo(jogador) then
                    return Utils.setStatus("A entrega foi desativada: não confirmei o trade de @" .. jogador.Name, "aviso")
                elseif tentativasConfirm >= 3 then
                    Utils.setStatus("Apertei o Confirm e ele não mudou. Aperte o Confirm você (eu sigo sozinho).", "aviso")
                    task.wait(1)
                else
                    tentativasConfirm += 1
                    local function mudou()
                        if jaConfirmado(janela) then return true end
                        if not botao.Parent then return false end
                        local agora = Utils.limpar(Utils.textoDe(botao) or "")
                        return agora ~= texto and agora ~= "" and not string.find(agora, "%d")
                    end
                    if Utils.clicar(botao, janela, mudou, 2.5, 2) then
                        confirmou = true
                    else
                        Utils.setStatus("O Confirm ainda não respondeu. Tento de novo...", "espera")
                        task.wait(2)
                    end
                end
            end
        end

        if not confirmou then
            if janelaTrade() == janela then
                return Utils.setStatus("O trade ainda está aberto e não consegui confirmar. Termine manualmente.", "aviso")
            end
            Historico.registrar(jogador.Name, jogador.UserId, "cancelado", "fechou antes de confirmar")
            return Utils.setStatus("O trade fechou antes de confirmar. Aguardando de novo...", "aviso")
        end

        Utils.setStatus("Confirmado! Esperando @" .. jogador.Name .. " confirmar também...", "espera")
        local nice, quadro, mensagem
        local fechouEm
        inicio = os.clock()
        while rodando and os.clock() - inicio < S.TIMEOUT_RESULTADO do
            task.wait(0.4)
            if Trade.fecharAvisoDeSeguranca then Trade.fecharAvisoDeSeguranca() end
            nice, quadro, mensagem = sucessoNaTela()
            if nice then break end
            if janelaTrade() ~= janela then
                fechouEm = fechouEm or os.clock()
                if os.clock() - fechouEm > 5 then break end
            end
        end

        if nice then
            if not Utils.temPalavra(string.lower(mensagem), string.lower(jogador.Name))
                and not Utils.temPalavra(string.lower(mensagem), string.lower(jogador.DisplayName)) then
                Utils.aviso("a mensagem de sucesso não cita @" .. jogador.Name .. ": " .. mensagem)
            end
            Utils.clicar(nice, quadro)
            entregaConcluida(jogador.Name, jogador.UserId)
        elseif janelaTrade() == janela then
            Utils.setStatus("@" .. jogador.Name .. " ainda não confirmou. Termine manualmente.", "aviso")
        else
            Historico.registrar(jogador.Name, jogador.UserId, "cancelado", "fechou sem a mensagem de sucesso")
            Utils.setStatus("O trade fechou sem 'You traded your home'. Aguardando de novo...", "aviso")
        end
    end

    function Trade.diagnostico()
        local app = PlayerGui:FindFirstChild(S.NOME_JANELA_TRADE, true)
        local janela, jogador, texto = lerJanela()
        local botao = janela and Utils.acharBotao(janela, S.TEXTO_ACEITAR, S.NOMES_ACEITAR)
        local comprador = E.userIdAlvo and Players:GetPlayerByUserId(E.userIdAlvo)
        return {
            appExiste = app ~= nil,
            janelaAberta = janela ~= nil,
            parceiro = jogador and ("@" .. jogador.Name) or texto,
            parceiroOk = jogador ~= nil,
            botaoAceitar = botao and botao.Name or nil,
            comprador = E.userIdAlvo and ("@" .. E.nickAlvo) or nil,
            compradorNoServidor = comprador ~= nil,
            pedidoNaTela = acharPedido() ~= nil,
        }
    end

    local function avisoDeSeguranca()
        for _, d in ipairs(PlayerGui:GetDescendants()) do
            if d:IsA("TextLabel") and Utils.temAlguma(string.lower(string.gsub(Utils.limpar(d.Text), "%s+", " ")), S.TEXTOS_AVISO_TRADE) and Utils.naTela(d) then
                local quadro = d.Parent
                for _ = 1, 5 do
                    if not quadro or quadro:IsA("LayerCollector") then break end
                    local ok = Utils.acharBotao(quadro, S.TEXTO_OKAY)
                    if ok then return ok, quadro end
                    quadro = quadro.Parent
                end
            end
        end
        return nil
    end

    local function fecharAvisoDeSeguranca()
        local botao, quadro = avisoDeSeguranca()
        if not botao then return false end
        Utils.trabalhando()
        Utils.setStatus("Aviso do trade: apertando " .. Utils.limpar(Utils.textoDe(botao)) .. "...", "espera")
        Utils.ignorarTextoAoRedor = botao
        local ok = Utils.clicar(botao, quadro)
        if Utils.ignorarTextoAoRedor == botao then Utils.ignorarTextoAoRedor = nil end
        task.wait(0.5)
        return ok
    end
    Trade.fecharAvisoDeSeguranca = fecharAvisoDeSeguranca
    Trade.avisoNaTela = avisoDeSeguranca

    function Trade.iniciar()
        if rodando then return end
        rodando = true
        task.spawn(function()
            while rodando do
                task.wait(0.5)
                if E.userIdAlvo and not E.pausado then
                    local ok, err = pcall(function()
                        if fecharAvisoDeSeguranca() then return end
                        local nice, quadro, mensagem = sucessoNaTela()
                        if nice then
                            Utils.clicar(nice, quadro)
                            local msg = string.lower(mensagem)
                            local comprador = Players:GetPlayerByUserId(E.userIdAlvo)
                            if Utils.temPalavra(msg, string.lower(E.nickAlvo))
                                or (comprador and Utils.temPalavra(msg, string.lower(comprador.DisplayName))) then
                                entregaConcluida(E.nickAlvo, E.userIdAlvo)
                            else
                                Utils.aviso("apertei Nice numa mensagem que não é do comprador: " .. mensagem)
                            end
                            return
                        end
                        local janela, jogador, texto, erro = lerJanela()
                        if janela then
                            Utils.trabalhando()
                            processando = true
                            local okP, errP = pcall(processar, janela, jogador, texto, erro)
                            processando = false
                            if not okP then error(errP, 0) end
                        elseif not (S.ACEITAR_PEDIDO and aceitarPedido()) and S.RECUSAR_OUTROS then
                            recusarPedidoDeOutro()
                        end
                    end)
                    if not ok then
                        Utils.aviso("" .. tostring(err))
                        Utils.setStatus("Erro interno (veja Registro)", "erro")
                    end
                end
            end
        end)
    end

    function Trade.parar()
        rodando = false
    end

    return Trade
end
