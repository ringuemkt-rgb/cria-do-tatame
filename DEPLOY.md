# Deploy do CRIA DO TATAME

Este repositório contém um site estático com HTML, CSS, JavaScript, PWA e assets de pixel art. O fluxo recomendado usa **GitHub Pages** com o workflow em `.github/workflows/pages.yml`.

## Publicação automática

Cada push na branch `main` executa o workflow de Pages. O artefato publicado é o conteúdo da raiz do repositório; não há etapa de build que possa introduzir dependências externas ou alterar os caminhos relativos dos assets.

A URL inicial configurada para a publicação é:

`https://ringuemkt-rgb.github.io/cria-do-tatame/`

O GitHub Pages fornece HTTPS automaticamente. O domínio personalizado pode ser conectado depois nas configurações de Pages, apontando um registro `CNAME` ou `A` conforme as instruções exibidas pelo GitHub.

## Verificação pós-publicação

Depois que o workflow concluir, validar a página inicial, o manifesto, o service worker, um GIF do elenco, o jogo de combate e a página `404.html`. Também é necessário abrir a página em uma janela anônima e testar a instalação PWA, a navegação por teclado e os botões de ação no celular.

## Desenvolvimento local

```bash
python3 -m http.server 4173
```

Abra `http://127.0.0.1:4173/` no navegador. O service worker só deve ser testado em HTTPS ou em `localhost`.

## Domínio próprio

Quando um domínio for escolhido, substituir a URL canônica em `index.html`, o `og:url`, `og:image`, `robots.txt` e `sitemap.xml`. Em seguida, configurar o domínio em **Settings → Pages → Custom domain** e aguardar a emissão do certificado HTTPS.

## Limitações conhecidas

O formulário da página é uma interface estática e não envia dados para um servidor. Para receber mensagens, conectar um endpoint de formulário ou serviço de email em uma etapa posterior. O jogo web e os assets versionados funcionam sem CDN obrigatório; fontes e dependências externas não são necessárias para o carregamento principal.
