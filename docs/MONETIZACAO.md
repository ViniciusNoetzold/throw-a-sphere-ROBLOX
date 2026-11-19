# Loja, benefícios e recibos

A interface reúne os 11 passes e oito produtos do catálogo detalhado do planejamento. A tabela compartilhada fica em `src/shared/ConfigMonetizacao.luau`; a view está em `src/client/UI/ShopView.luau`. Os algoritmos de benefícios, a integração com os serviços de jogo e o processamento persistente de recibos estão implementados. A validação com produtos reais em uma experiência publicada continua pendente.

Todas as entradas têm `Id = 0` e `FulfillmentReady = false`, e o catálogo tem `SalesEnabled = false`. Por isso a loja apresenta **Em breve**, informa que compras estão indisponíveis e identifica cada preço como **Planejado**. Nenhum prompt de compra é disparado nessa configuração. Não há cronômetro de oferta ou afirmação de produto mais vendido sem dados reais.

O código prepara `PromptGamePassPurchase` e `PromptProductPurchase` somente quando as três condições estiverem presentes: vendas habilitadas, ID válido e entrega pronta. Nessa situação consulta `GetProductInfoAsync` com o tipo adequado e usa o preço devolvido pelo Roblox. Uma consulta falha mantém o botão indisponível. Para passes, também verifica a propriedade antes de oferecer a compra. Callbacks de consultas antigas são descartados quando a aba muda ou a view é destruída.

## Benefícios no servidor

`MonetizationService` verifica a propriedade dos passes no servidor e mantém os direitos confirmados em cache durante a sessão. O cliente recebe somente o estado público dos benefícios; não pode conceder moedas, orbes ou direitos pagos. Com IDs zero, nenhum passe é reconhecido como adquirido. A participação em grupo também depende de `ConfigGameplay.GroupId`, atualmente zero.

`GameplayMath` centraliza capacidade de santuário, ganho de treino, alcance, sorte, multiplicadores de moedas e XP e renda offline. A renda offline considera a expiração de poções durante a janela de até oito horas. Captura, progressão, fusão, automações e recompensas consomem os benefícios verificados no servidor. O Starter Pack usa uma marca persistente para impedir concessão repetida; VIP possui resgate diário controlado pelo servidor. A apresentação final de auras e modelos acompanha a etapa de arte.

As regras e os contratos estão em [Economia e trocas](ECONOMIA_E_TROCAS.md) e [Progressão](PROGRESSAO.md).

## Recibos e consumíveis

`ProcessReceipt` reconhece somente produtos conhecidos com ID válido e `FulfillmentReady = true`. A recompensa e o `PurchaseId` em `ProcessedReceipts` são salvos juntos antes de retornar `PurchaseGranted`. Recibos repetidos não repetem a concessão. Falha de substituição ou salvamento mantém o recibo pendente e protege a sessão para recuperação; o serviço não confirma uma entrega sem persistência. Eventos de fechamento do prompt não comprovam a entrega de um produto.

Orbes Mestre entram no estoque. O pacote de poções concede um token de sorte 3x e um de moedas 3x, ativáveis por 30 minutos cada. Totens, invocação de evento, pulo de fusão e slot extra são tokens persistentes consumidos pelo serviço de recompensas. O slot permanece disponível quando o santuário já está no limite.

## Configuração e validação pendentes

Nenhum passe ou produto foi criado, nenhuma venda foi ativada e a experiência não foi publicada nesta etapa. **`SalesEnabled = false`, IDs zero e `FulfillmentReady = false` permanecem no repositório**, mesmo com a lógica de entrega implementada.

A bateria automatizada inclui 22 cenários de `GameplayMath` e 73 cenários de economia com módulos reais e mocks, cobrindo recibos duplicados, falhas de escrita, concessão única e recuperação de transações. Esses testes não substituem a validação externa de MarketplaceService e DataStore em experiência publicada. Antes de habilitar uma entrada, é necessário configurar os identificadores corretos e validar propriedade, entrega persistente, reentrada, repetição de recibos e falhas de salvamento nesse ambiente. O checkpoint e os testes ainda pendentes estão em [Teste no Studio](TESTE_NO_STUDIO.md).

Os preços de referência não são ajustes da economia ao vivo. Para balanceamentos que precisem de mudanças sem reiniciar servidores, considerar Experience Configs no servidor; preços efetivos em Robux continuam pertencendo ao MarketplaceService.

Referências oficiais: [MarketplaceService](https://create.roblox.com/docs/reference/engine/classes/MarketplaceService), [passes](https://create.roblox.com/docs/production/monetization/passes) e [developer products](https://create.roblox.com/docs/production/monetization/developer-products).
