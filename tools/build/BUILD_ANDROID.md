# Build Android Helper

Este diretório guarda scripts e instruções para exportação Android.

Fluxo recomendado:

```bash
mkdir -p export/builds
GODOT_BIN=godot
$GODOT_BIN --headless --export-debug "Android" export/builds/cria_do_tatame_debug.apk
```

Antes disso, configure:

1. Godot 4.2+.
2. Export templates.
3. Android SDK.
4. JDK compatível.
5. Preset Android em `export/export_presets.cfg`.

Não afirmar APK pronto sem rodar e validar a exportação real.
