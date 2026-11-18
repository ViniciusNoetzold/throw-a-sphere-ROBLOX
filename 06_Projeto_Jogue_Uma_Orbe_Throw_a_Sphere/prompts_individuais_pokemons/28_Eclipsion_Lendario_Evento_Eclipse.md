# 28. Eclipsion — Lendário do Evento Eclipse Solar

* **Elemento:** `Cósmico` | **Bioma:** `Evento Global: Eclipse (A cada 20 min)` | **Raridade:** `Lendária (Evento)`
* **Dificuldade de Captura:** `180000` | **Renda Base:** `$260.000/s` | **XP Base:** `4.000 XP`
* **Orçamento 3D:** `900 - 1.900 tris`

## 📋 Prompt Completo (Copie e Cole para Gerar este Modelo 3D)

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Eclipsion — Lendário do Evento Eclipse Solar" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

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
6. Orçamento de Triângulos: 900 - 1.900 tris.

ESPECIFICAÇÃO DA CRIATURA (28. Eclipsion):
- Elemento: Cósmico | Bioma: Evento Global: Eclipse (A cada 20 min) | Raridade: Lendária (Evento)
- Paleta RGBA: Núcleo Negro Eclipse (0.04, 0.04, 0.06, 1.0) | Coroa de Luz Laranja/Branca (1.0, 0.65, 0.10, 1.0) | Manto Roxo Real (0.32, 0.10, 0.55, 1.0)
- Anatomia Detalhada:
- Ser celestial sem pernas com torso envolto por um manto angular flutuante em camadas.
- Cabeça formada por um disco preto central cercado por um anel brilhante de eclipse solar e 8 raios prismáticos.
- 4 braços flutuantes estilizados com mãos em formato de crescentes lunares.
- Pontos para Animação (Rigging / Studio): Os 8 raios da coroa giram lentamente; mãos orbitam em postura mística.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

## 🎬 Notas de Animação no Roblox Studio
* **Comportamento:** Os 8 raios da coroa giram lentamente; mãos orbitam em postura mística.
* **Alvo Crítico (1.5x):** Posicionar a `Part` chamada `Head` no topo do modelo para que arremessos que atingirem a cabeça apliquem automaticamente o multiplicador crítico no servidor.
