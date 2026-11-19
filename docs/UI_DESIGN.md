# Direção visual da interface — passo 2

O usuário enviou cinco referências nesta sessão e pediu um refinamento incremental do HUD, dos menus do hub e da loja. As referências orientam o estilo; suas marcas d'água, textos promocionais e imagens não fazem parte do jogo.

## Elementos do estilo

- Medalhões circulares com anel colorido, núcleo escuro e reflexos claros para ícones de coleção, força, orbes e ações.
- Botões arredondados com relevo, sombra inferior, borda escura, brilho superior e gradientes vivos. Verde/ciano, amarelo/laranja e rosa/roxo separam ações e categorias.
- Detalhes discretos de studs e facetas, inspirados nas barras e tiles enviados, preservando contraste para textos.
- Loja com moldura decorativa inspirada em pedra e cristais, cabeçalhos coloridos e cards de catálogo com preços legíveis.
- `FredokaOne` em títulos e números; `GothamBold` nos detalhes. Textos principais usam contorno escuro.

## Implementação e uso

Os componentes são gerados com elementos nativos de GUI do Roblox. O projeto não depende de IDs externos de imagens para renderizar os ícones e acabamentos. `HUDWidgets` concentra os componentes e `HUDIcons` os pictogramas; as views preservam os remotes autoritativos do passo 1.

Decorações não devem capturar input. Padrões de studs precisam ter quantidade limitada; listas usam rolagem e atualizações preservam sua posição. Os botões principais compactos têm aproximadamente 44 pixels de altura. A interface mantém `CoreUISafeInsets` e a orientação `LandscapeSensor` do projeto.

As três abas da loja continuam sendo um catálogo em preparação. Não adicionar descontos, urgência, contadores de oferta, eventos ou recompensas fictícias a partir dos exemplos visuais. Os preços efetivos e a entrega dos produtos dependem da integração futura descrita em [Monetização](MONETIZACAO.md).

Os modelos 3D finais serão produzidos e enviados pelo usuário. Este refinamento não substitui os modelos provisórios do mundo nem inicia rigging ou animações de criaturas.
