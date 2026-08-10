# Neplex Vectorizer — integração de fonte vetorial v1

## Decisão

`@neplex/vectorizer` 0.1.0 está aprovado como **ferramenta externa de fonte vetorial candidata**, nunca como dependência do runtime e nunca como conversor universal da arte do jogo.

O uso correto é estreito:

| Permitido | Bloqueado |
|---|---|
| emblemas de ALE/LEM/NTM | sprites dos lutadores |
| emblemas dos estilos | quadros de grappling pareado |
| ícones de HUD/menu | spritesheets e GIFs |
| marca sem tipografia raster | tiles, vegetação e mapa pixel art |
| diagramas de acessibilidade | arenas, crowd e ilustrações de carta |

O SVG preserva uma fonte escalável para marcas e pictogramas. O runtime continua recebendo PNGs em tamanhos definidos e revisados. Isso mantém clusters de pixel, dithering, contraste em escala pequena, importação previsível no Godot e custo estável no Android.

## Origem auditada

- repositório oficial: `https://github.com/neplextech/vectorizer`;
- pacote: `@neplex/vectorizer@0.1.0`;
- commit declarado pelo pacote: `dd96eea07d1eb6c0c796801a385efbf53d512591`;
- licença: MIT;
- integridade npm: `sha512-J2cfkJG0hmOsC+QiPfkNSe8U68vW5SdaM8PjLMVgacmKfOtZKbU5syz3BqlfYoMlPjJlfzYdxwfH4GiAz5vLUQ==`;
- hash SHA-256 do tarball auditado: `59f2ed520e885bbca4fc72709bc8a2418776c670e1e3d642e9c14ff5cd515c03`;
- motor de traçado declarado pelo projeto: VTracer; otimizador: wrapper de `oxvg_optimiser`.

O pacote publicado foi executado duas vezes sobre o mesmo emblema PNG. As duas saídas tiveram SHA-256 idêntico (`2cf35a...b20e`), 187 bytes, um único `path` e nenhum conteúdo ativo ou referência externa.

O adaptador completo também passou em diretório temporário: verificou o pacote, executou a CLI, auditou dimensões/paths/cores e escreveu `cria-vector-intake.json` mantendo o estado `candidate_vector_source`.

A suíte do checkout-fonte não foi contabilizada como aprovada: naquele estado ela requer primeiro compilar o binding N-API local. A evidência desta integração é o smoke do **pacote publicado e fixado**, que inclui o binding da plataforma. Essa distinção evita registrar um PASS inexistente.

## Playground e privacidade

O playground oficial de exemplo é `twlite/vectorizer-playground`, também MIT. A revisão do código mostrou o arquivo lido como `ArrayBuffer` e enviado para um Web Worker local; não foi observada requisição de upload da imagem. O site usa Vercel Analytics.

Política do projeto:

- arte do projeto não entra no playground hospedado;
- a CLI local é o caminho de produção;
- uma cópia self-hosted só pode ser usada para imagens públicas de teste;
- API ou site jamais entram no runtime do jogo.

## Instalação isolada

Instale fora da árvore do jogo, com versão exata e sem scripts de pacote:

```bash
mkdir -p /tmp/cria-vectorizer
cd /tmp/cria-vectorizer
npm init -y
npm install --ignore-scripts --no-audit --no-fund --save-exact @neplex/vectorizer@0.1.0
```

O adaptador verifica nome, versão, hashes dos arquivos executáveis e `vectorizer --version`. O `gitHead` é preservado no perfil a partir do registro npm; como o npm o remove do `package.json` empacotado, a identidade executável é fechada pelos hashes do pacote. Um pacote que apenas imite a versão é rejeitado.

## Execução controlada

Verifique o pacote:

```bash
python tools/visual/neplex_vectorizer_adapter.py verify \
  --package-root /tmp/cria-vectorizer/node_modules/@neplex/vectorizer \
  --vectorizer-cli /tmp/cria-vectorizer/node_modules/@neplex/vectorizer/cli/index.mjs
```

Planeje sem escrever saída:

```bash
python tools/visual/neplex_vectorizer_adapter.py plan \
  --package-root /tmp/cria-vectorizer/node_modules/@neplex/vectorizer \
  --vectorizer-cli /tmp/cria-vectorizer/node_modules/@neplex/vectorizer/cli/index.mjs \
  --input production/source/ui/lem_emblem.png \
  --batch-id ui_vector_01 \
  --asset-id lem_emblem \
  --profile faction_emblem
```

Execute somente após confirmar direitos e limites:

```bash
python tools/visual/neplex_vectorizer_adapter.py run \
  --package-root /tmp/cria-vectorizer/node_modules/@neplex/vectorizer \
  --vectorizer-cli /tmp/cria-vectorizer/node_modules/@neplex/vectorizer/cli/index.mjs \
  --input production/source/ui/lem_emblem.png \
  --batch-id ui_vector_01 \
  --asset-id lem_emblem \
  --profile faction_emblem \
  --source-rights-confirmed \
  --acknowledge-vector-source-only \
  --acknowledge-local-cli-only
```

A saída só pode existir em:

```text
production/candidates/neplex_vectorizer/<lote>/<asset>/
```

O diretório recebe o SVG e `cria-vector-intake.json` com hashes, comando, contagem de paths/cores e gates pendentes. O estado inicial é `candidate_vector_source`; promoção automática é impossível.

## Auditoria SVG fail-closed

O adaptador aceita somente `svg`, `g` e `path`. Rejeita:

- `script`, `foreignObject`, `image`, `use`, `iframe`, `object`, `embed`, `style` e `text`;
- `href`, `xlink:href`, eventos `on*`, CSS inline, `javascript:`, `data:`, `url()` e `@import`;
- XML com `DOCTYPE`/`ENTITY`;
- dimensões divergentes do PNG;
- tags, atributos, cores ou sintaxe de path fora da lista;
- excesso de bytes, dimensões, cores ou paths por perfil.

O comando usa preset `poster`, configuração de geometria por classe, otimizador `safe` e três passes no máximo. A função `optimize` para SVG arbitrário não é exposta pelo adaptador; só a saída recém-gerada de PNG pode prosseguir.

## Gates para o Godot

Antes de qualquer uso no jogo:

1. confirmar proveniência e direito do PNG fonte;
2. revisar silhueta e paleta contra o STYLE-LOCK;
3. testar legibilidade nos tamanhos reais de UI;
4. manter o SVG como fonte e gerar PNGs específicos por escala;
5. revisar importação, contraste e navegação no Godot;
6. validar no aparelho Android físico;
7. obter aprovação humana.

Para remover a integração, apague o perfil, schema, adaptador, validador e esta página; remova também a decisão `neplex_vectorizer` do SOP e o script de validação do `package.json`. Nenhum runtime ou save é afetado.
