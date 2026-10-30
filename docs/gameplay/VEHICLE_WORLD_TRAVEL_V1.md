# Vehicle World Travel V1 — CRIA DO TATAME

**Status:** candidate integration design  
**Base:** `integrate/p0-world-progression-20260912`  
**Runtime:** Godot only  
**Shipping:** false until runtime + mobile + physical Android gates pass

## 1. Tese de jogabilidade

A Kombi do Terreiro não é um menu com rodas. Ela é a ponte jogável entre o mapa regional, a carreira, as missões, a reputação, o mundo vivo e a chegada às arenas.

O jogo mantém hubs densos em vez de tentar virar um open world rodoviário caro. A exploração veicular acontece **nas rotas entre nós**: o jogador escolhe um destino no mapa, prepara a viagem, dirige quando a rota pede gameplay, encontra eventos e pontos de interesse, chega com consequências e entra no hub de destino.

O objetivo é fazer a pergunta “como eu chego lá?” ter peso sem transformar toda viagem repetida em obrigação.

## 2. Autoridades preservadas

- `WorldMapManager`: única autoridade de rota/viagem;
- `WorldState`: dinheiro, energia e reputação;
- `WorldDirectorManager`: clima e eventos de mundo;
- `ProgressionOS`: ledger, exploração e domínio de progressão;
- `SaveManager`: persistência;
- `AudioManager`: áudio;
- `CombatManager`: combate, sem qualquer interferência da viagem em legalidade/score.

Não criar `VehicleManager` autoload. Estado persistente de veículos e domínio de viagem ficam sob `WorldMapManager.world_travel_state`.

## 3. Loop principal

```text
HUB / MISSÃO
    ↓
MAPA VIVO
    ↓
FOCO NO NÓ
    ↓
PAINEL DE VIAGEM
    ↓
VALIDAR ROTA + GATES + CLIMA + MARÉ + MISSÃO
    ↓
ESCOLHER MEIO
    ↓
PREPARAR COMBUSTÍVEL / CONDIÇÃO / CARGA / EQUIPE
    ↓
CRIAR TRAVEL PLAN IMUTÁVEL
    ↓
ROTA 101 / VIAGEM RESOLVIDA / FERRY / TRILHA
    ↓
TRAVEL OUTCOME
    ↓
COMMIT ÚNICO NO WORLDMAPMANAGER
    ↓
PROGRESSION OS + SAVE
    ↓
ENTRAR NO HUB / ARENA / MISSÃO
```

## 4. Viagem em duas fases

A principal mudança arquitetural é parar de mutar o mundo assim que o jogador clica no destino.

### Fase A — planejamento

`prepare_travel()` deve:

- validar origem e destino;
- achar a rota canônica;
- verificar locks, ato, missão, maré, clima e story flags;
- verificar método permitido;
- estimar custo, tempo e combustível;
- gerar `plan_id` estável;
- capturar um snapshot do contexto;
- **não** descontar dinheiro, não mover o jogador e não salvar chegada.

### Fase B — resolução

A cena/minigame devolve um `TravelOutcome`.

`commit_travel_outcome()` deve:

- rejeitar plano já usado;
- aplicar custos uma única vez;
- atualizar condição/combustível;
- aplicar tempo/energia;
- mover `current_hub/current_node` apenas em sucesso;
- registrar descoberta/mastery;
- emitir `world_travel_completed` só depois do commit;
- salvar;
- liberar entrada na cena de destino.

Falha não é game over da campanha.

## 5. A Kombi do Terreiro

### Identidade

- azul e branca;
- símbolo Silverback fictício;
- veículo coletivo, não prêmio individual de Ruan;
- carrega a equipe, material de treino e pequenas entregas;
- histórias de estrada são parte do vínculo da equipe.

### Atributos persistentes

- combustível `0..100`;
- condição `0..100`;
- dano grave `0..3`;
- upgrades;
- recordes por rota;
- conhecimento por rota.

### Upgrades bons

- pneus;
- suspensão;
- tanque;
- faróis;
- bagageiro;
- kit de reparo;
- conforto dos bancos;
- rádio cosmético.

Nada de arma, atropelamento como mecânica ou bônus de dano.

## 6. Métodos de deslocamento

### Kombi

Escolha-padrão para viagens de equipe e rotas terrestres importantes. Ativa `ROTA 101` quando a rota estiver marcada para o minigame.

### Moto emprestada

Solo, rápida, barata e útil em acesso estreito ou urgente. Menos carga, mais vulnerável a chuva e sem conversa de equipe.

### Ônibus regional

Fallback seguro. Viagem resolvida, sem dano de veículo próprio e sem coletáveis de estrada. Custa passagem e segue tempo fixo.

### Barco/ferry

Obrigatório em rotas marítimas. Respeita maré e clima. No V1 usa resolução/vignette; o futuro minigame marítimo deve ser outro modo, nunca `ROTA 101` terrestre.

### A pé

Para hub, vila, trilha e pequenos deslocamentos. Custa energia, favorece NPCs, recursos e exploração local.

## 7. ROTA 101 — como deve jogar

### Não é clone de Enduro

A inspiração é perspectiva arcade retrô. O jogo é do CRIA:

- estrada do Baixo Sul;
- mata, cacau, mangue, ponte, praia e cidade;
- Kombi e equipe;
- eventos ligados à campanha;
- direção responsável como parte da disciplina.

### Câmera

- pseudo-3D pixel art;
- horizonte alto ~30%;
- pista domina a leitura;
- Kombi traseira/3-4 na faixa inferior;
- tráfego nasce pequeno no horizonte e cresce em perspectiva;
- sensação de velocidade vem de asfalto, postes, vegetação e parallax.

### Controles desktop

- A/D ou ←/→: esterço;
- W/↑: acelerar;
- S/↓: frear;
- Espaço: buzina;
- P: pausa.

### Controles mobile

- zona esquerda: esterço;
- zona direita: acelerar/frear;
- buzina contextual;
- pausa;
- alvos ≥48 px;
- opção auto-acelerar;
- opção assistência de faixa;
- opção reduzir trepidação.

### Velocidade

O jogo não precisa exibir 178 km/h para parecer rápido. A faixa visual é estilizada, porém coerente:

- estrada pavimentada: 70–110 km/h;
- vicinal: 30–70;
- urbano: 20–50.

A sensação arcade vem do scroll/perspectiva. Pontuação não premia imprudência.

## 8. O que o jogador faz durante uma rota

A estrada não é apenas “desvie de carro”. Ela possui três camadas:

### Condução

- posicionamento de faixa;
- antecipação de curva;
- freada;
- ultrapassagem limpa;
- clima/neblina;
- integridade de carga;
- combustível.

### Decisão

Em junctions o jogador escolhe:

- continuar pela rota principal;
- parar em posto;
- entrar em acesso conhecido;
- investigar um POI;
- evitar bloqueio;
- aceitar risco de atalho se o cânone permitir.

### Mundo

Eventos podem trazer:

- caminhão de cacau lento;
- ônibus regional;
- moto em ultrapassagem;
- buraco;
- galho caído;
- chuva forte;
- neblina;
- obra;
- checkpoint institucional fictício;
- bloqueio de facção apenas quando sustentado pela história;
- parada segura para recurso/coletável;
- diálogo de equipe.

Pedestre, criança e ciclista não são alvo nem obstáculo recompensado. Zonas vulneráveis pedem redução de velocidade.

## 9. Tipos de viagem

A mesma infraestrutura suporta presets sem criar sistemas paralelos.

### Viagem livre

Exploração, POIs, recursos e descoberta da rota.

### Missão com horário

Chegar dentro da janela sem destruir a condição da equipe.

### Entrega

Integridade da carga vale mais do que tempo.

### Equipe para competição

Condição de chegada influencia somente um pequeno modificador temporário de disposição, nunca regra de BJJ.

### Viagem narrativa de risco

Emboscadas/bloqueios só em missões específicas. Não virar rotina procedural genérica.

## 10. Resultado

Métricas:

- tempo;
- direção limpa;
- dano;
- combustível;
- carga;
- descobertas;
- condição de chegada.

Condição de chegada:

- `fresh`;
- `steady`;
- `tired`;
- `shaken`.

Ela pode gerar um modificador pequeno consumido na próxima atividade. Nunca concede técnica, ponto, score ou finalização.

## 11. Progressão de rota

### Unknown

Nunca concluída.

### Known

Primeira chegada com sucesso. Revela informação básica e recorde.

### Familiar

Duas viagens limpas. Permite resolução rápida quando a história não exigir gameplay.

### Mastered

Quatro viagens limpas + descobertas da rota. Libera fast travel quando permitido, estimativa precisa de combustível e pontos seguros conhecidos.

Isso resolve o problema clássico: a primeira viagem é experiência; a décima não vira trabalho repetitivo.

## 12. Integração com ProgressionOS

Eventos propostos:

- `travel_started`;
- `travel_completed`;
- `travel_clean`;
- `travel_breakdown`;
- `route_discovered`;
- `route_mastery_changed`;
- `travel_poi_discovered`.

Todos pertencem ao domínio `exploration`, exceto eventos explicitamente narrativos que também podem registrar `story` por regra de dados.

## 13. Integração com mapa vivo

O `WorldMapScreen` atual ainda tem quatro botões legados chamando `WorldMapManager.travel_to()` diretamente. O mapa vivo já desenha páginas/nós e emite `node_focused`, mas clicar no nó só atualiza o painel de detalhes.

Destino correto:

```text
node_focused
→ TravelDetailPanel
→ route resolver
→ method picker
→ prepare_travel
→ scene transition
→ commit outcome
```

Os quatro botões antigos só saem depois do novo fluxo passar smoke de viagem.

## 14. Novo world_map_v4 aprovado em chat

O snapshot aprovado pelo usuário em 2026-09-12 expande a intenção para 11 páginas e dezenas de nós adicionais, porém ainda não está consumido pela branch de integração.

Ele também usa uma forma semântica diferente do renderer atual:

- `pag` em vez de `pagina`;
- `de/para` em vez de `from/to`;
- não possui `pos` visual;
- usa `ponte/conexao` nas rotas apesar de esses valores não aparecerem no enum declarado;
- inclui LEI no campo de controle;
- contém uma rota marítima marcada com `rota_101`, embora `ROTA 101` seja terrestre.

A solução não é enfiar coordenadas no grafo semântico.

### Separação proposta

- `world_map_v4.json`: semântica de gameplay;
- `world_map_layout_v2.json`: página, posição, curva e âncoras de desenho;
- adapter normaliza nomes de campos para o renderer;
- LEI é `institutional_controller`, não quarta facção cultural ativa;
- marítimo nunca dispara `ROTA 101`.

As contagens devem ser derivadas por validator, não hardcoded no HUD.

## 15. Narrativa dentro da Kombi

A cabine é um palco de personagem de baixo custo.

Antes da viagem:

- Dendê comenta propósito e responsabilidade;
- Joaquim fornece informação, rota e ironia;
- Degodo comenta condição da Kombi;
- passageiros variam conforme missão.

Durante:

- falas curtas acionadas por trecho, clima ou evento;
- nunca tapar pista;
- prioridade para áudio/legenda curta;
- conversa pode revelar rumor, POI ou contexto, não alterar resultado arbitrariamente.

Depois:

- comentário curto sobre chegada;
- reação coerente com dano/atraso;
- entrada direta no próximo objetivo.

## 16. Recursos e coletáveis

Coletável não fica boiando no meio da BR.

Ele aparece em POIs seguros:

- posto;
- mirante;
- cais;
- barraca;
- acesso de mata;
- parada narrativa.

Isso conecta cacau, piaçava, pesca, plantas, memória, dossiê e CriaCoin ao mundo sem transformar a estrada em caça-moeda genérica.

## 17. Relação com facções e LEI

As facções culturais ativas continuam ALE, LEM e NTM conforme contrato v4.1.

`LEI` deve funcionar como controlador institucional de nó/rota, não como quarta facção ativa. Checkpoints, operações e restrições vêm de dados e missões; nenhuma instituição real deve ser copiada em brasão/uniforme/logotipo final.

## 18. Economia e manutenção

A viagem consome dinheiro, combustível, tempo e condição em proporção previsível.

Evitar grind:

- custo estimado antes de sair;
- botão de abastecimento suficiente para a rota;
- reparo rápido e reparo completo;
- degradação lenta em condução limpa;
- dano grave vem de erro real, não RNG oculto;
- ônibus continua sendo fallback quando a Kombi estiver indisponível.

## 19. Regras de fail-safe

- plano de viagem não muta mundo;
- outcome é idempotente;
- save durante minigame nunca cria chegada fantasma;
- crash/reload retorna ao último checkpoint coerente;
- rota bloqueada não pode ser forçada por UI;
- maré e story gate são revalidados antes de começar;
- não descontar custo duas vezes;
- ProgressionOS deduplica eventos;
- falha de minigame não apaga progresso de campanha.

## 20. QA obrigatório

### Dados

- rota aponta para nós existentes;
- método compatível com tipo;
- minigame compatível com meio;
- todos os gates têm consumidor;
- sem IDs duplicados.

### Runtime

- prepare é não-mutante;
- commit é idempotente;
- sucesso move;
- falha não move;
- custos aplicados uma vez;
- first visit correto;
- repeat visit correto;
- save/load no meio da viagem;
- ProgressionOS sem eventos duplicados.

### Visual/touch

- leitura a 6 polegadas;
- 48 px mínimo de touch;
- contraste de neblina/noite;
- reduced motion;
- sem texto baked no cenário;
- 45 FPS sustentados no Android físico alvo.

## 21. Ordem de implementação

### VT1 — contrato + resolver

Somente dados e testes. Nenhuma nova cena pesada.

### VT2 — TravelDetailPanel

Nó do mapa realmente abre planejamento data-driven.

### VT3 — two-phase WorldMapManager

`prepare_travel` + `commit_travel_outcome`, mantendo `travel_to` como facade de compatibilidade.

### VT4 — Kombi state + save local version

Combustível, condição, recordes e mastery.

### VT5 — ROTA 101 vertical slice

Apenas **Ituberá → Valença** primeiro. Uma pista, um clima base, quatro eventos, mobile touch e arrival outcome.

### VT6 — contexto vivo

Clima, diálogo, facção, POI, neblina e variantes.

### VT7 — rotas restantes

Expandir somente depois da rota ouro aprovada.

### VT8 — marítimo

Separado. Não reutilizar ROTA 101 como se barco fosse Kombi com água embaixo.

## Definition of Done do slice

```text
Terreiro
→ abrir mapa
→ selecionar Valença
→ ver custo/tempo/combustível
→ escolher Kombi
→ iniciar ROTA 101
→ dirigir com touch/teclado
→ resolver eventos
→ chegar ou falhar
→ outcome aplicado exatamente uma vez
→ ProgressionOS registra exploração
→ save
→ Valença/hub correto
→ reload preserva estado
```

Só depois disso a Kombi deixa de ser concept art e vira sistema de jogo.
