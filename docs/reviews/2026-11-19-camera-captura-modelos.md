# Câmera, captura e malhas Blender — 19/11/2026

Skills usadas para orientar a entrega: `scenario-roblox-expert`, `scenario-roblox-assets`, `scenario-roblox-animation`, `el4cteo-roblox-studio-mcp` e `rbx-import-asset`. A revisão usou exportação Blender e Play local. A origem é privada, portanto o fluxo gera um arquivo local específico para o lote de arte.

## Teste funcional

- **Academia.** O botão do HUD abriu o treino, o personagem ficou ancorado e a câmera enquadrou o avatar e a barra de lado e de frente. Parar o treino restaurou a câmera Custom e a mobilidade.
- **Faixa.** A barra começou automaticamente na faixa. A tentativa de caminhar com a barra aberta deixou o avatar no mesmo lugar. O clique fora da barra iniciou um arremesso pelo fluxo normal.
- **Voo e captura.** Na chegada, a câmera ainda estava em Scriptable e o personagem ainda estava ancorado. Depois de uma captura real de Buzzleaf, a câmera voltou a Custom, a âncora foi removida e os efeitos temporários foram limpos. A barra ficou fechada até o jogador sair e voltar à faixa.
- **Apresentação.** A orbe ganha corpo, aro e núcleo luminoso, aparece na mão no preparo, viaja com rastro e pousa antes de balançar. A quantidade de balançadas visíveis acompanha o resultado validado. O encontro usa silhueta, órbita, onda e partículas com intensidade por raridade. A prévia mítica de Ignisovereign exibiu o MeshPart original sem conceder recompensas.

## Lote local de arte

| Criatura | Triângulos da exportação | Dimensões no jogo em studs |
| --- | ---: | --- |
| Sproutling | 3.080 | 2,11 × 2,48 × 3,65 |
| Leviathorn | 6.516 | 1,17 × 3,01 × 3,65 |
| Ignisovereign | 16.192 | 3,24 × 3,27 × 3,65 |

As três malhas apareceram como MeshParts no cliente em uma sessão real de Studio, com conteúdo opaco e dimensões compatíveis com os dados do Blender. O cercado reaproveita o mesmo carregador e conserva a movimentação e o indicador de renda existentes. As medidas acima são para a variação padrão. Os scripts de modelo Blender foram usados somente para gerar as geometrias. O catálogo externo de referências corresponde a outras espécies e segue fora do catálogo jogável.

## Escopo da verificação

`scripts/Test.ps1` aprovou a compilação Luau, as suítes existentes, 25 cenários de voo, 19 de academia e o build Rojo. A compilação, os testes com mocks e o Play local são verificações separadas. O Play usou uma sessão StudioMemory. Ainda é preciso validar consumo de memória em celular, o servidor com oito clientes e as permissões de malha em experiência publicada. O asset preexistente `203785492` continua emitindo um aviso do Studio.

O [vídeo de referência](https://www.tiktok.com/@barezz999/video/7707953041193864455) abriu como um clipe de *Throw a Seed*. O TikTok pediu verificação de idade antes de permitir uma revisão completa. A atualização seguiu a descrição do usuário sobre câmera fixa, foco no exercício, barra de força e espera durante a captura.
