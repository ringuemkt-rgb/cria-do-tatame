# Pipeline de Análise de Movimento — Cria do Tatame

Objetivo: transformar vídeos de jiu-jitsu em material de produção para o jogo.

Fluxo:
1. Entrada: vídeo de treino, luta ou golpe.
2. Extração de frames.
3. Detecção de pose 2D ou 3D.
4. Limpeza dos keypoints.
5. Segmentação por fase do golpe.
6. Revisão técnica por nomenclatura brasileira.
7. Geração de ficha biomecânica.
8. Geração de poses-chave.
9. Geração de sprite sheet.
10. Importação no Godot.

Ferramentas recomendadas:
- MediaPipe Pose Landmarker para protótipo rápido.
- MMPose para pipeline técnico mais robusto.
- YOLO Pose para detecção rápida em vídeo.
- DeepLabCut para treino customizado quando houver dataset próprio.
- PYSKL ou MMAction2 para classificação de ações por esqueleto.

Saída padrão por técnica:
- nome brasileiro do golpe;
- estado inicial;
- estado final;
- fases: preparação, entrada, contato, controle, estabilização, saída;
- keyframes;
- ângulos principais;
- risco esportivo;
- animações necessárias;
- sprite sheet alvo;
- dados para o sistema de combate.

Regra de segurança:
Este pipeline deve produzir referência visual e gameplay esportivo. Não deve gerar instruções para machucar pessoas. Toda finalização deve ser tratada como técnica esportiva com tap, escape ou intervenção segura.
