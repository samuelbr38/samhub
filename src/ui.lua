return function(App)
    local Config, Tema, Utils, C = App.Config, App.Tema, App.Utils, App.C
    local Scanner, Trade, Mapeador, Historico, Casa = App.Scanner, App.Trade, App.Mapeador, App.Historico, App.Casa
    local S, E = Config.SAMHUB, Config.Estado

    local Players = game:GetService("Players")
    local UIS = game:GetService("UserInputService")
    local CoreGui = game:GetService("CoreGui")

    local UI = {}

    local W, H = Tema.largura, Tema.altura
    local LAT, TOPO = Tema.larguraLateral, Tema.alturaTopo
    local ALTURA_MARCA = 64

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

    local function arrastavel(janela, alca, maid)
        local arrastando, inicioPos, inicioMouse = false, nil, nil
        alca.InputBegan:Connect(function(input)
            local tipo = input.UserInputType
            if tipo == Enum.UserInputType.MouseButton1 or tipo == Enum.UserInputType.Touch then
                arrastando, inicioPos, inicioMouse = true, janela.Position, input.Position
                local conexao
                conexao = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        arrastando = false
                        conexao:Disconnect()
                    end
                end)
            end
        end)
        maid:Add(UIS.InputChanged:Connect(function(input)
            local tipo = input.UserInputType
            if arrastando and (tipo == Enum.UserInputType.MouseMovement or tipo == Enum.UserInputType.Touch) then
                local delta = input.Position - inicioMouse
                janela.Position = UDim2.new(
                    inicioPos.X.Scale, inicioPos.X.Offset + delta.X,
                    inicioPos.Y.Scale, inicioPos.Y.Offset + delta.Y
                )
            end
        end))
    end

    local function contarSelecionadas()
        local n = 0
        for _ in pairs(E.casasSelecionadas) do n += 1 end
        return n
    end

    local function pagina(pai)
        return C.criar("Frame", {
            Parent = pai, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Visible = false,
        }, { C.padding(16, 16, 16, 16) })
    end

    local function colunas(pg, proporcao)
        local esquerda = C.card({ Parent = pg, Size = UDim2.new(proporcao, -6, 1, 0) })
        local direita = C.card({
            Parent = pg, Position = UDim2.new(proporcao, 6, 0, 0), Size = UDim2.new(1 - proporcao, -6, 1, 0),
        })
        return esquerda, direita
    end

    function UI.criar(maid)
        local gui = C.criar("ScreenGui", {
            Name = "SAMHUB_Menu", ResetOnSpawn = false, IgnoreGuiInset = true,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 50,
        })
        colocarNaTela(gui)
        maid:Add(gui)

        local janela = C.criar("Frame", {
            Parent = gui, BackgroundColor3 = Tema.fundo, ClipsDescendants = true,
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, W, 0, 0),
        }, { C.canto(14), C.borda(Tema.borda) })

        local escala = C.criar("UIScale", { Parent = janela })
        local function ajustarEscala()
            local camera = workspace.CurrentCamera
            if not camera then return end
            local tela = camera.ViewportSize
            escala.Scale = math.clamp(math.min((tela.X - 24) / W, (tela.Y - 24) / H), 0.45, 1)
        end
        ajustarEscala()
        if workspace.CurrentCamera then
            maid:Add(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(ajustarEscala))
        end

        local lateral = C.criar("Frame", {
            Parent = janela, BackgroundColor3 = Tema.lateral, Size = UDim2.new(0, LAT, 1, 0),
        }, { C.canto(14) })
        C.criar("Frame", {
            Parent = lateral, BackgroundColor3 = Tema.lateral, BorderSizePixel = 0,
            Position = UDim2.new(1, -14, 0, 0), Size = UDim2.new(0, 14, 1, 0),
        })
        C.criar("Frame", {
            Parent = lateral, BackgroundColor3 = Tema.borda, BorderSizePixel = 0,
            Position = UDim2.new(1, -1, 0, 0), Size = UDim2.new(0, 1, 1, 0),
        })

        local marca = C.criar("Frame", {
            Parent = lateral, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, ALTURA_MARCA),
        })
        local fundoLogo = C.criar("Frame", {
            Parent = marca, BackgroundColor3 = Color3.new(1, 1, 1),
            Position = UDim2.new(0, 14, 0, 15), Size = UDim2.new(0, 34, 0, 34),
        }, { C.canto(10), C.gradiente(45) })
        local logo = C.criar("TextButton", {
            Parent = fundoLogo, Text = "S", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
            Font = Tema.fonteForte, TextSize = 17, TextColor3 = Color3.new(1, 1, 1),
        })
        C.texto({
            Parent = marca, Text = "SAMHUB", Position = UDim2.new(0, 58, 0, 15), Size = UDim2.new(1, -62, 0, 18),
            Font = Tema.fonteForte, TextSize = 15,
        })
        C.texto({
            Parent = marca, Text = "v" .. Config.VERSAO .. " · Adopt Me", Position = UDim2.new(0, 58, 0, 33),
            Size = UDim2.new(1, -62, 0, 14), TextSize = 10, TextColor3 = Tema.rosaClaro,
        })

        local nav = C.criar("Frame", {
            Parent = lateral, BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, ALTURA_MARCA + 8),
            Size = UDim2.new(1, 0, 0, 200),
        }, { C.padding(0, 10, 0, 10), C.lista(4) })

        local cardEstado = C.criar("Frame", {
            Parent = lateral, BackgroundColor3 = Tema.painel2, Position = UDim2.new(0, 10, 1, -82),
            Size = UDim2.new(1, -20, 0, 70),
        }, { C.canto(10), C.borda() })
        local selo = C.criar("Frame", {
            Parent = cardEstado, BackgroundColor3 = Tema.apagado, Position = UDim2.new(0, 10, 0, 10),
            Size = UDim2.new(0, 80, 0, 20),
        }, { C.canto(10) })
        local textoSelo = C.texto({
            Parent = selo, Text = "INATIVO", Size = UDim2.new(1, 0, 1, 0), Font = Tema.fonteForte, TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Center,
        })
        local textoComprador = C.texto({
            Parent = cardEstado, Text = "Nenhum comprador", Position = UDim2.new(0, 10, 0, 38),
            Size = UDim2.new(1, -20, 0, 20), TextSize = 11, TextColor3 = Tema.suave,
            TextTruncate = Enum.TextTruncate.AtEnd,
        })

        local area = C.criar("Frame", {
            Parent = janela, BackgroundTransparency = 1, Position = UDim2.new(0, LAT, 0, 0),
            Size = UDim2.new(1, -LAT, 1, 0),
        })
        local topo = C.criar("Frame", { Parent = area, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, TOPO) })
        C.criar("Frame", {
            Parent = topo, BackgroundColor3 = Tema.borda, BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1),
        })
        local tituloPagina = C.texto({
            Parent = topo, Position = UDim2.new(0, 20, 0, 11), Size = UDim2.new(1, -120, 0, 20),
            Font = Tema.fonteForte, TextSize = 17,
        })
        local subtituloPagina = C.texto({
            Parent = topo, Position = UDim2.new(0, 20, 0, 32), Size = UDim2.new(1, -120, 0, 14),
            TextSize = 11, TextColor3 = Tema.suave,
        })
        local botaoMin = C.icone({
            Parent = topo, Texto = "–", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -48, 0.5, 0),
        })
        C.icone({
            Parent = topo, Texto = "X", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0),
            CorHover = Tema.vermelho, OnClick = function() App.fechar() end,
        })

        local conteudo = C.criar("Frame", {
            Parent = area, BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, TOPO),
            Size = UDim2.new(1, 0, 1, -TOPO),
        })

        arrastavel(janela, topo, maid)
        arrastavel(janela, marca, maid)

        local ABAS = {
            { icone = "🚚", nome = "Entrega", sub = "Escolha o comprador e a casa" },
            { icone = "📜", nome = "Histórico", sub = "Trades finalizados, recusados e cancelados" },
            { icone = "⚙️", nome = "Ajustes", sub = "Comportamento e tempos" },
            { icone = "🧪", nome = "Diagnóstico", sub = "O que o script está vendo agora" },
        }
        local itensNav, paginas = {}, {}
        local abaAtual = 1
        local aoAbrirAba = {}

        local function irPara(i)
            abaAtual = i
            for j, pg in ipairs(paginas) do pg.Visible = (j == i) end
            for j, item in ipairs(itensNav) do
                local ativo = (j == i)
                C.tween(item.botao, { BackgroundTransparency = ativo and 0.82 or 1, TextColor3 = ativo and Tema.texto or Tema.suave })
                item.barra.Visible = ativo
            end
            tituloPagina.Text = ABAS[i].nome
            subtituloPagina.Text = ABAS[i].sub
            if aoAbrirAba[i] then task.spawn(aoAbrirAba[i]) end
        end

        for i, aba in ipairs(ABAS) do
            local botao = C.criar("TextButton", {
                Parent = nav, LayoutOrder = i, Text = aba.icone .. "   " .. aba.nome, AutoButtonColor = false,
                BackgroundColor3 = Tema.rosa, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 38),
                Font = Tema.fonteMedia, TextSize = 12, TextColor3 = Tema.suave,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, { C.canto(9), C.padding(0, 10, 0, 16) })
            local barra = C.criar("Frame", {
                Parent = botao, BackgroundColor3 = Tema.rosa, AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, -10, 0.5, 0), Size = UDim2.new(0, 3, 0, 18), Visible = false,
            }, { C.canto(2) })
            botao.MouseEnter:Connect(function()
                if abaAtual ~= i then C.tween(botao, { BackgroundTransparency = 0.92 }) end
            end)
            botao.MouseLeave:Connect(function()
                if abaAtual ~= i then C.tween(botao, { BackgroundTransparency = 1 }) end
            end)
            botao.MouseButton1Click:Connect(function() irPara(i) end)
            itensNav[i] = { botao = botao, barra = barra }
            paginas[i] = pagina(conteudo)
        end
        local pgEntrega, pgHistorico, pgAjustes, pgDiag = paginas[1], paginas[2], paginas[3], paginas[4]

        local cardComprador, cardCasas = colunas(pgEntrega, 0.42)

        C.cabecalho(cardComprador, 1, "👤", "Comprador")

        local cardStatus = C.criar("Frame", {
            Parent = cardComprador, LayoutOrder = 2, BackgroundColor3 = Tema.painel2,
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        }, { C.canto(9), C.padding(9, 10, 9, 18) })
        local barraStatus = C.criar("Frame", {
            Parent = cardStatus, BackgroundColor3 = Tema.rosa, Position = UDim2.new(0, -10, 0, 0),
            Size = UDim2.new(0, 3, 1, 0),
        }, { C.canto(2) })
        local textoStatus = C.texto({
            Parent = cardStatus, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            TextWrapped = true, Font = Tema.fonteMedia, TextSize = 11, Text = "",
        })

        local caixaNick = C.input({
            Parent = cardComprador, LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 34),
            Placeholder = "@username ou apelido", Icone = "👤",
        })

        local buscando = false
        local botaoAtivar = C.botao({
            Parent = cardComprador, LayoutOrder = 4, Texto = "▶  Ativar", Variante = "primario",
            Size = UDim2.new(1, 0, 0, 40), TextSize = 13,
        })

        local linhaControle = C.linha(cardComprador, 5, 32)
        local botaoPausa = C.botao({
            Parent = linhaControle, Texto = "⏸  Pausar", Size = UDim2.new(0.5, -4, 1, 0), TextSize = 11,
            OnClick = function() Trade.alternarPausa() end,
        })
        C.botao({
            Parent = linhaControle, Texto = "🔄  Resetar", Position = UDim2.new(0.5, 4, 0, 0),
            Size = UDim2.new(0.5, -4, 1, 0), TextSize = 11,
            OnClick = function()
                Trade.resetar()
                caixaNick.Text = ""
            end,
        })

        local linhaCasa = C.linha(cardComprador, 6, 32)
        C.botao({
            Parent = linhaCasa, Texto = "📮  À venda", Size = UDim2.new(0.5, -4, 1, 0), TextSize = 11,
            OnClick = function() task.spawn(Casa.listarParaTroca) end,
        })
        C.botao({
            Parent = linhaCasa, Texto = "🔎  Conferir", Position = UDim2.new(0.5, 4, 0, 0),
            Size = UDim2.new(0.5, -4, 1, 0), TextSize = 11,
            OnClick = function() task.spawn(Casa.conferirVenda) end,
        })

        cardCasas:FindFirstChildWhichIsA("UIListLayout"):Destroy()
        C.cabecalho(cardCasas, 0, "🏠", "Suas casas")
        local contador = C.texto({
            Parent = cardCasas, Size = UDim2.new(1, 0, 0, 18), TextXAlignment = Enum.TextXAlignment.Right,
            TextSize = 10, TextColor3 = Tema.suave, Text = "",
        })
        local caixaBusca = C.input({
            Parent = cardCasas, Position = UDim2.new(0, 0, 0, 32), Size = UDim2.new(1, -112, 0, 32),
            Placeholder = "Filtrar casas...", Icone = "🔎",
        })
        C.botao({
            Parent = cardCasas, Texto = "🔍  Escanear", Variante = "primario",
            Position = UDim2.new(1, -104, 0, 32), Size = UDim2.new(0, 104, 0, 32), TextSize = 11,
            OnClick = function() Scanner.escanear() end,
        })
        local fundoLista = C.criar("Frame", {
            Parent = cardCasas, BackgroundColor3 = Tema.painel2, Position = UDim2.new(0, 0, 0, 74),
            Size = UDim2.new(1, 0, 1, -74),
        }, { C.canto(9) })
        local listaCasas = C.criar("ScrollingFrame", {
            Parent = fundoLista, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0),
            ScrollBarThickness = 3, ScrollBarImageColor3 = Tema.rosa,
            AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
        }, { C.padding(6), C.lista(3) })
        local avisoVazio = C.texto({
            Parent = fundoLista, Size = UDim2.new(1, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Center,
            TextColor3 = Tema.apagado, TextSize = 11, TextWrapped = true,
            Text = "Abra a lista MY HOMES no jogo\ne clique em Escanear",
        })

        local function atualizarContador()
            contador.Text = contarSelecionadas() .. " de " .. #E.todasAsCasas .. " selecionada(s)"
        end

        local function criarLinhaCasa(casa, ordem)
            local linha = C.criar("TextButton", {
                Parent = listaCasas, LayoutOrder = ordem, Text = "", AutoButtonColor = false,
                BackgroundColor3 = Tema.hover, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 32),
            }, { C.canto(7) })
            local caixa = C.criar("Frame", {
                Parent = linha, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0),
                Size = UDim2.new(0, 18, 0, 18), BackgroundColor3 = Tema.painel,
            }, { C.canto(6) })
            local bordaCaixa = C.borda(Tema.apagado)
            bordaCaixa.Parent = caixa
            local check = C.texto({
                Parent = caixa, Text = "✓", Size = UDim2.new(1, 0, 1, 0), Font = Tema.fonteForte,
                TextSize = 13, TextXAlignment = Enum.TextXAlignment.Center,
            })
            local textoLinha = (casa.icone or "🏠") .. "  " .. Utils.escaparRich(casa.nome)
            if casa.detalhe and casa.detalhe ~= "" then
                textoLinha ..= '  <font color="#8c7088" size="10">' .. Utils.escaparRich(casa.detalhe) .. "</font>"
            end
            local nome = C.texto({
                Parent = linha, Position = UDim2.new(0, 38, 0, 0), Size = UDim2.new(1, -46, 1, 0),
                Text = textoLinha, RichText = true, TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd,
            })

            local function desenhar()
                local marcada = E.casasSelecionadas[casa.nome] == true
                C.tween(caixa, { BackgroundColor3 = marcada and Tema.rosa or Tema.painel }, 0.1)
                bordaCaixa.Color = marcada and Tema.rosa or Tema.apagado
                check.Visible = marcada
                nome.TextColor3 = marcada and Tema.texto or Tema.suave
            end
            desenhar()

            linha.MouseEnter:Connect(function() C.tween(linha, { BackgroundTransparency = 0 }) end)
            linha.MouseLeave:Connect(function() C.tween(linha, { BackgroundTransparency = 1 }) end)
            linha.MouseButton1Click:Connect(function()
                if Trade.estado() ~= "inativo" then
                    return Utils.setStatus("Desative antes de mudar as casas", "aviso")
                end
                E.casasSelecionadas[casa.nome] = (not E.casasSelecionadas[casa.nome]) or nil
                desenhar()
                atualizarContador()
            end)
        end

        local function renderCasas()
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
            if #E.todasAsCasas > 0 and mostradas == 0 then
                avisoVazio.Text = "Nenhuma casa com esse nome"
            end
            atualizarContador()
        end
        caixaBusca:GetPropertyChangedSignal("Text"):Connect(renderCasas)

        botaoAtivar.MouseButton1Click:Connect(function()
            if buscando then return end
            if Trade.estado() ~= "inativo" then return Trade.desativar() end
            if Utils.limpar(caixaNick.Text) == "" then
                return Utils.setStatus("Digite o @username do comprador", "aviso")
            end
            if contarSelecionadas() == 0 then
                return Utils.setStatus("Marque a casa que vai vender (lista ao lado)", "aviso")
            end
            buscando = true
            botaoAtivar.Text = "Buscando..."
            Trade.ativar(caixaNick.Text, function(achou)
                buscando = false
                Utils.EstadoMudou:Fire()
                if achou and S.LISTAR_AO_ATIVAR then
                    task.wait(0.5)
                    Casa.listarParaTroca()
                end
            end)
        end)

        local cardResumo, cardLista = colunas(pgHistorico, 0.3)
        C.cabecalho(cardResumo, 1, "📊", "Resumo")

        local CORES_RESULTADO = {
            finalizado = Tema.verde, recusado = Tema.vermelho, cancelado = Tema.amarelo,
        }
        local numeros = {}
        for i, info in ipairs({ { "finalizado", "Finalizados" }, { "recusado", "Recusados" }, { "cancelado", "Cancelados" } }) do
            local card = C.criar("Frame", {
                Parent = cardResumo, LayoutOrder = 1 + i, BackgroundColor3 = Tema.painel2,
                Size = UDim2.new(1, 0, 0, 54),
            }, { C.canto(9) })
            C.criar("Frame", {
                Parent = card, BackgroundColor3 = CORES_RESULTADO[info[1]], Position = UDim2.new(0, 0, 0, 12),
                Size = UDim2.new(0, 3, 1, -24),
            }, { C.canto(2) })
            numeros[info[1]] = C.texto({
                Parent = card, Text = "0", Position = UDim2.new(0, 14, 0, 7), Size = UDim2.new(1, -20, 0, 24),
                Font = Tema.fonteForte, TextSize = 20, TextColor3 = CORES_RESULTADO[info[1]],
            })
            C.texto({
                Parent = card, Text = info[2], Position = UDim2.new(0, 14, 0, 31), Size = UDim2.new(1, -20, 0, 14),
                TextSize = 10, TextColor3 = Tema.suave,
            })
        end
        C.botao({
            Parent = cardResumo, LayoutOrder = 10, Texto = "📋  Copiar", Size = UDim2.new(1, 0, 0, 30), TextSize = 11,
            OnClick = function()
                local texto = Historico.texto()
                print("===== SAMHUB: HISTÓRICO =====\n" .. texto)
                Utils.setStatus(Utils.copiar(texto) and "Histórico copiado" or "Histórico no console (F9)", "info")
            end,
        })
        C.botao({
            Parent = cardResumo, LayoutOrder = 11, Texto = "🗑  Limpar", Size = UDim2.new(1, 0, 0, 30), TextSize = 11,
            OnClick = function() Historico.limpar() end,
        })

        cardLista:FindFirstChildWhichIsA("UIListLayout"):Destroy()
        C.cabecalho(cardLista, 0, "📜", "Últimos trades")
        local listaHist = C.criar("ScrollingFrame", {
            Parent = cardLista, BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 32),
            Size = UDim2.new(1, 0, 1, -32), ScrollBarThickness = 3, ScrollBarImageColor3 = Tema.rosa,
            AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
        }, { C.lista(6) })
        local vazioHist = C.texto({
            Parent = cardLista, Position = UDim2.new(0, 0, 0, 32), Size = UDim2.new(1, 0, 1, -32), TextSize = 11,
            TextColor3 = Tema.apagado, TextXAlignment = Enum.TextXAlignment.Center,
            Text = "Nenhum trade registrado ainda",
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
                    Parent = listaHist, LayoutOrder = i, BackgroundColor3 = Tema.painel2,
                    Size = UDim2.new(1, -6, 0, 44),
                }, { C.canto(9) })
                C.criar("Frame", {
                    Parent = card, BackgroundColor3 = cor, AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, 12, 0.5, 0), Size = UDim2.new(0, 8, 0, 8),
                }, { C.canto(4) })
                C.texto({
                    Parent = card, Text = "@" .. tostring(r.nick), Position = UDim2.new(0, 28, 0, 6),
                    Size = UDim2.new(1, -130, 0, 16), Font = Tema.fonteMedia, TextTruncate = Enum.TextTruncate.AtEnd,
                })
                C.texto({
                    Parent = card, Text = (r.detalhe ~= "" and r.detalhe) or "-", Position = UDim2.new(0, 28, 0, 23),
                    Size = UDim2.new(1, -130, 0, 14), TextSize = 10, TextColor3 = Tema.suave,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                })
                C.texto({
                    Parent = card, Text = string.upper(tostring(r.resultado)), AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, -12, 0, 6), Size = UDim2.new(0, 100, 0, 16), Font = Tema.fonteForte,
                    TextSize = 9, TextColor3 = cor, TextXAlignment = Enum.TextXAlignment.Right,
                })
                C.texto({
                    Parent = card, Text = tostring(r.hora), AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, -12, 0, 23), Size = UDim2.new(0, 100, 0, 14), TextSize = 10,
                    TextColor3 = Tema.apagado, TextXAlignment = Enum.TextXAlignment.Right,
                })
            end
            for chave, rotulo in pairs(numeros) do rotulo.Text = tostring(cont[chave] or 0) end
            vazioHist.Visible = #Historico.listar() == 0
        end
        maid:Add(Historico.Mudou:Connect(renderHistorico))

        local cardTrade, cardTempo = colunas(pgAjustes, 0.5)
        cardTrade:FindFirstChildWhichIsA("UIListLayout").Padding = UDim.new(0, 4)

        C.cabecalho(cardTrade, 1, "🔄", "Trade")
        local function toggle(ordem, chave, texto, descricao)
            C.toggle({
                Parent = cardTrade, LayoutOrder = ordem, Texto = texto, Descricao = descricao, Valor = S[chave],
                OnChange = function(v)
                    S[chave] = v
                    App.salvarAjustes()
                end,
            })
        end
        toggle(2, "ACEITAR_PEDIDO", "Aceitar pedido", "Accept no aviso dele")
        toggle(3, "LISTAR_AO_ATIVAR", "Pôr à venda ao ativar", "Usa a caixa de correio")
        toggle(4, "ANDAR_ATE_CAIXA", "Andar até a caixa", "Vai sozinho até ela")
        toggle(5, "CONFERIR_VENDA", "Conferir após listar", "Acha a casa com Unlist")
        toggle(6, "RECUSAR_OUTROS", "Recusar outras pessoas", "Desligado: só ignora")
        toggle(7, "VERIFICAR_CASA", "Conferir casa no trade", "Só se a casa aparecer")

        C.cabecalho(cardTempo, 1, "⏱", "Tempo")
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

        C.cabecalho(cardTempo, 5, "⌨️", "Atalhos")
        C.texto({
            Parent = cardTempo, LayoutOrder = 6, Size = UDim2.new(1, 0, 0, 16), TextSize = 11,
            TextColor3 = Tema.suave, Text = S.TECLA_MENU.Name .. "  →  esconder / mostrar",
        })
        C.texto({
            Parent = cardTempo, LayoutOrder = 7, Size = UDim2.new(1, 0, 0, 16), TextSize = 11,
            TextColor3 = Tema.suave, Text = "Logo  →  minimizar / abrir",
        })
        C.texto({
            Parent = cardTempo, LayoutOrder = 8, Size = UDim2.new(1, 0, 0, 16), TextSize = 11,
            TextColor3 = se(Utils.temArquivos, Tema.verde, Tema.amarelo),
            Text = se(Utils.temArquivos, "●  Ajustes salvos em arquivo", "●  Executor não salva arquivos"),
        })

        local cardExec, cardJogo = colunas(pgDiag, 0.5)
        cardExec:FindFirstChildWhichIsA("UIListLayout").Padding = UDim.new(0, 6)
        cardJogo:FindFirstChildWhichIsA("UIListLayout").Padding = UDim.new(0, 6)

        C.cabecalho(cardExec, 1, "🧪", "Executor")
        local dExecutor = C.info(cardExec, 2, "Executor")
        local dVim = C.info(cardExec, 3, "Clique virtual")
        local dConexoes = C.info(cardExec, 4, "getconnections")
        local dFire = C.info(cardExec, 5, "firesignal")
        local dArquivos = C.info(cardExec, 6, "Salvar arquivos")
        local dMetodo = C.info(cardExec, 7, "Último clique")

        local linhaMapa = C.linha(cardExec, 8, 30)
        C.botao({
            Parent = linhaMapa, Texto = "Mapear trade", Size = UDim2.new(0.5, -4, 1, 0), TextSize = 11,
            OnClick = function() Mapeador.mapearTrade() end,
        })
        C.botao({
            Parent = linhaMapa, Texto = "Mapear casas", Position = UDim2.new(0.5, 4, 0, 0),
            Size = UDim2.new(0.5, -4, 1, 0), TextSize = 11, OnClick = function() Mapeador.mapearCasas() end,
        })
        C.botao({
            Parent = cardExec, LayoutOrder = 9, Texto = "Mapear tudo", Size = UDim2.new(1, 0, 0, 30), TextSize = 11,
            OnClick = function() Mapeador.mapear() end,
        })

        C.cabecalho(cardJogo, 1, "🎮", "Jogo")
        local dJogo = C.info(cardJogo, 2, "Adopt Me")
        local dJanela = C.info(cardJogo, 3, "Janela de trade")
        local dParceiro = C.info(cardJogo, 4, "Parceiro lido")
        local dAceitar = C.info(cardJogo, 5, "Botão Aceitar")
        local dComprador = C.info(cardJogo, 6, "Comprador")
        local dPedido = C.info(cardJogo, 7, "Pedido de trade")
        local dLista = C.info(cardJogo, 8, "Lista MY HOMES")
        local dCaixa = C.info(cardJogo, 9, "Caixa de correio")

        local function atualizarDiagnostico(completo)
            local r = Utils.recursos
            dExecutor(Utils.nomeExecutor(), nil)
            dVim(se(r.vim, "sim", "não"), r.vim)
            dConexoes(se(r.getconnections, "sim", "não"), r.getconnections)
            dFire(se(r.firesignal, "sim", "não"), r.firesignal)
            dArquivos(se(r.arquivos, "sim", "não"), r.arquivos)
            dMetodo(Utils.metodoClique or "nenhum ainda", se(Utils.metodoClique ~= nil, true, nil))

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
                dComprador(d.comprador .. se(d.compradorNoServidor, " (no servidor)", " (fora)"), d.compradorNoServidor)
            else
                dComprador("não ativado", nil)
            end
            dPedido(se(d.pedidoNaTela, "na tela", "nenhum"), se(d.pedidoNaTela, true, nil))

            if completo then
                local painel = Scanner.acharPainel()
                dLista(se(painel ~= nil, "achada", "abra MY HOMES"), se(painel ~= nil, true, nil))
                local c = Casa.diagnostico()
                if c.menuAberto then
                    dCaixa("menu aberto", true)
                elseif c.caixaCorreio then
                    dCaixa(string.format("%s a %.0f studs", c.tipo or "achada", c.distancia or 0), true)
                elseif c.placa then
                    dCaixa(string.format("placa a %.0f studs", c.distanciaPlaca or 0), true)
                else
                    dCaixa("não achei", false)
                end
            end
        end

        C.botao({
            Parent = cardJogo, LayoutOrder = 10, Texto = "🔄  Atualizar", Variante = "primario",
            Size = UDim2.new(1, 0, 0, 30), TextSize = 11,
            OnClick = function() atualizarDiagnostico(true) end,
        })

        local rodadaDiag = 0
        aoAbrirAba[4] = function()
            rodadaDiag += 1
            local minha = rodadaDiag
            pcall(atualizarDiagnostico, true)
            while gui.Parent and abaAtual == 4 and rodadaDiag == minha do
                task.wait(1)
                if abaAtual == 4 and rodadaDiag == minha then pcall(atualizarDiagnostico, false) end
            end
        end

        local function mostrarStatus(texto, tipo)
            textoStatus.Text = (Tema.icones[tipo] or "") .. "  " .. texto
            C.tween(barraStatus, { BackgroundColor3 = Tema.status[tipo] or Tema.rosa })
        end
        maid:Add(Utils.StatusMudou:Connect(function(texto, tipo)
            mostrarStatus(texto, tipo)
            if tipo == "ok" or tipo == "erro" then C.toast(gui, texto, tipo) end
        end))

        local SELOS = {
            ativo = { "● ATIVO", Tema.rosa },
            pausado = { "⏸ PAUSADO", Tema.amarelo },
            inativo = { "INATIVO", Tema.apagado },
        }
        local function atualizarEstado()
            local estado = Trade.estado()
            textoSelo.Text = SELOS[estado][1]
            C.tween(selo, { BackgroundColor3 = SELOS[estado][2] })
            textoComprador.Text = se(E.userIdAlvo ~= nil, "@" .. tostring(E.nickAlvo), "Nenhum comprador")
            textoComprador.TextColor3 = se(E.userIdAlvo ~= nil, Tema.texto, Tema.suave)

            if not buscando then
                botaoAtivar.Text = se(estado == "inativo", "▶  Ativar", "⏹  Desativar")
                C.pintar(botaoAtivar, se(estado == "inativo", Tema.rosa, Tema.vermelho))
            end
            botaoPausa.Text = se(estado == "pausado", "▶  Continuar", "⏸  Pausar")
            caixaNick.TextEditable = estado == "inativo"
            caixaNick.TextColor3 = se(estado == "inativo", Tema.texto, Tema.suave)
            renderCasas()
        end
        maid:Add(Utils.EstadoMudou:Connect(atualizarEstado))

        local bolha = C.criar("TextButton", {
            Parent = gui, Name = "Bolha", Text = "", AutoButtonColor = false, Visible = false,
            BackgroundColor3 = Color3.new(1, 1, 1), AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, 56, 0.5, 0), Size = UDim2.new(0, 54, 0, 54),
        }, {
            C.criar("UICorner", { CornerRadius = UDim.new(1, 0) }),
            C.gradiente(45),
            C.criar("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2, Transparency = 0.35 }),
        })
        C.texto({
            Parent = bolha, Text = "S", Size = UDim2.new(1, 0, 1, 0), Font = Tema.fonteForte, TextSize = 24,
            TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Center,
        })
        local pontinho = C.criar("Frame", {
            Parent = bolha, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.85, 0, 0.15, 0),
            Size = UDim2.new(0, 14, 0, 14), BackgroundColor3 = Tema.apagado,
        }, {
            C.criar("UICorner", { CornerRadius = UDim.new(1, 0) }),
            C.criar("UIStroke", { Color = Tema.fundo, Thickness = 2 }),
        })

        local function pintarPontinho()
            pontinho.BackgroundColor3 = SELOS[Trade.estado()][2]
        end
        pintarPontinho()
        maid:Add(Utils.EstadoMudou:Connect(pintarPontinho))

        local function mostrarJanela()
            bolha.Visible = false
            janela.Visible = true
            janela.Size = UDim2.new(0, W, 0, 0)
            C.tween(janela, { Size = UDim2.new(0, W, 0, H) }, 0.25)
        end

        local function mostrarBolha()
            janela.Visible = false
            bolha.Visible = true
            bolha.Size = UDim2.new(0, 0, 0, 0)
            C.tween(bolha, { Size = UDim2.new(0, 54, 0, 54) }, 0.2)
        end

        local apertada, moveu, inicioPos, inicioToque = false, false, nil, nil
        bolha.InputBegan:Connect(function(input)
            local tipo = input.UserInputType
            if tipo == Enum.UserInputType.MouseButton1 or tipo == Enum.UserInputType.Touch then
                apertada, moveu, inicioPos, inicioToque = true, false, bolha.Position, input.Position
                local conexao
                conexao = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        conexao:Disconnect()
                        if apertada and not moveu then mostrarJanela() end
                        apertada = false
                    end
                end)
            end
        end)
        maid:Add(UIS.InputChanged:Connect(function(input)
            local tipo = input.UserInputType
            if apertada and (tipo == Enum.UserInputType.MouseMovement or tipo == Enum.UserInputType.Touch) then
                local delta = input.Position - inicioToque
                if math.abs(delta.X) + math.abs(delta.Y) > 6 then moveu = true end
                if moveu then
                    bolha.Position = UDim2.new(
                        inicioPos.X.Scale, inicioPos.X.Offset + delta.X,
                        inicioPos.Y.Scale, inicioPos.Y.Offset + delta.Y
                    )
                end
            end
        end))

        botaoMin.MouseButton1Click:Connect(mostrarBolha)
        logo.MouseButton1Click:Connect(mostrarBolha)

        maid:Add(UIS.InputBegan:Connect(function(input, processado)
            if not processado and input.KeyCode == S.TECLA_MENU then
                if janela.Visible then mostrarBolha() else mostrarJanela() end
            end
        end))

        local function cobre(obj, ponto)
            if not obj.Visible then return false end
            local pos, tam = obj.AbsolutePosition, obj.AbsoluteSize
            return ponto.X >= pos.X and ponto.X <= pos.X + tam.X and ponto.Y >= pos.Y and ponto.Y <= pos.Y + tam.Y
        end
        Utils.esconderMenuSeCobrir = function(ponto)
            local escondidos = {}
            for _, obj in ipairs({ janela, bolha }) do
                if cobre(obj, ponto) then
                    obj.Visible = false
                    table.insert(escondidos, obj)
                end
            end
            if #escondidos == 0 then return nil end
            return function()
                for _, obj in ipairs(escondidos) do obj.Visible = true end
            end
        end
        maid:Add(function() Utils.esconderMenuSeCobrir = nil end)

        irPara(1)
        mostrarStatus(E.status, E.statusTipo)
        atualizarEstado()
        renderHistorico()
        C.tween(janela, { Size = UDim2.new(0, W, 0, H) }, 0.35)

        UI.gui = gui
        return gui
    end

    return UI
end
