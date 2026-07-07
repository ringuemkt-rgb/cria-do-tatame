# Baixo Sul Geo Canon — Mapa Fiel do Jogo

## Objetivo

Garantir que o mapa de **Cria do Tatame** respeite a geografia real do Baixo Sul da Bahia como base de navegação, atmosfera e progressão.

O mapa do jogo pode ser estilizado em HD Pixel Art 2.5D, mas a posição relativa dos lugares precisa obedecer a lógica real:

- Ituberá como coração do jogo.
- Valença ao norte/noroeste do arco costeiro.
- Nilo Peçanha acima de Ituberá/Taperoá no eixo regional.
- Camamu ao sul de Ituberá, ligado à Baía de Camamu.
- Cairu em ilhas/canais, com lógica marítima.
- Itacaré ao sul, litoral/estilo surf/cultura.
- Salvador fora do Baixo Sul, como polo oficial estadual.

---

## 1. Região canônica

O território de referência é a Costa do Dendê / Baixo Sul, usando como núcleo a antiga microrregião de Valença e a zona turística formada por Valença, Cairu, Camamu, Taperoá, Nilo Peçanha, Ituberá e entorno costeiro.

### Municípios-base de mapa

| Node | Função no jogo | Uso |
|---|---|---|
| Ituberá | hub principal | Terreiro da Luta, centro moral |
| Valença | porta comercial | Ponte do Saci, comércio, rotas |
| Nilo Peçanha | cultura e ritual | Zambiapunga |
| Taperoá | travessia regional | rota de ligação |
| Cairu | ilhas e travessias | Boipeba/Morro como expansão futura |
| Camamu | baía e porto | Porto de Camamu, rota marítima |
| Maraú | península e litoral | expansão praia/natureza |
| Itacaré | litoral/cultura/surf | Praia de Pratigi/Itacaré como arco litoral |
| Salvador | circuito oficial estadual | Arena do Dique |

---

## 2. Regra de fidelidade geográfica

### O que deve ser fiel

- Posição relativa dos municípios.
- Relação costa/rios/mangue/ilhas.
- Salvador separado como polo estadual, não colado no Baixo Sul.
- Ituberá como centro emocional do jogo, não necessariamente centro geométrico.
- Rotas terrestres e marítimas diferenciadas.

### O que pode ser estilizado

- Distância comprimida para gameplay.
- Curvas de rota mais bonitas.
- Ícones, cards e hubs ampliados.
- Local fictício dentro de município real.
- Arena inspirada em lugar real, desde que marcada como ficcional quando necessário.

---

## 3. Pipeline correto para mapa final

Para máxima fidelidade:

1. Baixar malhas municipais oficiais do IBGE.
2. Importar no QGIS.
3. Recortar municípios do Baixo Sul.
4. Marcar sedes municipais e pontos de interesse.
5. Exportar mapa-base em PNG/SVG.
6. Criar paint-over em HD Pixel Art 2.5D.
7. Manter coordenadas em `data/world_map_geo.json`.
8. Converter coordenadas reais para coordenadas de tela por script.

---

## 4. Coordenadas de âncora

As coordenadas em `data/world_map_geo.json` são âncoras iniciais para posicionamento. Antes da arte final, validar contra malha municipal do IBGE ou OpenStreetMap/QGIS.

---

## 5. Tipos de rota

| Tipo | Cor sugerida | Gameplay |
|---|---|---|
| oficial | azul | regras, ranking, baixo risco |
| híbrida | amarelo | meio oficial/meio rua |
| clandestina | vermelho | risco alto, hype/sombra |
| costeira | verde | turismo, cultura, litoral |
| marítima | ciano | ilhas, barcos, travessias |
| bloqueada | cinza | requisito narrativo |

---

## 6. Erros proibidos

- Arena do Dique dentro de Nilo Peçanha.
- Zambiapunga como RJ.
- Ferro Velho da Lapa como São Paulo.
- Cachoeira Pancada Grande como Chapada Diamantina quando usada no arco de Ituberá.
- Praia de Pratigi como se fosse centro urbano de Itacaré.
- Misturar mapa real com nomes sem lógica territorial.

---

## 7. Canon geográfico final

```txt
Terreiro da Luta = Ituberá, BA
Arena do Dique = Salvador, BA
Ponte do Saci = Valença, BA
Zambiapunga = Nilo Peçanha, BA
Praia de Pratigi = Ituberá / litoral do Baixo Sul
Itacaré = arco litoral/cultural ao sul
Cachoeira Pancada Grande = região de Ituberá
Manguezal Profundo = Baixo Sul / área ficcional de mangue
Ferro Velho da Lapa = Salvador/BA ou zona urbana baiana ficcional
Budokan das Águas = dojo ficcional em área costeira do Baixo Sul
```
