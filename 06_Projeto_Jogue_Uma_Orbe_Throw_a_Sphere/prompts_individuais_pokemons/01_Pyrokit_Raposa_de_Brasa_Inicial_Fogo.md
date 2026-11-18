# 01. Pyrokit — Raposa de Brasa (Inicial de Fogo - Estágio 1)

* **Elemento:** `Fogo` | **Bioma:** `1. Pradaria Solar` | **Raridade:** `Incomum (Inicial)`
* **Dificuldade de Captura:** `18` | **Renda Base:** `$12/s` | **XP Base:** `40 XP`
* **Orçamento 3D:** `350 - 650 tris`

## 📋 Prompt Completo (Copie e Cole para Gerar este Modelo 3D)

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Pyrokit — Raposa de Brasa (Inicial de Fogo - Estágio 1)" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

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
6. Orçamento de Triângulos: 350 - 650 tris.

ESPECIFICAÇÃO DA CRIATURA (01. Pyrokit):
- Elemento: Fogo | Bioma: 1. Pradaria Solar | Raridade: Incomum (Inicial)
- Paleta RGBA: Corpo Laranja Brasa (0.98, 0.42, 0.10, 1.0) | Peito Creme (0.98, 0.90, 0.65, 1.0) | Ponta da Cauda e Orelhas Amarelo Fogo (1.0, 0.80, 0.12, 1.0) | Olhos Carvão/Âmbar (0.12, 0.08, 0.06, 1.0)
- Anatomia Detalhada:
- Torso compacto e levemente inclinado para frente (cubo chanfrado 1.2 x 1.6 x 1.0) com tufo creme no peito.
- Cabeça grande e fofa (1.3 x 1.2 x 1.1) com focinho pontudo curto e 2 orelhas triangulares longas feitas com cones de 4 lados.
- 4 patas curtas em cones facetados (6 vértices, radius1=0.22, radius2=0.15, altura 0.7).
- Cauda volumosa de chama em 3 segmentos cônicos empilhados apontando para cima com ponta amarelo-sol.
- Pontos para Animação (Rigging / Studio): Pivô da cauda balançando em arco; cabeça inclina 10° no Idle; orelhas abaixam ao se preparar para correr.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

## 🎬 Notas de Animação no Roblox Studio
* **Comportamento:** Pivô da cauda balançando em arco; cabeça inclina 10° no Idle; orelhas abaixam ao se preparar para correr.
* **Alvo Crítico (1.5x):** Posicionar a `Part` chamada `Head` no topo do modelo para que arremessos que atingirem a cabeça apliquem automaticamente o multiplicador crítico no servidor.
