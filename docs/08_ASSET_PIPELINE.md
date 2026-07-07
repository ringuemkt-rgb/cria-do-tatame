# 08 - Pipeline de Assets

## Regra principal

Não travar produção esperando asset final. Primeiro placeholders jogáveis, depois arte premium.

---

## Sprites de personagens

Formato preferencial:

- PNG transparente.
- Pivot na base dos pés.
- Tamanho mínimo: 256x256 por frame para protótipo.
- Spritesheet por ação.
- Naming convention: `character_action_direction_variant.png`.

Exemplo:

```txt
ruan_macacao_idle_right_v01.png
ruan_macacao_grip_right_v01.png
ruan_macacao_takedown_right_v01.png
```

---

## Ações mínimas de Ruan

- idle
- walk
- stance
- grip_attempt
- grip_success
- clinch
- takedown
- guard
- pass
- mount
- submission_setup
- submission_lock
- submission_finish
- win
- lose

---

## Arenas

Cada arena deve ser separada em camadas:

```txt
bg_far
bg_mid
play_area
foreground
particles
ui_overlay_optional
```

---

## UI

- Bordas douradas.
- Fundo preto fosco.
- Ícones legíveis.
- HUD mobile com safe area.
- Texto grande.

---

## Áudio

Pastas:

```txt
assets/audio/music/
assets/audio/sfx/combat/
assets/audio/sfx/ui/
assets/audio/ambience/
```

---

## Checklist de importação Godot

- Desativar filtro em pixel art.
- Testar escala no Android.
- Confirmar pivôs.
- Agrupar atlas quando possível.
- Não usar arquivos enormes no APK inicial.
