# Continuidade do projeto

- A fonte executável é `src/`, mapeada pelo `default.project.json`. Preserve a pesquisa e os prompts originais.
- Siga a ordem solicitada: base funcional, UI, orbes/estruturas, criaturas por lotes. Não marque etapas futuras como prontas por terem catálogo ou prompt.
- Ao concluir e publicar qualquer etapa, atualize o checkpoint do `README.md` com data/hora de Brasília, entrega, validações, pendências e próximo trabalho. O usuário alterna entre dois PCs.
- Use Luau `--!strict`, lógica autoritativa no servidor, validação de remotes e salvamento que preserve dados existentes quando o carregamento falhar.
- Execute `scripts/Test.ps1` ou os comandos equivalentes antes de publicar. Diferencie compilação, testes com mocks, Play no Studio e DataStore publicado.
- Não inclua credenciais, `.tools/`, logs ou arquivos temporários. Não use push forçado para resolver divergências entre computadores.
- Não publique uma experiência Roblox nem configure produtos pagos sem uma solicitação que autorize essa operação.

## Skills locais

- Consulte `docs/SKILLS.md` e `docs/SKILLS_CATALOGO.md` para escolher skills instaladas em `.agents/skills/`. Carregue somente as pertinentes à tarefa.
- Preserve originais e licenças em `vendor/skill-sources/` e a procedência em `skills.lock.json`. Não use templates de configuração upstream para substituir a configuração Roblox deste projeto.
- Os perfis de agentes e scripts vendorizados são material de apoio; não são serviços ativos. A instalação não autoriza executar hooks, telemetria, publicações ou alterações externas.
- Guarde relatórios de skills no projeto (`docs/reviews/`), para acompanhar o Git entre os PCs. Após alterar as cópias instaladas ou seu inventário, execute `python scripts/Verify-Skills.py` e atualize os hashes e a documentação.
