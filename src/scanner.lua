return function(App)
    local Config, Utils = App.Config, App.Utils
    local S = Config.SAMHUB
    local Players = game:GetService("Players")

    local Scanner = {}

    local function pareceCasa(texto)
        local l = string.lower(texto)
        if l == "" or #texto > S.TAMANHO_MAX_NOME then return false end
        if Config.IGNORAR[l] then return false end
        if string.find(l, "%d+%s*/%s*%d+") then return false end
        if string.find(l, "[%?!:]") then return false end
        for _, palavra in ipairs(Config.PALAVRAS_CASA) do
            if string.find(l, palavra, 1, true) then return true end
        end
        return false
    end

    function Scanner.tipo(nome)
        local l = string.lower(nome)
        for _, par in ipairs(Config.TIPOS) do
            if string.find(l, par[1], 1, true) then return par[2] end
        end
        return "🏠 Casa"
    end

    local function raiz()
        local gui = Players.LocalPlayer:WaitForChild("PlayerGui")
        if S.CONTAINER_CASAS then
            return gui:FindFirstChild(S.CONTAINER_CASAS, true)
        end
        return gui
    end

    function Scanner.escanear()
        local casas, vistos = {}, {}
        local r = raiz()

        if not r then
            Utils.setStatus("Container '" .. tostring(S.CONTAINER_CASAS) .. "' não encontrado", "erro")
        else
            for _, d in ipairs(r:GetDescendants()) do
                if d:IsA("TextLabel") and Utils.visivel(d) then
                    local nome = Utils.limpar(d.Text)
                    local chave = string.lower(nome)
                    if not vistos[chave] and pareceCasa(nome) then
                        vistos[chave] = true
                        table.insert(casas, { nome = nome, tipo = Scanner.tipo(nome) })
                    end
                end
            end
            table.sort(casas, function(a, b) return a.nome < b.nome end)

            if #casas > 0 then
                Utils.setStatus(#casas .. " casa(s) encontrada(s)", "info")
            else
                Utils.setStatus("Nenhuma casa. Abra a lista de casas no jogo.", "aviso")
            end
        end

        Config.Estado.todasAsCasas = casas
        local existentes = {}
        for _, c in ipairs(casas) do existentes[c.nome] = true end
        for nome in pairs(Config.Estado.casasSelecionadas) do
            if not existentes[nome] then Config.Estado.casasSelecionadas[nome] = nil end
        end

        Utils.EstadoMudou:Fire()
        return casas
    end

    return Scanner
end
