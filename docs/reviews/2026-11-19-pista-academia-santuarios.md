# Pista, academia e santuários — 19/11/2026

Skills consultadas para a entrega: `el4cteo-roblox-ui`, `el4cteo-roblox-world-building`, `el4cteo-roblox-game-systems`, `el4cteo-roblox-networking`, `el4cteo-roblox-data-stores` e `el4cteo-roblox-studio-mcp`. Aplicamos limites de tamanho, validação e salvamento no servidor, geometria estática com proteção física e animação de criaturas no cliente com limite de distância.

## Comportamento testado

- **Faixa.** A área amarela mede 58 × 22 studs e coincide com a região de ativação. O painel aparece ao entrar na área e o servidor confirma a barra. Em uma passagem com teclado no Studio, o ponteiro ficou disponível cerca de 0,27 s depois da entrada. Um clique fora do painel disparou a animação e o voo. O marcador percorre o ciclo em 3,8 segundos.
- **Percurso seguro.** O túnel tem 12 segmentos de parede lateral de 16 studs de altura. A praça, cinco biomas separados e o pátio de trocas somam 28 barreiras de borda. Um avatar caminhou contra a borda da praça e parou dentro do mapa. Quedas provocadas no teste da praça e de um bioma restauraram a posição segura do local com saúde 100. A tentativa de ficar no interior do túnel devolveu o avatar à entrada.
- **Resgates.** A captura criou uma recompensa no menu. O resgate foi feito longe da faixa. O servidor valida o dono e impede resgate repetido. Recompensas pendentes ficam disponíveis durante a mesma sessão por até 30 minutos.
- **Orbes.** A Orbe Comum manteve o estoque depois do voo. O jogador evoluiu para Esmeralda via clique no painel. Compra em sequência, débito único, desconto por fragmentos, migração de estoques existentes e lançamento com estoque zero foram cobertos por mocks.
- **Academia.** O menu abriu e iniciou o treino. Após atingir o nível necessário, o jogador comprou a barra reforçada. O rótulo do aparelho e os ganhos passaram a mostrar +2 de força e +13 de XP por repetição. Testes com mocks conferiram custo, requisitos, persistência e aplicação da melhora.
- **Santuários.** O Studio carregou oito cercados e uma criatura capturada andou no cercado com a renda verde acima da cabeça. O servidor usa a mesma conta de renda para o saldo e para o valor por criatura, incluindo bônus ativos.

`scripts/Test.ps1` verificou integridade de 155 skills, compilação Luau, suítes de servidor com mocks e o build Rojo. O teste em Studio usou um cliente e perfil StudioMemory. O aviso preexistente do asset `203785492` apareceu durante o Play. Modelos, nomes e valores de evolução seguem provisórios. DataStore publicado, dispositivos físicos e uma sessão de oito jogadores ainda precisam de verificação. O cap de jogadores é uma [configuração do place no Creator Dashboard](https://create.roblox.com/docs/reference/engine/classes/Players#MaxPlayers).
