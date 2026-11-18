# 05. Tidefang — Lobo Marinho (Evolução Água - Estágio 2)

* **Elemento:** `Água` | **Bioma:** `4. Abismo Glacial` | **Raridade:** `Rara`
* **Dificuldade de Captura:** `1600` | **Renda Base:** `$1.800/s` | **XP Base:** `320 XP`
* **Orçamento 3D:** `550 - 800 tris`

## 📋 Prompt Completo (Copie e Cole para Gerar este Modelo 3D)

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Tidefang — Lobo Marinho (Evolução Água - Estágio 2)" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

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
6. Orçamento de Triângulos: 550 - 800 tris.

ESPECIFICAÇÃO DA CRIATURA (05. Tidefang):
- Elemento: Água | Bioma: 4. Abismo Glacial | Raridade: Rara
- Paleta RGBA: Azul Profundo (0.08, 0.30, 0.72, 1.0) | Barbatanas Turquesa (0.14, 0.85, 0.82, 1.0) | Presas e Garras Branco Pérola (0.94, 0.97, 1.0, 1.0)
- Anatomia Detalhada:
- Corpo hidrodinâmico alongado com grande barbatana dorsal serrilhada em 3 blocos triangulares.
- Cabeça feroz com duas presas externas saltando da mandíbula inferior e colar de espuma/cristal no pescoço.
- Cauda dupla bifurcada em formato de nadadeira de tubarão facetada.
- Pontos para Animação (Rigging / Studio): Movimento sinuoso de nado mesmo andando na terra; mandíbula abre/fecha ao detectar orbe.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

## 🎬 Notas de Animação no Roblox Studio
* **Comportamento:** Movimento sinuoso de nado mesmo andando na terra; mandíbula abre/fecha ao detectar orbe.
* **Alvo Crítico (1.5x):** Posicionar a `Part` chamada `Head` no topo do modelo para que arremessos que atingirem a cabeça apliquem automaticamente o multiplicador crítico no servidor.
