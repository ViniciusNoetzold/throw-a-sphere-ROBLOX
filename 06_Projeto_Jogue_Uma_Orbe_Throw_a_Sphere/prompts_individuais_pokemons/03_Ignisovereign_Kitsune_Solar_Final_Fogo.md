# 03. Ignisovereign — Kitsune Solar (Evolução Final Fogo - Estágio 3)

* **Elemento:** `Fogo` | **Bioma:** `3. Cânion Vulcânico / Fusão` | **Raridade:** `Mítica`
* **Dificuldade de Captura:** `1150` | **Renda Base:** `$1.450/s` | **XP Base:** `650 XP`
* **Orçamento 3D:** `900 - 1.800 tris`

## 📋 Prompt Completo (Copie e Cole para Gerar este Modelo 3D)

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

## 🎬 Notas de Animação no Roblox Studio
* **Comportamento:** Anel solar gira 360° continuamente; 6+ caudas ondulam como chamas; aura de brasas subindo.
* **Alvo Crítico (1.5x):** Posicionar a `Part` chamada `Head` no topo do modelo para que arremessos que atingirem a cabeça apliquem automaticamente o multiplicador crítico no servidor.
