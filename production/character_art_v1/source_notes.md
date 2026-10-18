# Proveniência do lote de identidade

- Método: geração/edição pelo `image_gen.imagegen`, seguida por medição determinística sem edição de pixels em Python.
- Data: 2026-10-17. Revisão exata do modelo: não exposta pela ferramenta.
- Referência de estilo: prancha do elenco criada nesta conversa e aceita pelo usuário como direção para continuar. Isso não equivale a aprovar automaticamente os novos atlas ou a sua versão normalizada.
- Fonte de identidade/narrativa: arquivos canônicos do projeto, incluindo overrides e o roster de 17 lutadores. Não foram usadas fotos ou retratos de pessoas reais.
- `authoring_sources.json` registra os 10 atlas, membros, referência de condicionamento e prompts disponíveis. Os prompts 01–03 estão no histórico da sessão, não em captura textual completa deste pacote; não confundir ausência de captura completa com licença concedida.
- Atlas 03 e 05 foram reeditados no gerador para afastar figuras que se encostavam entre linhas. Os originais rejeitados não são ativos do pacote.
- Os PNGs selecionados são os bytes originais do gerador. Hashes SHA-256 e regiões de corpo são registrados no manifesto. A medição por componentes opacos não modifica nem limpa o alpha do PNG.
- Direitos/termos de geração: revisão pendente; nenhuma declaração CC0 ou licença de terceiro foi atribuída. Revisão humana do desenho, da coerência GI/NO-GI, de marcas acidentais e de eventual semelhança permanece pendente.
- Contornos e alpha parcial exigem limpeza antes de sprites normalizados. Não há animação, sequência biomecânica, sync_map ou aprovação de técnica neste pacote.
- `shipping=false` em todo o lote. Uso atual: visualizador de autoria dentro do Godot do repositório oficial.
