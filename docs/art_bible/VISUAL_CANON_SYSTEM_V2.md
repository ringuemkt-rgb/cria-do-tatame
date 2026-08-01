# Sistema Canônico Visual v2 — Cria do Tatame

**Status:** CANONICAL  
**Atualizado:** 2026-08-01  
**Contrato:** `data/visual/visual_canon_contract_v2.json`  
**Skill:** `.agents/skills/cria-visual-canon-director/SKILL.md`

## 1. Objetivo

Este documento transforma o acervo de imagens conceituais do projeto em um sistema de produção coerente, repetível e verificável. Ele não declara que os mockups recebidos são assets finais. Ele determina como aproveitar o melhor dessas imagens sem importar erros de cânone, geografia, gameplay, licença, cultura, interface ou desempenho.

A direção aprovada é:

> **HD painted pixel art 2D com apresentação 2.5D regional premium.**

A arte final continua 2D. A profundidade vem de parallax, camadas, oclusão, sombras de contato, partículas, iluminação 2D e câmera. Bloqueios 3D podem apoiar pose e perspectiva, mas não substituem o acabamento pixel art.

## 2. Fontes de autoridade

| Categoria | Fonte principal |
|---|---|
| Cânone geral | `data/production/canon_contract_v4_1.json` |
| Facções e aliases | `data/production/faction_migration_v4_2.json` |
| Marca e logo | `data/visual/brand_identity_v01.json` |
| Sistema visual | `data/visual/visual_canon_contract_v2.json` |
| Inventário audiovisual | `data/visual/production_manifest_v02.json` |
| Personagens | `data/characters.json` |
| Arenas | `data/arenas.json` |
| Facções | `data/factions.json` |
| Técnicas | `data/techniques.json` |
| Auditoria do acervo | `data/visual/reference_audit_v2.json` |

A imagem mais bonita não supera esses contratos.

## 3. Cânone visual protegido

- Protagonista: **Ruan “Macacão” Silva**.
- Origem: Ituberá, Baixo Sul da Bahia.
- Símbolo: gorila Silverback.
- Estilo: pressão, pegada e top game.
- Frase eixo: **Ser forte é ser gentil.**
- Facções ativas: `ALE`, `LEM`, `NTM`.
- Nome de exibição de `ALE`: **Os Aleluiados**.
- Logo: Silverback frontal, coroa dourada, kimono preto, emblema circular, preto/branco/dourado.
- Núcleo visual do combate: Jiu-Jitsu posicional, não MMA, luta de rua ou beat’em up.
- Finalizações: tap, escape ou intervenção técnica.
- Técnicas: somente IDs presentes em `data/techniques.json`.

## 4. Tokens de produção

| Token | Valor |
|---|---:|
| Altura nominal do lutador em combate | 72 px |
| Célula de personagem no hub | 64 px |
| Grade de produção | 16 px |
| Contorno nominal | 1 px |
| Rim light nominal | 1 px |
| Filtro | nearest |
| Safe area mobile | 7% |
| Touch target mínimo | 48 dp |
| FPS mínimo sustentado do gate | 45 |
| Lote máximo | 10 imagens do mesmo tipo |

Paleta estrutural:

```text
#0A0A0A  #1A1A1A  #B8860B  #F2C230  #F2F2F2
#D92323  #1E3A5F  #2D5016  #4B0082
```

Extensões precisam ser documentadas no metadata do personagem, arena ou facção.

## 5. O que o acervo visual representa

### Referência de alto valor

O acervo define corretamente:

- ambição de acabamento;
- força das silhuetas;
- atmosfera regional;
- composição de personagem;
- identidade de arenas;
- linguagem editorial premium;
- mapa ilustrado como visão de mundo;
- estandartes de facção;
- importância de Gi e No-Gi;
- animações de controle e posição como centro visual.

### Não é evidência de runtime

As imagens não comprovam:

- cena Godot funcional;
- mapa navegável;
- animação pareada completa;
- touch utilizável;
- performance Android;
- licença comercial;
- biomecânica correta;
- técnica existente no catálogo;
- localização canônica;
- save ou progressão integrados.

## 6. Estados obrigatórios do asset

```text
reference_only
→ canon_reconciled
→ production_candidate
→ qa_passed
→ human_approved
→ godot_integrated
→ device_tested
→ release_ready
```

Nenhum estado pode ser pulado. Imagem gerada por IA começa, no máximo, como `production_candidate`.

## 7. Personagens

As pranchas de personagem devem ser produzidas como **Character Bible**, separadas do HUD runtime.

Cada personagem exige:

- ID e nome canônicos;
- função narrativa;
- origem;
- faixa por ato ou modo;
- perfil Gi/No-Gi;
- silhueta;
- paleta;
- turnaround;
- expressões;
- retrato;
- core animations;
- técnicas existentes;
- licença/origem;
- revisão humana.

### Correções fixas do acervo

- Ruan “Cria” → **Ruan “Macacão”**.
- Leoa não usa cabelo como arma; a ação vira arm drag, desequilíbrio ou tomada das costas.
- Cássio não usa joelhadas; sua pressão vira clinch, snapdown, body lock, queda e controle.
- Kenzo não é caricatura criminal japonesa; é rival técnico e estrategista nipo-brasileiro.
- Delegado não usa símbolo, sigla ou uniforme de polícia real; sua instituição é ficcional.
- Jacaré não é definido por lutar sujo; é pressão de sobrevivência com respeito técnico.
- Guigo é treinador avançado de No-Gi e não substitui Dendê como mentor moral.
- Davi Relâmpago permanece distinto de qualquer outro personagem chamado Davi.

## 8. Técnicas e animações

Toda técnica é animação pareada.

Obrigatório:

- atacante e defensor;
- mesma quantidade de frames;
- pivô compartilhado;
- contato documentado;
- pegada antes da força;
- antecipação, entrada, controle e saída;
- reação plausível;
- estado final coerente;
- sem teleporte;
- sem clipping crítico;
- sem lesão como espetáculo;
- revisão biomecânica.

GrappleMap pode apoiar grafo, pose e sequência esquemática. Não é autoridade de timing real, técnica de Gi ou biomecânica final.

## 9. Arenas

Cada arena precisa ser derivada dos dados e possuir:

1. fundo distante;
2. arquitetura/paisagem;
3. plano médio e público;
4. área jogável;
5. foreground/oclusão;
6. câmera e bounds;
7. colisão;
8. sombra de contato;
9. áudio;
10. orçamento mobile.

### Decisões principais

- **Terreiro da Luta:** hub de Ituberá, madeira, rio, mangue, comunidade e treino.
- **Arena do Dique:** circuito oficial em Salvador segundo os dados atuais; remover órgãos, federações e patrocinadores reais.
- **Budokan das Águas:** precisão, silêncio e arquitetura ficcional nipo-baiana; revisar japonês.
- **Zambiapunga:** festa, memória e comunidade; exige revisão cultural local e não pode virar “arena tribal”.
- **Pancada Grande:** contexto de Ituberá/Baixo Sul; luta em plataforma ficcional segura próxima à cachoeira, não sobre rocha letal.
- **Manguezal, Pratigi e Ferro Velho:** manter identidades e IDs distintos.

## 10. HUD

Não existe um único HUD para todas as imagens. O sistema separa:

- combate runtime;
- finalização runtime;
- tutorial/codex;
- menu de personagem;
- art bible;
- material promocional.

### Combate runtime

Prioridade:

- posição atual;
- gás;
- controle posicional;
- foco ou fluxo quando relevante;
- tempo/pontos conforme ruleset;
- três cartas ou comandos contextuais.

Pranchas densas de posição, risco e recompensa pertencem ao tutorial/codex, não à luta em tempo real.

## 11. Mapas

O modelo aprovado é **mapa regional por nós e rotas**.

- Ituberá é o núcleo narrativo.
- Hubs e arenas são instanciados.
- Rotas terrestres e marítimas são distintas.
- Salvador não deve ser desenhada como se estivesse dentro do Baixo Sul.
- Cidade ou arena não pode aparecer duplicada.
- O mapa só exibe conteúdo implementado.
- A ilustração não é autoridade cartográfica.
- O produto não promete mundo aberto contínuo 3D.

## 12. Facções

| ID | Exibição | Direção |
|---|---|---|
| `ALE` | **Os Aleluiados** | azul, branco, dourado; pomba e cruz abstratas ficcionais |
| `LEM` | Lá Ele Mil Vezes | vermelho, roxo, dourado; olho e mão abstratos |
| `NTM` | Nós Tem Um Molho | amarelo, laranja, vermelho; pimenta, pilão e molho ficcional |

O ID legado `os_aleluia` permanece como alias técnico. A atualização é visual/textual, não uma quarta facção ou migração destrutiva.

Cada facção precisa de:

- estandarte;
- emblema quadrado;
- badge circular;
- ícone 32 px;
- banner de arena;
- patch Gi/No-Gi;
- variante monocromática;
- metadata do símbolo ficcional.

## 13. Gi e No-Gi

No-Gi não é apenas trocar kimono por rashguard. A arte e a animação precisam refletir:

- ausência de pegadas de tecido;
- pummeling e body locks;
- silhueta e materiais;
- atrito;
- som;
- técnicas válidas;
- entradas e controles próprios.

Uma variante visual só é declarada jogável após o ruleset estar integrado ao combate, save, missão e HUD.

## 14. Segurança jurídica e cultural

Bloqueadores:

- pessoa real sem autorização;
- logo real;
- polícia, prefeitura, federação, academia ou patrocinador real;
- frame de transmissão ou aula redistribuído;
- estereótipo religioso, japonês, quilombola ou afro-baiano;
- uso de tradição viva como decoração ou magia genérica;
- japonês não revisado;
- origem/licença ausente.

O logo oficial continua bloqueado para shipping até remoção do wordmark de terceiro identificado nos óculos.

## 15. Pipeline

```text
referência
→ reconciliação canônica
→ contrato visual
→ produção candidata
→ limpeza pixel art
→ QA automático
→ revisão humana
→ integração Godot
→ teste Android físico
→ release
```

A produção visual utiliza o manifesto e o catálogo existentes. Esta camada não cria outro runtime, registry ou pipeline concorrente.

## 16. Ordem oficial de produção

1. limpeza jurídica da marca e derivados;
2. Ruan Macacão Gi/No-Gi;
3. Davi Relâmpago Gi/No-Gi;
4. Arena do Dique;
5. Terreiro da Luta;
6. HUD mobile reduzido;
7. oito técnicas pareadas do vertical slice;
8. Submission HUD;
9. áudio e VFX representativos;
10. Android físico;
11. expansão por pacote vertical.

Pacote vertical:

```text
rival + arena + técnicas + áudio + missão + QA
```

## 17. Gate automático

Executar:

```bash
python .agents/skills/cria-visual-canon-director/scripts/validate_skill.py
python tools/audit/validate_visual_canon_v2.py
python -m pytest -q tests/test_visual_canon_skill_v2.py
npm run validate:visual-canon
npm run quality
```

A CI deve impedir regressão de nomes, estilo, estados de asset, batch policy, fontes de verdade, integração e segurança.

## 18. Limites honestos

Este sistema entrega direção, contrato, auditoria, skill e QA. Ele não declara que:

- os personagens estão finalizados;
- as 50 técnicas estão animadas;
- as arenas estão integradas;
- o mapa está jogável;
- a arte atingiu aprovação humana;
- o Android físico foi testado;
- o logo está comercialmente liberado.

Esses resultados serão construídos em lotes posteriores e só avançarão quando houver evidência.