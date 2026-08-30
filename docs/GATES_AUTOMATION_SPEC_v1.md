# Gates Automation Stack V1

**Status:** `CALIBRATION_LOCKED`

**Decisões:** D23–D30, D240–D243
**Escopo:** evidência, triagem e bloqueio; promoção e integração são proibidas.

## Contrato

O stack produz respostas reproduzíveis sem substituir o decisor humano. **Captura é evidência; IA é derivado.** Qualquer recriação recebe o rótulo “derivado visual, nunca evidência”. **Runtime decide, animação apresenta:** elegibilidade, prioridade, janelas em milissegundos e resultado pertencem ao runtime; pose, contato e antecipação tornam esse resultado legível.

| Ordem | Ferramenta | Entrada | Saída autorizada | Falha bloqueante |
|---:|---|---|---|---|
| 1 | `evidence_pack.py` | arquivos explícitos | caminhos, SHA-256, bytes e estado | arquivo ausente/fora do repo |
| 2 | `validate_lore_v4.py` | árvore textual | PASS/BLOCKED V4 OIIA | blacklist ou rótulo ausente |
| 3 | `accessibility_checks.py` | contrato de controles | cobertura, feedback e prioridade | input morto ou TAP não soberano |
| 4 | `license_scanner.py` | caminhos explícitos de assets | inventário de sidecars | licença ausente/incompatível |
| 5 | rubrica + log | decisão de máquina e humana | acordo rastreável | corpo decisório/assinatura ausente |
| 6 | `auto_promote.py` | rubrica e acordos | recomendação reversível de revisão | divergência, amostra ou política inválida |

## Calibração fechada

1. Uma categoria acumula 20 acordos humanos consecutivos com a triagem automática.
2. Depois disso, a ferramenta pode recomendar revisão automática; não pode promover asset, mudar estado canônico nem integrar runtime.
3. Pelo menos 10% dos casos continuam em amostra humana determinística.
4. Uma única divergência cria `RELOCKED`; a categoria volta à revisão humana integral.
5. `created`, `validated_automatic`, `pending_human`, `integrated` e `device_validated` são estados distintos.

## Núcleo humano irredutível

- consentimento e autorização de uso da captura;
- veto BJJ ao introduzir categoria técnica nova;
- teste físico em aparelho ARM64 real;
- decisão final de shipping;
- assinaturas dos Gates 01–06 por seus corpos decisórios definidos.

Ausência de corpo decisório produz `missing_body_blocked`. Nenhum nome, aprovação ou valor é inferido.

## Comandos de gate

```bash
python tools/gates/validate_lore_v4.py
python tools/gates/accessibility_checks.py
python tools/gates/license_scanner.py CAMINHO_DO_LOTE
python tools/gates/evidence_pack.py --state created CAMINHO_DO_ARQUIVO
python tools/gates/auto_promote.py --category lore_v4 --record-id ID
```

Todos falham com exit code não zero quando bloqueados. O CI executa o gate V4; os demais são chamados pelo lote que possui as entradas. Nenhum script publica, assina ou move candidatos para runtime.
