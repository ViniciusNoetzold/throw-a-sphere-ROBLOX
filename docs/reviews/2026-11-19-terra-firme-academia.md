# Mapa, pista e progressão da academia

A entrega seguiu as skills `scenario-roblox-environment`, `scenario-roblox-expert`, `el4cteo-roblox-world-building` e `gstack-balance-review`.

## Progressão

Os tempos abaixo usam a máquina indicada, sem bônus 2×, e começam com a barra de XP vazia.

| Nível atual | Máquina | XP por repetição | XP para subir | Repetições |
| --- | --- | ---: | ---: | ---: |
| 1 | Barra de treino | 8 | 24 | 3 |
| 2 | Barra reforçada | 12 | 39 | 4 |
| 14 | Estação cósmica | 50 | 625 | 13 |
| 52 | Estação estelar | 263 | 7.046 | 27 |
| 99 | Estação estelar | 410 | 24.109 | 59 |

Ganhos de força e XP aumentam com o nível e a máquina. O alvo de XP cresce mais rápido nas faixas avançadas. Uma repetição mais rápida nas máquinas avançadas também reduz o tempo entre tentativas de desafio. Com a orbe comum, nível 1 e 75% na barra, a força 10 gera cerca de 326 studs e a força 40 gera cerca de 497 studs.

## Verificações

- Em Play local, o raio lançado de cima da pista atingiu uma placa da Pradaria Solar e outro atingiu uma peça do acostamento. Foram conferidos os seis portais da pista, 29 muros de contenção com colisão, 144 placas de pista com relevo e 48 pontos de decoração.
- A academia subiu do nível 1 ao 2 na terceira repetição. O desafio concedeu mais 8 XP de academia. A Barra Reforçada foi comprada pelo fluxo normal. Parar o treino restaurou a câmera e o controle.
- Um arremesso da faixa com 97% na barra percorreu cerca de 425 studs até a Floresta Neon e revelou Flutterwing. **Jogar de novo** reabriu a barra. No arremesso seguinte, **Voltar à base** levou ao santuário e restaurou o controle. O menu de orbes exibiu oito prévias 3D.
- `scripts/Test.ps1` aprovou a compilação Luau, os testes com mocks e o build Rojo. Os testes incluem 21 cenários de academia, 28 de arremesso e 32 de persistência e serviços. A validação de persistência cobre o excedente de XP de um save antigo e o salvamento da máquina de estágio 8.

O Play foi feito com um cliente e StudioMemory. Permanecem pendentes a medição em celular físico, o teste simultâneo com oito jogadores e a verificação de DataStore publicado.
