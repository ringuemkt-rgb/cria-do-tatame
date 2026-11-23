# CRIA Universal Combat Authoring v0.3 — todo o elenco

**Estado:** sistema de preparação de conteúdo, ainda não é um motor completo de combate. Padrão obrigatório: shipping=false e QA pendente.

## Objetivo

Não prender o jogo à luta Ruan × Davi. Os scripts buscam TODOS os IDs autorizados em data/combat/roster_v3.json, sem lista fixa no código. Hoje são 17 personagens; 18 é meta futura do contrato. O sistema não inventa o 18º nem libera automaticamente personagens que o gameplay não considera jogáveis.

Para 17 personagens: 136 duplas distintas e 272 direções atacante/defensor. É uma matriz de **planejamento**, não 272 jogos, nem 136 animações prontas.

## Comandos da fábrica (raiz do único repositório oficial)

Gerar a cobertura do elenco sem imagens, GPU ou modelos pagos:

    python tools/cria-asset-factory/scripts/plan_combat_matchups.py --all --out /tmp/cria-matchups.json

Selecionar qualquer par do elenco e uma técnica já cadastrada na fábrica:

    python tools/cria-asset-factory/scripts/plan_combat_matchups.py --fighter leoa --opponent jacare_do_mangue --technique baiana --out /tmp/leoa-jacare.json

Gerar um conceito visual pendente, sem rodar inferência:

    python tools/cria-asset-factory/scripts/prepare_candidate_job.py --id baiana --character leoa --opponent jacare_do_mangue --phase anticipation --outfit gi_white --out /tmp/leoa-concept.json

Após fornecer **frames PNG 128x128 autorizados**, empacotar um candidato:

    python tools/cria-asset-factory/scripts/build_paired_technique.py --id baiana --attacker-id leoa --defender-id jacare_do_mangue --attacker /tmp/frames-a --defender /tmp/frames-b --counts 2,2,2,3,2,2 --commit-frame 8 --out /tmp/leoa-jacare-frames

## Arquitetura final desejada

1. O único motor Godot e os sistemas existentes de CombatManager / BJJGraphReducer e rulesets decidem posição, ações válidas, resultado e pontuação. IA e animações NÃO alteram regras.
2. Cada lutador possui identidade própria, GI/NO-GI, silhueta, tamanho corporal, movimentação, respostas táticas e técnicas autorizadas. O cadastro atual não certifica esses atributos.
3. Biblioteca de movimentos reutilizáveis por técnica/posição e **papéis atacante/defensor**. Pareamento dinâmico só ocorre quando escala, contato, figurino, regras e pontos de apoio forem compatíveis.
4. Renderizador Godot associa personagens e a técnica autorizada a duas faixas de movimento sincronizadas. Um único asset técnico pode servir vários pares sem gerar uma nova animação inteira para cada combinação.
5. Perfis de IA, disponibilidade de técnicas, áudio, câmera, arena e UI são consumidores independentes do sistema de regras. Cada confronto gera replay determinístico testável.
6. Só liberar após revisão de contato, biomecânica, direitos, identidade, integração com cena, QA visual humano e teste real no Android.

## Bloqueios que permanecem explícitos

- O grafo BJJ completo não foi encontrado em data/bjj/bjj_knowledge_graph_v1.json. As dez técnicas da Asset Factory são **candidatas**, não licença para assumir suporte a todas as 120 técnicas projetadas.
- O catálogo mestre e a fixture do vertical slice têm IDs e estados distintos. Por exemplo, baiana / t001 e sprawl / slice_sprawl NÃO são equivalências automáticas.
- Não foi verificado que todo personagem sabe toda técnica ou possui autorização para toda categoria de luta; toda elegibilidade permanece UNVERIFIED.
- A fábrica gera PLANO e pacotes candidatos, não liga automaticamente 136 lutas ao menu Godot.
- Falta provar matchmaking de toda dupla compatível, perfil tático de cada lutador, sprites finais, importação no Godot e QA no dispositivo.

A certificação inicial Ruan × Davi permanece como teste de regressão (docs/DECISIONS.md D9), nunca como restrição da arquitetura de produção. Expandir o elenco é derivar novos arquivos a partir do cânone, não editar hardcodes nos scripts.
