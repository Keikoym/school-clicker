extends RefCounted

# Preços derivados do nível: a mesma regra vale para compras e saves antigos.
const INICIAIS := {"clique": 20, "gerador": 60, "multiplicador": 160, "passivo": 240}
const CRESCIMENTO := {"clique": 1.45, "gerador": 1.40, "multiplicador": 1.55, "passivo": 1.50}
const PROVA_1 := 400
const PROVA_2 := 1600

static func preco(tipo: String, nivel: int) -> int:
	# O teto evita overflow em saves com níveis extremos.
	var valor: float = float(INICIAIS[tipo]) * pow(float(CRESCIMENTO[tipo]), clampi(nivel, 0, 100))
	return int(minf(ceil(valor / 5.0) * 5.0, 1000000000000.0))

static func nivel_multiplicador(valor: float) -> int:
	return 0 if valor < 1.2 else 1 + maxi(0, roundi((valor - 1.2) / 0.1))

static func nivel_passivo(valor: float) -> int:
	return 0 if valor < 0.15 else 1 + maxi(0, roundi((valor - 0.15) / 0.05))
