# 04. Aquapup — Lontra Cristal (Inicial de Água - Estágio 1)

* **Elemento:** `Água` | **Bioma:** `1. Pradaria Solar` | **Raridade:** `Incomum (Inicial)`
* **Dificuldade de Captura:** `18` | **Renda Base:** `$12/s` | **XP Base:** `40 XP`
* **Orçamento 3D:** `350 - 650 tris`

## 📋 Prompt Completo (Copie e Cole para Gerar este Modelo 3D)

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

## 🎬 Notas de Animação no Roblox Studio
* **Comportamento:** Balança o corpo lateralmente como um pinguim/lontra feliz; cauda bate no chão suavemente.
* **Alvo Crítico (1.5x):** Posicionar a `Part` chamada `Head` no topo do modelo para que arremessos que atingirem a cabeça apliquem automaticamente o multiplicador crítico no servidor.
