# Cria do Tatame — Plano Mestre de Conclusão APK e Audiovisual V0.9

## Objetivo

Transformar o repositório oficial em um produto verificável: jogo Godot que abre, percorre o fluxo principal, executa combate posicional, salva progresso, exporta APK Android e possui um inventário completo de arte, animação, áudio e documentação.

Este plano não permite marcar o jogo como concluído por quantidade de documentos ou concept arts. A conclusão depende de evidência executável.

## Estado confirmado em 14/07/2026

- Runtime central auditado por Godot headless.
- Fluxo de menu, hub, combate, resultado e progressão coberto por smoke test.
- JSON, contratos e referências possuem validadores automáticos.
- Combate data-driven possui ações contextuais e recursos posicionais.
- Save/load possui teste de roundtrip.
- Ainda não existe evidência de APK exportado e instalado em aparelho físico.
- A maior parte da arte presente é referência de produção, não sprites/tilemaps finais.
- Áudio final, controles touch validados, performance Android e assinatura release ainda não estão aprovados.

## Definition of Done do APK debug

Todos os itens abaixo são obrigatórios:

1. `project.godot` importa sem erro fatal.
2. `export_presets.cfg` está na raiz do projeto.
3. Export templates compatíveis com a versão do Godot estão instalados.
4. JDK 17 e Android SDK estão configurados.
5. `tools/build/build_android_debug.ps1` termina com código zero.
6. `builds/android/CriaDoTatame-debug.apk` existe e possui tamanho maior que 1 KiB.
7. SHA-256 do APK foi registrado.
8. APK instala por `adb install -r` em pelo menos um aparelho ARM64.
9. O jogo abre sem crash, permanece em landscape e aceita toque.
10. Menu → Terreiro → combate → resultado → hub funciona no aparelho.
11. Save persiste após fechar e reabrir o aplicativo.
12. Relatório contém modelo do aparelho, Android, FPS, uso de memória e bugs.

## Definition of Done do vertical slice

- Protagonista canônico: Ruan “Macacão” Silva.
- Mestre Dendê disponível no Terreiro.
- Davi Relâmpago como rival inicial.
- Terreiro da Luta navegável.
- Arena do Dique funcional.
- HUD mobile legível.
- Movimento e auto-facing.
- Pegada, clinch, queda, guarda, passagem, montada e encerramento técnico.
- Recursos: vida, gás, foco, guarda, grip e controle.
- IA executa defesa e ao menos duas respostas posicionais.
- Resultado altera carreira e reputação.
- Um post de Cria Live é gerado após o combate.
- Uma semana de carreira pode avançar e ser salva.

## Estrutura de produção audiovisual

### Personagem

Cada ação final precisa entregar:

- `raw_sheet.png` — saída original preservada para rastreabilidade;
- `clean_sheet.png` — paleta e fundo corrigidos;
- `spritesheet.png` — grade definitiva;
- `frames/*.png` — quadros individuais;
- `preview.gif` — inspeção rápida;
- `contact_sheet.png` — comparação de todos os quadros;
- `metadata.json` — frame size, FPS, pivô, loop, eventos e versão;
- `hitbox.json` — hitbox/hurtbox/grabbox quando aplicável;
- `import_notes.md` — configuração Godot;
- `qa_report.md` — resultado e defeitos conhecidos.

### Técnica em dupla

Técnicas de Jiu-Jitsu não devem ser tratadas como animações isoladas. Cada técnica exige:

- animação sincronizada do atacante;
- animação sincronizada do defensor;
- estado de entrada e saída;
- pivôs compartilhados;
- ponto de contato principal;
- janela de interrupção;
- custo de recursos;
- evento de som e impacto;
- câmera recomendada;
- fallback quando uma animação estiver indisponível.

### Arena

Cada arena final precisa possuir:

- fundo distante;
- meio-fundo;
- camada de público;
- área jogável limpa;
- primeiro plano;
- partículas;
- props separados;
- colisões;
- limites de câmera;
- spawns;
- zonas de perigo;
- modificadores de gameplay;
- variações de manhã, tarde, noite e chuva quando previstas;
- cena Godot e preview executável.

### Áudio

Cada evento sonoro exige WAV mestre e OGG de runtime:

- passos por superfície;
- atrito de tecido/gi/rashguard;
- grip e quebra de pegada;
- queda no tatame, madeira, lama e metal;
- respiração por fadiga;
- crowd por arena;
- ambience loops sem clique;
- UI e Cria Live;
- música por hub, arena e estado narrativo;
- sidechain/ducking durante falas e finalizações.

## Fases de execução

### Fase A — Build reproduzível

- Presets na raiz.
- Scripts Windows de auditoria e exportação.
- Relatório automático e hash.
- Teste manual em aparelho.

### Fase B — Controles mobile

- Joystick esquerdo.
- Cinco ações contextuais.
- Alvos mínimos de 48 dp; recomendado 72–96 dp.
- Input buffer configurável.
- Vibração opcional.
- Safe area para recortes e barras do sistema.
- Modo de acessibilidade com alvos ampliados e redução de movimento.

### Fase C — Pacote de combate final

- Idle, locomoção, guarda, reação e queda.
- Clinch e pummeling.
- Baiana/single leg.
- Guarda por cima e por baixo.
- Passagem knee cut.
- Cem quilos.
- Montada.
- Kimura, triângulo e mata-leão.
- Vitória, derrota e retorno ao neutro.

### Fase D — Mundo e carreira

- Terreiro da Luta.
- Mapa do Baixo Sul.
- Arena do Dique.
- Manguezal.
- Ferro Velho da Lapa.
- Zambiapunga.
- Viagem, missão, calendário, treino e recuperação.

### Fase E — Arte e áudio final

- Executar fila em lotes pequenos.
- Validar silhueta, proporção e pivô antes de ampliar produção.
- Proibir asset gerado diretamente na build sem limpeza e QA.
- Verificar licença de todo modelo, dataset, fonte, sample e asset externo.

### Fase F — Release candidate

- Perfil de desempenho em celulares fraco, intermediário e forte.
- Correção de crash e save.
- Ícones, splash e package id final.
- Keystore fora do Git.
- Build release assinada.
- Testes de instalação, atualização e reinstalação.

## Matriz de prioridade

| Prioridade | Entrega | Critério |
|---|---|---|
| P0 | APK debug reproduzível | arquivo real + instalação física |
| P0 | Vertical slice | fluxo completo no celular |
| P0 | Controles touch | sem ação impossível ou botão sobreposto |
| P1 | Ruan + Davi completos | todas as ações da primeira luta |
| P1 | Terreiro + Dique | cena final, colisão, áudio e iluminação |
| P1 | Save e carreira | persistência real após reinício |
| P2 | Personagens secundários | pacote individual validado |
| P2 | Arenas adicionais | modificador mecânico e QA |
| P2 | Cria Live e facções | consequências funcionais |
| P3 | Multiplayer | somente após combate offline estável |

## Proibições

- Não declarar APK pronto sem arquivo e teste físico.
- Não usar imagens de referência como asset final.
- Não inserir chave de API no projeto ou APK.
- Não versionar keystore, senha, token ou credencial.
- Não adicionar segundo runtime de aplicativo; Godot é a engine única.
- Não depender de IA em tempo real para o combate principal.
- Não gerar sprites gigantes misturando muitas ações sem inspeção intermediária.

## Próxima execução no Windows

```powershell
cd C:\Projetos\cria-do-tatame
powershell -ExecutionPolicy Bypass -File .\tools\build\check_environment.ps1
powershell -ExecutionPolicy Bypass -File .\tools\build\build_android_debug.ps1
```

Para instalar imediatamente após exportar:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\build\build_android_debug.ps1 -Install
```

O resultado esperado é `builds/android/CriaDoTatame-debug.apk`, acompanhado por hash e relatório em `reports/build/`.
