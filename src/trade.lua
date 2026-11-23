return function(App)
    local Config, Utils, Historico = App.Config, App.Utils, App.Historico
    local S, E = Config.SAMHUB, Config.Estado
    local Players = game:GetService("Players")

    local Trade = {}
    local rodando = false

    local function janelaTrade()
        local janela = Players.LocalPlayer.PlayerGui:FindFirstChild(S.NOME_JANELA_TRADE, true)
        if janela and Utils.visivel(janela) then return janela end
        return nil
    end

    local function textoParceiro(janela)
        local label = janela:FindFirstChild(S.NOME_PARCEIRO, true)
        if not label or not (label:IsA("TextLabel") or label:IsA("TextButton")) then return nil end
        local texto = string.lower(Utils.limpar(label.Text))
        texto = string.gsub(texto, "^@", "")
        return texto ~= "" and texto or nil
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

    local function esperarFechar(janela, timeout)
        local t = 0
        while rodando and janelaTrade() == janela and (not timeout or t < timeout) do
            task.wait(0.25)
            t += 0.25
        end
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
                Utils.setStatus("Aguardando trade de @" .. nick, "espera")
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
        Utils.clicarPorTexto(janela, S.TEXTO_RECUSAR)
        Utils.setStatus("Recusado: " .. nome .. " (" .. motivo .. ")", "aviso")
        Historico.registrar(nome, id, "recusado", motivo)
        esperarFechar(janela, 5)
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

        Utils.setStatus("Conferindo oferta de @" .. jogador.Name .. "...", "espera")
        local estavel, foto = ofertaEstavel(janela)
        if not estavel then
            return Utils.setStatus("Esperando: " .. foto, "espera")
        end

        Utils.esperar()
        local botaoAceitar = Utils.acharBotao(janela, S.TEXTO_ACEITAR)
        if not botaoAceitar then
            return Utils.setStatus("Botão Aceitar não encontrado (use Mapear UI)", "erro")
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
                    if janela then
                        local ok, err = pcall(processar, janela)
                        if not ok then
                            warn("[SAMHUB] " .. tostring(err))
                            Utils.setStatus("Erro interno (veja F9)", "erro")
                        end
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
