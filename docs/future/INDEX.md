# Future Index — fora do cânone ativo do slice

**Status:** DEFERRED / NON-CANON FOR SLICE  
**Regra:** este índice preserva trabalho desenhado sem autorizá-lo para implementação antes do DoD do APK.

## Decisões adiadas

Todas as decisões D48–D228 ficam fora do cânone ativo do slice, **exceto** as explicitamente promovidas em `docs/DECISIONS.md`: D86, D96, D98, D99, D100, D128, D135, D143 e D148.

Nada neste arquivo autoriza implementação. Quando o DoD do APK ficar verde, cada item deverá voltar por lote próprio e gate explícito.

## Cortes obrigatórios do slice

- Modo espelho: adiado.
- Seleção completa com 5 categorias de arena: adiada; slice usa somente **História** + **Treino simples**.
- Ranking/clã: adiado.
- Configuração extensa: adiada; só controles e opções estritamente necessárias ao teste.
- Marcos/Memórias acima de 3: adiados; slice limita-se a 3.
- Maré sistêmica ativa: adiada; dados podem existir, sem mecânica sistêmica no slice.
- Cria Live acima de 3 módulos: adiado; máximo de 3 módulos no slice.
- Cidade caminhável acima de 1 rua: adiada; somente 1 rua de Ituberá.
- Quartel/Guarda: adiado.
- Pratigi Neon: adiado.
- NFT, blockchain ou certificação on-chain: adiados; nenhuma dependência de produto.
- Arenas além de Terreiro, Dique e Ponte: adiadas.
- Técnicas além das 6 técnicas-ouro: adiadas.
- Elenco de combate além de Ruan, Davi e Leoa apenas para sparring: adiado.

## Regra de retorno

Um item só sai de `future/` quando:
1. `docs/DEFINITION_OF_DONE_APK.md` estiver integralmente verde em aparelho ARM64 real;
2. existir novo lote explícito;
3. o novo lote demonstrar que reduz risco ou aumenta valor jogável sem quebrar o slice;
4. não houver promoção automática ou merge implícito.
