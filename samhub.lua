-- =============================================
-- SAMHUB — VERSÃO SIMPLIFICADA E GARANTIDA
-- =============================================

-- 🔹 Configurações
local SAMHUB = {
    NOME_JANELA_TRADE = "TradeApp",
    NOME_PARCEIRO = "PartnerLabel",
    TEXTO_ACEITAR = "Accept",
    TEXTO_RECUSAR = "Decline",
    DELAY_MIN = 0.8,
    DELAY_MAX = 2.5
}

local Config = {
    webhook = "",
    nickAlvo = "",
    casasSelecionadas = {},
    pausado = false,
    status = "Aguardando..."
}

local todasAsCasas = {}

-- 🔹 Funções auxiliares
local function esperar()
    task.wait(math.random(SAMHUB.DELAY_MIN * 10, SAMHUB.DELAY_MAX * 10) / 10)
end

local function identificarTipoCasa(nome)
    local l = string.lower(nome)
    if string.find(l, "mansao") or string.find(l, "mansion") then return "🏰 Mansão"
    elseif string.find(l, "castelo") or string.find(l, "castle") then return "🏯 Castelo"
    elseif string.find(l, "wooden") then return "🪵 Casa de Madeira"
    else return "🏠 Casa" end
end

local function clicarPorTexto(pai, texto)
    for _, d in pairs(pai:GetDescendants()) do
        if (d:IsA("TextButton") or d:IsA("TextLabel")) 
            and string.lower(d.Text or "") == string.lower(texto) then
            pcall(function() d:Activate() end)
            return true
        end
    end
    return false
end

-- 🔹 Escanear Inventário
local function escanearCasas()
    todasAsCasas = {}
    local backpack = game.Players.LocalPlayer.PlayerGui:FindFirstChild("BackpackApp", true)
    if not backpack then
        Config.status = "❌ Abra a Mochila primeiro"
        return
    end
    
    local scroller = backpack:FindFirstChildOfClass("ScrollingFrame")
    if not scroller then return end
    
    for _, item in pairs(scroller:GetChildren()) do
        if item:FindFirstChild("TextLabel") then
            local nome = item.TextLabel.Text
            if string.find(string.lower(nome), "casa") or string.find(string.lower(nome), "house") then
                table.insert(todasAsCasas, {
                    nome = nome,
                    tipo = identificarTipoCasa(nome)
                })
            end
        end
    end
    Config.status = "✅ " .. #todasAsCasas .. " casinhas encontradas"
end

-- 🔹 Sistema de Trade
local function pegarJanelaTrade()
    return game.Players.LocalPlayer.PlayerGui:FindFirstChild(SAMHUB.NOME_JANELA_TRADE, true)
end

local function pegarNomeParceiro(janela)
    local label = janela:FindFirstChild(SAMHUB.NOME_PARCEIRO, true)
    return label and string.lower(label.Text) or nil
end

local function recusar(janela, motivo)
    esperar()
    clicarPorTexto(janela, SAMHUB.TEXTO_RECUSAR)
    Config.status = "❌ Recusado: " .. motivo
end

local function confirmarTrade(janela)
    esperar()
    clicarPorTexto(janela, SAMHUB.TEXTO_ACEITAR)
    Config.status = "✅ TRADE CONCLUÍDO!"
    Config.nickAlvo = ""
    Config.casasSelecionadas = {}
end

-- =============================================
-- 🖥️ CRIAÇÃO DO MENU
-- =============================================
local CoreGui = game:GetService("CoreGui")

-- Remove menu antigo
if CoreGui:FindFirstChild("SAMHUB_Menu") then
    CoreGui.SAMHUB_Menu:Destroy()
end

local Menu = Instance.new("ScreenGui")
Menu.Name = "SAMHUB_Menu"
Menu.Parent = CoreGui
Menu.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MainFrame = Instance.new("Frame")
MainFrame.Parent = Menu
MainFrame.BackgroundColor3 = Color3.fromRGB(12,12,12)
MainFrame.BorderColor3 = Color3.fromRGB(0, 200, 200)
MainFrame.BorderSizePixel = 1
MainFrame.Position = UDim2.new(0.02,0,0.02,0)
MainFrame.Size = UDim2.new(0, 270, 0, 320)

-- Título
local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(0,150,150)
Title.Size = UDim2.new(1,0,0,30)
Title.Font = Enum.Font.GothamBold
Title.Text = "SAMHUB — Entrega"
Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.TextSize = 12

-- Status
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0.04,0,0.11,0)
StatusLabel.Size = UDim2.new(0.92,0,0,18)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Text = "Status: Pronto"
StatusLabel.TextColor3 = Color3.fromRGB(0,200,200)
StatusLabel.TextSize = 10

-- Nick Input
local NickInput = Instance.new("TextBox")
NickInput.Parent = MainFrame
NickInput.BackgroundColor3 = Color3.fromRGB(35,35,35)
NickInput.Position = UDim2.new(0.04,0,0.20,0)
NickInput.Size = UDim2.new(0.92,0,0,28)
NickInput.PlaceholderText = "Nick do comprador"
NickInput.Font = Enum.Font.Gotham
NickInput.TextColor3 = Color3.fromRGB(255,255,255)
NickInput.TextSize = 10

-- Lista de Casas
local ScrollCasas = Instance.new("ScrollingFrame")
ScrollCasas.Parent = MainFrame
ScrollCasas.BackgroundColor3 = Color3.fromRGB(25,25,25)
ScrollCasas.Position = UDim2.new(0.04,0,0.32,0)
ScrollCasas.Size = UDim2.new(0.92,0,0,120)
ScrollCasas.CanvasSize = UDim2.new(0,0,0,0)
ScrollCasas.ScrollBarThickness = 3

-- Botões
local BotaoScan = Instance.new("TextButton")
BotaoScan.Parent = MainFrame
BotaoScan.BackgroundColor3 = Color3.fromRGB(0,110,180)
BotaoScan.Position = UDim2.new(0.04,0,0.70,0)
BotaoScan.Size = UDim2.new(0.44,0,0,28)
BotaoScan.Font = Enum.Font.GothamBold
BotaoScan.Text = "🔍 Escanear"
BotaoScan.TextColor3 = Color3.fromRGB(255,255,255)
BotaoScan.TextSize = 10

local BotaoAtivar = Instance.new("TextButton")
BotaoAtivar.Parent = MainFrame
BotaoAtivar.BackgroundColor3 = Color3.fromRGB(0,160,70)
BotaoAtivar.Position = UDim2.new(0.52,0,0.70,0)
BotaoAtivar.Size = UDim2.new(0.44,0,0,28)
BotaoAtivar.Font = Enum.Font.GothamBold
BotaoAtivar.Text = "✅ Ativar"
BotaoAtivar.TextColor3 = Color3.fromRGB(255,255,255)
BotaoAtivar.TextSize = 10

local BotaoReset = Instance.new("TextButton")
BotaoReset.Parent = MainFrame
BotaoReset.BackgroundColor3 = Color3.fromRGB(150,30,30)
BotaoReset.Position = UDim2.new(0.04,0,0.82,0)
BotaoReset.Size = UDim2.new(0.92,0,0,28)
BotaoReset.Font = Enum.Font.GothamBold
BotaoReset.Text = "🔄 Reset"
BotaoReset.TextColor3 = Color3.fromRGB(255,255,255)
BotaoReset.TextSize = 10

-- 🔹 Atualizar Lista
local function atualizarLista()
    for _,v in pairs(ScrollCasas:GetChildren()) do
        if v:IsA("GuiObject") then v:Destroy() end
    end
    Config.casasSelecionadas = {}
    
    for i, casa in ipairs(todasAsCasas) do
        local btn = Instance.new("TextButton")
        btn.Parent = ScrollCasas
        btn.BackgroundTransparency = 1
        btn.Position = UDim2.new(0,5,0, (i-1)*20)
        btn.Size = UDim2.new(0,250,0,18)
        btn.Font = Enum.Font.Gotham
        btn.Text = "⬜ " .. casa.tipo .. " — " .. casa.nome
        btn.TextColor3 = Color3.fromRGB(200,200,200)
        btn.TextSize = 9
        
        btn.MouseButton1Click:Connect(function()
            local idx = table.find(Config.casasSelecionadas, i)
            if idx then
                table.remove(Config.casasSelecionadas, idx)
                btn.Text = "⬜ " .. casa.tipo .. " — " .. casa.nome
                btn.TextColor3 = Color3.fromRGB(200,200,200)
            else
                table.insert(Config.casasSelecionadas, i)
                btn.Text = "✅ " .. casa.tipo .. " — " .. casa.nome
                btn.TextColor3 = Color3.fromRGB(80,220,120)
            end
        end)
    end
    ScrollCasas.CanvasSize = UDim2.new(0,0,0,#todasAsCasas*20,0)
end

-- 🔹 Eventos dos Botões
BotaoScan.MouseButton1Click:Connect(function()
    escanearCasas()
    atualizarLista()
end)

BotaoAtivar.MouseButton1Click:Connect(function()
    local nick = NickInput.Text
    if nick == "" then
        Config.status = "⚠️ Digite o nick!"
        return
    end
    if #Config.casasSelecionadas == 0 then
        Config.status = "⚠️ Selecione as casinhas!"
        return
    end
    Config.nickAlvo = string.lower(nick)
    Config.pausado = false
    Config.status = "✅ Aguardando trade de " .. nick
end)

BotaoReset.MouseButton1Click:Connect(function()
    Config.nickAlvo = ""
    Config.casasSelecionadas = {}
    NickInput.Text = ""
    atualizarLista()
    Config.status = "🔄 Pronto para novo"
end)

-- 🔹 Atualizar Status em tempo real
task.spawn(function()
    while true do
        task.wait(0.3)
        StatusLabel.Text = "Status: " .. Config.status
    end
end)

-- =============================================
-- 🔄 LOOP PRINCIPAL
-- =============================================
print("✅ SAMHUB INICIADO COM SUCESSO!")

task.spawn(function()
    while true do
        task.wait(0.5)
        
        if Config.pausado or Config.nickAlvo == "" then
            continue
        end
        
        local janela = pegarJanelaTrade()
        if not janela then
            continue
        end
        
        local nomeParceiro = pegarNomeParceiro(janela)
        if not nomeParceiro then
            recusar(janela, "Não leu o nome")
            continue
        end
        
        Config.status = "📩 Trade de: " .. nomeParceiro
        print("[SAMHUB] Trade de: " .. nomeParceiro .. " | Esperado: " .. Config.nickAlvo)
        
        if string.lower(nomeParceiro) == string.lower(Config.nickAlvo) then
            Config.status = "✅ NOME CONFIRMADO — Aceitando!"
            confirmarTrade(janela)
            task.wait(3)
        else
            recusar(janela, "Nome errado")
        end
    end
end)
