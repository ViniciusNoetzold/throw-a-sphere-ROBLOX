# GDD Completo — Jogue uma Orbe! / Throw a Sphere!

**Subpasta do Projeto:** `06_Projeto_Jogue_Uma_Orbe_Throw_a_Sphere/`  
**Título Global (Roblox EN):** `Throw a Sphere! [Catch Critters]`  
**Título Localizado (PT-BR):** `Jogue uma Orbe! [Capture Criaturas]`  
**Gênero:** Simulation / Incremental Catch & Collection Tycoon  
**Tamanho do Servidor:** 6 Jogadores *(ideal para manter os 6 Santuários ao redor do Hub Central sem quedas de FPS em celulares)*

---

## 1. Identidade Visual e Proteção de Direitos Autorais (IP Safe)

Para unir o apelo viral de simuladores de arremesso (*Throw a Seed* / *Throw Food For Animals*) com a fantasia de captura estilo Pokémon sem sofrer bloqueios DMCA na plataforma:

1. **Cápsulas Originais (Sem Esferas Bicolores Clássicas):**
   * Substituímos pokébolas por **Orbes Geométricas, Rúnicas e Hex-Tech** (octaedros, icosaedros e esferas com anéis orbitais giratórios e núcleo de energia neon).
   * Ao acertar uma criatura, a orbe abre suas placas geométricas, projeta um feixe de energia e fecha em um núcleo pulsante.
2. **Design das Criaturas (Voxel / Blocky Studs + Low-Poly Facetado):**
   * Todas as criaturas usam silhuetas icônicas, faces expressivas e estética **Blocky/Voxel com Square Studs** ou **Low-Poly Flat-Shaded**, alinhadas ao padrão visual de sucesso do Roblox.
   * **Auras de Raridade à Distância:** Criaturas *Épicas* possuem partículas sutis; *Míticas* emitem contornos `Highlight`; *Lendárias* e *Secretas* projetam um **pilar vertical de luz (`Beam`)** visível de qualquer ponto do bioma.
3. **Variantes Visuais (Mutações × Tamanhos):**
   * **Tamanhos (via `Model:ScaleTo`):** Normal (`1.0x`), Grande (`1.35x`, renda `1.5x`), Enorme/Huge (`1.85x`, renda `2.5x`), Titânico (`2.6x`, renda `5x`).
   * **Mutações Visuais:** Normal (`1x`), **Dourada** (`2x`, material `Foil` + brilho ouro), **Cristal/Diamante** (`3.5x`, `Glass` ciano), **Abissal** (`6x`, roxo escuro + aura de fumaça), **Arco-Íris** (`12x`, ciclo `Color3.fromHSV`), **Celestial** (`20x`, branco/ouro com coroa flutuante).

---

## 2. Planejamento das 4 Gerações de Criaturas ("Pokémons" Autorais)

Para sustentar atualizações semanais no Roblox por meses (exatamente como os jogos líderes fazem), o catálogo é dividido em **4 Gerações**:

### 🌱 Geração 1 — *Origens Elementais* (Lançamento Base: 30 Criaturas + Evoluções)
* **3 Linhas Evolutivas Iniciais (Escolha ou Capture no Mapa):**
  * **Fogo:** `01. Pyrokit` (Raposa de Brasa) → `02. Blazefox` (Raposa Chamejante) → `03. Ignisovereign` (Kitsune Solar)
  * **Água:** `04. Aquapup` (Lontra Cristal) → `05. Tidefang` (Lobo Marinho) → `06. Leviathorn` (Dragão Abissal)
  * **Planta:** `07. Sproutling` (Tatuzinho Folha) → `08. Thornback` (Golem Florido) → `09. Gaiahorn` (Titã Silvestre)
* **Criaturas dos 6 Biomas Base (18 Criaturas):** 3 criaturas por bioma (Comum/Incomum, Rara/Épica, Mítica/Chefe de Zona).
* **Criaturas Especiais de Lançamento (3 Criaturas):** 2 Lendárias de Evento Climático (`Eclipsion`, `Meteorgon`) + 1 Secreta `1 em 1.000.000` (`Omnisfera`).
* *(Todas as 30 criaturas possuem prompts individuais prontos na pasta `prompts_individuais_pokemons/`!)*

### 🌗 Geração 2 — *Expansão "Luz & Eclipse"* (+25 Criaturas — Update 1 e 2)
* Introduz o **Ciclo Dia/Noite** (10 min dia / 10 min noite) e os elementos **Luz** e **Sombra**.
* Adiciona **Ovos de Santuário** (pré-evoluções fofas chocadas na base) e criaturas noturnas exclusivas (corujas estelares, panteras de sombra, mariposas de néon).

### ⛈️ Geração 3 — *Expansão "Fúria Climática"* (+25 Criaturas — Update 3 e 4)
* Introduz **Duplas Elementais** (ex.: Fogo+Terra, Gelo+Raio, Planta+Cósmico) e 4 climas globais dinâmicos: **Chuva de Meteoros, Tempestade Áurea, Nevasca Glacial e Aurora Estelar**.

### 🌀 Geração 4 — *Expansão "Fendas Dimensionais & Apex"* (+25 Criaturas — Update 5+)
* Introduz **Mega-Fusão Apex** (evolução máxima usando *Núcleos de Rebirth* + 5 criaturas fundidas), fendas dimensionais cronometradas e **Raids de Chefes do Servidor Inteiro**.

---

## 3. Cenário Completo, Zonas e Arquitetura Espacial

Veja o diagrama visual em `diagramas_projeto/mapa_cenario_santuarios_e_biomas.png`.

### A) Hub Central (Praça das Esferas — Raio: `110 studs`)
* **Pódio 3D Central:** Plataforma elevada no centro da praça com degraus de Ouro (1º), Prata (2º) e Bronze (3º) exibindo os **avatares 3D reais** dos Top 3 jogadores + sua criatura mais rara ao lado.
* **4 Quadros de Placar (`SurfaceGui`):**
  1. `Top Moedas Totais ($)`
  2. `Top Captura Mais Rara (1 em X / $/s)`
  3. `Top Nível & Rebirths`
  4. `Top Bestiário Completo`
* **Lojas e Estações ao Redor da Praça:**
  * **Mercador de Orbes** (compra de cápsulas em 8 tiers).
  * **Academia de Arremesso** (barras/alvos de treino para aumentar o Alcance e Força).
  * **Máquina de Fusão (5→1)** (combina 5 criaturas iguais em 1 versão evoluída/dourada `3x`).
  * **Totem de Recompensas Diárias & Baú de Grupo**.
  * **Portal da Trading Plaza** (desbloqueado no Nível 15).

### B) Anel dos 6 Santuários Pessoais
* Dispostos em semicírculo ao redor do Hub, cada jogador recebe automaticamente 1 lote cercado com:
  * **Placa com Avatar + Renda Total (`$/s`)** (igual ao visto em *Throw a Seed*).
  * **Slots de Exibição/Trabalho:** Inicia com 6 slots (expansível até 24 via Nível/Moedas/Gamepass), onde as criaturas equipadas passeiam e geram moedas continuamente (inclusive **offline** com até 8 horas acumuláveis).
  * **Área de Treino Pessoal:** Alvo/Barra fixa dentro da base para treinar Força de Arremesso rapidamente.

### C) Os 6 Biomas Escalonados (Corredor & Ilhas Conectadas por Portais)
| # | Bioma | Requisito de Entrada | Estilo Visual (Voxel + Studs) | Faixa de Dificuldade |
| :---: | :--- | :--- | :--- | :--- |
| **1** | **Pradaria Solar** | Grátis (Inicial) | Grama xadrez `#4CD92B / #3FC022`, árvores cúbicas, céu azul | `10 – 45` |
| **2** | **Floresta Neon** | `$2.500` + 4 registros no Bestiário | Grama azul-escura `#0F172A`, cogumelos e árvores neon ciano/rosa | `60 – 220` |
| **3** | **Cânion Vulcânico** | `$50.000` + 10 registros | Rocha xadrez `#450A0A / #B91C1C`, rios de lava luminosa | `300 – 1.200` |
| **4** | **Abismo Glacial** | `$1.2M` + 16 registros | Gelo xadrez `#BAE6FD / #38BDF8`, cavernas com cristais | `1.500 – 7.500` |
| **5** | **Ruínas Ancestrais** | `$45M` + 22 registros | Arenito dourado `#F5D06F`, pirâmides em blocos e runas | `10.000 – 45.000` |
| **6** | **Vazio Cósmico** | `$2.5B` + 26 registros + Nível 25 | Espaço `#1B1947 / #262460`, plataformas flutuantes estelares | `60.000 – 500.000+` |

---

## 4. Regras do Jogo (Balanceamento & Anti-Frustração)

1. **Regra de Propriedade da Captura (*Catch Lock*):** No instante em que sua orbe atinge uma criatura e iniciam as 3 balançadas, aquela criatura fica **bloqueada exclusivamente para você** por ~4 segundos. Outros jogadores não podem "roubar" o lançamento no meio da animação.
2. **Regra de Limite de Distância & Força de Arremesso:** Seu alcance máximo começa em `40 studs` e sobe ao treinar Força ou subir de Nível (`AlcanceMax = 40 + (ForcaTreino * 0.5) + (Nivel * 2)`). A mira parabólica fica **verde/dourada** dentro do seu alcance e **vermelha** se o alvo estiver fora do alcance.
3. **Regra de Recompensa na Fuga (Nunca Sair de Mãos Vazias):** Se a criatura escapar na 1ª ou 2ª balançada, o jogador recebe **25% a 50% do XP daquela criatura**, alguns **Fragmentos de Orbe** e **+5% de Pity (Sorte Acumulada)** até sua próxima captura bem-sucedida.
4. **Regra de Sinergia Elemental na Base:**
   * `3 criaturas` do mesmo elemento juntas no Santuário = **`+25% $/s`** para o grupo.
   * `6 criaturas` do mesmo elemento = **`+60% $/s`** + aura elemental conectada no chão.
   * `1 Trio Inicial Completo` (Fogo + Água + Planta no mesmo lote) = **`+40% $/s` ("Equilíbrio Primordial")**.
5. **Regra da Máquina de Fusão (5→1):**
   * Inserir **5 criaturas idênticas** funde-as em **1 versão superior**:
     * 5 Normais → 1 **Dourada Evoluída** (`3x $/s`)
     * 5 Douradas → 1 **Cristal/Diamante** (`6x $/s`)
     * 5 Cristais → 1 **Arco-Íris** (`15x $/s`)
6. **Regra de Trocas (Trading Plaza):** Exige **Nível 15+** e confirmações em 2 etapas com trava de 3 segundos contra golpes (*scam protection*).

---

## 5. Mecânica de Arremesso, Fórmula e Catálogo de Orbes

### Fórmula Matemática Exata da Captura
Para cada uma das **3 balançadas independentes**, a probabilidade $P \in [0, 1]$ é:

$$P = \min\left(1,\ \left(\frac{\text{PoderOrbe} \times \text{BonusMira} \times \text{SorteJogador}}{\text{DificuldadeCriatura}}\right)^{\frac{1}{3}}\right)$$

* **Multiplicadores de Precisão (`BonusMira`):**
  * Acerto no Corpo: **`1.0x`**
  * Longa Distância (`> 90 studs`): **`1.25x`** (*"TIRO LONGO!"*)
  * Acerto Crítico no Topo/Cabeça: **`1.5x`** (*"CRÍTICO!"*)
  * Longo Alcance + Crítico no Topo: **`1.85x`** (*"ARREMESSO LENDÁRIO!"*)
* **Exemplo Prático:** Se `PoderOrbe = 25`, `BonusMira = 1.5`, `SorteJogador = 1.2` e `DificuldadeCriatura = 90`:
  * Razão = `(25 * 1.5 * 1.2) / 90 = 45 / 90 = 0.50` (chance total final = 50%).
  * Por balançada: $P = 0.50^{1/3} \approx 0.7937$ (**79,4%** em cada giro; $0.7937^3 = 50\%$ de capturar!).

### Tabela das 8 Orbes de Captura
| Tier | Nome da Orbe | Poder | Custo (Moedas / Robux) | Visual & Efeito Especial |
| :---: | :--- | :---: | :---: | :--- |
| **1** | **Orbe Comum (Esfera de Pedra)** | `10` | `$25` | Octaedro cinza/azul com núcleo brilhante suave |
| **2** | **Orbe Esmeralda (Orbe Veloz)** | `25` | `$180` | Cubo chanfrado verde com anel horizontal giratório |
| **3** | **Orbe Rubi (Orbe de Fogo)** | `75` | `$1.500` | Cristal hexagonal vermelho/ouro; `+10%` extra em Fogo |
| **4** | **Orbe Safira (Orbe Glacial)** | `220` | `$15.000` | Prisma octogonal azul-gelo; `+10%` extra em Água/Gelo |
| **5** | **Orbe Rúnica Ancestral** | `800` | `$200.000` | Dodecaedro dourado com 2 anéis rúnicos flutuantes |
| **6** | **Orbe Hextech Neon** | `3.500` | `$4.000.000` | Núcleo ciano suspenso em gaiola geométrica rotativa |
| **7** | **Orbe Cósmica Estelar** | `18.000` | `$120.000.000` | Galáxia interna roxa com estrelas orbitais |
| **8** | **Orbe Mestre Suprema** | `∞` (`100%`) | `Drop Raro / 149 Robux` | Dourada + Arco-Íris com asas de energia; **nunca falha** |

---

## 6. Sistema de Upar de Nível (Níveis 1 a 100) + Rebirth

### Curva de XP e Ganhos
* **Fórmula de XP para o próximo nível:** $\text{XP}_{\text{req}}(L) = \lfloor 100 \times L^{1.6} \rfloor$
  * Nível 1 → 2: `100 XP` | Nível 5 → 6: `1.313 XP` | Nível 15 → 16: `7.614 XP` | Nível 50 → 51: `52.196 XP`
* **XP ganho por ação:**
  * Captura Comum: `+25 XP` | Rara: `+80 XP` | Épica: `+220 XP` | Mítica: `+650 XP` | Lendária/Chefe: `+2.500 XP` | Secreta: `+15.000 XP`.
  * **Fuga (Consolação):** Concede **35% do XP** da criatura + bônus de precisão (`+15 XP` por Acerto Crítico).

### Recompensas Automáticas ao Upar de Nível
* **A cada Nível ganho:** `+1.5% Sorte Permanente`, `+2 studs` de Alcance de Arremesso e prêmio instantâneo em moedas.
* **Marcos Especiais de Nível:**
  * **Nível 3:** Desbloqueia o **Auto-Coletor de Moedas** da Base.
  * **Nível 5:** `+1 Slot` no Santuário + Desbloqueia **Missões Diárias**.
  * **Nível 10:** Desbloqueia a **Máquina de Fusão (5→1)** + Título `[Caçador]`.
  * **Nível 15:** Desbloqueia o portal da **Trading Plaza** + `+1 Slot` no Santuário.
  * **Nível 25:** Acesso ao Bioma 6 (**Vazio Cósmico**) + Título `[Mestre das Orbes]`.
  * **Nível 40:** Desbloqueia **Rebirth** (reseta moedas e biomas por **Gemas Celestiais**, **`+50% Sorte`**, **`+100% Moedas $/s`** e **`+50% XP`** permanentes por Rebirth).

---

## 7. Sistema de Recompensas, Missões & Recompensas Diárias

### A) Recompensas Diárias (Daily Login Streak — Ciclo de 7 Dias)
| Dia | Recompensa Principal | Bônus Extra |
| :---: | :--- | :--- |
| **Dia 1** | `$500 Moedas` + `10x Orbes Comuns` | `+100 XP` |
| **Dia 2** | `$2.500 Moedas` + `5x Orbes Esmeralda` | Poção `2x Sorte` (10 min) |
| **Dia 3** | `$15.000 Moedas` + `5x Orbes Rubi` | `+500 XP` |
| **Dia 4** | `1x Criatura Rara Dourada Garantida` | Poção `2x Moedas` (15 min) |
| **Dia 5** | `$250.000 Moedas` + `3x Orbes Rúnicas` | `+1.500 XP` |
| **Dia 6** | `1x Totem de Chuva de Sorte (Servidor)` | `3x Orbes Hextech` |
| **Dia 7** | **`1x ORBE MESTRE SUPREMA` + Pet Exclusivo Semanal** | `5x Gemas de Rebirth` + Título `[Fiel]` |

### B) Presentes de Tempo Online (*Playtime Rewards* — Reseta a cada Sessão/Dia)
* **12 marcos cronometrados:** `2 min` → `5m` → `10m` → `15m` → `20m` → `30m` → `40m` → `50m` → `60m` → `75m` → `90m` → `120 min` (entregando moedas escaladas ao seu nível, pacotes de orbes, poções de `2x Luck` e uma *Orbe Cósmica* aos 120 min).

### C) Missões Diárias & Recompensas do Bestiário
* **3 Missões Diárias (Exemplos):** *"Capture 15 criaturas"*, *"Acerte 3 arremessos críticos"*, *"Faça 1 fusão na máquina"*. Recompensa: Orbes do seu bioma atual + XP + Gemas.
* **Bestiário Completo (Por Bioma):** Completar todas as entradas de um bioma desbloqueia **`+10% Sorte Permanente`**, uma **Aura/Trilha exclusiva** para o avatar e um **Bônus de Moedas**.
* **Recompensa de Grupo Roblox:** Entrar no grupo oficial concede `+10% Sorte`, `+1 Slot na Base` e Auto-Treino liberado grátis.

---

## 8. Placar Global + Pódio 3D & Sistema de Animações

### A) Placar + Pódio 3D Interativo
* **Pódio Físico no Centro do Hub:**
  * 1º Lugar (Bloco Dourado alto, coroa flutuante, luz dourada).
  * 2º Lugar (Bloco Prateado médio à esquerda).
  * 3º Lugar (Bloco Bronze à direita).
* **Como funciona no código:** A cada 60 segundos, o servidor consulta o ranking (`OrderedDataStore` ou sessão), gera um boneco NPC do avatar de cada vencedor via `Players:CreateHumanoidModelFromUserId(userId)`, aplica animação de vitória/aceno e instancia **ao lado dele a sua criatura equipada mais forte** com seu respectivo tamanho/mutação.

### B) Catálogo Completo de Animações do Jogo
1. **Avatar do Jogador:**
   * *Mira Carregada:* Braço direito recuado para trás segurando a Orbe girando; tronco levemente inclinado para frente.
   * *Arremesso:* Movimento rápido de lançamento + soltura de partículas na mão.
   * *Treino na Base:* Flexão na barra fixa ou golpe em saco de areia/alvo para aumentar Alcance.
   * *Captura Bem-Sucedida:* Pulo comemorativo + banner na tela exibindo a criatura girando em 3D (*ViewportFrame*).
2. **Orbe de Captura:**
   * *Voo:* Trajetória em curva de Bézier quadrática com rastro (`Trail`) colorido da cor da Orbe.
   * *Impacto & Absorção:* A orbe abre em 2 metades/anéis, emite um feixe de sucção (`Beam`) enquanto a criatura encolhe (`TweenService`) para dentro do núcleo.
   * *As 3 Balançadas:* Inclinação esquerda (`-28°`) → direita (`+28°`) → centro, acompanhada de faíscas e som de clique metálico **subindo 1 semitom a cada balançada** (`PlaybackSpeed`: `1.0` → `1.15` → `1.32`).
   * *Trava Final (Sucesso):* Explosão de estrelas/confetes + som de sino dourado + texto `CAPTURADO!`.
   * *Quebra (Falha):* Orbe racha com partículas cinzas + criatura reaparece dando um salto e foge em corrida com `XP +`.
3. **Criaturas:**
   * *Idle:* Flutuação senoidal ou respiração suave (cabeça e cauda balançando via `Motor6D` ou `CFrame`).
   * *Patrulha no Bioma:* Caminhada entre *waypoints* aleatórios com rotação suave para a direção do movimento.
   * *Na Base:* Passeiam pelo lote do jogador e, a cada intervalo, geram moedas flutuantes (`+$150`) que sobem até desaparecer.


---

## 9. Arquitetura de Servidores & Lotação por Sala

* **Mundo Principal (`Place 1`):** **6 jogadores por sala** (+1 vaga social reservada para amigos). Mantém o carregamento leve em celulares e todos os 6 Santuários em volta da Praça Central.
* **Servidores Privados (VIP):** **6 jogadores** a **`99 Robux/mês`**, focado em jogadores que deixam o PC/celular no *Auto-Arremesso AFK* ou caçam Chefes/Secretos sem concorrência.
* **Trading Plaza (`Place 2` via `TeleportService`):** **30 jogadores por sala**, liberada a partir do **Nível 15**, reunindo jogadores de vários servidores para trocas e leilões de criaturas *Arco-Íris*, *Abissais* e *Titânicas*.

---

## 10. Monetização em Robux (Baseada nos Preços Reais dos 4 Jogos)

* **Referência Observada:** *Throw a Seed* (`149 R$ Strong Arms`, `199 R$ Double Money`, `249 R$ Double Luck`, `799 R$ Rainbow Seed`), *Steal An Egg* (`399 R$ X2 Money`, `467 R$ X2 Growth Speed`) e *+1 Ride Pets to Fight* (`49 R$ Starter Pack`, `99 R$ Turbo Bot`).
* **11 Gamepasses Permanentes (de `49 R$` a `1.199 R$`):**
  * `Starter Pack` (**49 R$**) • `Braços de Titã 2x Força` (**149 R$**) • `Auto-Arremesso AFK` (**179 R$**) • `2x Moedas` (**199 R$**) • `2x Sorte` (**249 R$**) • `Santuário +8 Slots` (**299 R$**) • `Fusão Rápida & 2x XP` (**349 R$**) • `VIP Dourado` (**399 R$**) • `Arremesso Triplo` (**599 R$**) • `Orbe Prismática Infinita 10x Sorte` (**799 R$**) • `Mega Coletor + Auto-Fusão` (**1.199 R$**).
* **7 Produtos Recorrentes (*Developer Products*):** `1x Orbe Mestre` (**79 R$**, ou `3x = 199 R$` / `10x = 549 R$`), Botão de Emergência `"Salvar Lendário!"` (**79 R$**), `Totem Global 5x Sorte (15m)` (**199 R$**), `Invocar Boss/Eclipse` (**249 R$**), `Combo Poções 3x` (**99 R$**), `Slot Extra` (**69 R$**) e `Pular Cooldown Fusão` (**39 R$**).

*(Consulte o documento completo em `05_SERVIDORES_MONETIZACAO_NUMEROS_E_UI.md` para detalhes de ritmo, Big Numbers até `Ocd`, Combo Fever Mode e design da UI).*
