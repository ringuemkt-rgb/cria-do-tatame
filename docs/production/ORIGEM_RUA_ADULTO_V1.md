# Origem de rua e construção adulta v1

Status: ACTIVE — lote incremental, 07/09/2026.
Base verificada: main cfb1afa18b0b4bdc5c3eb567276ea1d83823ce98.
Autor: direção expressa do mestre nesta sessão; implementação e revisão Codex.

## Resultado observável deste lote

O menu oferece **MEMÓRIA: O CARRO DE MÃO**. A cena consome `data/narrative/acts_v3.json.prologue` e permite completar Z1–Z5 e rever a memória:

- Z1: três entregas, movimento por setas/botões, bancas com colisão, gasto/recuperação de gás e R$2 locais por corrida;
- Z2: brigar/recuar produz texto de consequência, seguido da intervenção;
- Z3: recrutamento de ambos por Dendê;
- Z4: sequência interativa de tarefas/pegada/posição/tap;
- Z5: leitura de alternativa à força e encerramento pelo Coro.

É **protótipo com geometria e texto**, não arte final, sparring simulado ou cutscene animada. Z4 confirma verbos em sequência; ainda não conecta o motor de grappling. O alvo de duração 8–12 minutos não foi medido. Não há prazo punitivo nesta versão. O acesso por memória permite revisar a origem sem substituir o onboarding estável enquanto a ponte de faixa/idade estiver aberta.

O dinheiro é local à memória. Replay não paga CriaCoin, não sobrescreve save e não altera carreira; por isso não há migração de save neste lote. A memória recomeça ao sair. Persistência do prólogo integrado à campanha será outro lote com versão/migração.

## Confirmações do autor registradas

- Ruan/Joaquim aos ~12, feira de Ituberá, carro de mão e R$2; gentileza protegida pela armadura de brutalidade, xadrez e consertos de Tinker.
- CriaLive é rede social diegética: publicidade, desafios, patrocínio, lives, hype, Coro e clipes. As lives são conteúdo ficcional offline; não implicam streaming de rede.
- CriaCoin é moeda principal interna, BRL representa dinheiro de rua. Nenhuma conversão automática, blockchain ou compra com dinheiro real foi introduzida.
- Joaquim é empresário/agente: negocia cachê/local/regra, articula informações com Vera e favores com Ubirá, cuida da marca de Ruan. Cargo federal formal não é presumido.
- Vera observa A1 e recruta Ruan com ponte de Joaquim no A2. No A3 Joaquim percebe o custo psicológico do disfarce; não descobre pela segunda vez a colaboração com a PF. Chupeta tenta comprá-lo no A4.
- Chefões e territórios constam em `roster_v3.json.territory_bosses`: 11 registros **planejados**, separados dos 17 fighters. IDs possíveis não são aliases aprovados. Joaquim Jacaré e Joaquim Tinker são pessoas diferentes.
- Alvo editorial adulto 18+, violência com consequência, infância cooptada tratada criticamente, romance entre adultos Ruan/Leoa possível, sem glamour do crime. Não é classificação oficial já concedida.
- M10: Teruko apenas memória/fotos; gramática popular; sem marcas reais nem vingança glorificada.
- As referências a GTA e outros jogos são comparações abstratas de design, não afirmações sobre recursos confirmados de produtos externos nem cópia de implementação.

## Adaptação dos chefões: contrato para próximo lote

Gatilho: apenas clipe de luta efetivamente publicado. Registrar ID estável de clipe, território, técnicas observadas e chefe que teve acesso. Clipe não publicado não treina chefe. Reprocessar o mesmo clipe não concede outra adaptação. Após janela de treinamento, no reencontro, no máximo um counter novo, legal no ruleset e legível antes da execução. Nunca ler input privado ou mudar resposta retroativamente.

Aprender counter e copiar técnica são operações diferentes. O exemplo baiana/sprawl é counter; exigir catálogo de relações, treino e slots. Derrota do chefe concede uma técnica elegível uma vez, respeitando faixa e modo GI/NO-GI. Não adicionar técnica proibida diretamente ao deck.

Assist mode limita/remova escalada sem retirar recompensa narrativa. Memória de clipes/adaptações, recompensas e libertação do território deve ter save versionado e testes de replay/load/idempotência. Os managers existentes devem ser estendidos; não criar outra IA ou outro CriaLive.

## Agenciamento e feed: integração pendente

O repositório já tem CriaLiveManager, CriaLiveInteractionManager, FactionManager/Director e GameFlowManager. Reutilizá-los para menu de negociação (pagamento/risco/heat/regra), tarefas de informação/cobertura, favores/rep PM e publicidade/desafios com cláusulas.

Joaquim jogável em negociação/estratégia não exige troca de lutador durante combate. Loja de Luiz Henrique, rádio regional, desafios públicos, receitas recorrentes e libertação de território ainda precisam de consumidores, dados, UI, áudio, saldo/pagamento idempotente e testes. Nenhum deles foi marcado pronto neste lote.

PF e PM são instituições narrativas; milícia é rede antagonista. Isso preserva as três facções de gameplay ALE/LEM/NTM. A ambiguidade moral não significa que todos os membros tenham culpa coletiva. Favores ilegítimos possuem consequências ficcionais, não instruções reais de evasão policial.

## Pendências de continuidade que não devem ser preenchidas por adivinhação

1. Treino aos 12 versus branca aos 19–20. Escrever intervalo/retomada sem transformar Ruan em iniciante sem memória.
2. Biel versus Pipoca: manter registros separados até confirmação da relação; não apagar tragédia existente por busca/substituição.
3. Finais: runtime tem cinco; canon_v3 explicita dois e camada Verdade; direção nova pede três + Verdade. Precisamos do terceiro final e tabela de migração/condições antes de alterar resolver.
4. Vado/Concha, Sombra=Ramiro e Montanha divergem de papéis antigos; não renomear Davi, Dr. Sombra ou outros por inferência.
5. Chefões: confirmar aliases Oni da Lapa/Montenegro/Jacaré; não inferir Oni do Sul=Oni Maré ou Mateus Predador=Faro.
6. Guardiões/responsáveis e acolhimento no Terreiro precisam de ponte narrativa.
7. Explicitar vínculo, idade e preparação da colaboração de Ruan com Vera. Não confundir informante com carreira policial.

## Auditoria para evitar retrabalho

Anexos anteriores: 5 PDFs, 127 páginas; ZIP de 94 arquivos com cenas vazias; 37 imagens recuperadas, aproximadamente 27 composições devido a variantes. Relatório/inventários/imagens foram entregues em Cria_Revisao_Consolidada.zip. O ZIP antigo não substitui esta main.

Main atual: 40 nós no world_map_v4 (não 53), dez páginas, 14 municípios, 17 perfis do roster backbone. Há runtime mais avançado que o ZIP antigo. Não declarar esses perfis como 17 sprites completos. PRs abertos foram consultados; nenhum PR de prólogo equivalente apareceu na lista e a busca de issues por “prólogo” não encontrou resultado. PR81 trata mapa, PR86 inteligência BJJ, PR87 HUD; não duplicar esses lotes.

Correção deste lote: ALE e NTM divergiam entre produção, canon_lock, factions_v2 e dois validadores. Agora o backbone confere o contrato de produção; nomes são Os Aleluiado / Nós Tem Um Molho, preservando IDs. Não se trata de criar outra autoridade.

## Gates e limites

Executar npm run quality, testes de origem, auditoria completa, import Godot, smokes existentes e street_prologue_smoke.gd. CI Full Game Hardening inclui o smoke novo e rejeita erros de parser/runtime nos logs.

Godot não está instalado neste executor. Não afirmar teste local Godot. Executar pelo CI e registrar conclusão real. Android físico, touch em proporções distintas, ausência de scroll horizontal, animação pareada e duração continuam pendentes. Nenhum shipping asset/licença/aprovação humana foi promovido. Um gate estático verde não comprova jogo completo.

Rollback: reverter o commit do lote remove botão/cena/contratos novos e conserva o fluxo adulto pré-existente. Não requer converter saves porque a memória não os modifica.
