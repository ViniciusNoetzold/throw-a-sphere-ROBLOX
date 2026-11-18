# Roteiro de validação integrada do passo 1

Use uma sessão em memória primeiro. Este roteiro documenta o que precisa ser observado; a existência deste arquivo não significa que todos os testes reais já passaram.

## Play local

1. Gere o place com `scripts/Build.ps1`, abra `build/ThrowASphere.rbxlx` e dê Play.
2. Confira o Output do servidor e do cliente: sem erros de carregamento de módulos, propriedades ou remotes.
3. Confira chão xadrez, spawn, seis criaturas nomeadas e seis santuários. O HUD deve mostrar nível 1, $150, 25 orbes comuns e modo de teste local.
4. Mire no corpo e na cabeça de uma criatura: arco verde e dourado, respectivamente. Distancie-se até ficar vermelho.
5. Lance e confira um único consumo de orbe, voo e até três balançadas. Uma falha deve retornar a criatura visível e conceder XP/pity; sucesso deve adicioná-la ao inventário/santuário e removê-la do mundo depois da animação.
6. Aguarde a reposição da criatura. Tente lançar durante o cooldown e observe a recusa sem novo consumo.
7. Após capturar, confira moedas subindo por segundo. Desequipe a criatura e observe a renda cair; reequipe e confira o retorno.
8. Compre/equipe uma orbe; confira o preço e o estoque. A Mestre não pode ser comprada por moedas.
9. Treine e confira força, alcance e +5 moedas. Suba de nível e confira a barra, o alcance e a recompensa.
10. Teste respawn do avatar: HUD continua, referências da câmera e mira permanecem válidas.

## Dois clientes

Use o modo de teste de servidor com dois jogadores. Confirme santuários separados, renda individual e animações replicadas. Lance sobre a mesma criatura simultaneamente: somente um jogador deve consumir orbe enquanto a criatura estiver bloqueada. Desconecte e reconecte um cliente e confira a liberação do santuário.

## Dispositivos

No emulador móvel, teste segurar/soltar fora dos controles, tocar nos botões sem lançar, redimensionar a janela e abrir o inventário. Em controle, teste a mira central com R2. Câmera, controles de movimento e notificações precisam continuar utilizáveis.

## Persistência real

Use uma experiência publicada de teste e um DataStore exclusivo. Ative o modo persistente conforme [guia de ambiente](AMBIENTE_E_DOIS_PCS.md). Capture/equipe, aguarde autosave, saia, entre novamente e confira saldo, XP, estoque, inventário, slots e renda offline. Teste indisponibilidade de API e reentrada rápida; o servidor deve recusar uma carga insegura em vez de criar um save novo.

Registre no README quais destas verificações realmente foram executadas e o resultado observado.
