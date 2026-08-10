# 04 - Bíblia de Arenas

Cada arena deve ter identidade visual, trilha, mecânica e consequência narrativa.

## Arenas principais

### Terreiro da Luta
- Local: Ituberá, Baixo Sul da Bahia.
- Função: hub moral, treino, primeiro lar de Ruan.
- Visual: madeira, rio, mangue, luz quente, tatame azul/dourado, placas de respeito e disciplina.
- Modificadores: recuperação, foco e honra.

### Arena do Dique
- Local: Salvador, Bahia.
- Função: circuito oficial.
- Visual: ginásio grande, público, telões, placas oficiais, tatame azul/dourado.
- Modificadores: regra rígida, pressão de público, penalidade por erro.

### Ferro Velho da Lapa
- Função: arena dura, instável e suja.
- Visual: metal, sombra, faíscas, chão pesado.
- Modificadores: risco alto, controle difícil, moral testada.

### Manguezal Profundo
- Função: arena de raiz.
- Visual: lama, água, raízes, barcos, vegetação fechada.
- Modificadores: tração baixa, sweeps fortes, velocidade reduzida.

### Praia de Pratigi
- Função: hype e público.
- Visual: areia, sol, barracas, crowd regional.
- Modificadores: queda de velocidade, hype alto.

#### Variante — Festival Maré Alta (Rota Paralela)
- Status: evento noturno ficcional; não substitui a Praia de Pratigi canônica.
- Visual: palco de DJ ficcional, crowd dançando ao redor, cantos azul/dourado e linha d'água animada.
- Mecânica: aposta opcional apenas com moeda interna, heat visível, aviso e interdição segura.
- Consequência: Cria Live, hype, sombra e atenção de autoridade; não existe gameplay de fuga.

### Zambiapunga
- Função: cultura, ritmo e pressão coletiva.
- Modificadores: moral e foco oscilam com o público.

### Cachoeira Pancada Grande
- Função: água, escorregamento e visual de impacto.
- Modificadores: tração instável.

### Colônia Nishimura
- Função: disciplina e foco.
- Visual: templo, silêncio, água, madeira e símbolo ancestral.

### Budokan das Águas
- Função: precisão e erro caro.
- Visual: azul profundo, silêncio, tatame limpo e geometria rígida.

## Regra de implementação

Toda arena precisa de:

- `id`
- `name`
- `region`
- `visual_identity`
- `music_theme`
- `modifiers`
- `narrative_tags`
- `asset_requirements`
