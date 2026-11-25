return function(App)
    local Tema = App.Tema
    local TweenService = game:GetService("TweenService")
    local UIS = game:GetService("UserInputService")
    local function soToque() return UIS.TouchEnabled and not UIS.MouseEnabled end

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

    function C.borda(cor, espessura, transparencia)
        return C.criar("UIStroke", {
            Color = cor or Tema.borda,
            Thickness = espessura or 1,
            Transparency = transparencia or 0,
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
            Padding = UDim.new(0, espaco or 6),
        })
    end

    function C.texto(props)
        local base = {
            BackgroundTransparency = 1,
            Font = Tema.fonte,
            TextSize = 11,
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

    function C.gradiente(rotacao)
        return C.criar("UIGradient", {
            Color = ColorSequence.new(Tema.rosa, Tema.lilas), Rotation = rotacao or 45,
        })
    end

    function C.degrade(cor1, cor2, rotacao)
        return C.criar("UIGradient", { Color = ColorSequence.new(cor1, cor2), Rotation = rotacao or 90 })
    end

    function C.bordaNeon(transparencia, espessura)
        local borda = C.criar("UIStroke", {
            Color = Color3.new(1, 1, 1), Thickness = espessura or 1, Transparency = transparencia or 0.35,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        })
        C.gradiente(45).Parent = borda
        return borda
    end

    function C.card(p)
        local filhos = {
            C.canto(Tema.raio), C.borda(Tema.borda, 1, 0.25), C.padding(10, 10, 10, 10),
            C.degrade(Tema.painel, Tema.fundoBaixo, 90),
        }
        if p.Lista ~= false then table.insert(filhos, C.lista(p.Espaco or 6)) end
        return C.criar("Frame", {
            Parent = p.Parent, BackgroundColor3 = Color3.new(1, 1, 1), Size = p.Size or UDim2.new(1, 0, 1, 0),
            Position = p.Position or UDim2.new(), LayoutOrder = p.LayoutOrder or 0,
        }, filhos)
    end

    function C.cabecalho(pai, ordem, _, texto)
        local linha = C.linha(pai, ordem, 14)
        C.criar("Frame", {
            Parent = linha, BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(0, 3, 0, 11),
        }, { C.canto(2), C.gradiente(90) })
        C.texto({
            Parent = linha, Text = string.upper(texto), Position = UDim2.new(0, 8, 0, 0),
            Size = UDim2.new(1, -8, 1, 0), Font = Tema.fonteMono, TextSize = 10, TextColor3 = Tema.rosaClaro,
        })
        return linha
    end

    function C.info(pai, ordem, rotulo)
        local linha = C.linha(pai, ordem, 16)
        local bolinha = C.criar("Frame", {
            Parent = linha, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.new(0, 6, 0, 6), BackgroundColor3 = Tema.apagado,
        }, { C.canto(3) })
        C.texto({
            Parent = linha, Text = rotulo, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(0.45, -12, 1, 0),
            TextSize = 10, TextColor3 = Tema.suave, TextTruncate = Enum.TextTruncate.AtEnd,
        })
        local valor = C.texto({
            Parent = linha, Text = "-", Position = UDim2.new(0.45, 0, 0, 0), Size = UDim2.new(0.55, 0, 1, 0),
            TextSize = 10, Font = Tema.fonteMono, TextXAlignment = Enum.TextXAlignment.Right,
            TextTruncate = Enum.TextTruncate.AtEnd,
        })
        return function(texto, ok)
            valor.Text = tostring(texto)
            bolinha.BackgroundColor3 = (ok == true and Tema.verde) or (ok == false and Tema.vermelho) or Tema.apagado
        end
    end

    local function clarear(cor) return cor:Lerp(Color3.new(1, 1, 1), 0.1) end
    local function escurecer(cor) return cor:Lerp(Color3.new(0, 0, 0), 0.2) end

    local CORES_VARIANTE = {
        primario = Tema.rosa,
        secundario = Tema.painel2,
        sucesso = Tema.verde,
        perigo = Tema.vermelho,
    }

    local BRANCO = Color3.new(1, 1, 1)

    function C.botao(p)
        local variante = p.Variante or "secundario"
        local cor = CORES_VARIANTE[variante]
        local primario = variante == "primario"
        local botao = C.criar("TextButton", {
            Parent = p.Parent, Text = p.Texto, Size = p.Size, Position = p.Position or UDim2.new(),
            LayoutOrder = p.LayoutOrder or 0, BackgroundColor3 = cor, AutoButtonColor = false,
            Font = Tema.fonteForte, TextSize = p.TextSize or 11, TextColor3 = Tema.texto,
        }, { C.canto(6) })
        if variante == "secundario" then C.borda(Tema.borda, 1, 0.1).Parent = botao end

        local fundo = botao
        if primario then
            botao.BackgroundTransparency = 1
            botao.TextTransparency = 1
            fundo = C.criar("Frame", {
                Name = "Fundo", Parent = botao, Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = BRANCO,
                BorderSizePixel = 0,
            }, { C.canto(6) })
            local g = C.gradiente(20)
            g.Name = "Degrade"
            g.Parent = fundo
            local rotulo = C.criar("TextLabel", {
                Name = "Rotulo", Parent = botao, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
                Text = botao.Text, Font = botao.Font, TextSize = botao.TextSize, TextColor3 = botao.TextColor3,
                TextWrapped = true, TextTruncate = Enum.TextTruncate.AtEnd,
            })
            for _, prop in ipairs({ "Text", "Font", "TextSize", "TextColor3" }) do
                botao:GetPropertyChangedSignal(prop):Connect(function() rotulo[prop] = botao[prop] end)
            end
        end
        fundo:SetAttribute("CorBase", primario and BRANCO or cor)
        local escala = C.criar("UIScale", { Parent = botao })

        local function base() return fundo:GetAttribute("CorBase") end
        local vez = 0
        local function normal()
            vez += 1
            C.tween(fundo, { BackgroundColor3 = base() }, 0.08)
            C.tween(escala, { Scale = 1 }, 0.1)
        end
        botao.MouseEnter:Connect(function()
            if soToque() then return end
            C.tween(fundo, { BackgroundColor3 = clarear(base()) })
        end)
        botao.MouseLeave:Connect(normal)
        botao.MouseButton1Down:Connect(function()
            vez += 1
            local minha = vez
            C.tween(fundo, { BackgroundColor3 = escurecer(base()) }, 0.06)
            C.tween(escala, { Scale = 0.96 }, 0.06)
            task.delay(0.25, function()
                if vez == minha then normal() end
            end)
        end)
        botao.MouseButton1Up:Connect(normal)
        botao.MouseButton1Click:Connect(normal)
        botao:GetPropertyChangedSignal("Visible"):Connect(normal)
        botao.AncestryChanged:Connect(function() if botao.Parent then normal() end end)
        if p.OnClick then botao.MouseButton1Click:Connect(p.OnClick) end
        return botao
    end

    function C.pintar(botao, cor)
        local fundo = botao:FindFirstChild("Fundo") or botao
        local g = fundo:FindFirstChild("Degrade")
        if g then
            g.Enabled = cor == Tema.rosa
            if cor == Tema.rosa then cor = BRANCO end
        end
        fundo:SetAttribute("CorBase", cor)
        C.tween(fundo, { BackgroundColor3 = cor })
    end

    function C.sombra(pai, tamanho, posicao, ancora, raio)
        return C.criar("Frame", {
            Parent = pai, BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.75,
            AnchorPoint = ancora or Vector2.new(0.5, 0.5), Position = posicao,
            Size = tamanho + UDim2.new(0, 8, 0, 8), ZIndex = 0,
        }, { C.canto((raio or 8) + 4) })
    end

    function C.icone(p)
        local botao = C.criar("TextButton", {
            Parent = p.Parent, Text = p.Texto, AnchorPoint = p.AnchorPoint or Vector2.zero,
            Position = p.Position, Size = UDim2.new(0, 24, 0, 24), BackgroundColor3 = Tema.hover,
            BackgroundTransparency = 1, AutoButtonColor = false, Font = Tema.fonteForte,
            TextSize = 12, TextColor3 = Tema.suave,
        }, { C.canto(5) })
        local corHover = p.CorHover or Tema.texto
        local function normal() C.tween(botao, { BackgroundTransparency = 1, TextColor3 = Tema.suave }) end
        botao.MouseEnter:Connect(function()
            if soToque() then return end
            C.tween(botao, { BackgroundTransparency = 0, TextColor3 = corHover })
        end)
        botao.MouseLeave:Connect(normal)
        botao.MouseButton1Click:Connect(normal)
        if p.OnClick then botao.MouseButton1Click:Connect(p.OnClick) end
        return botao
    end

    function C.input(p)
        local caixa = C.criar("TextBox", {
            Parent = p.Parent, Size = p.Size, Position = p.Position or UDim2.new(),
            LayoutOrder = p.LayoutOrder or 0, BackgroundColor3 = Tema.painel2, Text = "",
            PlaceholderText = p.Placeholder or "", Font = Tema.fonteMono, TextSize = 11,
            TextColor3 = Tema.texto, PlaceholderColor3 = Tema.apagado,
            TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
        }, { C.canto(5), C.padding(0, 8, 0, p.Prefixo and 22 or 8) })
        local borda = C.borda()
        borda.Parent = caixa
        if p.Prefixo then
            C.texto({
                Parent = caixa, Text = p.Prefixo, Size = UDim2.new(0, 16, 1, 0), Position = UDim2.new(0, -16, 0, 0),
                Font = Tema.fonteMono, TextColor3 = Tema.rosa, TextXAlignment = Enum.TextXAlignment.Center,
            })
        end
        caixa.Focused:Connect(function() C.tween(borda, { Color = Tema.rosa, Thickness = 1.5 }) end)
        caixa.FocusLost:Connect(function() C.tween(borda, { Color = Tema.borda, Thickness = 1 }) end)
        return caixa
    end

    function C.inputSenha(p)
        local caixa = C.input(p)
        local dica = caixa.PlaceholderText
        caixa.PlaceholderText = ""
        caixa.TextTransparency = 1
        local mascara = C.texto({
            Parent = caixa, Size = UDim2.new(1, 0, 1, 0), Font = Tema.fonteMono, TextSize = 11,
            TextColor3 = Tema.apagado, Text = dica, ZIndex = caixa.ZIndex + 1,
        })
        local function desenhar()
            local n = utf8.len(caixa.Text) or #caixa.Text
            if n == 0 then
                mascara.Text, mascara.TextColor3 = dica, Tema.apagado
            else
                mascara.Text, mascara.TextColor3 = string.rep("•", math.min(n, 40)), Tema.texto
            end
        end
        caixa:GetPropertyChangedSignal("Text"):Connect(desenhar)
        desenhar()
        return caixa
    end

    function C.toggle(p)
        local linha = C.linha(p.Parent, p.LayoutOrder, p.Descricao and 28 or 18)
        C.texto({ Parent = linha, Text = p.Texto, Size = UDim2.new(1, -40, 0, 14), Font = Tema.fonteMedia })
        if p.Descricao then
            C.texto({
                Parent = linha, Text = p.Descricao, Position = UDim2.new(0, 0, 0, 14), Size = UDim2.new(1, -40, 0, 12),
                TextSize = 9, Font = Tema.fonteMono, TextColor3 = Tema.apagado, TextTruncate = Enum.TextTruncate.AtEnd,
            })
        end
        local trilho = C.criar("TextButton", {
            Parent = linha, Text = "", AutoButtonColor = false, AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0, 32, 0, 18), BackgroundColor3 = Tema.painel2,
        }, { C.canto(9), C.borda(Tema.borda, 1, 0.1) })
        local degrade = C.gradiente(0)
        degrade.Parent = trilho
        local bolinha = C.criar("Frame", {
            Parent = trilho, AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0, 12, 0, 12),
            BackgroundColor3 = Tema.texto,
        }, { C.canto(6) })

        local valor = p.Valor == true
        local function desenhar(animar)
            degrade.Enabled = valor
            local corTrilho = valor and Color3.new(1, 1, 1) or Tema.painel2
            local posicao = valor and UDim2.new(1, -15, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
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
        local linha = C.linha(p.Parent, p.LayoutOrder, 22)
        C.texto({ Parent = linha, Text = p.Texto, Size = UDim2.new(1, -90, 1, 0), Font = Tema.fonteMedia })
        local caixa = C.criar("Frame", {
            Parent = linha, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.new(0, 84, 0, 20), BackgroundColor3 = Tema.painel2,
        }, { C.canto(5), C.borda() })
        local rotulo = C.texto({
            Parent = caixa, Size = UDim2.new(1, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Center,
            Font = Tema.fonteMono, TextSize = 10,
        })
        local valor = p.Valor
        local function mostrar() rotulo.Text = string.format("%.1f%s", valor, p.Sufixo or "") end
        local function mudar(delta)
            local novo = math.floor((valor + delta) / p.Passo + 0.5) * p.Passo
            valor = math.clamp(novo, p.Min, p.Max)
            mostrar()
            if p.OnChange then p.OnChange(valor) end
        end
        mostrar()
        for _, info in ipairs({ { "-", -p.Passo, UDim2.new(0, 0, 0, 0) }, { "+", p.Passo, UDim2.new(1, -20, 0, 0) } }) do
            local b = C.criar("TextButton", {
                Parent = caixa, Text = info[1], Position = info[3], Size = UDim2.new(0, 20, 1, 0),
                BackgroundTransparency = 1, Font = Tema.fonteMono, TextSize = 12, TextColor3 = Tema.rosa,
            })
            b.MouseButton1Click:Connect(function() mudar(info[2]) end)
        end
        return linha
    end

    local contadorToast = 0

    function C.toast(gui, texto, tipo)
        local cor = Tema.status[tipo] or Tema.rosa
        local area = gui:FindFirstChild("Toasts")
        if not area then
            area = C.criar("Frame", {
                Name = "Toasts", Parent = gui, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), ZIndex = 60,
                Position = UDim2.new(0.5, 0, 0, 76), Size = UDim2.new(0, 260, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            }, {
                C.criar("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4),
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                }),
            })
        end
        contadorToast += 1
        local cards = {}
        for _, f in ipairs(area:GetChildren()) do
            if f:IsA("Frame") then table.insert(cards, f) end
        end
        table.sort(cards, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
        while #cards >= 4 do table.remove(cards, 1):Destroy() end

        local card = C.criar("Frame", {
            Parent = area, LayoutOrder = contadorToast, BackgroundColor3 = Tema.painel, BackgroundTransparency = 0.04,
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        }, { C.canto(8), C.borda(cor, 1, 0.45), C.padding(8, 10, 8, 14) })
        local faixa = C.criar("Frame", {
            Parent = card, BackgroundColor3 = cor, BorderSizePixel = 0, Position = UDim2.new(0, -14, 0, -8),
            Size = UDim2.new(0, 3, 1, 16),
        }, { C.canto(2) })
        local rotulo = C.texto({
            Parent = card, Text = (Tema.icones[tipo] or "") .. " " .. texto, TextWrapped = true, TextTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Font = Tema.fonteMono, TextSize = 10,
        })
        local escala = C.criar("UIScale", { Parent = card, Scale = 0.9 })
        C.tween(escala, { Scale = 1 }, 0.18)
        C.tween(rotulo, { TextTransparency = 0 }, 0.18)
        task.delay(4.5, function()
            if not card.Parent then return end
            C.tween(card, { BackgroundTransparency = 1 }, 0.3)
            C.tween(rotulo, { TextTransparency = 1 }, 0.3)
            C.tween(faixa, { BackgroundTransparency = 1 }, 0.3)
            C.tween(escala, { Scale = 0.92 }, 0.3)
            task.wait(0.3)
            if card.Parent then card:Destroy() end
        end)
    end

    return C
end
