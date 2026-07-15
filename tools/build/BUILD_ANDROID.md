# Build Android — Cria do Tatame

O preset oficial está em `export_presets.cfg`, na raiz do projeto, com o nome exato **Android Debug**.

## Pré-requisitos

1. Godot 4.2.2 ou versão 4.2 compatível.
2. Export templates da mesma versão do Godot.
3. Android SDK configurado.
4. JDK 17.
5. Debug keystore disponível em `~/.android/debug.keystore` ou configurado no editor.

## Linux / macOS

Na raiz do repositório:

```bash
mkdir -p builds/android reports/build
GODOT_BIN="${GODOT_BIN:-godot}"

"$GODOT_BIN" --headless --editor --path . --quit
"$GODOT_BIN" --headless --path . \
  --export-debug "Android Debug" \
  builds/android/CriaDoTatame-debug.apk

unzip -t builds/android/CriaDoTatame-debug.apk
sha256sum builds/android/CriaDoTatame-debug.apk \
  > builds/android/CriaDoTatame-debug.apk.sha256.txt
```

## Windows PowerShell

O script oficial verifica o ambiente, importa o projeto, exporta, confere o tamanho e produz SHA-256:

```powershell
$env:GODOT_BIN = "C:\caminho\Godot_v4.2.2-stable_win64.exe"
.\tools\build\build_android_debug.ps1
```

Para instalar em um aparelho conectado:

```powershell
.\tools\build\build_android_debug.ps1 -Install
```

## Resultado esperado

```text
builds/android/CriaDoTatame-debug.apk
builds/android/CriaDoTatame-debug.apk.sha256.txt
reports/build/android_export.log
reports/build/android_build_report.json
```

Nunca declare o APK como pronto sem executar a exportação real e validar:

- arquivo criado e maior que 1 MB;
- `unzip -t` sem erro;
- package ID `com.criadotatame.pressao`;
- SHA-256 gerado;
- smoke tests Godot aprovados antes do build.
