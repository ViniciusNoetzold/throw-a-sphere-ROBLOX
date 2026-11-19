# Roteiro de validação do jogo base

Este roteiro separa testes automatizados, Play local e validações externas. A presença de um item neste arquivo não significa que o teste foi executado.

## Estado observado em 18/11/2026, 21:45 — Brasília

- Compilação Luau e build Rojo: passaram por `scripts/Test.ps1`.
- Sistemas com mocks: **206 cenários** — 66 captura/spawn/mundo/drops, 31 dados, 73 economia/transações e 36 progressão/recompensas/automações.
- GameplayMath: **22 cenários**. Big Numbers: **86 verificações**. CaptureMath e 20 mil quantis/amostras determinísticas de variantes: passaram.
- Play real via MCP: schema 2/salvamento válido de teste; fusão de cinco UIDs em Dourada de 24/s; daily por remote e por clique real na UI, com uma única concessão; playtime, poções e bestiário com proteção contra repetição; desbloqueio/viagem e acesso negado por requisito; token de totem debitado; chefe em quatro acertos com recompensa única; rebirth preservando a coleção.
- Drop físico real: posição `Vector3`, sete moedas e uma Orbe Mestre concedidas uma vez, com segunda coleta recusada. Fragmentos por fuga e criação de Orbe Comum com dez fragmentos estão implementados; as regras e os testes determinísticos constam em [Mundo](MUNDO.md).
- Primeiro HUD do passo 2 emulado em iPhone 17 Pro e Samsung Galaxy A06 em paisagem: conferido. R2 bloqueado por modal e fechamento por B/Escape: observados.
- **QA real no Studio desktop:** Fusão, Rebirth, Auto, Códigos, Biomas, Bestiário, Criaturas, Orbes, Rank, Consumíveis, Trocas, Leilões e Grupo/VIP abriram com `Modal = true` e `TextFitsFailures = []`. O listener das estações para abrir os painéis foi corrigido e testado no HUD final. Output final sem erros do projeto. Essa rodada cobre abertura e ajuste de texto dos 13 painéis, sem afirmar validação multiplayer ou em aparelhos físicos.
- Evidências: [HUD das mecânicas](evidencias/mecanicas-presentes.jpg) e [Fusão](evidencias/mecanicas-fusao.jpg).
- **Dois clientes reais, persistência publicada, compras reais e segundo place:** pendentes. Os testes de trocas/leilões até este registro são determinísticos com mocks, não multiplayer real.

## Abrir e conferir a base local

1. Atualize o clone com `git pull --ff-only` depois de conferir `git status`. Instale as ferramentas pelo script do repositório, execute `scripts/Test.ps1` e abra `game/ThrowASphere.rbxlx` no Studio.
2. Dê Play em memória. Confira Output de servidor e cliente, schema 2, HUD único e estado inicial de nível 1, $150, 25 Orbes Comuns e modo de teste local.
3. Confira os seis santuários, os destinos dos seis biomas e as criaturas provisórias por zona. Os modelos atuais são blockouts das 30 espécies, não a arte final.
4. Mire no corpo e na cabeça: arco verde e dourado. Fora do alcance deve ficar vermelho. Lance, confira um único consumo, voo, balançadas, XP/pity na falha e captura/inventário no sucesso.
5. Confirme bloqueio durante captura, reposição de spawns, renda das criaturas equipadas e queda da renda ao desequipar. Compre/equipe uma orbe e treine; confira os valores no servidor.
6. Teste respawn do avatar, câmera e reabertura dos menus. O HUD não pode duplicar.

## UI completa e controles

1. Confira moedas/renda, força/alcance, gemas, nível/XP, orbe e estoque usando dados reais. Fever só anuncia bônus no combo real de dez capturas; eventos exibem o estado real do servidor.
2. Abra Bestiário, Criaturas, Orbes, Loja, Fusão, Rebirth, Diário, Missões, Consumíveis, Biomas, Auto, Códigos, Grupo/VIP, Ranking, Trocas e Leilões. Recompensas de bestiário ficam na aba correspondente do Bestiário.
3. Confira rolagem, textos, foco de controle e inputs. Alterações de saldo/relógio não devem apagar códigos ou lances digitados. Oferta/seleção de UIDs e página do inventário precisam permanecer coerentes após atualizações.
4. Abra um modal e pressione/solte mouse, toque e R2 sobre uma criatura: não pode consumir estoque. Feche com B/Escape e confirme que o arremesso volta a funcionar. A navegação por controle deve permanecer dentro do modal.
5. Na loja, confira três abas e 19 itens. IDs são zero e vendas estão desabilitadas; todos os preços devem ser identificados como planejados e nenhum prompt de compra pode abrir. Grupo e VIP não podem aparecer ativos sem configuração/verificação real.
6. No emulador, confira iPhone 17 Pro e Galaxy A06 em paisagem: textos, botões, rolagem, treino, touch, fechamento e espaço para os controles de movimento. Restaure o viewport padrão. A orientação do projeto permanece `LandscapeSensor`.
7. Confira o Output após ciclos repetidos de abrir/fechar menus, trocar abas, receber snapshots e respawn. Emulador não substitui aparelho físico.

## Progressão, recompensas e mundo

1. Funda somente UIDs realmente possuídos e compatíveis; rejeite duplicatas, quantidade errada, nível insuficiente e repetição do pedido. Confira remoção dos ingredientes, criatura resultante, renda e recarga.
2. No rebirth, confira a prévia, confirmação, requisitos, resets e preservação de criaturas/orbes/força/bestiário/compras/resgates conforme [Progressão](PROGRESSAO.md).
3. Resgate daily, presente de tempo, missão e bestiário; repita o pedido e confirme que nada é concedido duas vezes. Use relógios/requisitos do servidor e teste inventário cheio sem consumir recompensa de criatura.
4. Ative poções: mesma potência estende o tempo, poção inferior não substitui uma superior ativa. Slots no teto de 24 devem preservar o token. Totem/evento devem debitar um token somente quando a ativação for aceita.
5. Teste bloqueio de automações sem direito e fora das condições de execução. GrupoId zero e passes sem ID não liberam acesso.
6. Desbloqueie e viaje por cada bioma; teste saldo, registros e nível insuficientes. Tente atravessar a barreira sem desbloqueio e confira a correção pelo servidor.
7. Confira evento, relógio, sorte global, spawns especiais, estabilidade do chefe e recompensa única após a derrota. Confira quatro rankings e atualização periódica; o modo da sala deve ser distinguido de dados globais indisponíveis.
8. Confira fragmentos ao falhar e criação de uma Orbe Comum por dez fragmentos. Saldo insuficiente, spam e estoque no limite não devem consumir fragmentos. Colete um drop físico e repita a coleta: moedas e eventual Orbe Mestre devem entrar uma única vez.

## Próxima etapa de conteúdo

Receber os modelos 3D do usuário; conferir nomes, escala e pivôs; substituir blockouts em lotes preservando IDs do catálogo e saves; depois preparar rigs e animações. Repetir spawn, captura, inventário e santuário para cada lote. Essa integração é separada das validações externas abaixo.

## Dois clientes: captura, trocas e leilões

**Ainda pendente de execução com clientes reais neste checkpoint.** Use Server & Clients com dois jogadores em memória antes dos testes persistentes.

1. Confira santuários separados, renda individual e efeitos replicados. Lance sobre a mesma criatura simultaneamente: somente um jogador pode consumir a orbe durante o Catch Lock.
2. Leve ambos ao nível 15 e à praça local. Convide, aceite, escolha UIDs e envie ofertas. As duas partes devem conferir nomes, variantes, renda e revisão da oferta.
3. Marque ambos prontos, tente confirmar antes dos três segundos e confira rejeição. Altere a oferta: as duas confirmações anteriores devem ser limpas. Confirme a mesma revisão e confira UIDs transferidos uma única vez e remoção dos slots antigos.
4. Teste inventário cheio, UID inexistente/duplicado, oferta antiga, cancelamento, saída da praça e desconexão durante as fases. Durante revisão/commit, outras mutações devem respeitar a trava.
5. Crie um leilão e confira remoção/escrow da criatura e reserva de espaço. Dê lance com o segundo cliente; confira débito, aumento do próprio lance somente pela diferença, relógio de 120 segundos e limite de lotes.
6. Com mais um cliente, supere o lance e confira restituição. No término, confira entrega única e conservação do saldo total transferido. Cancele lote sem lance e teste saída do vendedor/maior ofertante com restituição.
7. Reentre com pendências duráveis e confira recuperação idempotente conforme [Economia e trocas](ECONOMIA_E_TROCAS.md). Nenhum cliente pode fornecer seus próprios benefícios ou atributos confiáveis de criatura.

## Persistência real, produtos e implantação

**Ainda pendentes; não confundir com SaveNow válido em StudioMemory.** Use experiência separada de teste e DataStore exclusivo, conforme [Ambiente e dois PCs](AMBIENTE_E_DOIS_PCS.md).

1. Migre um save schema 1 existente para schema 2 sem perder moedas, UIDs, inventário ou progresso. Saves inválidos/versões futuras devem ser recusados sem substituição por padrões.
2. Capture/equipe, aguarde autosave, saia/reentre e confira estoque, XP, slots, claims e renda offline limitada a oito horas. Teste expiração de poção durante o período offline.
3. Teste indisponibilidade de API, lease concorrente, reentrada rápida, encerramento de servidor e falha depois de uma decisão de transação. Recibos/journals não podem ser apagados por autosave antigo.
4. Somente depois de configurar produtos reais com autorização, valide recibos repetidos, entrega, inventário no limite, falha de escrita e benefícios verificados no servidor. Não habilite vendas apenas para remover o estado de indisponibilidade da UI.
5. Configure o place secundário e valide transporte/retorno e requisitos. A praça local e os leilões atuais são da sala; não comprovam comércio global.
6. Confira limites de jogadores e dispositivos físicos antes de publicar. Publicação Roblox não foi executada nesta sessão.

Registre no README os testes realmente executados, com ambiente, resultado e limitações. Preserve esta separação ao continuar em outro computador.
