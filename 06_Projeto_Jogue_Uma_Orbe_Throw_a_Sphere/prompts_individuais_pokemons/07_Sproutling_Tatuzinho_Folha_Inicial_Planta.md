# 07. Sproutling — Tatuzinho Folha (Inicial de Planta - Estágio 1)

* **Elemento:** `Planta` | **Bioma:** `1. Pradaria Solar` | **Raridade:** `Comum (Inicial)`
* **Dificuldade de Captura:** `12` | **Renda Base:** `$8/s` | **XP Base:** `25 XP`
* **Orçamento 3D:** `300 - 550 tris`

## 📋 Prompt Completo (Copie e Cole para Gerar este Modelo 3D)

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Sproutling — Tatuzinho Folha (Inicial de Planta - Estágio 1)" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

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
6. Orçamento de Triângulos: 300 - 550 tris.

ESPECIFICAÇÃO DA CRIATURA (07. Sproutling):
- Elemento: Planta | Bioma: 1. Pradaria Solar | Raridade: Comum (Inicial)
- Paleta RGBA: Corpo Verde Lima (0.35, 0.85, 0.28, 1.0) | Carapaça Musgo (0.14, 0.52, 0.20, 1.0) | Broto no Topo Verde Claro (0.62, 1.0, 0.32, 1.0)
- Anatomia Detalhada:
- Corpo oval/cúbico baixo protegido por 3 placas de carapaça verde-musgo nas costas.
- Grande broto com 2 folhas em formato de hélice nascendo exatamente no topo da cabeça (alvo crítico!).
- 4 patinhas curtas cilíndricas/cônicas de 6 lados e olhos redondos brilhantes.
- Pontos para Animação (Rigging / Studio): As 2 folhas do topo giram como hélice quando o monstro dá um pulinho feliz.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

## 🎬 Notas de Animação no Roblox Studio
* **Comportamento:** As 2 folhas do topo giram como hélice quando o monstro dá um pulinho feliz.
* **Alvo Crítico (1.5x):** Posicionar a `Part` chamada `Head` no topo do modelo para que arremessos que atingirem a cabeça apliquem automaticamente o multiplicador crítico no servidor.
