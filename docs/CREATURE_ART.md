# Build local com a arte Blender

Abra `build/ThrowASphere-ComModelos.rbxlx` e clique em **Play** para ver o lote de arte. O arquivo reúne 23 modelos Blender da revisão `33188649fb368956eae63c523a04fe41b6ee398d` do repositório privado do colaborador. A exportação preserva a geometria e os materiais originais e ajusta os eixos e a escala. Os PNGs da origem são prévias e referências. As malhas usam materiais de cor sólida e paletas de mutação.

As novas espécies entram no sorteio de arremesso, no mapa e no bestiário quando suas malhas acompanham o build. As aparições selvagens priorizam modelos com arte. A captura, o cercado e as revelações usam o mesmo carregador. Pyrokit, Blazefox, Ignisovereign, Leviathorn e Sproutling mantêm seus IDs e ganham os modelos da origem. As criaturas sem malha correspondente continuam com seu visual provisório.

O tamanho padrão varia por espécie, de cerca de 1 stud para Gustfinch a 4,8 studs para Galehawk. Grande, Enorme e Titânica usam os multiplicadores de tamanho já salvos no jogo. Onde a fonte inclui essas paletas, Dourada usa as cores douradas e ArcoIris usa as cores Shiny do Blender. As demais mutações usam as cores do jogo. No cercado, o maior eixo de um modelo fica limitado a 11 studs para caber no espaço de circulação.

Para gerar a versão com arte em outro PC, atualize o projeto pelo Git e clone o repositório privado de modelos em `.tools/modelospokemonroblox` com uma conta que tenha acesso. Execute na raiz do projeto, ajustando o caminho do executável e da origem conforme a máquina.

```powershell
$blender = 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe'
git -C .tools/modelospokemonroblox fetch origin 33188649fb368956eae63c523a04fe41b6ee398d
git -C .tools/modelospokemonroblox checkout --detach 33188649fb368956eae63c523a04fe41b6ee398d
& $blender --background --factory-startup --disable-autoexec --python-exit-code 1 --python scripts/Export-CreatureArt.py -- .tools/modelospokemonroblox art/creatures/local/data art/creatures/local/glb
powershell -ExecutionPolicy Bypass -File scripts/Build.ps1 -WithCreatureArt
```

Os 23 GLBs ficam em `art/creatures/local/glb/`. As malhas e o place com arte ficam em caminhos ignorados pelo Git. O build público `game/ThrowASphere.rbxlx` usa o catálogo base com os modelos provisórios.

No Studio, o cliente monta uma malha por espécie e reaproveita esse recurso entre o mapa, o cercado e a revelação. A malha usa a API EditableMesh para carregar os dados e é convertida em conteúdo opaco quando a API permite. A disponibilidade de memória e das permissões em produção precisa de validação antes de usar o mesmo caminho em uma experiência publicada. Para publicação, as equipes podem importar os GLBs na conta ou grupo que detém a arte após decidir as permissões. [Documentação de EditableMesh](https://create.roblox.com/docs/reference/engine/classes/EditableMesh) · [Importador do Studio](https://create.roblox.com/docs/studio/importer).
