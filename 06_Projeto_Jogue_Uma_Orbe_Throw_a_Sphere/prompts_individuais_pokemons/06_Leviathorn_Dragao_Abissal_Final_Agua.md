# 06. Leviathorn — Dragão Abissal (Evolução Final Água - Estágio 3)

* **Elemento:** `Água` | **Bioma:** `4. Abismo Glacial / Fusão` | **Raridade:** `Mítica`
* **Dificuldade de Captura:** `5500` | **Renda Base:** `$6.400/s` | **XP Base:** `950 XP`
* **Orçamento 3D:** `1.000 - 2.000 tris`

## 📋 Prompt Completo (Copie e Cole para Gerar este Modelo 3D)

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Leviathorn — Dragão Abissal (Evolução Final Água - Estágio 3)" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

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
6. Orçamento de Triângulos: 1.000 - 2.000 tris.

ESPECIFICAÇÃO DA CRIATURA (06. Leviathorn):
- Elemento: Água | Bioma: 4. Abismo Glacial / Fusão | Raridade: Mítica
- Paleta RGBA: Escamas Índigo Abissal (0.06, 0.14, 0.42, 1.0) | Placas Bioluminescentes Ciano (0.12, 0.95, 1.0, 1.0) | Chifres Ouro Antigo (0.90, 0.75, 0.25, 1.0)
- Anatomia Detalhada:
- Corpo serpentino segmentado em 5 blocos articulados flutuando em onda S.
- Cabeça dracônica com 4 chifres curvos para trás e bigodes luminosos em ciano.
- Asas membranosas em formato de nadadeiras gigantes com nervuras rígidas facetadas.
- Pontos para Animação (Rigging / Studio): Flutua 1.5 studs acima do chão em movimento serpentino contínuo entre os 5 segmentos.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

## 🎬 Notas de Animação no Roblox Studio
* **Comportamento:** Flutua 1.5 studs acima do chão em movimento serpentino contínuo entre os 5 segmentos.
* **Alvo Crítico (1.5x):** Posicionar a `Part` chamada `Head` no topo do modelo para que arremessos que atingirem a cabeça apliquem automaticamente o multiplicador crítico no servidor.
