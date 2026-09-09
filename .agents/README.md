# Agentes do Projeto

Este diretório contém apenas skills, instruções e recursos operacionais diretamente vinculados à construção de **Cria do Tatame – Pressão**.

Regras:

- `AGENTS.md` na raiz continua sendo a entrada obrigatória;
- skills não substituem contratos em `data/production/` nem o cânone ativo;
- nenhum agente pode declarar conclusão sem evidência de integração e teste;
- não armazenar prompts de outros produtos, credenciais, conversas exportadas ou saídas brutas;
- toda skill adicionada deve possuir versão, finalidade, limites e validação.

## Skills instaladas

- `skills/cria-art-direction/SKILL.md` — direção visual mestre para personagem, sprite, técnica, arena, mapa, UI, carta, ícone e cena; aplica cânone, tokens, QA, rights e `shipping=false` por padrão.
- `skills/cria-sprite-forge/SKILL.md` — consistência quantitativa e handoff técnico de sprites/animações para o Asset Pipeline v2.

Para trabalho de sprite/animação, use as duas: `cria-art-direction` define o **que deve parecer**; `cria-sprite-forge` define **como manter consistência e entregar tecnicamente**.
