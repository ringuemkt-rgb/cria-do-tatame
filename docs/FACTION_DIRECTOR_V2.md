# Faction Director v2 — Cria do Tatame

## Visão

O Faction Director transforma as facções do jogo em organizações persistentes que continuam agindo mesmo quando Ruan está em outro hub. O sistema foi construído sobre o World Director existente e mantém compatibilidade com missões que usam apenas `FactionManager.relations` e `FactionManager.heat`.

## Facções ativas

1. Terreiro da Luta;
2. Os Aleluia;
3. Lá Ele Mil Vezes;
4. Nós Tem Um Molho;
5. Casa da Leoa — Raiz do Baixo Sul;
6. Tríade Dragão Vermelho;
7. Agência Fantasma.

Circuito Oficial, Cria Live e Atalhos continuam existindo como instituições, arenas de influência e forças narrativas, mas não executam operações políticas próprias.

## Poder multidimensional

Cada facção possui valores entre 0 e 100 para:

- território;
- caixa;
- influência;
- medo;
- inteligência;
- coesão;
- força marcial.

A média define o nível sistêmico: colapso, presença local, potência regional, domínio territorial ou hegemonia.

## Identidade dramática

Cada organização possui:

- desejo;
- medo;
- tabu;
- pergunta moral;
- face pública;
- face oculta;
- líder;
- hierarquia;
- candidatos à sucessão;
- doutrina de combate;
- tipos preferidos de dívida e favor.

Esses campos orientam a seleção de operações e impedem que todas as facções se comportem da mesma maneira.

## Operações semanais

Quando uma semana termina, cada facção sem operação ativa escolhe uma ação compatível com seus recursos e personalidade. Exemplos:

- proteger a comunidade;
- formar um campeão;
- recrutar;
- lançar campanha pública;
- investigar;
- infiltrar;
- espalhar rumor;
- controlar evento;
- comprar influência;
- pressionar rival;
- expandir território;
- negociar trégua;
- conter crise.

As operações possuem custo, duração, requisitos, alvo, efeitos e consequências públicas e ocultas. A escolha é determinística por semana e estado do save, permitindo reprodução em QA.

## Guerra e diplomacia

Relações entre organizações percorrem:

1. desconfiança;
2. vigilância;
3. provocação;
4. disputa indireta;
5. retaliação;
6. guerra aberta;
7. trégua;
8. reorganização.

A intensidade muda conforme operações, conquistas territoriais, ações do jogador e planos externos validados. Guerra aberta é um estado político do mundo, não uma autorização para substituir a IA local de combate.

## Territórios funcionais

Cada território possui:

- proprietário;
- recurso produzido;
- valor estratégico;
- controle;
- apoio popular;
- segurança;
- renda;
- tags de evento;
- facções interessadas;
- influência acumulada por desafiante.

Uma mudança de domínio exige presença acumulada. O território não troca de cor por um único sorteio.

## Memória histórica

O sistema registra:

- operações iniciadas e resolvidas;
- resultados de combate de campeões;
- ações do jogador;
- testemunhas;
- violações de tabu;
- mudanças de liderança;
- ganhos territoriais.

Diálogos, cenas e missões podem consultar `get_recent_memories()` para recuperar consequências antigas.

## Dívidas e favores

`add_debt()` registra dívidas de honra, proteção, família, imagem, contrato, política, informação, segredo ou dinheiro. A dívida contém credor, valor, semana de criação, prazo, nota e status.

O sistema não movimenta dinheiro real nem blockchain. Trata-se de uma mecânica narrativa interna.

## Sucessão

Quando coesão cai abaixo do limite, a crise sobe demais ou o líder fica indisponível, o diretor avalia candidatos por ambição, lealdade e ruído determinístico. A mudança de líder altera memória, coesão e futuros ganchos, preservando a existência da organização.

## Campeões adaptativos

Cada facção mantém um campeão sistêmico com:

- nível;
- adaptação;
- moral;
- risco de lesão narrativo;
- especialização;
- semanas de treinamento.

Derrotas contra Ruan aumentam adaptação. O Faction Director prepara a estratégia geral, mas a escolha de técnicas continua no `RivalAIManager` e nos perfis locais autorizados.

## Cria Live

Publicações agora carregam métricas de:

- alcance;
- credibilidade;
- polarização;
- hype;
- rejeição;
- apoio comunitário;
- interesse de patrocinadores;
- atenção das autoridades.

Operações podem produzir posts públicos, crises ou desinformação narrativa. A Agência Fantasma publica somente mensagens indiretas, preservando sua identidade.

## Pressão Regional

Cinco eixos formam o equivalente autoral a um sistema de pressão do mundo:

- atenção pública;
- vigilância das facções;
- desconfiança comunitária;
- interesse das autoridades;
- exposição digital.

O nível varia de 0 a 5. Em níveis altos, o Cria Live publica reação regional e cenas futuras podem restringir eventos, viagens ou contatos.

## Integração com IA externa

`FactionAIPlanBridge` recebe apenas `faction_pressure` já validada pelo World Director. O valor é limitado e convertido em calor e medo sistêmico. A IA remota não pode:

- criar facções canônicas;
- trocar líderes diretamente;
- conquistar território diretamente;
- controlar golpes;
- executar ações por frame;
- escrever chaves ou segredos no cliente.

## Persistência

O save v4 armazena:

- estado legado das relações;
- estado completo do Faction Director;
- feed e métricas do Cria Live;
- mundo vivo;
- NFTs cosméticos opcionais;
- demais sistemas anteriores.

Saves antigos são migrados: novas facções recebem valores padrão sem apagar relações existentes.

## APIs principais

```gdscript
FactionDirectorManager.advance_faction_week()
FactionDirectorManager.get_faction("terreiro")
FactionDirectorManager.get_territory("arena_do_dique")
FactionDirectorManager.get_conflict("os_aleluia", "nos_tem_um_molho")
FactionDirectorManager.register_player_action(...)
FactionDirectorManager.add_debt(...)
FactionDirectorManager.settle_debt(...)
FactionDirectorManager.violate_taboo("nos_tem_um_molho")
FactionDirectorManager.get_recent_memories("fantasma", 8)
```

## QA

```bash
pytest -q tests/test_faction_director_data.py
godot --headless --path . --script res://tests/faction_director_smoke.gd
```

O workflow `Faction Director QA` valida dados, contratos, importação Godot e simulação de semanas, operações, memória, dívidas e save.
