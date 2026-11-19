# Curral, chance de raros e captura

## Progressão da pista

| Bioma | Nível | Força |
| --- | ---: | ---: |
| Pradaria Solar | 1 | Inicial |
| Floresta Neon | 4 | 35 |
| Cânion Vulcânico | 11 | 180 |
| Abismo Glacial | 20 | 580 |
| Ruínas Ancestrais | 33 | 1.500 |
| Vazio Cósmico | 50 | 4.000 |

O servidor calcula o alcance pela força, pelo nível, pela orbe e pelo acerto na barra. Os marcos limitam até onde a orbe pode viajar. A Chance de raros usa a distância efetiva e o multiplicador da orbe. Cada variante mostra a probabilidade conjunta de espécie, mutação e tamanho. O denominador usa abreviações de Big Numbers.

## Verificações

- O pacote local reúne 23 malhas e 40 paletas alternativas da fonte Blender. No Play, 36 criaturas selvagens exibiram textura e nenhuma peça provisória de criatura ficou visível. Uma Sproutling Dourada e Enorme mostrou a textura e a paleta no curral.
- Um arremesso com perfil inicial terminou em 299 studs na Pradaria Solar. Foram verificadas a absorção, as balançadas, a malha texturizada na revelação e a escolha pós-captura. Com um perfil de teste em nível 6 e força 1.200, a orbe Esmeralda exibiu o fator ×1,25 e terminou em 599 studs na Floresta Neon.
- O curral começou em 10 vagas. A sessão de teste confirmou que a seleção por renda põe a criatura mais rentável na primeira vaga, a substituição mantém as duas criaturas na coleção e a venda retira apenas a escolhida do inventário.
- A compilação Luau, os testes com mocks e o build Rojo passaram. Os testes com mocks verificam os marcos, o cálculo de chances, o excedente do curral, o envio de capturas antigas ao inventário e a proteção contra venda duplicada.

O Play usou um cliente em StudioMemory. A publicação no Roblox, o armazenamento em produção e o desempenho em dispositivos físicos ainda precisam de validação.
