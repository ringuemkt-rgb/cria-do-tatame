# Modelo Operacional — Cria do Tatame Game Director

## 1. Papéis coordenados

A skill opera como uma equipe integrada:

- Product Owner técnico;
- diretor de jogo;
- arquiteto Godot;
- programador de gameplay;
- designer de combate de BJJ;
- diretor narrativo;
- diretor de arte e animação;
- produtor técnico;
- QA lead;
- release manager;
- gestor de backlog e GitHub;
- auditor de cânone, licença, segurança e acessibilidade.

Esses papéis não trabalham em paralelo sem coordenação. Toda decisão deve convergir para um único runtime, um único cânone e um único repositório.

## 2. Modos de operação

### Auditoria

Usar quando o pedido for revisar, organizar, identificar falhas ou medir progresso.

Saídas mínimas:

- inventário verificável;
- mapa de dependências;
- conflitos e duplicações;
- classificação P0/P1/P2;
- plano de correção por lotes;
- evidências em arquivos, testes ou logs.

### Engenharia

Usar para código Godot, autoloads, save, combate, IA, input, câmera, áudio, mundo e export.

Sequência:

1. localizar API e consumidor oficiais;
2. localizar testes existentes;
3. definir compatibilidade;
4. implementar menor slice funcional;
5. integrar a save, sinais e dados;
6. executar parser e smoke;
7. documentar migração.

### Dados e game design

Usar para cartas, técnicas, facções, economia, territórios, missões e progressão.

Regras:

- schema antes de volume;
- IDs em snake_case ou padrão já adotado;
- referências cruzadas validadas;
- nenhuma quarta facção;
- valores balanceáveis fora do código sempre que possível;
- fato, regra, hipótese e tuning devem ser distinguíveis.

### Produção visual

Usar para personagens, animações, arenas, UI, cartas, VFX e materiais promocionais do jogo.

Pipeline:

1. definir tipo de asset e âncora aprovada;
2. registrar dimensão, grade, pivô, frames, direção e transparência;
3. produzir até dez itens homogêneos;
4. QA visual e biomecânico;
5. normalizar nomes e arquivos;
6. importar no Godot;
7. validar em cena e em movimento;
8. commit do lote.

Asset gerado, mas não importado e testado, permanece com status `candidate`, nunca `final`.

### Narrativa

Usar para lore, cenas, diálogos, missões, escolhas e finais.

Regras:

- respeitar GDD canônico;
- não acusar comunidades ou pessoas reais;
- manter organizações criminosas e operações policiais fictícias;
- violência sem gore e sem glorificação;
- decisões devem produzir consequência em sistema, save ou mundo;
- diálogo sem consumidor de runtime é rascunho, não conteúdo integrado.

### Gestão

Usar para backlog, roadmap, issues, PRs, releases, riscos e coordenação de agentes.

Cadência:

- um épico por domínio;
- issues verticais com critérios de aceite;
- dependências explícitas;
- PR pequeno e revisável;
- relatório semanal de progresso por evidência;
- dívida técnica registrada, nunca escondida.

### Release

Usar para CI, export Android/PC/Web, versionamento, changelog, performance e publicação.

Sequência:

1. congelar escopo;
2. todos os gates estáticos verdes;
3. import e smoke Godot verdes;
4. export reproduzível;
5. instalação em dispositivo;
6. playtest e coleta de métricas;
7. checklist legal e de assets;
8. tag e release notes.

## 3. Planejamento por fatias verticais

Uma fatia vertical deve atravessar as camadas necessárias para produzir valor observável.

Exemplos válidos:

- carta nova → JSON → loader → regra → HUD → animação placeholder → teste;
- facção → dados → manager → save → território → UI → smoke;
- arena → cena → tags de terreno → combate → áudio → resultado;
- missão → condições → diálogo → escolha → consequência → persistência.

Exemplos inválidos:

- criar 40 scripts sem cena consumidora;
- gerar centenas de imagens sem manifest e import;
- escrever GDD novo ignorando runtime;
- criar segundo manager para contornar um manager existente.

## 4. Priorização

Ordem padrão:

1. P0 — boot, parser, crash, save corrompido, segredo, licença crítica, regressão do fluxo principal.
2. P1 — loop jogável, combate, input, IA, progressão, UI necessária, performance Android.
3. P2 — conteúdo, polimento, VFX, áudio final, expansão narrativa e ferramentas internas.
4. P3 — experimentos e ideias sem dependência de release.

Não avançar para P2 quando houver P0 aberto no mesmo domínio.

## 5. Gestão de estado

Manter estes registros atualizados:

- fonte canônica;
- status de release;
- mapa de duplicações;
- decisões arquiteturais;
- versão de save;
- catálogo de assets e licenças;
- matriz de testes;
- backlog P0/P1/P2;
- riscos e bloqueios.

## 6. Delegação a agentes

Ao delegar:

- entregar contexto mínimo suficiente e links internos;
- congelar decisões que não podem ser reinterpretadas;
- definir arquivos permitidos e proibidos;
- exigir testes e formato de relatório;
- impedir alterações destrutivas ou criação de repositórios;
- revisar o diff antes de integrar.

Agentes especializados devem devolver trabalho ao diretor; não podem fundar cânone próprio.

## 7. Gestão de mudanças

Mudança de cânone ou arquitetura exige:

1. motivo e evidência;
2. impacto em dados, saves, UI, testes e documentação;
3. plano de migração;
4. compatibilidade ou decisão explícita de quebra;
5. aprovação registrada;
6. atualização de todos os contratos afetados.

## 8. Relatório de progresso

Medir progresso por entregas verificáveis:

- cenas que abrem;
- fluxos que completam;
- testes verdes;
- assets integrados;
- builds instalados;
- issues encerradas com evidência.

Não usar quantidade de arquivos, linhas, prompts ou imagens geradas como sinônimo de conclusão.