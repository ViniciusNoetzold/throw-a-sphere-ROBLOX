# Catálogo Completo — 30 Prompts Individuais (1 por 1) das Criaturas

Cada criatura possui também seu **arquivo individual separado** na pasta `prompts_individuais_pokemons/` para você trabalhar uma por vez.

---

## 01. Pyrokit (Raposa de Brasa (Inicial de Fogo - Estágio 1))
- **Arquivo Individual:** `prompts_individuais_pokemons/01_Pyrokit_Raposa_de_Brasa_Inicial_Fogo.md`
- **Stats:** Elemento `Fogo` | Bioma `1. Pradaria Solar` | Raridade `Incomum (Inicial)` | Dificuldade `18` | Renda `$12/s`

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Pyrokit — Raposa de Brasa (Inicial de Fogo - Estágio 1)" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

REGRAS TÉCNICAS OBRIGATÓRIAS:
1. Shading sempre Flat: chamar `bpy.ops.object.shade_flat()` em todas as primitivas e no objeto final unido. Nunca usar Smooth Shading.
2. Materiais em Cor Sólida: criar materiais com `use_nodes = False` e definir `mat.diffuse_color = rgba`.
3. Geometria Facetada: usar cones (`radius1 != radius2`, 4 a 8 vértices) para partes que afunilam (caudas, orelhas, patas, chifres) e cubos escalonados para corpo e cabeça.
4. Bevel Final: após unir todas as partes com `bpy.ops.object.join()`, aplicar o modifier Bevel (`width=0.015` a `0.025`, `segments=2`, `limit_method='ANGLE'`) e aplicar imediatamente com `bpy.ops.object.modifier_apply(modifier="Bevel")`.
5. Estrutura do Código:
   - `CONFIG = { ... }` no topo com a paleta RGBA, dimensões e parâmetros de bevel.
   - Função `clean_existing_object(obj_name)` para limpar execuções anteriores.
   - Funções auxiliares (`create_cone`, `create_cylinder`, `create_cube`, `create_icosphere`).
   - Função principal de montagem usando posições relativas (ex: `torso -> neck -> head -> limbs -> tail`).
   - Função `generate_variations()` gerando a versão Normal, Dourada e Enorme (Huge) lado a lado.
6. Orçamento de Triângulos: 350 - 650 tris.

ESPECIFICAÇÃO DA CRIATURA (01. Pyrokit):
- Elemento: Fogo | Bioma: 1. Pradaria Solar | Raridade: Incomum (Inicial)
- Paleta RGBA: Corpo Laranja Brasa (0.98, 0.42, 0.10, 1.0) | Peito Creme (0.98, 0.90, 0.65, 1.0) | Ponta da Cauda e Orelhas Amarelo Fogo (1.0, 0.80, 0.12, 1.0) | Olhos Carvão/Âmbar (0.12, 0.08, 0.06, 1.0)
- Anatomia Detalhada:
- Torso compacto e levemente inclinado para frente (cubo chanfrado 1.2 x 1.6 x 1.0) com tufo creme no peito.
- Cabeça grande e fofa (1.3 x 1.2 x 1.1) com focinho pontudo curto e 2 orelhas triangulares longas feitas com cones de 4 lados.
- 4 patas curtas em cones facetados (6 vértices, radius1=0.22, radius2=0.15, altura 0.7).
- Cauda volumosa de chama em 3 segmentos cônicos empilhados apontando para cima com ponta amarelo-sol.
- Pontos para Animação (Rigging / Studio): Pivô da cauda balançando em arco; cabeça inclina 10° no Idle; orelhas abaixam ao se preparar para correr.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

---

## 02. Blazefox (Raposa Chamejante (Evolução Fogo - Estágio 2))
- **Arquivo Individual:** `prompts_individuais_pokemons/02_Blazefox_Raposa_Chamejante_Evo_Fogo.md`
- **Stats:** Elemento `Fogo` | Bioma `3. Cânion Vulcânico` | Raridade `Rara` | Dificuldade `320` | Renda `$280/s`

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Blazefox — Raposa Chamejante (Evolução Fogo - Estágio 2)" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

REGRAS TÉCNICAS OBRIGATÓRIAS:
1. Shading sempre Flat: chamar `bpy.ops.object.shade_flat()` em todas as primitivas e no objeto final unido. Nunca usar Smooth Shading.
2. Materiais em Cor Sólida: criar materiais com `use_nodes = False` e definir `mat.diffuse_color = rgba`.
3. Geometria Facetada: usar cones (`radius1 != radius2`, 4 a 8 vértices) para partes que afunilam (caudas, orelhas, patas, chifres) e cubos escalonados para corpo e cabeça.
4. Bevel Final: após unir todas as partes com `bpy.ops.object.join()`, aplicar o modifier Bevel (`width=0.015` a `0.025`, `segments=2`, `limit_method='ANGLE'`) e aplicar imediatamente com `bpy.ops.object.modifier_apply(modifier="Bevel")`.
5. Estrutura do Código:
   - `CONFIG = { ... }` no topo com a paleta RGBA, dimensões e parâmetros de bevel.
   - Função `clean_existing_object(obj_name)` para limpar execuções anteriores.
   - Funções auxiliares (`create_cone`, `create_cylinder`, `create_cube`, `create_icosphere`).
   - Função principal de montagem usando posições relativas (ex: `torso -> neck -> head -> limbs -> tail`).
   - Função `generate_variations()` gerando a versão Normal, Dourada e Enorme (Huge) lado a lado.
6. Orçamento de Triângulos: 500 - 800 tris.

ESPECIFICAÇÃO DA CRIATURA (02. Blazefox):
- Elemento: Fogo | Bioma: 3. Cânion Vulcânico | Raridade: Rara
- Paleta RGBA: Pelagem Vermelho Carmesim (0.88, 0.18, 0.12, 1.0) | Juba e Caudas Laranja (1.0, 0.52, 0.08, 1.0) | Garras Obsidiana (0.14, 0.14, 0.18, 1.0) | Olhos Ciano/Branco Brilhante (1.0, 0.92, 0.40, 1.0)
- Anatomia Detalhada:
- Corpo atlético bípede ou quadrúpede ágil (1.4 x 2.1 x 1.3) com juba pontiaguda ao redor do pescoço.
- Cabeça afiada estilo lobo/raposa com focinho alongado e sobrancelhas angulares marcantes.
- 3 caudas independentes em formato de chamas geométricas facetadas abertas em leque.
- Pulseiras de brasa/armadura simples nos tornozelos e garras pontudas escuras.
- Pontos para Animação (Rigging / Studio): 3 caudas oscilam em defasagem de fase; corrida rápida inclinando o corpo 20° para frente.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

---

## 03. Ignisovereign (Kitsune Solar (Evolução Final Fogo - Estágio 3))
- **Arquivo Individual:** `prompts_individuais_pokemons/03_Ignisovereign_Kitsune_Solar_Final_Fogo.md`
- **Stats:** Elemento `Fogo` | Bioma `3. Cânion Vulcânico / Fusão` | Raridade `Mítica` | Dificuldade `1150` | Renda `$1.450/s`

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Ignisovereign — Kitsune Solar (Evolução Final Fogo - Estágio 3)" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

REGRAS TÉCNICAS OBRIGATÓRIAS:
1. Shading sempre Flat: chamar `bpy.ops.object.shade_flat()` em todas as primitivas e no objeto final unido. Nunca usar Smooth Shading.
2. Materiais em Cor Sólida: criar materiais com `use_nodes = False` e definir `mat.diffuse_color = rgba`.
3. Geometria Facetada: usar cones (`radius1 != radius2`, 4 a 8 vértices) para partes que afunilam (caudas, orelhas, patas, chifres) e cubos escalonados para corpo e cabeça.
4. Bevel Final: após unir todas as partes com `bpy.ops.object.join()`, aplicar o modifier Bevel (`width=0.015` a `0.025`, `segments=2`, `limit_method='ANGLE'`) e aplicar imediatamente com `bpy.ops.object.modifier_apply(modifier="Bevel")`.
5. Estrutura do Código:
   - `CONFIG = { ... }` no topo com a paleta RGBA, dimensões e parâmetros de bevel.
   - Função `clean_existing_object(obj_name)` para limpar execuções anteriores.
   - Funções auxiliares (`create_cone`, `create_cylinder`, `create_cube`, `create_icosphere`).
   - Função principal de montagem usando posições relativas (ex: `torso -> neck -> head -> limbs -> tail`).
   - Função `generate_variations()` gerando a versão Normal, Dourada e Enorme (Huge) lado a lado.
6. Orçamento de Triângulos: 900 - 1.800 tris.

ESPECIFICAÇÃO DA CRIATURA (03. Ignisovereign):
- Elemento: Fogo | Bioma: 3. Cânion Vulcânico / Fusão | Raridade: Mítica
- Paleta RGBA: Corpo Dourado Solar (1.0, 0.78, 0.14, 1.0) | Marcas Sagradas Vermelho Rubi (0.85, 0.10, 0.15, 1.0) | Anel Solar nas Costas Branco/Ouro (1.0, 0.96, 0.75, 1.0)
- Anatomia Detalhada:
- Corpo imponente e esguio de Kitsune mítica com colar de esferas de fogo flutuantes ao redor do pescoço.
- Cabeça adornada com máscara/crista frontal solar em forma de coroa de 3 pontas.
- 6 a 9 caudas majestosas curvadas em leque radial atrás do corpo usando cones de 6 lados segmentados.
- Halo/Anel octogonal flutuante atrás dos ombros girando lentamente no jogo.
- Pontos para Animação (Rigging / Studio): Anel solar gira 360° continuamente; 6+ caudas ondulam como chamas; aura de brasas subindo.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

---

## 04. Aquapup (Lontra Cristal (Inicial de Água - Estágio 1))
- **Arquivo Individual:** `prompts_individuais_pokemons/04_Aquapup_Lontra_Cristal_Inicial_Agua.md`
- **Stats:** Elemento `Água` | Bioma `1. Pradaria Solar` | Raridade `Incomum (Inicial)` | Dificuldade `18` | Renda `$12/s`

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Aquapup — Lontra Cristal (Inicial de Água - Estágio 1)" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

REGRAS TÉCNICAS OBRIGATÓRIAS:
1. Shading sempre Flat: chamar `bpy.ops.object.shade_flat()` em todas as primitivas e no objeto final unido. Nunca usar Smooth Shading.
2. Materiais em Cor Sólida: criar materiais com `use_nodes = False` e definir `mat.diffuse_color = rgba`.
3. Geometria Facetada: usar cones (`radius1 != radius2`, 4 a 8 vértices) para partes que afunilam (caudas, orelhas, patas, chifres) e cubos escalonados para corpo e cabeça.
4. Bevel Final: após unir todas as partes com `bpy.ops.object.join()`, aplicar o modifier Bevel (`width=0.015` a `0.025`, `segments=2`, `limit_method='ANGLE'`) e aplicar imediatamente com `bpy.ops.object.modifier_apply(modifier="Bevel")`.
5. Estrutura do Código:
   - `CONFIG = { ... }` no topo com a paleta RGBA, dimensões e parâmetros de bevel.
   - Função `clean_existing_object(obj_name)` para limpar execuções anteriores.
   - Funções auxiliares (`create_cone`, `create_cylinder`, `create_cube`, `create_icosphere`).
   - Função principal de montagem usando posições relativas (ex: `torso -> neck -> head -> limbs -> tail`).
   - Função `generate_variations()` gerando a versão Normal, Dourada e Enorme (Huge) lado a lado.
6. Orçamento de Triângulos: 350 - 650 tris.

ESPECIFICAÇÃO DA CRIATURA (04. Aquapup):
- Elemento: Água | Bioma: 1. Pradaria Solar | Raridade: Incomum (Inicial)
- Paleta RGBA: Corpo Azul Oceano (0.16, 0.62, 0.96, 1.0) | Barriga Azul Gelo (0.72, 0.92, 1.0, 1.0) | Cristal no Peito e Barbatanas Ciano Neon (0.10, 0.95, 0.95, 1.0)
- Anatomia Detalhada:
- Corpo roliço de lontra sentada (1.3 x 1.5 x 1.2) com uma concha/cristal hexagonal encaixado na barriga.
- Cabeça arredondada low-poly com bochechas largas, nariz azul escuro e barbatanas laterais no lugar de orelhas.
- Cauda larga de remo achatada horizontalmente em forma de leque facetado.
- Pontos para Animação (Rigging / Studio): Balança o corpo lateralmente como um pinguim/lontra feliz; cauda bate no chão suavemente.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

---

## 05. Tidefang (Lobo Marinho (Evolução Água - Estágio 2))
- **Arquivo Individual:** `prompts_individuais_pokemons/05_Tidefang_Lobo_Marinho_Evo_Agua.md`
- **Stats:** Elemento `Água` | Bioma `4. Abismo Glacial` | Raridade `Rara` | Dificuldade `1600` | Renda `$1.800/s`

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Tidefang — Lobo Marinho (Evolução Água - Estágio 2)" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

REGRAS TÉCNICAS OBRIGATÓRIAS:
1. Shading sempre Flat: chamar `bpy.ops.object.shade_flat()` em todas as primitivas e no objeto final unido. Nunca usar Smooth Shading.
2. Materiais em Cor Sólida: criar materiais com `use_nodes = False` e definir `mat.diffuse_color = rgba`.
3. Geometria Facetada: usar cones (`radius1 != radius2`, 4 a 8 vértices) para partes que afunilam (caudas, orelhas, patas, chifres) e cubos escalonados para corpo e cabeça.
4. Bevel Final: após unir todas as partes com `bpy.ops.object.join()`, aplicar o modifier Bevel (`width=0.015` a `0.025`, `segments=2`, `limit_method='ANGLE'`) e aplicar imediatamente com `bpy.ops.object.modifier_apply(modifier="Bevel")`.
5. Estrutura do Código:
   - `CONFIG = { ... }` no topo com a paleta RGBA, dimensões e parâmetros de bevel.
   - Função `clean_existing_object(obj_name)` para limpar execuções anteriores.
   - Funções auxiliares (`create_cone`, `create_cylinder`, `create_cube`, `create_icosphere`).
   - Função principal de montagem usando posições relativas (ex: `torso -> neck -> head -> limbs -> tail`).
   - Função `generate_variations()` gerando a versão Normal, Dourada e Enorme (Huge) lado a lado.
6. Orçamento de Triângulos: 550 - 800 tris.

ESPECIFICAÇÃO DA CRIATURA (05. Tidefang):
- Elemento: Água | Bioma: 4. Abismo Glacial | Raridade: Rara
- Paleta RGBA: Azul Profundo (0.08, 0.30, 0.72, 1.0) | Barbatanas Turquesa (0.14, 0.85, 0.82, 1.0) | Presas e Garras Branco Pérola (0.94, 0.97, 1.0, 1.0)
- Anatomia Detalhada:
- Corpo hidrodinâmico alongado com grande barbatana dorsal serrilhada em 3 blocos triangulares.
- Cabeça feroz com duas presas externas saltando da mandíbula inferior e colar de espuma/cristal no pescoço.
- Cauda dupla bifurcada em formato de nadadeira de tubarão facetada.
- Pontos para Animação (Rigging / Studio): Movimento sinuoso de nado mesmo andando na terra; mandíbula abre/fecha ao detectar orbe.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

---

## 06. Leviathorn (Dragão Abissal (Evolução Final Água - Estágio 3))
- **Arquivo Individual:** `prompts_individuais_pokemons/06_Leviathorn_Dragao_Abissal_Final_Agua.md`
- **Stats:** Elemento `Água` | Bioma `4. Abismo Glacial / Fusão` | Raridade `Mítica` | Dificuldade `5500` | Renda `$6.400/s`

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Leviathorn — Dragão Abissal (Evolução Final Água - Estágio 3)" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

REGRAS TÉCNICAS OBRIGATÓRIAS:
1. Shading sempre Flat: chamar `bpy.ops.object.shade_flat()` em todas as primitivas e no objeto final unido. Nunca usar Smooth Shading.
2. Materiais em Cor Sólida: criar materiais com `use_nodes = False` e definir `mat.diffuse_color = rgba`.
3. Geometria Facetada: usar cones (`radius1 != radius2`, 4 a 8 vértices) para partes que afunilam (caudas, orelhas, patas, chifres) e cubos escalonados para corpo e cabeça.
4. Bevel Final: após unir todas as partes com `bpy.ops.object.join()`, aplicar o modifier Bevel (`width=0.015` a `0.025`, `segments=2`, `limit_method='ANGLE'`) e aplicar imediatamente com `bpy.ops.object.modifier_apply(modifier="Bevel")`.
5. Estrutura do Código:
   - `CONFIG = { ... }` no topo com a paleta RGBA, dimensões e parâmetros de bevel.
   - Função `clean_existing_object(obj_name)` para limpar execuções anteriores.
   - Funções auxiliares (`create_cone`, `create_cylinder`, `create_cube`, `create_icosphere`).
   - Função principal de montagem usando posições relativas (ex: `torso -> neck -> head -> limbs -> tail`).
   - Função `generate_variations()` gerando a versão Normal, Dourada e Enorme (Huge) lado a lado.
6. Orçamento de Triângulos: 1.000 - 2.000 tris.

ESPECIFICAÇÃO DA CRIATURA (06. Leviathorn):
- Elemento: Água | Bioma: 4. Abismo Glacial / Fusão | Raridade: Mítica
- Paleta RGBA: Escamas Índigo Abissal (0.06, 0.14, 0.42, 1.0) | Placas Bioluminescentes Ciano (0.12, 0.95, 1.0, 1.0) | Chifres Ouro Antigo (0.90, 0.75, 0.25, 1.0)
- Anatomia Detalhada:
- Corpo serpentino segmentado em 5 blocos articulados flutuando em onda S.
- Cabeça dracônica com 4 chifres curvos para trás e bigodes luminosos em ciano.
- Asas membranosas em formato de nadadeiras gigantes com nervuras rígidas facetadas.
- Pontos para Animação (Rigging / Studio): Flutua 1.5 studs acima do chão em movimento serpentino contínuo entre os 5 segmentos.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

---

## 07. Sproutling (Tatuzinho Folha (Inicial de Planta - Estágio 1))
- **Arquivo Individual:** `prompts_individuais_pokemons/07_Sproutling_Tatuzinho_Folha_Inicial_Planta.md`
- **Stats:** Elemento `Planta` | Bioma `1. Pradaria Solar` | Raridade `Comum (Inicial)` | Dificuldade `12` | Renda `$8/s`

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Sproutling — Tatuzinho Folha (Inicial de Planta - Estágio 1)" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

REGRAS TÉCNICAS OBRIGATÓRIAS:
1. Shading sempre Flat: chamar `bpy.ops.object.shade_flat()` em todas as primitivas e no objeto final unido. Nunca usar Smooth Shading.
2. Materiais em Cor Sólida: criar materiais com `use_nodes = False` e definir `mat.diffuse_color = rgba`.
3. Geometria Facetada: usar cones (`radius1 != radius2`, 4 a 8 vértices) para partes que afunilam (caudas, orelhas, patas, chifres) e cubos escalonados para corpo e cabeça.
4. Bevel Final: após unir todas as partes com `bpy.ops.object.join()`, aplicar o modifier Bevel (`width=0.015` a `0.025`, `segments=2`, `limit_method='ANGLE'`) e aplicar imediatamente com `bpy.ops.object.modifier_apply(modifier="Bevel")`.
5. Estrutura do Código:
   - `CONFIG = { ... }` no topo com a paleta RGBA, dimensões e parâmetros de bevel.
   - Função `clean_existing_object(obj_name)` para limpar execuções anteriores.
   - Funções auxiliares (`create_cone`, `create_cylinder`, `create_cube`, `create_icosphere`).
   - Função principal de montagem usando posições relativas (ex: `torso -> neck -> head -> limbs -> tail`).
   - Função `generate_variations()` gerando a versão Normal, Dourada e Enorme (Huge) lado a lado.
6. Orçamento de Triângulos: 300 - 550 tris.

ESPECIFICAÇÃO DA CRIATURA (07. Sproutling):
- Elemento: Planta | Bioma: 1. Pradaria Solar | Raridade: Comum (Inicial)
- Paleta RGBA: Corpo Verde Lima (0.35, 0.85, 0.28, 1.0) | Carapaça Musgo (0.14, 0.52, 0.20, 1.0) | Broto no Topo Verde Claro (0.62, 1.0, 0.32, 1.0)
- Anatomia Detalhada:
- Corpo oval/cúbico baixo protegido por 3 placas de carapaça verde-musgo nas costas.
- Grande broto com 2 folhas em formato de hélice nascendo exatamente no topo da cabeça (alvo crítico!).
- 4 patinhas curtas cilíndricas/cônicas de 6 lados e olhos redondos brilhantes.
- Pontos para Animação (Rigging / Studio): As 2 folhas do topo giram como hélice quando o monstro dá um pulinho feliz.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

---

## 08. Thornback (Golem Florido (Evolução Planta - Estágio 2))
- **Arquivo Individual:** `prompts_individuais_pokemons/08_Thornback_Golem_Florido_Evo_Planta.md`
- **Stats:** Elemento `Planta` | Bioma `2. Floresta Neon` | Raridade `Rara` | Dificuldade `130` | Renda `$110/s`

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Thornback — Golem Florido (Evolução Planta - Estágio 2)" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

REGRAS TÉCNICAS OBRIGATÓRIAS:
1. Shading sempre Flat: chamar `bpy.ops.object.shade_flat()` em todas as primitivas e no objeto final unido. Nunca usar Smooth Shading.
2. Materiais em Cor Sólida: criar materiais com `use_nodes = False` e definir `mat.diffuse_color = rgba`.
3. Geometria Facetada: usar cones (`radius1 != radius2`, 4 a 8 vértices) para partes que afunilam (caudas, orelhas, patas, chifres) e cubos escalonados para corpo e cabeça.
4. Bevel Final: após unir todas as partes com `bpy.ops.object.join()`, aplicar o modifier Bevel (`width=0.015` a `0.025`, `segments=2`, `limit_method='ANGLE'`) e aplicar imediatamente com `bpy.ops.object.modifier_apply(modifier="Bevel")`.
5. Estrutura do Código:
   - `CONFIG = { ... }` no topo com a paleta RGBA, dimensões e parâmetros de bevel.
   - Função `clean_existing_object(obj_name)` para limpar execuções anteriores.
   - Funções auxiliares (`create_cone`, `create_cylinder`, `create_cube`, `create_icosphere`).
   - Função principal de montagem usando posições relativas (ex: `torso -> neck -> head -> limbs -> tail`).
   - Função `generate_variations()` gerando a versão Normal, Dourada e Enorme (Huge) lado a lado.
6. Orçamento de Triângulos: 500 - 800 tris.

ESPECIFICAÇÃO DA CRIATURA (08. Thornback):
- Elemento: Planta | Bioma: 2. Floresta Neon | Raridade: Rara
- Paleta RGBA: Tronco/Corpo Marrom Casca (0.42, 0.26, 0.16, 1.0) | Espinhos e Folhas Verde Escuro (0.10, 0.58, 0.22, 1.0) | Flor Central Rosa Magenta (0.96, 0.28, 0.62, 1.0)
- Anatomia Detalhada:
- Tronco largo e robusto de golem quadrúpede/bípede com ombros assimétricos de pedra e madeira.
- Grande flor prismática de 6 pétalas magenta plantada nas costas com núcleo amarelo.
- Braços pesados terminando em punhos cúbicos cercados por espinhos cônicos.
- Pontos para Animação (Rigging / Studio): Caminhada pesada alternando ombros; flor nas costas abre e fecha lentamente.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

---

## 09. Gaiahorn (Titã Silvestre (Evolução Final Planta - Estágio 3))
- **Arquivo Individual:** `prompts_individuais_pokemons/09_Gaiahorn_Tita_Silvestre_Final_Planta.md`
- **Stats:** Elemento `Planta` | Bioma `2. Floresta Neon / Fusão` | Raridade `Mítica` | Dificuldade `750` | Renda `$880/s`

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Gaiahorn — Titã Silvestre (Evolução Final Planta - Estágio 3)" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

REGRAS TÉCNICAS OBRIGATÓRIAS:
1. Shading sempre Flat: chamar `bpy.ops.object.shade_flat()` em todas as primitivas e no objeto final unido. Nunca usar Smooth Shading.
2. Materiais em Cor Sólida: criar materiais com `use_nodes = False` e definir `mat.diffuse_color = rgba`.
3. Geometria Facetada: usar cones (`radius1 != radius2`, 4 a 8 vértices) para partes que afunilam (caudas, orelhas, patas, chifres) e cubos escalonados para corpo e cabeça.
4. Bevel Final: após unir todas as partes com `bpy.ops.object.join()`, aplicar o modifier Bevel (`width=0.015` a `0.025`, `segments=2`, `limit_method='ANGLE'`) e aplicar imediatamente com `bpy.ops.object.modifier_apply(modifier="Bevel")`.
5. Estrutura do Código:
   - `CONFIG = { ... }` no topo com a paleta RGBA, dimensões e parâmetros de bevel.
   - Função `clean_existing_object(obj_name)` para limpar execuções anteriores.
   - Funções auxiliares (`create_cone`, `create_cylinder`, `create_cube`, `create_icosphere`).
   - Função principal de montagem usando posições relativas (ex: `torso -> neck -> head -> limbs -> tail`).
   - Função `generate_variations()` gerando a versão Normal, Dourada e Enorme (Huge) lado a lado.
6. Orçamento de Triângulos: 900 - 1.700 tris.

ESPECIFICAÇÃO DA CRIATURA (09. Gaiahorn):
- Elemento: Planta | Bioma: 2. Floresta Neon / Fusão | Raridade: Mítica
- Paleta RGBA: Corpo Madeira Ancestral (0.34, 0.22, 0.14, 1.0) | Copa/Juba Verde Esmeralda (0.12, 0.76, 0.34, 1.0) | Galhada Dourada (0.96, 0.80, 0.20, 1.0)
- Anatomia Detalhada:
- Corpo de cervo/titã majestoso com placa de musgo e mini-árvores crescendo nos ombros.
- Enormes chifres ramificados em blocos dourados e verdes sustentando esferas de luz.
- Cascos sólidos cinza-pedra e olhos verde-esmeralda brilhantes.
- Pontos para Animação (Rigging / Studio): Passo nobre e lento; luz pulsante na galhada dourada a cada 2 segundos.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

---

## 10. Voltmouse (Ratinho Raio (Pradaria Solar))
- **Arquivo Individual:** `prompts_individuais_pokemons/10_Voltmouse_Ratinho_Raio_Pradaria.md`
- **Stats:** Elemento `Raio` | Bioma `1. Pradaria Solar` | Raridade `Rara` | Dificuldade `35` | Renda `$28/s`

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Voltmouse — Ratinho Raio (Pradaria Solar)" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

REGRAS TÉCNICAS OBRIGATÓRIAS:
1. Shading sempre Flat: chamar `bpy.ops.object.shade_flat()` em todas as primitivas e no objeto final unido. Nunca usar Smooth Shading.
2. Materiais em Cor Sólida: criar materiais com `use_nodes = False` e definir `mat.diffuse_color = rgba`.
3. Geometria Facetada: usar cones (`radius1 != radius2`, 4 a 8 vértices) para partes que afunilam (caudas, orelhas, patas, chifres) e cubos escalonados para corpo e cabeça.
4. Bevel Final: após unir todas as partes com `bpy.ops.object.join()`, aplicar o modifier Bevel (`width=0.015` a `0.025`, `segments=2`, `limit_method='ANGLE'`) e aplicar imediatamente com `bpy.ops.object.modifier_apply(modifier="Bevel")`.
5. Estrutura do Código:
   - `CONFIG = { ... }` no topo com a paleta RGBA, dimensões e parâmetros de bevel.
   - Função `clean_existing_object(obj_name)` para limpar execuções anteriores.
   - Funções auxiliares (`create_cone`, `create_cylinder`, `create_cube`, `create_icosphere`).
   - Função principal de montagem usando posições relativas (ex: `torso -> neck -> head -> limbs -> tail`).
   - Função `generate_variations()` gerando a versão Normal, Dourada e Enorme (Huge) lado a lado.
6. Orçamento de Triângulos: 350 - 650 tris.

ESPECIFICAÇÃO DA CRIATURA (10. Voltmouse):
- Elemento: Raio | Bioma: 1. Pradaria Solar | Raridade: Rara
- Paleta RGBA: Corpo Amarelo Elétrico (1.0, 0.86, 0.10, 1.0) | Listras e Orelhas Preto Grafite (0.12, 0.12, 0.15, 1.0) | Bochechas Laranja (1.0, 0.40, 0.10, 1.0)
- Anatomia Detalhada:
- Corpo pequeno e ágil com 2 listras pretas horizontais nas costas.
- Orelhas compridas pontudas inclinadas em V com pontas pretas.
- Cauda construída em zigue-zague com 3 prismas retangulares conectados em formato de raio.
- Pontos para Animação (Rigging / Studio): Salto rápido constante pelo bioma; cauda de raio vibra com pequenas faíscas.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

---

## 11. Fluffhop (Coelho Nuvem (Pradaria Solar))
- **Arquivo Individual:** `prompts_individuais_pokemons/11_Fluffhop_Coelho_Nuvem_Pradaria.md`
- **Stats:** Elemento `Planta` | Bioma `1. Pradaria Solar` | Raridade `Comum` | Dificuldade `14` | Renda `$9/s`

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Fluffhop — Coelho Nuvem (Pradaria Solar)" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

REGRAS TÉCNICAS OBRIGATÓRIAS:
1. Shading sempre Flat: chamar `bpy.ops.object.shade_flat()` em todas as primitivas e no objeto final unido. Nunca usar Smooth Shading.
2. Materiais em Cor Sólida: criar materiais com `use_nodes = False` e definir `mat.diffuse_color = rgba`.
3. Geometria Facetada: usar cones (`radius1 != radius2`, 4 a 8 vértices) para partes que afunilam (caudas, orelhas, patas, chifres) e cubos escalonados para corpo e cabeça.
4. Bevel Final: após unir todas as partes com `bpy.ops.object.join()`, aplicar o modifier Bevel (`width=0.015` a `0.025`, `segments=2`, `limit_method='ANGLE'`) e aplicar imediatamente com `bpy.ops.object.modifier_apply(modifier="Bevel")`.
5. Estrutura do Código:
   - `CONFIG = { ... }` no topo com a paleta RGBA, dimensões e parâmetros de bevel.
   - Função `clean_existing_object(obj_name)` para limpar execuções anteriores.
   - Funções auxiliares (`create_cone`, `create_cylinder`, `create_cube`, `create_icosphere`).
   - Função principal de montagem usando posições relativas (ex: `torso -> neck -> head -> limbs -> tail`).
   - Função `generate_variations()` gerando a versão Normal, Dourada e Enorme (Huge) lado a lado.
6. Orçamento de Triângulos: 320 - 580 tris.

ESPECIFICAÇÃO DA CRIATURA (11. Fluffhop):
- Elemento: Planta | Bioma: 1. Pradaria Solar | Raridade: Comum
- Paleta RGBA: Corpo Branco Nuvem (0.96, 0.97, 1.0, 1.0) | Colarinho Fofo Azul Céu (0.58, 0.84, 1.0, 1.0) | Interior Orelhas Rosa (1.0, 0.65, 0.78, 1.0)
- Anatomia Detalhada:
- Corpo pequeno e macio cercado por 4 cubos/icospheres ao redor do pescoço formando uma nuvem fofa.
- Duas orelhas longas dobradas ligeiramente para trás no topo.
- Pés traseiros grandes para saltos altos e rabinho redondo em forma de pompom facetado.
- Pontos para Animação (Rigging / Studio): Pula a cada 1.5s com squash-and-stretch vertical suave.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

---

## 12. Buzzleaf (Abelha Real (Pradaria Solar))
- **Arquivo Individual:** `prompts_individuais_pokemons/12_Buzzleaf_Abelha_Real_Pradaria.md`
- **Stats:** Elemento `Planta` | Bioma `1. Pradaria Solar` | Raridade `Incomum` | Dificuldade `24` | Renda `$18/s`

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Buzzleaf — Abelha Real (Pradaria Solar)" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

REGRAS TÉCNICAS OBRIGATÓRIAS:
1. Shading sempre Flat: chamar `bpy.ops.object.shade_flat()` em todas as primitivas e no objeto final unido. Nunca usar Smooth Shading.
2. Materiais em Cor Sólida: criar materiais com `use_nodes = False` e definir `mat.diffuse_color = rgba`.
3. Geometria Facetada: usar cones (`radius1 != radius2`, 4 a 8 vértices) para partes que afunilam (caudas, orelhas, patas, chifres) e cubos escalonados para corpo e cabeça.
4. Bevel Final: após unir todas as partes com `bpy.ops.object.join()`, aplicar o modifier Bevel (`width=0.015` a `0.025`, `segments=2`, `limit_method='ANGLE'`) e aplicar imediatamente com `bpy.ops.object.modifier_apply(modifier="Bevel")`.
5. Estrutura do Código:
   - `CONFIG = { ... }` no topo com a paleta RGBA, dimensões e parâmetros de bevel.
   - Função `clean_existing_object(obj_name)` para limpar execuções anteriores.
   - Funções auxiliares (`create_cone`, `create_cylinder`, `create_cube`, `create_icosphere`).
   - Função principal de montagem usando posições relativas (ex: `torso -> neck -> head -> limbs -> tail`).
   - Função `generate_variations()` gerando a versão Normal, Dourada e Enorme (Huge) lado a lado.
6. Orçamento de Triângulos: 360 - 650 tris.

ESPECIFICAÇÃO DA CRIATURA (12. Buzzleaf):
- Elemento: Planta | Bioma: 1. Pradaria Solar | Raridade: Incomum
- Paleta RGBA: Abdômen Amarelo Mel (1.0, 0.78, 0.12, 1.0) | Listras Marrom Escuro (0.24, 0.15, 0.10, 1.0) | Asas Ciano Translúcido (0.70, 0.95, 1.0, 1.0)
- Anatomia Detalhada:
- Corpo segmentado em 3 blocos listrados de amarelo e marrom com ferrão cônico atrás.
- 2 pares de asas em forma de folha chanfrada plana fixadas no topo do tórax.
- Pequena coroa de folha verde na cabeça e 2 antenas em L.
- Pontos para Animação (Rigging / Studio): Paira no ar a 2 studs do chão; asas batem em alta velocidade (oscilação de ±35°).
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

---

## 13. Glowshroom (Cogumelo Neon (Floresta Neon))
- **Arquivo Individual:** `prompts_individuais_pokemons/13_Glowshroom_Cogumelo_Neon_Floresta.md`
- **Stats:** Elemento `Planta` | Bioma `2. Floresta Neon` | Raridade `Incomum` | Dificuldade `85` | Renda `$75/s`

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Glowshroom — Cogumelo Neon (Floresta Neon)" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

REGRAS TÉCNICAS OBRIGATÓRIAS:
1. Shading sempre Flat: chamar `bpy.ops.object.shade_flat()` em todas as primitivas e no objeto final unido. Nunca usar Smooth Shading.
2. Materiais em Cor Sólida: criar materiais com `use_nodes = False` e definir `mat.diffuse_color = rgba`.
3. Geometria Facetada: usar cones (`radius1 != radius2`, 4 a 8 vértices) para partes que afunilam (caudas, orelhas, patas, chifres) e cubos escalonados para corpo e cabeça.
4. Bevel Final: após unir todas as partes com `bpy.ops.object.join()`, aplicar o modifier Bevel (`width=0.015` a `0.025`, `segments=2`, `limit_method='ANGLE'`) e aplicar imediatamente com `bpy.ops.object.modifier_apply(modifier="Bevel")`.
5. Estrutura do Código:
   - `CONFIG = { ... }` no topo com a paleta RGBA, dimensões e parâmetros de bevel.
   - Função `clean_existing_object(obj_name)` para limpar execuções anteriores.
   - Funções auxiliares (`create_cone`, `create_cylinder`, `create_cube`, `create_icosphere`).
   - Função principal de montagem usando posições relativas (ex: `torso -> neck -> head -> limbs -> tail`).
   - Função `generate_variations()` gerando a versão Normal, Dourada e Enorme (Huge) lado a lado.
6. Orçamento de Triângulos: 340 - 600 tris.

ESPECIFICAÇÃO DA CRIATURA (13. Glowshroom):
- Elemento: Planta | Bioma: 2. Floresta Neon | Raridade: Incomum
- Paleta RGBA: Caule Creme Lilás (0.88, 0.84, 0.96, 1.0) | Chapéu Roxo Neon (0.58, 0.16, 0.92, 1.0) | Pintas Ciano Brilhante (0.15, 0.95, 0.98, 1.0)
- Anatomia Detalhada:
- Corpo cilíndrico/cônico curto com 2 perninhas atarracadas.
- Chapéu largo de cogumelo formado por cone de 8 lados achatado e base chanfrada.
- 5 manchas cúbicas/hexagonais em ciano neon salientes sobre o chapéu.
- Pontos para Animação (Rigging / Studio): Pulsa o chapéu (escala Y entre 0.95 e 1.08) emitindo esporos brilhantes.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

---

## 14. Cybermantis (Louva-Deus Laser (Floresta Neon))
- **Arquivo Individual:** `prompts_individuais_pokemons/14_Cybermantis_Louva_Deus_Laser_Floresta.md`
- **Stats:** Elemento `Raio` | Bioma `2. Floresta Neon` | Raridade `Épica` | Dificuldade `165` | Renda `$165/s`

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Cybermantis — Louva-Deus Laser (Floresta Neon)" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

REGRAS TÉCNICAS OBRIGATÓRIAS:
1. Shading sempre Flat: chamar `bpy.ops.object.shade_flat()` em todas as primitivas e no objeto final unido. Nunca usar Smooth Shading.
2. Materiais em Cor Sólida: criar materiais com `use_nodes = False` e definir `mat.diffuse_color = rgba`.
3. Geometria Facetada: usar cones (`radius1 != radius2`, 4 a 8 vértices) para partes que afunilam (caudas, orelhas, patas, chifres) e cubos escalonados para corpo e cabeça.
4. Bevel Final: após unir todas as partes com `bpy.ops.object.join()`, aplicar o modifier Bevel (`width=0.015` a `0.025`, `segments=2`, `limit_method='ANGLE'`) e aplicar imediatamente com `bpy.ops.object.modifier_apply(modifier="Bevel")`.
5. Estrutura do Código:
   - `CONFIG = { ... }` no topo com a paleta RGBA, dimensões e parâmetros de bevel.
   - Função `clean_existing_object(obj_name)` para limpar execuções anteriores.
   - Funções auxiliares (`create_cone`, `create_cylinder`, `create_cube`, `create_icosphere`).
   - Função principal de montagem usando posições relativas (ex: `torso -> neck -> head -> limbs -> tail`).
   - Função `generate_variations()` gerando a versão Normal, Dourada e Enorme (Huge) lado a lado.
6. Orçamento de Triângulos: 500 - 800 tris.

ESPECIFICAÇÃO DA CRIATURA (14. Cybermantis):
- Elemento: Raio | Bioma: 2. Floresta Neon | Raridade: Épica
- Paleta RGBA: Exoesqueleto Verde Esmeralda (0.08, 0.78, 0.42, 1.0) | Lâminas Neon Ciano (0.10, 0.98, 0.96, 1.0) | Visor Preto (0.08, 0.09, 0.12, 1.0)
- Anatomia Detalhada:
- Tórax esguio erguido com abdômen traseiro segmentado em placa angular.
- Dois braços articulados terminando em grandes foices prismáticas ciano neon.
- Cabeça triangular invertida com visor futurista e duas longas antenas finas.
- Pontos para Animação (Rigging / Studio): Cruza e descruza as lâminas neon em guarda; movimenta-se com passos precisos.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

---

## 15. Neonlynx (Lince Holográfico (Chefe da Floresta Neon))
- **Arquivo Individual:** `prompts_individuais_pokemons/15_Neonlynx_Lince_Holografico_Floresta.md`
- **Stats:** Elemento `Raio` | Bioma `2. Floresta Neon` | Raridade `Mítica (Boss de Zona)` | Dificuldade `220` | Renda `$240/s`

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Neonlynx — Lince Holográfico (Chefe da Floresta Neon)" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

REGRAS TÉCNICAS OBRIGATÓRIAS:
1. Shading sempre Flat: chamar `bpy.ops.object.shade_flat()` em todas as primitivas e no objeto final unido. Nunca usar Smooth Shading.
2. Materiais em Cor Sólida: criar materiais com `use_nodes = False` e definir `mat.diffuse_color = rgba`.
3. Geometria Facetada: usar cones (`radius1 != radius2`, 4 a 8 vértices) para partes que afunilam (caudas, orelhas, patas, chifres) e cubos escalonados para corpo e cabeça.
4. Bevel Final: após unir todas as partes com `bpy.ops.object.join()`, aplicar o modifier Bevel (`width=0.015` a `0.025`, `segments=2`, `limit_method='ANGLE'`) e aplicar imediatamente com `bpy.ops.object.modifier_apply(modifier="Bevel")`.
5. Estrutura do Código:
   - `CONFIG = { ... }` no topo com a paleta RGBA, dimensões e parâmetros de bevel.
   - Função `clean_existing_object(obj_name)` para limpar execuções anteriores.
   - Funções auxiliares (`create_cone`, `create_cylinder`, `create_cube`, `create_icosphere`).
   - Função principal de montagem usando posições relativas (ex: `torso -> neck -> head -> limbs -> tail`).
   - Função `generate_variations()` gerando a versão Normal, Dourada e Enorme (Huge) lado a lado.
6. Orçamento de Triângulos: 700 - 1.200 tris.

ESPECIFICAÇÃO DA CRIATURA (15. Neonlynx):
- Elemento: Raio | Bioma: 2. Floresta Neon | Raridade: Mítica (Boss de Zona)
- Paleta RGBA: Corpo Índigo Escuro (0.12, 0.14, 0.28, 1.0) | Listras Rosa e Ciano Neon (0.96, 0.22, 0.78, 1.0) | Garras Elétricas (0.20, 0.95, 1.0, 1.0)
- Anatomia Detalhada:
- Silhueta de felino predador ágil com ombros pontudos e tufos neon nas pontas das orelhas.
- Listras geométricas salientes nas costas e patas traseiras musculosas.
- Rabo curto terminado em esfera/losango energético flutuante.
- Pontos para Animação (Rigging / Studio): Postura de caça agachada; tufos e listras piscam em ciclo neon.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

---

## 16. Magmacrab (Caranguejo Obsidiana (Cânion Vulcânico))
- **Arquivo Individual:** `prompts_individuais_pokemons/16_Magmacrab_Caranguejo_Obsidiana_Vulcao.md`
- **Stats:** Elemento `Fogo` | Bioma `3. Cânion Vulcânico` | Raridade `Rara` | Dificuldade `310` | Renda `$310/s`

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Magmacrab — Caranguejo Obsidiana (Cânion Vulcânico)" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

REGRAS TÉCNICAS OBRIGATÓRIAS:
1. Shading sempre Flat: chamar `bpy.ops.object.shade_flat()` em todas as primitivas e no objeto final unido. Nunca usar Smooth Shading.
2. Materiais em Cor Sólida: criar materiais com `use_nodes = False` e definir `mat.diffuse_color = rgba`.
3. Geometria Facetada: usar cones (`radius1 != radius2`, 4 a 8 vértices) para partes que afunilam (caudas, orelhas, patas, chifres) e cubos escalonados para corpo e cabeça.
4. Bevel Final: após unir todas as partes com `bpy.ops.object.join()`, aplicar o modifier Bevel (`width=0.015` a `0.025`, `segments=2`, `limit_method='ANGLE'`) e aplicar imediatamente com `bpy.ops.object.modifier_apply(modifier="Bevel")`.
5. Estrutura do Código:
   - `CONFIG = { ... }` no topo com a paleta RGBA, dimensões e parâmetros de bevel.
   - Função `clean_existing_object(obj_name)` para limpar execuções anteriores.
   - Funções auxiliares (`create_cone`, `create_cylinder`, `create_cube`, `create_icosphere`).
   - Função principal de montagem usando posições relativas (ex: `torso -> neck -> head -> limbs -> tail`).
   - Função `generate_variations()` gerando a versão Normal, Dourada e Enorme (Huge) lado a lado.
6. Orçamento de Triângulos: 450 - 780 tris.

ESPECIFICAÇÃO DA CRIATURA (16. Magmacrab):
- Elemento: Fogo | Bioma: 3. Cânion Vulcânico | Raridade: Rara
- Paleta RGBA: Casco Obsidiana (0.14, 0.12, 0.16, 1.0) | Fissuras de Lava Laranja (1.0, 0.36, 0.05, 1.0) | Pinças Amarelo Incandescente (1.0, 0.75, 0.10, 1.0)
- Anatomia Detalhada:
- Carapaça hexagonal larga e baixa de rocha vulcânica com fendas laranja brilhantes no topo.
- Duas pinças enormes assimétricas (a direita maior que a esquerda) feitas com blocos e cunhas.
- 6 patas articuladas laterais em cones facetados e dois olhos amarelos brilhantes.
- Pontos para Animação (Rigging / Studio): Anda de lado (caranguejo); abre e fecha a pinça maior fazendo estalo.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

---

## 17. Lavarex (Tirano de Magma (Cânion Vulcânico))
- **Arquivo Individual:** `prompts_individuais_pokemons/17_Lavarex_Tirano_Magma_Vulcao.md`
- **Stats:** Elemento `Fogo` | Bioma `3. Cânion Vulcânico` | Raridade `Épica` | Dificuldade `420` | Renda `$450/s`

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Lavarex — Tirano de Magma (Cânion Vulcânico)" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

REGRAS TÉCNICAS OBRIGATÓRIAS:
1. Shading sempre Flat: chamar `bpy.ops.object.shade_flat()` em todas as primitivas e no objeto final unido. Nunca usar Smooth Shading.
2. Materiais em Cor Sólida: criar materiais com `use_nodes = False` e definir `mat.diffuse_color = rgba`.
3. Geometria Facetada: usar cones (`radius1 != radius2`, 4 a 8 vértices) para partes que afunilam (caudas, orelhas, patas, chifres) e cubos escalonados para corpo e cabeça.
4. Bevel Final: após unir todas as partes com `bpy.ops.object.join()`, aplicar o modifier Bevel (`width=0.015` a `0.025`, `segments=2`, `limit_method='ANGLE'`) e aplicar imediatamente com `bpy.ops.object.modifier_apply(modifier="Bevel")`.
5. Estrutura do Código:
   - `CONFIG = { ... }` no topo com a paleta RGBA, dimensões e parâmetros de bevel.
   - Função `clean_existing_object(obj_name)` para limpar execuções anteriores.
   - Funções auxiliares (`create_cone`, `create_cylinder`, `create_cube`, `create_icosphere`).
   - Função principal de montagem usando posições relativas (ex: `torso -> neck -> head -> limbs -> tail`).
   - Função `generate_variations()` gerando a versão Normal, Dourada e Enorme (Huge) lado a lado.
6. Orçamento de Triângulos: 650 - 1.100 tris.

ESPECIFICAÇÃO DA CRIATURA (17. Lavarex):
- Elemento: Fogo | Bioma: 3. Cânion Vulcânico | Raridade: Épica
- Paleta RGBA: Pele Carmesim Escura (0.68, 0.10, 0.10, 1.0) | Crista Dorsal Magma (1.0, 0.48, 0.08, 1.0) | Dentes Branco Marfim (0.98, 0.96, 0.90, 1.0)
- Anatomia Detalhada:
- Corpo bípede robusto de T-Rex em blocos pesados com mandíbula quadrada grande e fileira de dentes cônicos.
- Braços curtos com 2 garras pretas e pernas grossas musculosas.
- Fileira de 5 espinhos dorsais incandescentes descendo da cabeça até a ponta da cauda grossa.
- Pontos para Animação (Rigging / Studio): Passada pesada que treme suavemente; ruge abrindo a mandíbula e soltando fumaça.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

---

## 18. Solarpheonix (Fênix Eterna (Chefe do Cânion Vulcânico))
- **Arquivo Individual:** `prompts_individuais_pokemons/18_Solarpheonix_Fenix_Eterna_Boss_Vulcao.md`
- **Stats:** Elemento `Fogo` | Bioma `3. Cânion Vulcânico` | Raridade `Lendária (Boss de Zona)` | Dificuldade `1200` | Renda `$1.600/s`

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Solarpheonix — Fênix Eterna (Chefe do Cânion Vulcânico)" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

REGRAS TÉCNICAS OBRIGATÓRIAS:
1. Shading sempre Flat: chamar `bpy.ops.object.shade_flat()` em todas as primitivas e no objeto final unido. Nunca usar Smooth Shading.
2. Materiais em Cor Sólida: criar materiais com `use_nodes = False` e definir `mat.diffuse_color = rgba`.
3. Geometria Facetada: usar cones (`radius1 != radius2`, 4 a 8 vértices) para partes que afunilam (caudas, orelhas, patas, chifres) e cubos escalonados para corpo e cabeça.
4. Bevel Final: após unir todas as partes com `bpy.ops.object.join()`, aplicar o modifier Bevel (`width=0.015` a `0.025`, `segments=2`, `limit_method='ANGLE'`) e aplicar imediatamente com `bpy.ops.object.modifier_apply(modifier="Bevel")`.
5. Estrutura do Código:
   - `CONFIG = { ... }` no topo com a paleta RGBA, dimensões e parâmetros de bevel.
   - Função `clean_existing_object(obj_name)` para limpar execuções anteriores.
   - Funções auxiliares (`create_cone`, `create_cylinder`, `create_cube`, `create_icosphere`).
   - Função principal de montagem usando posições relativas (ex: `torso -> neck -> head -> limbs -> tail`).
   - Função `generate_variations()` gerando a versão Normal, Dourada e Enorme (Huge) lado a lado.
6. Orçamento de Triângulos: 1.000 - 2.100 tris.

ESPECIFICAÇÃO DA CRIATURA (18. Solarpheonix):
- Elemento: Fogo | Bioma: 3. Cânion Vulcânico | Raridade: Lendária (Boss de Zona)
- Paleta RGBA: Corpo Laranja Solar (1.0, 0.45, 0.06, 1.0) | Pontas das Asas Amarelo Ouro (1.0, 0.90, 0.22, 1.0) | Crista Rubi (0.92, 0.14, 0.18, 1.0)
- Anatomia Detalhada:
- Corpo elegante de ave de rapina com peitoral blindado em placas angulares douradas.
- Enormes asas abertas compostas por 6 penas prismáticas escalonadas de cada lado.
- 3 longas fitas/penas de cauda terminando em losangos de fogo e crista flamejante na cabeça.
- Pontos para Animação (Rigging / Studio): Paira a 4 studs de altura batendo as grandes asas majestosamente e deixando rastro de fogo.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

---

## 19. Frostpengu (Pinguim de Cristal (Abismo Glacial))
- **Arquivo Individual:** `prompts_individuais_pokemons/19_Frostpengu_Pinguim_Cristal_Abismo.md`
- **Stats:** Elemento `Gelo` | Bioma `4. Abismo Glacial` | Raridade `Incomum` | Dificuldade `1500` | Renda `$1.500/s`

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Frostpengu — Pinguim de Cristal (Abismo Glacial)" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

REGRAS TÉCNICAS OBRIGATÓRIAS:
1. Shading sempre Flat: chamar `bpy.ops.object.shade_flat()` em todas as primitivas e no objeto final unido. Nunca usar Smooth Shading.
2. Materiais em Cor Sólida: criar materiais com `use_nodes = False` e definir `mat.diffuse_color = rgba`.
3. Geometria Facetada: usar cones (`radius1 != radius2`, 4 a 8 vértices) para partes que afunilam (caudas, orelhas, patas, chifres) e cubos escalonados para corpo e cabeça.
4. Bevel Final: após unir todas as partes com `bpy.ops.object.join()`, aplicar o modifier Bevel (`width=0.015` a `0.025`, `segments=2`, `limit_method='ANGLE'`) e aplicar imediatamente com `bpy.ops.object.modifier_apply(modifier="Bevel")`.
5. Estrutura do Código:
   - `CONFIG = { ... }` no topo com a paleta RGBA, dimensões e parâmetros de bevel.
   - Função `clean_existing_object(obj_name)` para limpar execuções anteriores.
   - Funções auxiliares (`create_cone`, `create_cylinder`, `create_cube`, `create_icosphere`).
   - Função principal de montagem usando posições relativas (ex: `torso -> neck -> head -> limbs -> tail`).
   - Função `generate_variations()` gerando a versão Normal, Dourada e Enorme (Huge) lado a lado.
6. Orçamento de Triângulos: 350 - 650 tris.

ESPECIFICAÇÃO DA CRIATURA (19. Frostpengu):
- Elemento: Gelo | Bioma: 4. Abismo Glacial | Raridade: Incomum
- Paleta RGBA: Costas Azul Marinho (0.12, 0.24, 0.48, 1.0) | Barriga Branca Neve (0.96, 0.98, 1.0, 1.0) | Bico e Cristais Ciano Gelo (0.45, 0.92, 1.0, 1.0)
- Anatomia Detalhada:
- Corpo ovóide/cúbico atarracado com 2 nadadeiras laterais achatadas.
- Sobrancelhas e crista feitas de 3 cristais pontudos de gelo azul-claro no topo da cabeça.
- Bico curto amarelo-alaranjado e pés largos em cunha.
- Pontos para Animação (Rigging / Studio): Anda bamboleando de um lado para o outro e ocasionalmente desliza de barriga no gelo.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

---

## 20. Cryoyeti (Colosso Glacial (Abismo Glacial))
- **Arquivo Individual:** `prompts_individuais_pokemons/20_Cryoyeti_Colosso_Glacial_Abismo.md`
- **Stats:** Elemento `Gelo` | Bioma `4. Abismo Glacial` | Raridade `Mítica` | Dificuldade `2800` | Renda `$3.200/s`

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Cryoyeti — Colosso Glacial (Abismo Glacial)" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

REGRAS TÉCNICAS OBRIGATÓRIAS:
1. Shading sempre Flat: chamar `bpy.ops.object.shade_flat()` em todas as primitivas e no objeto final unido. Nunca usar Smooth Shading.
2. Materiais em Cor Sólida: criar materiais com `use_nodes = False` e definir `mat.diffuse_color = rgba`.
3. Geometria Facetada: usar cones (`radius1 != radius2`, 4 a 8 vértices) para partes que afunilam (caudas, orelhas, patas, chifres) e cubos escalonados para corpo e cabeça.
4. Bevel Final: após unir todas as partes com `bpy.ops.object.join()`, aplicar o modifier Bevel (`width=0.015` a `0.025`, `segments=2`, `limit_method='ANGLE'`) e aplicar imediatamente com `bpy.ops.object.modifier_apply(modifier="Bevel")`.
5. Estrutura do Código:
   - `CONFIG = { ... }` no topo com a paleta RGBA, dimensões e parâmetros de bevel.
   - Função `clean_existing_object(obj_name)` para limpar execuções anteriores.
   - Funções auxiliares (`create_cone`, `create_cylinder`, `create_cube`, `create_icosphere`).
   - Função principal de montagem usando posições relativas (ex: `torso -> neck -> head -> limbs -> tail`).
   - Função `generate_variations()` gerando a versão Normal, Dourada e Enorme (Huge) lado a lado.
6. Orçamento de Triângulos: 750 - 1.400 tris.

ESPECIFICAÇÃO DA CRIATURA (20. Cryoyeti):
- Elemento: Gelo | Bioma: 4. Abismo Glacial | Raridade: Mítica
- Paleta RGBA: Pelagem Branco Glacial (0.92, 0.96, 1.0, 1.0) | Chifres e Garras Preto/Azul Escuro (0.10, 0.15, 0.25, 1.0) | Ombros Cristal Ciano (0.30, 0.88, 1.0, 1.0)
- Anatomia Detalhada:
- Torso gigantesco em V (ombros muito largos, cintura estreita) com punhos maciços tocando quase o chão.
- Cabeça afundada entre os ombros com sobrancelhas vermelhas/azuis furiosas, dentes à mostra e dois chifres curvos.
- Agregados de cristais de gelo fincados nos dois ombros e nas costas.
- Pontos para Animação (Rigging / Studio): Bate os dois punhos no peito/chão periodicamente criando onda de gelo.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

---

## 21. Abysskraken (Kraken Bioluminescente (Chefe do Abismo))
- **Arquivo Individual:** `prompts_individuais_pokemons/21_Abysskraken_Kraken_Bioluminescente_Boss_Abismo.md`
- **Stats:** Elemento `Água` | Bioma `4. Abismo Glacial` | Raridade `Lendária (Boss de Zona)` | Dificuldade `7200` | Renda `$8.500/s`

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Abysskraken — Kraken Bioluminescente (Chefe do Abismo)" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

REGRAS TÉCNICAS OBRIGATÓRIAS:
1. Shading sempre Flat: chamar `bpy.ops.object.shade_flat()` em todas as primitivas e no objeto final unido. Nunca usar Smooth Shading.
2. Materiais em Cor Sólida: criar materiais com `use_nodes = False` e definir `mat.diffuse_color = rgba`.
3. Geometria Facetada: usar cones (`radius1 != radius2`, 4 a 8 vértices) para partes que afunilam (caudas, orelhas, patas, chifres) e cubos escalonados para corpo e cabeça.
4. Bevel Final: após unir todas as partes com `bpy.ops.object.join()`, aplicar o modifier Bevel (`width=0.015` a `0.025`, `segments=2`, `limit_method='ANGLE'`) e aplicar imediatamente com `bpy.ops.object.modifier_apply(modifier="Bevel")`.
5. Estrutura do Código:
   - `CONFIG = { ... }` no topo com a paleta RGBA, dimensões e parâmetros de bevel.
   - Função `clean_existing_object(obj_name)` para limpar execuções anteriores.
   - Funções auxiliares (`create_cone`, `create_cylinder`, `create_cube`, `create_icosphere`).
   - Função principal de montagem usando posições relativas (ex: `torso -> neck -> head -> limbs -> tail`).
   - Função `generate_variations()` gerando a versão Normal, Dourada e Enorme (Huge) lado a lado.
6. Orçamento de Triângulos: 1.100 - 2.200 tris.

ESPECIFICAÇÃO DA CRIATURA (21. Abysskraken):
- Elemento: Água | Bioma: 4. Abismo Glacial | Raridade: Lendária (Boss de Zona)
- Paleta RGBA: Corpo Azul Abissal (0.06, 0.18, 0.38, 1.0) | Ventosas e Olhos Neon Turquesa (0.10, 0.98, 0.88, 1.0)
- Anatomia Detalhada:
- Cabeça em formato de elmo/domo de lula gigante com duas abas laterais angulares.
- 6 a 8 tentáculos longos construídos com segmentos cônicos curvados para cima, com blocos brilhantes turquesa (ventosas).
- Olhos ferozes brilhando sob o manto frontal.
- Pontos para Animação (Rigging / Studio): Flutua girando lentamente enquanto os tentáculos se mexem em ondas alternadas.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

---

## 22. Runegolem (Sentinela Dourado (Ruínas Ancestrais))
- **Arquivo Individual:** `prompts_individuais_pokemons/22_Runegolem_Sentinela_Dourado_Ruinas.md`
- **Stats:** Elemento `Terra` | Bioma `5. Ruínas Ancestrais` | Raridade `Épica` | Dificuldade `12000` | Renda `$14.000/s`

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Runegolem — Sentinela Dourado (Ruínas Ancestrais)" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

REGRAS TÉCNICAS OBRIGATÓRIAS:
1. Shading sempre Flat: chamar `bpy.ops.object.shade_flat()` em todas as primitivas e no objeto final unido. Nunca usar Smooth Shading.
2. Materiais em Cor Sólida: criar materiais com `use_nodes = False` e definir `mat.diffuse_color = rgba`.
3. Geometria Facetada: usar cones (`radius1 != radius2`, 4 a 8 vértices) para partes que afunilam (caudas, orelhas, patas, chifres) e cubos escalonados para corpo e cabeça.
4. Bevel Final: após unir todas as partes com `bpy.ops.object.join()`, aplicar o modifier Bevel (`width=0.015` a `0.025`, `segments=2`, `limit_method='ANGLE'`) e aplicar imediatamente com `bpy.ops.object.modifier_apply(modifier="Bevel")`.
5. Estrutura do Código:
   - `CONFIG = { ... }` no topo com a paleta RGBA, dimensões e parâmetros de bevel.
   - Função `clean_existing_object(obj_name)` para limpar execuções anteriores.
   - Funções auxiliares (`create_cone`, `create_cylinder`, `create_cube`, `create_icosphere`).
   - Função principal de montagem usando posições relativas (ex: `torso -> neck -> head -> limbs -> tail`).
   - Função `generate_variations()` gerando a versão Normal, Dourada e Enorme (Huge) lado a lado.
6. Orçamento de Triângulos: 600 - 1.100 tris.

ESPECIFICAÇÃO DA CRIATURA (22. Runegolem):
- Elemento: Terra | Bioma: 5. Ruínas Ancestrais | Raridade: Épica
- Paleta RGBA: Pedra Arenito (0.78, 0.64, 0.42, 1.0) | Armadura Ouro Antigo (0.96, 0.78, 0.22, 1.0) | Núcleo Rúnico Turquesa (0.15, 0.95, 0.85, 1.0)
- Anatomia Detalhada:
- Corpo modular desconectado: torso grande com um cristal rúnico turquesa girando no vazio do peito.
- Braços e ombros flutuando 0.3 unidades separados do tronco por energia rúnica.
- Cabeça cúbica monolítica com 1 único olho visor horizontal luminoso.
- Pontos para Animação (Rigging / Studio): Braços e cabeça levitam levemente separados do tronco; núcleo peitoral gira sem parar.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

---

## 23. Anubispecter (Chacal Astral (Ruínas Ancestrais))
- **Arquivo Individual:** `prompts_individuais_pokemons/23_Anubispecter_Chacal_Astral_Ruinas.md`
- **Stats:** Elemento `Terra` | Bioma `5. Ruínas Ancestrais` | Raridade `Mítica` | Dificuldade `24000` | Renda `$28.500/s`

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Anubispecter — Chacal Astral (Ruínas Ancestrais)" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

REGRAS TÉCNICAS OBRIGATÓRIAS:
1. Shading sempre Flat: chamar `bpy.ops.object.shade_flat()` em todas as primitivas e no objeto final unido. Nunca usar Smooth Shading.
2. Materiais em Cor Sólida: criar materiais com `use_nodes = False` e definir `mat.diffuse_color = rgba`.
3. Geometria Facetada: usar cones (`radius1 != radius2`, 4 a 8 vértices) para partes que afunilam (caudas, orelhas, patas, chifres) e cubos escalonados para corpo e cabeça.
4. Bevel Final: após unir todas as partes com `bpy.ops.object.join()`, aplicar o modifier Bevel (`width=0.015` a `0.025`, `segments=2`, `limit_method='ANGLE'`) e aplicar imediatamente com `bpy.ops.object.modifier_apply(modifier="Bevel")`.
5. Estrutura do Código:
   - `CONFIG = { ... }` no topo com a paleta RGBA, dimensões e parâmetros de bevel.
   - Função `clean_existing_object(obj_name)` para limpar execuções anteriores.
   - Funções auxiliares (`create_cone`, `create_cylinder`, `create_cube`, `create_icosphere`).
   - Função principal de montagem usando posições relativas (ex: `torso -> neck -> head -> limbs -> tail`).
   - Função `generate_variations()` gerando a versão Normal, Dourada e Enorme (Huge) lado a lado.
6. Orçamento de Triângulos: 750 - 1.350 tris.

ESPECIFICAÇÃO DA CRIATURA (23. Anubispecter):
- Elemento: Terra | Bioma: 5. Ruínas Ancestrais | Raridade: Mítica
- Paleta RGBA: Corpo Obsidiana Negra (0.10, 0.10, 0.14, 1.0) | Adornos Ouro Real (0.98, 0.80, 0.18, 1.0) | Olhos e Cajado Roxo Astral (0.68, 0.25, 0.98, 1.0)
- Anatomia Detalhada:
- Corpo bípede esguio de guardião com saia/armadura egípcia geométrica em ouro e preto.
- Cabeça clássica de chacal com focinho longo retangular e duas orelhas verticais muito altas e pontudas.
- Anel/Colar largo dourado nos ombros e esfera astral flutuando atrás da cabeça.
- Pontos para Animação (Rigging / Studio): Levita silenciosamente sobre as areias com braços cruzados ou estendidos.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

---

## 24. Chronoswyrm (Serpente do Tempo (Chefe das Ruínas))
- **Arquivo Individual:** `prompts_individuais_pokemons/24_Chronoswyrm_Serpente_do_Tempo_Boss_Ruinas.md`
- **Stats:** Elemento `Terra` | Bioma `5. Ruínas Ancestrais` | Raridade `Lendária (Boss de Zona)` | Dificuldade `45000` | Renda `$55.000/s`

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Chronoswyrm — Serpente do Tempo (Chefe das Ruínas)" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

REGRAS TÉCNICAS OBRIGATÓRIAS:
1. Shading sempre Flat: chamar `bpy.ops.object.shade_flat()` em todas as primitivas e no objeto final unido. Nunca usar Smooth Shading.
2. Materiais em Cor Sólida: criar materiais com `use_nodes = False` e definir `mat.diffuse_color = rgba`.
3. Geometria Facetada: usar cones (`radius1 != radius2`, 4 a 8 vértices) para partes que afunilam (caudas, orelhas, patas, chifres) e cubos escalonados para corpo e cabeça.
4. Bevel Final: após unir todas as partes com `bpy.ops.object.join()`, aplicar o modifier Bevel (`width=0.015` a `0.025`, `segments=2`, `limit_method='ANGLE'`) e aplicar imediatamente com `bpy.ops.object.modifier_apply(modifier="Bevel")`.
5. Estrutura do Código:
   - `CONFIG = { ... }` no topo com a paleta RGBA, dimensões e parâmetros de bevel.
   - Função `clean_existing_object(obj_name)` para limpar execuções anteriores.
   - Funções auxiliares (`create_cone`, `create_cylinder`, `create_cube`, `create_icosphere`).
   - Função principal de montagem usando posições relativas (ex: `torso -> neck -> head -> limbs -> tail`).
   - Função `generate_variations()` gerando a versão Normal, Dourada e Enorme (Huge) lado a lado.
6. Orçamento de Triângulos: 1.100 - 2.300 tris.

ESPECIFICAÇÃO DA CRIATURA (24. Chronoswyrm):
- Elemento: Terra | Bioma: 5. Ruínas Ancestrais | Raridade: Lendária (Boss de Zona)
- Paleta RGBA: Placas Bronze/Ouro (0.88, 0.68, 0.22, 1.0) | Corpo Mármore Branco (0.92, 0.92, 0.96, 1.0) | Engrenagens Ciano Tempo (0.20, 0.92, 1.0, 1.0)
- Anatomia Detalhada:
- Grande serpente alada mecânico-mística em 6 segmentos blindados.
- Dois anéis de relógio/engrenagem octogonais flutuando ao redor do pescoço.
- Cabeça coroada com ampulheta luminosa na testa.
- Pontos para Animação (Rigging / Studio): Anéis temporais giram em sentidos opostos ao redor do corpo ondulante.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

---

## 25. Nebulimp (Diabrete Estelar (Vazio Cósmico))
- **Arquivo Individual:** `prompts_individuais_pokemons/25_Nebulimp_Diabrete_Estelar_Vazio.md`
- **Stats:** Elemento `Cósmico` | Bioma `6. Vazio Cósmico` | Raridade `Épica` | Dificuldade `65000` | Renda `$82.000/s`

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Nebulimp — Diabrete Estelar (Vazio Cósmico)" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

REGRAS TÉCNICAS OBRIGATÓRIAS:
1. Shading sempre Flat: chamar `bpy.ops.object.shade_flat()` em todas as primitivas e no objeto final unido. Nunca usar Smooth Shading.
2. Materiais em Cor Sólida: criar materiais com `use_nodes = False` e definir `mat.diffuse_color = rgba`.
3. Geometria Facetada: usar cones (`radius1 != radius2`, 4 a 8 vértices) para partes que afunilam (caudas, orelhas, patas, chifres) e cubos escalonados para corpo e cabeça.
4. Bevel Final: após unir todas as partes com `bpy.ops.object.join()`, aplicar o modifier Bevel (`width=0.015` a `0.025`, `segments=2`, `limit_method='ANGLE'`) e aplicar imediatamente com `bpy.ops.object.modifier_apply(modifier="Bevel")`.
5. Estrutura do Código:
   - `CONFIG = { ... }` no topo com a paleta RGBA, dimensões e parâmetros de bevel.
   - Função `clean_existing_object(obj_name)` para limpar execuções anteriores.
   - Funções auxiliares (`create_cone`, `create_cylinder`, `create_cube`, `create_icosphere`).
   - Função principal de montagem usando posições relativas (ex: `torso -> neck -> head -> limbs -> tail`).
   - Função `generate_variations()` gerando a versão Normal, Dourada e Enorme (Huge) lado a lado.
6. Orçamento de Triângulos: 420 - 750 tris.

ESPECIFICAÇÃO DA CRIATURA (25. Nebulimp):
- Elemento: Cósmico | Bioma: 6. Vazio Cósmico | Raridade: Épica
- Paleta RGBA: Corpo Roxo Nebulosa (0.38, 0.12, 0.72, 1.0) | Chifres e Cauda Rosa Estelar (0.98, 0.32, 0.78, 1.0) | Olhos Amarelo Estrela (1.0, 0.94, 0.35, 1.0)
- Anatomia Detalhada:
- Corpo pequeno travesso com grande cabeça redonda/facetada e sorriso largo em blocos.
- Chifres curvados para cima, asinhas triangulares nas costas e cauda fina terminando em uma estrela de 4 pontas.
- Duas mini-luas orbitando o topo da cabeça.
- Pontos para Animação (Rigging / Studio): Dá piruetas no ar enquanto flutua; mini-luas orbitam rapidamente.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

---

## 26. Voidstalker (Pantera Dimensional (Vazio Cósmico))
- **Arquivo Individual:** `prompts_individuais_pokemons/26_Voidstalker_Pantera_Dimensional_Vazio.md`
- **Stats:** Elemento `Cósmico` | Bioma `6. Vazio Cósmico` | Raridade `Mítica` | Dificuldade `140000` | Renda `$185.000/s`

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Voidstalker — Pantera Dimensional (Vazio Cósmico)" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

REGRAS TÉCNICAS OBRIGATÓRIAS:
1. Shading sempre Flat: chamar `bpy.ops.object.shade_flat()` em todas as primitivas e no objeto final unido. Nunca usar Smooth Shading.
2. Materiais em Cor Sólida: criar materiais com `use_nodes = False` e definir `mat.diffuse_color = rgba`.
3. Geometria Facetada: usar cones (`radius1 != radius2`, 4 a 8 vértices) para partes que afunilam (caudas, orelhas, patas, chifres) e cubos escalonados para corpo e cabeça.
4. Bevel Final: após unir todas as partes com `bpy.ops.object.join()`, aplicar o modifier Bevel (`width=0.015` a `0.025`, `segments=2`, `limit_method='ANGLE'`) e aplicar imediatamente com `bpy.ops.object.modifier_apply(modifier="Bevel")`.
5. Estrutura do Código:
   - `CONFIG = { ... }` no topo com a paleta RGBA, dimensões e parâmetros de bevel.
   - Função `clean_existing_object(obj_name)` para limpar execuções anteriores.
   - Funções auxiliares (`create_cone`, `create_cylinder`, `create_cube`, `create_icosphere`).
   - Função principal de montagem usando posições relativas (ex: `torso -> neck -> head -> limbs -> tail`).
   - Função `generate_variations()` gerando a versão Normal, Dourada e Enorme (Huge) lado a lado.
6. Orçamento de Triângulos: 750 - 1.400 tris.

ESPECIFICAÇÃO DA CRIATURA (26. Voidstalker):
- Elemento: Cósmico | Bioma: 6. Vazio Cósmico | Raridade: Mítica
- Paleta RGBA: Corpo Negro Vazio (0.06, 0.05, 0.12, 1.0) | Manchas Galácticas Magenta/Ciano (0.85, 0.20, 0.95, 1.0) | Cauda Fenda Brilhante (0.35, 0.90, 1.0, 1.0)
- Anatomia Detalhada:
- Pantera esguia com patas afiadas e 2 ombreiras flutuantes em forma de crescente.
- Cristais estelares saindo ao longo da coluna vertebral.
- Cauda longa bifurcada na ponta segurando um micro-buraco negro (esfera preta com anel ciano).
- Pontos para Animação (Rigging / Studio): Caminhada furtiva deixando sombras roxas; micro-buraco negro na cauda pulsa.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

---

## 27. Astraldragon (Dragão Galáctico (Chefe Final do Vazio))
- **Arquivo Individual:** `prompts_individuais_pokemons/27_Astraldragon_Dragao_Galactico_Boss_Vazio.md`
- **Stats:** Elemento `Cósmico` | Bioma `6. Vazio Cósmico` | Raridade `Lendária (Boss Final)` | Dificuldade `320000` | Renda `$450.000/s`

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Astraldragon — Dragão Galáctico (Chefe Final do Vazio)" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

REGRAS TÉCNICAS OBRIGATÓRIAS:
1. Shading sempre Flat: chamar `bpy.ops.object.shade_flat()` em todas as primitivas e no objeto final unido. Nunca usar Smooth Shading.
2. Materiais em Cor Sólida: criar materiais com `use_nodes = False` e definir `mat.diffuse_color = rgba`.
3. Geometria Facetada: usar cones (`radius1 != radius2`, 4 a 8 vértices) para partes que afunilam (caudas, orelhas, patas, chifres) e cubos escalonados para corpo e cabeça.
4. Bevel Final: após unir todas as partes com `bpy.ops.object.join()`, aplicar o modifier Bevel (`width=0.015` a `0.025`, `segments=2`, `limit_method='ANGLE'`) e aplicar imediatamente com `bpy.ops.object.modifier_apply(modifier="Bevel")`.
5. Estrutura do Código:
   - `CONFIG = { ... }` no topo com a paleta RGBA, dimensões e parâmetros de bevel.
   - Função `clean_existing_object(obj_name)` para limpar execuções anteriores.
   - Funções auxiliares (`create_cone`, `create_cylinder`, `create_cube`, `create_icosphere`).
   - Função principal de montagem usando posições relativas (ex: `torso -> neck -> head -> limbs -> tail`).
   - Função `generate_variations()` gerando a versão Normal, Dourada e Enorme (Huge) lado a lado.
6. Orçamento de Triângulos: 1.200 - 2.400 tris.

ESPECIFICAÇÃO DA CRIATURA (27. Astraldragon):
- Elemento: Cósmico | Bioma: 6. Vazio Cósmico | Raridade: Lendária (Boss Final)
- Paleta RGBA: Escamas Índigo Estelar (0.10, 0.08, 0.28, 1.0) | Asas Constelação Ouro/Rosa (1.0, 0.78, 0.25, 1.0) | Anéis Cósmicos Neon (0.94, 0.28, 0.88, 1.0)
- Anatomia Detalhada:
- Grande dragão quadrúpede/alado com corpo escuro salpicado de blocos brilhantes estilo constelação.
- Duas asas enormes em armação geométrica dourada com membranas roxas translúcidas.
- Anéis planetários dourados envolvendo o pescoço e a cauda longa com espinhos magenta.
- Pontos para Animação (Rigging / Studio): Paira majestosamente com bater lento de asas; emite partículas de estrelas.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

---

## 28. Eclipsion (Lendário do Evento Eclipse Solar)
- **Arquivo Individual:** `prompts_individuais_pokemons/28_Eclipsion_Lendario_Evento_Eclipse.md`
- **Stats:** Elemento `Cósmico` | Bioma `Evento Global: Eclipse (A cada 20 min)` | Raridade `Lendária (Evento)` | Dificuldade `180000` | Renda `$260.000/s`

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Eclipsion — Lendário do Evento Eclipse Solar" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

REGRAS TÉCNICAS OBRIGATÓRIAS:
1. Shading sempre Flat: chamar `bpy.ops.object.shade_flat()` em todas as primitivas e no objeto final unido. Nunca usar Smooth Shading.
2. Materiais em Cor Sólida: criar materiais com `use_nodes = False` e definir `mat.diffuse_color = rgba`.
3. Geometria Facetada: usar cones (`radius1 != radius2`, 4 a 8 vértices) para partes que afunilam (caudas, orelhas, patas, chifres) e cubos escalonados para corpo e cabeça.
4. Bevel Final: após unir todas as partes com `bpy.ops.object.join()`, aplicar o modifier Bevel (`width=0.015` a `0.025`, `segments=2`, `limit_method='ANGLE'`) e aplicar imediatamente com `bpy.ops.object.modifier_apply(modifier="Bevel")`.
5. Estrutura do Código:
   - `CONFIG = { ... }` no topo com a paleta RGBA, dimensões e parâmetros de bevel.
   - Função `clean_existing_object(obj_name)` para limpar execuções anteriores.
   - Funções auxiliares (`create_cone`, `create_cylinder`, `create_cube`, `create_icosphere`).
   - Função principal de montagem usando posições relativas (ex: `torso -> neck -> head -> limbs -> tail`).
   - Função `generate_variations()` gerando a versão Normal, Dourada e Enorme (Huge) lado a lado.
6. Orçamento de Triângulos: 900 - 1.900 tris.

ESPECIFICAÇÃO DA CRIATURA (28. Eclipsion):
- Elemento: Cósmico | Bioma: Evento Global: Eclipse (A cada 20 min) | Raridade: Lendária (Evento)
- Paleta RGBA: Núcleo Negro Eclipse (0.04, 0.04, 0.06, 1.0) | Coroa de Luz Laranja/Branca (1.0, 0.65, 0.10, 1.0) | Manto Roxo Real (0.32, 0.10, 0.55, 1.0)
- Anatomia Detalhada:
- Ser celestial sem pernas com torso envolto por um manto angular flutuante em camadas.
- Cabeça formada por um disco preto central cercado por um anel brilhante de eclipse solar e 8 raios prismáticos.
- 4 braços flutuantes estilizados com mãos em formato de crescentes lunares.
- Pontos para Animação (Rigging / Studio): Os 8 raios da coroa giram lentamente; mãos orbitam em postura mística.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

---

## 29. Meteorgon (Colosso da Chuva de Meteoros)
- **Arquivo Individual:** `prompts_individuais_pokemons/29_Meteorgon_Lendario_Evento_Meteoro.md`
- **Stats:** Elemento `Fogo` | Bioma `Evento Global: Chuva de Meteoros` | Raridade `Lendária (Evento)` | Dificuldade `210000` | Renda `$310.000/s`

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Meteorgon — Colosso da Chuva de Meteoros" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

REGRAS TÉCNICAS OBRIGATÓRIAS:
1. Shading sempre Flat: chamar `bpy.ops.object.shade_flat()` em todas as primitivas e no objeto final unido. Nunca usar Smooth Shading.
2. Materiais em Cor Sólida: criar materiais com `use_nodes = False` e definir `mat.diffuse_color = rgba`.
3. Geometria Facetada: usar cones (`radius1 != radius2`, 4 a 8 vértices) para partes que afunilam (caudas, orelhas, patas, chifres) e cubos escalonados para corpo e cabeça.
4. Bevel Final: após unir todas as partes com `bpy.ops.object.join()`, aplicar o modifier Bevel (`width=0.015` a `0.025`, `segments=2`, `limit_method='ANGLE'`) e aplicar imediatamente com `bpy.ops.object.modifier_apply(modifier="Bevel")`.
5. Estrutura do Código:
   - `CONFIG = { ... }` no topo com a paleta RGBA, dimensões e parâmetros de bevel.
   - Função `clean_existing_object(obj_name)` para limpar execuções anteriores.
   - Funções auxiliares (`create_cone`, `create_cylinder`, `create_cube`, `create_icosphere`).
   - Função principal de montagem usando posições relativas (ex: `torso -> neck -> head -> limbs -> tail`).
   - Função `generate_variations()` gerando a versão Normal, Dourada e Enorme (Huge) lado a lado.
6. Orçamento de Triângulos: 950 - 2.000 tris.

ESPECIFICAÇÃO DA CRIATURA (29. Meteorgon):
- Elemento: Fogo | Bioma: Evento Global: Chuva de Meteoros | Raridade: Lendária (Evento)
- Paleta RGBA: Rocha Espacial Grafite (0.18, 0.16, 0.22, 1.0) | Núcleo Meteoro Magenta/Laranja (1.0, 0.30, 0.45, 1.0) | Cristais Estelares (0.25, 0.90, 1.0, 1.0)
- Anatomia Detalhada:
- Golem titânico feito de blocos de asteroide irregulares ligados por veios incandescentes.
- Cristais cósmicos cravados no peito e nas costas em ângulos variados.
- Braços massivos com antebraços em formato de cometa pontiagudo.
- Pontos para Animação (Rigging / Studio): Gira o torso de pedra antes de socar o chão; deixa rastro flamejante ao mover-se.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

---

## 30. Omnisfera (Entidade Secreta (1 em 1.000.000))
- **Arquivo Individual:** `prompts_individuais_pokemons/30_Omnisfera_Secreto_1_em_1_Milhao.md`
- **Stats:** Elemento `Cósmico` | Bioma `Todos os Biomas (Spawn Secreto Global)` | Raridade `Secreta (1 in 1M)` | Dificuldade `500000` | Renda `$1.000.000/s`

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Omnisfera — Entidade Secreta (1 em 1.000.000)" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

REGRAS TÉCNICAS OBRIGATÓRIAS:
1. Shading sempre Flat: chamar `bpy.ops.object.shade_flat()` em todas as primitivas e no objeto final unido. Nunca usar Smooth Shading.
2. Materiais em Cor Sólida: criar materiais com `use_nodes = False` e definir `mat.diffuse_color = rgba`.
3. Geometria Facetada: usar cones (`radius1 != radius2`, 4 a 8 vértices) para partes que afunilam (caudas, orelhas, patas, chifres) e cubos escalonados para corpo e cabeça.
4. Bevel Final: após unir todas as partes com `bpy.ops.object.join()`, aplicar o modifier Bevel (`width=0.015` a `0.025`, `segments=2`, `limit_method='ANGLE'`) e aplicar imediatamente com `bpy.ops.object.modifier_apply(modifier="Bevel")`.
5. Estrutura do Código:
   - `CONFIG = { ... }` no topo com a paleta RGBA, dimensões e parâmetros de bevel.
   - Função `clean_existing_object(obj_name)` para limpar execuções anteriores.
   - Funções auxiliares (`create_cone`, `create_cylinder`, `create_cube`, `create_icosphere`).
   - Função principal de montagem usando posições relativas (ex: `torso -> neck -> head -> limbs -> tail`).
   - Função `generate_variations()` gerando a versão Normal, Dourada e Enorme (Huge) lado a lado.
6. Orçamento de Triângulos: 1.200 - 2.500 tris.

ESPECIFICAÇÃO DA CRIATURA (30. Omnisfera):
- Elemento: Cósmico | Bioma: Todos os Biomas (Spawn Secreto Global) | Raridade: Secreta (1 in 1M)
- Paleta RGBA: Núcleo Branco Puro/Arco-Íris (1.0, 1.0, 1.0, 1.0) | Anéis Dourado Celestial (1.0, 0.85, 0.20, 1.0) | Placas Ciano/Magenta (0.20, 0.95, 1.0, 1.0)
- Anatomia Detalhada:
- Núcleo central icosaédrico brilhante cercado por 3 anéis giroscópicos concêntricos inclinados em eixos diferentes.
- 6 asas de luz geométricas desconectadas dispostas em hexágono atrás do núcleo.
- Coroa tridimensional de cristal flutuando sobre o anel externo + olhos místicos no núcleo central.
- Pontos para Animação (Rigging / Studio): Os 3 anéis giram simultaneamente nos eixos X, Y e Z; as 6 asas respiram expandindo radialmente.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

---
