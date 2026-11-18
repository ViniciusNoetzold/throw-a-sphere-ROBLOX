# 13. Glowshroom — Cogumelo Neon (Floresta Neon)

* **Elemento:** `Planta` | **Bioma:** `2. Floresta Neon` | **Raridade:** `Incomum`
* **Dificuldade de Captura:** `85` | **Renda Base:** `$75/s` | **XP Base:** `110 XP`
* **Orçamento 3D:** `340 - 600 tris`

## 📋 Prompt Completo (Copie e Cole para Gerar este Modelo 3D)

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

## 🎬 Notas de Animação no Roblox Studio
* **Comportamento:** Pulsa o chapéu (escala Y entre 0.95 e 1.08) emitindo esporos brilhantes.
* **Alvo Crítico (1.5x):** Posicionar a `Part` chamada `Head` no topo do modelo para que arremessos que atingirem a cabeça apliquem automaticamente o multiplicador crítico no servidor.
