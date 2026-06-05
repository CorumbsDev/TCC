class_name TutorialTexts
## Textos do onboarding. Constantes = chaves em user:// (learning_prefs).

const KEY_PHASE_BINARY := "phase_binary_v1"
const KEY_PHASE_BACKPACK := "phase_backpack_v1"
const KEY_PHASE_CONVERSION := "phase_conversion_v1"
const KEY_GLOSSARY := "glossary_v1"
const KEY_RAW_KNAPSACK := "raw_knapsack_phase_intro"


static func title_for(key: String) -> String:
	match key:
		KEY_PHASE_BINARY:
			return "Fase 1 — Binário"
		KEY_PHASE_BACKPACK:
			return "Fase 2 — Mochila (bytes)"
		KEY_PHASE_CONVERSION:
			return "Fase 3 — Decimal → binário"
		KEY_GLOSSARY:
			return "Glossário rápido"
		KEY_RAW_KNAPSACK:
			return "Mochila + Tipagem (RAW)"
		_:
			return "Ajuda"


static func body_for(key: String) -> String:
	match key:
		KEY_PHASE_BINARY:
			return (
				"[b]Objetivo:[/b] complete o número binário arrastando um bit (0 ou 1) para o espaço central.\n\n"
				+ "[b]Bit:[/b] dígito em base 2 (0 ou 1).\n\n"
				+ "[b]Como jogar:[/b] use a ação [b]select_item[/b] (mouse) para pegar um orb, arraste e solte no slot vazio. "
				+ "Ao soltar, o jogo mostra o valor em decimal e uma linha explicando a conversão posição a posição.\n\n"
				+ "Você pode trocar o bit e ver o resultado de novo."
			)
		KEY_PHASE_BACKPACK:
			return (
				"[b]Objetivo:[/b] encher a [b]mochila do desafio[/b] até o limite de [b]bytes[/b].\n\n"
				+ "[b]Byte (neste OA):[/b] “peso” do item. Nesta fase, usamos apenas [b]INT (1 byte cada)[/b].\n\n"
				+ "[b]Pool:[/b] área à direita com itens para arrastar para a mochila.\n\n"
				+ "[b]Como jogar:[/b] clique em um INT do pool e arraste para um slot vazio da mochila do desafio.\n\n"
				+ "[b]Cheio:[/b] quando a soma dos bytes na mochila atinge o máximo. "
				+ "Ao concluir, um texto explica como a soma fecha."
			)
		KEY_PHASE_CONVERSION:
			return (
				"[b]Objetivo:[/b] representar o decimal indicado em [b]3 bits[/b] (esquerda = bit mais significativo).\n\n"
				+ "[b]Como jogar:[/b] arraste 0 ou 1 do pool para os três slots. "
				+ "Quando estiverem preenchidos, o jogo confere o valor e mostra a soma 2²+2¹+2⁰."
			)
		KEY_GLOSSARY:
			return "Abra o glossário pelo menu principal para ver definições dos termos usados no projeto."
		KEY_RAW_KNAPSACK:
			return (
				"[b]Objetivo:[/b] encher a mochila até o limite de bytes, mas os valores chegam [b]sem tipo (RAW)[/b].\n\n"
				+ "[b]1)[/b] Pegue um valor do pool (cinza, sem tipo).\n"
				+ "[b]2)[/b] Solte numa [b]estação de tipagem[/b] (Int, Float, etc.). Se o valor não couber no tipo, a conversão falha.\n"
				+ "[b]3)[/b] Arraste o orbe tipado para a mochila. Cada tipo ocupa bytes diferentes.\n\n"
				+ "RAW não pode ir direto para a mochila — é o desafio extra desta fase."
			)
		_:
			return ""
