# Tool Routing — Cria do Tatame

## Princípio central

Escolher a ferramenta que produz evidência verificável e deixa o projeto em estado reproduzível. Não usar ferramenta apenas porque está disponível.

## GitHub

Usar para:

- ler e modificar código e dados;
- criar branches, commits, issues e PRs;
- consultar workflows, artifacts e logs;
- registrar decisões, migrações e riscos;
- consolidar trabalho de agentes.

Regras:

- confirmar repositório e branch antes de escrever;
- reler SHA antes de atualizar arquivo alterado;
- não escrever em `main` sem autorização;
- não apagar repositório ou arquivo útil por inferência;
- não fechar PR útil antes de absorver ou documentar descarte.

## Godot e terminal

Usar para:

- import e parse;
- testes headless;
- auditoria de autoloads e recursos;
- export Android, PC e Web;
- captura de logs e métricas;
- validação de cena e runtime.

Regras:

- preferir comandos versionados no repositório;
- não mascarar exit code;
- salvar logs em `reports/`;
- distinguir falha de ambiente de falha do projeto.

## Python e scripts

Usar para:

- validar JSON e schemas;
- lint de cânone;
- migração e auditoria de dados;
- normalização de sprites;
- geração de manifests;
- relatórios determinísticos.

Regras:

- biblioteca padrão quando suficiente;
- dependências fixadas quando necessárias;
- scripts destrutivos devem possuir dry-run;
- saída deve ter exit code confiável.

## Geração e edição de imagens

Usar para:

- conceito visual;
- assets por lote aprovado;
- variações de pose, personagem, arena, UI e VFX;
- correção ou transformação de imagem fornecida.

Regras:

- seguir o cânone visual da skill;
- até dez imagens homogêneas por lote;
- uma âncora visual por lote;
- sem pessoa real, marca, texto embutido, arma de fogo ou gore;
- não declarar asset final antes de normalização, integração e QA.

## Pipeline de sprites

Usar para:

- strips e spritesheets;
- pivôs e anchors;
- transparência;
- escala e alinhamento;
- preview de animação;
- nomenclatura e manifest.

Regras:

- atacante e defensor devem compartilhar timeline coerente;
- não interpolar biomecânica impossível;
- validar primeiro/último frame e looping;
- preservar fonte e licença.

## Pesquisa web

Usar somente quando necessário para:

- documentação atual de Godot, Android, GitHub e ferramentas;
- licença e origem de bibliotecas/assets;
- informação geográfica, regulatória ou factual externa;
- benchmarks recentes.

Priorizar fonte primária. Registrar data e versão. Não usar pesquisa web para substituir análise do repositório.

## Hugging Face e modelos locais

Usar para:

- explorar modelos e datasets licenciados;
- prototipar ferramentas internas;
- embeddings, reranking e assistência offline não crítica.

Regras:

- fixar modelo, revisão, licença e hash quando incorporado;
- não baixar modelo gigante sem orçamento e objetivo;
- LLM não decide frame crítico de combate;
- sempre fornecer fallback determinístico.

## Ferramentas de design e sites

Figma, Canva, Adobe, Lovable, Replit, Hostinger e equivalentes podem apoiar mockups, documentação e presença web.

Eles não substituem:

- runtime Godot;
- assets-fonte versionados;
- testes;
- export do jogo;
- repositório canônico.

## Documentos, planilhas e apresentações

Usar para relatórios, planejamento, inventário, pitch e materiais didáticos. O estado oficial do jogo deve continuar registrado em arquivos versionados no repositório.

## Credenciais e segredos

Nunca:

- versionar chave API;
- colar token em issue ou PR;
- enviar keystore para ferramenta externa;
- registrar senha em log;
- reutilizar credencial exposta.

Usar variáveis de ambiente, secrets do GitHub e arquivos locais ignorados.

## Matriz de decisão rápida

| Necessidade | Ferramenta principal | Evidência esperada |
|---|---|---|
| Alterar runtime | GitHub + Godot | diff + smoke |
| Alterar dados | GitHub + Python | schema/lint verde |
| Criar sprite | imagem + pipeline | manifest + preview + cena |
| Corrigir build | terminal + CI | log + artifact |
| Gerir escopo | GitHub Issues/PR | critérios e status |
| Pesquisar licença | web primária | fonte, versão e licença |
| Criar material de apresentação | ferramenta de documentos/slides | arquivo exportado |
| Declarar release | Godot + Android físico + GitHub | build instalado + checklist |