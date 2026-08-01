# Quality Gates — CRIA Visual Canon Director

## 1. Princípio

Um asset só avança quando todos os bloqueadores da categoria passam. Média alta não compensa falha de cânone, licença, biomecânica, integração ou legibilidade.

## 2. Bloqueadores absolutos

Reprovar imediatamente quando houver:

- personagem, facção, arena ou técnica com ID incorreto;
- `Ruan “Cria” Silva` como nome oficial;
- `ALE` exibida fora do nome canônico vigente;
- técnica ausente em `data/techniques.json`;
- soco, joelhada, cotovelada ou arma no núcleo BJJ;
- finalização sem posição/controle ou sem tap/escape/intervenção;
- marca, brasão, academia, liga ou pessoa real sem licença;
- cópia identificável de frame, jogo, fotografia ou aula;
- estereótipo cultural/religioso/regional;
- uso de saída de IA como asset final sem limpeza e aprovação humana;
- arquivo sem origem/licença/metadata;
- filtro bilinear ou pixel art borrada;
- animação pareada com contagem de frames divergente;
- ausência de consumidor Godot quando o estado declarado for `godot_integrated`;
- desempenho apenas estimado quando o estado declarado for `device_tested` ou `release_ready`.

## 3. Pontuação visual

Aplicar após os bloqueadores.

| Dimensão | Peso | Critério |
|---|---:|---|
| Cânone | 20 | nome, ID, origem, função, ruleset e símbolos corretos |
| Gameplay | 15 | imagem representa estado e ação reais |
| Silhueta | 10 | reconhecível sem texto e em 25% de zoom |
| Pixel craft | 10 | clusters, contorno, paleta e nearest consistentes |
| Anatomia/biomecânica | 10 | pose, apoio, pegada, carga e reação plausíveis |
| Consistência temporal | 10 | proporção, rosto, roupa e escala estáveis entre frames |
| Composição | 5 | foco, profundidade e leitura sem ruído |
| Mobile | 5 | safe area, contraste e touch adequados |
| Regional/cultural | 5 | específico, contextualizado e respeitoso |
| Licença/origem | 5 | documentação completa e liberada para o uso declarado |
| Integração | 5 | metadata, paths, pivô, import e consumidor real |

### Faixas

- `95–100`: candidato a human approval;
- `90–94`: aprovado para QA técnico, exige correções menores;
- `80–89`: produção candidata, não integrar;
- `<80`: reprovado;
- qualquer bloqueador: reprovado independentemente da nota.

## 4. Gate de personagem

Obrigatório:

- [ ] ID e nome canônicos;
- [ ] função narrativa definida;
- [ ] Gi/No-Gi compatível;
- [ ] altura visual consistente com a escala do elenco;
- [ ] silhueta única;
- [ ] proporções estáveis;
- [ ] rosto reconhecível em retrato e sprite;
- [ ] paleta documentada;
- [ ] sem marca real;
- [ ] turnaround frontal/lateral/costas/3-4;
- [ ] expressões previstas;
- [ ] idle/walk/clinch/ground/victory conforme perfil;
- [ ] preview em fundo claro e escuro;
- [ ] revisão humana.

## 5. Gate de técnica pareada

Obrigatório:

- [ ] técnica existe em `data/techniques.json`;
- [ ] estado de entrada e saída válidos;
- [ ] ruleset permitido;
- [ ] atacante e defensor com o mesmo frame count;
- [ ] shared pivot;
- [ ] linha de contato;
- [ ] antecipação legível;
- [ ] pegada antes de projeção/pressão;
- [ ] centro de massa plausível;
- [ ] pés/mãos não deslizam sem motivo;
- [ ] reação sincronizada;
- [ ] sem clipping crítico;
- [ ] sem teleporte;
- [ ] posição final corresponde ao estado lógico;
- [ ] tap, escape ou intervenção quando finalização;
- [ ] `sync_map.json`;
- [ ] `metadata.json`;
- [ ] preview GIF;
- [ ] revisão biomecânica humana.

### Tolerâncias

- drift de pivô: máximo 1 px na escala nativa;
- diferença de frame count: 0;
- frames sem contato durante fase de controle: 0, salvo transição documentada;
- mudança de escala corporal entre frames: máximo 2% visual;
- clipping aceitável: apenas oclusão intencional registrada.

## 6. Gate de arena

Obrigatório:

- [ ] ID/localização vindos dos dados;
- [ ] tipo e modificadores documentados;
- [ ] fundo distante;
- [ ] arquitetura;
- [ ] plano médio;
- [ ] área jogável;
- [ ] foreground/oclusão;
- [ ] câmera e bounds;
- [ ] colisão;
- [ ] sombra de contato;
- [ ] público/NPCs com densidade escalável;
- [ ] pontos de áudio;
- [ ] variante principal e fallback de baixo custo;
- [ ] sem marca ou órgão real;
- [ ] leitura do lutador preservada;
- [ ] teste de desempenho no alvo.

### Orçamento visual mobile

- máximo de cinco camadas principais simultâneas, salvo perfil específico validado;
- partículas escaláveis por preset;
- luzes animadas limitadas e agrupadas;
- crowd com variantes de baixa densidade;
- texturas sem filtro suave;
- nenhum detalhe de fundo pode competir com a silhueta dos lutadores.

## 7. Gate de HUD

Obrigatório:

- [ ] superfície classificada: runtime, tutorial, menu, codex ou marketing;
- [ ] safe area mínima de 7%;
- [ ] touch targets mínimos equivalentes a 48 dp;
- [ ] contraste suficiente;
- [ ] posição atual visível;
- [ ] ação indisponível apresenta motivo curto;
- [ ] no máximo três escolhas principais simultâneas quando a mão for de três cartas;
- [ ] informação secundária fora do centro de ação;
- [ ] sem textos longos durante luta;
- [ ] modo foco e redução sensorial considerados;
- [ ] leitura em tela pequena;
- [ ] navegação por touch e controle quando aplicável.

## 8. Gate de mapa

Obrigatório:

- [ ] geografia derivada de fonte canônica;
- [ ] Ituberá e demais nós sem duplicidade;
- [ ] rotas terrestres e marítimas diferenciadas;
- [ ] arena vinculada ao nó correto;
- [ ] ícone corresponde a conteúdo implementado;
- [ ] mapa não promete mundo contínuo 3D;
- [ ] versão compacta mobile;
- [ ] texto revisado em pt-BR;
- [ ] ausência de distorção cultural/geográfica não declarada.

## 9. Gate de facção

Obrigatório:

- [ ] somente `ALE`, `LEM`, `NTM`;
- [ ] display names corretos;
- [ ] alias legado não aparece como quarta facção;
- [ ] símbolo ficcional descrito;
- [ ] estandarte completo e variantes compactas;
- [ ] paleta consistente;
- [ ] não associa religião real ou grupo real a crime;
- [ ] texto revisado;
- [ ] badge legível em 32 px;
- [ ] banner legível em arena.

## 10. Gate cultural

Para Zambiapunga, referências quilombolas, japonesas, afro-baianas, cristãs ou de comunidades específicas:

- [ ] origem e contexto documentados;
- [ ] função narrativa não reduzida a decoração;
- [ ] símbolos compreendidos e revisados;
- [ ] nenhum termo pejorativo;
- [ ] nenhuma fusão arbitrária de tradições;
- [ ] pessoa ou consultor local quando necessário;
- [ ] aprovação humana registrada.

## 11. Gate jurídico

- [ ] fonte própria, domínio público ou licença compatível;
- [ ] termos de modelo/dataset verificados quando usados;
- [ ] nenhum frame de transmissão ou aula redistribuído;
- [ ] nenhum logo real;
- [ ] nenhuma pessoa real reconhecível;
- [ ] atribuição registrada quando exigida;
- [ ] hash do master;
- [ ] licença do derivativo;
- [ ] autorização escrita arquivada quando aplicável.

## 12. Gate Godot

- [ ] import sem erro;
- [ ] path canônico;
- [ ] metadata resolvida;
- [ ] texture filter nearest;
- [ ] pivô correto;
- [ ] atlas sem frame faltante;
- [ ] AnimationPlayer/AnimatedSprite configurado;
- [ ] fallback seguro;
- [ ] cena de teste;
- [ ] consumidor real;
- [ ] smoke aplicável;
- [ ] nenhuma dependência de rede.

## 13. Gate Android físico

- [ ] instalação real;
- [ ] carregamento sem textura ausente;
- [ ] mínimo sustentado de 45 FPS no perfil-alvo definido;
- [ ] touch sem sobreposição;
- [ ] texto legível;
- [ ] memória registrada;
- [ ] temperatura observada;
- [ ] bateria observada;
- [ ] redução de flash testada;
- [ ] save/reload não perde seleção visual;
- [ ] screenshots ou vídeo de evidência.

## 14. Relatório de reprovação

Quando reprovar, emitir:

```text
ASSET:
ESTADO:
GATE BLOQUEADO:
EVIDÊNCIA:
RISCO:
CORREÇÃO MÍNIMA:
ARQUIVOS AFETADOS:
PODE SER PRESERVADO COMO REFERÊNCIA?:
PRÓXIMA VERIFICAÇÃO:
```

## 15. Regra de aprovação

A palavra `final`, `oficial`, `integrado`, `pronto`, `shipping` ou `release-ready` só pode ser usada quando o estado correspondente estiver comprovado.