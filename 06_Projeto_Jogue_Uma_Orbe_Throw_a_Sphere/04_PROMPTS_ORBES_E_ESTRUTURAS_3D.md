# Prompts 3D — Orbes de Captura, Máquina de Fusão, Pódio 3D e Portais

Aqui estão os prompts individuais **1 por 1** para construir no Blender (`bpy`) ou no Roblox Studio todos os objetos icônicos do jogo **sem risco de copyright** (substituindo pokébolas por Orbes Geométricas/Rúnicas/Hextech) e as estruturas centrais do mapa.

---

## 🔮 Parte 1 — Prompts Individuais das 8 Orbes de Captura

> **Como usar:** Copie o prompt da Orbe desejada e peça para gerar o script Blender Python (`bpy`) ou construa no Roblox Studio seguindo as dimensões e cores exatas.

### Orbe 1 — Orbe Comum (Esfera de Pedra Rúnica)
```text
Crie um script Python autossuficiente para Blender (bpy) que gere o modelo 3D da "Orbe Comum (Esfera de Pedra Rúnica)" no estilo Low-Poly / Voxel facetado para Roblox, com shading 100% Flat (`bpy.ops.object.shade_flat()`), materiais de cor sólida (`use_nodes = False`, `diffuse_color = rgba`) e modificador Bevel aplicado (`width=0.015, segments=2`).
Especificação visual (IP Safe, NÃO parecida com Pokébola):
- Corpo principal: Octaedro/Esfera low-poly facetada (icosphere subdivisions=1 ou octaedro chanfrado) de raio 0.55 em cinza-azulado pedra RGBA (0.45, 0.50, 0.58, 1.0).
- Faixa equatorial: Anel octogonal (cilindro 8 lados achatado, raio 0.60, altura 0.14) em azul cobalto RGBA (0.18, 0.45, 0.88, 1.0).
- Núcleo frontal e traseiro: Cristal cúbico rotacionado a 45 graus encaixado no centro da faixa em azul-ciano brilhante RGBA (0.22, 0.85, 0.98, 1.0).
- Orçamento: 120 a 220 triângulos. Inclua CONFIG, clean_existing_object() e generate_variations().
```

### Orbe 2 — Orbe Esmeralda (Cubo Veloz)
```text
Crie um script Python autossuficiente para Blender (bpy) que gere a "Orbe Esmeralda (Cubo Veloz)" no estilo Low-Poly / Voxel facetado para Roblox, com `shade_flat()`, materiais `use_nodes = False` e Bevel aplicado (`width=0.02, segments=2`).
Especificação visual:
- Corpo: Cubo chanfrado de tamanho (0.95, 0.95, 0.95) em verde esmeralda vibrante RGBA (0.09, 0.72, 0.38, 1.0) dividido por um sulco central escuro RGBA (0.06, 0.22, 0.14, 1.0).
- Anel orbital inclinado: Aro fino octogonal inclinado a 25° ao redor do cubo em ouro claro RGBA (0.98, 0.82, 0.22, 1.0).
- Núcleo central: Diamante de 4 lados na face frontal em verde-limão neon RGBA (0.55, 1.0, 0.35, 1.0).
- Orçamento: 140 a 260 triângulos. Inclua CONFIG, clean_existing_object() e generate_variations().
```

### Orbe 3 — Orbe Rubi (Cristal de Fogo)
```text
Crie um script Python autossuficiente para Blender (bpy) que gere a "Orbe Rubi (Cristal de Fogo)" no estilo Low-Poly facetado para Roblox, com `shade_flat()`, materiais sólidos e Bevel aplicado.
Especificação visual:
- Corpo: Prisma hexagonal alongado verticalmente (6 lados, raio 0.52, altura 1.15) com pontas cônicas superior e inferior em vermelho rubi RGBA (0.88, 0.14, 0.18, 1.0).
- Armadura lateral: 3 placas angulares em formato de chama envolventes em dourado metálico RGBA (0.98, 0.75, 0.12, 1.0).
- Núcleo interno visível na fenda frontal: Laranja incandescente RGBA (1.0, 0.45, 0.08, 1.0).
- Orçamento: 150 a 280 triângulos.
```

### Orbe 4 — Orbe Safira (Prisma Glacial)
```text
Crie um script Python autossuficiente para Blender (bpy) que gere a "Orbe Safira (Prisma Glacial)" no estilo Low-Poly facetado para Roblox, com `shade_flat()`, materiais sólidos e Bevel aplicado.
Especificação visual:
- Corpo: Dodecaedro ou Icosphere (subdivisions=1) em azul safira profundo RGBA (0.12, 0.38, 0.92, 1.0).
- Coroa de cristais: 4 pontas prismáticas de gelo saindo na diagonal superior e inferior em azul-gelo translúcido/claro RGBA (0.58, 0.90, 1.0, 1.0).
- Cinturão prateado: Anel de 8 lados em prata clara RGBA (0.85, 0.90, 0.96, 1.0) com gema frontal branca brilhante.
- Orçamento: 180 a 320 triângulos.
```

### Orbe 5 — Orbe Rúnica Ancestral
```text
Crie um script Python autossuficiente para Blender (bpy) que gere a "Orbe Rúnica Ancestral" no estilo Low-Poly facetado para Roblox, com `shade_flat()`, materiais sólidos e Bevel aplicado.
Especificação visual:
- Núcleo central: Esfera facetada (8x6 segmentos) em pedra arenito escura RGBA (0.32, 0.25, 0.18, 1.0) com gravações/blocos dourados RGBA (0.96, 0.78, 0.20, 1.0).
- Dois anéis rúnicos cruzados: Dois aros quadrados/octogonais girados em 45° e -45° ao redor do núcleo em ouro antigo, com 4 pequenos losangos turquesa RGBA (0.18, 0.92, 0.80, 1.0) incrustados nos pontos cardeais.
- Orçamento: 220 a 380 triângulos.
```

### Orbe 6 — Orbe Hextech Neon
```text
Crie um script Python autossuficiente para Blender (bpy) que gere a "Orbe Hextech Neon" no estilo Low-Poly Sci-Fi / Voxel para Roblox, com `shade_flat()`, materiais sólidos e Bevel aplicado.
Especificação visual:
- Gaiola externa aberta: 6 hastes retangulares formando uma moldura de cubo/octaedro tecnológico em grafite escuro RGBA (0.10, 0.12, 0.18, 1.0) com chanfros em ciano neon RGBA (0.10, 0.92, 1.0, 1.0).
- Núcleo flutuante suspenso no centro: Octaedro brilhante em ciano-elétrico RGBA (0.45, 0.98, 1.0, 1.0) desconectado da gaiola externa para girar livremente.
- Orçamento: 200 a 340 triângulos.
```

### Orbe 7 — Orbe Cósmica Estelar
```text
Crie um script Python autossuficiente para Blender (bpy) que gere a "Orbe Cósmica Estelar" no estilo Low-Poly facetado para Roblox, com `shade_flat()`, materiais sólidos e Bevel aplicado.
Especificação visual:
- Corpo: Icosphere facetada (subdivisions=2) em roxo cósmico escuro RGBA (0.18, 0.08, 0.42, 1.0) com placas flutuantes magenta RGBA (0.85, 0.22, 0.88, 1.0).
- Anel planetário inclinado: Anel octogonal largo estilo Saturno inclinado em 30° em dourado estelar RGBA (1.0, 0.86, 0.35, 1.0) acompanhado de 3 mini-estrelas octaédricas orbitando ao redor.
- Orçamento: 240 a 420 triângulos.
```

### Orbe 8 — Orbe Mestre Suprema (100% Captura)
```text
Crie um script Python autossuficiente para Blender (bpy) que gere a "Orbe Mestre Suprema" no estilo Low-Poly épico para Roblox, com `shade_flat()`, materiais sólidos e Bevel aplicado.
Especificação visual:
- Núcleo: Dodecaedro branco-pérola RGBA (0.96, 0.96, 1.0, 1.0) envolto por faixas douradas RGBA (1.0, 0.80, 0.12, 1.0) e gema central arco-íris/magenta RGBA (0.95, 0.25, 0.78, 1.0).
- Asas geométricas laterais: Par de asas estilizadas em blocos angulares (3 penas prismáticas de cada lado) estendendo-se para cima em ouro e roxo real RGBA (0.48, 0.16, 0.85, 1.0).
- Coroa superior flutuante de 3 pontas acima da orbe.
- Orçamento: 300 a 480 triângulos.
```

---

## 🏛️ Parte 2 — Prompts das Estruturas 3D do Cenário

### Estrutura 1 — Pódio 3D Global (Top 1, 2 e 3)
```text
Crie um script Python para Blender (bpy) ou construtor modular que gere o "Pódio 3D dos Campeões" no estilo Voxel Studs do Roblox:
- Base retangular de degraus em mármore branco/cinza claro RGBA (0.90, 0.92, 0.96, 1.0).
- Degrau 1º Lugar (Centro, altura 3.2, largura 3.0): Dourado RGBA (0.98, 0.78, 0.14, 1.0) com grande placa frontal "1" em relevo e arco luminoso traseiro em colunas quadradas.
- Degrau 2º Lugar (Esquerda, altura 2.2, largura 2.6): Prateado RGBA (0.78, 0.82, 0.88, 1.0) com placa "2".
- Degrau 3º Lugar (Direita, altura 1.5, largura 2.6): Bronze RGBA (0.80, 0.48, 0.22, 1.0) com placa "3".
- Inclua espaços planos marcados ao lado de cada posição para posicionar o avatar do jogador + sua criatura mais rara. Use shade_flat() e Bevel aplicado.
```

### Estrutura 2 — Máquina de Fusão (5 → 1)
```text
Crie um script Python para Blender (bpy) que gere a "Máquina de Fusão Elemental" no estilo Voxel/Low-Poly para Roblox:
- Plataforma octogonal metálica cinza-escura RGBA (0.16, 0.18, 0.24, 1.0) com 5 pedestais pequenos em semicírculo na frente (para as 5 criaturas sacrificadas) conectados por faixas luminosas no chão até um grande tubo/cúpula hexagonal central de energia ciano-dourada RGBA (0.20, 0.90, 0.98, 1.0).
- Dois arcos mecânicos laterais apontando para o centro com engrenagens/blocos dourados no topo. Use shade_flat() e Bevel aplicado.
```

### Estrutura 3 — Portal de Bioma Escalonado
```text
Crie um script Python para Blender (bpy) que gere um "Portal de Bioma Modular" no estilo Voxel Studs para Roblox:
- Dois pilares laterais em blocos empilhados escalonados (altura 9.0) + arco superior chanfrado com placa de cristal central para exibir o nome do bioma e o custo de desbloqueio.
- Inclua `generate_variations()` gerando variações de cor para os 6 biomas (Floresta Neon ciano, Vulcão vermelho-magma, Abismo azul-gelo, Ruínas ouro-areia, Vazio roxo-cósmico). Use shade_flat() e Bevel aplicado.
```
