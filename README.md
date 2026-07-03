# 🦍🥋 CRIA DO TATAME

**Cria do Tatame** é um protótipo jogável web/mobile de RPG tático de Jiu-Jitsu Brasileiro, com foco em carreira, progressão semanal, partida posicional, reputação, Cria Live e conteúdo data-driven.

> Regra de ouro: a IA alimenta o mundo; o jogo roda sozinho. O gameplay é determinístico, leve e funcional offline.

## ✅ Estado desta branch

Branch de resgate: `rescue/sprint-0-complete`

Entregas implementadas:

- PWA funcional com `index.html`, `style.css`, `game.js`, `manifest.webmanifest` e `sw.js`.
- Loop jogável com hub, treino, partida posicional, reputação e Cria Live.
- Progressão semanal com treino, descanso, energia, dinheiro, hype, honra e sombra.
- Dados separados em JSON: personagens, técnicas, missões, arenas, facções, patrocinadores e posts.
- Save/load via `localStorage`.
- Service worker simples.
- Workflow de CI para validação JSON.
- Documento inicial de Lore Guardian em `docs/AI_LORE_GUARDIAN.md`.

## 🧠 Arquitetura correta de IA

A IA não entra como dependência obrigatória do APK. O fluxo profissional é:

```txt
Hugging Face / Ollama / llama.cpp
→ Lore Guardian
→ JSON validado
→ data/*.json
→ jogo executa offline
```

Modelos sugeridos para produção externa:

- `Qwen/Qwen3-4B-GGUF` — escrita de lore, missões e diálogos.
- `Qwen/Qwen3-1.7B-GGUF` — alternativa leve.
- `HuggingFaceTB/SmolLM3-3B` — alternativa compacta multilíngue.
- `BAAI/bge-m3` — embeddings/RAG do lore.
- `BAAI/bge-reranker-v2-m3` — reranking de contexto.

## 🚀 Rodar localmente

```bash
npm install
npm run start
```

Abra:

```txt
http://localhost:8000
```

Também funciona com servidor estático simples:

```bash
python -m http.server 8000
```

## 📱 Android / Capacitor

A branch já possui `capacitor.config.json` mínimo, mas o pacote Android ainda deve ser gerado em etapa própria com Capacitor ou Android Studio.

Sprint 1 recomendado:

```bash
npm install @capacitor/core @capacitor/cli @capacitor/android
npx cap init "CRIA DO TATAME" "com.criadotatame.app" --web-dir .
npx cap add android
npx cap sync android
npx cap open android
```

## 📁 Estrutura

```txt
cria-do-tatame/
├── index.html
├── style.css
├── game.js
├── manifest.webmanifest
├── sw.js
├── package.json
├── capacitor.config.json
├── data/
│   ├── characters.json
│   ├── techniques.json
│   ├── missions.json
│   ├── arenas.json
│   ├── factions.json
│   ├── sponsors.json
│   └── cria_live_posts.json
├── docs/
│   └── AI_LORE_GUARDIAN.md
└── .github/workflows/ci.yml
```

## 🎮 Controles

- **Treinar**: aumenta XP e prepara graduação.
- **Descansar**: recupera energia.
- **Partida**: inicia teste posicional.
- **Cria Live**: publica repercussões e altera reputação.
- **Salvar**: persiste progresso no navegador.

## 🥋 Loop principal

```txt
Treinar → Recuperar → Partida → Reputação → Semana avança → Conteúdo desbloqueia
```

## 🧪 Definition of Done do Sprint 0

- [x] App abre no navegador.
- [x] Interface preta/dourada mobile-first.
- [x] Loop jogável básico.
- [x] Recursos de partida visíveis.
- [x] Save/load persistente.
- [x] Dados em JSON.
- [x] Cria Live com fallback.
- [x] README realista.

## ⚠️ Observações

- O arquivo legado `apk` ainda existe na branch base e não é usado pelo app.
- O build Android definitivo deve ser tratado no Sprint 1.
- A migração oficial para Godot 4.2+ continua sendo a rota recomendada para o jogo completo.
