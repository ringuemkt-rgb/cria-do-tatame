# Combate universal — Exibição v1

Estado: candidato de desenvolvimento. Godot 4.3; compatibilidade mínima auditada 4.2.2. Este documento não substitui AGENTS.md, os contratos de produção, nem docs/DECISIONS.md.

## Objetivo e autoridade

Ruan x Davi continua como marco de QA da história, não como limite técnico do motor. Qualquer dupla distinta do elenco canônico cadastrado em data/combat/roster_v3.json deve poder participar de uma exibição de prévia, com combate resolvido exclusivamente pelo CombatManager vigente. Não há outro manager, autoload, versão do projeto, nem LLM no loop de combate.

## Implementações

- data/combat/fighter_profiles_universal_v1.json: fichas para 17 IDs atuais do roster; nome, estilo, repertório, preferências da IA, assinatura, estatísticas de preview, paleta, escala. Preserva atributos da data/characters.json quando existentes. Os demais são heurísticas ainda não calibradas.
- FighterCombatProfileRegistryV1.gd: valida roster/catálogo/owner de técnicas e expõe lookup/candidatos de exibição.
- technique_identity_bridge_universal_v1.json e TechniqueIdentityBridgeUniversalV1.gd: mapeamento de 21 técnicas legadas contra o shadow map BJJ já existente. Baiana/t001 e Sprawl/slice_sprawl preservam semantic delta; não promovem o reducer nem alteram pontuação. Ausências falham fechadas.
- CombatManager: método prepare_exhibition_match; mesma máquina de estados e resolver existente, técnica por ID e autorização do dono, sem deck da campanha ou progressão. Encerra explicitamente com exhibition=true.
- DaviAIController é reaproveitado: somente Davi recebe sua política especial; demais IDs usam perfis táticos próprios. Nome histórico da classe é mantido para compatibilidade; refatoração de nome é opcional e não parte do gate.
- CombatPairTimelineV1: seis fases sincronizadas genéricas para qualquer dupla; ainda é RIG PROCEDURAL de prévia, sem claim de asset biomecânico final.
- PreFightHub ganha Exibição Livre, ExhibitionSelection oferece seleção de dois jogadores do elenco, CombatArenaBase exibe perfis selecionados e ResultScreen permite retornar à seleção sem avançar carreira.
- ProgressionOS, CriaLiveManager, FactionDirectorManager, WorldDirectorManager recebem guarda explícita para eventos de exibição.

## Testes

python tools/ci/validate_universal_combat_v1.py

python -m unittest discover -s tests -p 'test_universal_combat_contract_v1.py' -v

godot --headless --editor --path . --import

godot --headless --path . --script res://tests/universal_exhibition_smoke.gd

bash tools/ci/run_godot_smokes.sh ./godot reports/full_game_audit

npm run quality

O smoke testa 272 pares dirigidos como METADADOS, vários confrontos não-Ruan como gameplay, técnica exclusiva de Ruan bloqueada, IA por personagem, reprodução procedural e invariância de campanha. O CI Godot roda 4.2.2 e 4.3; export Android é coberta pelo Full Game Hardening da PR.

## Invariantes

- Gameplay e pontuação seguem CombatManager. BJJGraphReducerV2 permanece em shadow observacional.
- O modo de exibição nunca concede XP, dinheiro, resultado de campanha, alteração de facção, calendário ou save.
- Técnica exclusiva não é herdada por outro personagem.
- O status de assets e atributos é UNCALIBRATED/PENDING; shipping=false.
- O mapeamento BJJ não pode tratar estados legacy e BJJ como iguais sem revisão.

## Futuras integrações obrigatórias

1. Criar contratos de elegibilidade GI/NO-GI por personagem e ruleset oficial, não inferir de roteiro.
2. Produzir identidade, animações e colisões aprovadas dos 17 lutadores com Sprite Forge e Motion Lab.
3. Reutilizar movimento por técnica/papel + escalonamento e correção de contato, sem produzir 136 animações de pares à toa.
4. Substituir rig procedural por spritesheets aprovados com verificação de pivô, agarramento, biomecânica e qualidade do movimento.
5. Completar grafo de 40 posições/120 técnicas/10 cadeias e fazer parity gates antes de tornar BJJGraphReducerV2 autoridade.
6. Balancear os perfis experimentais por telemetria de replay offline e validação humana.

## QA visual e Android físico

Teste em ARM64 real: instale APK debug, abra PreFightHub -> Exibição Livre, selecione Leoa contra Jacaré e Miyao contra Viera, inverta os papéis, confira todos os controles touch e visuais, execute técnicas e verifique retorno à seleção. Registre FPS, tempo de frame, memória, temperatura, colisões, UI em 360x800 / 390x844 / 412x915 quando disponível, prints dos seis estágios, vídeo e eventuais travamentos. Verifique pelo antes/depois que Save, Cria Live, reputação, XP, dinheiro, facções e semana não foram alterados.

O ledger production/evidence/android_physical_device_v1.json continua PENDING até um aparelho real, APK hash, commit SHA, identificação do aparelho, capturas e revisão humana serem fornecidos. Um Godot smoke em CI ou export de APK não serve como teste visual físico.
