# 20. Cryoyeti — Colosso Glacial (Abismo Glacial)

* **Elemento:** `Gelo` | **Bioma:** `4. Abismo Glacial` | **Raridade:** `Mítica`
* **Dificuldade de Captura:** `2800` | **Renda Base:** `$3.200/s` | **XP Base:** `700 XP`
* **Orçamento 3D:** `750 - 1.400 tris`

## 📋 Prompt Completo (Copie e Cole para Gerar este Modelo 3D)

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Cryoyeti — Colosso Glacial (Abismo Glacial)" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

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

ESPECIFICAÇÃO DA CRIATURA (20. Cryoyeti):
- Elemento: Gelo | Bioma: 4. Abismo Glacial | Raridade: Mítica
- Paleta RGBA: Pelagem Branco Glacial (0.92, 0.96, 1.0, 1.0) | Chifres e Garras Preto/Azul Escuro (0.10, 0.15, 0.25, 1.0) | Ombros Cristal Ciano (0.30, 0.88, 1.0, 1.0)
- Anatomia Detalhada:
- Torso gigantesco em V (ombros muito largos, cintura estreita) com punhos maciços tocando quase o chão.
- Cabeça afundada entre os ombros com sobrancelhas vermelhas/azuis furiosas, dentes à mostra e dois chifres curvos.
- Agregados de cristais de gelo fincados nos dois ombros e nas costas.
- Pontos para Animação (Rigging / Studio): Bate os dois punhos no peito/chão periodicamente criando onda de gelo.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

## 🎬 Notas de Animação no Roblox Studio
* **Comportamento:** Bate os dois punhos no peito/chão periodicamente criando onda de gelo.
* **Alvo Crítico (1.5x):** Posicionar a `Part` chamada `Head` no topo do modelo para que arremessos que atingirem a cabeça apliquem automaticamente o multiplicador crítico no servidor.
