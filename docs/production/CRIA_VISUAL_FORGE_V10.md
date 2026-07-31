# CRIA VISUAL FORGE v1.0 — Sistema Mestre de Produção Gráfica

## 1. Missão

Converter o cânone do **Cria do Tatame** em material visual implementável, versionado e testável. O sistema não entrega apenas pranchas bonitas: entrega arquivos com dimensões, pivôs, camadas, metadados, hashes, licença, preview, importação e QA.

## 2. Contrato de produção

```text
briefing canônico
-> job estruturado
-> seed aprovado
-> faixa completa em uma geração
-> normalização por âncora compartilhada
-> preview GIF/contact sheet
-> QA automático + revisão humana
-> catálogo runtime
-> importação Godot
```

## 3. Hierarquia de verdade

1. Cânone mais recente do repositório.
2. `visual_forge_config_v10.json`.
3. `production_manifest_v02.json`.
4. Job individual.
5. Prompt de geração.

Prompts nunca podem alterar protagonista, facções, paleta, silhueta ou função mecânica.

## 4. Famílias de assets

### Personagens

- portrait 1024²;
- turnaround;
- sprites de hub 8 direções;
- fighter core;
- clinch;
- chão;
- técnicas pareadas;
- reações, vitória e derrota;
- metadata, pivô, eventos e hitbox references.

### Técnicas

Cada técnica precisa de:

- ícone 256²;
- card art 768×1024;
- thumbnail;
- sequência pareada;
- `sync_map.json`;
- `hitbox.json`;
- nota segura de representação;
- VFX e SFX keys.

### Arenas

Cada variante precisa de:

- `bg_far.png`;
- `bg_mid.png`;
- `play_area.png`;
- `foreground.png`;
- `overlay_particles.png`;
- `collision.json`;
- `camera_bounds.json`;
- preview composto;
- cena `.tscn`.

### UI

A UI deve manter o centro do combate limpo, safe area de 7% no Android, botões de ação com mínimo de 80 px e contraste AA/AAA sempre que possível.

### VFX

VFX ficam separados dos sprites. Isso permite reduzir partículas, shaders e resolução no mobile sem substituir o personagem.

## 5. Produção de sprites

A produção quadro a quadro isolada é proibida por padrão, porque gera deriva. A sequência completa deve ser gerada em uma única faixa, usando um seed aprovado, mesma direção, mesma escala e fundo transparente. Depois o normalizador aplica uma escala compartilhada e âncora inferior central.

## 6. Quality gates

- silhueta reconhecível em escala de jogo;
- proporções estáveis;
- alpha limpo;
- nenhum frame vazio;
- contato com chão constante;
- ação tecnicamente compreensível;
- sem marca real, pessoa real ou cópia de frame protegido;
- paleta e contraste conformes;
- nomes ASCII snake_case;
- hash e licença registrados;
- preview aprovado antes do runtime.

## 7. Estados

- `queued`: job criado;
- `generated`: saída bruta existe;
- `normalized`: frames e dimensões padronizados;
- `qa_pass`: automação aprovada;
- `approved`: direção humana aprovou;
- `qa_fail`: bloqueado, sem importação.

## 8. Critério de finalização

Um personagem não está pronto por possuir concept art. Está pronto quando o pacote visual exigido existe, passa QA, possui catálogo e funciona no Godot. A mesma regra vale para técnica, arena, HUD e VFX.
