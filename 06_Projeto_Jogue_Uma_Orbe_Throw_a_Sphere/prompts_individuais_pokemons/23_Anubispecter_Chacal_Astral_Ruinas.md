# 23. Anubispecter — Chacal Astral (Ruínas Ancestrais)

* **Elemento:** `Terra` | **Bioma:** `5. Ruínas Ancestrais` | **Raridade:** `Mítica`
* **Dificuldade de Captura:** `24000` | **Renda Base:** `$28.500/s` | **XP Base:** `1.600 XP`
* **Orçamento 3D:** `750 - 1.350 tris`

## 📋 Prompt Completo (Copie e Cole para Gerar este Modelo 3D)

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Anubispecter — Chacal Astral (Ruínas Ancestrais)" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

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
6. Orçamento de Triângulos: 750 - 1.350 tris.

ESPECIFICAÇÃO DA CRIATURA (23. Anubispecter):
- Elemento: Terra | Bioma: 5. Ruínas Ancestrais | Raridade: Mítica
- Paleta RGBA: Corpo Obsidiana Negra (0.10, 0.10, 0.14, 1.0) | Adornos Ouro Real (0.98, 0.80, 0.18, 1.0) | Olhos e Cajado Roxo Astral (0.68, 0.25, 0.98, 1.0)
- Anatomia Detalhada:
- Corpo bípede esguio de guardião com saia/armadura egípcia geométrica em ouro e preto.
- Cabeça clássica de chacal com focinho longo retangular e duas orelhas verticais muito altas e pontudas.
- Anel/Colar largo dourado nos ombros e esfera astral flutuando atrás da cabeça.
- Pontos para Animação (Rigging / Studio): Levita silenciosamente sobre as areias com braços cruzados ou estendidos.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

## 🎬 Notas de Animação no Roblox Studio
* **Comportamento:** Levita silenciosamente sobre as areias com braços cruzados ou estendidos.
* **Alvo Crítico (1.5x):** Posicionar a `Part` chamada `Head` no topo do modelo para que arremessos que atingirem a cabeça apliquem automaticamente o multiplicador crítico no servidor.
