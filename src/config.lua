local Config = {}

Config.VERSAO = "6.3"
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
    TEXTO_LISTAR_CASA      = { "List for Trade", "Trade House", "Listar para troca" },
    TEXTO_DESLISTAR        = { "Unlist from Trade", "Unlist", "Remove from Trade", "Remover da troca" },
    TEXTO_TROCAR_CASA      = { "Change House", "Trocar de casa", "Mudar de casa" },
    TEXTO_MENU_CAIXA_EXTRA = { "Throw Party", "Lock Door", "Unlock Door", "Change House" },
    CONFIRMAR_LISTAGEM     = { "Yes", "Confirm", "OK", "Okay", "Sim", "Confirmar" },
    TEXTO_MUDAR_PARA_CASA  = { "Go!", "Go", "Move In", "Move Here" },
    PALAVRAS_A_VENDA       = { "unlist", "for trade", "listed", "à venda" },
    PADROES_PLACA_CASA     = { "%s's house", "casa de %s" },
    TECLA_INTERAGIR        = Enum.KeyCode.E,
    TECLA_TROCAR_CASA      = Enum.KeyCode.One,
    DISTANCIA_CAIXA_CORREIO = 60,
    DISTANCIA_PERTO         = 6,
    ESPERA_CAIXA_CORREIO    = 25,
    ESPERA_SAIR_CASA        = 90,
    LER_TIPO_CASA           = true,
    TEMPO_MAX_ANDANDO       = 40,
    DISTANCIA_MAX_ANDAR     = 150,
    CAIXAS                  = {},
    CAIXA_OBJETO            = nil,
    MAX_CANDIDATOS_CAIXA    = 3,

    PALAVRAS_PEDIDO = { "trade request", "sent you a trade", "trade", "troca", "trocar", "negociar" },

    RECUSAR_OUTROS    = true,
    ACEITAR_PEDIDO    = true,
    VERIFICAR_CASA    = false,
    LISTAR_AO_ATIVAR  = true,
    ANDAR_ATE_CAIXA   = true,
    CONFERIR_VENDA    = true,
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
    "ANDAR_ATE_CAIXA", "CONFERIR_VENDA", "CAIXAS", "CAIXA_OBJETO",
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

Config.NUNCA_CLICAR = {
    "build", "buy", "comprar", "construir", "robux", "purchase",
    "sell", "vender", "unlist", "paint", "delete", "apagar", "rename",
}

Config.PALAVRAS_PERIGO = { "sell", "vender", "venda por", "delete", "apagar", "robux", "purchase", "buy", "comprar" }

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
    { "toyshop",      "🧸" }, { "ranch",     "🐎" }, { "cottage", "🏡" }, { "gingerbread", "🍪" },
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
