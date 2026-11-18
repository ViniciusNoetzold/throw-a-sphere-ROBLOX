# 14. Cybermantis — Louva-Deus Laser (Floresta Neon)

* **Elemento:** `Raio` | **Bioma:** `2. Floresta Neon` | **Raridade:** `Épica`
* **Dificuldade de Captura:** `165` | **Renda Base:** `$165/s` | **XP Base:** `200 XP`
* **Orçamento 3D:** `500 - 800 tris`

## 📋 Prompt Completo (Copie e Cole para Gerar este Modelo 3D)

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Cybermantis — Louva-Deus Laser (Floresta Neon)" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

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
6. Orçamento de Triângulos: 500 - 800 tris.

ESPECIFICAÇÃO DA CRIATURA (14. Cybermantis):
- Elemento: Raio | Bioma: 2. Floresta Neon | Raridade: Épica
- Paleta RGBA: Exoesqueleto Verde Esmeralda (0.08, 0.78, 0.42, 1.0) | Lâminas Neon Ciano (0.10, 0.98, 0.96, 1.0) | Visor Preto (0.08, 0.09, 0.12, 1.0)
- Anatomia Detalhada:
- Tórax esguio erguido com abdômen traseiro segmentado em placa angular.
- Dois braços articulados terminando em grandes foices prismáticas ciano neon.
- Cabeça triangular invertida com visor futurista e duas longas antenas finas.
- Pontos para Animação (Rigging / Studio): Cruza e descruza as lâminas neon em guarda; movimenta-se com passos precisos.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

## 🎬 Notas de Animação no Roblox Studio
* **Comportamento:** Cruza e descruza as lâminas neon em guarda; movimenta-se com passos precisos.
* **Alvo Crítico (1.5x):** Posicionar a `Part` chamada `Head` no topo do modelo para que arremessos que atingirem a cabeça apliquem automaticamente o multiplicador crítico no servidor.
