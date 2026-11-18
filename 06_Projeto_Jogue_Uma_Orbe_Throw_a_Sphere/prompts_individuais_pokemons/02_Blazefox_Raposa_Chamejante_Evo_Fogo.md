# 02. Blazefox — Raposa Chamejante (Evolução Fogo - Estágio 2)

* **Elemento:** `Fogo` | **Bioma:** `3. Cânion Vulcânico` | **Raridade:** `Rara`
* **Dificuldade de Captura:** `320` | **Renda Base:** `$280/s` | **XP Base:** `180 XP`
* **Orçamento 3D:** `500 - 800 tris`

## 📋 Prompt Completo (Copie e Cole para Gerar este Modelo 3D)

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Blazefox — Raposa Chamejante (Evolução Fogo - Estágio 2)" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

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

ESPECIFICAÇÃO DA CRIATURA (02. Blazefox):
- Elemento: Fogo | Bioma: 3. Cânion Vulcânico | Raridade: Rara
- Paleta RGBA: Pelagem Vermelho Carmesim (0.88, 0.18, 0.12, 1.0) | Juba e Caudas Laranja (1.0, 0.52, 0.08, 1.0) | Garras Obsidiana (0.14, 0.14, 0.18, 1.0) | Olhos Ciano/Branco Brilhante (1.0, 0.92, 0.40, 1.0)
- Anatomia Detalhada:
- Corpo atlético bípede ou quadrúpede ágil (1.4 x 2.1 x 1.3) com juba pontiaguda ao redor do pescoço.
- Cabeça afiada estilo lobo/raposa com focinho alongado e sobrancelhas angulares marcantes.
- 3 caudas independentes em formato de chamas geométricas facetadas abertas em leque.
- Pulseiras de brasa/armadura simples nos tornozelos e garras pontudas escuras.
- Pontos para Animação (Rigging / Studio): 3 caudas oscilam em defasagem de fase; corrida rápida inclinando o corpo 20° para frente.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

## 🎬 Notas de Animação no Roblox Studio
* **Comportamento:** 3 caudas oscilam em defasagem de fase; corrida rápida inclinando o corpo 20° para frente.
* **Alvo Crítico (1.5x):** Posicionar a `Part` chamada `Head` no topo do modelo para que arremessos que atingirem a cabeça apliquem automaticamente o multiplicador crítico no servidor.
