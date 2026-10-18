# Correções integradas — 18/10/2026

Status: `DRAFT / VALIDATED_INTEGRATION_BRANCH` — revisão antes de main.

A branch reúne correções existentes de combate, saves, atlas/touch, viagem regional e deck, com uma correção adicional na leitura de presets V2. Não altera a main. Os SHAs de origem e resultados estão no JSON de evidências ao lado.

| Área | Comportamento corrigido | Origem |
|---|---|---|
| Combate | Rejeição de ações indisponíveis e repetidas; defesa touch; pontuação após estabilização; resultado por tempo; ausência de vitória artificial por HP/gás | #157 |
| Visualização de combate | Relógio pareado de seis fases e fallback gráfico sem autoridade de estado | #166, baseado em #157 |
| Persistência | Preservação do último backup recuperável ao promover principal novo e ao falhar restauração/migração | #165 |
| Árvore e deck | Equipagem transacional, remoção touch e rejeição de técnicas duplicadas no preset | #173, inclui trabalho de #167 |
| Atlas | Limites responsivos, proporção da imagem e seleção do marcador mais próximo | #171, inclui #168 |
| Viagens | Restrição ao Baixo Sul e migração de saves legados externos | #169 |
| QA de Davi | Quatro ações canônicas com perfis registrados; comparação das ações declaradas com os jobs compilados | correção de #157 conciliada com o diagnóstico local |

## Falha adicional reproduzida e corrigida

`DeckManager.configure_from_data` importava `v2_presets` diretamente. A gravação recusava duplicatas, porém o carregamento de um save contornava essa validação. Um valor escalar podia chegar a um getter que esperava Array; listas inválidas também reapareciam no pré-combate.

A carga agora mantém apenas os três IDs aceitos e arrays com 6–8 técnicas únicas e desbloqueadas. A mesma função pura valida criação e carga. Uma entrada inválida é descartada, preservando outros presets, coleção e dados do chamador. O formato do save não mudou.

O teste `deck_v2_preset_load_smoke.gd` reproduziu 12 falhas em 33 verificações antes da correção. Após a correção e ampliação dos casos, passou em 43 verificações: valores nulos, números, strings, objetos, duplicatas, tamanho inválido, técnica desconhecida/bloqueada e ID de preset desconhecido; inclui round-trip válido e cópia independente na leitura.

## Integração e conflitos

Os conflitos de perfil visual e teste de Davi foram conciliados com a versão mais abrangente de #157: `counter_entry=dynamic_upright`, `sprawl_response/scramble=ground_transition` e assinatura com override explícito. Nenhum limiar existente foi relaxado. As demais branches combinaram sem conflito de conteúdo. A soma foi testada como um único projeto Godot.

Os PRs individuais permanecem abertos. Este lote é uma alternativa de integração consolidada; coordenar a promoção para não reaplicar patches sem considerar a ancestralidade. #172 e #174 são pacotes separados de autoria visual e não estão incluídos neste conjunto executável.

## Verificações locais

- `npm run quality`: comando completo, exit 0.
- `python -m pytest -q`: 154 testes + 5 subtestes, sem falhas.
- Godot 4.2.2 e 4.3: importação e **21 scripts smoke em cada versão**, sem erro de runtime oculto.
- Auditoria integral: 0 erros, 13 avisos informativos (IDs compartilhados entre catálogos, sinais sem emissão direta detectada e permissão de rede opcional).
- Ruff crítico, compilação Python, YAML dos workflows e `git diff --check`: sem erros.
- Pacote PCK desktop: exportação, boot e quatro smokes executados fora do checkout; requer executável Godot da versão indicada no relatório do pacote.

```bash
npm run quality
python -m pytest -q
python tools/audit_full_game.py
python -m ruff check tools tests --select E9,F63,F7,F82
godot --headless --editor --path . --quit
bash tools/ci/run_godot_smokes.sh godot reports/full_game_audit
python tools/build/build_playtest_pack.py --godot godot --output reports/build/playtest
```

O runner isola dados de usuário por processo e rejeita erros Godot mesmo com exit 0. O Full Game Hardening passa a executá-lo em matriz 4.2.2/4.3; não houve migração de engine. A certificação de exportação Android e testes em aparelho físico permanecem pendentes. Arte final, revisão biomecânica e grafo BJJ integral também permanecem sujeitos aos gates existentes.

Rollback: usar a main-base `099c060092f94065afafd331e785472cc254e06f`. Não há mudança de schema de save nem manager duplicado. A disponibilidade de testes aprovados não constitui garantia de ausência de bugs fora das situações exercitadas.
