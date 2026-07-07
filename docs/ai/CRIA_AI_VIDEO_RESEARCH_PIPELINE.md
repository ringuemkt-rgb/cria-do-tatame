# Cria AI Video Research Pipeline

## Função

Sistema de pesquisa e análise técnica para transformar vídeos autorizados de jiu-jitsu em conhecimento de jogo, arte e animação.

## Fontes permitidas

- vídeos próprios;
- vídeos enviados pelo usuário;
- vídeos com licença compatível;
- vídeos com autorização do criador;
- vídeos públicos usados apenas como referência manual e anotação técnica.

## Fontes não permitidas

- copiar frames de terceiros;
- reproduzir atleta real;
- copiar fala de aula;
- copiar kimono, marca ou cenário protegido;
- treinar dataset com material sem direito claro.

## Fluxo técnico

1. Registrar fonte no catálogo.
2. Classificar técnica.
3. Anotar ângulo da câmera.
4. Extrair ou observar fases do movimento.
5. Rodar pose estimation quando houver arquivo autorizado.
6. Separar keyframes principais.
7. Gerar ficha técnica PT-BR.
8. Gerar prompt de sprite autoral.
9. Gerar JSON de gameplay.
10. Enviar para revisão de qualidade.

## Ferramentas grátis recomendadas

- MediaPipe Pose para protótipo leve.
- OpenCV para frames e overlays.
- MMPose ou RTMPose para análise mais robusta.
- YOLO Pose para detecção rápida.
- DeepLabCut para dataset próprio de jiu-jitsu.
- VideoMAE ou PYSKL para classificação de ações.
- Segment Anything ou rembg para segmentação auxiliar.
- ControlNet OpenPose para guiar pose visual.
- Pixelorama, LibreSprite e Krita para limpeza de pixel art.
- sprite-sheet-creator para montar spritesheets.
- Godot 4.2 ou superior para implementação.

## Saídas obrigatórias

- pesquisa.md;
- ficha_biomecanica.md;
- keyframes.json;
- prompt_sprite.txt;
- tecnica_godot.json;
- eventos_animacao.json;
- qa_visual.md.

## Regra de linguagem

Tudo em português brasileiro, com nomenclatura real de tatame: pegada, base, queda, sprawl, guarda, meia-guarda, passar, raspar, cem quilos, montada, costas, ganchos, cinto, tap.
