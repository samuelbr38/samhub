return function(App)
    local Config, Tema, Utils, C = App.Config, App.Tema, App.Utils, App.C
    local Scanner, Trade, Mapeador, Historico = App.Scanner, App.Trade, App.Mapeador, App.Historico
    local S, E = Config.SAMHUB, Config.Estado

    local Players = game:GetService("Players")
    local UIS = game:GetService("UserInputService")
    local CoreGui = game:GetService("CoreGui")

    local UI = {}

    local ALTURA_TOPO = 48
    local ALTURA_ABAS = 38

    local function colocarNaTela(gui)
        if typeof(gethui) == "function" then
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
        return C.criar("ScrollingFrame", {
            Parent = pai, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0),
            ScrollBarThickness = 3, ScrollBarImageColor3 = Tema.borda,
            AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Visible = false,
        }, { C.padding(14, 16, 14, 16), C.lista(8) })
    end

    function UI.criar(maid)
        local gui = C.criar("ScreenGui", {
            Name = "SAMHUB_Menu", ResetOnSpawn = false, IgnoreGuiInset = true,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        })
        colocarNaTela(gui)
        maid:Add(gui)

        local janela = C.criar("Frame", {
            Parent = gui, BackgroundColor3 = Tema.fundo, ClipsDescendants = true,
            Position = UDim2.new(0, 40, 0.5, -Tema.altura / 2), Size = UDim2.new(0, Tema.largura, 0, 0),
        }, { C.canto(Tema.raio), C.borda(Tema.borda) })

        local topo = C.criar("Frame", {
            Parent = janela, BackgroundColor3 = Tema.painel, Size = UDim2.new(1, 0, 0, ALTURA_TOPO),
        }, { C.canto(Tema.raio) })
        C.criar("Frame", {
            Parent = topo, BackgroundColor3 = Tema.painel, BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 1, -Tema.raio), Size = UDim2.new(1, 0, 0, Tema.raio),
        })

        local logo = C.criar("Frame", {
            Parent = topo, BackgroundColor3 = Color3.new(1, 1, 1), AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 14, 0.5, 0), Size = UDim2.new(0, 28, 0, 28),
        }, {
            C.canto(8),
            C.criar("UIGradient", {
                Color = ColorSequence.new(Tema.destaque, Tema.roxo), Rotation = 45,
            }),
        })
        C.texto({
            Parent = logo, Text = "S", Size = UDim2.new(1, 0, 1, 0), Font = Tema.fonteForte, TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Center,
        })

        C.texto({
            Parent = topo, Text = "SAMHUB", Position = UDim2.new(0, 52, 0, 8), Size = UDim2.new(0, 120, 0, 18),
            Font = Tema.fonteForte, TextSize = 14,
        })
        C.texto({
            Parent = topo, Text = "Entrega de casas · v" .. Config.VERSAO, Position = UDim2.new(0, 52, 0, 25),
            Size = UDim2.new(0, 160, 0, 14), TextSize = 10, TextColor3 = Tema.suave,
        })

        local selo = C.criar("Frame", {
            Parent = topo, BackgroundColor3 = Tema.apagado, AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -78, 0.5, 0), Size = UDim2.new(0, 70, 0, 20),
        }, { C.canto(10) })
        local textoSelo = C.texto({
            Parent = selo, Text = "INATIVO", Size = UDim2.new(1, 0, 1, 0), Font = Tema.fonteForte,
            TextSize = 9, TextXAlignment = Enum.TextXAlignment.Center,
        })

        local botaoMin = C.icone({
            Parent = topo, Texto = "–", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -42, 0.5, 0),
        })
        C.icone({
            Parent = topo, Texto = "✕", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
            CorHover = Tema.vermelho, OnClick = function() App.fechar() end,
        })

        arrastavel(janela, topo, maid)

        local barraAbas = C.criar("Frame", {
            Parent = janela, BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, ALTURA_TOPO),
            Size = UDim2.new(1, 0, 0, ALTURA_ABAS),
        })
        C.criar("Frame", {
            Parent = barraAbas, BackgroundColor3 = Tema.borda, BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1),
        })

        local nomesAbas = { "🚚  Entrega", "📜  Histórico", "⚙️  Ajustes" }
        local larguraAba = 1 / #nomesAbas
        local indicador = C.criar("Frame", {
            Parent = barraAbas, BackgroundColor3 = Tema.destaque, BorderSizePixel = 0,
            Position = UDim2.new(0, 16, 1, -2), Size = UDim2.new(larguraAba, -32, 0, 2),
        }, { C.canto(1) })

        local conteudo = C.criar("Frame", {
            Parent = janela, BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, ALTURA_TOPO + ALTURA_ABAS),
            Size = UDim2.new(1, 0, 1, -(ALTURA_TOPO + ALTURA_ABAS)),
        })

        local botoesAba, paginas = {}, {}
        local function irPara(i)
            for j, pg in ipairs(paginas) do pg.Visible = (j == i) end
            for j, b in ipairs(botoesAba) do
                C.tween(b, { TextColor3 = (j == i) and Tema.texto or Tema.suave })
            end
            C.tween(indicador, { Position = UDim2.new(larguraAba * (i - 1), 16, 1, -2) }, 0.2)
        end

        for i, nome in ipairs(nomesAbas) do
            botoesAba[i] = C.criar("TextButton", {
                Parent = barraAbas, Text = nome, BackgroundTransparency = 1, Font = Tema.fonteMedia, TextSize = 12,
                TextColor3 = Tema.suave, Position = UDim2.new(larguraAba * (i - 1), 0, 0, 0),
                Size = UDim2.new(larguraAba, 0, 1, -2),
            })
            botoesAba[i].MouseButton1Click:Connect(function() irPara(i) end)
            paginas[i] = pagina(conteudo)
        end
        local pgEntrega, pgHistorico, pgAjustes = paginas[1], paginas[2], paginas[3]

        local cardStatus = C.criar("Frame", {
            Parent = pgEntrega, LayoutOrder = 1, BackgroundColor3 = Tema.painel,
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        }, { C.canto(8), C.borda(), C.padding(10, 12, 10, 20) })
        local barraStatus = C.criar("Frame", {
            Parent = cardStatus, BackgroundColor3 = Tema.destaque, Position = UDim2.new(0, -12, 0, 0),
            Size = UDim2.new(0, 3, 1, 0),
        }, { C.canto(2) })
        local textoStatus = C.texto({
            Parent = cardStatus, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            TextWrapped = true, Font = Tema.fonteMedia, Text = "",
        })

        C.titulo(pgEntrega, 2, "Comprador")
        local caixaNick = C.input({
            Parent = pgEntrega, LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 34),
            Placeholder = "@username (não o apelido)", Icone = "👤",
        })

        local cabecalhoCasas = C.linha(pgEntrega, 4, 14)
        C.titulo(cabecalhoCasas, 0, "Suas casas")
        local contador = C.texto({
            Parent = cabecalhoCasas, Size = UDim2.new(1, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Right,
            TextSize = 10, TextColor3 = Tema.suave, Text = "",
        })

        local caixaBusca = C.input({
            Parent = pgEntrega, LayoutOrder = 5, Size = UDim2.new(1, 0, 0, 30),
            Placeholder = "Filtrar casas...", Icone = "🔎",
        })

        local fundoLista = C.criar("Frame", {
            Parent = pgEntrega, LayoutOrder = 6, BackgroundColor3 = Tema.painel, Size = UDim2.new(1, 0, 0, 140),
        }, { C.canto(8), C.borda() })
        local listaCasas = C.criar("ScrollingFrame", {
            Parent = fundoLista, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0),
            ScrollBarThickness = 3, ScrollBarImageColor3 = Tema.borda,
            AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
        }, { C.padding(6), C.lista(2) })
        local avisoVazio = C.texto({
            Parent = fundoLista, Size = UDim2.new(1, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Center,
            TextColor3 = Tema.apagado, TextSize = 11, TextWrapped = true,
            Text = "Abra a lista de casas no jogo\ne clique em Escanear",
        })

        local function atualizarContador()
            contador.Text = contarSelecionadas() .. " de " .. #E.todasAsCasas .. " selecionada(s)"
        end

        local function criarLinhaCasa(casa, ordem)
            local linha = C.criar("TextButton", {
                Parent = listaCasas, LayoutOrder = ordem, Text = "", AutoButtonColor = false,
                BackgroundColor3 = Tema.hover, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28),
            }, { C.canto(6) })
            local caixa = C.criar("Frame", {
                Parent = linha, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 8, 0.5, 0),
                Size = UDim2.new(0, 16, 0, 16), BackgroundColor3 = Tema.painel2,
            }, { C.canto(5) })
            local bordaCaixa = C.borda(Tema.apagado)
            bordaCaixa.Parent = caixa
            local check = C.texto({
                Parent = caixa, Text = "✓", Size = UDim2.new(1, 0, 1, 0), Font = Tema.fonteForte,
                TextSize = 12, TextColor3 = Tema.fundo, TextXAlignment = Enum.TextXAlignment.Center,
            })
            local nome = C.texto({
                Parent = linha, Position = UDim2.new(0, 34, 0, 0), Size = UDim2.new(1, -42, 1, 0),
                Text = casa.tipo .. "  ·  " .. casa.nome, TextSize = 11, TextTruncate = Enum.TextTruncate.AtEnd,
            })

            local function desenhar()
                local marcada = E.casasSelecionadas[casa.nome] == true
                C.tween(caixa, { BackgroundColor3 = marcada and Tema.verde or Tema.painel2 }, 0.1)
                bordaCaixa.Color = marcada and Tema.verde or Tema.apagado
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

        local linha1 = C.linha(pgEntrega, 7, 36)
        C.botao({
            Parent = linha1, Texto = "🔍  Escanear", Size = UDim2.new(0.5, -4, 1, 0),
            OnClick = function() Scanner.escanear() end,
        })
        local buscando = false
        local botaoAtivar = C.botao({
            Parent = linha1, Texto = "▶  Ativar", Variante = "sucesso",
            Position = UDim2.new(0.5, 4, 0, 0), Size = UDim2.new(0.5, -4, 1, 0),
        })
        botaoAtivar.MouseButton1Click:Connect(function()
            if buscando then return end
            if Trade.estado() ~= "inativo" then return Trade.desativar() end
            if Utils.limpar(caixaNick.Text) == "" then
                return Utils.setStatus("Digite o @username do comprador", "aviso")
            end
            if contarSelecionadas() == 0 then
                return Utils.setStatus("Selecione pelo menos 1 casa", "aviso")
            end
            buscando = true
            botaoAtivar.Text = "Buscando..."
            Trade.ativar(caixaNick.Text, function()
                buscando = false
                Utils.EstadoMudou:Fire()
            end)
        end)

        local linha2 = C.linha(pgEntrega, 8, 32)
        local botaoPausa = C.botao({
            Parent = linha2, Texto = "⏸  Pausar", Size = UDim2.new(0.5, -4, 1, 0), TextSize = 11,
            OnClick = function() Trade.alternarPausa() end,
        })
        C.botao({
            Parent = linha2, Texto = "🔄  Resetar", Position = UDim2.new(0.5, 4, 0, 0),
            Size = UDim2.new(0.5, -4, 1, 0), TextSize = 11,
            OnClick = function()
                Trade.resetar()
                caixaNick.Text = ""
            end,
        })

        local CORES_RESULTADO = {
            finalizado = Tema.verde, recusado = Tema.vermelho, cancelado = Tema.amarelo,
        }

        local resumo = C.criar("Frame", {
            Parent = pgHistorico, LayoutOrder = 1, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 52),
        }, {
            C.criar("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }),
        })
        local numeros = {}
        for i, info in ipairs({ { "finalizado", "Finalizados" }, { "recusado", "Recusados" }, { "cancelado", "Cancelados" } }) do
            local card = C.criar("Frame", {
                Parent = resumo, LayoutOrder = i, BackgroundColor3 = Tema.painel,
                Size = UDim2.new(1 / 3, -6, 1, 0),
            }, { C.canto(8), C.borda() })
            numeros[info[1]] = C.texto({
                Parent = card, Text = "0", Position = UDim2.new(0, 10, 0, 6), Size = UDim2.new(1, -20, 0, 22),
                Font = Tema.fonteForte, TextSize = 18, TextColor3 = CORES_RESULTADO[info[1]],
            })
            C.texto({
                Parent = card, Text = info[2], Position = UDim2.new(0, 10, 0, 29), Size = UDim2.new(1, -20, 0, 14),
                TextSize = 10, TextColor3 = Tema.suave,
            })
        end

        local linhaHist = C.linha(pgHistorico, 2, 30)
        C.botao({
            Parent = linhaHist, Texto = "📋  Copiar", Size = UDim2.new(0.5, -4, 1, 0), TextSize = 11,
            OnClick = function()
                local texto = Historico.texto()
                print("===== SAMHUB: HISTÓRICO =====\n" .. texto)
                Utils.setStatus(Utils.copiar(texto) and "Histórico copiado" or "Histórico no console (F9)", "info")
            end,
        })
        C.botao({
            Parent = linhaHist, Texto = "🗑  Limpar", Position = UDim2.new(0.5, 4, 0, 0),
            Size = UDim2.new(0.5, -4, 1, 0), TextSize = 11, OnClick = function() Historico.limpar() end,
        })

        local listaHist = C.criar("Frame", {
            Parent = pgHistorico, LayoutOrder = 3, BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        }, { C.lista(6) })
        local vazioHist = C.texto({
            Parent = pgHistorico, LayoutOrder = 4, Size = UDim2.new(1, 0, 0, 60), TextSize = 11,
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
                    Parent = listaHist, LayoutOrder = i, BackgroundColor3 = Tema.painel,
                    Size = UDim2.new(1, 0, 0, 44),
                }, { C.canto(8) })
                C.criar("Frame", {
                    Parent = card, BackgroundColor3 = cor, AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, 12, 0.5, 0), Size = UDim2.new(0, 8, 0, 8),
                }, { C.canto(4) })
                C.texto({
                    Parent = card, Text = "@" .. tostring(r.nick), Position = UDim2.new(0, 28, 0, 6),
                    Size = UDim2.new(1, -110, 0, 16), Font = Tema.fonteMedia, TextTruncate = Enum.TextTruncate.AtEnd,
                })
                C.texto({
                    Parent = card, Text = r.detalhe ~= "" and r.detalhe or "-", Position = UDim2.new(0, 28, 0, 23),
                    Size = UDim2.new(1, -110, 0, 14), TextSize = 10, TextColor3 = Tema.suave,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                })
                C.texto({
                    Parent = card, Text = string.upper(tostring(r.resultado)), AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, -12, 0, 6), Size = UDim2.new(0, 80, 0, 16), Font = Tema.fonteForte,
                    TextSize = 9, TextColor3 = cor, TextXAlignment = Enum.TextXAlignment.Right,
                })
                C.texto({
                    Parent = card, Text = tostring(r.hora), AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, -12, 0, 23), Size = UDim2.new(0, 80, 0, 14), TextSize = 10,
                    TextColor3 = Tema.apagado, TextXAlignment = Enum.TextXAlignment.Right,
                })
            end
            for chave, rotulo in pairs(numeros) do rotulo.Text = tostring(cont[chave] or 0) end
            vazioHist.Visible = #Historico.listar() == 0
        end
        maid:Add(Historico.Mudou:Connect(renderHistorico))

        C.titulo(pgAjustes, 1, "Trade")
        C.toggle({
            Parent = pgAjustes, LayoutOrder = 2, Texto = "Recusar outras pessoas",
            Descricao = "Desligado: só ignora trades de quem não é o comprador",
            Valor = S.RECUSAR_OUTROS,
            OnChange = function(v) S.RECUSAR_OUTROS = v; App.salvarAjustes() end,
        })
        C.stepper({
            Parent = pgAjustes, LayoutOrder = 3, Texto = "Oferta parada por", Valor = S.TEMPO_ESTAVEL,
            Min = 0, Max = 5, Passo = 0.5, Sufixo = "s",
            OnChange = function(v) S.TEMPO_ESTAVEL = v; App.salvarAjustes() end,
        })
        C.stepper({
            Parent = pgAjustes, LayoutOrder = 4, Texto = "Atraso mínimo", Valor = S.DELAY_MIN,
            Min = 0.2, Max = 5, Passo = 0.1, Sufixo = "s",
            OnChange = function(v) S.DELAY_MIN = v; App.salvarAjustes() end,
        })
        C.stepper({
            Parent = pgAjustes, LayoutOrder = 5, Texto = "Atraso máximo", Valor = S.DELAY_MAX,
            Min = 0.2, Max = 8, Passo = 0.1, Sufixo = "s",
            OnChange = function(v) S.DELAY_MAX = v; App.salvarAjustes() end,
        })

        C.titulo(pgAjustes, 6, "Ferramentas")
        C.botao({
            Parent = pgAjustes, LayoutOrder = 7, Texto = "🐞  Mapear UI do jogo", Size = UDim2.new(1, 0, 0, 34),
            OnClick = function() Mapeador.mapear() end,
        })
        C.texto({
            Parent = pgAjustes, LayoutOrder = 8, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            TextWrapped = true, TextSize = 10, TextColor3 = Tema.suave,
            Text = "Abra a janela de trade (ou a lista de casas) e clique acima. Os nomes aparecem no F9 "
                .. "e vão para a área de transferência. Depois preencha o config.lua.",
        })

        C.titulo(pgAjustes, 9, "Atalhos")
        C.texto({
            Parent = pgAjustes, LayoutOrder = 10, Size = UDim2.new(1, 0, 0, 16), TextSize = 11,
            TextColor3 = Tema.suave, Text = S.TECLA_MENU.Name .. " → esconder / mostrar o menu",
        })
        C.texto({
            Parent = pgAjustes, LayoutOrder = 11, Size = UDim2.new(1, 0, 0, 16), TextSize = 11,
            TextColor3 = Utils.temArquivos and Tema.verde or Tema.amarelo,
            Text = Utils.temArquivos and "● Ajustes e histórico salvos em arquivo"
                or "● Seu executor não salva arquivos (só nesta sessão)",
        })

        local function mostrarStatus(texto, tipo)
            local cor = Tema.status[tipo] or Tema.destaque
            textoStatus.Text = (Tema.icones[tipo] or "") .. "  " .. texto
            C.tween(barraStatus, { BackgroundColor3 = cor })
        end
        maid:Add(Utils.StatusMudou:Connect(function(texto, tipo)
            mostrarStatus(texto, tipo)
            if tipo == "ok" or tipo == "erro" then C.toast(gui, texto, tipo) end
        end))

        local SELOS = {
            ativo = { "● ATIVO", Tema.verde },
            pausado = { "❚❚ PAUSADO", Tema.amarelo },
            inativo = { "INATIVO", Tema.apagado },
        }
        local function atualizarEstado()
            local estado = Trade.estado()
            textoSelo.Text = SELOS[estado][1]
            C.tween(selo, { BackgroundColor3 = SELOS[estado][2] })

            if not buscando then
                botaoAtivar.Text = estado == "inativo" and "▶  Ativar" or "■  Desativar"
                C.pintar(botaoAtivar, estado == "inativo" and Tema.verde or Tema.vermelho)
            end
            botaoPausa.Text = estado == "pausado" and "▶  Continuar" or "⏸  Pausar"
            caixaNick.TextEditable = estado == "inativo"
            caixaNick.TextColor3 = estado == "inativo" and Tema.texto or Tema.suave
            renderCasas()
        end
        maid:Add(Utils.EstadoMudou:Connect(atualizarEstado))

        local minimizado = false
        botaoMin.MouseButton1Click:Connect(function()
            minimizado = not minimizado
            botaoMin.Text = minimizado and "+" or "–"
            C.tween(janela, { Size = UDim2.new(0, Tema.largura, 0, minimizado and ALTURA_TOPO or Tema.altura) }, 0.25)
        end)

        maid:Add(UIS.InputBegan:Connect(function(input, processado)
            if not processado and input.KeyCode == S.TECLA_MENU then
                janela.Visible = not janela.Visible
            end
        end))

        irPara(1)
        mostrarStatus(E.status, E.statusTipo)
        atualizarEstado()
        renderHistorico()
        C.tween(janela, { Size = UDim2.new(0, Tema.largura, 0, Tema.altura) }, 0.35)

        UI.gui = gui
        return gui
    end

    return UI
end
