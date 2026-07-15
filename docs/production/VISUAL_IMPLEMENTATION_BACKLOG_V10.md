# Visual Implementation Backlog V10

## Objetivo

Converter o runtime funcional atual para o formato visual aprovado sem quebrar combate, save/load, carreira, Android ou contratos de dados.

## Veredito do estado atual

| Área | Estado atual | Estado-alvo |
|---|---|---|
| Main Menu | Estrutura funcional com fundo plano e botões genéricos | Marca Silverback, preto/dourado, hierarquia premium e safe area |
| Combat HUD | Barras básicas e mensagem | HUD espelhado, timer central, controle/grip laterais e cinco comandos contextuais |
| World Map | Sistema existente/documentado | Mapa regional com objetivo, rotas, riscos, facções e ficha do local |
| Terreiro | Hub funcional/placeholder | Hub vivo 2.5D, NPCs, missões, minimapa, clima e evolução visual |
| Cria Live | Sistemas de reputação disponíveis | Feed, contratos, crises, facções e skill tree em abas mobile |
| Personagens | Manifesto de produção | Spritesheets finais sincronizados e QA por ação |
| Arenas | Dados e referências | Cinco layers, props, colisão, clima, público e áudio |
| Áudio | Pacotes definidos | Masters WAV, runtime OGG, buses e mix adaptativo |

## Sprint V10.0 — Contratos

- [x] Criar `docs/art/VISUAL_TARGET_V10.md`.
- [x] Criar `data/ui/ui_design_tokens_v01.json`.
- [x] Criar `data/visual/screen_contracts_v01.json`.
- [ ] Adicionar validação de schema para os dois JSON.
- [ ] Registrar os contratos em `DataRegistry`.
- [ ] Adicionar testes que bloqueiem nomes legados na UI.

## Sprint V10.1 — Main Menu

- [x] Reconstruir estrutura visual preto/dourado.
- [x] Preservar Novo Jogo, Continuar, Opções e áudio.
- [ ] Importar logo final sem texto rasterizado ilegível.
- [ ] Criar background em cinco layers: céu, mangue, água, Terreiro e partículas.
- [ ] Adicionar transição curta para o hub.
- [ ] Testar 1280×720, 1920×1080 e proporções mobile.

## Sprint V10.2 — Combat HUD

- [x] Criar moldura espelhada e barra superior.
- [x] Adicionar regiões de Controle, Pegada e comandos.
- [x] Manter paths esperados pelo script atual.
- [ ] Conectar timer e round ao `CombatManager`.
- [ ] Atualizar Controle e Grip em tempo real.
- [ ] Popular cinco botões a partir das técnicas válidas.
- [ ] Alternar labels por estado.
- [ ] Criar layout touch sem glyphs de controle físico.
- [ ] Criar modo acessível para daltonismo e texto ampliado.

## Sprint V10.3 — World Map

Arquivos-alvo:

```text
scenes/map/WorldMap.tscn
scenes/map/WorldMap.gd
data/world/locations.json
data/world/routes.json
data/world/faction_territories.json
```

Entregas:

- [ ] mapa com zoom/pan;
- [ ] Ituberá como hub central;
- [ ] rotas terrestres, marítimas, secretas e bloqueadas;
- [ ] objetivo atual à esquerda;
- [ ] ficha do local à direita;
- [ ] custo de viagem em dia, energia e dinheiro;
- [ ] status de missão, boss, torneio e facção;
- [ ] confirmação antes de viajar;
- [ ] revisão geográfica.

## Sprint V10.4 — Hub Ituberá/Terreiro

- [ ] reconstruir o playfield em camadas 2.5D;
- [ ] implementar minimapa;
- [ ] adicionar marcadores de Academia, Mercado, Doca, Quadro e Clínica;
- [ ] exibir até três missões ativas;
- [ ] adicionar ciclo manhã/tarde/noite/chuva;
- [ ] NPCs com rotinas simples;
- [ ] sistema de interação touch;
- [ ] evolução visual do Terreiro por nível de Legado.

## Sprint V10.5 — Cria Live + Skill Tree

- [ ] criar layout desktop de referência;
- [ ] criar layout Android em cinco abas;
- [ ] feed com posts e respostas;
- [ ] contratos com progresso e risco;
- [ ] crises com temporizador narrativo;
- [ ] mapa de influência de facções;
- [ ] árvore com Técnica, Pressão, Frieza e Legado;
- [ ] tooltips com custo, faixa e efeito;
- [ ] nenhuma ação social sem consequência sistêmica.

## Sprint V10.6 — Personagens

Prioridade:

1. Ruan “Macacão” Silva;
2. Davi Relâmpago;
3. Mestre Dendê;
4. Tinker Bell;
5. Leoa Quilombola;
6. Jacaré do Mangue;
7. Oni da Lapa;
8. Cássio Molho;
9. Kenzo Kuroi;
10. Mestre Guigo;
11. Delegado Montenegro.

Para cada lutador:

- turnaround;
- escala de combate e hub;
- portrait;
- core animation profile;
- técnicas assinatura;
- reações;
- hitboxes/hurtboxes;
- metadata;
- QA.

## Sprint V10.7 — Técnicas pareadas

Ordem recomendada:

1. jab setup;
2. clinch entry;
3. pummeling;
4. baiana/single leg;
5. sprawl;
6. raspagem tesoura;
7. knee cut;
8. mount transition;
9. bridge escape;
10. armbar;
11. triângulo;
12. mata-leão.

Cada técnica exige:

```text
attacker/
defender/
sync_map.json
hitbox.json
preview.gif
contact_sheet.png
qa_report.md
```

## Sprint V10.8 — Arenas

Ordem:

1. Terreiro da Luta;
2. Arena do Dique;
3. Manguezal Profundo;
4. Praia de Pratigi;
5. Ferro Velho da Lapa;
6. Ponte do Saici;
7. Zambiapunga;
8. Mirante da Gamboa;
9. Pancada Grande;
10. Budokan das Águas;
11. Itacaré;
12. Sede do Circuito Final.

Pacote por arena:

- `bg_far.png`;
- `bg_mid.png`;
- `play_area.png`;
- `foreground.png`;
- `overlay_particles.png`;
- `props/`;
- `collision.json`;
- `camera_bounds.json`;
- `arena.tscn`;
- variações de clima/luz;
- pacote de áudio;
- QA.

## Sprint V10.9 — Android

- [ ] botões 80 px mínimos em 1280×720;
- [ ] joystick 120 px;
- [ ] safe area 7%;
- [ ] layout adaptativo para 16:9, 18:9, 19.5:9 e 20:9;
- [ ] vibração configurável;
- [ ] qualidade baixa/média/alta;
- [ ] redução automática de partículas e luzes;
- [ ] teste em aparelho ARM64 físico;
- [ ] captura de FPS e memória;
- [ ] APK debug com SHA-256.

## Gates de aprovação

### Gate A — estrutura

- JSON válido;
- paths `res://` válidos;
- cenas abrem em headless;
- nenhum conflito de autoload/class_name.

### Gate B — jogabilidade

- Main Menu → Terreiro → Combate → Resultado → Hub;
- save roundtrip;
- estado de combate governa comandos;
- carreira avança uma semana.

### Gate C — visual

- mesmo design system nas telas principais;
- centro da luta limpo;
- texto legível;
- nenhuma marca real;
- protagonista canônico correto;
- concept art não usado como asset final.

### Gate D — audiovisual

- sprites, arenas e áudio com metadata;
- previews e QA presentes;
- sincronização atacante/defensor validada;
- buses e volumes normalizados.

### Gate E — release

- build Windows;
- APK debug;
- teste físico;
- performance registrada;
- bugs conhecidos documentados.

## Regra de fechamento

O projeto não pode ser chamado de “jogo completo” enquanto apenas mockups reproduzem o visual aprovado. Conclusão exige cenas, sprites, áudio, controles, saves, testes e builds reais.
