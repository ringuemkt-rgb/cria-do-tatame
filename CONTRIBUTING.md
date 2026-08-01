# Contribuindo com Cria do Tatame – Pressão

Este repositório é a única fonte oficial do jogo. Toda contribuição deve aumentar a capacidade de abrir, jogar, salvar, testar e entregar o produto sem criar sistemas paralelos.

## 1. Antes de começar

1. Leia `README.md`, `AGENTS.md` e `docs/REPOSITORY_GOVERNANCE.md`.
2. Procure implementação, issue ou PR equivalente.
3. Escolha um lote vertical pequeno e observável.
4. Abra ou vincule uma issue com critérios de aceite.
5. Parta de `main`, salvo quando o roadmap declarar uma branch de integração ativa.

## 2. Branches

Use nomes curtos e rastreáveis:

- `fix/<problema>` — correção;
- `feat/<sistema>` — feature jogável;
- `content/<pacote>` — conteúdo, dados ou narrativa;
- `visual/<pacote>` — arte, animação, UI, VFX ou áudio;
- `build/<alvo>` — CI, exportação e release;
- `docs/<tema>` — documentação sem alteração de runtime;
- `chore/<tema>` — manutenção e governança.

Não crie branches genéricas como `teste-final`, `novo`, `backup`, `versao2` ou `final-final-agora-vai`.

## 3. Commits

Use Conventional Commits:

```text
feat(combat): adicionar janela de defesa
fix(save): preservar backup após migração v5
docs(repo): registrar política de branches
visual(ruan): integrar idle aprovado ao Godot
build(android): validar APK ARM64 no CI
```

Cada commit deve ter uma responsabilidade clara e não deve misturar outro produto, e-book, site ou aplicação.

## 4. Regras arquiteturais

- Godot é o único runtime do jogo.
- `main` deve permanecer bootável.
- Gameplay crítico funciona offline e de forma determinística.
- Reutilize managers existentes; migrações usam adapter/fachada.
- Alteração em autoload exige auditoria de boot.
- Dados persistíveis exigem versão e migração de save.
- IDs em `data/` são estáveis e não devem ser renomeados sem mapper.
- Uma classe sem consumidor real, cena, dado ou teste não conta como feature integrada.

## 5. Arte, animação e áudio

- Concept art e arquivos gerados são candidatos, não assets finais.
- Todo pacote final precisa de origem/licença, metadata, preview, QA e integração Godot.
- Técnicas pareadas exigem atacante, defensor, pivô compartilhado, `sync_map` e revisão biomecânica.
- Não use pessoas, marcas, logos, frames ou áudios de terceiros sem autorização compatível.
- Não versionar modelos, checkpoints, caches ou saídas brutas gigantes sem justificativa aprovada.

## 6. Validação mínima

Execute antes de abrir ou atualizar um PR:

```bash
npm run quality
```

Quando aplicável, inclua também:

```bash
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/runtime_smoke.gd
```

Mudanças Android exigem exportação e, no gate de release, teste em aparelho físico.

## 7. Pull requests

Todo PR deve:

- ter escopo pequeno;
- explicar integração e consumidor real;
- listar testes e resultados;
- registrar riscos e rollback;
- indicar impacto em save, dados, autoloads e cânone;
- incluir evidência visual quando altera UI ou assets;
- manter checks verdes antes do merge.

PRs empilhados precisam declarar a dependência no corpo e não podem permanecer indefinidamente sobre uma base abandonada.

## 8. Definition of Done

Uma entrega só está concluída quando:

- está integrada ao fluxo oficial;
- passa os gates obrigatórios;
- não quebra save ou migração;
- possui documentação proporcional ao risco;
- não depende de segredo ou serviço externo para o loop principal;
- não chama placeholder, mockup ou fila de produção de produto final.

## 9. Segurança

Nunca envie tokens, chaves, `.env`, keystore, senha, dados pessoais ou credenciais. Em caso de exposição, remova o segredo do provedor imediatamente e siga `SECURITY.md`.
