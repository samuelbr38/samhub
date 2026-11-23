local Tema = {
    fundo    = Color3.fromRGB(15, 11, 17),
    lateral  = Color3.fromRGB(21, 15, 24),
    painel   = Color3.fromRGB(26, 19, 30),
    painel2  = Color3.fromRGB(36, 26, 41),
    hover    = Color3.fromRGB(48, 34, 55),
    borda    = Color3.fromRGB(60, 42, 66),

    rosa       = Color3.fromRGB(236, 98, 162),
    rosaClaro  = Color3.fromRGB(244, 170, 206),
    rosaEscuro = Color3.fromRGB(176, 66, 124),
    lilas      = Color3.fromRGB(176, 130, 236),

    verde    = Color3.fromRGB(72, 214, 142),
    amarelo  = Color3.fromRGB(255, 198, 80),
    vermelho = Color3.fromRGB(255, 88, 104),

    texto    = Color3.fromRGB(250, 238, 247),
    suave    = Color3.fromRGB(184, 156, 180),
    apagado  = Color3.fromRGB(112, 90, 112),

    rosaFundo  = Color3.fromRGB(46, 22, 42),
    fundoFim   = Color3.fromRGB(24, 12, 27),

    fonte      = Enum.Font.Gotham,
    fonteMedia = Enum.Font.GothamMedium,
    fonteForte = Enum.Font.GothamBold,
    fonteFofa  = Enum.Font.FredokaOne,

    raio          = 12,
    largura       = 700,
    altura        = 430,
    larguraLateral = 176,
    alturaTopo    = 56,
}

Tema.destaque = Tema.rosa

Tema.status = {
    info   = Tema.rosaClaro,
    ok     = Tema.verde,
    aviso  = Tema.amarelo,
    erro   = Tema.vermelho,
    espera = Tema.rosa,
}

Tema.icones = {
    info = "💗", ok = "✅", aviso = "⚠️", erro = "❌", espera = "⏳",
}

return Tema
