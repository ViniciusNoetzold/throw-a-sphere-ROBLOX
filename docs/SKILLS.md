# Skills de IA do projeto

Verificado em **19/11/2026**, horário de Brasília. Foram instaladas **155 skills** locais em `.agents/skills/`. As cópias acompanham o Git: no outro PC basta atualizar o repositório. Estar instalado não significa que um workflow foi executado ou que um relatório foi produzido.

## Pacotes e origens

| Origem | Skills ativas | Conteúdo preservado |
| --- | ---: | --- |
| [Donchitos/Claude-Code-Game-Studios](https://github.com/Donchitos/Claude-Code-Game-Studios) | 78 | Suíte de produção, design, balanceamento e QA; 49 perfis de agentes e arquivos de apoio preservados no vendor |
| [gamedev-skills/awesome-gamedev-agent-skills](https://github.com/gamedev-skills/awesome-gamedev-agent-skills) | 8 | Família Roblox completa, incluindo simulator economy; demais disciplinas no vendor |
| [scenario-labs/skills](https://github.com/scenario-labs/skills) | 14 | Família Roblox completa, incluindo expert, animação, dados, UI, assets, arquitetura e ferramentas compartilhadas |
| [EL4CTEO/roblox-skills](https://github.com/EL4CTEO/roblox-skills) | 23 | Pacote Roblox completo |
| [fagemx/gstack-game](https://github.com/fagemx/gstack-game) | 29 | Produção, revisão de economia, game feel, design e QA |
| [danicat/skills](https://github.com/danicat/skills) | 1 | Game design |
| [emilkowalski/skills](https://github.com/emilkowalski/skills) | 1 | Review animations, fonte original identificada para a referência OpenDesign |
| [agent-skills-hub/agent-skills-hub](https://github.com/agent-skills-hub/agent-skills-hub) | 1 | Game design; família de desenvolvimento de jogos preservada no vendor |
| [n4tivex/mcp-roblox-docs](https://github.com/n4tivex/mcp-roblox-docs) | 0 | Código-fonte de um servidor MCP, guardado como ferramenta opcional; não é pacote SKILL.md |

As contagens de estrelas do texto original não foram usadas como prova de qualidade ou compatibilidade. O catálogo real foi verificado no GitHub. O endereço `open-design/skills` respondeu 404; a skill `review-animations` foi localizada pela referência [OpenDesign](https://github.com/nexu-io/open-design/tree/main/skills/review-animations) e instalada da fonte original com licença MIT. A menção genérica a agent-skills-hub foi resolvida para a organização e o repositório vinculados acima.

## Uso no Codex

As skills ficam disponíveis para descoberta a partir do próximo turno; se um cliente ainda não as listar, reabra o projeto ou inicie uma nova sessão. Não é necessário instalar globalmente em cada PC. Um agente também pode consultar o arquivo `SKILL.md` pelo caminho do [catálogo completo](SKILLS_CATALOGO.md).

Exemplos de pedidos:

- “Use `scenario-roblox-animation` para revisar os rigs das criaturas.”
- “Use `el4cteo-roblox-security` para revisar a validação dos remotes de troca.”
- “Use `gamedev-roblox-datastores` para revisar carregamento e salvamento.”
- “Use `gstack-balance-review` para avaliar XP, preços, mutações e rebirth.”
- “Use `gstack-feel-pass` para avaliar a mira e as três balançadas com o jogo aberto.”
- “Use `emil-review-animations` como referência de motion; adapte critérios de CSS ao TweenService quando fizer sentido.”

Escolha a família que corresponde à tarefa e carregue apenas as instruções necessárias. Os critérios web da skill de animação não são regras da engine Roblox. Para detalhes de APIs, confira a documentação oficial e a versão do Studio.

## Compatibilidade e arquivos de apoio

- `skills.lock.json` registra repositório, commit, caminho original, adaptações e SHA-256 de todos os arquivos das skills instaladas.
- `vendor/skill-sources/` guarda originais, licenças e dependências. Não foi copiada uma configuração de hooks para a raiz do projeto.
- Nomes Donchitos, gamedev, EL4CTEO, gstack, danicat, Emil e hub receberam prefixos para evitar colisões. Scenario já utiliza seu próprio prefixo.
- As cópias Donchitos removem a injeção dinâmica de shell do Claude e a seleção de modelo; os caminhos de apoio apontam ao vendor. Os perfis de agentes são referências; a instalação não cria nem executa agentes.
- As cópias gstack removem o preâmbulo de Bash/Bun que criava estado e métricas na pasta pessoal. Relatórios compartilhados devem ficar em `docs/reviews/gstack/`, sob controle do Git.
- Os workflows originais podem depender de Claude Code, Bash, Bun, ferramentas opcionais, configurações ou evidências próprias. Não foram executados builds, instaladores, scripts ou hooks dos fornecedores. A instalação dos documentos não equivale à configuração desses ambientes.
- A família Scenario contém seus scripts e AgentKit, incluindo dependências entre especialistas e `scenario-roblox-expert`. O conteúdo upstream foi verificado pelo autor em macOS; validar adaptações Windows antes de executar esses scripts aqui.
- Instruções do usuário, regras deste projeto e permissões do ambiente continuam prevalecendo. A instalação não autoriza mensagens, telemetria, publicação Roblox, compras ou outras ações externas.

Para conferir a integridade local:

```powershell
python scripts/Verify-Skills.py
```

Atualizações futuras devem usar commits explícitos, preservar as licenças, renovar os hashes e registrar as adaptações. Não rode um atualizador genérico sobre essas cópias sem revisar a mudança.

## MCP oficial do Roblox

O conector `Roblox_Studio` está registrado nesta sessão. A consulta a `list_roblox_studios` retornou uma lista vazia durante esta instalação, portanto nenhum teste de geração, animação ou importação no Studio foi executado agora. O ambiente anuncia as 13 skills oficiais abaixo; elas são carregadas pelo MCP e não precisam ser duplicadas no Git:

`rbx-import-asset`, `rbx-open-cloud-usage`, `rbx-device-simulator-lua`, `rbx-configs-experimentation`, `rbx-instrument-analytics`, `rbx-network-simulator`, `rbx-perf-profiling`, `rbx-scene-analysis`, `rbx-debug`, `rbx-unit-test`, `rbx-docs-search`, `rbx-permissions`, `rbx-create-skill`.

Abra o arquivo do jogo no Studio e habilite o servidor MCP para consultar a disponibilidade real naquele Studio. Consulte [MCP_ROBLOX_STUDIO.md](MCP_ROBLOX_STUDIO.md).

## MCP adicional de documentação

O código está em `vendor/skill-sources/n4tivex--mcp-roblox-docs/`, fixado por commit. Ele não foi registrado como outro servidor nem foram instaladas dependências Python nesta etapa. O README e o pyproject upstream declaram MIT; o repositório verificado não fornece arquivo LICENSE separado.

Se esse MCP adicional for necessário, o projeto upstream descreve execução por `uv`/`uvx`. Para reproduzir a versão vendorizada, use `uv --directory vendor/skill-sources/n4tivex--mcp-roblox-docs run mcp-roblox-docs` a partir da raiz, após revisar e preparar as dependências. O MCP oficial já oferece busca documental. A configuração e autenticação dos conectores são locais de cada computador.
