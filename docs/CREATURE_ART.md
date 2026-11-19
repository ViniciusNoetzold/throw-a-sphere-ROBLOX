# Build local com a arte Blender

Abra `build/ThrowASphere-ComModelos.rbxlx` e clique em **Play** para ver o lote de arte. O arquivo reúne 148 modelos Blender da revisão `13572c53171b816548580e1ab4eab0ce2e1a2c3d` do repositório privado da equipe. A exportação preserva a geometria e os materiais e ajusta os eixos e a escala. Os PNGs da origem são prévias e referências. O cliente monta e aplica o atlas UV com as cores originais na primeira aparição de cada modelo. [Documentação de MeshPart](https://create.roblox.com/docs/reference/engine/classes/MeshPart).

Somente as espécies com malha no build aparecem nas novas capturas, no mapa e no bestiário. A captura, o cercado, o pódio e a revelação usam o mesmo carregador. Os seis biomas têm espécies próprias do lote. As criaturas antigas cuja arte está pendente ficam no inventário e podem ser vendidas. Geometrias alternativas de Frostseal, Sireseal e Glacierness são preservadas na Dourada.

Enorme, Shiny e Dourada usam a medida da Pokédex quando a espécie de referência está identificada, à razão de 3,5 studs por metro. Modelos originais sem medida de referência usam a escala do artista. No cercado, o maior eixo fica limitado a 11 studs para caber no espaço de circulação. [Tabela de alturas da Pokédex](https://github.com/PokeAPI/pokeapi/blob/master/data/v2/csv/pokemon.csv).

Para gerar a versão com arte em outro PC, atualize o projeto pelo Git e clone o repositório privado de modelos em `.tools/modelospokemonroblox` com uma conta que tenha acesso. Execute na raiz do projeto, ajustando o caminho do executável e da origem conforme a máquina.

```powershell
$blender = 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe'
git -C .tools/modelospokemonroblox fetch origin 13572c53171b816548580e1ab4eab0ce2e1a2c3d
git -C .tools/modelospokemonroblox checkout --detach 13572c53171b816548580e1ab4eab0ce2e1a2c3d
& $blender --background --factory-startup --disable-autoexec --python-exit-code 1 --python scripts/Export-CreatureArt.py -- .tools/modelospokemonroblox art/creatures/local/data art/creatures/local/glb
powershell -ExecutionPolicy Bypass -File scripts/Build.ps1 -WithCreatureArt
```

Os 148 GLBs base ficam em `art/creatures/local/glb/`. As malhas e o place com arte ficam em caminhos ignorados pelo Git. O build público `game/ThrowASphere.rbxlx` permite testar a academia e as interfaces. As capturas ficam disponíveis ao gerar e abrir a versão com arte.

No Studio, o cliente monta uma malha por espécie e reaproveita esse recurso entre o mapa, o cercado e a revelação. A malha usa a API EditableMesh para carregar os dados e é convertida em conteúdo opaco quando a API permite. A disponibilidade de memória e das permissões em produção precisa de validação antes de usar o mesmo caminho em uma experiência publicada. Para publicação, as equipes podem importar os GLBs na conta ou grupo que detém a arte após decidir as permissões. [Documentação de EditableMesh](https://create.roblox.com/docs/reference/engine/classes/EditableMesh) · [Importador do Studio](https://create.roblox.com/docs/studio/importer).
