# 22. Runegolem — Sentinela Dourado (Ruínas Ancestrais)

* **Elemento:** `Terra` | **Bioma:** `5. Ruínas Ancestrais` | **Raridade:** `Épica`
* **Dificuldade de Captura:** `12000` | **Renda Base:** `$14.000/s` | **XP Base:** `1.100 XP`
* **Orçamento 3D:** `600 - 1.100 tris`

## 📋 Prompt Completo (Copie e Cole para Gerar este Modelo 3D)

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Runegolem — Sentinela Dourado (Ruínas Ancestrais)" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

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
6. Orçamento de Triângulos: 600 - 1.100 tris.

ESPECIFICAÇÃO DA CRIATURA (22. Runegolem):
- Elemento: Terra | Bioma: 5. Ruínas Ancestrais | Raridade: Épica
- Paleta RGBA: Pedra Arenito (0.78, 0.64, 0.42, 1.0) | Armadura Ouro Antigo (0.96, 0.78, 0.22, 1.0) | Núcleo Rúnico Turquesa (0.15, 0.95, 0.85, 1.0)
- Anatomia Detalhada:
- Corpo modular desconectado: torso grande com um cristal rúnico turquesa girando no vazio do peito.
- Braços e ombros flutuando 0.3 unidades separados do tronco por energia rúnica.
- Cabeça cúbica monolítica com 1 único olho visor horizontal luminoso.
- Pontos para Animação (Rigging / Studio): Braços e cabeça levitam levemente separados do tronco; núcleo peitoral gira sem parar.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

## 🎬 Notas de Animação no Roblox Studio
* **Comportamento:** Braços e cabeça levitam levemente separados do tronco; núcleo peitoral gira sem parar.
* **Alvo Crítico (1.5x):** Posicionar a `Part` chamada `Head` no topo do modelo para que arremessos que atingirem a cabeça apliquem automaticamente o multiplicador crítico no servidor.
