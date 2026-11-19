# Benefícios, recibos e comércio

`GameplayMath` contém somente as regras matemáticas compartilhadas. `MonetizationService` verifica os direitos no servidor; `TradeService` coordena decisões persistentes e reconciliação; `AuctionService` implementa leilões **da sala atual**. `CommercePanels` apresenta trocas, leilões e Grupo/VIP usando os estados enviados pelo servidor.

## Vendas e benefícios

Os IDs de passes/produtos permanecem **zero**, `SalesEnabled = false` e todas as entradas têm `FulfillmentReady = false`. Esta implementação não cria produtos, não publica a experiência e não oferece compras reais. O catálogo continua identificando os preços como planejados.

As chaves verificadas de benefícios são as mesmas do catálogo: `StarterPack`, `TitanArms`, `AutoThrow`, `DoubleCoins`, `DoubleLuck`, `GiantSanctuary`, `GoldenVIP`, `FusionXP`, `TripleThrow`, `EternalPrism` e `MegaCollector`, além de `GroupMember`. Consultas de passes usam `UserOwnsGamePassAsync` no servidor; o grupo depende de `ConfigGameplay.GroupId`, atualmente zero. Nenhum remote aceita uma tabela de benefícios do cliente.

As regras preservam os valores detalhados do plano: Titã dobra o ganho de treino e aumenta o alcance em 35%; grupo adiciona 10% de sorte e um slot; Santuário Gigante adiciona oito slots, com teto total de 24. Sorte inclui nível, pity, rebirth, recompensas de bestiário, grupo, Fever, passe, poção, evento e Prismática quando realmente equipada com direito verificado. O multiplicador de XP não reaplica Fever: CaptureService é responsável por esse bônus.

Renda offline integra uma poção de moedas somente pelo período em que ela estava válida, dentro das primeiras oito horas desde `LastSeen`. Os campos da última poção devem continuar disponíveis até esse cálculo, mesmo que a expiração já tenha passado. Os valores salvos das criaturas antigas são preservados. O Starter Pack é uma concessão única, marcada em `OneTimeGrants`: 50.000 moedas, dez Orbes Rubi, vinte minutos de sorte 2x e uma Cybermantis Dourada promocional com renda de 500/s. Esse registro promocional não altera o catálogo nem a renda das criaturas selvagens.

`ProcessReceipt` aceita somente IDs de produtos conhecidos e com entrega implementada. `PurchaseId` é gravado em `ProcessedReceipts` junto da recompensa antes de retornar `PurchaseGranted`. Falha de substituição ou salvamento mantém a compra pendente e congela a sessão para reconciliação; o código não desfaz unilateralmente uma escrita cuja confirmação foi perdida. Um recibo repetido confirma o mesmo direito, sem concedê-lo duas vezes. O recebimento não depende de a loja estar aberta ou de um evento de fechamento do prompt.

Orbes Mestre são adicionadas ao estoque. O pacote de poções concede `PotionLuck3` e `PotionCoins3`, ativáveis por 30 minutos cada. Totens, invocação de evento e pulo de fusão são tokens persistentes, consumidos pelo serviço de recompensas. Slots extras também são tokens, para que uma compra não desapareça caso o santuário esteja no limite. Não há concessão paga a partir do cliente.

## Trocas diretas

Os dois jogadores devem estar no nível 15 ou superior e fisicamente na praça de trocas, validada pelo servidor. As ofertas contêm somente UIDs de criaturas; não são trocados Robux, passes, gemas ou tabelas de atributos fornecidas pelo cliente.

A sequência é convite → oferta → ambos prontos → revisão de três segundos → ambos confirmam a mesma revisão → persistência. Qualquer alteração de oferta incrementa a revisão e limpa as duas confirmações. Convites vencem em 60 segundos; ofertas sem concluir vencem em três minutos; a revisão vence em 60 segundos. O limite de oito criaturas por lado é uma decisão de implementação configurável por `MaxTradeOfferCreatures`.

Durante revisão e commit, os dois perfis têm uma trava exclusiva. Captura, treino, fusão, automações e outras mutações respeitam `Data.IsBusy`. Antes de transferir, o servidor verifica novamente posse dos UIDs, duplicidade, capacidade e localização. A desconexão antes da decisão cancela a troca. Foco visual, relógio ou botão habilitado no cliente não substituem essas verificações.

## Journal e recuperação

O DataStore `ThrowASphere_Transactions_v2` guarda um coordenador por operação, com estado `Prepared`/`Open`, seguido de uma decisão terminal `Committed` ou `Aborted`. Chaves usam um GUID. Em StudioMemory existe um journal equivalente em memória, sem acesso ao DataStore.

Na troca, cada perfil grava primeiro sua preparação em `PendingTransactions`. Somente depois das duas preparações duráveis o coordenador pode decidir `Committed`. Os patches finais preservam UID, variante e renda, removem do santuário os itens enviados e mantêm moedas, rebirths, recibos e demais campos dos participantes. Transferências não aumentam `TotalCoinsEarned` ou `TotalCaptures`, evitando inflação de placar por trocas repetidas.

Uma decisão comprometida nunca sofre rollback unilateral. Cada perfil aplica seu patch junto de `AppliedTransactions[id]` e remove a pendência em uma única escrita. Se houver crash ou erro após a decisão, o próximo carregamento consulta o coordenador e aplica o resultado uma única vez. Preparações ainda sem decisão podem ser abortadas atomicamente. Coordenador indisponível não autoriza adivinhar o resultado: o carregamento preserva os dados para nova tentativa.

Registrar `Trade.Init(ctx)` antes de serviços que calculam renda offline ou atribuem o santuário permite reconciliar o inventário antes de usá-lo. Os callbacks de saída não substituem nem salvam diretamente o perfil que está saindo; sua pendência acompanha o salvamento final e é tratada no próximo carregamento.

## Leilões da sala

As decisões novas, não detalhadas no GDD, são: duração de **120 segundos**, máximo de **dez lotes**, um lote por vendedor e lances inteiros em moedas do jogo. Não existem taxas nem extensão automática do prazo. O vendedor pode cancelar enquanto não houver lance. A saída do vendedor ou do maior ofertante cancela o lote e restitui os escrows. Interrupção da sala não recria um mercado global: na próxima entrada, lotes abertos são cancelados com restituição.

Criar um lote remove a criatura do inventário e registra seu retorno em uma pendência durável antes de abrir o lote. Dar um lance debita as moedas e grava a restituição correspondente antes de atualizar o maior lance. Aumentar o próprio lance debita somente a diferença. Um lance superado devolve o escrow anterior; se o perfil estiver ocupado, uma fila tenta novamente, e a pendência durável protege a restituição até a próxima entrada.

O vendedor reserva um espaço para a possível devolução; o comprador reserva um espaço para a possível vitória. `ReservedSlots` é considerado na capacidade de inventário. No encerramento, uma decisão única transfere as moedas reservadas ao vendedor e a criatura reservada ao vencedor. A capacidade e o UID são revalidados. Um ofertante anterior que ainda espera restituição recebe somente seu próprio escrow, mesmo se o lote terminar com outro vencedor.

O fluxo é local à praça da sala. Um segundo place e a integração entre servidores dependem dos identificadores reais e de validação de implantação; o código não afirma que existe um mercado global.

## Contratos da UI

- `TradeAction(action, payload)`: `Invite {TargetUserId}`, `Accept {SessionId}`, `Offer {SessionId, Revision, Uids}`, `Ready {SessionId, Revision}`, `Confirm {SessionId, Revision}` e `Cancel {SessionId}`.
- `AuctionAction(action, payload)`: `List {Uid, MinimumBid}`, `Bid {AuctionId, Amount}` e `Cancel {AuctionId}`.
- `StateUpdate` contém `Benefits`, `Trade`, `TradeCandidates` e `Auctions`. Os registros do parceiro incluem somente criaturas ofertadas. Recibos, journals e os demais itens do parceiro não são enviados.
- `CommercePanels.Render(parent, kind, state, actions)` retorna cleanup; kinds são `Trocas`, `Leiloes` e `GrupoVIP`. Ações: `Send`, `Notify`, `Open`, `Refresh`, `GetState`, `Session` e `Elapsed`.
- `Signature` exclui dinheiro, texto digitado e relógios. Lances e cronômetros dos lotes atualizam no lugar por `Update`, preservando TextBoxes. Seleção de UIDs, páginas, textos e rolagem ficam na sessão da UI. Confirmações continuam sob controle do servidor.

## Validações

Executar `tests/GameplayMath.spec.luau` com o Luau CLI e `python tests/run_economy_tests.py --luau .tools/luau/luau.exe`.

A bateria usa os módulos reais com mocks determinísticos: benefícios, expiração offline, recibos repetidos/falhas de escrita, substituição recusada, preparação abortada, revisão antiga, perda de resposta do commit, recuperação repetida, escrow de leilão, restituição ao ser superado, aumento do próprio lance, desconexão e reservas de inventário. Esses testes não comprovam disponibilidade real do DataStore, recibos em produção ou transporte entre places. As verificações no Studio e em experiência de teste devem ser registradas separadamente no checkpoint.
