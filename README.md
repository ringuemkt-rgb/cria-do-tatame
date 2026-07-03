# 🦍🥋 CRIA DO TATAME

**Cria do Tatame** é um protótipo jogável web/mobile de RPG tático de Jiu-Jitsu Brasileiro, com foco em carreira, progressão semanal, combate posicional, reputação, Cria Live e conteúdo data-driven.

> Regra de ouro: a IA alimenta o mundo; o jogo roda sozinho. O gameplay é determinístico, leve e funcional offline.

## ✅ Estado desta branch

Branch de resgate: `rescue/sprint-0-complete`

Entregas implementadas:

- PWA funcional com `index.html`, `style.css`, `game.js`, `manifest.webmanifest` e `sw.js`.
- Combate mínimo jogável com posição, stamina, grip integrity, base integrity, foco, moral e finalização.
- Progressão semanal com treino, descanso, energia, dinheiro, hype, honra e sombra.
- Cria Live com posts e fallback offline.
- Dados separados em JSON: personagens, técnicas, missões, arenas, facções, patrocinadores e posts.
- Save/load via `localStorage`.
- Estrutura preparada para Capacitor Android.
- Módulo `ai_lore_guardian/` para geração assistida de conteúdo por IA fora do APK.
- Stub Godot `src/autoloads/AILoreClient.gd` para futura migração Godot 4.2+.

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

Também funciona com qualquer servidor estático simples:

```bash
python -m http.server 8000
```

## 📱 Android / Capacitor

Primeira configuração:

```bash
npm install
npm run android:init
npm run android:add
npm run android:sync
```

Abrir no Android Studio:

```bash
npm run android:open
```

Depois gere o APK pelo Android Studio ou pelo Gradle dentro da pasta `android/`.

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
├── ai_lore_guardian/
│   ├── README.md
│   ├── lore_guardian_server.py
│   ├── validate_output.py
│   ├── export_to_godot.py
│   ├── prompts/
│   │   └── system_lore_guardian.md
│   └── schemas/
│       └── mission_schema.json
├── src/
│   └── autoloads/
│       └── AILoreClient.gd
└── .github/workflows/ci.yml
```

## 🎮 Controles

- **Treinar**: aumenta técnica, foco e progressão.
- **Descansar**: recupera energia.
- **Missão**: inicia combate ou evento de mundo.
- **Cria Live**: publica posts e altera reputação.
- **Combate**: escolha técnicas conforme posição, recursos e risco.

## 🥋 Loop principal

```txt
Treinar → Recuperar → Missão/Combate → Reputação → Semana avança → Conteúdo desbloqueia
```

## 🧪 Definition of Done do Sprint 0

- [x] App abre no navegador.
- [x] Interface preta/dourada mobile-first.
- [x] Combate mínimo funcional.
- [x] Recursos de luta visíveis.
- [x] Save/load persistente.
- [x] Dados em JSON.
- [x] Cria Live com fallback.
- [x] Estrutura de IA separada do jogo.
- [x] Configuração Capacitor corrigida.
- [x] README realista.

## ⚠️ Próxima etapa

Sprint 1 deve migrar o protótipo para uma arquitetura mais forte:

1. separar `game.js` em módulos reais;
2. implementar cenas completas;
3. criar animações/sprites;
4. adicionar áudio;
5. expandir IA de adversários;
6. decidir rota final: Phaser/Capacitor ou Godot 4.2+ oficial.
