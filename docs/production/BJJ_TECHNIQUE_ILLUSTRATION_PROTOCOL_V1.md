# BJJ Technique Illustration Protocol v1

Status: CANÔNICO DE PRODUÇÃO
Data: 2026-08-10
Objetivo: converter referências técnicas de grappling em keyframes fiéis para cartas, sprites pareados, animações e materiais 2.5D Pixel Art do Cria do Tatame.

## 1. Pipeline de engenharia reversa

Para cada referência técnica:

1. identificar posição inicial e estado posicional;
2. separar atacante e defensor;
3. marcar cabeça, coluna, cintura escapular, quadril, joelhos, tornozelos e mãos;
4. mapear grips e pontos de contato;
5. determinar base e centros de massa;
6. identificar eixo/alavanca e direção de força;
7. decompor em keyframes mínimos;
8. definir reação plausível do defensor;
9. criar frame de escape/tap quando aplicável;
10. converter para o DNA visual 2.5D Pixel Art do jogo.

## 2. Contrato de keyframes

Toda técnica pareada deve possuir, conforme aplicável:

- setup;
- anticipation;
- entry;
- contact;
- off-balance / posture break;
- control;
- stabilization;
- finish / positional outcome;
- tap or score state;
- escape / recovery;

## 3. Regras por família

### Armbar
- braço isolado;
- controle do punho;
- joelhos fechando a linha do ombro;
- perna sobre cabeça/rosto quando a variante exigir;
- cotovelo alinhado ao quadril;
- extensão pelo quadril, sem anatomia impossível.

### Kimura
- controle do punho;
- figura quatro correta;
- cotovelo/ombro isolados;
- rotação do ombro apoiada por tronco/quadril;
- mão conduzida em trajetória coerente.

### Americana
- punho preso ao tatame;
- cotovelo aproximadamente em ângulo funcional;
- figura quatro;
- ombro imobilizado;
- mão deslocada em direção ao quadril sem atravessar o corpo.

### Mata-leão
- back control estabelecido;
- braço estrangulador sob o queixo;
- mão no bíceps oposto;
- segunda mão controla a cabeça;
- peito conectado às costas;
- controle inferior por ganchos/body triangle quando visível.

### Triângulo
- postura quebrada;
- um braço dentro e um fora;
- perna sobre pescoço/ombro;
- figura quatro das pernas;
- quadril angulado lateralmente;
- pressão por adução das pernas e fechamento de espaço.

### Straight ankle lock
- pé preso na axila;
- linha do calcanhar apoiada no antebraço;
- joelhos comprimem a perna;
- quadril controla distância;
- extensão/arqueamento do corpo coerentes;
- não confundir com heel hook.

### Long step pass
- pressão de tronco/crossface ou controle superior coerente;
- braço defensivo do passador protegido;
- perna externa dá passo em arco por fora da guarda;
- quadril troca de lado e esconde a perna;
- consolidação termina em controle superior, não em pose intermediária.

### Granby roll
- corpo compacto;
- queixo protegido;
- rotação sobre ombro/cintura escapular, nunca diretamente sobre cervical;
- quadril passa alto e lateral;
- pés retornam para a frente;
- saída recupera base/guarda ou cria scramble.

### Controle de perna
- controle distal do pé/tornozelo;
- controle proximal da linha do joelho;
- postura e base do passador;
- distância entre quadris claramente gerenciada;
- objetivo deve ser leg drag, passagem, imobilização ou entrada de perna explicitamente definida.

### Canto choke / estrangulamento de gola
- pegada profunda de gola;
- postura quebrada;
- cabeça/pescoço controlados;
- ângulo do quadril e do tronco visíveis;
- fechamento do espaço cervical por tração e rotação, não por força gráfica abstrata.

## 4. Quedas e projeções

Representar sempre:

1. leitura/entrada;
2. desequilíbrio (kuzushi ou equivalente);
3. contato e mudança de nível/posição;
4. ação principal da perna/quadril/tronco;
5. deslocamento do centro de massa;
6. aterrissagem controlada;
7. continuação para estado posicional.

Uma queda não pode começar no ar sem preparação.

## 5. Boxes e sincronização

Metadados recomendados por animação:

```json
{
  "shared_pivot": [0.5, 0.86],
  "ground_line": 0.90,
  "contact_points": [],
  "grip_points": [],
  "impact_frame": 0,
  "stabilization_frame": 0,
  "tap_frame": null,
  "escape_window": null
}
```

Separar quando necessário:

- hitbox;
- hurtbox;
- grabbox;
- control zone;
- submission pressure state.

## 6. QA anatômico

Reprovar automaticamente se houver:

- dedos ou mãos fundidos;
- membros duplicados;
- joelho/cotovelo invertido;
- articulação em rotação impossível;
- pé sem conexão à perna;
- cabeça atravessando braço/tronco;
- grip que não alcança o ponto alegado;
- direção de força incompatível com o resultado;
- atacante e defensor em escalas corporais inconsistentes entre frames.

## 7. QA de animação

- silhueta legível em cada frame-chave;
- atacante/defensor preservam identidade;
- contato não desliza sem motivo;
- pivô não muda arbitrariamente;
- linha do chão constante;
- roupa reage à tração/compressão;
- transição não teleporta membros;
- timing diferencia entrada, controle e finalização.

## 8. Segurança visual

O jogo representa técnicas de combate esportivo. Evitar gore, lesões gráficas ou hiperextensão grotesca. O feedback de finalização deve usar tap, tensão, VFX, câmera, áudio e UI, não mutilação.

## 9. Regra final

Referência visual fornece mecânica. O Cria do Tatame fornece identidade. Nenhum asset é aprovado até satisfazer os dois.