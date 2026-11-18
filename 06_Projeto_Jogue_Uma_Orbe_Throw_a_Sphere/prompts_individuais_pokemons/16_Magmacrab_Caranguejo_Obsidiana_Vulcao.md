# 16. Magmacrab — Caranguejo Obsidiana (Cânion Vulcânico)

* **Elemento:** `Fogo` | **Bioma:** `3. Cânion Vulcânico` | **Raridade:** `Rara`
* **Dificuldade de Captura:** `310` | **Renda Base:** `$310/s` | **XP Base:** `210 XP`
* **Orçamento 3D:** `450 - 780 tris`

## 📋 Prompt Completo (Copie e Cole para Gerar este Modelo 3D)

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

## 🎬 Notas de Animação no Roblox Studio
* **Comportamento:** Anda de lado (caranguejo); abre e fecha a pinça maior fazendo estalo.
* **Alvo Crítico (1.5x):** Posicionar a `Part` chamada `Head` no topo do modelo para que arremessos que atingirem a cabeça apliquem automaticamente o multiplicador crítico no servidor.
