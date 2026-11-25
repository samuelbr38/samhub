return function(App)
    local Config, Utils = App.Config, App.Utils
    local S = Config.SAMHUB
    local HttpService = game:GetService("HttpService")
    local Players = game:GetService("Players")

    local Site = {}
    Site.Mudou = Utils.Sinal()
    Site.PedirLogin = Utils.Sinal()
    Site.estado = { logado = false, conta = nil, texto = "não entrou", ultimaBusca = nil, naFila = 0, erro = nil }

    local ARQUIVO = "samhub_site.json"
    local sessao = nil
    local geracao = 0
    local function pararLoop() geracao += 1 end
    local vistos = {}

    local function avisar(texto, logado)
        Site.estado.texto = texto
        if logado ~= nil then Site.estado.logado = logado end
        Site.estado.conta = sessao and sessao.conta or nil
        Site.Mudou:Fire()
    end

    function Site.configurado()
        return type(S.SITE_URL) == "string" and string.find(S.SITE_URL, "^https://") ~= nil
            and type(S.SITE_CHAVE_PUBLICA) == "string" and S.SITE_CHAVE_PUBLICA ~= ""
    end

    local function meuNick()
        local eu = Players.LocalPlayer
        return eu and eu.Name or nil
    end

    local function funcaoRequest()
        local ok, fn = pcall(function()
            local env = (typeof(getgenv) == "function" and getgenv()) or {}
            local global = getfenv(0)
            local syn = env.syn or global.syn
            local fluxus = env.fluxus or global.fluxus
            return env.request or global.request or env.http_request or global.http_request
                or (syn and syn.request) or (fluxus and fluxus.request)
        end)
        return ok and type(fn) == "function" and fn or nil
    end

    local function rpc(nome, corpo)
        if not Site.configurado() then return false, "o endereço do site não está no config.lua" end
        local req = funcaoRequest()
        if not req then return false, "este executor não faz pedidos para a internet (request)" end
        local chave = S.SITE_CHAVE_PUBLICA
        local cabecalhos = { ["Content-Type"] = "application/json", apikey = chave }
        if string.sub(chave, 1, 3) == "eyJ" then cabecalhos.Authorization = "Bearer " .. chave end
        local url = string.gsub(S.SITE_URL, "/+$", "")
        local ok, resposta = pcall(req, {
            Url = url .. "/rest/v1/rpc/" .. nome,
            Method = "POST",
            Headers = cabecalhos,
            Body = HttpService:JSONEncode(corpo),
        })
        if not ok or type(resposta) ~= "table" then return false, "sem resposta do site" end
        local codigo = tonumber(resposta.StatusCode) or 0
        local okJson, dados = pcall(HttpService.JSONDecode, HttpService, resposta.Body or "")
        if codigo >= 200 and codigo < 300 then return true, okJson and dados or nil end
        local msg = okJson and type(dados) == "table" and (dados.message or dados.hint) or ("erro " .. codigo)
        return false, tostring(msg)
    end

    local function sessaoCaiu(msg)
        return string.find(tostring(msg), "Sessão do SAMHUB inválida", 1, true) ~= nil
    end

    local function chamar(nome, corpo)
        if not sessao then return false, "não entrou" end
        corpo.p_token = sessao.token
        local ok, r = rpc(nome, corpo)
        if not ok and sessaoCaiu(r) then
            pararLoop()
            sessao = nil
            Utils.salvarJSON(ARQUIVO, {})
            Site.estado.erro = r
            avisar("a sessão caiu: entre de novo", false)
            Utils.notificar("🌐 A conta saiu do site (senha trocada, desligada ou entrou em outro celular). Entre de novo.", "erro")
            Site.PedirLogin:Fire()
        end
        return ok, r
    end

    function Site.log(titulo, texto, tipo)
        if not sessao then return end
        task.spawn(function()
            local ok, erro = chamar("samhub_log", { p_titulo = titulo, p_texto = texto or "", p_tipo = tipo or "info" })
            if not ok then Utils.log("site: log não foi (" .. tostring(erro) .. ")", "debug") end
        end)
    end

    local MAPA = { entregando = "entregando", entregue = "entregue", erro = "erro", pulado = "pulado" }

    function Site.reportar(p, estado, detalhe)
        if not p or not p.siteId or not MAPA[estado] or not sessao then return end
        task.spawn(function()
            for tentativa = 1, 3 do
                local ok, r = chamar("samhub_atualizar", {
                    p_id = p.siteId, p_status = MAPA[estado], p_detalhe = detalhe and tostring(detalhe) or nil,
                })
                if ok then
                    if type(r) == "table" and r.pedido_entregue then
                        Utils.notificar("🌐 Pedido #" .. tostring(p.pedidoSite) .. " marcado como entregue no site", "ok")
                    end
                    return
                end
                if not sessao then return end
                Utils.aviso("site: não consegui avisar '" .. estado .. "' (" .. tostring(r) .. ")")
                task.wait(2 * tentativa)
            end
        end)
    end

    local function buscar()
        local ok, r = chamar("samhub_pedidos", {})
        if not ok then
            if sessao then
                Site.estado.erro = r
                avisar("erro: " .. tostring(r), true)
            end
            return
        end
        Site.estado.erro = nil
        Site.estado.ultimaBusca = os.date("%H:%M:%S")
        local lista = type(r) == "table" and type(r.pedidos) == "table" and r.pedidos or {}
        Site.estado.naFila = #lista
        if #lista < 50 then
            local ativos = {}
            for _, item in ipairs(lista) do
                if type(item) == "table" and item.id then ativos[item.id] = true end
            end
            for _, id in ipairs(App.Fila.sincronizarSite(ativos)) do vistos[id] = nil end
        end

        local novos = 0
        for _, item in ipairs(lista) do
            if type(item) == "table" and item.id and not vistos[item.id] then
                vistos[item.id] = true
                if App.Fila.adicionarSite(item) then novos += 1 end
            end
        end
        avisar(string.format("%d casinha(s) para esta conta", #lista), true)
        if novos > 0 then
            Utils.notificar(string.format("🌐 %d casinha(s) nova(s) do site na fila", novos), "info")
            if S.SITE_AUTO_FILA and not App.Fila.rodando() and App.Trade.estado() == "inativo" then
                App.Fila.iniciar()
            end
        end
    end

    local function loop()
        geracao += 1
        local minha = geracao
        task.spawn(function()
            while minha == geracao and sessao do
                if S.SITE_LIGADO then
                    pcall(buscar)
                else
                    pcall(chamar, "samhub_ping", { p_roblox = meuNick() })
                end
                for _ = 1, 30 do
                    if minha ~= geracao then return end
                    task.wait(1)
                end
            end
        end)
    end

    function Site.entrar(usuario, senha)
        usuario = string.lower(Utils.limpar(usuario or ""))
        senha = tostring(senha or "")
        if not string.match(usuario, "^[%w_]+$") then return false, "Digite o usuário" end
        if senha == "" then return false, "Digite a senha" end
        avisar("entrando...", false)
        local ok, r = rpc("samhub_entrar", { p_usuario = usuario, p_senha = senha, p_roblox = meuNick() })
        senha = nil
        if not ok then
            avisar("não entrou: " .. tostring(r), false)
            return false, tostring(r)
        end
        if type(r) ~= "table" or not r.ok or type(r.token) ~= "string" then
            local msg = type(r) == "table" and r.erro or "resposta estranha do site"
            avisar(tostring(msg), false)
            return false, tostring(msg)
        end
        pararLoop()
        vistos = {}
        sessao = { conta = tostring(r.conta or usuario), token = r.token }
        Utils.salvarJSON(ARQUIVO, sessao)
        avisar("conectado como " .. sessao.conta, true)
        Utils.notificar("🌐 Conectado ao site como " .. sessao.conta, "ok")
        loop()
        return true, sessao.conta
    end

    function Site.sair()
        local antiga = sessao
        pararLoop()
        sessao = nil
        Utils.salvarJSON(ARQUIVO, {})
        avisar("saiu", false)
        if antiga then
            task.spawn(rpc, "samhub_sair", { p_token = antiga.token })
        end
        Site.PedirLogin:Fire()
    end

    Site.estado.casasEnviadas = nil
    function Site.enviarCasas(casas)
        if not sessao then
            Utils.notificar("🌐 Entre no site (aba 🌐) para mandar as casinhas.", "aviso")
            return false
        end
        local lista = {}
        for _, c in ipairs(casas or {}) do
            if type(c) == "table" and type(c.nome) == "string" and c.nome ~= "" then
                table.insert(lista, {
                    nome = string.sub(c.nome, 1, 40),
                    tipo = type(c.tipoCasa) == "string" and string.sub(c.tipoCasa, 1, 40) or nil,
                    venda = c.aVenda == true,
                })
            end
            if #lista >= 300 then break end
        end
        if #lista == 0 then
            Utils.notificar("🌐 Nenhuma casinha para mandar: abra o MY HOMES e toque em ESCANEAR.", "aviso")
            return false
        end
        task.spawn(function()
            local ok, r = chamar("samhub_casas_enviar", { p_casas = lista })
            if ok then
                local n = type(r) == "table" and tonumber(r.casas) or #lista
                Site.estado.casasEnviadas = { n = n, hora = os.date("%H:%M") }
                Utils.notificar(string.format("🌐 %d casinha(s) enviada(s) para o site", n), "ok")
                Site.Mudou:Fire()
            elseif sessao then
                Utils.notificar("🌐 Não consegui mandar as casinhas: " .. tostring(r), "erro")
            end
        end)
        return true
    end

    function Site.buscarAgora()
        if sessao then task.spawn(pcall, buscar) end
    end

    function Site.iniciar()
        if not Site.configurado() then
            avisar("site não configurado", false)
            return
        end
        local salvo = Utils.lerJSON(ARQUIVO)
        if type(salvo) == "table" and type(salvo.token) == "string" and type(salvo.conta) == "string" then
            sessao = { conta = salvo.conta, token = salvo.token }
            avisar("conectando como " .. salvo.conta .. "...", false)
            task.spawn(function()
                local ok, r = chamar("samhub_ping", { p_roblox = meuNick() })
                if ok then
                    avisar("conectado como " .. sessao.conta, true)
                    Site.log("🟢 SAMHUB aberto", "Roblox: @" .. tostring(meuNick()), "ok")
                    loop()
                elseif sessao then
                    avisar("site sem resposta (" .. tostring(r) .. "): tentando de novo...", false)
                    loop()
                end
            end)
        else
            avisar("não entrou", false)
            task.defer(function() Site.PedirLogin:Fire() end)
        end
    end

    function Site.parar()
        if sessao and Site.estado.logado then
            Site.log("⚪ SAMHUB fechado", "O script foi fechado.", "aviso")
        end
        pararLoop()
    end

    return Site
end
