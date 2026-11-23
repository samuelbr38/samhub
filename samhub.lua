-- =============================================
-- SAMHUB v1.0 — Configurado para SEU Adopt Me
-- =============================================

local SAMHUB = {
    WEBHOOK_URL = "",
    DELAY_MIN = 0.8,
    DELAY_MAX = 2.5,
    NOME_JANELA_TRADE = "TradeApp",
    NOME_PARCEIRO_TEXTO = "PartnerLabel",
    TEXTO_ACEITAR = "Accept",
    TEXTO_RECUSAR = "Decline",
    SENHA_MENU = "",
    TEMPORIZADOR_ESPERA = 180,
    LIMITE_TENTATIVAS = 3
}

local todasAsCasas = {}
local entregaAtual = {
    nickDestinatario = "",
    casasSelecionadas = {},
    pausado = false,
    status = "Aguardando configuração",
    tentativasFalhas = 0,
    historico = {}
}

local Config = {
    webhook = "",
    ultimoNick = ""
}

local function esperar()
    local tempo = math.random(SAMHUB.DELAY_MIN * 10, SAMHUB.DELAY_MAX * 10) / 10
    task.wait(tempo)
end

local function identificarTipoCasa(nome)
    local l = string.lower(nome)
    if string.find(l, "mansao") or string.find(l, "mansion") then return "🏰 Mansão"
    elseif string.find(l, "castelo") or string.find(l, "castle") then return "🏯 Castelo"
    elseif string.find(l, "casa de madeira") or string.find(l, "wooden house") then return "🪵 Casa de Madeira"
    elseif string.find(l, "apartamento") or string.find(l, "apartment") then return "🏢 Apartamento"
    elseif string.find(l, "iglu") then return "❄️ Iglu"
    elseif string.find(l, "fazenda") or string.find(l, "farm") then return "🌾 Fazenda"
    else return "🏠 Casa Comum" end
end

local function enviarWebhook(tipo, mensagem, detalhes)
    if not Config.webhook or Config.webhook == "" then return end
    local payload = {
        embeds = {{
            title = "SAMHUB — " .. tipo,
            description = mensagem,
            color = tipo == "ERRO" and 16711680 or tipo == "SUCESSO" and 65280 or 16776960,
            fields = detalhes,
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }
    local HttpService = game:GetService("HttpService")
    pcall(function()
        HttpService:PostAsync(Config.webhook, HttpService:JSONEncode(payload))
    end)
end

local function escanearInventario()
    todasAsCasas = {}
    local inventarioGui = game.Players.LocalPlayer.PlayerGui:FindFirstChild("BackpackApp", true)
    if not inventarioGui then
        entregaAtual.status = "❌ Abra o Mochila primeiro"
        return
    end
    local listaItens = inventarioGui:FindFirstChildOfClass("ScrollingFrame")
    if listaItens then
        for _, item in pairs(listaItens:GetChildren()) do
            if item:IsA("GuiObject") and item:FindFirstChild("TextLabel") then
                local nome = item.TextLabel.Text
                if nome and (string.find(string.lower(nome), "casa") or string.find(string.lower(nome), "house")) then
                    table.insert(todasAsCasas, {
                        nome = nome,
                        tipo = identificarTipoCasa(nome),
                        objeto = item
                    })
                end
            end
        end
    end
    entregaAtual.status = "✅ " .. #todasAsCasas .. " casinhas encontradas"
    print("[SAMHUB] " .. #todasAsCasas .. " casinhas carregadas")
end

local function pegarJanelaTrade()
    return game.Players.LocalPlayer.PlayerGui:FindFirstChild(SAMHUB.NOME_JANELA_TRADE, true)
end

local function pegarNomeParceiro(janela)
    for _, d in pairs(janela:GetDescendants()) do
        if d:IsA("TextLabel") and d.Name == SAMHUB.NOME_PARCEIRO_TEXTO then
            return string.lower(d.Text)
        end
    end
    return nil
end

local function nomesSaoIguais(nome1, nome2)
    return string.lower(nome1 or "") == string.lower(nome2 or "")
end

local function clicarBotaoPorTexto(janela, texto)
    for _, d in pairs(janela:GetDescendants()) do
        if (d:IsA("TextButton") or d:IsA("TextLabel")) and string.lower(d.Text or "") == string.lower(texto) then
            pcall(function() d:Activate() end)
            return true
        end
    end
    return false
end

local function recusarTrade(janela, motivo)
    esperar()
    clicarBotaoPorTexto(janela, SAMHUB.TEXTO_RECUSAR)
    entregaAtual.status = "❌ Recusado: " .. motivo
    print("[SAMHUB] Recusado: " .. motivo)
    enviarWebhook("INFO", "Trade recusado", {{name = "Motivo", value = motivo}})
    task.wait(1.5)
end

local function confirmarTrade(janela)
    esperar()
    if clicarBotaoPorTexto(janela, SAMHUB.TEXTO_ACEITAR) then
        entregaAtual.status = "✅ TRADE CONCLUÍDO!"
        print("[SAMHUB] SUCESSO — Entrega feita para " .. entregaAtual.nickDestinatario)
        local lista = ""
        for _, n in ipairs(entregaAtual.casasSelecionadas) do
            if todasAsCasas[n] then
                lista = lista .. todasAsCasas[n].tipo .. " — " .. todasAsCasas[n].nome .. "\n"
            end
        end
        table.insert(entregaAtual.historico, {
            nick = entregaAtual.nickDestinatario,
            itens = lista,
            data = os.date("%d/%m %H:%M")
        })
        enviarWebhook("SUCESSO", "Entrega concluída!", {
            {name = "Destinatário", value = entregaAtual.nickDestinatario},
            {name = "Itens", value = lista}
        })
        entregaAtual.casasSelecionadas = {}
        entregaAtual.nickDestinatario = ""
    end
end

local function executarEntrega(janela)
    entregaAtual.status = "📦 Colocando itens..."
    local sucesso = true
    for _, num in ipairs(entregaAtual.casasSelecionadas) do
        if todasAsCasas[num] then
            print("[SAMHUB] Entregando: " .. todasAsCasas[num].nome)
        end
    end
    esperar()
    confirmarTrade(janela)
end

-- =============================================
-- 🖥️ MOD MENU LEVE
-- =============================================
local CoreGui = game:GetService("CoreGui")
local Menu = Instance.new("ScreenGui")
Menu.Name = "SAMHUB_Menu"
Menu.Parent = CoreGui
Menu.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
if gethui then Menu.Parent = gethui() end

local MainFrame = Instance.new("Frame")
MainFrame.Parent = Menu
MainFrame.BackgroundColor3 = Color3.fromRGB(12,12,12)
MainFrame.BorderColor3 = Color3.fromRGB(0, 180, 180)
MainFrame.BorderSizePixel = 1
MainFrame.Position = UDim2.new(0.02,0,0.02,0)
MainFrame.Size = UDim2.new(0, 280, 0, 330)

local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(0,150,150)
Title.Size = UDim2.new(1,0,0,30)
Title.Font = Enum.Font.GothamBold
Title.Text = "SAMHUB v1.0"
Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.TextSize = 12

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0.04,0,0.11,0)
StatusLabel.Size = UDim2.new(0.92,0,0,18)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Text = "Status: Pronto"
StatusLabel.TextColor3 = Color3.fromRGB(0,200,200)
StatusLabel.TextSize = 10

local WebhookInput = Instance.new("TextBox")
WebhookInput.Parent = MainFrame
WebhookInput.BackgroundColor3 = Color3.fromRGB(30,30,30)
WebhookInput.Position = UDim2.new(0.04,0,0.18,0)
WebhookInput.Size = UDim2.new(0.92,0,0,26)
WebhookInput.PlaceholderText = "Webhook do Discord (opcional)"
WebhookInput.Font = Enum.Font.Gotham
WebhookInput.TextColor3 = Color3.fromRGB(200,200,200)
WebhookInput.TextSize = 9
WebhookInput.Text = Config.webhook or ""

local NickInput = Instance.new("TextBox")
NickInput.Parent = MainFrame
NickInput.BackgroundColor3 = Color3.fromRGB(30,30,30)
NickInput.Position = UDim2.new(0.04,0,0.27,0)
NickInput.Size = UDim2.new(0.92,0,0,26)
NickInput.PlaceholderText = "Nick do comprador"
NickInput.Font = Enum.Font.Gotham
NickInput.TextColor3 = Color3.fromRGB(255,255,255)
NickInput.TextSize = 10

local ScrollCasas = Instance.new("ScrollingFrame")
ScrollCasas.Parent = MainFrame
ScrollCasas.BackgroundColor3 = Color3.fromRGB(22,22,22)
ScrollCasas.Position = UDim2.new(0.04,0,0.37,0)
ScrollCasas.Size = UDim2.new(0.92,0,0,110)
ScrollCasas.CanvasSize = UDim2.new(0,0,0,0)
ScrollCasas.ScrollBarThickness = 3

local BotaoScan = Instance.new("TextButton")
BotaoScan.Parent = MainFrame
BotaoScan.BackgroundColor3 = Color3.fromRGB(0,100,170)
BotaoScan.Position = UDim2.new(0.04,0,0.71,0)
BotaoScan.Size = UDim2.new(0.44,0,0,26)
BotaoScan.Font = Enum.Font.GothamBold
BotaoScan.Text = "🔍 Escanear"
BotaoScan.TextColor3 = Color3.fromRGB(255,255,255)
BotaoScan.TextSize = 10

local BotaoAtivar = Instance.new("TextButton")
BotaoAtivar.Parent = MainFrame
BotaoAtivar.BackgroundColor3 = Color3.fromRGB(0,160,70)
BotaoAtivar.Position = UDim2.new(0.52,0,0.71,0)
BotaoAtivar.Size = UDim2.new(0.44,0,0,26)
BotaoAtivar.Font = Enum.Font.GothamBold
BotaoAtivar.Text = "✅ Ativar"
BotaoAtivar.TextColor3 = Color3.fromRGB(255,255,255)
BotaoAtivar.TextSize = 10

local BotaoPausar = Instance.new("TextButton")
BotaoPausar.Parent = MainFrame
BotaoPausar.BackgroundColor3 = Color3.fromRGB(150,110,0)
BotaoPausar.Position = UDim2.new(0.04,0,0.82,0)
BotaoPausar.Size = UDim2.new(0.44,0,0,26)
BotaoPausar.Font = Enum.Font.GothamBold
BotaoPausar.Text = "⏸️ Pausar"
BotaoPausar.TextColor3 = Color3.fromRGB(255,255,255)
BotaoPausar.TextSize = 10

local BotaoReset = Instance.new("TextButton")
BotaoReset.Parent = MainFrame
BotaoReset.BackgroundColor3 = Color3.fromRGB(140,20,20)
BotaoReset.Position = UDim2.new(0.52,0,0.82,0)
BotaoReset.Size = UDim2.new(0.44,0,0,26)
BotaoReset.Font = Enum.Font.GothamBold
BotaoReset.Text = "🔄 Reset"
BotaoReset.TextColor3 = Color3.fromRGB(255,255,255)
BotaoReset.TextSize = 10

local function atualizarListaCasas()
    for _,v in pairs(ScrollCasas:GetChildren()) do if v:IsA("GuiObject") and v ~= ScrollCasas then v:Destroy() end end
    for i,casa in ipairs(todasAsCasas) do
        local btn = Instance.new("TextButton")
        btn.Parent = ScrollCasas
        btn.BackgroundTransparency = 1
        btn.Position = UDim2.new(0,6,0, (i-1)*19)
        btn.Size = UDim2.new(0,250,0,18)
        btn.Font = Enum.Font.Gotham
        btn.Text = "⬜ " .. casa.tipo .. " — " .. casa.nome
        btn.TextColor3 = Color3.fromRGB(210,210,210)
        btn.TextSize = 9
        btn.MouseButton1Click:Connect(function()
            local idx = table.find(entregaAtual.casasSelecionadas, i)
            if idx then
                table.remove(entregaAtual.casasSelecionadas, idx)
                btn.Text = "⬜ " .. casa.tipo .. " — " .. casa.nome
                btn.TextColor3 = Color3.fromRGB(210,210,210)
            else
                table.insert(entregaAtual.casasSelecionadas, i)
                btn.Text = "✅ " .. casa.tipo .. " — " .. casa.nome
                btn.TextColor3 = Color3.fromRGB(80,220,120)
            end
        end)
    end
    ScrollCasas.CanvasSize = UDim2.new(0,0,0,#todasAsCasas*19,0)
end

WebhookInput.FocusLost:Connect(function()
    Config.webhook = WebhookInput.Text
    SAMHUB.WEBHOOK_URL = Config.webhook
    print("[SAMHUB] Webhook atualizado")
end)

BotaoScan.MouseButton1Click:Connect(function()
    escanearInventario()
    atualizarListaCasas()
end)

BotaoAtivar.MouseButton1Click:Connect(function()
    local nick = NickInput.Text
    if not nick or nick == "" then
        entregaAtual.status = "⚠️ Digite um nick!"
        return
    end
    if #entregaAtual.casasSelecionadas == 0 then
        entregaAtual.status = "⚠️ Selecione pelo menos 1 casa!"
        return
    end
    entregaAtual.nickDestinatario = nick
    entregaAtual.pausado = false
    entregaAtual.status = "✅ Aguardando trade de " .. nick
    print("[SAMHUB] Ativado — Aguardando: " .. nick)
    enviarWebhook("INFO", "Bot ativado", {{name = "Destinatário", value = nick}, {name = "Casas", value = tostring(#entregaAtual.casasSelecionadas)}})
end)

BotaoPausar.MouseButton1Click:Connect(function()
    entregaAtual.pausado = not entregaAtual.pausado
    BotaoPausar.Text = entregaAtual.pausado and "▶️ Retomar" or "⏸️ Pausar"
    entregaAtual.status = entregaAtual.pausado and "⏸️ PAUSADO" or "▶️ Aguardando trade"
    enviarWebhook("INFO", entregaAtual.pausado and "Bot pausado" or "Bot retomado", {})
end)

BotaoReset.MouseButton1Click:Connect(function()
    entregaAtual.nickDestinatario = ""
    entregaAtual.casasSelecionadas = {}
    entregaAtual.pausado = false
    NickInput.Text = ""
    atualizarListaCasas()
    entregaAtual.status = "🔄 Resetado — Pronto"
    print("[SAMHUB] Resetado")
end)

task.spawn(function()
    while true do
        task.wait(0.3)
        StatusLabel.Text = "Status: " .. entregaAtual.status
    end
end)

-- =============================================
-- 🔄 LOOP PRINCIPAL
-- =============================================
print("[SAMHUB] Iniciado — Aguardando configuração")
enviarWebhook("INFO", "SAMHUB iniciado", {{name = "Versão", value = "v1.0"}})

while true do
    task.wait(0.5)
    if entregaAtual.pausado or entregaAtual.nickDestinatario == "" then goto continue end
    local janela = pegarJanelaTrade()
    if not janela then goto continue end
    local nomeParceiro = pegarNomeParceiro(janela)
    if not nomeParceiro then
        recusarTrade(janela, "Não foi possível ler o nome")
        goto continue
    end
    entregaAtual.status = "📩 Trade de: " .. nomeParceiro
    print("[SAMHUB] Pedido de: " .. nomeParceiro .. " | Esperado: " .. entregaAtual.nickDestinatario)
    if nomesSaoIguais(nomeParceiro, entregaAtual.nickDestinatario) then
        entregaAtual.status = "✅ NOME CONFIRMADO — Entregando..."
        executarEntrega(janela)
        task.wait(3)
    else
        recusarTrade(janela, "Nome não corresponde (espera: " .. entregaAtual.nickDestinatario .. ")")
    end
    ::continue::
    esperar()
end
