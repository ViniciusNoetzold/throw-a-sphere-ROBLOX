# 09. Gaiahorn — Titã Silvestre (Evolução Final Planta - Estágio 3)

* **Elemento:** `Planta` | **Bioma:** `2. Floresta Neon / Fusão` | **Raridade:** `Mítica`
* **Dificuldade de Captura:** `750` | **Renda Base:** `$880/s` | **XP Base:** `550 XP`
* **Orçamento 3D:** `900 - 1.700 tris`

## 📋 Prompt Completo (Copie e Cole para Gerar este Modelo 3D)

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

## 🎬 Notas de Animação no Roblox Studio
* **Comportamento:** Passo nobre e lento; luz pulsante na galhada dourada a cada 2 segundos.
* **Alvo Crítico (1.5x):** Posicionar a `Part` chamada `Head` no topo do modelo para que arremessos que atingirem a cabeça apliquem automaticamente o multiplicador crítico no servidor.
