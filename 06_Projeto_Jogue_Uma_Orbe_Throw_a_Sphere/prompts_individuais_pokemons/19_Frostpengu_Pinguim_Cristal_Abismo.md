# 19. Frostpengu — Pinguim de Cristal (Abismo Glacial)

* **Elemento:** `Gelo` | **Bioma:** `4. Abismo Glacial` | **Raridade:** `Incomum`
* **Dificuldade de Captura:** `1500` | **Renda Base:** `$1.500/s` | **XP Base:** `290 XP`
* **Orçamento 3D:** `350 - 650 tris`

## 📋 Prompt Completo (Copie e Cole para Gerar este Modelo 3D)

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

## 🎬 Notas de Animação no Roblox Studio
* **Comportamento:** Anda bamboleando de um lado para o outro e ocasionalmente desliza de barriga no gelo.
* **Alvo Crítico (1.5x):** Posicionar a `Part` chamada `Head` no topo do modelo para que arremessos que atingirem a cabeça apliquem automaticamente o multiplicador crítico no servidor.
