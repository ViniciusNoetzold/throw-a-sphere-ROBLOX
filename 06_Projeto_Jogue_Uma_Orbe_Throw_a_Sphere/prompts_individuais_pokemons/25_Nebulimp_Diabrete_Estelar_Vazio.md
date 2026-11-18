# 25. Nebulimp — Diabrete Estelar (Vazio Cósmico)

* **Elemento:** `Cósmico` | **Bioma:** `6. Vazio Cósmico` | **Raridade:** `Épica`
* **Dificuldade de Captura:** `65000` | **Renda Base:** `$82.000/s` | **XP Base:** `1.900 XP`
* **Orçamento 3D:** `420 - 750 tris`

## 📋 Prompt Completo (Copie e Cole para Gerar este Modelo 3D)

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

## 🎬 Notas de Animação no Roblox Studio
* **Comportamento:** Dá piruetas no ar enquanto flutua; mini-luas orbitam rapidamente.
* **Alvo Crítico (1.5x):** Posicionar a `Part` chamada `Head` no topo do modelo para que arremessos que atingirem a cabeça apliquem automaticamente o multiplicador crítico no servidor.
