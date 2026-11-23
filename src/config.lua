local Config = {}

Config.VERSAO = "4.0"

Config.SAMHUB = {
    NOME_JANELA_TRADE    = "TradeApp",
    NOME_PARCEIRO        = "PartnerLabel",
    NOME_OFERTA_PARCEIRO = nil,

    TEXTO_ACEITAR   = { "Accept", "Aceitar" },
    TEXTO_CONFIRMAR = { "Confirm", "Confirmar" },
    TEXTO_RECUSAR   = { "Decline", "Recusar", "Cancel", "Cancelar" },

    RECUSAR_OUTROS = true,
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

Config.AJUSTES_SALVOS = { "RECUSAR_OUTROS", "TEMPO_ESTAVEL", "DELAY_MIN", "DELAY_MAX" }

Config.PALAVRAS_CASA = { "house", "home", "casa", "mansion", "castle", "apartment", "iglu", "igloo", "farm", "cabin" }

Config.IGNORAR = {
    ["home"] = true, ["house"] = true, ["casa"] = true, ["houses"] = true, ["casas"] = true,
    ["my house"] = true, ["my home"] = true, ["go home"] = true,
    ["teleport home"] = true, ["home button"] = true,
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
