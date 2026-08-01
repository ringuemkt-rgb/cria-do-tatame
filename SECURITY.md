# Política de Segurança

## Escopo

Esta política cobre o repositório, ferramentas de build, workflows, APKs de teste, serviços auxiliares e dados usados na produção de **Cria do Tatame – Pressão**.

## Nunca versionar

- tokens, chaves de API e senhas;
- arquivos `.env` reais;
- keystores e senhas de assinatura;
- credenciais de Hugging Face, OpenRouter, GitHub ou provedores;
- dados pessoais de jogadores, colaboradores ou pessoas usadas como referência;
- conteúdo privado ou sem licença.

## Como relatar uma vulnerabilidade

Não publique credenciais ou detalhes exploráveis em uma issue pública. Revogue imediatamente qualquer segredo exposto e entre em contato com o responsável do repositório por canal privado do GitHub.

Inclua:

- componente e versão/commit afetado;
- impacto provável;
- passos mínimos para reproduzir;
- evidência sem dados pessoais;
- sugestão de contenção, quando possível.

## Prioridades

- **Crítica:** execução remota, segredo exposto, assinatura comprometida, corrupção irrecuperável de save ou distribuição maliciosa;
- **Alta:** bypass de integridade, escrita arbitrária, perda frequente de progresso ou dependência comprometida;
- **Média:** vazamento limitado, negação de serviço local ou validação insuficiente;
- **Baixa:** hardening, informação excessiva ou risco teórico sem exploração demonstrada.

## Regras do runtime

- O loop principal deve funcionar offline.
- LLM ou serviço externo não controla combate por frame.
- Respostas externas são tratadas como não confiáveis e validadas por schema/whitelist.
- O APK não deve conter segredos.
- NFTs ou serviços cosméticos opcionais não podem conceder poder jogável.

## Dependências e assets

Toda dependência, modelo, fonte, sample ou asset externo precisa de versão, origem e licença registradas. Conteúdo com licença incerta não entra em caminhos de shipping.
