# 17. Lavarex — Tirano de Magma (Cânion Vulcânico)

* **Elemento:** `Fogo` | **Bioma:** `3. Cânion Vulcânico` | **Raridade:** `Épica`
* **Dificuldade de Captura:** `420` | **Renda Base:** `$450/s` | **XP Base:** `260 XP`
* **Orçamento 3D:** `650 - 1.100 tris`

## 📋 Prompt Completo (Copie e Cole para Gerar este Modelo 3D)

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

## 🎬 Notas de Animação no Roblox Studio
* **Comportamento:** Passada pesada que treme suavemente; ruge abrindo a mandíbula e soltando fumaça.
* **Alvo Crítico (1.5x):** Posicionar a `Part` chamada `Head` no topo do modelo para que arremessos que atingirem a cabeça apliquem automaticamente o multiplicador crítico no servidor.
