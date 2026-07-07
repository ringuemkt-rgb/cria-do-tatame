# Cria do Tatame - Pipeline de Material Grafico v0.1

## Objetivo

Organizar todo o material grafico do jogo para producao com IA, revisao tecnica e integracao no Godot.

## Arquivos adicionados

- `data/visual/graphic_asset_catalog_v01.json`
- `prompts/visual/GRAPHIC_ASSET_PROMPTS_MASTER_V01.md`
- `tools/ai_asset_pipeline/build_graphic_asset_queue.py`

## Familias de assets

### Personagens

Sprites e portraits para Ruan Macacao, Mestre Dende, Tinker Bell, Davi Relampago, Cassio Molho, Kenzo Kuroi, Leoa Quilombola e Oni da Lapa.

### Golpes

Cards, icones, thumbnails e spritesheets para Grip de Ferro, Baiana, Guarda Fechada, Raspagem Tesoura, Knee Cut, Cem Quilos, Montada, Kimura, Triangulo e Mata Leao.

### Arenas

Cada arena deve ter 5 camadas: `bg_far`, `bg_mid`, `play_area`, `foreground`, `particles`.

### UI

Menu, HUD, botoes mobile, cards de tecnica, Cria Live, mapa, resultado, save, dialogo e painel de faccao.

### Marketing

Key art, capa vertical, banner, icone, poster, infografico, carousel e frames de trailer.

## Comando para gerar fila

```bash
python tools/ai_asset_pipeline/build_graphic_asset_queue.py
```

Saida:

```text
tools/ai_asset_pipeline/generated_queue/graphic_asset_queue_v01.jsonl
```

## Regra de ouro

As imagens devem vir sem texto longo embutido. O Godot renderiza nomes, custos, categorias e descricoes.

## QA visual

- silhueta clara em celular;
- sem marcas reais;
- sem texto IA torto;
- Ruan reconhecivel;
- tecnica esportiva segura;
- fundo separado por camadas;
- UI com safe area;
- contraste preto/dourado forte.

## Ferramentas conectadas

- GitHub: fonte oficial do catalogo, prompts e scripts.
- Pipedream: tentativa de geracao direta de imagem, indisponivel nesta sessao por bloqueio de MCP.
- VEED: tentativa de listar avatars/vozes, bloqueada pela seguranca nesta sessao.
- Vercel: workspace verificado; nao havia projeto ativo para publicar galeria.
- HubSpot: conectado, mas sem funcao direta para criar assets graficos do jogo.
- Replit: recomendado para criar uma futura galeria interativa dos assets, mas nao foi acionado para evitar travar a resposta final e porque a fonte canonica precisa ficar no GitHub.
