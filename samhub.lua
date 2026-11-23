-- =============================================
-- SAMHUB v2.0 — VERSÃO COMPLETA
-- Design renovado • Menu arrastável • Busca inteligente
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
    nickAlvo = "",
    casasSelecionadas = {},
    pausado = false,
    status = "Aguardando...",
    arrastando = false,
    inicioPosicao = UDim2.new(0,0,0,0),
    inicioMouse = Vector2.new(0,0)
}

local todasAsCasas = {}

-- 🔹 Funções auxiliares
local function esperar()
    task.wait(math.random(SAMHUB.DELAY_MIN * 10, SAMHUB.DELAY_MAX * 10) / 10)
end

local function identificarTipoCasa(nome)
    local l = string.lower(nome)
    if string.find(l, "tiny home") then return "🏠 Tiny Home"
    elseif string.find(l, "mansion") then return "🏰 Mansão"
    elseif string.find(l, "castle") then return "🏯 Castelo"
    elseif string.find(l, "apartment") then return "🏢 Apartamento"
    elseif string.find(l, "iglu") then return "❄️ Iglu"
    elseif string.find(l, "farm") then return "🌾 Fazenda"
    elseif string.find(l, "wooden") then return "🪵 Casa de Madeira"
    else return "🏠 Casa Comum" end
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

-- 🔹 Escanear Inventário — Busca Inteligente
local function escanearCasas()
    todasAsCasas = {}
    Config.status = "🔍 Procurando casinhas..."
    
    local playerGui = game.Players.LocalPlayer.PlayerGui
    
    for _, gui in pairs(playerGui:GetChildren()) do
        if gui:IsA("GuiBase") then
            for _, d in pairs(gui:GetDescendants()) do
                if d:IsA("TextLabel") then
                    local nome = d.Text
                    if nome and (string.find(string.lower(nome), "home") 
                        or string.find(string.lower(nome), "house")
                        or string.find(string.lower(nome), "casa")) then
                        
                        local jaExiste = false
                        for _,c in ipairs(todasAsCasas) do
                            if string.lower(c.nome) == string.lower(nome) then 
                                jaExiste = true 
                                break 
                            end
                        end
                        
                        if not jaExiste and #nome < 35 then
                            table.insert(todasAsCasas, {
                                nome = nome,
                                tipo = identificarTipoCasa(nome)
                            })
                        end
                    end
                end
            end
        end
    end
    
    if #todasAsCasas > 0 then
        Config.status = "✅ " .. #todasAsCasas .. " casinhas encontradas!"
    else
        Config.status = "⚠️ Abra a lista de casas primeiro!"
    end
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
-- 🖥️ CRIAÇÃO DO MENU — DESIGN NOVO + ARRASTÁVEL
-- =============================================
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")

-- Remove menu antigo
if CoreGui:FindFirstChild("SAMHUB_Menu") then
    CoreGui.SAMHUB_Menu:Destroy()
end

local Menu = Instance.new("ScreenGui")
Menu.Name = "SAMHUB_Menu"
Menu.Parent = CoreGui
Menu.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Fundo principal com cantos arredondados
local MainFrame = Instance.new("Frame")
MainFrame.Parent = Menu
MainFrame.BackgroundColor3 = Color3.fromRGB(22, 24, 28)
MainFrame.BorderColor3 = Color3.fromRGB(58, 146, 248)
MainFrame.BorderSizePixel = 2
MainFrame.Position = UDim2.new(0.05, 0, 0.05, 0)
MainFrame.Size = UDim2.new(0, 300, 0, 380)
MainFrame.ClipsDescendants = true

-- Barra superior para arrastar
local BarraTitulo = Instance.new("Frame")
BarraTitulo.Parent = MainFrame
BarraTitulo.BackgroundColor3 = Color3.fromRGB(58, 146, 248)
BarraTitulo.Size = UDim2.new(1, 0, 0, 36)
BarraTitulo.Position = UDim2.new(0, 0, 0, 0)

local Titulo = Instance.new("TextLabel")
Titulo.Parent = BarraTitulo
Titulo.BackgroundTransparency = 1
Titulo.Position = UDim2.new(0, 12, 0, 0)
Titulo.Size = UDim2.new(1, -40, 1, 0)
Titulo.Font = Enum.Font.GothamBold
Titulo.Text = "🚀 SAMHUB — Entrega"
Titulo.TextColor3 = Color3.fromRGB(255, 255, 255)
Titulo.TextSize = 14

local DicaArrastar = Instance.new("TextLabel")
DicaArrastar.Parent = BarraTitulo
DicaArrastar.BackgroundTransparency = 1
DicaArrastar.Position = UDim2.new(1, -35, 0, 0)
DicaArrastar.Size = UDim2.new(0, 25, 1, 0)
DicaArrastar.Font = Enum.Font.Gotham
DicaArrastar.Text = "⋮⋮"
DicaArrastar.TextColor3 = Color3.fromRGB(220, 240, 255)
DicaArrastar.TextSize = 12

-- Caixa de status
local StatusContainer = Instance.new("Frame")
StatusContainer.Parent = MainFrame
StatusContainer.BackgroundColor3 = Color3.fromRGB(30, 34, 42)
StatusContainer.BorderSizePixel = 0
StatusContainer.Position = UDim2.new(0, 15, 0, 48)
StatusContainer.Size = UDim2.new(1, -30, 0, 32)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Parent = StatusContainer
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 10, 0, 0)
StatusLabel.Size = UDim2.new(1, -20, 1, 0)
StatusLabel.Font = Enum.Font.GothamSemibold
StatusLabel.Text = "⚡ Status: Pronto"
StatusLabel.TextColor3 = Color3.fromRGB(100, 210, 255)
StatusLabel.TextSize = 11

-- Nick Input
local NickLabel = Instance.new("TextLabel")
NickLabel.Parent = MainFrame
NickLabel.BackgroundTransparency = 1
NickLabel.Position = UDim2.new(0, 15, 0, 90)
NickLabel.Size = UDim2.new(1, -30, 0, 18)
NickLabel.Font = Enum.Font.GothamSemibold
NickLabel.Text = "👤 Nick do comprador:"
NickLabel.TextColor3 = Color3.fromRGB(180, 190, 210)
NickLabel.TextSize = 10

local NickInput = Instance.new("TextBox")
NickInput.Parent = MainFrame
NickInput.BackgroundColor3 = Color3.fromRGB(40, 44, 54)
NickInput.BorderSizePixel = 0
NickInput.Position = UDim2.new(0, 15, 0, 108)
NickInput.Size = UDim2.new(1, -30, 0, 34)
NickInput.Font = Enum.Font.Gotham
NickInput.PlaceholderText = "Digite o nick aqui..."
NickInput.TextColor3 = Color3.fromRGB(255, 255, 255)
NickInput.PlaceholderColor3 = Color3.fromRGB(120, 130, 150)
NickInput.TextSize = 11

-- Separador
local Separator = Instance.new("Frame")
Separator.Parent = MainFrame
Separator.BackgroundColor3 = Color3.fromRGB(50, 54, 64)
Separator.Position = UDim2.new(0, 15, 0, 155)
Separator.Size = UDim2.new(1, -30, 0, 1)

-- Lista de Casas
local ListaLabel = Instance.new("TextLabel")
ListaLabel.Parent = MainFrame
ListaLabel.BackgroundTransparency = 1
ListaLabel.Position = UDim2.new(0, 15, 0, 162)
ListaLabel.Size = UDim2.new(1, -30, 0, 18)
ListaLabel.Font = Enum.Font.GothamSemibold
ListaLabel.Text = "🏠 Suas Casas:"
ListaLabel.TextColor3 = Color3.fromRGB(180, 190, 210)
ListaLabel.TextSize = 10

local ScrollCasas = Instance.new("ScrollingFrame")
ScrollCasas.Parent = MainFrame
ScrollCasas.BackgroundColor3 = Color3.fromRGB(30, 34, 42)
ScrollCasas.BorderSizePixel = 0
ScrollCasas.Position = UDim2.new(0, 15, 0, 182)
ScrollCasas.Size = UDim2.new(1, -30, 0, 95)
ScrollCasas.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollCasas.ScrollBarThickness = 4
ScrollCasas.ScrollBarColor3 = Color3.fromRGB(80, 90, 100)

-- Botões
local BotaoScan = Instance.new("TextButton")
BotaoScan.Parent = MainFrame
BotaoScan.BackgroundColor3 = Color3.fromRGB(58, 146, 248)
BotaoScan.Position = UDim2.new(0, 15, 0, 292)
BotaoScan.Size = UDim2.new(0.5, -22, 0, 36)
BotaoScan.Font = Enum.Font.GothamBold
BotaoScan.Text = "🔍 Escanear"
BotaoScan.TextColor3 = Color3.fromRGB(255, 255, 255)
BotaoScan.TextSize = 11
BotaoScan.AutoButtonColor = true

local BotaoAtivar = Instance.new("TextButton")
BotaoAtivar.Parent = MainFrame
BotaoAtivar.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
BotaoAtivar.Position = UDim2.new(0.5, 7, 0, 292)
BotaoAtivar.Size = UDim2.new(0.5, -22, 0, 36)
BotaoAtivar.Font = Enum.Font.GothamBold
BotaoAtivar.Text = "✅ Ativar"
BotaoAtivar.TextColor3 = Color3.fromRGB(255, 255, 255)
BotaoAtivar.TextSize = 11

local BotaoReset = Instance.new("TextButton")
BotaoReset.Parent = MainFrame
BotaoReset.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
BotaoReset.Position = UDim2.new(0, 15, 0, 338)
BotaoReset.Size = UDim2.new(1, -30, 0, 28)
BotaoReset.Font = Enum.Font.GothamBold
BotaoReset.Text = "🔄 Resetar Tudo"
BotaoReset.TextColor3 = Color3.fromRGB(255, 255, 255)
BotaoReset.TextSize = 10

-- 🔹 Sistema de Arrastar o Menu
BarraTitulo.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Config.arrastando = true
        Config.inicioPosicao = MainFrame.Position
        Config.inicioMouse = UIS:GetMouseLocation()
    end
end)

UIS.InputChanged:Connect(function(input)
    if Config.arrastando and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = UIS:GetMouseLocation() - Config.inicioMouse
        MainFrame.Position = UDim2.new(
            Config.inicioPosicao.X.Scale,
            Config.inicioPosicao.X.Offset + delta.X,
            Config.inicioPosicao.Y.Scale,
            Config.inicioPosicao.Y.Offset + delta.Y
        )
    end
end)

BarraTitulo.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Config.arrastando = false
    end
end)

-- 🔹 Atualizar Lista de Casas
local function atualizarLista()
    for _,v in pairs(ScrollCasas:GetChildren()) do
        if v:IsA("GuiObject") then v:Destroy() end
    end
    Config.casasSelecionadas = {}
    
    for i, casa in ipairs(todasAsCasas) do
        local btn = Instance.new("TextButton")
        btn.Parent = ScrollCasas
        btn.BackgroundTransparency = 1
        btn.Position = UDim2.new(0, 8, 0, (i-1)*22)
        btn.Size = UDim2.new(1, -16, 0, 20)
        btn.Font = Enum.Font.Gotham
        btn.Text = "⬜ " .. casa.tipo .. " — " .. casa.nome
        btn.TextColor3 = Color3.fromRGB(160, 170, 190)
        btn.TextSize = 9
        
        btn.MouseButton1Click:Connect(function()
            local idx = table.find(Config.casasSelecionadas, i)
            if idx then
                table.remove(Config.casasSelecionadas, idx)
                btn.Text = "⬜ " .. casa.tipo .. " — " .. casa.nome
                btn.TextColor3 = Color3.fromRGB(160, 170, 190)
            else
                table.insert(Config.casasSelecionadas, i)
                btn.Text = "✅ " .. casa.tipo .. " — " .. casa.nome
                btn.TextColor3 = Color3.fromRGB(80, 220, 120)
            end
        end)
    end
    ScrollCasas.CanvasSize = UDim2.new(0, 0, 0, #todasAsCasas * 22)
end

-- 🔹 Eventos dos Botões
BotaoScan.MouseButton1Click:Connect(function()
    escanearCasas()
    atualizarLista()
end)

BotaoAtivar.MouseButton1Click:Connect(function()
    local nick = NickInput.Text
    if nick == "" then
        Config.status = "⚠️ Digite o nick primeiro!"
        return
    end
    if #Config.casasSelecionadas == 0 then
        Config.status = "⚠️ Selecione pelo menos 1 casa!"
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
        StatusLabel.Text = "⚡ Status: " .. Config.status
    end
end)

-- =============================================
-- 🔄 LOOP PRINCIPAL
-- =============================================
print("✅ SAMHUB v2.0 INICIADO COM SUCESSO!")

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
            recusar(janela, "Não foi possível ler o nome")
            continue
        end
        
        Config.status = "📩 Trade recebido de: " .. nomeParceiro
        print("[SAMHUB] Trade de: " .. nomeParceiro .. " | Esperado: " .. Config.nickAlvo)
        
        if string.lower(nomeParceiro) == string.lower(Config.nickAlvo) then
            Config.status = "✅ NOME CONFIRMADO — Aceitando!"
            confirmarTrade(janela)
            task.wait(3)
        else
            recusar(janela, "Nome não corresponde")
        end
    end
end)
