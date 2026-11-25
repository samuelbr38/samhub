local Tema = {
    fundo      = Color3.fromRGB(11, 9, 16),
    fundoBaixo = Color3.fromRGB(17, 11, 26),
    lateral    = Color3.fromRGB(14, 11, 20),
    painel     = Color3.fromRGB(19, 15, 27),
    painel2    = Color3.fromRGB(27, 21, 37),
    hover      = Color3.fromRGB(38, 29, 52),
    borda      = Color3.fromRGB(50, 38, 66),

    rosa       = Color3.fromRGB(255, 56, 152),
    rosaClaro  = Color3.fromRGB(255, 138, 198),
    rosaEscuro = Color3.fromRGB(150, 24, 92),
    lilas      = Color3.fromRGB(139, 92, 246),

    verde    = Color3.fromRGB(60, 230, 150),
    amarelo  = Color3.fromRGB(255, 196, 70),
    vermelho = Color3.fromRGB(255, 76, 96),

    texto    = Color3.fromRGB(240, 236, 248),
    suave    = Color3.fromRGB(160, 148, 178),
    apagado  = Color3.fromRGB(96, 86, 114),

    fonte      = Enum.Font.Gotham,
    fonteMedia = Enum.Font.GothamMedium,
    fonteForte = Enum.Font.GothamBold,
    fonteMono  = Enum.Font.RobotoMono,

    raio           = 8,
    largura        = 540,
    altura         = 330,
    larguraLateral = 48,
    alturaTopo     = 40,
}

Tema.destaque = Tema.rosa

Tema.status = {
    info   = Tema.rosaClaro,
    ok     = Tema.verde,
    aviso  = Tema.amarelo,
    erro   = Tema.vermelho,
    espera = Tema.rosa,
    debug  = Tema.apagado,
}

Tema.icones = {
    info = "[i]", ok = "[ok]", aviso = "[!]", erro = "[x]", espera = "[..]", debug = "[#]",
}

return Tema
