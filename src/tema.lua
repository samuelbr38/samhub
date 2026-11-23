local Tema = {
    fundo    = Color3.fromRGB(15, 15, 21),
    painel   = Color3.fromRGB(23, 23, 31),
    painel2  = Color3.fromRGB(31, 31, 42),
    hover    = Color3.fromRGB(40, 40, 54),
    borda    = Color3.fromRGB(48, 48, 64),

    destaque = Color3.fromRGB(110, 140, 255),
    verde    = Color3.fromRGB(52, 199, 120),
    amarelo  = Color3.fromRGB(245, 190, 60),
    vermelho = Color3.fromRGB(235, 87, 87),
    roxo     = Color3.fromRGB(165, 125, 255),

    texto    = Color3.fromRGB(236, 236, 245),
    suave    = Color3.fromRGB(150, 150, 170),
    apagado  = Color3.fromRGB(95, 95, 118),

    fonte      = Enum.Font.Gotham,
    fonteMedia = Enum.Font.GothamMedium,
    fonteForte = Enum.Font.GothamBold,

    raio    = 10,
    largura = 340,
    altura  = 520,
}

Tema.status = {
    info   = Tema.destaque,
    ok     = Tema.verde,
    aviso  = Tema.amarelo,
    erro   = Tema.vermelho,
    espera = Tema.roxo,
}

Tema.icones = {
    info = "ℹ️", ok = "✅", aviso = "⚠️", erro = "❌", espera = "⏳",
}

return Tema
