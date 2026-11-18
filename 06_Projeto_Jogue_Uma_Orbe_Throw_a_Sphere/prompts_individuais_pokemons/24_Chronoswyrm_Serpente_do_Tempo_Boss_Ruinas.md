# 24. Chronoswyrm — Serpente do Tempo (Chefe das Ruínas)

* **Elemento:** `Terra` | **Bioma:** `5. Ruínas Ancestrais` | **Raridade:** `Lendária (Boss de Zona)`
* **Dificuldade de Captura:** `45000` | **Renda Base:** `$55.000/s` | **XP Base:** `2.400 XP`
* **Orçamento 3D:** `1.100 - 2.300 tris`

## 📋 Prompt Completo (Copie e Cole para Gerar este Modelo 3D)

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Chronoswyrm — Serpente do Tempo (Chefe das Ruínas)" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

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
6. Orçamento de Triângulos: 1.100 - 2.300 tris.

ESPECIFICAÇÃO DA CRIATURA (24. Chronoswyrm):
- Elemento: Terra | Bioma: 5. Ruínas Ancestrais | Raridade: Lendária (Boss de Zona)
- Paleta RGBA: Placas Bronze/Ouro (0.88, 0.68, 0.22, 1.0) | Corpo Mármore Branco (0.92, 0.92, 0.96, 1.0) | Engrenagens Ciano Tempo (0.20, 0.92, 1.0, 1.0)
- Anatomia Detalhada:
- Grande serpente alada mecânico-mística em 6 segmentos blindados.
- Dois anéis de relógio/engrenagem octogonais flutuando ao redor do pescoço.
- Cabeça coroada com ampulheta luminosa na testa.
- Pontos para Animação (Rigging / Studio): Anéis temporais giram em sentidos opostos ao redor do corpo ondulante.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

## 🎬 Notas de Animação no Roblox Studio
* **Comportamento:** Anéis temporais giram em sentidos opostos ao redor do corpo ondulante.
* **Alvo Crítico (1.5x):** Posicionar a `Part` chamada `Head` no topo do modelo para que arremessos que atingirem a cabeça apliquem automaticamente o multiplicador crítico no servidor.
