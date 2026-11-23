return function(App)
    local Config, Utils, Historico = App.Config, App.Utils, App.Historico
    local S, E = Config.SAMHUB, Config.Estado
    local Players = game:GetService("Players")
    local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

    local Trade = {}
    local rodando = false

    local function labelParceiro(app)
        local label = app:FindFirstChild(S.NOME_PARCEIRO, true)
        if label and (label:IsA("TextLabel") or label:IsA("TextButton")) then return label end
        return nil
    end

    local function janelaTrade()
        local app = PlayerGui:FindFirstChild(S.NOME_JANELA_TRADE, true)
        if not app or not Utils.visivel(app) then return nil end
        local label = labelParceiro(app)
        if not label or not Utils.naTela(label) then return nil end
        return app
    end

    local function textoParceiro(janela)
        local label = labelParceiro(janela)
        if not label then return nil end
        local texto = string.lower(Utils.limpar(label.Text))
        texto = string.gsub(texto, "^@", "")
        if texto == "" or Config.PLACEHOLDERS[texto] then return nil end
        return texto
    end

    local function acharJogador(texto)
        local porApelido = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Players.LocalPlayer then
                if string.lower(p.Name) == texto then return p end
                if string.lower(p.DisplayName) == texto then table.insert(porApelido, p) end
            end
        end
        if #porApelido == 1 then return porApelido[1] end
        return nil, (#porApelido > 1 and "apelido repetido" or "não está no servidor")
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

    local function contemPalavra(texto, palavra)
        return string.find(texto, "%f[%w_]" .. Utils.escaparPadrao(palavra) .. "%f[^%w_]") ~= nil
    end

    local function aceitarPedido()
        local comprador = Players:GetPlayerByUserId(E.userIdAlvo)
        if not comprador then return false end
        local nomes = { string.lower(comprador.Name), string.lower(comprador.DisplayName) }

        for _, d in ipairs(PlayerGui:GetDescendants()) do
            if d:IsA("TextLabel") and Utils.naTela(d) then
                local t = string.lower(Utils.limpar(d.Text))
                if string.find(t, "trade", 1, true) or string.find(t, "troca", 1, true) then
                    local temNome = contemPalavra(t, nomes[1]) or contemPalavra(t, nomes[2])
                    if temNome then
                        local atual = d.Parent
                        for _ = 1, 6 do
                            if not atual or atual:IsA("LayerCollector") then break end
                            local botao = Utils.acharBotao(atual, S.TEXTO_ACEITAR)
                            if botao and Utils.naTela(botao) then
                                Utils.esperar()
                                if Utils.clicar(botao) then
                                    Utils.setStatus("Pedido de @" .. comprador.Name .. " aceito. Abrindo trade...", "espera")
                                    task.wait(2)
                                    return true
                                end
                            end
                            atual = atual.Parent
                        end
                    end
                end
            end
        end
        return false
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
            local ok, id = pcall(Players.GetUserIdFromNameAsync, Players, nick)
            local achou = ok and id ~= nil
            if achou then
                E.nickAlvo, E.userIdAlvo, E.pausado = nick, id, false
                avisarEstado()
                local noServidor = Players:GetPlayerByUserId(id) ~= nil
                Utils.setStatus("Aguardando trade de @" .. nick
                    .. (noServidor and "" or " (ainda não está no servidor)"), "espera")
            else
                Utils.setStatus("Usuário @" .. nick .. " não existe (use o @username)", "erro")
            end
            if aoTerminar then aoTerminar(achou) end
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
        local clicou = Utils.clicarPorTexto(janela, S.TEXTO_RECUSAR)
        Historico.registrar(nome, id, "recusado", motivo)
        if clicou then
            Utils.setStatus("Recusado: " .. nome .. " (" .. motivo .. ")", "aviso")
        else
            Utils.setStatus("Não achei o botão Recusar. Feche o trade de " .. nome .. " manualmente.", "aviso")
        end
        esperarFechar(janela)
    end

    local function processar(janela)
        local texto = textoParceiro(janela)
        if not texto then
            return Utils.setStatus("Lendo nome do parceiro...", "espera")
        end

        local jogador, erro = acharJogador(texto)
        if not (jogador and jogador.UserId == E.userIdAlvo) then
            local nome = jogador and jogador.Name or texto
            local motivo = erro or "não é o comprador"
            if S.RECUSAR_OUTROS then
                return recusar(janela, nome, jogador and jogador.UserId, motivo)
            end
            Utils.setStatus("Ignorando trade de " .. nome .. " (" .. motivo .. ")", "info")
            return esperarFechar(janela)
        end

        if S.VERIFICAR_CASA and not casaNoTrade(janela) then
            return Utils.setStatus("A casa marcada ainda não apareceu no trade", "espera")
        end

        Utils.setStatus("Conferindo oferta de @" .. jogador.Name .. "...", "espera")
        local estavel, foto = ofertaEstavel(janela)
        if not estavel then
            return Utils.setStatus("Esperando: " .. foto, "espera")
        end

        Utils.esperar()
        local botaoAceitar = Utils.acharBotao(janela, S.TEXTO_ACEITAR)
        if not botaoAceitar then
            return Utils.setStatus("Botão Aceitar não encontrado (use Mapear trade)", "erro")
        end
        if not Utils.clicar(botaoAceitar) then
            E.pausado = true
            avisarEstado()
            return Utils.setStatus("Seu executor não consegue clicar. Pausado.", "erro")
        end

        local confirmou, t = false, 0
        while rodando and t < S.TIMEOUT_CONFIRMAR + 15 do
            task.wait(0.4)
            t += 0.4
            if janelaTrade() ~= janela then break end

            local agora = fotoOferta(janela)
            if S.NOME_OFERTA_PARCEIRO and foto and agora and agora ~= foto then
                Utils.clicarPorTexto(janela, S.TEXTO_RECUSAR)
                Utils.setStatus("A oferta mudou depois do Aceitar! Trade cancelado.", "erro")
                Historico.registrar(jogador.Name, jogador.UserId, "cancelado", "oferta mudou")
                return esperarFechar(janela, 5)
            end

            if not confirmou then
                local botao = Utils.acharBotao(janela, S.TEXTO_CONFIRMAR)
                if botao and Utils.clicar(botao) then
                    confirmou = true
                    Utils.setStatus("Confirmado. Esperando o comprador...", "espera")
                elseif t > S.TIMEOUT_CONFIRMAR then
                    break
                end
            end
        end

        if janelaTrade() == janela then
            return Utils.setStatus("O trade ainda está aberto. Termine manualmente.", "aviso")
        end

        if confirmou then
            Historico.registrar(jogador.Name, jogador.UserId, "finalizado", "confira o inventário")
            E.casasSelecionadas = {}
            desativar()
            Utils.setStatus("Trade com @" .. jogador.Name .. " finalizado! Confira se a casa saiu.", "ok")
        else
            Historico.registrar(jogador.Name, jogador.UserId, "cancelado", "fechou antes de confirmar")
            Utils.setStatus("O trade fechou antes de confirmar. Aguardando de novo...", "aviso")
        end
    end

    function Trade.iniciar()
        if rodando then return end
        rodando = true
        task.spawn(function()
            while rodando do
                task.wait(0.5)
                if E.userIdAlvo and not E.pausado then
                    local janela = janelaTrade()
                    local ok, err = pcall(function()
                        if janela then
                            processar(janela)
                        elseif S.ACEITAR_PEDIDO then
                            aceitarPedido()
                        end
                    end)
                    if not ok then
                        warn("[SAMHUB] " .. tostring(err))
                        Utils.setStatus("Erro interno (veja F9)", "erro")
                    end
                end
            end
        end)
    end

    function Trade.parar()
        rodando = false
    end

    Trade.janelaTrade = janelaTrade

    return Trade
end
