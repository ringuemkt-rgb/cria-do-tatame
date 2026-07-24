# Grupos aposentados — memória de desenvolvimento

Este arquivo preserva contexto histórico de versões antigas sem reintroduzir entidades no runtime.

## Dragão Vermelho

- **Status:** aposentado.
- **ID legado:** `dragao_vermelho`.
- **Uso permitido:** menção de lore sobre grupos anteriores, memória migrada de saves antigos ou documentação histórica.
- **Uso proibido:** facção ativa, território, reputação canônica, operação, campeão, enum, condição de final ou conteúdo acusatório associado a grupo real.

## Fantasma

- **Status:** aposentado.
- **ID legado:** `fantasma`.
- **Uso permitido:** menção de lore sobre uma estrutura anterior apagada/absorvida, memória migrada de saves antigos ou documentação histórica.
- **Uso proibido:** facção ativa, território, reputação canônica, operação, campeão, enum, condição de final ou conteúdo que ensine atividade clandestina.

## Regra de runtime

O domínio ativo contém somente:

- `LEM` — Lá Ele Mil Vezes;
- `NTM` — Nós Tem Um Molho;
- `ALE` — Os Aleluiados.

Saves antigos podem registrar que o jogador conheceu um grupo aposentado, mas sua reputação, calor, território e operações não sobrevivem como facção. O histórico fica em `legacy_lore` e nunca retorna ao `FactionDirectorV3`.
