local REPO = "https://raw.githubusercontent.com/samuelbr38/samhub/refs/heads/main/"

local MODO_DEV = false

local env = (typeof(getgenv) == "function" and getgenv()) or _G
if env.SAMHUB and env.SAMHUB.fechar then
    pcall(env.SAMHUB.fechar)
end

local function baixar(caminho)
    if MODO_DEV then
        return readfile("samhub/" .. caminho)
    end
    return game:HttpGet(REPO .. caminho)
end

local function carregar(nome)
    local ok, codigo = pcall(baixar, "src/" .. nome .. ".lua")
    assert(ok and codigo and codigo ~= "", "[SAMHUB] Falha ao baixar " .. nome .. ": " .. tostring(codigo))
    local fn, err = loadstring(codigo, "=" .. nome)
    assert(fn, "[SAMHUB] Erro de sintaxe em " .. nome .. ": " .. tostring(err))
    return fn()
end

local App = {}
App.Config    = carregar("config")
App.Tema      = carregar("tema")
App.Utils     = carregar("utils")(App)
App.Historico = carregar("historico")(App)
App.Scanner   = carregar("scanner")(App)
App.Mapeador  = carregar("mapeador")(App)
App.Trade     = carregar("trade")(App)
App.C         = carregar("componentes")(App)
App.UI        = carregar("ui")(App)

local S = App.Config.SAMHUB
local maid = App.Utils.Maid()

function App.salvarAjustes()
    local dados = {}
    for _, chave in ipairs(App.Config.AJUSTES_SALVOS) do
        dados[chave] = S[chave]
    end
    App.Utils.salvarJSON(S.ARQUIVO_AJUSTES, dados)
end

local function carregarAjustes()
    local dados = App.Utils.lerJSON(S.ARQUIVO_AJUSTES)
    if type(dados) ~= "table" then return end
    for _, chave in ipairs(App.Config.AJUSTES_SALVOS) do
        if dados[chave] ~= nil and type(dados[chave]) == type(S[chave]) then
            S[chave] = dados[chave]
        end
    end
end

function App.fechar()
    App.Trade.parar()
    maid:Clean()
    if env.SAMHUB == App then env.SAMHUB = nil end
end

carregarAjustes()
App.UI.criar(maid)
App.Historico.carregar()
App.Trade.iniciar()
env.SAMHUB = App

App.Utils.setStatus("Pronto! Abra a lista de casas e clique em Escanear.", "info")
print("✅ SAMHUB v" .. App.Config.VERSAO .. " iniciado (RightShift esconde o menu)")
