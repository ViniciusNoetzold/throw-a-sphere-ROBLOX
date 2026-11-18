# 10. Voltmouse — Ratinho Raio (Pradaria Solar)

* **Elemento:** `Raio` | **Bioma:** `1. Pradaria Solar` | **Raridade:** `Rara`
* **Dificuldade de Captura:** `35` | **Renda Base:** `$28/s` | **XP Base:** `80 XP`
* **Orçamento 3D:** `350 - 650 tris`

## 📋 Prompt Completo (Copie e Cole para Gerar este Modelo 3D)

```text
Crie um script Python completo e autossuficiente para o Blender (`bpy`) que gere o modelo 3D da criatura "Voltmouse — Ratinho Raio (Pradaria Solar)" no estilo Low-Poly / Voxel Blocky para o jogo Roblox "Jogue uma Orbe / Throw a Sphere".

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

ESPECIFICAÇÃO DA CRIATURA (10. Voltmouse):
- Elemento: Raio | Bioma: 1. Pradaria Solar | Raridade: Rara
- Paleta RGBA: Corpo Amarelo Elétrico (1.0, 0.86, 0.10, 1.0) | Listras e Orelhas Preto Grafite (0.12, 0.12, 0.15, 1.0) | Bochechas Laranja (1.0, 0.40, 0.10, 1.0)
- Anatomia Detalhada:
- Corpo pequeno e ágil com 2 listras pretas horizontais nas costas.
- Orelhas compridas pontudas inclinadas em V com pontas pretas.
- Cauda construída em zigue-zague com 3 prismas retangulares conectados em formato de raio.
- Pontos para Animação (Rigging / Studio): Salto rápido constante pelo bioma; cauda de raio vibra com pequenas faíscas.
- Exportação: Garanta que a base dos pés toque Z = 0 no Blender e a frente aponte para -Y para importar limpo em `.fbx` no Roblox Studio.
```

## 🎬 Notas de Animação no Roblox Studio
* **Comportamento:** Salto rápido constante pelo bioma; cauda de raio vibra com pequenas faíscas.
* **Alvo Crítico (1.5x):** Posicionar a `Part` chamada `Head` no topo do modelo para que arremessos que atingirem a cabeça apliquem automaticamente o multiplicador crítico no servidor.
