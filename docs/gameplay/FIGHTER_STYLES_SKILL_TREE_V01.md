# Estilos de Lutador + Arvore de Habilidades V2

**Status:** IMPLEMENTED — vertical slice funcional; direcao radial final e teste Android ainda pendentes.
**Versao:** 1.0.0

## Decisao de integracao

A prancha da roda de oito cores foi tratada como arquitetura de informacao, nao como canon automatico. A implementacao preserva as autoridades reais:

- dados em `DataRegistry`;
- pontos em `WorldState.skill_points`;
- niveis e estilo ativo dentro de `WorldState.story_flags`, ja coberto pelo save v5;
- simulacao em `CombatManager`;
- consequencia social em `CriaLiveManager`;
- nenhum novo autoload ou moeda paralela.

O estilo padrao e `pressao`, coerente com Ruan “Macacao” Silva. A afinidade LEM/NTM/ALE serve somente para reacao narrativa e nunca altera a faccao do jogador.

## Fluxo jogavel

```text
Terreiro → Estilos e Progressao
→ gastar skill_points em 4 ramos × 4 nos
→ liberar/ativar uma das 8 vias
→ iniciar luta
→ bonus limitados de recurso inicial e chance por familia
→ recompensa e tom do Cria Live reagem ao estilo
→ salvar → carregar → manter niveis e estilo ativo
```

## Limites de balanceamento

- bonus total de recurso inicial: maximo `+20` por recurso;
- bonus total de chance por familia: maximo `+0.12`;
- multiplicador de dinheiro: maximo `1.20`;
- bonus extra de Honra/Hype: maximo `+3`;
- o estilo nunca escolhe uma tecnica, ignora estado, paga custo ou decide sucesso sozinho;
- a resolucao continua deterministica no nucleo atual, com IA generativa fora do runtime.

## Oito vias

`Fluxo`, `Anaconda`, `Magnata`, `Comunidade`, `Professor`, `Idolo`, `Pressao` e `Alfa` usam apenas IDs existentes em `data/techniques.json`. O mockup citava tecnicas ainda inexistentes; elas foram substituidas por equivalentes canônicos ativos, sem criar entradas falsas.

## Estado visual

A tela funcional usa os tokens preto/dourado/ciano do contrato visual e alvos touch de 48 px ou mais. A roda radial ilustrada permanece um asset candidato separado: ela precisa de arte final, origem/licenca, comparacao visual e aprovacao humana antes de substituir a grade funcional.

## Rollback

Remover o botao `ProgressionBtn`, a cena `StyleProgressionScreen`, os dois JSONs, `FighterStyleSystem.gd` e as extensoes cirurgicas de `DataRegistry`, `CombatManager` e `CriaLiveManager`. Niveis residuais ficam apenas em `story_flags` e sao ignorados por builds anteriores; nao ha migracao destrutiva.
