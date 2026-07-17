# Cria do Tatame — Especificação Suprema de Construção v1

Status: contrato de produção ativo. Este documento define o produto final desejado, os limites de autonomia de agentes e as evidências necessárias para declarar uma entrega concluída. O contrato executável correspondente está em `data/production/supreme_build_contract_v01.json`.

## 1. Verdade atual e princípio de execução

O repositório já contém um núcleo Godot funcional, dados de combate, carreira, navegação, validadores, pipeline de sprites, manifesto audiovisual e automação de build. Ele ainda não é o jogo completo: boa parte dos visuais é técnica ou provisória; o elenco, as técnicas, as arenas, a campanha e o áudio não atingiram o volume final; APK em aparelho físico e release assinada continuam sendo gates abertos.

Todo agente deve ampliar o jogo existente em lotes verticais jogáveis. Nenhum relatório, mockup, imagem isolada ou quantidade de arquivos substitui um fluxo executável.

Ordem de autoridade:

1. `AGENTS.md` e este contrato;
2. dados canônicos atuais em `data/`;
3. código e cenas que passam na CI;
4. documentos atuais em `docs/`;
5. PDFs de referência e documentos históricos, usados somente quando não contradizem o canon vigente.

## 2. Identidade inviolável

- Protagonista: Ruan “Macacão” Silva.
- Origem: Ituberá, Baixo Sul da Bahia.
- Símbolo: gorila Silverback.
- Estilo: pressão pesada, pegada forte e domínio por cima.
- Poder: Silverback Grip.
- Frase central: “Ser forte é ser gentil.”
- Visual: HD painted pixel art 2D/2.5D, regional, quente, artesanal e premium.
- Núcleo: Jiu-Jitsu Brasileiro posicional; não é beat’em up de soco e chute.
- Runtime: Godot, determinístico e jogável offline.

Os identificadores históricos registrados em `canon.forbidden_legacy_ids` são bloqueados. Não podem entrar em campanha, UI, save novo ou material promocional final.

## 3. Escopo definitivo do produto

O alvo de release completo é:

| Área | Meta mínima |
|---|---:|
| Personagens jogáveis e rivais com pacote final | 18 |
| Arenas com variantes, colisão, luz e ambiência | 15 |
| Técnicas de BJJ com animação pareada | 50 |
| Atos de carreira | 5 |
| Finais calculados por decisões e reputação | 5 |
| Missões/eventos jogáveis | 40 |
| Superfícies de UI | 18 |
| Efeitos sonoros editados | 100 |
| Cues musicais | 20 |
| Loops de ambiência regional | 12 |

O fluxo mínimo preservado em todas as versões é Main Menu → Terreiro → Combate → Resultado → Save → avanço de semana → Terreiro.

## 4. Vertical slice de ouro

Antes de escalar o conteúdo, uma fatia deve representar a qualidade final:

- Ruan contra Davi Relâmpago na Arena do Dique;
- Mestre Dendê e Tinker presentes no Terreiro;
- HUD desktop e touch com safe area;
- vida, gás, foco, guarda, pegada e controle posicional legíveis;
- queda, guarda, passagem, montada, costas, submissão, tap e escape;
- sprites finais representativos, sombra de contato, VFX e câmera responsiva;
- música, ambiência, UI, impacto, tecido, queda e respiração mixados;
- resultado alimentando reputação, Cria Live, save e calendário;
- export Android ARM64 e teste em aparelho físico.

O restante do jogo só herda um padrão aprovado por essa fatia.

## 5. Arquitetura do combate

O estado de combate é relativo aos dois atletas. Cada técnica declara posição de entrada, requisitos, custo, janelas, resposta do defensor, estado de saída e consequências. O simulador crítico não depende de rede ou IA generativa.

Toda técnica pareada deve possuir:

1. antecipação;
2. entrada;
3. estabelecimento de contato;
4. estabilização;
5. resposta sincronizada do oponente;
6. recuperação ou transição.

Submissões acrescentam preparação, encaixe, pressão técnica controlada, tap ou escape e intervenção/recuperação. Marcadores de sincronização vinculam pegadas, quadril, base, impacto no chão e mudança de estado. O atacante e o defensor são exportados separadamente, mas compartilham tempo, pivô e IDs de evento.

Não aceitar:

- teleporte entre poses;
- membros atravessando corpo ou tatame;
- finalização sem preparação e resposta;
- posição visual diferente do estado lógico;
- violência gráfica incompatível com a classificação desejada;
- técnica biomecanicamente duvidosa sem revisão de referência.

## 6. Pacote final de personagem

Cada personagem precisa de uma ficha visual canônica, proporções, silhueta, paleta, leitura em 25%, expressões, quimono/roupa, variantes de faixa e regras de dano/sujeira. O pacote inclui:

- model sheet frontal, perfil, costas e três quartos;
- escala comparativa com Ruan;
- retratos neutro, foco, esforço, vitória e derrota;
- idle respirando, deslocamentos, pivôs e mudança de base;
- entradas, defesa, quedas e recuperações;
- poses de todas as posições de solo relevantes;
- reações, tap, vitória, derrota e cutscene;
- spritesheet, preview animado, metadados e relatório de QA.

As animações devem preservar rosto, massa, roupa e paleta. Variação estilística entre frames é defeito, não expressão artística.

## 7. Arenas e mundo vivo

Cada arena possui pelo menos: céu/fundo, arquitetura, plano médio, plateia/vida local, área jogável, frente/oclusão, iluminação, colisão, pontos de áudio e variantes. Elementos regionais precisam ser específicos e respeitosos; referências genéricas de “favela tropical” são rejeitadas.

Perfis obrigatórios:

- manhã, tarde/noite ou clima quando fizer sentido;
- densidade de público e reatividade por momento da luta;
- pontos de câmera e limites seguros;
- máscara de oclusão, sombra e contato com o solo;
- ambiência sem emendas audíveis;
- orçamento móvel documentado.

O Terreiro é hub funcional, não cenário estático: NPCs, treino, missão, mapa, calendário, patrocinadores e Cria Live devem convergir nele.

## 8. UI, câmera e VFX

A direção de interface combina preto, grafite, dourado envelhecido e acentos regionais. A leitura vem antes do ornamento.

- HUD comunica estado posicional e recursos sem cobrir pegadas.
- Touch usa alvos de no mínimo 48 dp e respeita recortes/safe areas.
- Focus, hover, pressed, disabled e feedback de erro existem em todo controle.
- Texto suporta localização, escala e contraste.
- Câmera prioriza os dois corpos e reduz shake em acessibilidade.
- VFX reforçam timing e controle; não escondem a técnica.
- Retratos e ícones mantêm a mesma gramática do sprite em jogo.

As 18 superfícies incluem menu, save, Terreiro, mapa, calendário, treino, preparação, HUD, pausa, tutorial, resultado, Cria Live, reputação, inventário/equipamento, técnicas, patrocinadores, configurações e créditos.

## 9. Áudio completo

O áudio final é produzido em stems e fontes lossless, exportado para formatos de runtime e acompanhado de licença/metadados.

Famílias mínimas:

- tecido, pegada, passo, tatame, queda e deslizamento;
- esforço, respiração e reações sem repetição mecânica;
- UI, recompensa, erro e transição;
- plateia com intensidade orientada por estado;
- ambiências de Terreiro, Dique, mangue, rua, academia e eventos;
- música de menu, hub, treino, rival, pressão, vitória, derrota e narrativa.

Regras de mix:

- evitar clipping e normalizar loudness por categoria;
- sidechain discreto para fala/tutorial;
- limitar vozes simultâneas no Android;
- loops sem clique e sem silêncio acidental;
- nenhum sample ou voz sem origem e licença rastreáveis;
- opções separadas para master, música, SFX, voz e ambiência.

## 10. Pipeline gráfico e audiovisual

1. Ler canon, manifesto e ficha do asset.
2. Reunir referências permitidas e registrar origem.
3. Gerar thumbnails/conceitos; não integrar conceito cru.
4. Selecionar uma direção e consolidar model sheet/paleta.
5. Produzir frames-chave e sincronização biomecânica.
6. Interpolar e limpar manualmente contornos, pivôs e contato.
7. Exportar fonte, atlas, preview e metadados.
8. Importar no Godot com preset determinístico.
9. Testar em arena real, escala real e câmera real.
10. Executar QA visual, técnico, licença, performance e canon.

Arquivos finais devem ser reprodutíveis. Prompts, seeds, ferramentas, versões, licenças, edição humana e hashes ficam nos metadados quando IA for usada.

## 11. Ferramentas externas pesquisadas

Ferramentas são aprovadas por função, não copiadas automaticamente para o produto.

| Ferramenta | Licença | Decisão | Uso seguro |
|---|---|---|---|
| Pixelorama | MIT | aprovada | sprites, tiles, timeline e export de atlas |
| Material Maker | MIT | aprovada | fontes de textura procedural; resultado deve ser baked |
| GUT | MIT | avaliar versão fixada | testes GDScript; 9.3.x corresponde ao Godot 4.2 |
| Dialogue Manager | MIT | branch de avaliação | narrativa; fixar uma versão compatível antes de integrar |
| Modelos/Spaces Hugging Face | específica por modelo | pesquisa | conceito offline; exige licença e revisão individual |

Integrações MCP seguem estas funções:

- GitHub: versão, issues, revisão, CI e release no repositório oficial.
- Apixel/image generation: conceito e fonte visual com direção humana.
- Hugging Face: pesquisa, avaliação e protótipo offline.
- Sites: showcase e revisão visual; nunca segundo runtime do jogo.

Nenhuma plataforma conectada recebe segredos, build privada ou material de terceiros sem autorização. Nenhuma IA online participa do loop crítico em runtime.

## 12. Performance e plataformas

Android ARM64 é o piso mais restritivo. O alvo é 60 fps e o mínimo aceitável é 30 fps estáveis em aparelhos do perfil definido para QA. O orçamento inicial por combate é 512 MB, atlas até 4096 px e 24 vozes simultâneas. Esses números são limites de partida e devem ser ajustados por profiling real, nunca relaxados por suposição.

Gates por plataforma:

- import headless e parser Godot sem erro;
- navegação por teclado, controle e touch;
- save/load após encerramento abrupto;
- safe area, pausa, retorno do background e áudio interrompido;
- 20 minutos de soak test de combate;
- APK ARM64 instalado por `adb`, hash e relatório do aparelho;
- build Windows abre, luta e fecha sem erro fatal;
- Web é alvo de alcance/showcase, sem substituir Android/Windows.

## 13. Fases executáveis

### P0 — verdade e contratos

Manter dados válidos, backlog honesto, canon auditado e CI verde.

### P1 — vertical slice de ouro

Concluir Ruan vs. Davi com qualidade representativa de release e validar Android físico.

### P2 — elenco-base e Ato 1

Entregar seis personagens, seis arenas, vinte técnicas e Ato 1 completo.

### P3 — campanha completa

Escalar para todas as metas de conteúdo, sem placeholder nos caminhos de shipping.

### P4 — certificação de plataformas

Corrigir performance, input, acessibilidade, saves, matrizes Android e Windows.

### P5 — release candidate

Congelar conteúdo, auditar licenças, gerar builds reproduzíveis, assinar e executar regressão total.

Cada lote deve conter gameplay, visual, áudio, dados, testes e documentação necessários para ser jogado. Tarefas horizontais gigantes sem integração não são aceitas.

## 14. Protocolo autônomo GPT-SOL/Codex

Para cada ciclo:

1. sincronizar e inspecionar o repositório oficial;
2. executar `npm run quality` antes de modificar;
3. selecionar o menor lote vertical prioritário desbloqueado;
4. procurar implementação equivalente e preservar IDs;
5. implementar dados, runtime e assets sem introduzir outra engine;
6. executar fila e validações específicas;
7. testar o fluxo afetado no Godot;
8. registrar evidência, limitações e licenças;
9. executar `npm run quality` novamente;
10. criar commit focado e atualizar o GitHub quando autorizado.

O agente deve parar e pedir decisão quando houver conflito de canon, licença incerta, ação destrutiva, biomecânica insegura, mudança de público/classificação, gasto externo ou credencial ausente. Autonomia não autoriza inventar evidência nem publicar fora do escopo.

## 15. Quality gates e Definition of Done

O comando central é `npm run quality`. Além dele, release exige:

- import e parser Godot headless;
- smoke Main Menu → Terreiro → Combate → Resultado → Save;
- roundtrip de save e avanço de semana;
- revisão de canon e conteúdo regional;
- auditoria de licenças de todo asset;
- auditoria de loudness e loops;
- ausência de placeholder no caminho de shipping;
- teste de acessibilidade;
- export Android ARM64 e teste em aparelho físico;
- smoke do build Windows;
- artefatos, hashes e relatórios reproduzíveis.

“Jogo completo”, “arte final”, “áudio final”, “APK pronto” e “release ready” só podem ser usados quando todos os gates correspondentes possuírem evidência. Até lá, o status correto é núcleo, vertical slice, alpha, beta ou release candidate, conforme o que realmente passou.

## 16. Próxima ordem de produção

1. Fechar a vertical slice de ouro e substituir placeholders de Ruan, Davi, Dendê, Tinker e Arena do Dique.
2. Produzir áudio representativo dessa fatia e integrar estados de intensidade.
3. Validar touch, performance, save e APK em aparelho real.
4. Congelar a bíblia visual e os templates aprovados.
5. Escalar por rival/arena/arco, sempre com técnicas pareadas e QA.

Este documento é deliberadamente exigente: ele transforma “construir tudo” em um caminho verificável, preserva a identidade do jogo e impede que volume aparente seja confundido com qualidade de produto.
