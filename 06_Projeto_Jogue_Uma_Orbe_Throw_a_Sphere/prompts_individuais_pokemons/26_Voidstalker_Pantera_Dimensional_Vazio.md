# 26. Voidstalker — Pantera Dimensional (Vazio Cósmico)

* **Elemento:** `Cósmico` | **Bioma:** `6. Vazio Cósmico` | **Raridade:** `Mítica`
* **Dificuldade de Captura:** `140000` | **Renda Base:** `$185.000/s` | **XP Base:** `2.800 XP`
* **Orçamento 3D:** `750 - 1.400 tris`

## 📋 Prompt Completo (Copie e Cole para Gerar este Modelo 3D)

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

## 🎬 Notas de Animação no Roblox Studio
* **Comportamento:** Caminhada furtiva deixando sombras roxas; micro-buraco negro na cauda pulsa.
* **Alvo Crítico (1.5x):** Posicionar a `Part` chamada `Head` no topo do modelo para que arremessos que atingirem a cabeça apliquem automaticamente o multiplicador crítico no servidor.
