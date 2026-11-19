# Mundo, biomas, eventos, chefes e pódio

Este documento registra a implementação funcional anterior à importação dos modelos finais. As criaturas e estruturas ainda usam peças provisórias; os pontos de interação e as regras do servidor já ficam separados da arte.

## Mundo e acesso

- `ConfigWorld` define seis ilhas, portais, área local de trocas, pontos de evento e arena. `WorldService` gera piso de cada bioma, seis santuários com 24 pedestais, treino pessoal, estações e portais com `ProximityPrompt`.
- Os limites/custos do GDD permanecem: Floresta $2.500/4 espécies; Vulcão $50.000/10; Glacial $1,2M/16; Ruínas $45M/22; Vazio $2,5B/26 e nível 25. São compras permanentes por ciclo de rebirth.
- `BiomeService.Unlock` valida dados, transação em andamento, registros conhecidos e saldo antes de debitar. Repetir um desbloqueio concluído não cobra novamente.
- `Travel` verifica permissão, personagem vivo e cooldown. A praça de trocas local exige nível 15. A posição física do personagem determina `CurrentBiome`; o atributo usado pela interface não autoriza ações.
- `ReturnToMeadow` é um gancho interno do rebirth; não existe remote que permita ignorar uma trava de transação.
- A praça local permite implementar/testar trocas sem outro place publicado. `TradingPlaceId`, configuração pública da experiência, servidores privados e produtos reais continuam operações separadas.

## Spawns e captura

- Cada zona recebe seis criaturas provisórias. A primeira população distribui as espécies locais; após captura, a reposição ocorre em dois segundos e usa os pesos Comum 55, Incomum 30, Rara 12, Épica 5, Mítica 2 e Lendária 1. Esses pesos são decisões novas de balanceamento em `ConfigEvents`.
- Cada reposição tem uma verificação real de `1e-6` para Omnisfera. `SpawnChance` representa a chance de selecionar a espécie, incluindo o sorteio secreto; não representa chance de captura. A primeira população e especiais garantidos de evento não inventam uma probabilidade de nascimento.
- Mutação/tamanho são sorteados antes da captura. Sorte global de eventos/totens aumenta os pesos de variantes não normais nos novos spawns. Quantis privados permitem um bônus pessoal na recompensa de captura, sem reescrever a criatura compartilhada; detalhes abaixo.
- Patrulha provisória no servidor move os alvos dentro de um raio pequeno do seu ponto. Alvos bloqueados ficam parados; a implementação não depende de rigs ou animações finais.
- `CaptureService.TryThrow` é comum ao mouse, toque, controle e automação. Todas as rotas verificam transações, acesso ao bioma, estoque/entitlement, alcance, vida, ponto de impacto, linha de visão e catch lock.
- Rubi recebe +10% contra Fogo; Safira recebe +10% contra Água/Gelo. Prismática só é infinita com benefício confirmado pelo servidor. Sorte 10x vem de `GameplayMath` e não é aplicada duas vezes.
- Arremesso Triplo procura no servidor até dois alvos adicionais dentro de um cone de 25 graus. Cada alvo passa novamente pelas verificações, consome sua própria orbe e compartilha o cooldown do burst. Nenhum booleano enviado pelo cliente habilita esse caminho.
- Fever aplica 2x ao XP bruto de captura antes de `GrantXP`; o serviço de progressão aplica os demais benefícios uma vez e retorna o XP efetivamente concedido.

## Eventos e chefes

Decisões novas, necessárias porque os documentos originais não fixavam estes parâmetros:

- Ciclo de 1.200 segundos, duração de 300 segundos e rotação Meteoros → Eclipse → Tempestade Áurea. Meteoros/Eclipse concedem 2x sorte global; Tempestade, 3x.
- Meteorgon aparece na Pradaria durante Meteoros; Eclipsion durante Eclipse. Isso permite conseguir os registros adicionais exigidos pelos portões de Ruínas/Vazio antes de acessá-los.
- Totem concede 5x sorte durante 900 segundos. Repetições acumulam duração até 1.800 segundos; no limite, a API recusa o uso para o chamador preservar o token. Sorte de evento e totem se multiplicam.
- `Weather.UseTotem`, `ActivateGlobalLuck` e `SummonEvent` são APIs internas; `RewardService` controla o consumo dos respectivos itens. Um evento em andamento não é substituído por outro token.
- Chefes começam com estabilidade 100. Cada impacto validado causa `clamp(sqrt(poder efetivo) × 1,5, 2, 25)`. O arremesso consome estoque e respeita o cooldown normal. O catch lock exclusivo das criaturas comuns não impede contribuições simultâneas de jogadores diferentes no chefe.
- Todos os contribuidores ainda conectados e com perfil carregado recebem uma captura com UID próprio e a variante do chefe, mais seu XP base. Quem estiver sem espaço recebe moedas equivalentes a 60 segundos da renda base da espécie, o registro do bestiário e o XP. Uma recompensa só pode ser concedida uma vez por jogador/chefe.
- Se uma transação bloquear temporariamente o perfil, a recompensa aguarda enquanto ele continuar carregado. A fila do encontro é da sessão; sair antes de recebê-la não cria um crédito persistente pendente.
- Ao terminar um evento, seus alvos param de aceitar lançamentos. Um alvo com catch lock aguarda o fim da resolução antes de desaparecer; não há destruição no meio da animação ou respawn infinito de criaturas temporárias.

## Rankings e avatares

- Quatro rankings atualizam a cada 60 segundos: moedas acumuladas cunhadas pelo jogo, melhor renda de captura ainda no inventário, score `100 × rebirths + nível` e espécies descobertas.
- O Studio em memória usa somente jogadores da sessão. Servidores persistentes usam quatro `OrderedDataStore`s e resumos separados com os valores reais. A ordenação de valores grandes usa `floor(log10(valor + 1) × 1.000.000 + 0,5)`; valores extremamente próximos podem empatar nessa precisão.
- Falhas de consulta preservam o último resultado. Se a primeira consulta falhar, o modo é identificado como `SessionFallback`. A criação dos stores pode ser tentada novamente após recuperação.
- O pódio mostra os três líderes de moedas e sua criatura equipada de maior renda em peça provisória. Avatares oficiais são carregados com `Players:CreateHumanoidModelFromUserIdAsync`; animações finais e modelos das criaturas continuam para a fase de arte. O cache de modelos é limitado aos vencedores atuais.
- A base consulta `Data.IsPersistent()` apenas na atualização, após a inicialização dos dados; o Studio não acessa o ranking publicado por acidente.

## Contratos de integração

- `World.Init(ctx)`, `Biomes.Init(ctx)`, `Weather.Init(ctx)`, `Boss.Init(ctx)` e `LeaderboardPodiumService.Init(ctx)`.
- `Spawn.Init(ctx)` e `Capture.Init(ctx)` aceitam o contexto; as assinaturas antigas continuam válidas para regressão.
- Remotes: `UnlockBiome`, `TravelToBiome`, `WorldStateUpdate`, `RequestWorldState` e `OpenPanel`. Os dois primeiros recebem apenas o ID do destino; eventos/chefes não aceitam concessões arbitrárias do cliente.
- Providers de snapshot: `CurrentBiome`, `Weather` e `Leaderboards`. `WorldStateUpdate` envia o mapa retornado por `Weather.GetState()` sem wrapper.
- `Weather`: `Id`, `EventId`, `Name`, `StartedAt`, `EndsAt`, `NextAt`, `LuckMultiplier`, `TotemEndsAt`, `TotemOwner`, `Boss`.
- `Leaderboards`: `Mode`, `UpdatedAt`, `Boards` com `Coins`, `Capture`, `Level`, `Bestiary`.
- `ClientWorldController` aplica clima, auras, pilares e cor Arco-Íris localmente; nenhuma recompensa depende desses efeitos.

## Verificação

O runner `tests/run_capture_tests.py` executa os módulos de produção com fronteiras simuladas: 34 cenários de captura, 9 de spawn/expiração, 13 de biomas/eventos/chefes/rankings e 10 de drops/fragmentos/variantes, incluindo 20.000 verificações de quantis sem downgrade. Compilação e mocks não substituem Play, dois clientes, teste de persistência publicada nem publicação dos produtos.

Referências de API: [Players](https://create.roblox.com/docs/reference/engine/classes/Players), [OrderedDataStore](https://create.roblox.com/docs/reference/engine/classes/OrderedDataStore).

## Fragmentos, drops e sorte pessoal

- A fuga concede de 1 a 3 fragmentos. `CraftOrbFragments` transforma 10 em uma Orbe Comum sob trava e salvamento confirmado; saldo insuficiente, spam e estoque no limite não consomem fragmentos. Fragmentos e estoque criado têm teto de um bilhão.
- Cada captura cria um pacote físico provisório de moedas equivalente a dois segundos de sua renda registrada, mínimo $5; contribuições premiadas de chefe usam cinco segundos. Cada pacote tem chance real de 0,1% de conter também uma Orbe Mestre. Tudo é configurável em `ConfigDrops`.
- Só o dono pode recolher seu pacote. Coleta manual exige personagem vivo e distância de até 12 studs, validada no servidor. Pacotes expiram após 60 segundos. O limite de 20 pacotes físicos por jogador agrupa novas recompensas em um pacote existente, sem duplicar instâncias ou perder a Orbe Mestre.
- O Auto-Coletor do nível 3 recolhe os próprios pacotes pendentes quando o jogador está em seu santuário. Mega Coletor faz isso em qualquer local. A renda passiva do santuário continua entrando diretamente como no protótipo anterior; esse atalho não foi removido.
- `ctx.Drops` recebe `DropService`; `Init(ctx)`, `OnCapture(player, record, position, isBoss?)`, `AwardFailureFragments`, `Collect`, `CraftOrbFragments`, `GetSnapshot` e `Tick` são as APIs. Remotes opcionais: `CollectDrop` e `CraftOrbFragments`; os pacotes também possuem `ProximityPrompt`.
- `DropInfo` informa os próprios pacotes, custo de criação, chance real da Mestre e disponibilidade dos coletores. Não revela pacotes privados de outros jogadores.
- DoubleLuck, poções de sorte ativas e a Prismática verificada aumentam os pesos das mutações/tamanhos raros na recompensa pessoal. O servidor reutiliza os quantis privados do nascimento; essa transformação só mantém ou melhora a variante vista no mundo. Pesos multiplicados são normalizados, não uma promessa falsa de multiplicar uma probabilidade já próxima de 100%.
- `ThrowResult.VariantBonus` identifica a melhoria real; `MutationName`, `SizeName` e `IncomePerSec` correspondem ao registro concedido. `SpawnChance` continua sendo a probabilidade da espécie no nascimento e não muda por esse bônus.
