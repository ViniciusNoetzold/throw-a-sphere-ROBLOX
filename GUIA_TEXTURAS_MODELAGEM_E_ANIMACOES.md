# Guia Técnico: Texturas Reais, Modelagem 3D e Animações

Este guia analisa em detalhes **como os gráficos, texturas, modelos 3D e animações dos 4 jogos são construídos tecnicamente**, utilizando evidências retiradas diretamente das **capturas reais dentro dos jogos** e fornecendo **texturas e scripts prontos para usar** no Roblox Studio e no Blender.

---

## 1. Análise das Texturas Reais (Observadas no Jogo)

Ao examinar os recortes em zoom (`05_Texturas_e_Modelagem_3D/analise_visual_modelos_reais/`), identificamos **três técnicas visuais fundamentais** usadas por quase todos os jogos desse estilo no Roblox:

### A) Textura de "Square Studs" (Pinos Quadrados Clássicos 2006–2013)
* **Evidência real:** Observe `zoom_04_detalhe_chao_square_studs_e_planta_blocos.png` e `zoom_02_modelo_golden_apple_tree_e_ui.png`.
* **Como ela é:** Diferente dos studs redondos modernos do Roblox, esses jogos usam o estilo **Square Stud (pino quadrado vazado/chanfrado)**: um quadrado externo elevado com uma cavidade quadrada interna que gera sombra no lado inferior/direito e brilho no lado superior/esquerdo.
* **Por que usam isso?**
  1. Dá uma leitura imediata de escala no mundo (cada stud = 1 unidade de medida do Roblox, facilitando perceber o quão gigante é uma árvore *Titanic* ou um pet *Huge*).
  2. Cria uma identidade nostálgica e extremamente limpa visualmente, sem "ruído" fotorealista que cansa a vista no celular.

### B) Textura de "Inlets" (Encaixes Inferiores)
* **Evidência real:** Observe `zoom_01_modelo_pinheiro_wedges_e_inlets.png`.
* **Como ela é:** Na base branca embaixo do pinheiro (e em faces inferiores/laterais de certas peças), vê-se pequenos quadrados rebaixados em grade regular. Esse é o padrão clássico de **Inlet** (a parte de baixo das peças estilo LEGO do Roblox antigo).

### C) Piso e Paredes em "Grade Xadrez Bicolor" (*Checkered Stud Grid*)
* **Evidência real:** Visível no chão verde (`zoom_03` e `zoom_04`), nas paredes do cânion marrom (`02_gameplay_real_jardim_fiona_e_plantas.png`) e no cânion noturno roxo/azul (`03_gameplay_real_canion_noturno_cristais.png`).
* **Como é feito na prática:**
  * O terreno não usa o `Terrain` suave nativo do Roblox. Ele é montado com **blocos `Part` (ou uma textura repetida em `Texture`/`MaterialVariant`)** alternando duas tonalidades da mesma cor:
    * **Grama:** `#4CD92B` (claro) e `#3FC022` (médio)
    * **Terra/Parede:** `#96643A` (claro) e `#7E522E` (escuro)
    * **Noturno/Cristal:** `#262460` (claro) e `#1B1947` (escuro)
  * Cada quadrado do tabuleiro costuma equivaler a **2×2 ou 4×4 studs**.

### 📁 Texturas Prontas Incluídas Nesta Pasta (`texturas_prontas/`)
Geramos para você 6 arquivos PNG tileables (sem emendas) prontos para importar no Roblox Studio (como `Image` / `MaterialVariant` / `SurfaceAppearance`) ou no Blender:

1. `textura_stud_quadrado_topo_color.png` (`512×512`) — Matriz 4×4 de Square Studs neutros (pode ser multiplicada por qualquer cor usando `Color3` ou `Texture.Color3`).
2. `textura_inlet_quadrado_base_color.png` (`512×512`) — Matriz 4×4 de Inlets (encaixes inferiores).
3. `textura_stud_quadrado_normal_map.png` (`512×512`) — **Normal Map** em espaço tangente (`#8080FF` com chanfros nos eixos X/Y) para gerar relevo real sob a luz do Roblox Studio (`SurfaceAppearance.NormalMap` / `MaterialVariant.NormalMap`) ou Blender.
4. `textura_grama_xadrez_com_studs.png` (`1024×1024`) — Textura completa já pronta do piso verde xadrez com studs.
5. `textura_parede_terra_xadrez_com_studs.png` (`1024×1024`) — Textura completa pronta das paredes marrons do cânion com studs.
6. `textura_canion_noturno_xadrez_com_studs.png` (`1024×1024`) — Textura completa pronta do bioma noturno com studs.

#### Como Aplicar no Roblox Studio (2 Métodos)
* **Método 1 — `MaterialVariant` (Recomendado para performance):**
  1. Suba `textura_stud_quadrado_topo_color.png` (como *ColorMap*) e `textura_stud_quadrado_normal_map.png` (como *NormalMap*) no **Asset Manager**.
  2. Em `MaterialService`, crie um `MaterialVariant` com `BaseMaterial = SmoothPlastic`, defina `StudsPerTile = 4` e conecte os dois mapas.
  3. Qualquer `Part` que usar esse `MaterialVariant` ficará automaticamente com studs nítidos e coloridos conforme a `Part.Color`, consumindo memória mínima!
* **Método 2 — `Texture` em cada face (ou script):**
  * Veja o arquivo pronto `scripts_exemplo/RobloxStudio_TerrenoXadrez_e_Mutacoes.luau`, que também demonstra o uso direto de `TopSurface = Enum.SurfaceType.Studs` e `Texture` com `StudsPerTileU / V`.

---

## 2. Como São Feitos os Modelos 3D

Analisando os quatro zoom reais e as renders promocionais, os modelos seguem a filosofia **"Low-Part / Modular Voxel"**:

### 1. Plantas e Árvores (Exemplos reais de *Throw a Seed* e *Throw Food*)
* **Pinheiro (`zoom_01_modelo_pinheiro_wedges_e_inlets.png`):**
  * Base branca levemente chanfrada com `Inlets` visíveis.
  * Tronco curto central (`Part` retangular).
  * Copa construída por **3 a 4 andares empilhados de blocos verdes e anéis brancos** (`Part` e `WedgePart` inclinadas), cada andar ligeiramente menor que o de baixo.
* **Golden Apple Tree (`zoom_02_modelo_golden_apple_tree_e_ui.png`):**
  * Tronco marrom vertical formado por **blocos `Part` empilhados e escalonados**, com **raízes e galhos criados simplesmente rotacionando `Parts` retangulares em 35°–55°** via `CFrame.Angles`.
  * Folhagem feita com **cubos verdes agrupados de tamanhos variados** (sem folhas individuais ou transparência alfa).
  * Maçãs douradas são **cubos pequenos amarelos com um mini-bloco marrom/verde em cima** funcionando como cabo e folha!
* **Árvore de Blocos Coloridos (`zoom_04_detalhe_chao_square_studs_e_planta_blocos.png`):**
  * Um bloco base cinza-escuro no chão, 3 ou 4 galhos retos inclinados saindo do centro e blocos retangulares vermelhos e amarelos encaixados nas pontas formando a copa.
* **Baobab, Grape Vine e Orange Tree (`zoom_03_modelos_baobab_videira_laranjeira_jardim.png`):**
  * Formas icônicas simplificadas: o *Baobab* tem um tronco cinza-bege largo em formato de garrafa facetada com poucos tufos verdes no topo e frutinhas roxas cúbicas; a *Grape Vine* é um pequeno arco de madeira com cachos de cubinhos roxos.

### 2. Ovos, Guardiões e Montarias (Exemplos de *Steal An Egg* e *+1 Ride Pets to Fight*)
* **Em *Steal An Egg*:**
  * Criaturas como o *T-Rex*, *Viper* e *Yeti* são montadas com blocos prismáticos e `WedgeParts` para focinhos, dentes triangulares/cônicos simples, garras pretas pontudas e olhos em blocos `Neon` brilhantes.
  * Ovos são **esferas/ovoides low-poly facetados** feitos no Blender (ou `MeshPart`) com placas externas anexadas (cristais de gelo no *Yeti Egg*, placas de rocha e gemas âmbar no *Trex Egg*).
* **Em *+1 Ride Pets to Fight*:**
  * As montarias (*Wyvern Dourado*, *Frost Kitsune*, *Dragão Chinês*) combinam **modelagem voxel de alto detalhe no Blender/Blockbench** (múltiplos segmentos angulares para espinhos, asas com membranas finas e nove caudas articuláveis) com **textura sólida/flat shading**, garantindo silhueta super agressiva e pouquíssimos polígonos.
  * Para que o jogador monte no pet, o modelo inclui um `Seat` ou ponto de montagem (`Attachment` / `Motor6D`) no pescoço/dorso da criatura.

### 🛠️ Quais Ferramentas Usar para Criar Modelos Iguais?
| Ferramenta | Melhor Uso | Como Exportar / Usar |
| :--- | :--- | :--- |
| **Roblox Studio (Parts + WedgeParts)** | Terrenos xadrez, árvores blocadas, cercas, barras de treino, esteiras | Nativo — zero importação e textura de Stud aplicada na hora |
| **Blockbench** | Criaturas voxel estilo *Kitsune*, *T-Rex*, ovos estilizados, comidas | Exportar `.obj` / `.fbx` ou usar paleta de textura pixelada |
| **Blender (`bpy`)** | Ovos facetados, dragões low-poly, frutos estilizados com chanfro (*Bevel*) | Use o script pronto `scripts_exemplo/Blender_Gerador_Arvore_e_Pet_VoxelStuds.py` e exporte em `.fbx` |

---

## 3. Como Funcionam Mutações, Escalas, UI e Animações no Roblox

### 1. Tamanhos Dinâmicos (*Big, Huge, Titanic, Infinite*)
* Em vez de modelar 5 versões da mesma árvore ou animal, o desenvolvedor cria **apenas 1 modelo base** (`Model`) e ajusta tudo via código Luau com `Model:ScaleTo(fator)`:
  * Normal = `1.0` | Big = `1.4` | Huge = `2.2` | Titanic = `3.5+`
* Isso redimensiona proporcionalmente todas as `Parts`, `Attachments`, `Welds` e a distância do `BillboardGui`.

### 2. Efeitos Visuais de Mutação e Raridade
* **Gold / Diamond / Emerald / Ruby:** Alteram `Part.Material` (`Foil`, `Glass`, `Neon`, `SmoothPlastic`), aplicam tonalidade via `Color3:Lerp()` e adicionam um objeto **`Highlight`** dentro do `Model` para gerar o contorno colorido brilhante.
* **Rainbow:** Um loop leve em `RunService.Heartbeat` (ou `task.spawn`) atualiza a cor com `Color3.fromHSV(hue, 0.85, 1)` variando `hue` de `0` a `1` continuamente.
* **Pilares de Luz Vertical (visto em `zoom_03`):** São criados com **2 `Attachments`** (um no centro da planta e outro 40–60 studs acima no céu) ligados por um **`Beam`** com transparência gradual (`NumberSequence` indo de `0.2` na base até `1.0` no topo) e `LightEmission = 1`.

### 3. Sistema de Animações Usado nos 4 Jogos
* **Treino (Barras / Esteira):** `AnimationTrack` em loop na `Humanoid.Animator` do avatar. A barra fixa sobe e desce o corpo no eixo Y; a esteira acelera a `PlaybackSpeed` da animação de corrida conforme o nível do equipamento.
* **Arremesso Parabólico (*Throw a Seed* / *Throw Food*):**
  * Em vez de depender apenas de física (`BasePart:ApplyImpulse`) — que pode travar ou variar conforme o FPS do jogador — jogos modernos usam **trajetória matemática determinística (Curva de Bézier Quadrática)** no `Heartbeat`:
    $$P(t) = (1-t)^2 P_0 + 2(1-t)t P_1 + t^2 P_2$$
  * Isso garante que o jogo já saiba exatamente em qual zona e coordenada a semente/comida vai cair, enquanto a câmera acompanha `P(t)` suavemente com um `Trail` branco/amarelo ligado ao projétil.
* **Brotamento Elástico (*Sprout Tween*):**
  * Ao pousar, a planta nasce com escala `0.05` e cresce até a escala final em ~`0.65s` usando `TweenService` com `Enum.EasingStyle.Back` (dando aquele efeito gostoso de "pulo/estalo" ao surgir do chão).
* **Interface Flutuante (`BillboardGui` + `UIStroke`):**
  * Fontes grossas e arredondadas (`FredokaOne`, `GothamBlack`) sempre acompanhadas de `UIStroke` preto (`Thickness = 2` a `3`), garantindo leitura perfeita contra grama verde clara, neve ou lava.

---

## 4. Arquivos Prontos na Pasta `scripts_exemplo/`

1. **`RobloxStudio_TerrenoXadrez_e_Mutacoes.luau`**:
   * Cria o chão xadrez bicolor com `Studs` e `Inlets`.
   * Constrói uma árvore voxel modular por código.
   * Executa a animação de brotamento elástico.
   * Gera 3 versões lado a lado (*Normal*, *Gold* e *Rainbow* animada em tempo real) com `Highlight` e `BillboardGui` (`$/s`).
2. **`Blender_Gerador_Arvore_e_Pet_VoxelStuds.py`**:
   * Script Python autossuficiente para colar na aba *Scripting* do Blender e gerar instantaneamente o **Terreno Xadrez 4×4**, **Variações de Árvore Voxel** e uma **Montaria/Pet Low-Poly** com *Flat Shading*, cores sólidas e chanfro *Bevel* pronto para exportar ao Roblox.
