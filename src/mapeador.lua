return function(App)
    local Config, Utils = App.Config, App.Utils
    local S = Config.SAMHUB
    local Players = game:GetService("Players")
    local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

    local Mapeador = {}
    local LIMITE = 1500

    local function entregar(titulo, linhas, arquivo)
        if #linhas >= LIMITE then table.insert(linhas, "... (cortado em " .. LIMITE .. " linhas)") end
        local saida = "===== SAMHUB: " .. titulo .. " =====\n" .. table.concat(linhas, "\n")
        print(saida)
        local copiou = Utils.copiar(saida)
        local salvou = Utils.salvarTexto(arquivo, saida)
        Utils.setStatus(titulo .. ": " .. #linhas .. " linhas"
            .. (copiou and " · copiado" or "")
            .. (salvou and (" · salvo em " .. arquivo) or ""), "info")
    end

    local function arvore(raiz)
        local linhas = {}
        local function visitar(obj, nivel)
            if #linhas >= LIMITE then return end
            if obj:IsA("GuiObject") and not obj.Visible then return end
            if obj:IsA("GuiObject") or obj:IsA("LayerCollector") then
                local extra = ""
                if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                    local texto = Utils.limpar(obj.Text)
                    if texto ~= "" then extra = string.format(" %q", texto) end
                end
                if obj:IsA("GuiButton") then extra = extra .. " [clicável]" end
                if obj:IsA("GuiObject") and not Utils.naTela(obj) then extra = extra .. " [fora da tela]" end
                table.insert(linhas, string.rep("  ", nivel) .. obj.Name .. " (" .. obj.ClassName .. ")" .. extra)
                for _, filho in ipairs(obj:GetChildren()) do
                    visitar(filho, nivel + 1)
                end
            end
        end
        visitar(raiz, 0)
        return linhas
    end

    function Mapeador.mapearObjeto(raiz, titulo, arquivo)
        entregar(titulo, arvore(raiz), arquivo)
    end

    function Mapeador.mapearTrade()
        local app = PlayerGui:FindFirstChild(S.NOME_JANELA_TRADE, true)
        if not app then
            return Utils.setStatus("Não achei '" .. S.NOME_JANELA_TRADE .. "'. Use Mapear tudo.", "erro")
        end
        entregar("MAPA DO TRADE", arvore(app), "samhub_mapa_trade.txt")
    end

    function Mapeador.mapearCasas()
        local painel = App.Scanner.acharPainel()
        if not painel then
            return Utils.setStatus("Lista de casas não encontrada. Abra MY HOMES e tente de novo.", "erro")
        end
        entregar("MAPA DAS CASAS", arvore(painel), "samhub_mapa_casas.txt")
    end

    function Mapeador.mapear()
        local linhas = {}
        for _, d in ipairs(PlayerGui:GetDescendants()) do
            if #linhas >= LIMITE then break end
            if (d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox")) and Utils.naTela(d) then
                local texto = Utils.limpar(d.Text)
                if texto ~= "" then
                    table.insert(linhas, string.format("%s [%s] = %q", d:GetFullName(), d.ClassName, texto))
                end
            end
        end
        entregar("MAPA DA TELA", linhas, "samhub_mapa_tela.txt")
    end

    return Mapeador
end
