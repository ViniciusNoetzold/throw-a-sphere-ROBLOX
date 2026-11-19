# Verificação do arremesso e da academia — 19/11/2026

Skills usadas como referência: `el4cteo-roblox-game-systems`, `el4cteo-roblox-networking`, `el4cteo-roblox-physics`, `el4cteo-roblox-characters-animation` e `el4cteo-roblox-studio-mcp`. Não houve alteração no inventário das skills nem execução de hooks ou telemetria upstream.

## Testes automáticos

- Compilação Luau das fontes e build Rojo: aprovados.
- Integridade: 155 skills, 888 arquivos e nove fontes fixadas, aprovada.
- Suites existentes de matemática, dados, captura, progressão, comércio, monetização e mundo: aprovadas.
- `FlightService`: 23 cenários de ciclo de vida e segurança, além de verificações de timing, distância e desbloqueio de biomas.
- `TrainingService`: 18 cenários de XP, níveis, bônus, repetição de requisições, posição, pausa, morte, respawn e saída.
- Suite de dados ampliada para verificar campos da academia na migração e no save/load e rejeitar nível zero e XP negativo sem sobrescrever o save.

## Play local no Roblox Studio pelo MCP

Verificações executadas com perfil `StudioMemory`, sem experiência publicada:

- A academia iniciou na barra do próprio santuário, ancorou o personagem e exibiu sua interface.
- Repetições aumentaram força, XP da academia e XP do jogador; a barra e o texto acompanharam a subida de nível.
- Entradas reais de teclado E confirmaram dois desafios de 2× observados pelo evento de resposta do servidor.
- O clique real em PARAR TREINO escondeu a interface, removeu a âncora e restaurou WalkSpeed 16.
- Na linha amarela, a barra apareceu automaticamente com vermelho nas pontas e verde no centro.
- Um clique real fora do painel iniciou o voo, com câmera Scriptable. Após o resultado, a câmera voltou a Custom e os objetos de efeito e revelação foram limpos.
- A preparação fora da linha foi rejeitada. Ao posicionar o personagem dentro da pista para testar a proteção, o servidor o devolveu à entrada.
- As três performances procedurais produziram transformações diferentes do ombro em um avatar com AnimationConstraint, usando forças 0,10, 0,55 e 0,95.
- A primeira sessão de voo conferiu a revelação comum/incomum e a restauração dos controles. A apresentação secreta teve inspeção parcial de silhueta; não foi validada como drop secreto real.

O console da sessão íntegra não apresentou erro dos scripts do projeto; houve avisos de asset preexistente `203785492`, sem referência nas fontes novas. Os testes locais não validam permissões de assets em produção.

## Incidente na sincronização do Studio

Uma leitura agregada de fontes foi truncada pelo transporte da ferramenta. Essa cópia afetou um módulo em uma das janelas de edição. A revisão automática bloqueou a substituição que continha o trecho truncado. Os arquivos em `src/` e o build Rojo permaneceram íntegros. O Play aprovado foi executado na outra sessão, sincronizada com blocos menores e fontes completas. Não salvar a janela antiga por cima do build; reabrir `game/ThrowASphere.rbxlx` para continuar a partir da fonte versionada.

## Pendências reais

- Equipamentos da academia, modelos finais das criaturas/orbes e clipes finais de animação serão fornecidos pelo usuário.
- Todos os valores da academia e do novo voo são provisórios para testes; ainda falta balanceamento.
- Toque físico, controle físico, multiplayer, latência e DataStore de uma experiência publicada ainda precisam de validação.
- O antigo combate direcionado de chefe precisa ser adaptado ao novo ciclo. O remote legado foi bloqueado quando FlightService está ativo para preservar a exigência de lançar somente pela linha.
- Não houve publicação de experiência Roblox, cadastro de produtos ou alteração de preços pagos.
