# Arte de criaturas, orbes, academias e reserva

Abra [`game/ThrowASphere-ComModelos.rbxlx`](../game/ThrowASphere-ComModelos.rbxlx) no Roblox Studio e clique em **Play**. O jogo e os arquivos de arte acompanham o Git. A origem é a revisão `96a5c6fee9784d144a48d41425ccb01113324b8f` do repositório de Nicolas Doering Santos. [Repositório de origem](https://github.com/nicolasdoeringsantos/modelospokemonroblox)

O lote tem 148 criaturas e 290 variantes de cor ou geometria. O cliente monta um atlas com as cores dos materiais do Blender e reaproveita as malhas no mapa, no curral, no pódio e na revelação. Os seis biomas têm espécies próprias do lote. Capturas antigas cuja arte está pendente ficam no inventário. Geometrias alternativas de Frostseal, Sireseal e Glacierness aparecem na Dourada.

Enorme, Shiny e Dourada usam a medida da Pokédex quando a espécie de referência está identificada, à razão de 3,5 studs por metro. Criaturas sem medida de referência usam a escala do artista. No cercado, o maior eixo fica limitado a 11 studs para caber no espaço de circulação. [Tabela de alturas da Pokédex](https://github.com/PokeAPI/pokeapi/blob/master/data/v2/csv/pokemon.csv)

O menu **Orbes → Vitrine 3D** mostra os 11 modelos da equipe, um por vez. Nove foram associados às orbes que o jogo já usa no arremesso. Reforçada e Turbo aparecem na vitrine. A academia usa as 21 artes ao longo da progressão de treino. A Reserva Natural é uma área visitável com amostras de criaturas.

## Reconstruir ou editar em outro PC

Com o Git atualizado, o Rojo instalado e o Python no PATH, execute na raiz do projeto.

```powershell
powershell -ExecutionPolicy Bypass -File scripts/Build.ps1 -WithCreatureArt
```

O build extrai o pacote do próprio repositório e gera `build/ThrowASphere-ComModelos.rbxlx`. Para abrir os fontes dos modelos e os GLBs no Blender, extraia a arte para a pasta local.

```powershell
python scripts/Prepare-BundledArt.py restore
```

- `art/creatures/local/glb/` contém os 148 GLBs para importar no Blender.
- `art/creatures/local/blender-source/scripts_blender_criaturas/` contém os scripts originais que geram as criaturas.
- `art/creatures/local/modelos_roblox/` contém os originais de orbes, garagens, reserva e a vitrine de apresentação.
- `art/creatures/local/data/` contém as malhas e variantes que o jogo lê.

Para regenerar malhas a partir dos scripts Blender, use o executável da sua instalação. Os dois argumentos do build apontam para a arte local que você quer testar.

```powershell
& $blender --background --factory-startup --disable-autoexec --python-exit-code 1 --python scripts/Export-CreatureArt.py -- art/creatures/local/blender-source art/creatures/local/data art/creatures/local/glb
& .\scripts\Build.ps1 -WithCreatureArt -CreatureDataSource art/creatures/local/data -WorldArtSource art/creatures/local/modelos_roblox
```

O cliente usa EditableMesh para montar as criaturas. As 16 mais próximas da câmera dentro do alcance de exibição têm prioridade no mundo. A malha é liberada quando sua última cópia sai de cena. A memória em celulares e as permissões dessa API na experiência publicada precisam de um teste próprio antes da implantação. [Documentação de EditableMesh](https://create.roblox.com/docs/reference/engine/classes/EditableMesh) · [Importador do Studio](https://create.roblox.com/docs/studio/importer)
