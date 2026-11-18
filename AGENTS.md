# Continuidade do projeto

- A fonte executável é `src/`, mapeada pelo `default.project.json`. Preserve a pesquisa e os prompts originais.
- Siga a ordem solicitada: base funcional, UI, orbes/estruturas, criaturas por lotes. Não marque etapas futuras como prontas por terem catálogo ou prompt.
- Ao concluir e publicar qualquer etapa, atualize o checkpoint do `README.md` com data/hora de Brasília, entrega, validações, pendências e próximo trabalho. O usuário alterna entre dois PCs.
- Use Luau `--!strict`, lógica autoritativa no servidor, validação de remotes e salvamento que preserve dados existentes quando o carregamento falhar.
- Execute `scripts/Test.ps1` ou os comandos equivalentes antes de publicar. Diferencie compilação, testes com mocks, Play no Studio e DataStore publicado.
- Não inclua credenciais, `.tools/`, logs ou arquivos temporários. Não use push forçado para resolver divergências entre computadores.
- Não publique uma experiência Roblox nem configure produtos pagos sem uma solicitação que autorize essa operação.
