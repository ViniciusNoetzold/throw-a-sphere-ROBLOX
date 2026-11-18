# 30. Omnisfera — Entidade Secreta (1 em 1.000.000)

* **Elemento:** `Cósmico` | **Bioma:** `Todos os Biomas (Spawn Secreto Global)` | **Raridade:** `Secreta (1 in 1M)`
* **Dificuldade de Captura:** `500000` | **Renda Base:** `$1.000.000/s` | **XP Base:** `15.000 XP`
* **Orçamento 3D:** `1.200 - 2.500 tris`

## 📋 Prompt Completo (Copie e Cole para Gerar este Modelo 3D)

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Omnisfera — Entidade Secreta (1 em 1.000.000)" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

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
6. Orçamento de Triângulos: 1.200 - 2.500 tris.

ESPECIFICAÇÃO DA CRIATURA (30. Omnisfera):
- Elemento: Cósmico | Bioma: Todos os Biomas (Spawn Secreto Global) | Raridade: Secreta (1 in 1M)
- Paleta RGBA: Núcleo Branco Puro/Arco-Íris (1.0, 1.0, 1.0, 1.0) | Anéis Dourado Celestial (1.0, 0.85, 0.20, 1.0) | Placas Ciano/Magenta (0.20, 0.95, 1.0, 1.0)
- Anatomia Detalhada:
- Núcleo central icosaédrico brilhante cercado por 3 anéis giroscópicos concêntricos inclinados em eixos diferentes.
- 6 asas de luz geométricas desconectadas dispostas em hexágono atrás do núcleo.
- Coroa tridimensional de cristal flutuando sobre o anel externo + olhos místicos no núcleo central.
- Pontos para Animação (Rigging / Studio): Os 3 anéis giram simultaneamente nos eixos X, Y e Z; as 6 asas respiram expandindo radialmente.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

## 🎬 Notas de Animação no Roblox Studio
* **Comportamento:** Os 3 anéis giram simultaneamente nos eixos X, Y e Z; as 6 asas respiram expandindo radialmente.
* **Alvo Crítico (1.5x):** Posicionar a `Part` chamada `Head` no topo do modelo para que arremessos que atingirem a cabeça apliquem automaticamente o multiplicador crítico no servidor.
