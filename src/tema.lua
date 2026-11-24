local Tema = {
    fundo    = Color3.fromRGB(9, 8, 13),
    lateral  = Color3.fromRGB(13, 11, 18),
    painel   = Color3.fromRGB(17, 14, 23),
    painel2  = Color3.fromRGB(24, 20, 32),
    hover    = Color3.fromRGB(33, 27, 44),
    borda    = Color3.fromRGB(44, 34, 56),

    rosa       = Color3.fromRGB(255, 56, 152),
    rosaClaro  = Color3.fromRGB(255, 138, 198),
    rosaEscuro = Color3.fromRGB(150, 24, 92),
    lilas      = Color3.fromRGB(139, 92, 246),

    verde    = Color3.fromRGB(60, 230, 150),
    amarelo  = Color3.fromRGB(255, 196, 70),
    vermelho = Color3.fromRGB(255, 76, 96),

    texto    = Color3.fromRGB(236, 232, 244),
    suave    = Color3.fromRGB(150, 140, 166),
    apagado  = Color3.fromRGB(88, 80, 104),

    fonte      = Enum.Font.Gotham,
    fonteMedia = Enum.Font.GothamMedium,
    fonteForte = Enum.Font.GothamBold,
    fonteMono  = Enum.Font.RobotoMono,

    raio           = 6,
    largura        = 520,
    altura         = 320,
    larguraLateral = 46,
    alturaTopo     = 38,
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
