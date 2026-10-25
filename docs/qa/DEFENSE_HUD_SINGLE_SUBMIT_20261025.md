# Defesa do HUD — seleção única por janela (2026-10-25)

**Status:** DRAFT — PR empilhado sobre #177, que depende de #175. Não é evidência de homologação Android.

## Problema reproduzível

Durante a janela de reação de Davi, o jogador pode tocar duas vezes rapidamente, ou uma segunda entrada pode ficar enfileirada antes do encerramento da janela. O HUD do #177 permitia que cada `pressed` emitisse `combat_v2_defense_selected`; a arena descartava eventos tardios, mas outros consumidores do SignalBus poderiam observar mais de uma escolha.

## Alteração funcional

`scenes/ui/CombatDeckHUD.gd` consome a primeira escolha válida **antes** de emitir o sinal e desabilita os demais botões até o encerramento da janela. A próxima janela reinicializa o latch. Payloads não-Dictionary são exibidos como opções indisponíveis. Não muda `CombatManager`, pontuação, RNG, custo, catálogo, save ou autoload.

## Regressão automatizada

```bash
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/combat_defense_touch_window_smoke.gd
npm run quality
```

O smoke existente agora cobre opção inválida/malformada, primeira defesa, duas ativações consecutivas, tentativa de selecionar outra opção, encerramento e abertura de nova janela. É teste de sinal/estado do HUD, **não** substitui `InputEventScreenTouch` em Android físico.

## Teste Android obrigatório

No aparelho ARM64 real: iniciar Ruan × Davi; provocar reação; tocar duas vezes rapidamente e depois em outra carta; confirmar que apenas uma defesa é processada, sem ataque extra, consumo duplo ou transição prematura; provocar segundo ataque e confirmar que a defesa volta a responder. Repetir com teclado/mouse no desktop. Registrar vídeo, build SHA, versão do Godot, aparelho, FPS, orientação e logs.

## Integração, dependências e rollback

- Base imediata: #177; base transitiva: #175, que agrega #157/#164/#165/#166/#167/#168/#169.
- #176 (saves), #178 (primeira sessão) e #179 (atlas touch) permanecem independentes e exigem validação conjunta antes de `main`.
- Reverter os commits deste PR restaura o comportamento do #177. Nenhum schema/save é modificado.
- Revisão humana, CI verde e prova física Android são gates obrigatórios. Nenhum asset foi promovido via Sprite Forge.
