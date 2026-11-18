# Pesquisa Completa: Análise Detalhada de 4 Jogos Incrementais do Roblox

Esta pasta reúne a pesquisa completa, capturas reais de gameplay, imagens promocionais oficiais, análises de texturas e modelagem 3D, diagramas, texturas prontas e scripts de exemplo referentes aos quatro jogos do Roblox analisados:

1. **Throw a Seed** (*Lançar uma semente*) — `129081220403721`
2. **Steal An Egg** (*Roube um ovo*) — `107778070777162`
3. **Throw Food For Animals** (*Lançar comida para animais*) — `120219252362013`
4. **+1 Ride Pets to Fight** (*+1 animal de estimação para lutar*) — `127231827405683`

> 💡 **Dica de Leitura:**
> - Abra o arquivo **`PAINEL_VISUAL_INTERATIVO.html`** com duplo clique no seu navegador para visualizar toda a pesquisa com galerias de imagens lado a lado.
> - Leia **`GUIA_TEXTURAS_MODELAGEM_E_ANIMACOES.md`** para o mergulho técnico nas texturas reais (*Square Studs*, *Inlets*, piso xadrez), construção de modelos 3D, shaders de mutação e código Luau/Blender.

---

## 1. Tabela Comparativa Geral (Dados Oficiais Observados)

| Atributo | 🌱 Throw a Seed | 🥚 Steal An Egg | 🍖 Throw Food For Animals | 🐉 +1 Ride Pets to Fight |
| :--- | :--- | :--- | :--- | :--- |
| **Título PT-BR no Roblox** | Lançar uma semente | Roube um ovo | Lançar comida para animais | +1 animal de estimação para lutar |
| **Place ID** | `129081220403721` | `107778070777162` | `120219252362013` | `127231827405683` |
| **Estúdio / Grupo** | Fish Time Studios | and Collect Rare Pets ✓ | Goofy Chupacabra | Hatch to Fight |
| **Gênero / Subgênero** | Simulation / Incremental Simulator | Simulation / Tycoon | Simulation / Tycoon | Simulation / Incremental Simulator |
| **Jogadores Ativos** | 13.191 | 701.831 | 275.596 | 1.235 |
| **Visitas Totais** | 4,8M+ | 11,4B+ | 319,1M+ | 4,0M+ |
| **Favoritos** | 8.398 | 10.047.833 | 313.684 | 207.778 |
| **Likes / Dislikes** | 5.781 / 275 (**95,46%**) | 4.242.499 / 403.652 (**91,31%**) | 169.723 / 10.497 (**94,18%**) | 93.759 / 816 (**99,14%**) |
| **Tamanho do Servidor** | 5 jogadores | 7 jogadores | 5 jogadores | 8 jogadores |
| **Atributo de Treino** | Força (Barras fixas / *Pull-ups*) | Velocidade (Esteiras / *Treadmills*) | Poder de Arremesso (Barras fixas) | Poder `+1` e Nível do Pet |
| **Ação Principal** | Arremessar semente com timing no cânion | Invadir biomas, roubar ovos e fugir | Arremessar comida na pista para animais | Montar no pet e enfrentar ondas/chefes |
| **Economia / Renda** | Plantas no Jardim (`$/s` + offline) | Pets nos Cercados (`$/s` + fusão) | Animais na Base (`$/s` + offline) | Moedas, chaves, caixas e *Rebirth* |
| **Pasta de Imagens** | `01_Throw_a_Seed/` | `02_Steal_An_Egg/` | `03_Throw_Food_For_Animals/` | `04_Ride_Pets_to_Fight/` |

---

## 2. Análise Individual Detalhada

### 🌱 Jogo 1: Throw a Seed (*Lançar uma semente*)
* **URL:** https://www.roblox.com/pt/games/129081220403721/Throw-a-Seed
* **Grupo:** Fish Time Studios (`115196901`)

#### Como Funciona (Loop Principal)
1. **Treinamento na Barra (*Pull-Ups*):** O jogador interage com barras fixas para acumular Força. Você evolui o equipamento desde a **Wood Bar** (Barra de Madeira) até a **Diamond Bar** (Barra de Diamante) para multiplicar o ganho de força e aumentar o alcance máximo do arremesso.
2. **Arremesso com Timing:** Na linha amarela de lançamento do cânion, uma barra de precisão/força oscila. Clicar/tocar no ponto ideal (*sweet spot*) maximiza a distância de voo da semente.
3. **Travessia de 15 Zonas e Multiplicador de Sorte:** O cânion é dividido em **15 zonas sequenciais** (começando no **Meadow / Prado** — passando por *Autumn Woods*, *Tropical Beach*, deserto, vulcão e áreas cristalinas noturnas — até o **Starlight Glade / Bosque de Luz Estelar**). Cada zona atravessada no ar aumenta o multiplicador de **Sorte (*Luck*)** daquele arremesso.
4. **Germinação, Raridades e Mutações:** Quando a semente pousa, uma planta adulta brota instantaneamente do solo. Existem **mais de 75 plantas** (expandidas em atualizações) divididas em **10 raridades** (*Common, Uncommon, Rare, Epic, Legendary, Mythic, Divine, Transcendent, Unique* e *Secret*). Elas também podem surgir em **tamanhos enormes** (*Big, Huge, Titanic*) e **mutações** (*Gold, Diamond, Candy, Fire, Radioactive*).
5. **Economia de Jardim (Offline Cash) e Sementes:** Você planta suas descobertas no seu lote de jardim (`Plant your Golden Apple Tree`, botões `AUTO` e `STORE`) e elas geram dinheiro por segundo (`$/s`) continuamente — inclusive **enquanto o jogador está offline**. Sementes melhores (*Rainbow Seed*, *Enchanted Seeds*) aumentam a sorte base.
6. **Códigos Conhecidos:** `RELEASE`, `HYPE`, `UPDATE`, `1KFAVORITES`, `TIKTOK`, `CANDY`.

#### Gráficos, Animações e Imagens Reais Coletadas
* **Gráficos reais (in-game):** Terreno verde quadriculado em dois tons com textura clássica de **Square Studs**, paredes do cânion em marrom quadriculado, cercas de madeira no jardim e árvores feitas de blocos geométricos (*Pinheiros com camadas de WedgeParts e base branca com Inlets*, *Golden Apple Tree*, *Orange Tree*, *Grape Vine*, *Baobab*). Árvores raras emitem **pilares verticais de luz dourada** e exibem `BillboardGuis` flutuantes (`Fiona's Garden $23.9K/s`, `Baobab $525/s`, `Orange Tree $21/s`).
* **Animações:** Movimento repetitivo de barra fixa; animação de lançamento de braço com rastro branco/amarelo da semente; câmera que acompanha o voo da semente pelo cânion (inclusive no bioma noturno de cristais azuis/roxos); brotamento elástico da árvore ao pousar; pré-visualização transparente verde antes de posicionar a árvore no jardim (`Click where it goes | R rotate | Q store`).
* **Arquivos na pasta `01_Throw_a_Seed/`:**
  * `01_gameplay_real_plantando_golden_apple_tree.png` — Captura real dentro do jogo plantando uma *Golden Apple Tree*, mostrando HUD (`Index`, `Shop`, `Plants`, `259M`, `2.4T`), botões `AUTO`/`STORE` e pinheiro ao fundo.
  * `02_gameplay_real_jardim_fiona_e_plantas.png` — Visão aérea real dos jardins dos jogadores com cercas, barracas de loja e pilares de luz dourada.
  * `03_gameplay_real_canion_noturno_cristais.png` — Captura real do cânion noturno com cristais luminosos e arco de pedra com studs.
  * `04_promo_silhueta_misteriosa.png`, `05_promo_arremesso_canion_outono.png`, `06_promo_arvore_do_sol.png`, `07_promo_progressao_celestial_oak.png`, `pagina_completa_roblox.png`.

---

### 🥚 Jogo 2: Steal An Egg (*Roube um ovo*)
* **URL:** https://www.roblox.com/pt/games/107778070777162/Steal-An-Egg
* **Grupo:** and Collect Rare Pets (`825735094`) ✓

#### Como Funciona (Loop Principal)
1. **Treinamento de Velocidade em Esteiras (*Treadmills*):** O jogador treina na esteira da sua base para aumentar permanentemente o atributo **Velocidade (*Speed*)**. Carregar ovos pesados reduz a velocidade de fuga e os biomas avançados exigem estatísticas na casa dos milhões e bilhões.
2. **Infiltração em Biomas e Guardiões:** O mapa é uma longa trilha de biomas progressivos, cada qual protegido por um **Guardião Boss** que persegue invasores:
   1. **Forest** (Inicial — Guardião: *Chicken*)
   2. **Lake** (900 Speed — Guardião: *Swan*)
   3. **Desert** (10K Speed — Guardião: *Scorpion*)
   4. **Jungle** (40K Speed — Guardião: *Tiger*)
   5. **Snow** (170K Speed — Guardião: *Yeti*)
   6. **Volcano** (700K Speed — Guardião: *Cerberus*)
   7. **Abyss Ocean** (2.5M Speed — Guardião: *Moby*)
   8. **Prehistoric** (18M Speed — Guardião: *T-Rex*)
   9. **Cosmic** (700M Speed — Guardião: *Cosmic Skeleton*)
   10. **Cherry Blossom** (2.5B Speed — Guardião: *Oni Tiger* | desbloqueia a *Sakura Incubator* e evento *The Great Bloom*)
   11. **Titan Temple** (7B Speed — Guardião: *Gorilla King*)
   12. **Angels & Demons**
   13. **Enchanted Forest** (50B Speed — Guardião: *Enchanted Lion*)
3. **Roubo PvP e Armas do Índice:** Você pode roubar ovos tanto dos ninhos guardados quanto das mãos/bases de outros jogadores. Cada bioma padrão contém **8 pets no Pet Index**; completar `8/8` libera armas de combate com maior *knockback*: *Baseball Bat* → *Biome Bats (Tiers 1–9)* → *Katana* → *Titan Axe* → *Angelic Spear* → *Forest Club / Hammer* (além de itens de evento como *Racing Bat*, *Bee Gun* e *Technological Mine*).
4. **Incubação, Fusão, Pesos e Mutações:** As mutações são visíveis na casca do ovo antes do roubo:
   * **Silver:** `1.25x` | **Bloom:** `1.5x` | **Golden:** `2x` | **Rainbow:** `2.5x` | **Spirit Bloom / Sakura Bloom:** `3x` | Especiais (*Monstrous*, *Thunderous*).
   * Pets também possuem variação de **peso (kg)** até variantes *Huge* e podem ser combinados na **Fuse Machine / Secret Fuse Room**.

#### Gráficos, Animações e Imagens Coletadas
* **Gráficos:** Estilo 3D voxel/blocky de alto contraste com guardiões colossais de olhos brilhantes (*Yeti*, *Galaxy Dragon*, *T-Rex*, *Viper*), cascas de ovos estilizadas (cristais de gelo, escamas douradas, estrelas cósmicas) e efeitos de pétalas de sakura.
* **Animações:** Corrida acelerada na esteira com partículas e linhas de velocidade; pose de carregamento com os dois braços erguidos segurando o ovo gigante acima da cabeça (*Carry Pose*); estados animados dos guardiões (sono com `Z Z Z`, alerta `!!`, perseguição); golpes de taco/katana/martelo com física de *knockback/ragdoll* nos rivais.
* **Arquivos na pasta `02_Steal_An_Egg/`:**
  * `01_promo_fuga_cobra_vibora.png`
  * `02_promo_roubando_yeti_egg.png`
  * `03_promo_dragao_galactico_dormindo.png`
  * `04_promo_roubando_trex_egg.png`
  * `pagina_completa_roblox.png`

---

### 🍖 Jogo 3: Throw Food For Animals (*Lançar comida para animais*)
* **URL:** https://www.roblox.com/pt/games/120219252362013/Throw-Food-For-Animals
* **Grupo:** Goofy Chupacabra (`670988975`)

#### Como Funciona (Loop Principal)
1. **Treinamento em Stands de Barra Fixa:** Treinar nas barras fixas (*pull-up stands*) aumenta seu **Throw Power**, permitindo lançar alimentos cada vez mais longe na pista.
2. **Catálogo de 50 Comidas em 19 Tiers:** Comidas compradas na *Food Shop* são **permanentes e possuem arremessos ilimitados** (você não gasta unidades ao jogar). Exemplos de progressão:
   * *Tier 1:* Carrot (Grátis), Apple (\$30), Banana (\$150)
   * *Tier 2–4:* Toast (\$4K), Orange (\$20K), Pear (\$200K), Cheese (\$1M), Bread Loaf (\$12M), Watermelon (\$60M)
   * *Tier 5–8:* Croissant (\$650M), Chocolate (\$3.2B), Mushroom (\$30B), Bacon (\$150B), Burger (\$1.3T), Shank (\$6.8T), Fillet (\$57T), Steak (\$1.5Qa)
   * *Tier 9–19:* *Royal Steak, Golden Apple, Crystal Melon, Ember Bacon, Lava Steak, Elder Strawberry, Phoenix Fillet* até o item final Sovereign: **Black Sun Soufflé** (\$31Ocd).
3. **Pista com 17 Zonas / Biomas (5 até 6.200+ studs):**
   1. *Forest* | 2. *Savanna* | 3. *Desert* | 4. *Jungle* | 5. *Ocean* | 6. *Mountains* | 7. *Taiga* | 8. *Winter* | 9. *Prehistoric Forest* | 10. *Deep Waters* | 11. *Hell* | 12. *Ancient Ruins* | 13. *Mythical Paradise* | 14. *Shadow Realm* | 15. *Harvest Fields* | 16. *Phantom Harbor* | 17. *Nuclear Wasteland* (12 animais no último bioma; 8 na maioria dos demais).
4. **Mutações e Tamanhos:**
   * **Gold:** `1.5x` | **Diamond:** `3x` | **Emerald:** `5x` | **Ruby:** `10x` | **Rainbow:** `20x`.
   * Tamanhos variam de padrão e *Big* até variantes *Infinite*, multiplicando o lucro passivo (`$/s`) na base mesmo offline.

#### Gráficos, Animações e Imagens Reais Coletadas
* **Gráficos reais (in-game):** Visual praticamente idêntico ao de *Throw a Seed*: corredor longo com piso verde quadriculado em **Square Studs** muito nítidos, encostas marrons quadriculadas nas laterais, linhas brancas marcando as fronteiras de cada bioma com banner superior (`Desert 🌵`, `Taiga 🌲`) e vegetação em blocos geométricos simples com troncos inclinados.
* **Animações:** Movimento de arremesso da comida que gira no ar deixando um rastro branco/amarelo fino enquanto a câmera persegue o projétil pela pista; contador de raridade (`1 in 1`) no topo ao aterrissar; animação dos animais caminhando até a comida para comer e serem coletados.
* **Arquivos na pasta `03_Throw_Food_For_Animals/`:**
  * `01_gameplay_real_pista_bioma_desert.png` — Captura real do voo pelo corredor entrando no bioma *Desert 🌵*.
  * `02_gameplay_real_pista_bioma_taiga.png` — Captura real entrando no bioma *Taiga 🌲* mostrando a linha divisória branca e o rastro da carne girando no chão/ar.
  * `03_gameplay_real_close_terreno_studs_e_arvore.png` — Close real excelente para observar os *Square Studs* no gramado e a construção em blocos das árvores coloridas.
  * `04_gameplay_real_close_studs_e_blocos.png` — Segundo ângulo real em close dos blocos e studs no campo.
  * `05_promo_progressao_phoenix.png`, `06_promo_corredor_dragao.png`, `07_promo_silhueta_dragao_cenoura.png`, `08_promo_trex_bife.png`.

---

### 🐉 Jogo 4: +1 Ride Pets to Fight (*+1 animal de estimação para lutar*)
* **URL:** https://www.roblox.com/pt/games/127231827405683/1-Ride-Pets-to-Fight
* **Grupo:** Hatch to Fight (`614735275`)

#### Como Funciona (Loop Principal)
1. **Pet como Montaria + Arma:** Todo pet chocado funciona simultaneamente como seu **veículo de locomoção/montaria** e sua **arma de combate** (`[E] TO FIGHT`). São **mais de 165 pets** colecionáveis.
2. **Chocar, Forjar e Evoluir Níveis:** Você abre ovos e utiliza **The Forge** (Forja) para fundir/melhorar pets. Os pets sobem de nível ganhando poder (`+1`), mudando de porte e aparência em marcos evolutivos (ex.: `LEVEL 1` filhote → `LEVEL 10` dragão médio → `LEVEL 100` dragão colossal com armadura e lanternas).
3. **Combate em 60+ Estágios e Mundos:** Você cavalga pelo mapa enfrentando ondas de monstros e chefes de fim de estágio ao longo de **60+ estágios** e múltiplos mundos (como o *Mundo 2: Mundo do Oceano*).
4. **Sistemas de Meta-Progressão:**
   * **Rebirth:** Reinicia parte do progresso em troca de multiplicadores permanentes de dano e treino.
   * **Races (Raças):** Roda bônus passivos para o jogador via *Race Rerolls*.
   * **Trails & Crates:** Chaves abrem caixas com trilhas luminosas de velocidade e dano.
   * **Códigos Conhecidos:** `HALLOWEEN`, `8KCCU`, `1KCCU`, `LAUNCH`, `LUCKY`, `INFERNO`, `TRAILS`, `POWERUP`, `COINRUSH`, `HATCHER`, `RACES`.

#### Gráficos, Animações e Imagens Coletadas
* **Gráficos:** Mantém o chão de blocos com *studs* e construções voxel, mas eleva o nível de detalhamento das criaturas para um estilo **Voxel Anime/Fantasia** (raposas de nove caudas estilo *Kitsune/Kurama*, wyverns dourados de lava, dragões orientais com bigodes brancos e auras ciano/roxo neon).
* **Animações:** Acoplamento de montaria (*Mount Seat / Motor6D*) onde o avatar se inclina no dorso/pescoço da fera durante galope ou voo; animações de golpe e ataque da própria criatura; pop-ups flutuantes de `+1` com contorno preto espesso.
* **Arquivos na pasta `04_Ride_Pets_to_Fight/`:**
  * `01_promo_wyvern_dourado_lava.png`
  * `02_promo_raposa_nove_caudas_laranja.png`
  * `03_promo_fera_listrada_aura_roxa.png`
  * `04_promo_frost_kitsune_ciano.png`
  * `05_promo_evolucao_level_1_10_100.png`
  * `pagina_completa_roblox.png`

---

## 3. O Que Esses 4 Jogos Têm em Comum? (Os 7 Pilares)

1. **Mesmo Core Loop Incremental de 4 Passos:**
   * *Treino simples/AFK* (barra fixa, esteira ou `+1`) → *Ação em corredor linear* (arremessar, correr/roubar ou cavalgar/lutar) → *Coleta baseada em RNG* → *Renda/Poder exponencial na base* para comprar equipamentos superiores.
2. **Mapas Lineares em "Corredor de Biomas" (*Distance/Stat-Gated Runway*):**
   * Todos estruturam o mundo em uma linha reta progressiva de zonas/biomas (15 zonas, 13+ biomas, 17 zonas, 60 estágios). Isso cria o efeito psicológico de **"quase lá" (*near-miss*)**: o jogador vê a recompensa do próximo bioma logo à frente e sente urgência em treinar mais um pouco.
3. **Sistema de RNG em 3 Camadas (Raridade × Tamanho/Peso × Mutação):**
   * Além da raridade da espécie, sorteiam escala física gigantesca (*Big, Huge, Titanic, Infinite* ou peso em *kg*) e mutações visuais brilhantes (*Gold, Diamond, Emerald, Ruby, Rainbow, Bloom*) que empilham multiplicadores de `1.25x` a `20x+`. Todos também possuem um **Índice/Enciclopédia** para incentivar coleção completa.
4. **Direção de Arte "Studded Voxel Retro-Moderno":**
   * Terrenos quadriculados bicolores, texturas clássicas de **Square Studs** (e **Inlets**) do Roblox combinadas com materiais `Neon`, `Glass`, `Highlight`, partículas vibrantes e feixes de luz. Roda com excelente FPS em celulares de entrada e comunica visualmente cada raridade à primeira vista.
5. **Fórmula Idêntica de Marketing Visual (O "Padrão Bacon Hair"):**
   * Todos colocam o avatar clássico masculino **Bacon Hair** com contorno espesso (preto ou branco) e expressões faciais exageradas como protagonista das thumbnails.
   * *Throw a Seed* e *Throw Food For Animals* chegam a usar **exatamente os mesmos templates de composição** (escada de 5 plataformas coloridas até um item `$/S`, e silhueta preta com `?` branco e `!!` vermelho).
   * Uso massivo de gatilhos visuais de CTR: setas vermelhas, rótulos `YOU!`, números astronômicos em verde-neon (`$12,850B/S`, `$68,543B/S`, `$89,121Sp/s`), selos `+1` e evolução `LEVEL 1 → LEVEL 10 → LEVEL 100`.
6. **Servidores Pequenos (5 a 8 Jogadores) Otimizados para Mobile:**
   * Limites baixos (`5`, `7`, `5`, `8` jogadores) para manter todas as bases próximas à pista central e evitar quedas de FPS causadas por dezenas de modelos gigantes com textos `$/s` e partículas rodando simultaneamente em celulares e tablets.
7. **Economia de Retenção (Offline Cash + Inflação Numérica + Gamepasses Espelhados):**
   * Ganhos passivos mesmo offline, progressão numérica até casas como Quadrilhões (`Qa`), Septilhões (`Sp`) e Octodeciliões (`Ocd`), eventos semanais sazonais e monetização padronizada (*2x Luck*, *2x Power/Speed*, *Auto-Train/Hatch/Throw*).
