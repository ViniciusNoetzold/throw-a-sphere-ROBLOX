# 08. Thornback — Golem Florido (Evolução Planta - Estágio 2)

* **Elemento:** `Planta` | **Bioma:** `2. Floresta Neon` | **Raridade:** `Rara`
* **Dificuldade de Captura:** `130` | **Renda Base:** `$110/s` | **XP Base:** `140 XP`
* **Orçamento 3D:** `500 - 800 tris`

## 📋 Prompt Completo (Copie e Cole para Gerar este Modelo 3D)

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Thornback — Golem Florido (Evolução Planta - Estágio 2)" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

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

ESPECIFICAÇÃO DA CRIATURA (08. Thornback):
- Elemento: Planta | Bioma: 2. Floresta Neon | Raridade: Rara
- Paleta RGBA: Tronco/Corpo Marrom Casca (0.42, 0.26, 0.16, 1.0) | Espinhos e Folhas Verde Escuro (0.10, 0.58, 0.22, 1.0) | Flor Central Rosa Magenta (0.96, 0.28, 0.62, 1.0)
- Anatomia Detalhada:
- Tronco largo e robusto de golem quadrúpede/bípede com ombros assimétricos de pedra e madeira.
- Grande flor prismática de 6 pétalas magenta plantada nas costas com núcleo amarelo.
- Braços pesados terminando em punhos cúbicos cercados por espinhos cônicos.
- Pontos para Animação (Rigging / Studio): Caminhada pesada alternando ombros; flor nas costas abre e fecha lentamente.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

## 🎬 Notas de Animação no Roblox Studio
* **Comportamento:** Caminhada pesada alternando ombros; flor nas costas abre e fecha lentamente.
* **Alvo Crítico (1.5x):** Posicionar a `Part` chamada `Head` no topo do modelo para que arremessos que atingirem a cabeça apliquem automaticamente o multiplicador crítico no servidor.
