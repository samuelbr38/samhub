return function(App)
    local Config, Utils = App.Config, App.Utils
    local S = Config.SAMHUB

    local Historico = {}
    Historico.Mudou = Utils.Sinal()

    local registros = {}

    local function salvar()
        Utils.salvarJSON(S.ARQUIVO_HISTORICO, registros)
        Historico.Mudou:Fire()
    end

    function Historico.carregar()
        local dados = Utils.lerJSON(S.ARQUIVO_HISTORICO)
        if type(dados) == "table" then
            registros = dados
            Historico.Mudou:Fire()
        end
    end

    function Historico.registrar(nick, userId, resultado, detalhe)
        table.insert(registros, 1, {
            hora = os.date("%d/%m %H:%M"),
            nick = nick or "?",
            userId = userId,
            resultado = resultado,
            detalhe = detalhe or "",
        })
        while #registros > S.MAX_HISTORICO do
            table.remove(registros)
        end
        salvar()
    end

    function Historico.limpar()
        registros = {}
        salvar()
    end

    function Historico.listar()
        return registros
    end

    function Historico.texto()
        local linhas = {}
        for _, r in ipairs(registros) do
            table.insert(linhas, string.format("[%s] @%s (%s) — %s %s",
                r.hora, r.nick, tostring(r.userId or "?"), r.resultado, r.detalhe))
        end
        return #linhas > 0 and table.concat(linhas, "\n") or "(sem registros)"
    end

    return Historico
end
