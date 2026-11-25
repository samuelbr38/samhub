return function(App)
    local Config, Utils, Historico = App.Config, App.Utils, App.Historico
    local S, E = Config.SAMHUB, Config.Estado
    local Players = game:GetService("Players")
    local Eu = Players.LocalPlayer
    local PlayerGui = Eu:WaitForChild("PlayerGui")

    local Trade = {}
    Trade.Terminou = Utils.Sinal()
    local rodando = false

    local function jogadorExato(texto)
        local porApelido = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Eu then
                if string.lower(p.Name) == texto then return p end
                if string.lower(p.DisplayName) == texto then table.insert(porApelido, p) end
            end
        end
        if #porApelido == 1 then return porApelido[1] end
        return nil, (#porApelido > 1 and "apelido repetido" or nil)
    end

    local function jogadorNaFrase(texto)
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Eu then
                if #p.Name >= 3 and Utils.temPalavra(texto, string.lower(p.Name)) then return p end
            end
        end
        local achados = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Eu and #p.DisplayName >= 3 and Utils.temPalavra(texto, string.lower(p.DisplayName)) then
                table.insert(achados, p)
            end
        end
        return #achados == 1 and achados[1] or nil
    end

    local function lerTexto(obj)
        local t = string.lower(Utils.limpar(obj.Text))
        return (string.gsub(t, "^@", ""))
    end

    local function appTrade()
        local app = PlayerGui:FindFirstChild(S.NOME_JANELA_TRADE, true)
        if app and Utils.visivel(app) then return app end
        return nil
    end

    local function lerJanela()
        local app = appTrade()
        if not app then return nil end

        local textoLabel, erroLabel
        local label = app:FindFirstChild(S.NOME_PARCEIRO, true)
        if label and (label:IsA("TextLabel") or label:IsA("TextButton")) and Utils.naTela(label) then
            local texto = lerTexto(label)
            if texto ~= "" and not Config.PLACEHOLDERS[texto] then
                local jogador, erro = jogadorExato(texto)
                jogador = jogador or jogadorNaFrase(texto)
                if jogador then return app, jogador, texto end
                textoLabel, erroLabel = texto, erro
            end
        end

        for _, d in ipairs(app:GetDescendants()) do
            if (d:IsA("TextLabel") or d:IsA("TextButton")) and Utils.naTela(d) then
                local texto = lerTexto(d)
                if texto ~= "" and not Config.PLACEHOLDERS[texto] then
                    local jogador = jogadorExato(texto)
                    if jogador then return app, jogador, texto end
                end
            end
        end

        if textoLabel then return app, nil, textoLabel, erroLabel end
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
                            if citaComprador(tudo) and Utils.temAlguma(tudo, S.PALAVRAS_PEDIDO) then
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

    local function aceitarPedido()
        local botao, quadro, comprador = acharPedido()
        if not botao then return false end
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
            local noServidor = jogadorExato(string.lower(nick))
            local id, nomeReal
            if noServidor then
                id, nomeReal = noServidor.UserId, noServidor.Name
            else
                local ok, resultado = pcall(Players.GetUserIdFromNameAsync, Players, nick)
                if ok and resultado then id, nomeReal = resultado, nick end
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
            local aceitou, metodo = Utils.clicar(botaoAceitar, janela)
            if not aceitou then
                E.pausado = true
                avisarEstado()
                return Utils.setStatus("O clique no Accept não funcionou com nenhum método. Pausado.", "erro")
            end
            Utils.setStatus("Accept (" .. tostring(metodo) .. "). Esperando a tela de confirmação...", "espera")
        end

        local confirmou, vistoEm = jaConfirmado(janela), nil
        local inicio = os.clock()
        while rodando and not confirmou and os.clock() - inicio < S.TIMEOUT_CONFIRMAR + 30 do
            task.wait(0.4)
            if janelaTrade() ~= janela then break end
            if jaConfirmado(janela) then
                confirmou = true
                break
            end
            local botao = Utils.acharBotao(janela, S.TEXTO_CONFIRMAR)
            if botao then
                vistoEm = vistoEm or os.clock()
                local falta = S.ESPERA_CONFIRMAR - (os.clock() - vistoEm)
                local texto = Utils.limpar(Utils.textoDe(botao))
                if falta > 0 or string.find(texto, "%d") then
                    Utils.setStatus(string.format("Tela de confirmação: aperto o Confirm em %.0fs...", math.max(falta, 1)), "espera")
                elseif Utils.clicar(botao, janela, function() return jaConfirmado(janela) end, 2) then
                    confirmou = true
                else
                    Utils.setStatus("O Confirm ainda não respondeu. Tento de novo...", "espera")
                    task.wait(1)
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
            if d:IsA("TextLabel") and Utils.temAlguma(string.lower(d.Text), S.TEXTOS_AVISO_TRADE) and Utils.naTela(d) then
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
        Utils.setStatus("Aviso do trade: apertando Okay...", "espera")
        Utils.ignorarTextoAoRedor = true
        local ok = Utils.clicar(botao, quadro)
        Utils.ignorarTextoAoRedor = false
        task.wait(0.5)
        return ok
    end
    Trade.fecharAvisoDeSeguranca = fecharAvisoDeSeguranca

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
                            if Utils.temPalavra(msg, string.lower(E.nickAlvo)) then
                                entregaConcluida(E.nickAlvo, E.userIdAlvo)
                            else
                                Utils.aviso("apertei Nice numa mensagem que não é do comprador: " .. mensagem)
                            end
                            return
                        end
                        local janela, jogador, texto, erro = lerJanela()
                        if janela then
                            Utils.trabalhando()
                            processar(janela, jogador, texto, erro)
                        elseif S.ACEITAR_PEDIDO then
                            aceitarPedido()
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
