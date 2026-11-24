return function(App)
    local Config, Utils = App.Config, App.Utils
    local S, E = Config.SAMHUB, Config.Estado

    local Fila = {}
    Fila.Mudou = Utils.Sinal()

    local pedidos = {}
    local feitos = {}
    local rodando, pular = false, false
    local feitosNaRodada = 0

    local function avisar()
        Fila.Mudou:Fire()
    end

    function Fila.listar() return pedidos end
    function Fila.feitos() return feitos end
    function Fila.rodando() return rodando end

    function Fila.adicionar(nick, nomeCasa)
        nick = string.gsub(Utils.limpar(nick or ""), "^@", "")
        if nick == "" then return false, "Digite o @username do comprador" end
        if not nomeCasa then return false, "Marque a casa na lista" end
        for _, p in ipairs(pedidos) do
            if p.casa == nomeCasa then return false, "'" .. nomeCasa .. "' já está na fila" end
        end
        local info
        for _, c in ipairs(E.todasAsCasas) do
            if c.nome == nomeCasa then info = c end
        end
        table.insert(pedidos, {
            nick = nick,
            casa = nomeCasa,
            nomeOriginal = info and info.nomeOriginal or nomeCasa,
            tipo = info and info.tipoCasa or nil,
            estado = "esperando",
        })
        avisar()
        return true
    end

    function Fila.remover(i)
        local p = pedidos[i]
        if p and not (rodando and i == 1) then
            table.remove(pedidos, i)
            avisar()
        end
    end

    function Fila.limpar()
        for i = #pedidos, 1, -1 do
            if not (rodando and i == 1) then table.remove(pedidos, i) end
        end
        avisar()
    end

    function Fila.pular()
        if rodando then pular = true end
    end

    function Fila.parar()
        if not rodando then return end
        rodando, pular = false, true
        Utils.setStatus("Parando a fila...", "aviso")
    end

    local function concluir(p, estado, detalhe)
        p.estado, p.detalhe = estado, detalhe
        table.insert(feitos, 1, { nick = p.nick, casa = p.casa, estado = estado, hora = os.date("%H:%M") })
        while #feitos > 10 do table.remove(feitos) end
    end

    local function ativarEsperando(nick)
        local resposta
        App.Trade.ativar(nick, function(achou) resposta = achou end)
        local t = 0
        while resposta == nil and t < 20 do
            task.wait(0.2)
            t += 0.2
        end
        return resposta == true
    end

    local function entregar(p)
        p.estado, p.detalhe = "entregando", nil
        pular = false
        avisar()
        Utils.setStatus(string.format("Fila %d/%d: '%s' para @%s", feitosNaRodada + 1, feitosNaRodada + #pedidos, p.casa, p.nick), "espera")

        E.casasSelecionadas = { [p.casa] = true }
        Utils.EstadoMudou:Fire()

        if not ativarEsperando(p.nick) then
            return "erro", "comprador não encontrado"
        end
        if S.LISTAR_AO_ATIVAR and not App.Casa.listarParaTroca(p) then
            App.Trade.desativar()
            return "erro", "não consegui pôr a casa à venda"
        end
        Utils.setStatus(string.format("Fila: '%s' pronta. Esperando @%s mandar o trade...", p.casa, p.nick), "espera")

        local resultado
        local conexao = App.Trade.Terminou:Connect(function(r) resultado = r end)
        while rodando and not pular and not resultado do
            task.wait(0.5)
        end
        conexao:Disconnect()

        if resultado then return "entregue" end
        App.Trade.desativar()
        if pular then return "pulado" end
        return nil
    end

    function Fila.iniciar()
        if rodando then return end
        if #pedidos == 0 then return Utils.setStatus("A fila está vazia", "aviso") end
        if App.Trade.estado() ~= "inativo" then
            return Utils.setStatus("Desative a entrega atual antes de iniciar a fila", "aviso")
        end
        rodando, feitosNaRodada = true, 0
        Utils.trabalhando()
        avisar()

        task.spawn(function()
            while rodando and pedidos[1] do
                local p = pedidos[1]
                local ok, estado, detalhe = pcall(entregar, p)
                if not ok then
                    Utils.aviso("fila: " .. tostring(estado))
                    estado, detalhe = "erro", "erro interno"
                end

                if estado == nil then
                    p.estado = "esperando"
                    break
                elseif estado == "erro" then
                    p.estado, p.detalhe = "erro", detalhe
                    rodando = false
                    Utils.setStatus("Fila parada: '" .. p.casa .. "' (" .. tostring(detalhe) .. ")", "erro")
                    break
                else
                    concluir(p, estado, detalhe)
                    table.remove(pedidos, 1)
                    feitosNaRodada += 1
                    avisar()
                    if estado == "entregue" then
                        Utils.setStatus("Fila: '" .. p.casa .. "' entregue para @" .. p.nick .. " ✅", "ok")
                    end
                    if pedidos[1] then task.wait(3) end
                end
            end
            if rodando and not pedidos[1] then
                Utils.setStatus("Fila concluída! " .. feitosNaRodada .. " entrega(s) 🎉", "ok")
            end
            rodando = false
            avisar()
        end)
    end

    return Fila
end
