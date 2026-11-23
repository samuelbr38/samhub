return function(App)
    local Utils = App.Utils
    local Players = game:GetService("Players")

    local Mapeador = {}

    function Mapeador.mapear(raiz)
        raiz = raiz or Players.LocalPlayer:WaitForChild("PlayerGui")
        local linhas = {}

        for _, d in ipairs(raiz:GetDescendants()) do
            if (d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox")) and Utils.visivel(d) then
                local texto = Utils.limpar(d.Text)
                if texto ~= "" then
                    table.insert(linhas, string.format("%s [%s] = %q", d:GetFullName(), d.ClassName, texto))
                end
            end
        end

        local saida = table.concat(linhas, "\n")
        print("===== SAMHUB: MAPA DA UI (" .. #linhas .. " itens) =====\n" .. saida)
        local copiou = Utils.copiar(saida)
        Utils.setStatus(#linhas .. " itens mapeados (F9" .. (copiou and " e área de transferência)" or ")"), "info")
        return linhas
    end

    return Mapeador
end
