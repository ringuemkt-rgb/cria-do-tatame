# Cria do Tatame — IA local, NPCs e Android

## Decisão arquitetural

O jogo possui duas camadas de IA separadas:

1. **IA crítica de gameplay**: luta, defesa, contra-ataque, rotina e navegação. É determinística, data-driven e executada em GDScript/Behavior Tree.
2. **IA generativa opcional**: somente diálogo experimental e ferramenta externa de produção. Nunca controla o combate, nunca é necessária para abrir o APK e sempre possui fallback canônico.

Esta separação é obrigatória para preservar FPS, bateria, previsibilidade, QA e funcionamento offline.

## Estado implementado

- `CombatManager` e `DaviAIController` executam a IA real de luta sem LLM.
- `LocalAIManager` oferece um gateway opcional para Ollama ou servidor local compatível.
- O backend padrão é `disabled`.
- `ai_fallbacks_v01.json` garante diálogos offline para Mestre Dendê, Tinker Bell, Davi e Cássio.
- Respostas remotas são limitadas, saneadas e rejeitadas quando violam regras básicas de segurança.
- Nenhuma API key é exigida.

## Beehave

Beehave pode ser usado para rotinas complexas de NPCs, bosses e hubs. Ele não deve substituir o `CombatManager` nem introduzir dependência obrigatória no primeiro APK.

Repositório oficial:

- `https://github.com/bitbrain/beehave`
- branch padrão para Godot 4: `godot-4.x`

Integração recomendada:

1. Fixar uma versão compatível com Godot 4.2.2.
2. Copiar apenas `addons/beehave` e os templates necessários.
3. Registrar a versão e licença em `THIRD_PARTY_NOTICES.md`.
4. Usar árvores para comportamento de hub, patrulha, treino e boss.
5. Manter uma rotina GDScript de fallback para o APK continuar abrindo se o addon for removido.

A instalação automática do addon será feita somente após o combate e o vertical slice Android estarem estáveis. Evita-se vender a colmeia antes de ter abelha. 🐝

## Ollama: uso correto

Ollama é suportado oficialmente em macOS, Windows, Linux e Docker. No projeto, ele é um **servidor de desenvolvimento**, não um runtime Android embutido.

Fluxos válidos:

- Godot no PC → `http://127.0.0.1:11434`.
- Emulador Android → `http://10.0.2.2:11434`.
- Celular físico → servidor na mesma LAN, com URL informada manualmente e configuração de rede segura.

Fluxo inválido para release:

- prometer que `ollama serve` roda dentro do APK sem plugin nativo, NDK, empacotamento e benchmark físico.

## Modelos avaliados

### Qwen/Qwen3-0.6B

- 751,6 milhões de parâmetros.
- Apache-2.0.
- Melhor candidato para diálogo curto e classificação simples.
- Usar versão quantizada no runtime externo.

### Qwen/Qwen3-1.7B-GGUF

- Apache-2.0.
- Melhor coerência, maior uso de memória.
- Candidato para PC, servidor local ou aparelho Android forte em uma fase posterior.

### HuggingFaceTB/SmolLM3-3B

- 3,075 bilhões de parâmetros.
- Apache-2.0.
- Suporte explícito a português entre os idiomas do modelo.
- Recomendado para prototipação no desktop, não como padrão de aparelho intermediário.

## Backend nativo Android futuro

Uma versão realmente on-device exige uma destas rotas:

- plugin Android/JNI para `llama.cpp`;
- integração MLC LLM;
- runtime móvel equivalente, com biblioteca nativa e modelo quantizado.

Critérios antes de integrar:

- APK/AAB abre sem modelo instalado;
- download do modelo é opcional e verificável por hash;
- memória de pico medida em aparelho físico;
- geração não bloqueia a thread principal;
- cancelamento, timeout e fallback funcionam;
- consumo de bateria e temperatura são documentados;
- licença do modelo e da quantização são registradas.

## API do LocalAIManager

### Fallback imediato

```gdscript
var text := LocalAIManager.get_fallback_dialogue(
    "mestre_dende",
    "treino"
)
```

### Requisição assíncrona

```gdscript
func _ready() -> void:
    LocalAIManager.dialogue_ready.connect(_on_dialogue_ready)
    LocalAIManager.dialogue_failed.connect(_on_dialogue_failed)

func pedir_conselho() -> void:
    LocalAIManager.request_dialogue(
        "mestre_dende",
        "Mestre, por que minha passagem falhou?",
        {"category": "treino", "location": "terreiro_da_luta"}
    )

func _on_dialogue_ready(_id: int, npc_id: String, text: String, source: String) -> void:
    print(npc_id, ": ", text, " [", source, "]")
```

### Ativar Ollama manualmente no desenvolvimento

```gdscript
LocalAIManager.configure_backend("ollama_desktop")
```

Para celular físico, a URL deve ser informada explicitamente:

```gdscript
LocalAIManager.configure_backend(
    "ollama_desktop",
    "http://192.168.1.50:11434"
)
```

## Política de segurança e canon

- máximo de três frases;
- PT-BR obrigatório;
- sem novo protagonista, facção, morte ou parentesco canônico;
- sem instruções reais de lesão;
- sem LLM no combate;
- timeout vira fallback;
- JSON inválido vira fallback;
- rede desligada por padrão;
- nenhuma chave OpenAI ou Hugging Face dentro do APK.

## Testes obrigatórios

1. APK sem rede: diálogos de fallback funcionam.
2. Servidor Ollama desligado: resposta de fallback chega sem travar.
3. JSON inválido: fallback e sinal de erro.
4. Resposta vazia: fallback.
5. Resposta acima do limite: truncamento.
6. Dois NPCs pedindo fala: fila sequencial sem mistura.
7. Combate durante falha de IA generativa: zero impacto no loop.
8. Fechar e reabrir o jogo: nenhuma dependência de servidor.

## Definition of Done da IA generativa

A feature só pode ser chamada de pronta quando:

- o jogo funciona integralmente com backend `disabled`;
- o diálogo opcional funciona no desktop;
- o fallback passa no smoke test;
- o Android físico foi testado;
- RAM, bateria, temperatura e latência estão documentadas;
- nenhuma promessa de "IA dentro do APK" depende de um servidor escondido na rede.
