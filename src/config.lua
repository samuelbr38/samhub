local Config = {}

Config.VERSAO = "5.0"
Config.PLACE_ADOPT_ME = 920587237

Config.SAMHUB = {
    NOME_JANELA_TRADE    = "TradeApp",
    NOME_PARCEIRO        = "PartnerLabel",
    NOME_OFERTA_PARCEIRO = nil,

    TEXTO_ACEITAR   = { "Accept", "Aceitar" },
    NOMES_ACEITAR   = { "accept" },
    TEXTO_CONFIRMAR = { "Confirm", "Confirmar" },
    NOMES_CONFIRMAR = { "confirm" },
    TEXTO_RECUSAR   = { "Decline", "Recusar", "Cancel", "Cancelar" },
    NOMES_RECUSAR   = { "decline", "cancel" },

    PALAVRAS_CAIXA_CORREIO = { "mail", "correio", "trade house", "list for trade" },
    TEXTO_LISTAR_CASA      = { "List for Trade", "List For Trade", "Trade House", "Listar para troca", "Trocar casa" },

    PALAVRAS_PEDIDO = { "trade", "troca", "trocar", "negociar" },

    RECUSAR_OUTROS    = true,
    ACEITAR_PEDIDO    = true,
    VERIFICAR_CASA    = false,
    LISTAR_AO_ATIVAR  = true,
    TEMPO_ESTAVEL     = 1.5,
    DELAY_MIN         = 0.8,
    DELAY_MAX         = 2.5,

    TIMEOUT_CONFIRMAR = 10,

    CONTAINER_CASAS  = nil,
    TAMANHO_MAX_NOME = 35,

    TECLA_MENU        = Enum.KeyCode.RightShift,
    ARQUIVO_HISTORICO = "samhub_historico.json",
    ARQUIVO_AJUSTES   = "samhub_ajustes.json",
    MAX_HISTORICO     = 50,
}

Config.AJUSTES_SALVOS = {
    "RECUSAR_OUTROS", "ACEITAR_PEDIDO", "VERIFICAR_CASA", "LISTAR_AO_ATIVAR",
    "TEMPO_ESTAVEL", "DELAY_MIN", "DELAY_MAX",
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
    { "tiny home",    "🏠" }, { "mansion",   "🏰" }, { "castle",  "🏯" },
    { "apartment",    "🏢" }, { "iglu",      "❄️" }, { "igloo",   "❄️" },
    { "farm",         "🌾" }, { "wooden",    "🪵" }, { "queenslander", "🏡" },
    { "treehouse",    "🌳" }, { "moon",      "🌙" }, { "ice cream", "🍦" },
    { "toyshop",      "🧸" }, { "ranch",     "🐎" }, { "cottage", "🏡" },
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
