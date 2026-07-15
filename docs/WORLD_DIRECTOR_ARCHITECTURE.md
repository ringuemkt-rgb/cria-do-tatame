# Cria World Director — arquitetura do mundo vivo

## Objetivo

O **Cria World Director** coordena a simulação do mundo semiaberto de *Cria do Tatame* sem tornar o APK dependente de internet. O sistema combina regras determinísticas em GDScript com um diretor generativo opcional executado fora do jogo.

## Regra de ouro

- O jogo executa clima, NPCs, eventos, facções, economia e estratégias rivais localmente.
- A IA remota produz somente planos estratégicos de baixa frequência.
- Nenhuma LLM controla golpes, animações, inputs ou decisões por frame.
- Resposta inválida, timeout ou ausência de chave cai para simulação determinística.
- Nenhuma chave de OpenRouter ou Hugging Face é embarcada no APK.

## Camadas

```text
Godot 4.2+
├── WorldDirectorManager
│   ├── clima Markov determinístico
│   ├── rotina de NPCs por bloco do dia
│   ├── eventos condicionais e cooldowns
│   ├── pressão das facções
│   ├── economia por hub
│   └── diretrizes estratégicas dos rivais
├── RivalAIManager
│   └── executa a diretriz usando ações já autorizadas no perfil local
├── NFTManager
│   └── catálogo e cache de direitos cosméticos
└── SaveManager
    └── persiste todos os estados

Servidor externo FastAPI
├── Hugging Face Inference Providers
├── OpenRouter com structured outputs
├── fallback determinístico
└── verificação opcional ERC-721/ERC-1155
```

## Clima vivo

`climate_regions_v01.json` define estados visuais e sonoros, efeitos de deslocamento e matrizes de transição por região. O resultado é reproduzível pelo seed do save, facilitando QA e replays.

Regiões iniciais:

- Ituberá e Terreiro da Luta;
- Salvador e Arena do Dique;
- Zambiapunga;
- Camamu e Manguezal.

## NPCs

`npc_routines_v01.json` define manhã, tarde, noite e madrugada. Chuva, temporal e condições do mundo podem deslocar atividades sem inventar novo cânone.

## Eventos

`dynamic_events_v01.json` usa condições verificáveis: hub, semana, clima, reputação, chance, prioridade e cooldown. Os efeitos permitidos são limitados a reputação, energia, dinheiro e pressão das facções.

## Adversários

O diretor gera uma diretriz prévia por rival: agressividade, tolerância a risco, orçamento de gás, estratégia e uma ação preferida já existente no perfil. `RivalAIManager` continua responsável pela escolha local durante o combate.

## NFTs e colecionáveis

A integração é **opcional e estritamente cosmética**:

- o jogo abre sem carteira;
- nenhum item aumenta atributo, dano, stamina ou chance de vitória;
- chaves privadas nunca entram no cliente;
- a blockchain é a fonte de verdade quando configurada;
- o servidor suporta verificação de itens ERC-721 e ERC-1155 listados no catálogo;
- o modo de desenvolvimento off-chain precisa ser ativado explicitamente.

O projeto não inclui contrato implantado porque rede, contrato, tesouraria e política jurídica precisam ser definidos antes de qualquer mint real.

## Executar o servidor

```bash
cd tools/world_director_server
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
uvicorn app:app --host 127.0.0.1 --port 8787
```

No Godot, durante desenvolvimento:

```gdscript
WorldDirectorManager.configure_ai_proxy("http://127.0.0.1:8787")
NFTManager.configure_backend("http://127.0.0.1:8787")
```

Para Android físico, use HTTPS, autenticação no gateway e um backend próprio. Não exponha este serviço diretamente na internet sem reverse proxy, autenticação, rate limit e observabilidade. Não coloque tokens dos provedores no aplicativo.

## Provedores

O servidor tenta, por padrão:

1. Hugging Face com `Qwen/Qwen3-4B-Instruct-2507`;
2. OpenRouter com `openrouter/free`;
3. plano determinístico interno.

A ordem é configurável em `WORLD_AI_PROVIDER_ORDER`.

## Testes

```bash
pytest -q tests/test_world_director_data.py
python -m py_compile tools/world_director_server/app.py
```

A validação cobre política offline-first, transições climáticas, eventos, rotinas, integridade do catálogo NFT e presença dos runtimes.
