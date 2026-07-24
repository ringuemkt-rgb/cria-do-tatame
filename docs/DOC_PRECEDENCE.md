# DOC_PRECEDENCE — Ordem de autoridade documental

**Status:** canônico  
**Atualizado em:** 2026-07-24

Este arquivo resolve conflitos entre documentos, dados, código e memória de agentes.

## Ordem de autoridade

1. **Contrato supremo do produto e gates de release**
   - `docs/CRIA_DO_TATAME_SUPREME_BUILD_SPEC_V1.md`
   - `data/production/supreme_build_contract_v01.json`
2. **Processo e gestão**
   - `docs/GAME_BUILD_PROTOCOL.md`
3. **Cânone narrativo e gameplay atual**
   - GDD-CDT v4.x
   - GDD-SYSTEMS v4.x
   - decisões canônicas explicitamente aprovadas em `docs/canon/`
4. **Contratos técnicos e visuais vigentes**
   - ADRs atuais
   - schemas em `data/`
   - CPS/Reconciliation/brand book vigentes
5. **Runtime e dados que passam nos gates**
   - código Godot, cenas e dados integrados
   - testes, migrações e manifests correspondentes
6. **Documentos de entrada**
   - `AGENTS.md`
   - README
   - guias resumidos de contribuição
7. **Histórico**
   - versões antigas, mocks, prompts, PDFs e branches aposentadas

## Regra de conflito

Quando duas fontes da mesma camada divergem:

1. preferir a versão explicitamente marcada como mais recente e canônica;
2. verificar o runtime e os contratos consumidores;
3. registrar o conflito em issue ou PR;
4. não implementar até existir decisão ou adapter/migração documentada.

Memória de modelo, conversa anterior ou interpretação pessoal nunca supera arquivo canônico versionado.

## Separação de responsabilidades

- O SUPREME define **o produto final e as evidências de conclusão**.
- O GAME_BUILD_PROTOCOL define **como planejar, implementar, integrar, verificar e gerir**.
- Os GDDs definem **narrativa, regras, conteúdo e experiência**.
- Dados e schemas definem **contratos executáveis**.
- Código e cenas implementam esses contratos, mas não podem silenciosamente reescrever o cânone.

## Alterações nesta precedência

Qualquer mudança exige:

- commit `docs(protocol):` ou `docs(canon):`;
- justificativa no PR;
- atualização das referências cruzadas;
- validação da skill do diretor;
- aprovação do dono do projeto.