local Config = {}

Config.VERSAO = "4.1"

Config.SAMHUB = {
    NOME_JANELA_TRADE    = "TradeApp",
    NOME_PARCEIRO        = "PartnerLabel",
    NOME_OFERTA_PARCEIRO = nil,

    TEXTO_ACEITAR   = { "Accept", "Aceitar" },
    TEXTO_CONFIRMAR = { "Confirm", "Confirmar" },
    TEXTO_RECUSAR   = { "Decline", "Recusar", "Cancel", "Cancelar" },

    RECUSAR_OUTROS = true,
    ACEITAR_PEDIDO = true,
    VERIFICAR_CASA = false,
    TEMPO_ESTAVEL  = 1.5,
    DELAY_MIN      = 0.8,
    DELAY_MAX      = 2.5,

    TIMEOUT_CONFIRMAR = 10,

    CONTAINER_CASAS  = nil,
    TAMANHO_MAX_NOME = 35,

    TECLA_MENU        = Enum.KeyCode.RightShift,
    ARQUIVO_HISTORICO = "samhub_historico.json",
    ARQUIVO_AJUSTES   = "samhub_ajustes.json",
    MAX_HISTORICO     = 50,
}

Config.AJUSTES_SALVOS = {
    "RECUSAR_OUTROS", "ACEITAR_PEDIDO", "VERIFICAR_CASA", "TEMPO_ESTAVEL", "DELAY_MIN", "DELAY_MAX",
}

Config.PLACEHOLDERS = {
    ["somanycharacters"] = true, ["playername"] = true, ["username"] = true,
    ["name"] = true, ["label"] = true, ["text"] = true, ["player"] = true,
}

Config.TITULOS_LISTA_CASAS = {
    ["my homes"] = true, ["my houses"] = true, ["minhas casas"] = true, ["homes"] = true,
}

Config.PALAVRAS_CASA = { "house", "home", "casa", "mansion", "castle", "apartment", "iglu", "igloo", "farm", "cabin" }

Config.IGNORAR = {
    ["home"] = true, ["house"] = true, ["casa"] = true, ["houses"] = true, ["casas"] = true,
    ["my house"] = true, ["my home"] = true, ["go home"] = true,
    ["teleport home"] = true, ["home button"] = true,
    ["build house"] = true, ["my homes"] = true, ["my houses"] = true, ["minhas casas"] = true,
    ["build"] = true, ["visit"] = true, ["edit"] = true, ["select"] = true, ["equip"] = true,
    ["equipped"] = true, ["sell"] = true, ["trade"] = true, ["for trade"] = true, ["close"] = true,
}

Config.TIPOS = {
    { "tiny home", "🏠 Tiny Home" },
    { "mansion",   "🏰 Mansão" },
    { "castle",    "🏯 Castelo" },
    { "apartment", "🏢 Apartamento" },
    { "iglu",      "❄️ Iglu" },
    { "igloo",     "❄️ Iglu" },
    { "farm",      "🌾 Fazenda" },
    { "wooden",    "🪵 Madeira" },
    { "queenslander", "🏡 Queenslander" },
    { "treehouse", "🌳 Casa na Árvore" },
    { "moon",      "🌙 Lua" },
    { "ice cream", "🍦 Sorvete" },
    { "toyshop",   "🧸 Loja de Brinquedos" },
    { "ranch",     "🐎 Rancho" },
    { "cottage",   "🏡 Chalé" },
}

Config.Estado = {
    nickAlvo = "",
    userIdAlvo = nil,
    casasSelecionadas = {},
    pausado = false,
    status = "Pronto",
    statusTipo = "info",
    todasAsCasas = {},
}

return Config
