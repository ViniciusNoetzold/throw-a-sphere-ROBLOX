# Conexão MCP do Roblox Studio

O servidor oficial foi registrado no Codex deste PC como `Roblox_Studio`. Essa configuração é local: no outro PC ela precisa ser registrada novamente.

No Windows, com o Roblox Studio instalado:

```powershell
codex mcp add Roblox_Studio -- cmd.exe /c 'cd /d %LOCALAPPDATA%\Roblox && .\mcp.bat'
```

No Studio, abra o place do projeto e acesse **Assistant → … → Manage MCP Servers → Enable Studio as MCP server**. A barra inferior indica **MCP Ready**; o painel mostra a quantidade de clientes conectados. Reinicie o cliente Codex se as ferramentas ainda não aparecerem. Consulte a [documentação oficial do MCP Roblox](https://create.roblox.com/docs/studio/mcp).

Se houver vários Studios, use `list_roblox_studios` e selecione o `studio_id` cujo arquivo é `ThrowASphere.rbxlx`. O teste deste projeto usou um arquivo local, sem publicar uma experiência e sem acessar compras ou produtos.

## Validação observada em 18/11/2026

- Play iniciado pelo MCP; mapa, seis criaturas, santuários e HUD carregados.
- Estado inicial confirmado via `StateUpdate`: nível 1, $150, 25 orbes e `StudioMemory`.
- Sproutling capturado por requisição real do cliente: crítico, probabilidade 1, três balançadas, +25 XP e $8/s.
- Compra de uma orbe comum: −$25/+1 orbe; treino: +1 força/+5 moedas.
- Mouse simulado pelo MCP: 19 peças de mira visíveis, cor dourada de crítico; ao soltar, consumo de uma orbe e captura de Pyrokit Dourado, com $24/s.
- Quatro capturas no total: nível 2 com 15 XP, quatro slots ocupados e $54/s. A renda inclui três Sproutling com bônus de Planta +25% e o Pyrokit Dourado.
- Uma [imagem da execução](evidencias/passo1-studio.png) está versionada.

O Play usa dados em memória. Esses testes não demonstram persistência em servidores publicados, comportamento em dois clientes nem funcionamento em dispositivos reais. Continue pelo [roteiro de testes](TESTE_NO_STUDIO.md).
