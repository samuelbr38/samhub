return function(App)
    local Config, Tema, Utils, C = App.Config, App.Tema, App.Utils, App.C
    local Scanner, Trade, Mapeador, Historico, Casa = App.Scanner, App.Trade, App.Mapeador, App.Historico, App.Casa
    local Fila, Site = App.Fila, App.Site
    local S, E = Config.SAMHUB, Config.Estado

    local Players = game:GetService("Players")
    local UIS = game:GetService("UserInputService")
    local CoreGui = game:GetService("CoreGui")

    local UI = {}

    local W, H = Tema.largura, Tema.altura
    local LAT, TOPO = Tema.larguraLateral, Tema.alturaTopo

    local function se(condicao, a, b)
        if condicao then return a end
        return b
    end

    local function colocarNaTela(gui)
        if Utils.recursos.gethui then
            local ok, pasta = pcall(gethui)
            if ok and typeof(pasta) == "Instance" then
                gui.Parent = pasta
                return
            end
        end
        if not pcall(function() gui.Parent = CoreGui end) then
            gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
        end
    end

    local function ehToque(input)
        local tipo = input.UserInputType
        return tipo == Enum.UserInputType.MouseButton1 or tipo == Enum.UserInputType.Touch
    end

    local function ehMovimento(input)
        local tipo = input.UserInputType
        return tipo == Enum.UserInputType.MouseMovement or tipo == Enum.UserInputType.Touch
    end

    local function arrastavel(alvo, alca, maid, aoTocar)
        local apertado, moveu, inicioPos, inicioToque = false, false, nil, nil
        alca.InputBegan:Connect(function(input)
            if not ehToque(input) then return end
            apertado, moveu, inicioPos, inicioToque = true, false, alvo.Position, input.Position
            local conexao
            conexao = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    conexao:Disconnect()
                    if apertado and not moveu and aoTocar then aoTocar() end
                    apertado = false
                end
            end)
        end)
        maid:Add(UIS.InputChanged:Connect(function(input)
            if not apertado or not ehMovimento(input) then return end
            local delta = input.Position - inicioToque
            if math.abs(delta.X) + math.abs(delta.Y) > 5 then moveu = true end
            if moveu then
                alvo.Position = UDim2.new(inicioPos.X.Scale, inicioPos.X.Offset + delta.X, inicioPos.Y.Scale, inicioPos.Y.Offset + delta.Y)
            end
        end))
    end

    local function casaMarcada()
        for nome in pairs(E.casasSelecionadas) do return nome end
        return nil
    end

    local function colunas(pg, proporcao)
        local esquerda = C.card({ Parent = pg, Size = UDim2.new(proporcao, -4, 1, 0) })
        local direita = C.card({
            Parent = pg, Position = UDim2.new(proporcao, 4, 0, 0), Size = UDim2.new(1 - proporcao, -4, 1, 0),
        })
        return esquerda, direita
    end

    local function semLista(card)
        local lista = card:FindFirstChildWhichIsA("UIListLayout")
        if lista then lista:Destroy() end
    end

    local function scroll(pai, props)
        local base = {
            Parent = pai, BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2,
            ScrollBarImageColor3 = Tema.rosa, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
        }
        for k, v in pairs(props) do base[k] = v end
        return C.criar("ScrollingFrame", base)
    end

    function UI.criar(maid)
        local gui = C.criar("ScreenGui", {
            Name = "SAMHUB_Menu", ResetOnSpawn = false, IgnoreGuiInset = true,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 50,
        })
        colocarNaTela(gui)
        maid:Add(gui)

        local moldura = C.criar("Frame", {
            Parent = gui, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, W, 0, H),
        })
        C.sombra(moldura, UDim2.new(1, 0, 1, 0), UDim2.new(0.5, 0, 0.5, 4), nil, 10)
        local function janelaAberta()
            return moldura.Visible or moldura:GetAttribute("SamhubEscondido") == true
        end
        local janela = C.criar("Frame", {
            Parent = moldura, BackgroundColor3 = Color3.new(1, 1, 1), ClipsDescendants = true,
            Size = UDim2.new(1, 0, 1, 0), ZIndex = 1,
        }, { C.canto(10), C.bordaNeon(0.45), C.degrade(Tema.fundo, Tema.fundoBaixo, 120) })

        local escala = C.criar("UIScale", { Parent = moldura })
        local escalaBase = 1
        local function ajustarEscala()
            local camera = workspace.CurrentCamera
            if not camera then return end
            local tela = camera.ViewportSize
            escalaBase = math.clamp(math.min((tela.X - 20) / W, (tela.Y - 20) / H), 0.5, 1)
            escala.Scale = escalaBase
        end
        ajustarEscala()
        if workspace.CurrentCamera then
            maid:Add(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(ajustarEscala))
        end
        local function pop()
            escala.Scale = escalaBase * 0.94
            C.tween(escala, { Scale = escalaBase }, 0.2)
        end

        local lateral = C.criar("Frame", {
            Parent = janela, BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Size = UDim2.new(0, LAT, 1, 0),
        }, { C.degrade(Tema.lateral, Tema.fundo, 90) })
        C.criar("Frame", {
            Parent = lateral, BackgroundColor3 = Tema.borda, BorderSizePixel = 0,
            Position = UDim2.new(1, -1, 0, 0), Size = UDim2.new(0, 1, 1, 0),
        })
        local fundoLogo = C.criar("Frame", {
            Parent = lateral, BackgroundColor3 = Color3.new(1, 1, 1), AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 8), Size = UDim2.new(0, 28, 0, 28),
        }, { C.canto(6), C.gradiente(45) })
        local logo = C.criar("TextButton", {
            Parent = fundoLogo, Text = "S", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
            Font = Tema.fonteForte, TextSize = 15, TextColor3 = Color3.new(1, 1, 1),
        })

        local nav = C.criar("Frame", {
            Parent = lateral, BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 48), Size = UDim2.new(1, 0, 1, -76),
        }, {
            C.criar("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2),
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
            }),
        })

        local pontoEstado = C.criar("Frame", {
            Parent = lateral, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -12),
            Size = UDim2.new(0, 8, 0, 8), BackgroundColor3 = Tema.apagado,
        }, { C.canto(4) })

        local area = C.criar("Frame", {
            Parent = janela, BackgroundTransparency = 1, Position = UDim2.new(0, LAT, 0, 0), Size = UDim2.new(1, -LAT, 1, 0),
        })
        local topo = C.criar("Frame", { Parent = area, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, TOPO) })
        C.criar("Frame", {
            Parent = topo, BackgroundColor3 = Tema.borda, BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1),
        })
        C.criar("Frame", {
            Parent = topo, BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1),
        }, {
            C.criar("UIGradient", {
                Color = ColorSequence.new(Tema.rosa, Tema.lilas),
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.6, 0.6), NumberSequenceKeypoint.new(1, 1),
                }),
            }),
        })
        local tituloPagina = C.texto({
            Parent = topo, Position = UDim2.new(0, 12, 0, 6), Size = UDim2.new(1, -160, 0, 14),
            Font = Tema.fonteMono, TextSize = 12, TextColor3 = Tema.texto,
        })
        C.texto({
            Parent = topo, Position = UDim2.new(0, 12, 0, 21), Size = UDim2.new(1, -160, 0, 12),
            Font = Tema.fonteMono, TextSize = 9, TextColor3 = Tema.apagado,
            Text = "samhub v" .. Config.VERSAO .. " // adopt me",
        })
        local chip = C.criar("Frame", {
            Parent = topo, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -62, 0.5, 0),
            Size = UDim2.new(0, 64, 0, 18), BackgroundColor3 = Tema.painel2,
        }, { C.canto(9) })
        local bordaChip = C.borda(Tema.apagado)
        bordaChip.Parent = chip
        local textoChip = C.texto({
            Parent = chip, Size = UDim2.new(1, 0, 1, 0), Font = Tema.fonteMono, TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Center, Text = "OFF",
        })
        local botaoMin = C.icone({
            Parent = topo, Texto = "-", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -34, 0.5, 0),
        })
        C.icone({
            Parent = topo, Texto = "X", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0),
            CorHover = Tema.vermelho, OnClick = function() App.fechar() end,
        })

        local conteudo = C.criar("Frame", {
            Parent = area, BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, TOPO), Size = UDim2.new(1, 0, 1, -TOPO),
        })

        arrastavel(moldura, topo, maid)

        local ABAS = {
            { icone = "🚚", nome = "ENTREGA" },
            { icone = "📦", nome = "FILA" },
            { icone = "📜", nome = "HISTÓRICO" },
            { icone = "⚙️", nome = "AJUSTES" },
            { icone = "🧪", nome = "DIAGNÓSTICO" },
            { icone = "📟", nome = "REGISTRO" },
            { icone = "🌐", nome = "SITE" },
        }
        local itensNav, paginas, aoAbrirAba = {}, {}, {}
        local abaAtual = 1

        local function irPara(i)
            abaAtual = i
            for j, pg in ipairs(paginas) do pg.Visible = (j == i) end
            for j, item in ipairs(itensNav) do
                local ativo = j == i
                C.tween(item.botao, { BackgroundTransparency = se(ativo, 0.8, 1), TextTransparency = se(ativo, 0, 0.45) })
                item.barra.Visible = ativo
            end
            local pagina = paginas[i]
            if pagina then
                for _, d in ipairs(pagina:GetDescendants()) do
                    if d:IsA("TextLabel") or d:IsA("TextButton") then
                        local alvo = d:GetAttribute("TT0")
                        if alvo == nil then
                            alvo = d.TextTransparency
                            d:SetAttribute("TT0", alvo)
                        end
                        if alvo < 1 then
                            d.TextTransparency = math.min(1, alvo + 0.6)
                            C.tween(d, { TextTransparency = alvo }, 0.18)
                        end
                    end
                end
            end
            tituloPagina.Text = "> " .. ABAS[i].nome
            if aoAbrirAba[i] then task.spawn(aoAbrirAba[i]) end
        end

        for i, aba in ipairs(ABAS) do
            local botao = C.criar("TextButton", {
                Parent = nav, LayoutOrder = i, Text = aba.icone, AutoButtonColor = false,
                BackgroundColor3 = Tema.rosa, BackgroundTransparency = 1, Size = UDim2.new(0, 32, 0, 32),
                Font = Tema.fonte, TextSize = 15, TextTransparency = 0.45,
            }, { C.canto(8) })
            local barra = C.criar("Frame", {
                Parent = botao, BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, -8, 0.5, 0), Size = UDim2.new(0, 3, 0, 18), Visible = false,
            }, { C.canto(2), C.gradiente(90) })
            botao.MouseButton1Click:Connect(function() irPara(i) end)
            itensNav[i] = { botao = botao, barra = barra }
            paginas[i] = C.criar("Frame", {
                Parent = conteudo, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Visible = false,
            }, { C.padding(8, 8, 8, 8) })
        end
        local pgEntrega, pgFila, pgHistorico, pgAjustes, pgDiag, pgRegistro, pgSite = table.unpack(paginas)

        local cardComprador, cardCasas = colunas(pgEntrega, 0.46)

        C.cabecalho(cardComprador, 1, nil, "Comprador")
        local caixaStatus = C.criar("Frame", {
            Parent = cardComprador, LayoutOrder = 2, BackgroundColor3 = Tema.painel2,
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        }, { C.canto(5), C.padding(6, 8, 6, 10) })
        local barraStatus = C.criar("Frame", {
            Parent = caixaStatus, BackgroundColor3 = Tema.rosa, BorderSizePixel = 0,
            Position = UDim2.new(0, -10, 0, -6), Size = UDim2.new(0, 2, 1, 12),
        })
        local textoStatus = C.texto({
            Parent = caixaStatus, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            TextWrapped = true, Font = Tema.fonteMono, TextSize = 10, Text = "",
        })

        local caixaNick = C.input({
            Parent = cardComprador, LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 26),
            Placeholder = "username do comprador", Prefixo = "@",
        })

        local buscando = false
        local linhaAtivar = C.linha(cardComprador, 4, 28)
        local botaoAtivar = C.botao({
            Parent = linhaAtivar, Texto = "ATIVAR", Variante = "primario",
            Size = UDim2.new(0.62, -3, 1, 0), TextSize = 12,
        })
        local renderCasas
        C.botao({
            Parent = linhaAtivar, Texto = "+ FILA", Position = UDim2.new(0.62, 3, 0, 0),
            Size = UDim2.new(0.38, -3, 1, 0), TextSize = 11,
            OnClick = function()
                local ok, msg = Fila.adicionar(caixaNick.Text, casaMarcada())
                if ok then
                    Utils.setStatus("Na fila: " .. #Fila.listar() .. " entrega(s). Marque a próxima casa ou abra a aba 📦", "info")
                    E.casasSelecionadas = {}
                    renderCasas()
                else
                    Utils.setStatus(msg, "aviso")
                end
            end,
        })

        local linhaControle = C.linha(cardComprador, 5, 24)
        local botaoPausa = C.botao({
            Parent = linhaControle, Texto = "PAUSAR", Size = UDim2.new(0.5, -3, 1, 0), TextSize = 10,
            OnClick = function() Trade.alternarPausa() end,
        })
        C.botao({
            Parent = linhaControle, Texto = "RESETAR", Position = UDim2.new(0.5, 3, 0, 0),
            Size = UDim2.new(0.5, -3, 1, 0), TextSize = 10,
            OnClick = function()
                Trade.resetar()
                caixaNick.Text = ""
            end,
        })
        local linhaCasa = C.linha(cardComprador, 6, 24)
        C.botao({
            Parent = linhaCasa, Texto = "📮 À VENDA", Size = UDim2.new(0.5, -3, 1, 0), TextSize = 10,
            OnClick = function() task.spawn(Casa.listarParaTroca) end,
        })
        C.botao({
            Parent = linhaCasa, Texto = "🔎 CONFERIR", Position = UDim2.new(0.5, 3, 0, 0),
            Size = UDim2.new(0.5, -3, 1, 0), TextSize = 10,
            OnClick = function() task.spawn(Casa.conferirVenda) end,
        })

        semLista(cardCasas)
        C.cabecalho(cardCasas, 0, nil, "Casas")
        local contador = C.texto({
            Parent = cardCasas, Size = UDim2.new(1, 0, 0, 14), TextXAlignment = Enum.TextXAlignment.Right,
            Font = Tema.fonteMono, TextSize = 9, TextColor3 = Tema.suave, Text = "",
        })
        local caixaBusca = C.input({
            Parent = cardCasas, Position = UDim2.new(0, 0, 0, 20), Size = UDim2.new(1, -80, 0, 24),
            Placeholder = "filtrar...", Prefixo = "/",
        })
        C.botao({
            Parent = cardCasas, Texto = "ESCANEAR", Variante = "primario",
            Position = UDim2.new(1, -74, 0, 20), Size = UDim2.new(0, 74, 0, 24), TextSize = 10,
            OnClick = function() task.spawn(Scanner.escanear) end,
        })
        local fundoLista = C.criar("Frame", {
            Parent = cardCasas, BackgroundColor3 = Tema.painel2, Position = UDim2.new(0, 0, 0, 50),
            Size = UDim2.new(1, 0, 1, -50),
        }, { C.canto(5) })
        local listaCasas = scroll(fundoLista, { Size = UDim2.new(1, 0, 1, 0) })
        C.padding(4).Parent = listaCasas
        C.lista(2).Parent = listaCasas
        local avisoVazio = C.texto({
            Parent = fundoLista, Size = UDim2.new(1, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Center,
            Font = Tema.fonteMono, TextColor3 = Tema.apagado, TextSize = 10, TextWrapped = true,
            Text = "abra MY HOMES no jogo\ne toque em ESCANEAR",
        })

        local function atualizarContador()
            local marcada = casaMarcada()
            contador.Text = se(marcada ~= nil, "vender: " .. tostring(marcada), #E.todasAsCasas .. " casa(s) // marque 1")
        end

        local function criarLinhaCasa(casa, ordem)
            local marcada = E.casasSelecionadas[casa.nome] == true
            local linha = C.criar("TextButton", {
                Parent = listaCasas, LayoutOrder = ordem, Text = "", AutoButtonColor = false,
                BackgroundColor3 = Tema.rosa, BackgroundTransparency = se(marcada, 0.85, 1), Size = UDim2.new(1, 0, 0, 24),
            }, { C.canto(4) })
            local caixa = C.criar("Frame", {
                Parent = linha, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 6, 0.5, 0),
                Size = UDim2.new(0, 12, 0, 12), BackgroundColor3 = se(marcada, Tema.rosa, Tema.painel),
            }, { C.canto(3), C.borda(se(marcada, Tema.rosa, Tema.apagado)) })
            if marcada then
                C.criar("Frame", {
                    Parent = caixa, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
                    Size = UDim2.new(0, 4, 0, 4), BackgroundColor3 = Color3.new(1, 1, 1),
                }, { C.canto(2) })
            end
            local naFila = false
            for _, p in ipairs(Fila.listar()) do
                if p.casa == casa.nome then naFila = true end
            end
            local textoLinha = (casa.icone or "🏠") .. " " .. Utils.escaparRich(casa.nome)
            if naFila then
                textoLinha ..= ' <font face="RobotoMono" size="9" color="#ff3898">[fila]</font>'
            end
            if casa.detalhe and casa.detalhe ~= "" then
                textoLinha ..= '  <font face="RobotoMono" size="9" color="#7c6e8c">' .. Utils.escaparRich(casa.detalhe) .. "</font>"
            end
            C.texto({
                Parent = linha, Position = UDim2.new(0, 24, 0, 0), Size = UDim2.new(1, -28, 1, 0),
                Text = textoLinha, RichText = true, TextSize = 11, TextTruncate = Enum.TextTruncate.AtEnd,
                TextColor3 = se(marcada, Tema.texto, Tema.suave),
            })
            linha.MouseButton1Click:Connect(function()
                if Trade.estado() ~= "inativo" then
                    return Utils.setStatus("Desative antes de mudar a casa", "aviso")
                end
                E.casasSelecionadas = se(marcada, {}, { [casa.nome] = true })
                renderCasas()
            end)
        end

        renderCasas = function()
            for _, filho in ipairs(listaCasas:GetChildren()) do
                if filho:IsA("TextButton") then filho:Destroy() end
            end
            local filtro = string.lower(caixaBusca.Text)
            local mostradas = 0
            for i, casa in ipairs(E.todasAsCasas) do
                if filtro == "" or string.find(string.lower(casa.nome), filtro, 1, true) then
                    criarLinhaCasa(casa, i)
                    mostradas += 1
                end
            end
            avisoVazio.Visible = mostradas == 0
            if #E.todasAsCasas > 0 and mostradas == 0 then avisoVazio.Text = "nenhuma casa com esse nome" end
            atualizarContador()
        end
        caixaBusca:GetPropertyChangedSignal("Text"):Connect(renderCasas)

        botaoAtivar.MouseButton1Click:Connect(function()
            if buscando then return end
            if Trade.estado() ~= "inativo" then return Trade.desativar() end
            if Utils.limpar(caixaNick.Text) == "" then
                return Utils.setStatus("Digite o @username do comprador", "aviso")
            end
            if not casaMarcada() then
                return Utils.setStatus("Marque a casa que vai vender (lista ao lado)", "aviso")
            end
            buscando = true
            botaoAtivar.Text = "BUSCANDO..."
            Trade.ativar(caixaNick.Text, function(achou)
                buscando = false
                Utils.EstadoMudou:Fire()
                if achou and S.LISTAR_AO_ATIVAR then
                    task.wait(0.5)
                    Casa.listarParaTroca()
                end
            end)
        end)

        local cardPedidos, cardControle = colunas(pgFila, 0.6)
        semLista(cardPedidos)
        C.cabecalho(cardPedidos, 0, nil, "Pedidos")
        local contadorFila = C.texto({
            Parent = cardPedidos, Size = UDim2.new(1, 0, 0, 14), TextXAlignment = Enum.TextXAlignment.Right,
            Font = Tema.fonteMono, TextSize = 9, TextColor3 = Tema.suave, Text = "",
        })
        local fundoFila = C.criar("Frame", {
            Parent = cardPedidos, BackgroundColor3 = Tema.painel2, Position = UDim2.new(0, 0, 0, 20),
            Size = UDim2.new(1, 0, 1, -20),
        }, { C.canto(5) })
        local listaFila = scroll(fundoFila, { Size = UDim2.new(1, 0, 1, 0) })
        C.padding(4).Parent = listaFila
        C.lista(3).Parent = listaFila
        local vazioFila = C.texto({
            Parent = fundoFila, Size = UDim2.new(1, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Center,
            Font = Tema.fonteMono, TextSize = 10, TextColor3 = Tema.apagado, TextWrapped = true,
            Text = "fila vazia\n\nna aba 🚚: digite o @,\nmarque a casa e toque + FILA",
        })

        local CORES_PEDIDO = {
            esperando = Tema.suave, entregando = Tema.rosa, erro = Tema.vermelho,
            entregue = Tema.verde, pulado = Tema.amarelo,
        }

        C.cabecalho(cardControle, 1, nil, "Controle")
        local textoFila = C.texto({
            Parent = cardControle, LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            TextWrapped = true, Font = Tema.fonteMono, TextSize = 10, TextColor3 = Tema.suave, Text = "",
        })
        local botaoIniciar = C.botao({
            Parent = cardControle, LayoutOrder = 3, Texto = "INICIAR FILA", Variante = "primario",
            Size = UDim2.new(1, 0, 0, 28), TextSize = 11,
            OnClick = function()
                if Fila.rodando() then Fila.parar() else Fila.iniciar() end
            end,
        })
        local linhaFila = C.linha(cardControle, 4, 22)
        C.botao({
            Parent = linhaFila, Texto = "PULAR", Size = UDim2.new(0.5, -3, 1, 0), TextSize = 10,
            OnClick = function() Fila.pular() end,
        })
        C.botao({
            Parent = linhaFila, Texto = "LIMPAR", Position = UDim2.new(0.5, 3, 0, 0), Size = UDim2.new(0.5, -3, 1, 0),
            TextSize = 10, OnClick = function() Fila.limpar() end,
        })
        C.cabecalho(cardControle, 5, nil, "Concluídos")
        local listaFeitos = C.criar("Frame", {
            Parent = cardControle, LayoutOrder = 6, BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        }, { C.lista(2) })

        local function renderFila()
            for _, filho in ipairs(listaFila:GetChildren()) do
                if filho:IsA("Frame") then filho:Destroy() end
            end
            local pedidos = Fila.listar()
            for i, ped in ipairs(pedidos) do
                local cor = CORES_PEDIDO[ped.estado] or Tema.suave
                local linha = C.criar("Frame", {
                    Parent = listaFila, LayoutOrder = i, BackgroundColor3 = Tema.painel,
                    Size = UDim2.new(1, 0, 0, 30),
                }, { C.canto(4) })
                C.texto({
                    Parent = linha, Text = string.format("%02d", i), Position = UDim2.new(0, 6, 0, 0),
                    Size = UDim2.new(0, 18, 1, 0), Font = Tema.fonteMono, TextSize = 9, TextColor3 = Tema.apagado,
                })
                C.texto({
                    Parent = linha, Text = "🏠 " .. ped.casa .. (ped.tipo and ("  ·  " .. ped.tipo) or ""),
                    Position = UDim2.new(0, 26, 0, 2), Size = UDim2.new(1, -60, 0, 14), TextSize = 10,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                })
                C.texto({
                    Parent = linha, Text = "@" .. ped.nick .. "  " .. string.upper(ped.estado) .. (ped.detalhe and (" · " .. ped.detalhe) or ""),
                    Position = UDim2.new(0, 26, 0, 15), Size = UDim2.new(1, -60, 0, 12), Font = Tema.fonteMono,
                    TextSize = 9, TextColor3 = cor, TextTruncate = Enum.TextTruncate.AtEnd,
                })
                if not (Fila.rodando() and i == 1) then
                    C.botao({
                        Parent = linha, Texto = "X", Position = UDim2.new(1, -26, 0.5, -10),
                        Size = UDim2.new(0, 20, 0, 20), TextSize = 9,
                        OnClick = function() Fila.remover(i) end,
                    })
                end
            end
            vazioFila.Visible = #pedidos == 0
            contadorFila.Text = #pedidos .. " pedido(s)"

            for _, filho in ipairs(listaFeitos:GetChildren()) do
                if filho:IsA("TextLabel") then filho:Destroy() end
            end
            for i, f in ipairs(Fila.feitos()) do
                if i > 5 then break end
                C.texto({
                    Parent = listaFeitos, LayoutOrder = i, Size = UDim2.new(1, 0, 0, 12), Font = Tema.fonteMono,
                    TextSize = 9, TextColor3 = CORES_PEDIDO[f.estado] or Tema.suave, TextTruncate = Enum.TextTruncate.AtEnd,
                    Text = f.hora .. " " .. f.casa .. " > @" .. f.nick,
                })
            end

            if Fila.rodando() then
                textoFila.Text = "> rodando: entregando uma por vez"
                botaoIniciar.Text = "PARAR FILA"
                C.pintar(botaoIniciar, Tema.vermelho)
            else
                textoFila.Text = "> parada"
                botaoIniciar.Text = "INICIAR FILA"
                C.pintar(botaoIniciar, Tema.rosa)
            end
        end
        maid:Add(Fila.Mudou:Connect(function()
            renderFila()
            renderCasas()
        end))

        local cardResumo, cardLista = colunas(pgHistorico, 0.32)
        C.cabecalho(cardResumo, 1, nil, "Resumo")
        local CORES_RESULTADO = { finalizado = Tema.verde, recusado = Tema.vermelho, cancelado = Tema.amarelo }
        local numeros = {}
        for i, info in ipairs({ { "finalizado", "finalizados" }, { "recusado", "recusados" }, { "cancelado", "cancelados" } }) do
            local card = C.criar("Frame", {
                Parent = cardResumo, LayoutOrder = 1 + i, BackgroundColor3 = Tema.painel2, Size = UDim2.new(1, 0, 0, 34),
            }, { C.canto(5) })
            C.criar("Frame", {
                Parent = card, BackgroundColor3 = CORES_RESULTADO[info[1]], BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 0, 8), Size = UDim2.new(0, 2, 1, -16),
            })
            numeros[info[1]] = C.texto({
                Parent = card, Text = "0", Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(0, 40, 1, 0),
                Font = Tema.fonteMono, TextSize = 16, TextColor3 = CORES_RESULTADO[info[1]],
            })
            C.texto({
                Parent = card, Text = info[2], Position = UDim2.new(0, 50, 0, 0), Size = UDim2.new(1, -54, 1, 0),
                Font = Tema.fonteMono, TextSize = 9, TextColor3 = Tema.suave,
            })
        end
        C.botao({
            Parent = cardResumo, LayoutOrder = 10, Texto = "COPIAR", Size = UDim2.new(1, 0, 0, 22), TextSize = 10,
            OnClick = function()
                local texto = Historico.texto()
                Utils.log("histórico:\n" .. texto, "debug")
                Utils.setStatus(se(Utils.copiar(texto), "Histórico copiado", "Histórico no Registro"), "info")
            end,
        })
        C.botao({
            Parent = cardResumo, LayoutOrder = 11, Texto = "LIMPAR", Size = UDim2.new(1, 0, 0, 22), TextSize = 10,
            OnClick = function() Historico.limpar() end,
        })

        semLista(cardLista)
        C.cabecalho(cardLista, 0, nil, "Últimos trades")
        local listaHist = scroll(cardLista, { Position = UDim2.new(0, 0, 0, 20), Size = UDim2.new(1, 0, 1, -20) })
        C.lista(4).Parent = listaHist
        local vazioHist = C.texto({
            Parent = cardLista, Position = UDim2.new(0, 0, 0, 20), Size = UDim2.new(1, 0, 1, -20),
            Font = Tema.fonteMono, TextSize = 10, TextColor3 = Tema.apagado,
            TextXAlignment = Enum.TextXAlignment.Center, Text = "nenhum trade ainda",
        })

        local function renderHistorico()
            for _, filho in ipairs(listaHist:GetChildren()) do
                if filho:IsA("Frame") then filho:Destroy() end
            end
            local cont = { finalizado = 0, recusado = 0, cancelado = 0 }
            for i, r in ipairs(Historico.listar()) do
                cont[r.resultado] = (cont[r.resultado] or 0) + 1
                local cor = CORES_RESULTADO[r.resultado] or Tema.apagado
                local card = C.criar("Frame", {
                    Parent = listaHist, LayoutOrder = i, BackgroundColor3 = Tema.painel2, Size = UDim2.new(1, -4, 0, 32),
                }, { C.canto(5) })
                C.criar("Frame", {
                    Parent = card, BackgroundColor3 = cor, AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, 8, 0.5, 0), Size = UDim2.new(0, 6, 0, 6),
                }, { C.canto(3) })
                C.texto({
                    Parent = card, Text = "@" .. tostring(r.nick), Position = UDim2.new(0, 20, 0, 3),
                    Size = UDim2.new(1, -110, 0, 14), Font = Tema.fonteMedia, TextTruncate = Enum.TextTruncate.AtEnd,
                })
                C.texto({
                    Parent = card, Text = se(r.detalhe ~= "", r.detalhe, "-"), Position = UDim2.new(0, 20, 0, 17),
                    Size = UDim2.new(1, -110, 0, 12), Font = Tema.fonteMono, TextSize = 9, TextColor3 = Tema.apagado,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                })
                C.texto({
                    Parent = card, Text = string.upper(tostring(r.resultado)), AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, -8, 0, 3), Size = UDim2.new(0, 90, 0, 14), Font = Tema.fonteMono,
                    TextSize = 9, TextColor3 = cor, TextXAlignment = Enum.TextXAlignment.Right,
                })
                C.texto({
                    Parent = card, Text = tostring(r.hora), AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, -8, 0, 17), Size = UDim2.new(0, 90, 0, 12), Font = Tema.fonteMono,
                    TextSize = 9, TextColor3 = Tema.apagado, TextXAlignment = Enum.TextXAlignment.Right,
                })
            end
            for chave, rotulo in pairs(numeros) do rotulo.Text = tostring(cont[chave] or 0) end
            vazioHist.Visible = #Historico.listar() == 0
        end
        maid:Add(Historico.Mudou:Connect(renderHistorico))

        local cardTrade, cardTempo = colunas(pgAjustes, 0.55)
        semLista(cardTrade)
        C.cabecalho(cardTrade, 0, nil, "Automação")
        local listaToggles = scroll(cardTrade, { Position = UDim2.new(0, 0, 0, 20), Size = UDim2.new(1, 0, 1, -20) })
        C.padding(0, 6, 0, 0).Parent = listaToggles
        C.lista(4).Parent = listaToggles
        local function toggle(ordem, chave, texto, descricao)
            C.toggle({
                Parent = listaToggles, LayoutOrder = ordem, Texto = texto, Descricao = descricao, Valor = S[chave],
                OnChange = function(v)
                    S[chave] = v
                    App.salvarAjustes()
                end,
            })
        end
        toggle(2, "ACEITAR_PEDIDO", "Aceitar pedido", "accept no aviso do comprador")
        toggle(3, "LISTAR_AO_ATIVAR", "Pôr à venda ao ativar", "go! + caixa de correio")
        toggle(4, "ANDAR_ATE_CAIXA", "Andar até a caixa", "vai sozinho, longe da porta")
        toggle(5, "CONFERIR_VENDA", "Conferir após listar", "confere a casa marcada")
        toggle(6, "RECUSAR_OUTROS", "Recusar outras pessoas", "desligado: só ignora")
        toggle(7, "VERIFICAR_CASA", "Conferir casa no trade", "só se a casa aparecer")
        toggle(8, "MINIMIZAR_AUTO", "Minimizar ao trabalhar", "o menu sai da frente dos cliques")
        toggle(9, "POPUPS", "Popups ao vivo", "mostra o que ele está fazendo")
        toggle(10, "CONFERIR_ENTREGA", "Conferir após o trade", "a casa sumiu da lista MY HOMES?")
        toggle(11, "AUTO_CASH_OUT", "Cash Out automático", "cheque do banco: marca e saca")
        toggle(12, "ANTI_AFK", "Anti-inatividade", "o jogo não te tira depois de 20 min")

        C.cabecalho(cardTempo, 1, nil, "Tempo")
        local function stepper(ordem, chave, texto, minimo, maximo, passo)
            C.stepper({
                Parent = cardTempo, LayoutOrder = ordem, Texto = texto, Valor = S[chave],
                Min = minimo, Max = maximo, Passo = passo, Sufixo = "s",
                OnChange = function(v)
                    S[chave] = v
                    App.salvarAjustes()
                end,
            })
        end
        stepper(2, "TEMPO_ESTAVEL", "Oferta parada", 0, 5, 0.5)
        stepper(3, "DELAY_MIN", "Atraso mín.", 0.2, 5, 0.1)
        stepper(4, "DELAY_MAX", "Atraso máx.", 0.2, 8, 0.1)
        C.cabecalho(cardTempo, 5, nil, "Caixa de correio")
        C.botao({
            Parent = cardTempo, LayoutOrder = 6, Texto = "📍 ESTOU NA CAIXA", Size = UDim2.new(1, 0, 0, 22), TextSize = 10,
            OnClick = function() task.spawn(Casa.salvarPosicaoCaixa) end,
        })
        C.botao({
            Parent = cardTempo, LayoutOrder = 7, Texto = "ESQUECER CAIXA", Size = UDim2.new(1, 0, 0, 22), TextSize = 10,
            OnClick = function() Casa.esquecerCaixas() end,
        })
        C.texto({
            Parent = cardTempo, LayoutOrder = 8, Size = UDim2.new(1, 0, 0, 12), Font = Tema.fonteMono, TextSize = 9,
            TextColor3 = se(Utils.temArquivos, Tema.verde, Tema.amarelo),
            Text = se(Utils.temArquivos, "● ajustes salvos em arquivo", "● executor não salva arquivos"),
        })
        C.texto({
            Parent = cardTempo, LayoutOrder = 9, Size = UDim2.new(1, 0, 0, 12), Font = Tema.fonteMono, TextSize = 9,
            TextColor3 = Tema.apagado, Text = S.TECLA_MENU.Name .. " / logo = esconder",
        })

        local cardExec, cardJogo = colunas(pgDiag, 0.5)
        cardExec:FindFirstChildWhichIsA("UIListLayout").Padding = UDim.new(0, 4)
        cardJogo:FindFirstChildWhichIsA("UIListLayout").Padding = UDim.new(0, 4)

        C.cabecalho(cardExec, 1, nil, "Executor")
        local dExecutor = C.info(cardExec, 2, "executor")
        local dVim = C.info(cardExec, 3, "clique virtual")
        local dConexoes = C.info(cardExec, 4, "getconnections")
        local dFire = C.info(cardExec, 5, "firesignal")
        local dArquivos = C.info(cardExec, 6, "arquivos")
        local dMetodo = C.info(cardExec, 7, "último clique")
        local linhaMapa = C.linha(cardExec, 8, 22)
        C.botao({
            Parent = linhaMapa, Texto = "MAPA TRADE", Size = UDim2.new(0.5, -3, 1, 0), TextSize = 9,
            OnClick = function() Mapeador.mapearTrade() end,
        })
        C.botao({
            Parent = linhaMapa, Texto = "MAPA CASAS", Position = UDim2.new(0.5, 3, 0, 0), Size = UDim2.new(0.5, -3, 1, 0),
            TextSize = 9, OnClick = function() Mapeador.mapearCasas() end,
        })
        local linhaMapa2 = C.linha(cardExec, 9, 22)
        C.botao({
            Parent = linhaMapa2, Texto = "MAPA CAIXA", Size = UDim2.new(0.5, -3, 1, 0), TextSize = 9,
            OnClick = function() task.spawn(Casa.mapear) end,
        })
        C.botao({
            Parent = linhaMapa2, Texto = "MAPA TELA", Position = UDim2.new(0.5, 3, 0, 0), Size = UDim2.new(0.5, -3, 1, 0),
            TextSize = 9, OnClick = function() Mapeador.mapear() end,
        })

        C.cabecalho(cardJogo, 1, nil, "Jogo")
        local dJogo = C.info(cardJogo, 2, "adopt me")
        local dJanela = C.info(cardJogo, 3, "janela de trade")
        local dParceiro = C.info(cardJogo, 4, "parceiro")
        local dAceitar = C.info(cardJogo, 5, "botão accept")
        local dComprador = C.info(cardJogo, 6, "comprador")
        local dPedido = C.info(cardJogo, 7, "pedido de trade")
        local dLista = C.info(cardJogo, 8, "lista my homes")
        local dCaixa = C.info(cardJogo, 9, "caixa de correio")

        local function atualizarDiagnostico(completo)
            local r = Utils.recursos
            dExecutor(Utils.nomeExecutor(), nil)
            dVim(se(r.vim, "sim", "não"), r.vim)
            dConexoes(se(r.getconnections, "sim", "não"), r.getconnections)
            dFire(se(r.firesignal, "sim", "não"), r.firesignal)
            dArquivos(se(r.arquivos, "sim", "não"), r.arquivos)
            dMetodo(Utils.metodoClique or "nenhum", se(Utils.metodoClique ~= nil, true, nil))

            local ehAdopt = game.PlaceId == Config.PLACE_ADOPT_ME
            dJogo(se(ehAdopt, "sim", "não (" .. game.PlaceId .. ")"), ehAdopt)

            local d = Trade.diagnostico()
            if d.janelaAberta then
                dJanela("aberta", true)
                dParceiro(d.parceiro or "?", d.parceiroOk)
                dAceitar(d.botaoAceitar or "não achei", d.botaoAceitar ~= nil)
            else
                dJanela(se(d.appExiste, "fechada", "não encontrada"), se(d.appExiste, nil, false))
                dParceiro("-", nil)
                dAceitar("-", nil)
            end
            if d.comprador then
                dComprador(d.comprador .. se(d.compradorNoServidor, " (aqui)", " (fora)"), d.compradorNoServidor)
            else
                dComprador("não ativado", nil)
            end
            dPedido(se(d.pedidoNaTela, "na tela", "nenhum"), se(d.pedidoNaTela, true, nil))

            if completo then
                local painel = Scanner.acharPainel()
                dLista(se(painel ~= nil, "aberta", "fechada"), se(painel ~= nil, true, nil))
                local c = Casa.diagnostico()
                if c.menuAberto then
                    dCaixa("menu aberto", true)
                elseif c.botaoE then
                    dCaixa("botão E na tela", true)
                elseif c.objeto then
                    dCaixa(string.format("conhecida %.0f studs", c.distanciaObjeto or 0), true)
                elseif c.salva then
                    dCaixa(string.format("aprendida %.0f studs", c.distanciaSalva or 0), true)
                elseif c.placa and c.candidatos > 0 then
                    dCaixa(c.candidatos .. " possível(is)", nil)
                elseif c.placa then
                    dCaixa("toque nela 1 vez", false)
                else
                    dCaixa("casa não achada", false)
                end
            end
        end
        C.botao({
            Parent = cardJogo, LayoutOrder = 10, Texto = "ATUALIZAR", Variante = "primario",
            Size = UDim2.new(1, 0, 0, 22), TextSize = 10, OnClick = function() atualizarDiagnostico(true) end,
        })

        local rodadaDiag = 0
        aoAbrirAba[5] = function()
            rodadaDiag += 1
            local minha = rodadaDiag
            pcall(atualizarDiagnostico, true)
            while gui.Parent and abaAtual == 5 and rodadaDiag == minha do
                task.wait(1)
                if abaAtual == 5 and rodadaDiag == minha then pcall(atualizarDiagnostico, false) end
            end
        end

        local cardReg = C.card({ Parent = pgRegistro, Lista = false })
        C.cabecalho(cardReg, 0, nil, "Registro")
        C.botao({
            Parent = cardReg, Texto = "COPIAR", Position = UDim2.new(1, -122, 0, -3),
            Size = UDim2.new(0, 58, 0, 20), TextSize = 9,
            OnClick = function()
                Utils.setStatus(se(Utils.copiar(Utils.textoRegistro()), "Registro copiado", "Não deu para copiar"), "info")
            end,
        })
        C.botao({
            Parent = cardReg, Texto = "LIMPAR", Position = UDim2.new(1, -58, 0, -3),
            Size = UDim2.new(0, 58, 0, 20), TextSize = 9,
            OnClick = function()
                table.clear(Utils.registro)
                Utils.RegistroMudou:Fire()
            end,
        })
        local fundoReg = C.criar("Frame", {
            Parent = cardReg, BackgroundColor3 = Tema.fundo, Position = UDim2.new(0, 0, 0, 24), Size = UDim2.new(1, 0, 1, -24),
        }, { C.canto(5), C.borda() })
        local listaReg = scroll(fundoReg, { Size = UDim2.new(1, 0, 1, 0) })
        C.padding(6, 8, 6, 8).Parent = listaReg
        C.lista(2).Parent = listaReg

        local registroSujo = true
        local function renderRegistro()
            registroSujo = false
            for _, filho in ipairs(listaReg:GetChildren()) do
                if filho:IsA("TextLabel") then filho:Destroy() end
            end
            for i, r in ipairs(Utils.registro) do
                if i > 80 then break end
                local cor = Tema.status[r.tipo] or Tema.suave
                C.texto({
                    Parent = listaReg, LayoutOrder = i, Size = UDim2.new(1, -4, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                    TextWrapped = true, RichText = true, Font = Tema.fonteMono, TextSize = 9, TextColor3 = cor,
                    Text = '<font color="#584f68">' .. r.hora .. "</font> " .. Utils.escaparRich(r.texto),
                })
            end
        end
        maid:Add(Utils.RegistroMudou:Connect(function()
            if abaAtual == 6 then renderRegistro() else registroSujo = true end
        end))
        aoAbrirAba[6] = function()
            if registroSujo then renderRegistro() end
        end

        local cardConta, cardSite = colunas(pgSite, 0.52)
        C.cabecalho(cardConta, 1, nil, "Conta do site")
        local caixaConta = C.criar("Frame", {
            Parent = cardConta, LayoutOrder = 2, BackgroundColor3 = Tema.painel2,
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        }, { C.canto(6), C.padding(8, 10, 8, 10), C.borda(Tema.borda, 1, 0.2) })
        local textoConta = C.texto({
            Parent = caixaConta, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            TextWrapped = true, RichText = true, Font = Tema.fonteMono, TextSize = 10, Text = "",
        })
        local linhaConta = C.linha(cardConta, 3, 26)
        local botaoEntrarSite = C.botao({
            Parent = linhaConta, Texto = "ENTRAR", Variante = "primario", Size = UDim2.new(0.55, -3, 1, 0), TextSize = 11,
            OnClick = function() UI.mostrarLogin() end,
        })
        C.botao({
            Parent = linhaConta, Texto = "SAIR", Position = UDim2.new(0.55, 3, 0, 0), Size = UDim2.new(0.45, -3, 1, 0),
            TextSize = 10, OnClick = function() Site.sair() end,
        })
        C.texto({
            Parent = cardConta, LayoutOrder = 4, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            TextWrapped = true, Font = Tema.fonteMono, TextSize = 9, TextColor3 = Tema.apagado,
            Text = "cada celular entra com uma conta criada no site (configurações > entrega automática). a senha não fica salva aqui.",
        })

        semLista(cardSite)
        C.cabecalho(cardSite, 0, nil, "Pedidos do site")
        local listaAjSite = scroll(cardSite, { Position = UDim2.new(0, 0, 0, 20), Size = UDim2.new(1, 0, 1, -20) })
        C.padding(0, 6, 0, 0).Parent = listaAjSite
        C.lista(4).Parent = listaAjSite
        local infoSite = C.texto({
            Parent = listaAjSite, LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            TextWrapped = true, Font = Tema.fonteMono, TextSize = 10, TextColor3 = Tema.suave, Text = "",
        })
        for i, t in ipairs({
            { "SITE_LIGADO", "Buscar pedidos do site", "a cada 30 a 60 segundos" },
            { "SITE_AUTO_FILA", "Começar a fila sozinho", "quando chegar casinha nova" },
        }) do
            C.toggle({
                Parent = listaAjSite, LayoutOrder = 1 + i, Texto = t[2], Descricao = t[3], Valor = S[t[1]],
                OnChange = function(v)
                    S[t[1]] = v
                    App.salvarAjustes()
                end,
            })
        end
        C.botao({
            Parent = listaAjSite, LayoutOrder = 10, Texto = "BUSCAR AGORA", Size = UDim2.new(1, 0, 0, 22), TextSize = 10,
            OnClick = function() Site.buscarAgora() end,
        })
        C.botao({
            Parent = listaAjSite, LayoutOrder = 11, Texto = "MANDAR CASINHAS PRO SITE", Size = UDim2.new(1, 0, 0, 22), TextSize = 10,
            OnClick = function()
                if #E.todasAsCasas == 0 then
                    Utils.notificar("Abra o MY HOMES no jogo e toque em ESCANEAR (aba Entrega) primeiro.", "aviso")
                else
                    Site.enviarCasas(E.todasAsCasas)
                end
            end,
        })

        local function renderSite()
            local st = Site.estado
            local cor = se(st.logado, "#3ce696", se(st.erro ~= nil, "#ff4c60", "#a094b2"))
            textoConta.Text = string.format('<font color="%s">%s</font> %s\n<font color="#605672">%s</font>',
                cor, se(st.logado, "●", "○"), Utils.escaparRich(st.conta or "sem conta"), Utils.escaparRich(st.texto or ""))
            botaoEntrarSite.Text = se(st.logado, "TROCAR CONTA", "ENTRAR")
            infoSite.Text = string.format("> para esta conta: %d casinha(s)\n> última busca: %s\n> casinhas no site: %s",
                st.naFila or 0, st.ultimaBusca or "-",
                st.casasEnviadas and string.format("%d (às %s)", st.casasEnviadas.n, st.casasEnviadas.hora) or "escaneie para mandar")
        end
        maid:Add(Site.Mudou:Connect(renderSite))
        renderSite()

        local login = C.criar("Frame", {
            Parent = gui, Name = "Login", BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.35,
            Size = UDim2.new(1, 0, 1, 0), ZIndex = 40, Visible = false, Active = true,
        })
        local cartaoLogin = C.criar("Frame", {
            Parent = login, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 290, 0, 268), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 41,
        }, { C.canto(12), C.bordaNeon(0.25, 1.5), C.degrade(Tema.painel, Tema.fundoBaixo, 120), C.padding(18, 20, 16, 20) })
        local escalaLogin = C.criar("UIScale", { Parent = cartaoLogin })
        local function escalarLogin()
            local camera = workspace.CurrentCamera
            local tela = camera and camera.ViewportSize or Vector2.new(800, 600)
            escalaLogin.Scale = math.clamp(math.min((tela.X - 20) / 290, (tela.Y - 20) / 268), 0.6, 1)
        end
        escalarLogin()
        if workspace.CurrentCamera then
            maid:Add(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(escalarLogin))
        end

        local logoLogin = C.criar("Frame", {
            Parent = cartaoLogin, BackgroundColor3 = Color3.new(1, 1, 1), Size = UDim2.new(0, 36, 0, 36), ZIndex = 42,
        }, { C.canto(10), C.gradiente(45) })
        C.texto({
            Parent = logoLogin, Text = "S", Size = UDim2.new(1, 0, 1, 0), Font = Tema.fonteForte, TextSize = 18,
            TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 43,
        })
        C.texto({
            Parent = cartaoLogin, Text = "SAMHUB", Position = UDim2.new(0, 46, 0, 0), Size = UDim2.new(1, -46, 0, 20),
            Font = Tema.fonteForte, TextSize = 16, ZIndex = 42,
        })
        C.texto({
            Parent = cartaoLogin, Text = "entre com a sua conta // v" .. Config.VERSAO, Position = UDim2.new(0, 46, 0, 20),
            Size = UDim2.new(1, -46, 0, 14), Font = Tema.fonteMono, TextSize = 9, TextColor3 = Tema.suave, ZIndex = 42,
        })

        local function rotuloLogin(texto, y)
            C.texto({
                Parent = cartaoLogin, Text = texto, Position = UDim2.new(0, 0, 0, y), Size = UDim2.new(1, 0, 0, 12),
                Font = Tema.fonteMono, TextSize = 9, TextColor3 = Tema.rosaClaro, ZIndex = 42,
            })
        end
        rotuloLogin("USUÁRIO", 50)
        local campoUsuario = C.input({
            Parent = cartaoLogin, Position = UDim2.new(0, 0, 0, 64), Size = UDim2.new(1, 0, 0, 30),
            Placeholder = "ex.: celular1", Prefixo = "@",
        })
        rotuloLogin("SENHA", 102)
        local campoSenha = C.inputSenha({
            Parent = cartaoLogin, Position = UDim2.new(0, 0, 0, 116), Size = UDim2.new(1, 0, 0, 30),
            Placeholder = "sua senha", Prefixo = "#",
        })
        for _, o in ipairs({ campoUsuario, campoSenha }) do
            o.ZIndex = 42
            for _, d in ipairs(o:GetDescendants()) do
                if d:IsA("GuiObject") then d.ZIndex = 43 end
            end
        end
        local avisoLogin = C.texto({
            Parent = cartaoLogin, Text = "", Position = UDim2.new(0, 0, 0, 152), Size = UDim2.new(1, 0, 0, 26),
            Font = Tema.fonteMono, TextSize = 9, TextColor3 = Tema.vermelho, TextWrapped = true, ZIndex = 42,
            TextYAlignment = Enum.TextYAlignment.Top,
        })
        local botaoEntrar = C.botao({
            Parent = cartaoLogin, Texto = "ENTRAR", Variante = "primario", Position = UDim2.new(0, 0, 0, 182),
            Size = UDim2.new(1, 0, 0, 32), TextSize = 12,
        })
        botaoEntrar.ZIndex = 42
        local semSite = C.criar("TextButton", {
            Parent = cartaoLogin, Text = "usar sem o site", Position = UDim2.new(0, 0, 0, 220), Size = UDim2.new(1, 0, 0, 16),
            BackgroundTransparency = 1, Font = Tema.fonteMono, TextSize = 9, TextColor3 = Tema.suave, ZIndex = 42,
        })

        local entrando = false
        local function esconderLogin()
            login:SetAttribute("SamhubEscondido", nil)
            login.Visible = false
            campoSenha.Text = ""
        end
        function UI.mostrarLogin(msg)
            if not Site.configurado() then return end
            avisoLogin.Text = msg or ""
            avisoLogin.TextColor3 = Tema.vermelho
            if campoUsuario.Text == "" and Site.estado.conta then campoUsuario.Text = Site.estado.conta end
            login:SetAttribute("SamhubEscondido", nil)
            login.Visible = true
            escalarLogin()
            local alvo = escalaLogin.Scale
            escalaLogin.Scale = alvo * 0.94
            C.tween(escalaLogin, { Scale = alvo }, 0.18)
        end

        local function entrar()
            if entrando then return end
            entrando = true
            botaoEntrar.Text = "ENTRANDO..."
            avisoLogin.TextColor3 = Tema.suave
            avisoLogin.Text = "conferindo..."
            task.spawn(function()
                local ok, msg = Site.entrar(campoUsuario.Text, campoSenha.Text)
                entrando = false
                botaoEntrar.Text = "ENTRAR"
                if ok then
                    esconderLogin()
                else
                    campoSenha.Text = ""
                    avisoLogin.TextColor3 = Tema.vermelho
                    avisoLogin.Text = tostring(msg)
                end
            end)
        end
        botaoEntrar.MouseButton1Click:Connect(entrar)
        campoSenha.FocusLost:Connect(function(enter) if enter then entrar() end end)
        campoUsuario.FocusLost:Connect(function(enter) if enter then campoSenha:CaptureFocus() end end)
        semSite.MouseButton1Click:Connect(esconderLogin)
        maid:Add(Site.PedirLogin:Connect(function() UI.mostrarLogin() end))

        local function mostrarStatus(texto, tipo)
            textoStatus.Text = (Tema.icones[tipo] or "") .. " " .. texto
            textoStatus.TextColor3 = se(tipo == "erro" or tipo == "aviso", Tema.status[tipo], Tema.texto)
            barraStatus.BackgroundColor3 = Tema.status[tipo] or Tema.rosa
        end
        maid:Add(Utils.StatusMudou:Connect(function(texto, tipo)
            mostrarStatus(texto, tipo)
            if tipo == "ok" or tipo == "erro" then C.toast(gui, texto, tipo) end
        end))
        maid:Add(Utils.Notificou:Connect(function(texto, tipo)
            if S.POPUPS or janelaAberta() then C.toast(gui, texto, tipo) end
        end))

        local ESTADOS = {
            ativo = { "● ON", Tema.verde },
            pausado = { "PAUSA", Tema.amarelo },
            inativo = { "OFF", Tema.apagado },
        }
        local function atualizarEstado()
            local estado = Trade.estado()
            local info = ESTADOS[estado]
            textoChip.Text = info[1]
            textoChip.TextColor3 = info[2]
            bordaChip.Color = info[2]
            pontoEstado.BackgroundColor3 = info[2]
            if not buscando then
                botaoAtivar.Text = se(estado == "inativo", "ATIVAR", "DESATIVAR")
                C.pintar(botaoAtivar, se(estado == "inativo", Tema.rosa, Tema.vermelho))
            end
            botaoPausa.Text = se(estado == "pausado", "CONTINUAR", "PAUSAR")
            caixaNick.TextEditable = estado == "inativo"
            caixaNick.TextColor3 = se(estado == "inativo", Tema.texto, Tema.suave)
            renderCasas()
        end
        maid:Add(Utils.EstadoMudou:Connect(atualizarEstado))

        local bolha = C.criar("TextButton", {
            Parent = gui, Name = "Bolha", Text = "S", AutoButtonColor = false, Visible = false,
            BackgroundColor3 = Tema.painel2, AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, 40, 0.5, 0), Size = UDim2.new(0, 42, 0, 42),
            Font = Tema.fonteForte, TextSize = 18, TextColor3 = Tema.texto,
        }, {
            C.criar("UICorner", { CornerRadius = UDim.new(1, 0) }),
            C.bordaNeon(0, 2),
        })
        local anel = C.criar("Frame", {
            Parent = bolha, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ZIndex = 0,
        }, { C.criar("UICorner", { CornerRadius = UDim.new(1, 0) }), C.bordaNeon(1, 2) })
        local contornoAnel = anel:FindFirstChildOfClass("UIStroke")
        local respirando = false
        local function respirar(ligar)
            if ligar == respirando then return end
            respirando = ligar
            if not ligar then return end
            task.spawn(function()
                while respirando and bolha.Parent do
                    anel.Size = UDim2.new(1, 0, 1, 0)
                    contornoAnel.Transparency = 0.2
                    C.tween(anel, { Size = UDim2.new(1, 18, 1, 18) }, 0.9)
                    C.tween(contornoAnel, { Transparency = 1 }, 0.9)
                    task.wait(1.1)
                end
                contornoAnel.Transparency = 1
            end)
        end
        maid:Add(Utils.StatusMudou:Connect(function(_, tipo) respirar(tipo == "espera") end))
        local pontinho = C.criar("Frame", {
            Parent = bolha, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.85, 0, 0.15, 0),
            Size = UDim2.new(0, 10, 0, 10), BackgroundColor3 = Tema.apagado,
        }, {
            C.criar("UICorner", { CornerRadius = UDim.new(1, 0) }),
            C.criar("UIStroke", { Color = Tema.fundo, Thickness = 2 }),
        })
        local function pintarPontinho()
            pontinho.BackgroundColor3 = ESTADOS[Trade.estado()][2]
        end
        pintarPontinho()
        maid:Add(Utils.EstadoMudou:Connect(pintarPontinho))

        local function definirVisivel(obj, valor)
            if not obj then return end
            obj:SetAttribute("SamhubEscondido", nil)
            obj.Visible = valor
        end

        local hudRef
        local function mostrarJanela()
            definirVisivel(bolha, false)
            definirVisivel(moldura, true)
            definirVisivel(hudRef, false)
            pop()
        end
        local function mostrarBolha()
            definirVisivel(moldura, false)
            definirVisivel(bolha, true)
        end
        arrastavel(bolha, bolha, maid, mostrarJanela)
        botaoMin.MouseButton1Click:Connect(mostrarBolha)
        logo.MouseButton1Click:Connect(mostrarBolha)

        maid:Add(UIS.InputBegan:Connect(function(input, processado)
            if not processado and input.KeyCode == S.TECLA_MENU then
                if janelaAberta() then mostrarBolha() else mostrarJanela() end
            end
        end))

        local hud = C.criar("Frame", {
            Parent = gui, Name = "Hud", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 46),
            Size = UDim2.new(0, 0, 0, 24), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = Tema.fundo,
            BackgroundTransparency = 0.08, Visible = false,
        }, { C.canto(12), C.padding(0, 12, 0, 22), C.bordaNeon(0.3) })
        local pontoHud = C.criar("Frame", {
            Parent = hud, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, -13, 0.5, 0),
            Size = UDim2.new(0, 6, 0, 6), BackgroundColor3 = Tema.rosa,
        }, { C.canto(3) })
        local textoHud = C.texto({
            Parent = hud, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X,
            Font = Tema.fonteMono, TextSize = 10,
        })
        local contadorHud = 0
        local function mostrarHud(texto, tipo)
            if not S.POPUPS or janelaAberta() then
                definirVisivel(hud, false)
                return
            end
            if #texto > 70 then texto = string.sub(texto, 1, 67) .. "..." end
            contadorHud += 1
            local meu = contadorHud
            local cor = Tema.status[tipo] or Tema.rosa
            textoHud.Text = texto
            textoHud.TextColor3 = se(tipo == "espera" or tipo == "info", Tema.texto, cor)
            pontoHud.BackgroundColor3 = cor
            definirVisivel(hud, true)
            task.spawn(function()
                local aceso = true
                while contadorHud == meu and tipo == "espera" and hud.Visible do
                    aceso = not aceso
                    pontoHud.BackgroundTransparency = se(aceso, 0, 0.7)
                    task.wait(0.45)
                end
                pontoHud.BackgroundTransparency = 0
            end)
            task.delay(se(tipo == "espera", 12, 5), function()
                if contadorHud == meu then definirVisivel(hud, false) end
            end)
        end
        hudRef = hud
        maid:Add(Utils.StatusMudou:Connect(mostrarHud))

        maid:Add(Utils.Trabalho:Connect(function()
            local telaLogin = gui:FindFirstChild("Login")
            if telaLogin and telaLogin.Visible and not entrando then
                telaLogin:SetAttribute("SamhubEscondido", nil)
                telaLogin.Visible = false
            end
            if S.MINIMIZAR_AUTO and janelaAberta() then mostrarBolha() end
        end))

        local function cobre(obj, ponto)
            if not obj or not obj.Visible then return false end
            local pos, tam = obj.AbsolutePosition, obj.AbsoluteSize
            return ponto.X >= pos.X and ponto.X <= pos.X + tam.X and ponto.Y >= pos.Y and ponto.Y <= pos.Y + tam.Y
        end
        Utils.esconderMenuSeCobrir = function(ponto)
            local escondidos = {}
            for _, obj in ipairs({ moldura, bolha, hud, gui:FindFirstChild("Toasts") or false, gui:FindFirstChild("Login") or false }) do
                if obj and cobre(obj, ponto) then
                    obj:SetAttribute("SamhubEscondido", true)
                    obj.Visible = false
                    table.insert(escondidos, obj)
                end
            end
            if #escondidos == 0 then return nil end
            return function()
                for _, obj in ipairs(escondidos) do
                    if obj.Parent and obj:GetAttribute("SamhubEscondido") then
                        obj:SetAttribute("SamhubEscondido", nil)
                        obj.Visible = true
                    end
                end
            end
        end
        maid:Add(function() Utils.esconderMenuSeCobrir = nil end)

        irPara(1)
        mostrarStatus(E.status, E.statusTipo)
        atualizarEstado()
        renderHistorico()
        renderFila()
        pop()

        UI.gui = gui
        return gui
    end

    return UI
end
