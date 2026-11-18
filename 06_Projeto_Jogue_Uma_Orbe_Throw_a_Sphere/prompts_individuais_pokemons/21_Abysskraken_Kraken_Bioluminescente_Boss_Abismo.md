# 21. Abysskraken — Kraken Bioluminescente (Chefe do Abismo)

* **Elemento:** `Água` | **Bioma:** `4. Abismo Glacial` | **Raridade:** `Lendária (Boss de Zona)`
* **Dificuldade de Captura:** `7200` | **Renda Base:** `$8.500/s` | **XP Base:** `1.200 XP`
* **Orçamento 3D:** `1.100 - 2.200 tris`

## 📋 Prompt Completo (Copie e Cole para Gerar este Modelo 3D)

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Abysskraken — Kraken Bioluminescente (Chefe do Abismo)" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

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
6. Orçamento de Triângulos: 1.100 - 2.200 tris.

ESPECIFICAÇÃO DA CRIATURA (21. Abysskraken):
- Elemento: Água | Bioma: 4. Abismo Glacial | Raridade: Lendária (Boss de Zona)
- Paleta RGBA: Corpo Azul Abissal (0.06, 0.18, 0.38, 1.0) | Ventosas e Olhos Neon Turquesa (0.10, 0.98, 0.88, 1.0)
- Anatomia Detalhada:
- Cabeça em formato de elmo/domo de lula gigante com duas abas laterais angulares.
- 6 a 8 tentáculos longos construídos com segmentos cônicos curvados para cima, com blocos brilhantes turquesa (ventosas).
- Olhos ferozes brilhando sob o manto frontal.
- Pontos para Animação (Rigging / Studio): Flutua girando lentamente enquanto os tentáculos se mexem em ondas alternadas.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

## 🎬 Notas de Animação no Roblox Studio
* **Comportamento:** Flutua girando lentamente enquanto os tentáculos se mexem em ondas alternadas.
* **Alvo Crítico (1.5x):** Posicionar a `Part` chamada `Head` no topo do modelo para que arremessos que atingirem a cabeça apliquem automaticamente o multiplicador crítico no servidor.
