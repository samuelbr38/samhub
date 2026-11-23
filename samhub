local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

local guiPai = CoreGui
if typeof(gethui) == "function" then
    local ok, hui = pcall(gethui)
    if ok and hui then guiPai = hui end
end

local SAMHUB = {
    VERSAO = "1.0.0",
    DELAY_MIN = 0.7,
    DELAY_MAX = 3.2,
    SAVE_FILE = "samhub_config.json",
    MAX_FALHAS_ITEM = 3
}

local state = {
    webhook = "",
    nick = "",
    casas = {},
    casasData = {},
    ativo = false,
    pausado = false,
    concluido = false,
    status = "Aguardando configuracao",
    stats = {entregas = 0, recusadas = 0, erros = 0}
}

local Menu, StatusLabel, NickBox, WebhookBox, ScrollCasas, BotaoAtivar, BotaoPausar, BotaoReset, CasasContador, StatsLabel
local atualizarListaCasas

local function esperar()
    task.wait(math.random(SAMHUB.DELAY_MIN * 10, SAMHUB.DELAY_MAX * 10) / 10)
end

local function salvarConfig()
    if typeof(writefile) ~= "function" then return end
    pcall(writefile, SAMHUB.SAVE_FILE, HttpService:JSONEncode({webhook = state.webhook, nick = state.nick}))
end

local function carregarConfig()
    if typeof(readfile) ~= "function" or typeof(isfile) ~= "function" then return end
    if not isfile(SAMHUB.SAVE_FILE) then return end
    local ok, dados = pcall(function() return HttpService:JSONDecode(readfile(SAMHUB.SAVE_FILE)) end)
    if ok and type(dados) == "table" then
        state.webhook = dados.webhook or ""
        state.nick = dados.nick or ""
    end
end

local function httpPost(url, json)
    if typeof(syn) == "table" and typeof(syn.request) == "function" then
        return syn.request({Url = url, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = json})
    elseif typeof(request) == "function" then
        return request({Url = url, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = json})
    else
        return HttpService:PostAsync(url, json, Enum.HttpContentType.ApplicationJson)
    end
end

local function enviarWebhook(tipo, mensagem, campos)
    if state.webhook == "" or not state.webhook:find("https://") then return end
    for _, c in ipairs(campos or {}) do
        if type(c.value) == "string" and #c.value > 900 then c.value = c.value:sub(1, 900) .. "..." end
    end
    local payload = {embeds = {{
        title = "SAMHUB - " .. tipo,
        description = mensagem,
        color = tipo == "ERRO" and 16711680 or tipo == "SUCESSO" and 65280 or 16776960,
        fields = campos,
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }}}
    local ok, err = pcall(httpPost, state.webhook, HttpService:JSONEncode(payload))
    if not ok then print("[SAMHUB] Webhook falhou: " .. tostring(err)) end
end

local function tipoCasa(nome)
    local l = string.lower(nome)
    if l:find("mans") then return "Mansao"
    elseif l:find("cast") then return "Castelo"
    elseif l:find("madeira") or l:find("wood") then return "Madeira"
    elseif l:find("apart") then return "Apartamento"
    elseif l:find("iglu") then return "Iglu"
    elseif l:find("fazenda") or l:find("farm") then return "Fazenda"
    elseif l:find("chale") or l:find("cottage") then return "Chale"
    else return "Casa" end
end

local function acharBotoes(janela)
    local alvos = {}
    for _, d in ipairs(janela:GetDescendants()) do
        if d:IsA("TextButton") and d.Visible then
            local t = string.lower(d.Text or "")
            if not alvos.aceitar and (t:find("aceitar") or t:find("accept") or t:find("ready") or t:find("pronto")) then alvos.aceitar = d end
            if not alvos.recusar and (t:find("recusar") or t:find("decline") or t:find("cancel")) then alvos.recusar = d end
            if not alvos.confirmar and t:find("confirm") then alvos.confirmar = d end
        end
    end
    return alvos
end

local function encontrarJanelaTrade()
    for _, gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
        if gui.Name ~= "SAMHUB_Menu" then
            local botoes = acharBotoes(gui)
            if (botoes.aceitar and botoes.recusar) or botoes.confirmar then return gui, botoes end
        end
    end
    return nil
end

local function encontrarParceiro(janela)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local alvo = string.lower(p.Name)
            for _, d in ipairs(janela:GetDescendants()) do
                if d:IsA("TextLabel") and d.Visible and d.Text ~= "" and string.lower(d.Text) == alvo then
                    return p.Name
                end
            end
        end
    end
    return nil
end

local function escanearCasas()
    state.casasData = {}
    state.casas = {}
    local vistos = {}
    for _, gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
        if gui.Name ~= "SAMHUB_Menu" then
            for _, d in ipairs(gui:GetDescendants()) do
                if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Visible then
                    local t = d.Text or ""
                    local l = string.lower(t)
                    if (#t < 40) and not vistos[t] and (l:find("casa") or l:find("house")) then
                        vistos[t] = true
                        table.insert(state.casasData, {nome = t, tipo = tipoCasa(t)})
                    end
                end
            end
        end
    end
    if atualizarListaCasas then atualizarListaCasas() end
    enviarWebhook("INFO", "Inventario escaneado", {{name = "Casas encontradas", value = tostring(#state.casasData)}})
    state.status = #state.casasData > 0 and "Casas encontradas: " .. #state.casasData or "Nenhuma casa visivel - abra a aba de casas"
end

local function clicarItem(janela, nomeItem)
    local alvo = string.lower(nomeItem)
    for _, d in ipairs(janela:GetDescendants()) do
        if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Visible and string.lower(d.Text or "") == alvo then
            local btn = d:IsA("TextButton") and d or d:FindFirstAncestorWhichIsA("TextButton")
            if btn then btn:Activate() return true end
        end
    end
    return false
end

local function recusarTrade(janela, motivo)
    esperar()
    local b = acharBotoes(janela)
    if b.recusar then b.recusar:Activate() end
    state.stats.recusadas = state.stats.recusadas + 1
    state.status = "Recusado: " .. motivo
    enviarWebhook("INFO", "Trade recusado", {{name = "Motivo", value = motivo}, {name = "Esperado", value = state.nick}})
    task.wait(1.5)
end

local function confirmarTrade(janela)
    esperar()
    local b = acharBotoes(janela)
    if b.aceitar then b.aceitar:Activate() end
    esperar()
    b = acharBotoes(janela)
    if b.confirmar then b.confirmar:Activate() end
    state.stats.entregas = state.stats.entregas + 1
    state.concluido = true
    state.status = "Entrega concluida - pressione Reset"
    enviarWebhook("SUCESSO", "Trade concluido", {{name = "Destinatario", value = state.nick}, {name = "Casas", value = tostring(#state.casas)}})
end

local function executarEntrega(janela)
    state.status = "Entregando itens..."
    local falhas = 0
    for _, idx in ipairs(state.casas) do
        local casa = state.casasData[idx]
        if casa then
            if not clicarItem(janela, casa.nome) then falhas = falhas + 1 end
            esperar()
        end
    end
    if falhas >= SAMHUB.MAX_FALHAS_ITEM then
        state.stats.erros = state.stats.erros + 1
        recusarTrade(janela, "Itens nao encontrados na troca")
    else
        confirmarTrade(janela)
    end
end

local function diagnostico()
    local rel = {}
    table.insert(rel, {"Webhook", state.webhook:find("https://") and "OK" or "FALTANDO - cole no menu"})
    local temHttp = (typeof(syn) == "table" and typeof(syn.request) == "function") or typeof(request) == "function"
    table.insert(rel, {"Requisicao HTTP", temHttp and "OK" or "FALTANDO"})
    table.insert(rel, {"Salvar arquivos", typeof(writefile) == "function" and "OK" or "Indisponivel neste executor"})
    local janela, botoes = encontrarJanelaTrade()
    table.insert(rel, {"Janela de trade", janela and "OK" or "FECHADA - abra um trade com um alt e rode de novo"})
    if janela then
        table.insert(rel, {"Botao aceitar", botoes.aceitar and "OK" or "NAO ENCONTRADO"})
        table.insert(rel, {"Botao recusar", botoes.recusar and "OK" or "NAO ENCONTRADO"})
        table.insert(rel, {"Botao confirmar", botoes.confirmar and "OK" or "ausente (normal em 1 etapa)"})
        table.insert(rel, {"Parceiro", encontrarParceiro(janela) or "NAO ENCONTRADO"})
        local dump = {}
        for _, d in ipairs(janela:GetDescendants()) do
            if d:IsA("GuiObject") then
                local linha = d.ClassName .. " | " .. d.Name
                if d:IsA("TextLabel") or d:IsA("TextButton") then linha = linha .. " | '" .. tostring(d.Text) .. "'" end
                table.insert(dump, linha)
            end
        end
        if typeof(writefile) == "function" then pcall(writefile, "samhub_dump.txt", table.concat(dump, "\n")) end
    end
    local msg = ""
    for _, r in ipairs(rel) do msg = msg .. r[1] .. ": " .. r[2] .. "\n" end
    print("[SAMHUB DIAG]\n" .. msg)
    enviarWebhook("INFO", "Diagnostico executado", {{name = "Resultado", value = msg}})
    state.status = "Diagnostico concluido"
end

if typeof(getgenv) == "function" and getgenv().__SAMHUB then
    pcall(getgenv().__SAMHUB.limpar)
end

local rodando = true
local function limparInstancia()
    rodando = false
    for _, pai in ipairs({guiPai, CoreGui}) do
        local antigo = pai:FindFirstChild("SAMHUB_Menu")
        if antigo then antigo:Destroy() end
    end
end

local Menu = Instance.new("ScreenGui")
Menu.Name = "SAMHUB_Menu"
Menu.Parent = guiPai
Menu.ResetOnSpawn = false
Menu.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MainFrame = Instance.new("Frame")
MainFrame.Parent = Menu
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BorderColor3 = Color3.fromRGB(0, 180, 180)
MainFrame.BorderSizePixel = 1
MainFrame.Position = UDim2.new(0.02, 0, 0.02, 0)
MainFrame.Size = UDim2.new(0, 285, 0, 350)

local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(0, 150, 150)
Title.Size = UDim2.new(1, 0, 0, 28)
Title.Font = Enum.Font.GothamBold
Title.Text = "SAMHUB v" .. SAMHUB.VERSAO
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 13

StatusLabel = Instance.new("TextLabel")
StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0.04, 0, 0.085, 0)
StatusLabel.Size = UDim2.new(0.92, 0, 0, 16)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Text = "Status: " .. state.status
StatusLabel.TextColor3 = Color3.fromRGB(0, 220, 220)
StatusLabel.TextSize = 9

WebhookBox = Instance.new("TextBox")
WebhookBox.Parent = MainFrame
WebhookBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
WebhookBox.Position = UDim2.new(0.04, 0, 0.14, 0)
WebhookBox.Size = UDim2.new(0.92, 0, 0, 24)
WebhookBox.PlaceholderText = "Webhook do Discord (cole aqui)"
WebhookBox.Font = Enum.Font.Gotham
WebhookBox.TextColor3 = Color3.fromRGB(255, 255, 255)
WebhookBox.TextSize = 9
WebhookBox.ClearTextOnFocus = false

NickBox = Instance.new("TextBox")
NickBox.Parent = MainFrame
NickBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
NickBox.Position = UDim2.new(0.04, 0, 0.215, 0)
NickBox.Size = UDim2.new(0.92, 0, 0, 24)
NickBox.PlaceholderText = "Nick do comprador"
NickBox.Font = Enum.Font.Gotham
NickBox.TextColor3 = Color3.fromRGB(255, 255, 255)
NickBox.TextSize = 10
NickBox.ClearTextOnFocus = false

CasasContador = Instance.new("TextLabel")
CasasContador.Parent = MainFrame
CasasContador.BackgroundTransparency = 1
CasasContador.Position = UDim2.new(0.04, 0, 0.29, 0)
CasasContador.Size = UDim2.new(0.92, 0, 0, 14)
CasasContador.Font = Enum.Font.Gotham
CasasContador.Text = "Casas marcadas: 0"
CasasContador.TextColor3 = Color3.fromRGB(200, 200, 200)
CasasContador.TextSize = 9

ScrollCasas = Instance.new("ScrollingFrame")
ScrollCasas.Parent = MainFrame
ScrollCasas.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
ScrollCasas.Position = UDim2.new(0.04, 0, 0.335, 0)
ScrollCasas.Size = UDim2.new(0.92, 0, 0, 92)
ScrollCasas.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollCasas.ScrollBarThickness = 4

local BotaoEscanear = Instance.new("TextButton")
BotaoEscanear.Parent = MainFrame
BotaoEscanear.BackgroundColor3 = Color3.fromRGB(0, 100, 170)
BotaoEscanear.Position = UDim2.new(0.04, 0, 0.61, 0)
BotaoEscanear.Size = UDim2.new(0.44, 0, 0, 26)
BotaoEscanear.Font = Enum.Font.GothamBold
BotaoEscanear.Text = "Escanear"
BotaoEscanear.TextColor3 = Color3.fromRGB(255, 255, 255)
BotaoEscanear.TextSize = 10

BotaoAtivar = Instance.new("TextButton")
BotaoAtivar.Parent = MainFrame
BotaoAtivar.BackgroundColor3 = Color3.fromRGB(0, 150, 75)
BotaoAtivar.Position = UDim2.new(0.52, 0, 0.61, 0)
BotaoAtivar.Size = UDim2.new(0.44, 0, 0, 26)
BotaoAtivar.Font = Enum.Font.GothamBold
BotaoAtivar.Text = "Ativar"
BotaoAtivar.TextColor3 = Color3.fromRGB(255, 255, 255)
BotaoAtivar.TextSize = 10

BotaoPausar = Instance.new("TextButton")
BotaoPausar.Parent = MainFrame
BotaoPausar.BackgroundColor3 = Color3.fromRGB(160, 120, 0)
BotaoPausar.Position = UDim2.new(0.04, 0, 0.7, 0)
BotaoPausar.Size = UDim2.new(0.44, 0, 0, 26)
BotaoPausar.Font = Enum.Font.GothamBold
BotaoPausar.Text = "Pausar"
BotaoPausar.TextColor3 = Color3.fromRGB(255, 255, 255)
BotaoPausar.TextSize = 10

BotaoReset = Instance.new("TextButton")
BotaoReset.Parent = MainFrame
BotaoReset.BackgroundColor3 = Color3.fromRGB(150, 35, 35)
BotaoReset.Position = UDim2.new(0.52, 0, 0.7, 0)
BotaoReset.Size = UDim2.new(0.44, 0, 0, 26)
BotaoReset.Font = Enum.Font.GothamBold
BotaoReset.Text = "Reset"
BotaoReset.TextColor3 = Color3.fromRGB(255, 255, 255)
BotaoReset.TextSize = 10

local BotaoDiagnostico = Instance.new("TextButton")
BotaoDiagnostico.Parent = MainFrame
BotaoDiagnostico.BackgroundColor3 = Color3.fromRGB(90, 60, 160)
BotaoDiagnostico.Position = UDim2.new(0.04, 0, 0.79, 0)
BotaoDiagnostico.Size = UDim2.new(0.92, 0, 0, 26)
BotaoDiagnostico.Font = Enum.Font.GothamBold
BotaoDiagnostico.Text = "Diagnostico (o que falta)"
BotaoDiagnostico.TextColor3 = Color3.fromRGB(255, 255, 255)
BotaoDiagnostico.TextSize = 10

StatsLabel = Instance.new("TextLabel")
StatsLabel.Parent = MainFrame
StatsLabel.BackgroundTransparency = 1
StatsLabel.Position = UDim2.new(0.04, 0, 0.885, 0)
StatsLabel.Size = UDim2.new(0.92, 0, 0, 14)
StatsLabel.Font = Enum.Font.Gotham
StatsLabel.Text = "Entregas: 0 | Recusadas: 0 | Erros: 0"
StatsLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
StatsLabel.TextSize = 9

function atualizarListaCasas()
    for _, v in ipairs(ScrollCasas:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    for i, casa in ipairs(state.casasData) do
        local btn = Instance.new("TextButton")
        btn.Parent = ScrollCasas
        btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        btn.Size = UDim2.new(1, -10, 0, 17)
        btn.Position = UDim2.new(0, 5, 0, (i - 1) * 19)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 9
        btn.TextColor3 = Color3.fromRGB(220, 220, 220)
        local marcado = false
        for _, idx in ipairs(state.casas) do if idx == i then marcado = true break end end
        btn.Text = (marcado and "[x] " or "[ ] ") .. casa.tipo .. " - " .. casa.nome
        btn.MouseButton1Click:Connect(function()
            local achou = false
            for k, idx in ipairs(state.casas) do
                if idx == i then table.remove(state.casas, k) achou = true break end
            end
            if not achou then table.insert(state.casas, i) end
            atualizarListaCasas()
        end)
    end
    ScrollCasas.CanvasSize = UDim2.new(0, 0, 0, #state.casasData * 19 + 5)
    CasasContador.Text = "Casas marcadas: " .. #state.casas
end

BotaoEscanear.MouseButton1Click:Connect(escanearCasas)

BotaoAtivar.MouseButton1Click:Connect(function()
    local nick = NickBox.Text:gsub("%s+", "")
    state.webhook = WebhookBox.Text
    if nick == "" then state.status = "Digite o nick do comprador" return end
    if #nick < 3 or #nick > 20 or not nick:match("^[%w_]+$") then state.status = "Nick invalido (3 a 20 letras/digitos)" return end
    if #state.casas == 0 then state.status = "Marque pelo menos uma casa" return end
    state.nick = nick
    state.ativo = true
    state.pausado = false
    state.concluido = false
    state.status = "Aguardando trade de " .. nick
    salvarConfig()
    enviarWebhook("INFO", "Bot ativado", {{name = "Nick", value = nick}, {name = "Casas", value = tostring(#state.casas)}})
end)

BotaoPausar.MouseButton1Click:Connect(function()
    state.pausado = not state.pausado
    BotaoPausar.Text = state.pausado and "Retomar" or "Pausar"
    state.status = state.pausado and "Pausado" or "Retomado"
end)

BotaoReset.MouseButton1Click:Connect(function()
    state.nick = ""
    state.casas = {}
    state.ativo = false
    state.pausado = false
    state.concluido = false
    state.status = "Resetado"
    NickBox.Text = ""
    BotaoPausar.Text = "Pausar"
    atualizarListaCasas()
end)

BotaoDiagnostico.MouseButton1Click:Connect(diagnostico)

carregarConfig()
WebhookBox.Text = state.webhook
NickBox.Text = state.nick

task.spawn(function()
    while rodando do
        task.wait(0.4)
        if state.ativo and not state.pausado and not state.concluido then
            local janela = encontrarJanelaTrade()
            if janela then
                local parceiro = encontrarParceiro(janela)
                if not parceiro then
                    recusarTrade(janela, "Parceiro nao identificado")
                elseif string.lower(parceiro) ~= string.lower(state.nick) then
                    recusarTrade(janela, "Nick diferente: " .. parceiro)
                else
                    state.status = "Trade do nick correto - entregando"
                    executarEntrega(janela)
                end
            end
        end
        if StatusLabel then StatusLabel.Text = "Status: " .. state.status end
        if StatsLabel then StatsLabel.Text = "Entregas: " .. state.stats.entregas .. " | Recusadas: " .. state.stats.recusadas .. " | Erros: " .. state.stats.erros end
    end
end)

if typeof(getgenv) == "function" then
    getgenv().__SAMHUB = {limpar = limparInstancia}
end

enviarWebhook("INFO", "SAMHUB iniciado", {{name = "Executor", value = typeof(syn) == "table" and "syn" or typeof(request) == "function" and "request" or "HttpService"}})
