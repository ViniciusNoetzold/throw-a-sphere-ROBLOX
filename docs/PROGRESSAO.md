# Progressão, fusão, recompensas e automação

O servidor é a autoridade de moedas, estoque, propriedade das criaturas, relógios, acesso a passes e resgates. A interface envia intenção e IDs. Operações de recompensa, fusão, rebirth e compra de espaços usam trava por jogador e salvamento imediato; falha de persistência interrompe a sessão para proteger o save anterior.

## Regras do GDD implementadas

- Fusão no nível 10: cinco criaturas da mesma espécie, mutação e tamanho; quatro com o passe `FusionXP`. Normal gera Dourada com renda-base 3×; Dourada gera Cristal 6×; Cristal gera Arco-Íris 15×. O tamanho é preservado e seu multiplicador continua aplicado. A fusão não muda os multiplicadores das variantes selvagens, que continuam 2×/3,5×/12×. O resultado recebe `FusionStage` 1/2/3.
- Rebirth no nível 40: +5 gemas e +1 rebirth; os multiplicadores permanentes são +100% renda, +50% sorte e +50% XP por rebirth. Força, orbes, coleção, bestiário, compras e resgates são preservados.
- Diário com sete dias conforme a tabela principal do GDD: dia 1, 500 moedas/10 Comuns/100 XP; dia 2, 2.500/5 Esmeraldas/poção 2× sorte 10 min; dia 3, 15.000/5 Rubis/500 XP; dia 4, Rara Dourada/poção 2× moedas 15 min; dia 5, 250.000/3 Rúnicas/1.500 XP; dia 6, totem global/3 Hextech; dia 7, Mestre/pet semanal/5 gemas/título Fiel.
- Presentes nos marcos 2, 5, 10, 15, 20, 30, 40, 50, 60, 75, 90 e 120 minutos. O último inclui uma Orbe Cósmica.
- Missões a partir do nível 5: 15 capturas, 3 críticos e 1 fusão; cada missão é resgatada uma vez por dia UTC. Crítico validado pelo servidor conta mesmo quando a criatura escapa.
- Coleção completa por bioma concede +10% sorte permanente, moedas e título de domínio do bioma.
- Auto-Arremesso/Auto-Treino exigem `AutoThrow`; membros do grupo recebem Auto-Treino. Auto-Fusão exige `MegaCollector`. Auto-Treino só funciona no santuário pessoal. Arremessos automáticos reutilizam a mesma validação, estoque, alcance, obstáculos e cooldown do arremesso manual.

## Decisões de balanceamento onde o GDD era incompleto

As definições ficam em `src/shared/ConfigProgression.luau` e `ConfigRecompensas.luau`.

- Rebirth também volta nível/XP a 1/0 e moedas a 150; biomas retornam à Pradaria. Isso impede rebirth ilimitado no mesmo nível 40. Slots que excederem a capacidade após perder os marcos de nível são desequipados; criaturas continuam no inventário.
- Fusão entrega o resultado imediatamente e aplica 30 segundos de recarga; o passe `FusionXP` reduz o lote a quatro criaturas e zera a recarga. `SkipFusion` remove uma recarga restante. Auto-Fusão só usa criaturas de raridade Comum, mutação Normal e fora dos slots de exibição; não consome raras ou criaturas equipadas automaticamente.
- Espaços por moedas começam em 10.000 e dobram a cada espaço comprado. Capacidade total máxima: 24, incluindo níveis, grupo e passes.
- Diário exige 24 horas entre resgates; depois de 48 horas sem resgate o ciclo volta ao dia 1. O dia 4 usa Voltmouse Dourada Normal. O pet semanal é registrado em `WeeklyPets`, um cosmético cuja apresentação 3D será produzida na etapa de modelos.
- Tempo online acumula por dia UTC e persiste entre sessões; reentrar não reabre um presente já recebido. Horas offline não contam como playtime. O acumulado muda de dia à meia-noite UTC.
- Moedas dos presentes são o valor abaixo multiplicado pelo nível no momento do resgate; XP também recebe os multiplicadores gerais de XP do jogador.

| Minutos | Moedas-base × nível | Extra |
| --- | ---: | --- |
| 2 | 500 | 10 Comuns |
| 5 | 1.000 | 3 Esmeraldas |
| 10 | 2.500 | 250 XP |
| 15 | 5.000 | 3 Rubis |
| 20 | 10.000 | Poção 2× sorte |
| 30 | 25.000 | 2 Safiras |
| 40 | 50.000 | 500 XP |
| 50 | 75.000 | 1 Rúnica |
| 60 | 100.000 | Poção 2× moedas |
| 75 | 150.000 | 1 Hextech |
| 90 | 250.000 | Poção 2× sorte |
| 120 | 500.000 | 1 Cósmica |

Missões: capturas dão 3 orbes/250 XP/1 gema; críticos, 2 orbes/300 XP/1 gema; fusão, 2 orbes/500 XP/2 gemas. A missão de fusão exige nível 10; as outras exigem nível 5. Orbes por bioma: Comum, Esmeralda, Rubi, Safira, Rúnica e Cósmica, respectivamente.

Moedas do bestiário completo: Pradaria 1.000; Floresta 10.000; Cânion 50.000; Abismo 250.000; Ruínas 2.000.000; Vazio 10.000.000. O título registra a aura/trilha conquistada; a apresentação final pertence à etapa visual.

## Consumíveis e códigos

`PotionLuck2` dura 600 s, `PotionCoins2` 900 s; `PotionLuck3` e `PotionCoins3` duram 1.800 s. Poção igual estende a duração; poção superior substitui a inferior; tentar consumir uma inferior enquanto a superior está ativa não gasta o item. O cálculo offline integra o trecho efetivamente coberto por uma poção de moedas, com limite de oito horas.

`GlobalLuckTotem` ativa 5× sorte por 900 s através do serviço de clima. `SummonEvent` invoca um evento através desse serviço. O débito é salvo antes de ativar um efeito global; se o serviço recusar, a devolução também é salva sob a mesma trava. `SanctuarySlot` adiciona um espaço e preserva o token quando já há 24 espaços. Tokens são descontados somente no servidor.

O baú VIP exige `GoldenVIP` verificado e intervalo de 24 horas; o conteúdo configurável inicial é 10.000 moedas, três Esmeraldas e 100 XP base. Esses valores são uma decisão nova de balanceamento, pois o GDD especificava o baú sem definir seu conteúdo.

`Codes = {}` é intencionalmente vazio. Não existem promoções inventadas. Para cadastrar um código real em `ConfigRecompensas`, use uma chave em maiúsculas e o formato `{ExpiresAt = timestampOpcional, MinLevel = 1, Reward = {Coins = 500, Orbs = {Comum = 5}}}`. Cada código é resgatável uma vez por perfil; o servidor ignora espaços externos e diferença de maiúsculas/minúsculas.

## Interfaces de integração

`GrantXP(player, amount)` retorna `(leveled, gained)` e aplica os multiplicadores gerais de XP uma única vez. CaptureService aplica o Fever antes de chamar essa função. No nível 100, `gained` é zero.

`RewardService.GrantReward(player, reward)` é uma API interna para um chamador que já controla a transação/salvamento. A recompensa de criatura verifica a capacidade incluindo reservas de devolução de trocas e leilões. `OnProgress(player, "Captures" | "Criticals" | "Fusions", amount)` recebe eventos internos confiáveis.

Remotes: `RebirthRequest`, `BuySanctuarySlot`, `FuseCreatures`, `ClaimDailyReward`, `ClaimPlaytimeReward`, `ClaimMissionReward`, `ClaimBestiaryReward`, `RedeemCode`, `UseConsumable`, `ClaimGroupReward`, `SetAutoMode`. O perfil público recebe os resumos `Progression`, `Fusion`, `Rewards`, `Automation` e `SlotCapacity`; metadados de transação ficam no servidor.
