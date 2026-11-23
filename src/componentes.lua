return function(App)
    local Tema = App.Tema
    local TweenService = game:GetService("TweenService")

    local C = {}

    function C.criar(classe, props, filhos)
        local obj = Instance.new(classe)
        for k, v in pairs(props or {}) do
            if k ~= "Parent" then obj[k] = v end
        end
        for _, filho in ipairs(filhos or {}) do
            filho.Parent = obj
        end
        if props and props.Parent then obj.Parent = props.Parent end
        return obj
    end

    function C.tween(obj, props, tempo)
        local tw = TweenService:Create(obj, TweenInfo.new(tempo or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
        tw:Play()
        return tw
    end

    function C.canto(raio)
        return C.criar("UICorner", { CornerRadius = UDim.new(0, raio or Tema.raio) })
    end

    function C.borda(cor, espessura)
        return C.criar("UIStroke", {
            Color = cor or Tema.borda,
            Thickness = espessura or 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        })
    end

    function C.padding(cima, direita, baixo, esquerda)
        return C.criar("UIPadding", {
            PaddingTop = UDim.new(0, cima or 0),
            PaddingRight = UDim.new(0, direita or cima or 0),
            PaddingBottom = UDim.new(0, baixo or cima or 0),
            PaddingLeft = UDim.new(0, esquerda or direita or cima or 0),
        })
    end

    function C.lista(espaco)
        return C.criar("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, espaco or 8),
        })
    end

    function C.texto(props)
        local base = {
            BackgroundTransparency = 1,
            Font = Tema.fonte,
            TextSize = 12,
            TextColor3 = Tema.texto,
            TextXAlignment = Enum.TextXAlignment.Left,
        }
        for k, v in pairs(props) do base[k] = v end
        return C.criar("TextLabel", base)
    end

    function C.linha(pai, ordem, altura)
        return C.criar("Frame", {
            Parent = pai, LayoutOrder = ordem, BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, altura),
        })
    end

    function C.titulo(pai, ordem, texto)
        return C.texto({
            Parent = pai, LayoutOrder = ordem, Text = string.upper(texto),
            Size = UDim2.new(1, 0, 0, 14), Font = Tema.fonteForte, TextSize = 10, TextColor3 = Tema.suave,
        })
    end

    function C.gradiente(rotacao)
        return C.criar("UIGradient", {
            Color = ColorSequence.new(Tema.rosa, Tema.lilas), Rotation = rotacao or 45,
        })
    end

    function C.card(p)
        local filhos = { C.canto(Tema.raio), C.borda(), C.padding(14, 14, 14, 14) }
        if p.Lista ~= false then table.insert(filhos, C.lista(p.Espaco or 8)) end
        return C.criar("Frame", {
            Parent = p.Parent, BackgroundColor3 = Tema.painel, Size = p.Size or UDim2.new(1, 0, 1, 0),
            Position = p.Position or UDim2.new(), LayoutOrder = p.LayoutOrder or 0,
        }, filhos)
    end

    function C.cabecalho(pai, ordem, icone, texto)
        local linha = C.linha(pai, ordem, 22)
        C.texto({
            Parent = linha, Text = icone .. "  " .. texto, Size = UDim2.new(1, 0, 1, -4),
            Font = Tema.fonteForte, TextSize = 13,
        })
        C.criar("Frame", {
            Parent = linha, BackgroundColor3 = Tema.rosa, BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 1, -2), Size = UDim2.new(0, 28, 0, 2),
        }, { C.canto(1) })
        return linha
    end

    function C.info(pai, ordem, rotulo)
        local linha = C.linha(pai, ordem, 22)
        local bolinha = C.criar("Frame", {
            Parent = linha, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.new(0, 8, 0, 8), BackgroundColor3 = Tema.apagado,
        }, { C.canto(4) })
        C.texto({
            Parent = linha, Text = rotulo, Position = UDim2.new(0, 16, 0, 0), Size = UDim2.new(0.5, -16, 1, 0),
            TextSize = 11, TextColor3 = Tema.suave,
        })
        local valor = C.texto({
            Parent = linha, Text = "-", Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(0.5, 0, 1, 0),
            TextSize = 11, Font = Tema.fonteMedia, TextXAlignment = Enum.TextXAlignment.Right,
            TextTruncate = Enum.TextTruncate.AtEnd,
        })
        return function(texto, ok)
            valor.Text = tostring(texto)
            local cor = (ok == true and Tema.verde) or (ok == false and Tema.vermelho) or Tema.apagado
            bolinha.BackgroundColor3 = cor
        end
    end

    local function clarear(cor) return cor:Lerp(Color3.new(1, 1, 1), 0.12) end
    local function escurecer(cor) return cor:Lerp(Color3.new(0, 0, 0), 0.18) end

    local CORES_VARIANTE = {
        primario = Tema.rosa,
        secundario = Tema.painel2,
        sucesso = Tema.verde,
        perigo = Tema.vermelho,
    }

    function C.girar(gradiente, segundos)
        local tw = TweenService:Create(gradiente,
            TweenInfo.new(segundos or 6, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
            { Rotation = gradiente.Rotation + 360 })
        tw:Play()
        return tw
    end

    function C.botao(p)
        local variante = p.Variante or "secundario"
        local cor = CORES_VARIANTE[variante]
        local botao = C.criar("TextButton", {
            Parent = p.Parent, Text = p.Texto, Size = p.Size, Position = p.Position or UDim2.new(),
            LayoutOrder = p.LayoutOrder or 0, BackgroundColor3 = cor, AutoButtonColor = false,
            Font = Tema.fonteForte, TextSize = p.TextSize or 12, TextColor3 = Tema.texto,
        }, { C.canto(8) })

        if variante == "secundario" then C.borda().Parent = botao end
        botao:SetAttribute("CorBase", cor)

        local function base() return botao:GetAttribute("CorBase") end
        botao.MouseEnter:Connect(function() C.tween(botao, { BackgroundColor3 = clarear(base()) }) end)
        botao.MouseLeave:Connect(function() C.tween(botao, { BackgroundColor3 = base() }) end)
        botao.MouseButton1Down:Connect(function() C.tween(botao, { BackgroundColor3 = escurecer(base()) }, 0.06) end)
        botao.MouseButton1Up:Connect(function() C.tween(botao, { BackgroundColor3 = clarear(base()) }, 0.06) end)
        if p.OnClick then botao.MouseButton1Click:Connect(p.OnClick) end

        return botao
    end

    function C.pintar(botao, cor)
        botao:SetAttribute("CorBase", cor)
        C.tween(botao, { BackgroundColor3 = cor })
    end

    function C.sombra(pai, tamanho, posicao, ancora, raio)
        return C.criar("Frame", {
            Parent = pai, BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.82,
            AnchorPoint = ancora or Vector2.new(0.5, 0.5), Position = posicao,
            Size = tamanho + UDim2.new(0, 10, 0, 10), ZIndex = 0,
        }, { C.canto((raio or 14) + 5) })
    end

    function C.icone(p)
        local botao = C.criar("TextButton", {
            Parent = p.Parent, Text = p.Texto, AnchorPoint = p.AnchorPoint or Vector2.zero,
            Position = p.Position, Size = UDim2.new(0, 28, 0, 28), BackgroundColor3 = Tema.hover,
            BackgroundTransparency = 1, AutoButtonColor = false, Font = Tema.fonteForte,
            TextSize = 14, TextColor3 = Tema.suave,
        }, { C.canto(7) })
        local corHover = p.CorHover or Tema.texto
        botao.MouseEnter:Connect(function() C.tween(botao, { BackgroundTransparency = 0, TextColor3 = corHover }) end)
        botao.MouseLeave:Connect(function() C.tween(botao, { BackgroundTransparency = 1, TextColor3 = Tema.suave }) end)
        if p.OnClick then botao.MouseButton1Click:Connect(p.OnClick) end
        return botao
    end

    function C.input(p)
        local caixa = C.criar("TextBox", {
            Parent = p.Parent, Size = p.Size, Position = p.Position or UDim2.new(),
            LayoutOrder = p.LayoutOrder or 0, BackgroundColor3 = Tema.painel2, Text = "",
            PlaceholderText = p.Placeholder or "", Font = Tema.fonte, TextSize = 12,
            TextColor3 = Tema.texto, PlaceholderColor3 = Tema.apagado,
            TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
        }, { C.canto(7), C.padding(0, 10, 0, p.Icone and 30 or 10) })

        local borda = C.borda()
        borda.Parent = caixa

        if p.Icone then
            C.texto({
                Parent = caixa, Text = p.Icone, Size = UDim2.new(0, 20, 1, 0),
                Position = UDim2.new(0, -22, 0, 0), TextXAlignment = Enum.TextXAlignment.Center,
                TextColor3 = Tema.apagado,
            })
        end

        caixa.Focused:Connect(function() C.tween(borda, { Color = Tema.destaque }) end)
        caixa.FocusLost:Connect(function() C.tween(borda, { Color = Tema.borda }) end)
        return caixa
    end

    function C.toggle(p)
        local linha = C.linha(p.Parent, p.LayoutOrder, p.Descricao and 40 or 28)
        C.texto({
            Parent = linha, Text = p.Texto, Size = UDim2.new(1, -56, 0, 18), Font = Tema.fonteMedia,
        })
        if p.Descricao then
            C.texto({
                Parent = linha, Text = p.Descricao, Position = UDim2.new(0, 0, 0, 18),
                Size = UDim2.new(1, -56, 0, 18), TextSize = 10, TextColor3 = Tema.suave, TextWrapped = true,
            })
        end

        local trilho = C.criar("TextButton", {
            Parent = linha, Text = "", AutoButtonColor = false, AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0, 40, 0, 22), BackgroundColor3 = Tema.painel2,
        }, { C.canto(11), C.borda() })
        local bolinha = C.criar("Frame", {
            Parent = trilho, AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0, 16, 0, 16),
            BackgroundColor3 = Tema.texto,
        }, { C.canto(8) })

        local valor = p.Valor == true
        local function desenhar(animar)
            local corTrilho = valor and Tema.rosa or Tema.painel2
            local posicao = valor and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
            if animar then
                C.tween(trilho, { BackgroundColor3 = corTrilho })
                C.tween(bolinha, { Position = posicao })
            else
                trilho.BackgroundColor3 = corTrilho
                bolinha.Position = posicao
            end
        end
        desenhar(false)

        trilho.MouseButton1Click:Connect(function()
            valor = not valor
            desenhar(true)
            if p.OnChange then p.OnChange(valor) end
        end)
        return linha
    end

    function C.stepper(p)
        local linha = C.linha(p.Parent, p.LayoutOrder, 28)
        C.texto({ Parent = linha, Text = p.Texto, Size = UDim2.new(1, -116, 1, 0), Font = Tema.fonteMedia })

        local caixa = C.criar("Frame", {
            Parent = linha, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.new(0, 108, 0, 26), BackgroundColor3 = Tema.painel2,
        }, { C.canto(7), C.borda() })

        local rotulo = C.texto({
            Parent = caixa, Size = UDim2.new(1, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Center,
            Font = Tema.fonteForte,
        })

        local valor = p.Valor
        local function mostrar()
            rotulo.Text = string.format("%.1f%s", valor, p.Sufixo or "")
        end
        local function mudar(delta)
            local novo = math.floor((valor + delta) / p.Passo + 0.5) * p.Passo
            valor = math.clamp(novo, p.Min, p.Max)
            mostrar()
            if p.OnChange then p.OnChange(valor) end
        end
        mostrar()

        for _, info in ipairs({ { "−", -p.Passo, UDim2.new(0, 0, 0, 0) }, { "+", p.Passo, UDim2.new(1, -26, 0, 0) } }) do
            local b = C.criar("TextButton", {
                Parent = caixa, Text = info[1], Position = info[3], Size = UDim2.new(0, 26, 1, 0),
                BackgroundTransparency = 1, Font = Tema.fonteForte, TextSize = 14, TextColor3 = Tema.suave,
            })
            b.MouseEnter:Connect(function() C.tween(b, { TextColor3 = Tema.texto }) end)
            b.MouseLeave:Connect(function() C.tween(b, { TextColor3 = Tema.suave }) end)
            b.MouseButton1Click:Connect(function() mudar(info[2]) end)
        end
        return linha
    end

    local contadorToast = 0

    function C.toast(gui, texto, tipo)
        local cor = Tema.status[tipo] or Tema.destaque
        local area = gui:FindFirstChild("Toasts")
        if not area then
            area = C.criar("Frame", {
                Name = "Toasts", Parent = gui, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1),
                Position = UDim2.new(1, -16, 1, -16), Size = UDim2.new(0, 280, 1, -32),
            }, {
                C.criar("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8),
                    VerticalAlignment = Enum.VerticalAlignment.Bottom,
                }),
            })
        end

        contadorToast += 1
        local card = C.criar("Frame", {
            Parent = area, LayoutOrder = contadorToast, BackgroundColor3 = Tema.painel,
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        }, { C.canto(10), C.borda(), C.padding(10, 12, 10, 18) })

        local faixa = C.criar("Frame", {
            Parent = card, BackgroundColor3 = cor, Position = UDim2.new(0, -10, 0, 0),
            Size = UDim2.new(0, 3, 1, 0),
        }, { C.canto(2) })

        local rotulo = C.texto({
            Parent = card, Text = (Tema.icones[tipo] or "") .. "  " .. texto, TextWrapped = true,
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Font = Tema.fonteMedia,
        })

        task.delay(4, function()
            if not card.Parent then return end
            C.tween(card, { BackgroundTransparency = 1 }, 0.3)
            C.tween(rotulo, { TextTransparency = 1 }, 0.3)
            C.tween(faixa, { BackgroundTransparency = 1 }, 0.3)
            task.wait(0.3)
            card:Destroy()
        end)
    end

    return C
end
