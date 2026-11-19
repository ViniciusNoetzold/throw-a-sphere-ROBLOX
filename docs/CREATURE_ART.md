# Build local com a arte Blender

O build público fica em `game/ThrowASphere.rbxlx`. O build local `build/ThrowASphere-ComModelos.rbxlx` contém os dados das malhas originais de Sproutling, Leviathorn e Ignisovereign. Os dados derivam dos scripts Blender do colaborador, no commit `f7cd1f85e05a2e1fde4d452f1baa9b3c088c5866`. A exportação mantém os vértices, triângulos e materiais de cor sólida, ajustando escala e eixos para o jogo. As outras criaturas continuam com o visual provisório até receberem suas malhas.

Para gerar a versão com arte em outro PC, use uma cópia da origem privada à qual a sua conta já tenha acesso. Execute na raiz do projeto, ajustando o caminho do executável e da origem conforme a máquina.

```powershell
$blender = 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe'
& $blender --background --factory-startup --disable-autoexec --python-exit-code 1 --python scripts/Export-CreatureArt.py -- .tools/modelospokemonroblox art/creatures/local/data art/creatures/local/glb
powershell -ExecutionPolicy Bypass -File scripts/Build.ps1 -WithCreatureArt
```

Os três GLBs ficam em `art/creatures/local/glb/`. Os dados e o place com arte ficam em caminhos ignorados pelo Git. O build normal mantém o mesmo fluxo do jogo e usa os modelos provisórios.

No Studio, o cliente monta uma malha por espécie e reaproveita esse recurso entre o mapa, o cercado e a revelação. A malha usa a API EditableMesh para carregar os dados e é convertida em conteúdo opaco quando a API permite. A disponibilidade de memória e das permissões em produção precisa de validação antes de usar o mesmo caminho em uma experiência publicada. Para publicação, as equipes podem importar os GLBs na conta ou grupo que detém a arte após decidir as permissões. [Documentação de EditableMesh](https://create.roblox.com/docs/reference/engine/classes/EditableMesh) · [Importador do Studio](https://create.roblox.com/docs/studio/importer).
