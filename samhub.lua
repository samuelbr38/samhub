local REPO = "https://raw.githubusercontent.com/samuelbr38/samhub/refs/heads/main/"

local MODO_DEV = false

local MODULOS = { "config", "tema", "utils", "historico", "scanner", "mapeador", "casa", "trade", "componentes", "ui" }

local env = (typeof(getgenv) == "function" and getgenv()) or _G
if env.SAMHUB and env.SAMHUB.fechar then
    pcall(env.SAMHUB.fechar)
end

if not game:IsLoaded() then game.Loaded:Wait() end

local function baixar(caminho)
    if MODO_DEV then
        return readfile("samhub/" .. caminho)
    end
    return game:HttpGet(REPO .. caminho .. "?v=" .. tostring(os.time()))
end

local codigos, faltam = {}, #MODULOS
local inicio = os.clock()

for _, nome in ipairs(MODULOS) do
    task.spawn(function()
        local ultimoErro
        for tentativa = 1, 3 do
            local ok, resultado = pcall(baixar, "src/" .. nome .. ".lua")
            if ok and type(resultado) == "string" and resultado ~= "" and not string.find(resultado, "^404") then
                codigos[nome] = resultado
                break
            end
            ultimoErro = resultado
            task.wait(0.4 * tentativa)
        end
        if not codigos[nome] then
            codigos[nome] = false
            warn("[SAMHUB] não baixou src/" .. nome .. ".lua: " .. tostring(ultimoErro))
        end
        faltam -= 1
    end)
end

while faltam > 0 and os.clock() - inicio < 30 do
    task.wait()
end

local function modulo(nome)
    local codigo = codigos[nome]
    assert(codigo, "[SAMHUB] Faltou o arquivo src/" .. nome .. ".lua no GitHub")
    local fn, err = loadstring(codigo, "=" .. nome)
    assert(fn, "[SAMHUB] Erro em " .. nome .. ".lua: " .. tostring(err))
    return fn()
end

local App = {}
App.Config    = modulo("config")
App.Tema      = modulo("tema")
App.Utils     = modulo("utils")(App)
App.Historico = modulo("historico")(App)
App.Scanner   = modulo("scanner")(App)
App.Mapeador  = modulo("mapeador")(App)
App.Casa      = modulo("casa")(App)
App.Trade     = modulo("trade")(App)
App.C         = modulo("componentes")(App)
App.UI        = modulo("ui")(App)

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
        if dados[chave] ~= nil and (S[chave] == nil or type(dados[chave]) == type(S[chave])) then
            S[chave] = dados[chave]
        end
    end
end

function App.fechar()
    App.Trade.parar()
    App.Casa.pararVigia()
    maid:Clean()
    if env.SAMHUB == App then env.SAMHUB = nil end
end

carregarAjustes()
App.UI.criar(maid)
App.Historico.carregar()
App.Trade.iniciar()
App.Casa.iniciarVigia()
env.SAMHUB = App

local tempo = string.format("%.1fs", os.clock() - inicio)
if game.PlaceId ~= App.Config.PLACE_ADOPT_ME then
    App.Utils.setStatus("Carregado em " .. tempo .. ", mas este jogo não é o Adopt Me", "aviso")
else
    App.Utils.setStatus("Carregado em " .. tempo .. "! Abra MY HOMES e clique em Escanear.", "info")
end
print("💗 SAMHUB v" .. App.Config.VERSAO .. " carregado em " .. tempo .. " (RightShift esconde o menu)")
