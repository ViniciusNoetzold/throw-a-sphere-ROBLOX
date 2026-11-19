# Arremesso por biomas e academia

Implementação funcional de 19/11/2026. A fonte é `src/`; `game/ThrowASphere.rbxlx` é o build gerado pelo Rojo. Equipamentos, criaturas e orbes ainda usam peças provisórias. Os valores da academia são parâmetros de teste, sujeitos ao balanceamento posterior solicitado pelo usuário.

## Ciclo do jogador

1. Abrir **ACADEMIA** na barra inferior ou interagir com **TREINO PESSOAL** no próprio santuário.
2. O personagem faz repetições automaticamente na barra provisória. Cada ciclo aumenta a força de arremesso, o XP da academia e uma pequena quantidade de XP do jogador.
3. A cada três repetições aparece um botão **2×** em uma posição diferente. Clicar, tocar ou apertar **E / X** dentro da janela concede um bônus equivalente ao ganho daquela repetição. Falhar mantém o treino automático e seus ganhos normais.
4. A barra mostra XP atual, próximo nível e ganho por ciclo. Subir o nível da academia aumenta gradualmente a força recebida por repetição. **PARAR TREINO**, **Esc** ou **B** devolvem os controles ao jogador.
5. Caminhar até a linha amarela antes do corredor. A barra de força aparece automaticamente; as outras interfaces ficam recolhidas durante a ação.
6. Clicar ou tocar em qualquer lugar, ou usar **R2**, trava a força. As duas pontas vermelhas são fracas; o centro verde é forte. O servidor calcula a força usando seu próprio relógio.
7. O personagem executa uma das três performances procedurais: fraca, média ou forte. A câmera acompanha a orbe pelo corredor, respeitando os biomas desbloqueados.
8. A espécie é sorteada no servidor somente ao final do voo. O resultado passa pelas três balançadas e pela revelação, cuja apresentação cresce com a raridade.

A pista tem uma barreira física e correção pelo servidor: somente a orbe percorre seu interior. O antigo lançamento direcionado via `RequestThrow` fica desativado no bootstrap com `FlightService`, impedindo um caminho alternativo fora da linha. A adaptação do combate direcionado do chefe para esse novo formato fica pendente; o sistema legado permanece coberto por seus testes, sem ser anunciado como combate validado no novo ciclo.

## Inspiração e decisão de design

As referências de Pokémon misturam sistemas distintos. A orientação oficial de Sword/Shield descreve treinamento direcionado de atributos por pontos base; em Pokémon GO o fortalecimento usa Poeira Estelar e Doces para aumentar CP/HP. Portanto, não foi implementada uma regra única que atribui a todos esses jogos o mesmo treinamento por XP. Referências: [guia oficial de treinamento](https://www.pokemon.com/us/strategy/train-raid-and-hatch-pokemon-to-breed-victories-in-pokemon-sword-and-pokemon-shield) e [ajuda oficial do Pokémon GO](https://niantic.helpshift.com/hc/en/6-pokemon-go/faq/2372-powering-up-pokemon/?hl=en).

Aqui a adaptação é treinar o **treinador** para arremessar mais longe. O ciclo é treino → força → distância → biomas → coleção e renda. O desafio de 2× recompensa atenção sem exigir cliques contínuos. Esta entrega não cria EVs, batalhas, vínculo ou níveis individuais das criaturas. Essas decisões podem acompanhar os modelos e equipamentos que o usuário vai produzir.

Os três vídeos locais enviados pelo usuário foram usados como referências de timing, preparação, câmera de voo, distância e revelação. Não foram publicados no Git. As cenas de revelação atuais são uma base funcional com silhueta, zoom, órbitas, luz, anéis e som; a direção de arte e as animações finais ainda serão trabalhadas com os modelos definitivos.

## Configuração provisória

| Arquivo | Responsabilidade |
| --- | --- |
| `src/shared/ConfigTraining.luau` | Tempo por repetição, XP, desafio a cada três ciclos, janela do desafio, limites e ganho por nível |
| `src/shared/TrainingMath.luau` | Curva de XP e ganho da academia |
| `src/shared/ConfigFlight.luau` | Linha amarela, período da barra, dimensões da pista e duração do voo |
| `src/shared/FlightMath.luau` | Barra com centro forte, alcance, bloqueios de bioma e escolha ponderada da espécie |
| `src/shared/ConfigReveal.luau` | Sete apresentações por raridade, do comum ao secreto |

O bônus de 2× dobra a repetição que originou o desafio; não dobra indefinidamente o treino inteiro. Não há treino offline novo nesta entrega. Benefícios pagos existentes continuam dependendo das verificações do servidor e de IDs configurados; nenhum produto foi cadastrado.

## Segurança e continuidade

- Força, XP, nível, bioma, estoque de orbes, espécie, variantes e captura são decisões do servidor.
- Tokens dos desafios são temporários, vinculados à sessão e consumidos uma única vez. IDs falsos, repetidos, vencidos ou enviados após respawn não geram bônus.
- O treino pausa durante operações de dados e não compensa uma pausa longa com uma explosão de recompensas.
- A academia e o voo não podem começar ao mesmo tempo. Morte, respawn, saída e parada limpam as sessões e restauram os controles.
- `TrainingLevel` e `TrainingXP` entram no perfil existente com padrões seguros, preservando moedas, criaturas e campos anteriores. Os testes cobrem migração, save/load e rejeição de valores inválidos.
- O voo fixa estoque e capacidade sob trava de dados, resolve uma vez e exige salvamento antes de anunciar sucesso. Cancelamento remoto após o lançamento não devolve a orbe.

## Integração da arte

A barra da academia é um blockout em `WorldService`; substituir sua geometria mantendo `PersonalTraining` como referência de posição. As três performances do personagem estão em `Throw/ThrowPose.luau` e podem ser substituídas por clipes finais compatíveis com os rigs.

`RevealDirector` procura `ReplicatedStorage/CreatureModels/<CreatureId>`. Se existir um Model, usa uma cópia visual ancorada e sem scripts; caso contrário, mostra a criatura provisória. Os parâmetros visuais não alteram as chances nem as recompensas.

## Validação

Executar `powershell -ExecutionPolicy Bypass -File scripts/Test.ps1`. A rotina compila as fontes, verifica a integridade das skills, roda as suites com mocks e gera o arquivo do Studio. O relatório desta entrega está em [docs/reviews/2026-11-19-arremesso-academia.md](reviews/2026-11-19-arremesso-academia.md).

Permanecem pendentes testes multiplayer, toque em dispositivo físico, experiência publicada/DataStore real, balanceamento final, arte definitiva e adaptação do chefe ao novo arremesso. Compilação, mocks e Play local não substituem esses testes.
