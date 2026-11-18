# 15. Neonlynx — Lince Holográfico (Chefe da Floresta Neon)

* **Elemento:** `Raio` | **Bioma:** `2. Floresta Neon` | **Raridade:** `Mítica (Boss de Zona)`
* **Dificuldade de Captura:** `220` | **Renda Base:** `$240/s` | **XP Base:** `320 XP`
* **Orçamento 3D:** `700 - 1.200 tris`

## 📋 Prompt Completo (Copie e Cole para Gerar este Modelo 3D)

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Neonlynx — Lince Holográfico (Chefe da Floresta Neon)" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

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
6. Orçamento de Triângulos: 700 - 1.200 tris.

ESPECIFICAÇÃO DA CRIATURA (15. Neonlynx):
- Elemento: Raio | Bioma: 2. Floresta Neon | Raridade: Mítica (Boss de Zona)
- Paleta RGBA: Corpo Índigo Escuro (0.12, 0.14, 0.28, 1.0) | Listras Rosa e Ciano Neon (0.96, 0.22, 0.78, 1.0) | Garras Elétricas (0.20, 0.95, 1.0, 1.0)
- Anatomia Detalhada:
- Silhueta de felino predador ágil com ombros pontudos e tufos neon nas pontas das orelhas.
- Listras geométricas salientes nas costas e patas traseiras musculosas.
- Rabo curto terminado em esfera/losango energético flutuante.
- Pontos para Animação (Rigging / Studio): Postura de caça agachada; tufos e listras piscam em ciclo neon.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

## 🎬 Notas de Animação no Roblox Studio
* **Comportamento:** Postura de caça agachada; tufos e listras piscam em ciclo neon.
* **Alvo Crítico (1.5x):** Posicionar a `Part` chamada `Head` no topo do modelo para que arremessos que atingirem a cabeça apliquem automaticamente o multiplicador crítico no servidor.
