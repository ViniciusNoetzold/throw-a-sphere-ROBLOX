# 27. Astraldragon — Dragão Galáctico (Chefe Final do Vazio)

* **Elemento:** `Cósmico` | **Bioma:** `6. Vazio Cósmico` | **Raridade:** `Lendária (Boss Final)`
* **Dificuldade de Captura:** `320000` | **Renda Base:** `$450.000/s` | **XP Base:** `5.000 XP`
* **Orçamento 3D:** `1.200 - 2.400 tris`

## 📋 Prompt Completo (Copie e Cole para Gerar este Modelo 3D)

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Astraldragon — Dragão Galáctico (Chefe Final do Vazio)" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

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
6. Orçamento de Triângulos: 1.200 - 2.400 tris.

ESPECIFICAÇÃO DA CRIATURA (27. Astraldragon):
- Elemento: Cósmico | Bioma: 6. Vazio Cósmico | Raridade: Lendária (Boss Final)
- Paleta RGBA: Escamas Índigo Estelar (0.10, 0.08, 0.28, 1.0) | Asas Constelação Ouro/Rosa (1.0, 0.78, 0.25, 1.0) | Anéis Cósmicos Neon (0.94, 0.28, 0.88, 1.0)
- Anatomia Detalhada:
- Grande dragão quadrúpede/alado com corpo escuro salpicado de blocos brilhantes estilo constelação.
- Duas asas enormes em armação geométrica dourada com membranas roxas translúcidas.
- Anéis planetários dourados envolvendo o pescoço e a cauda longa com espinhos magenta.
- Pontos para Animação (Rigging / Studio): Paira majestosamente com bater lento de asas; emite partículas de estrelas.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

## 🎬 Notas de Animação no Roblox Studio
* **Comportamento:** Paira majestosamente com bater lento de asas; emite partículas de estrelas.
* **Alvo Crítico (1.5x):** Posicionar a `Part` chamada `Head` no topo do modelo para que arremessos que atingirem a cabeça apliquem automaticamente o multiplicador crítico no servidor.
