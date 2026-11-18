# Ambiente e continuidade entre dois PCs

## Primeiro acesso no outro PC (Windows x64)

Instale Git, Python 3 e Roblox Studio. Clone o projeto em uma pasta de trabalho:

```powershell
git clone https://github.com/ViniciusNoetzold/throw-a-sphere-ROBLOX.git
cd throw-a-sphere-ROBLOX
powershell -ExecutionPolicy Bypass -File scripts/Install-Tools.ps1 -InstallStudioPlugin
powershell -ExecutionPolicy Bypass -File scripts/Test.ps1
```

O instalador baixa versões oficiais fixas de Rojo 7.7.0 e Luau 0.747, verifica SHA-256 e guarda os executáveis em `.tools/`. Não exige Node, npm, banco externo ou chaves de API. O parâmetro `-InstallStudioPlugin` instala o plugin local do Rojo; reinicie o Studio se ele estava aberto. Referência: [instalação oficial Rojo](https://rojo.space/docs/v7/getting-started/installation/).

O commit [`112c87f`](https://github.com/ViniciusNoetzold/throw-a-sphere-ROBLOX/commit/112c87f) já publicou a pasta completa, com 123 arquivos e as 44 imagens da pesquisa. O checkpoint registra compilação Luau e build Rojo aprovados, além de **51 cenários do servidor aprovados**: 26 de captura, 6 de spawn/bloqueio e 19 de dados/santuário/progressão. As pendências de validação integrada ficam no `README.md`.

## Abrir o jogo

O repositório também inclui `game/ThrowASphere.rbxlx`: abra esse arquivo diretamente para jogar sem instalar a ferramenta de build. Para editar o código, use o fluxo abaixo; o build regenera tanto `build/` quanto a cópia versionada em `game/`.

1. Execute `powershell -ExecutionPolicy Bypass -File scripts/Build.ps1`.
2. No Roblox Studio use **File → Open from File** e abra `build/ThrowASphere.rbxlx`.
3. Aperte **Play**. O servidor cria o chão, o spawn, as criaturas provisórias e os seis santuários.
4. Segure o botão esquerdo sobre uma criatura, observe a mira e solte. No celular, segure e solte um toque fora dos controles. No controle, use R2 com a mira central.
5. As capturas ocupam os primeiros slots livres do santuário e geram moedas. Use o painel para comprar orbes, equipar, treinar e gerenciar as criaturas.

Para editar em tempo real execute `scripts/Serve.ps1`, abra o plugin Rojo no Studio e conecte em `localhost:34872`. O servidor de desenvolvimento fica restrito ao computador local. O código em `src/` é a fonte de verdade: alterações apenas dentro do Studio não voltam automaticamente para os arquivos Git.

## Salvamento

O padrão `StudioPersistence = false` em `src/shared/Config.luau` permite testar sem publicar uma experiência. O HUD mostra **TESTE LOCAL · dados não são salvos**. Parar o Play limpa essa sessão.

Em um servidor publicado, o DataStore fica ativo automaticamente. Para validar persistência no Studio, publique uma **experiência separada de teste**, habilite **Experience Settings → Security → Enable Studio Access to API Services**, escolha um `DataStoreName` exclusivo de teste e então altere `StudioPersistence` para `true`. Volte ao padrão antes de trabalhar em outro ambiente. O Studio pode acessar os mesmos dados do jogo publicado; esse comportamento está documentado no [guia oficial de DataStores](https://create.roblox.com/docs/cloud-services/data-stores).

O servidor salva periodicamente, ao sair e no encerramento, usa `UpdateAsync` e uma trava por sessão. Uma falha ao carregar não cria um perfil padrão sobre o save existente. A renda offline considera até oito horas das criaturas equipadas. Isso ainda precisa de teste integrado em uma experiência publicada.

Configure o máximo de jogadores do place como **6** no Creator Hub antes de publicar. Essa configuração de servidor não é aplicada pelo arquivo Rojo. Servidores VIP, vaga social, Trading Plaza, compras Robux e IDs de assets ainda não estão configurados nesta etapa.

## Trocar de computador

Antes de começar:

```powershell
git status
git pull --ff-only
```

Ao terminar uma etapa:

1. Execute `scripts/Test.ps1`.
2. Atualize o checkpoint no `README.md`: etapa, entrega, validações, limitações e próximo trabalho.
3. Execute:

```powershell
git add .
git commit -m "feat: descreva a etapa concluída"
git push origin main
git status --short --branch
```

Só considere o trabalho sincronizado após confirmar o push. Não use `push --force` nem descarte alterações do outro computador. Se `git pull --ff-only` recusar, compare as branches e resolva o conflito antes de continuar.

Neste PC, o `git push` foi validado em 18/11/2026 usando a sessão já salva no **Git Credential Manager**. A configuração local deste repositório seleciona esse gerenciador; o uso normal de `git push origin main` não depende de renovar o token do `gh`.

O `gh auth status` ainda indica um token inválido para a CLI GitHub. Execute `gh auth login -h github.com` apenas se precisar usar comandos `gh`. Esse estado é separado da autenticação do Git Credential Manager que já permitiu publicar o projeto.

A configuração local do Git e as sessões de autenticação não são sincronizadas pelo repositório. No outro PC, use o Git Credential Manager instalado com o Git e autentique sua conta quando solicitado. Nenhum token ou outra credencial foi gravado no projeto.

