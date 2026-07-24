# Quality Gates — Cria do Tatame

## Gate 0 — Integridade do lote

- objetivo e critérios de aceite definidos;
- arquivos afetados inventariados;
- rollback possível;
- nenhum segredo incluído;
- nenhuma ação destrutiva não autorizada;
- nenhuma mudança fora do produto Cria do Tatame.

## Gate 1 — Cânone e dados

- exatamente três facções: `LEM`, `NTM`, `ALE`;
- núcleos permanecem subordinados;
- IDs não duplicados;
- referências cruzadas válidas;
- schemas e versões coerentes;
- Pratigi tratada como localização de Ituberá;
- pessoas, operações policiais e grupos criminosos reais não usados como acusação ou facção jogável;
- cartas, técnicas e missões possuem consumidores reais.

Comandos mínimos:

```bash
python tools/lint_canon_v4.py
python tools/validate_json.py
python tools/validate_runtime_contracts.py
```

## Gate 2 — Boot e arquitetura

- `project.godot` faz parse;
- main scene permanece correta;
- autoloads resolvem caminhos válidos;
- nenhum singleton duplicado;
- sinais emitidos estão declarados;
- recursos `res://` existem;
- managers não assumem responsabilidades de outros managers.

Comandos mínimos:

```bash
python tools/audit/audit_boot.py
python tools/validate_complete_game.py
```

Quando Godot estiver disponível:

```bash
godot --headless --editor --path . --import
godot --headless --path . --script res://tests/runtime_smoke.gd
```

## Gate 3 — Combate

Validar:

- posição e lado relativos;
- mão contextual;
- custo de recursos;
- janelas de defesa;
- transições válidas;
- falha e sucesso determinísticos sob seed/controladores de teste;
- finalização, tap, escape e opção moral de soltar;
- adapter legado;
- IA usa apenas ações válidas;
- HUD não congela o runtime.

Comandos mínimos:

```bash
godot --headless --path . --script res://tests/v4_combat_smoke.gd
godot --headless --path . --editor --quit-after 2 res://scenes/combat/CombatArenaV4.tscn
```

## Gate 4 — Save e migração

- versão de save incrementada quando necessário;
- migração de versões antigas testada;
- escrita atômica e backup preservados;
- save/load restaura facções, mundo, economia, deck, Hub, missões e flags;
- dados aposentados são reclassificados ou arquivados, nunca mapeados arbitrariamente;
- save corrompido falha com segurança.

## Gate 5 — Visual e animação

Para cada asset:

- manifest, ID, tipo, dimensão e destino definidos;
- paleta aprovada;
- sem texto embutido, marca de terceiros, gore ou pessoa real;
- transparência correta;
- pivô e escala consistentes;
- sem frames cortados;
- atacante e defensor sincronizados;
- biomecânica plausível;
- import Godot validado;
- licença e origem registradas;
- QA aprovado antes do próximo lote.

## Gate 6 — UI, touch e acessibilidade

- alvos de toque adequados;
- safe area em Android;
- navegação sem mouse;
- foco de controle visível;
- contraste legível;
- informação não depende apenas de cor;
- opção de redução de flash/strobe;
- volume por categoria;
- texto escalável quando aplicável;
- nenhuma ação crítica escondida fora da tela.

## Gate 7 — Áudio

- um único AudioManager;
- buses e categorias definidos;
- clips com licença registrada;
- ausência de clipping;
- loudness coerente;
- feedback de grip, queda, defesa, transição e tap distinguível;
- modo silencioso não quebra gameplay.

## Gate 8 — Performance

Metas mínimas:

- 60 FPS alvo;
- 45 FPS mínimo aceito em Android de referência;
- sem crescimento contínuo de memória;
- tempos de carregamento medidos;
- draw calls, partículas e texturas compatíveis com mobile;
- bateria e temperatura observadas em playtest prolongado.

Não afirmar performance sem medição.

## Gate 9 — Build e instalação

- export preset versionado sem segredos;
- build reproduzível;
- APK/AAB realmente gerado;
- assinatura tratada fora do repositório;
- instalação em dispositivo físico;
- boot, novo jogo, save, combate e retorno ao hub testados;
- permissões mínimas;
- versão e changelog coerentes.

## Gate 10 — GitHub e documentação

- commit focado;
- PR descreve escopo, arquivos, testes, migrações e riscos;
- issue relacionada atualizada;
- documentação corresponde ao runtime;
- screenshots ou logs anexados quando úteis;
- dívida técnica registrada;
- nenhum PR concorrente contém implementação substituta não absorvida.

## Definition of Done global

O jogo só pode ser declarado completo quando:

1. todos os gates obrigatórios estiverem verdes;
2. campanha e loop principal forem completáveis;
3. combate e progressão forem persistíveis;
4. conteúdo mínimo acordado estiver integrado;
5. Android físico atender desempenho e usabilidade;
6. assets, áudio e licenças forem aprovados;
7. não houver P0 aberto;
8. release versionada for reproduzível.

Documentação, prompts, conceitos ou quantidade de assets não substituem esses critérios.