# Definition of Done — APK do slice V4

**Status:** BLOCKED_PENDING_PHYSICAL_DEVICE

**Versão:** 1.1.0

**Alvo:** aparelho Android ARM64 real
**Pergunta governante:** “Ruan entra, luta 6 técnicas, defende, dá TAP, salva e volta no celular real?”

O APK só recebe `APK_SLICE_ACCEPTED` quando uma única build possui evidência fresca para todos os gates. Exportar APK, passar em CI ou abrir no desktop não substitui aparelho físico.

| Gate | Evidência obrigatória no mesmo build | Estado inicial |
|---|---|---|
| Entrar no Terreiro | vídeo contínuo menu → Terreiro, sem atalho de debug | PENDING |
| Seis técnicas-ouro | `grip_de_ferro`, `baiana`, `sprawl`, `corte_joelho`, `cem_quilos`, `encerramento_tecnico`, todas por elegibilidade | PENDING |
| Defesa em ms | log com abertura, input e resultado da janela em milissegundos | PENDING |
| TAP soberano | segurar B/touch durante `submission_defense=true`, soltura imediata e nenhum consumo por pausa/defesa/contextual | PENDING |
| Resultado | tela e log com método, posição, recursos, defesa e métricas da luta | PENDING |
| Save | snapshot versionado após resultado | PENDING |
| Fechar e reabrir | cold restart retorna ao mesmo ponto persistido | PENDING |
| Estabilidade | 10 minutos contínuos, sem crash, softlock ou input morto | PENDING |
| CI | `validate_data`, `validate_lore_v4`, `npm run quality` e matriz 8/8 verdes no SHA testado | PENDING |
| Gates humanos | 01 BJJ, 02 Animação e 03 Arte assinados por Mestre Satoshi | PENDING |

## Registro físico obrigatório

- aparelho/modelo: `________________`;
- Android/SoC/RAM: `________________`;
- SHA-256 do APK: `________________`;
- commit: `________________`;
- início/fim do ensaio: `________________`;
- FPS mínimo/mediano e temperatura: `________________`;
- save antes/depois: `________________`;
- assinatura: `________________`.

## Veredito

O aceite é binário. Qualquer linha pendente, falha ou sem evidência mantém `BLOCKED_PENDING_PHYSICAL_DEVICE`. Este documento não declara integração, aprovação humana, instalação ou release.
