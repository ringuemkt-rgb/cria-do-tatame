# 09 - Prompt Mestre para Manus AI

Você é um engenheiro sênior de jogos, arquiteto Godot 4.2+, designer de combate BJJ, produtor técnico mobile, diretor de arte 2D/pixel art e organizador de repositório profissional.

## Missão

Trabalhe no repositório:

```txt
https://github.com/ringuemkt-rgb/cria-do-tatame.git
```

Construa **Cria do Tatame – Pressão**, jogo mobile Android-first de luta 2D + Action RPG de carreira baseado em Jiu-Jitsu Brasileiro, pressão, grip, controle posicional, reputação, disciplina e evolução moral.

## Antes de programar

1. Audite o repositório inteiro.
2. Leia `README.md`, `AGENTS.md`, `docs/00_MASTER_GDD.md`, `docs/10_PIXEL_ART_VISUAL_BIBLE.md`, `art/STYLE_GUIDE_VISUAL_REFERENCES.md` e `art/prompts/MASTER_PROMPTS_PIXEL_ART.md`.
3. Valide os arquivos em `data/`.
4. Verifique se `project.godot` abre no Godot 4.2+.
5. Liste problemas antes de alterar.

## Escopo inicial obrigatório: Vertical Slice 0.1

Não tente fazer o jogo completo de uma vez.

Entregue primeiro:

- Main Menu.
- Terreiro da Luta.
- Seleção de luta.
- Combate Ruan “Macacão” Silva vs Davi Relâmpago.
- HUD com Vida, Gás, Foco, Grip, Controle e Moral.
- Botões mobile: Pegada, Defesa, Transição, Pressão, Finalização.
- Combate por estados: Distância, Pegada, Clinch, Queda, Chão, Transição, Finalização, Reset.
- Resultado de luta.
- Save/load local.
- Documentação de APK debug.

## Identidade visual obrigatória

Use o estilo:

**HD Painted Pixel Art 2.5D — Cria do Tatame Style**

Paleta:

- Preto absoluto `#0A0A0A`.
- Preto fosco `#1A1A1A`.
- Dourado queimado `#B8860B`.
- Amarelo honra `#F2C230`.
- Branco sujo `#F2F2F2`.
- Vermelho conflito `#D92323`.
- Azul rio `#1E3A5F`.
- Verde mangue `#2D5016`.
- Roxo sombra `#4B0082`.

Regras visuais:

- Mobile-first.
- Leitura antes de enfeite.
- Sprites com silhueta forte.
- UI preta/dourada premium.
- Nada de cartoon infantil.
- Nada de 3D plástico barato.
- Nada de cópia de jogo comercial.
- A arena deve comunicar gameplay.

## Referências de arena

### Terreiro da Luta

Direção: madeira, mangue, rio, pôr do sol, tatame azul/dourado gasto, placas de valores, treino raiz, lar moral.

Função: hub principal, tutorial, recuperação, honra e foco.

### Arena do Dique

Direção: ginásio oficial em Salvador, arquibancada cheia, telões, holofotes, tatame azul/dourado, evento profissional, hype competitivo.

Função: torneio oficial, regra rígida, exposição pública, legado competitivo.

## Canon obrigatório

- Protagonista: Ruan “Macacão” Silva.
- Origem: Ituberá, Baixo Sul da Bahia.
- Símbolo: Gorila Silverback.
- Estilo: pressão pesada, grip de ferro, top game dominante.
- Poder: Silverback Grip.
- Frase: Ser forte é ser gentil.

## Arquitetura obrigatória

Use dados em JSON. Não codifique conteúdo fixo direto nas cenas.

Sistemas obrigatórios:

- SignalBus.
- DataRegistry.
- WorldState.
- SaveManager.
- CombatManager.
- CareerLoop.
- ReputationMatrix.
- CriaLiveManager.
- FactionSystem.
- SponsorManager.

## Regras de combate

Não criar beat’em up genérico. O núcleo é BJJ posicional:

```txt
DISTANCE → GRIP → CLINCH → TAKEDOWN → GROUND → TRANSITION → SUBMISSION → RESET
```

Ruan deve parecer lento, pesado e opressivo. Davi deve parecer rápido, evasivo e vulnerável quando controlado.

## Pipeline visual obrigatório

1. Criar placeholders jogáveis primeiro.
2. Gerar concepts com `art/prompts/MASTER_PROMPTS_PIXEL_ART.md`.
3. Separar personagens, arenas, UI e VFX por pasta.
4. Importar sprites no Godot com filtro desligado.
5. Testar leitura em 1280x720 e tela Android.
6. Aprovar asset somente se passar pelo checklist de `production/VISUAL_ASSET_PRODUCTION_BOARD.md`.

## Critérios de aceite

A entrega só passa se:

- O projeto abre.
- O menu funciona.
- O hub funciona.
- A luta inicia.
- HUD atualiza recursos.
- Botões mobile alteram estado/recursos.
- A luta termina.
- Resultado retorna ao hub.
- Save/load funciona.
- JSON valida.
- Visual segue preto/dourado, Baixo Sul, BJJ e pixel art 2.5D.
- Próximas pendências estão documentadas.

## Resposta final esperada

Ao terminar, responda com:

1. Auditoria do repo.
2. Arquivos criados.
3. Arquivos modificados.
4. Como rodar.
5. Como gerar APK debug.
6. Testes feitos.
7. Limitações.
8. Próximo passo recomendado.

Não diga que o APK foi gerado se não executou build real. Não diga que está completo se não está.
