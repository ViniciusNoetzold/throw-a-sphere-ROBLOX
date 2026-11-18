# Servidores, Monetização em Robux, Motor de "Big Numbers" & UI Completa

Este documento complementa o GDD principal com a **arquitetura de servidores**, a **estratégia real de vendas no Roblox (baseada nos preços dos 4 jogos de referência)**, o **balanceamento de progressão longa com explosão de números na tela** e o **Prompt Exclusivo para criar toda a UI (HUD + Menus)**.

---

## 1. Arquitetura de Servidores & Lotação por Sala

### A) Por que 6 Jogadores por Sala Principal (e não 20 ou 50)?
Nos jogos de referência (*Throw a Seed*: `5 jogadores`, *Throw Food For Animals*: `5 jogadores`, *Steal An Egg*: `7 jogadores`, *+1 Ride Pets to Fight*: `8 jogadores`), salas pequenas são o segredo técnico e psicológico do sucesso:
1. **Performance Mobile:** Cada jogador exibe até 18–24 criaturas 3D com tamanhos *Huge/Titânico*, partículas, `Highlight`, feixes verticais (`Beam`) e `BillboardGuis` (`$/s`). Em salas de 6 jogadores, o mapa carrega instantaneamente em celulares básicos a 60 FPS.
2. **Proximidade do Santuário:** Os 6 Santuários formam um semicírculo compacto ao redor da Praça Central e da entrada do primeiro bioma — todo mundo vê as criaturas raras dos vizinhos o tempo inteiro (gerando *inveja positiva* e vontade de gastar Robux para alcançá-los!).
3. **Menos Disputa Frustrante:** Com 6 jogadores espalhados pelos 6 biomas, sempre há monstros nascendo sem virar bagunça.

### B) Configuração Exata das Salas no Roblox Creator Dashboard
| Tipo de Place / Sala | Máximo de Jogadores | Vagas Sociais (Amigos) | Preço / Acesso | Função no Ecossistema |
| :--- | :---: | :---: | :--- | :--- |
| **Place 1: Mundo Principal** | **6 Jogadores** | `1 vaga reservada` (entra até 7 via amigo) | Grátis | Caça nos 6 biomas, Santuários pessoais, Eventos e Pódio 3D |
| **Servidores Privados (VIP)** | **6 Jogadores** | Livre para convidados | **`99 Robux/mês`** | Farm AFK sem concorrência por Chefes de Zona e spawns Secretos |
| **Place 2: Trading Plaza** *(TeleportService)* | **30 Jogadores** | `3 vagas` | Grátis (**Exige Nível 15+**) | Mercado de trocas entre jogadores, leilões de criaturas *Arco-Íris/Abissal* e *Placar Global* |

> **Dica de Retenção Financeira:** Servidores Privados a **`99 Robux`** vendem muito mais do que servidores caros (300–500 R$) porque jogadores de farm AFK compram para deixar a conta farmando a noite toda com *Auto-Arremesso*.

---

## 2. Estratégia Real de Monetização (Preços Baseados nos 4 Jogos)

### A) Referência Real Observada nos Concorrentes
* **Throw a Seed:** *Strong Arms* (`149 R$`), *Double Money* (`199 R$`), *Double Luck* (`249 R$`), *Rainbow Seed — 10x Sorte* (`799 R$`), além de *VIP* e *Big Garden*.
* **Steal An Egg:** *X2 Money* (`399 R$`), *X2 Growth Speed* (`467 R$`) + consumíveis instantâneos (*Instant Hatch / Grow All*).
* **+1 Ride Pets to Fight:** *Starter Pack* (`49 R$`), *Turbo Bot* (`99 R$`) + passes de *Auto*, *2x Power* e poções/boosts.

### B) Catálogo de Gamepasses Permanentes de "Jogue uma Orbe!"
Construímos uma escada de preços que converte desde quem só tem `49 Robux` até as "baleias" (*whales*) de `1.199 Robux`:

| # | Gamepass | Preço (Robux) | Efeito no Jogo & Psicologia de Venda |
| :---: | :--- | :---: | :--- |
| **1** | **Starter Pack (Oferta 15 min)** | **`49 R$`** | 1x Criatura Épica Dourada (`+500/s`), 10x Orbes Rubi, `+50.000 Moedas` e `2x Sorte (20m)` |
| **2** | **Braços de Titã (`2x Força & Alcance`)** | **`149 R$`** | Dobra o ganho de Força no treino e aumenta o alcance máximo da mira em `+35%` |
| **3** | **Auto-Arremesso & Auto-Treino** | **`179 R$`** | Automatiza treino na base + mira e lança orbes sozinho no bioma atual (essencial para AFK!) |
| **4** | **2x Moedas (`Double Cash`)** | **`199 R$`** | Dobra para sempre toda a renda gerada no Santuário e offline |
| **5** | **2x Sorte (`Double Luck`)** | **`249 R$`** | Dobra permanentemente a chance de captura $P$ e de Mutações/Tamanhos raros |
| **6** | **Santuário Gigante (`+8 Slots`)** | **`299 R$`** | Adiciona +8 espaços extras na base para acumular Sinergias Elementais |
| **7** | **VIP Dourado (`Tag + Renda + Orbe`)** | **`399 R$`** | Tag `[VIP]` dourada no chat, `+25% Moedas`, `+25% XP`, aura exclusiva e Baú VIP diário |
| **8** | **Fusão Instantânea & 2x XP** | **`349 R$`** | Dobra todo XP de nível e permite fundir com **4 criaturas** em vez de 5 |
| **9** | **Arremesso Triplo (`Triple Throw`)** | **`599 R$`** | Lança **3 Orbes em leque** de uma só vez (pode capturar 3 monstros simultâneos!) |
| **10** | **Orbe Prismática Eterna (10x Sorte)** | **`799 R$`** | Inspirada na *Rainbow Seed* (799 R$): Orbe infinita (não acaba!) com **10x de Sorte** e brilho arco-íris |
| **11** | **Mega Coletor Magnético + Auto-Fusão** | **`1.199 R$`** | Pacote endgame: coleta drops/moedas do mapa inteiro e funde comuns automaticamente |

### C) Produtos Consumíveis Recorrentes (*Developer Products* — Compráveis Infinitas Vezes)
Onde os jogos do Roblox realmente faturam alto todos os dias:
1. **1x Orbe Mestre Suprema (100% Captura):** **`79 R$`** *(Pacote com 3x = `199 R$` | Pacote 10x = `549 R$`)*
2. **Gatilho de Emergência ("SALVAR LENDÁRIO!"):** Quando uma criatura *Lendária/Secreta* aparece ou escapa na 2ª balançada, surge um botão discreto pulsante por 10s: **`Usar Orbe Mestre Agora (79 R$)`** — taxa de conversão altíssima!
3. **Totem Global de Chuva de Sorte (`Server-Wide 5x Luck 15m`):** **`199 R$`** — Anuncia seu nome em banner dourado no topo da tela para todos na sala (*"Ana ativou 5x Sorte para o servidor!"*).
4. **Invocar Chefe de Zona / Evento Eclipse Agora:** **`249 R$`**
5. **Pacote de Poções (`3x Sorte` + `3x Moedas` por 30 min):** **`99 R$`**
6. **Comprar Slot de Santuário Extra Individual:** **`69 R$`** (ou moedas no endgame).
7. **Pular Cooldown da Máquina de Fusão / Chocar Agora:** **`39 R$`**

---

## 3. Engenharia do Ciclo Vicioso & Motor de "Big Numbers"

Para o jogo prender por **dezenas de horas** (começo frenético e viciante → meio estratégico → endgame de números astronômicos), estruturamos o ritmo em **4 Atos**:

### A) Curva de Ritmo (Como Viciar o Jogador)
1. **Ato 1 — Gancho Instantâneo (0 a 5 minutos):**
   * O jogador começa com `25 Orbes Comuns` e `$150`. Em **10 segundos** vê criaturas na *Pradaria Solar* e captura sua primeira em **1 arremesso**.
   * Ganha `$12/s` na hora, sobe para o **Nível 2 em menos de 1 minuto** (chuva de `+XP!` e `LEVEL UP!`), abre o **Presente de 2 minutos** e compra a *Orbe Esmeralda* (`$180`).
2. **Ato 2 — Expansão & Sinergia (5 a 45 minutos):**
   * Desbloqueia a **Floresta Neon (`$2.500`)** e o **Cânion Vulcânico (`$50.000`)**.
   * Descobre que uma criatura **Dourada Grande (`3x`)** ou juntar **3 do mesmo elemento (`+25%`)** faz sua renda pular de `$500/s` para `$50K/s`. Sente a necessidade de treinar Força para alcançar criaturas mais distantes.
3. **Ato 3 — A Parede Estratégica & Fusão (1h a 6h):**
   * O **Abismo Glacial (`$1.2M`)** e as **Ruínas Ancestrais (`$45M`)** exigem **Máquina de Fusão (`5 → 1`)**, **Orbes Rúnicas/Hextech** e busca por mutações **Abissal (`6x`)** e **Arco-Íris (`12x`)**.
   * Aqui entram as primeiras compras de passes (`2x Luck`, `2x Cash`, `Auto-Throw`) e participação nos **Eventos a cada 20 min** para conseguir Lendários.
4. **Ato 4 — Endgame Exponencial & Rebirths (6h a 50h+):**
   * O **Vazio Cósmico (`$2.5B`)**, *Bosses Coletivos*, **Rebirths** no Nível 40+ (`+100% Renda` e `+50% Sorte` cumulativos por Rebirth) e caça à **Omnisfera Arco-Íris Titânica (`$60M × Mutação × Rebirth = Bilhões/Trilhões/Septilhões por segundo`)**.

### B) Escala de "Big Numbers" na Tela (Até Octodeciliões)
O formatador numérico oficial converte qualquer valor gigante para exibição legível e viciante na HUD:
* `K` (Mil — $10^3$) → `M` (Milhão — $10^6$) → `B` (Bilhão — $10^9$) → `T` (Trilhão — $10^{12}$) → `Qa` (Quadrilhão — $10^{15}$) → `Qi` (Quintilhão — $10^{18}$) → `Sx` (Sextilhão — $10^{21}$) → **`Sp`** (Septilhão — $10^{24}$, igual ao `$89,121Sp/s` de *Steal An Egg*!) → `Oc` ($10^{27}$) → `No` ($10^{30}$) → `Dc` ($10^{33}$) → ... → **`Ocd`** (Octodecilião — $10^{57}$, igual a *Throw Food For Animals*!).

### C) Chuva de Números & Efeitos na Tela (*Juice* Máximo)
1. **Pop-ups Elásticos Flutuantes:** Toda coleta da base, acerto de treino ou captura lança múltiplos números coloridos na tela com contorno preto (`UIStroke`), subindo com curva elástica (`+$14.2B`, `+450 XP`, `CRÍTICO 1.5x!`, `TIRO LONGO 1.25x!`).
2. **Combo Fever Mode (`COMBO x2 → x10 FEVER!`):** Capturar criaturas em sequência sem errar enche uma barra de **FEBRE** no topo. Ao atingir `5x` ou `10x`, a borda da tela brilha dourada, todos os números na tela dobram de tamanho e você ganha **`+50% Sorte` e `2x XP`** durante o combo!
3. **Banner Global de Raro (`1 in 250,000!`):** Quando alguém na sala captura uma criatura Mítica/Lendária/Secreta/Arco-Íris, aparece um banner animado no topo com o avatar da pessoa e a probabilidade (`1 in 1,000,000!`).

---

## 4. Design da Interface (UI) + Prompt Exclusivo de UI

Veja o layout visual completo no arquivo **`diagramas_projeto/mockup_ui_completa_e_numeros_na_tela.png`** e o script Luau gerador pronto em **`scripts_prototipo_luau/04_Client_UI_Completa_BigNumbers_e_LojaRobux.luau`**.

### 📋 Prompt Exclusivo para Gerar / Expandir Toda a UI no Roblox Studio
```text
Crie um sistema completo de Interface (ScreenGui) gerado via Script Luau (`--!strict`) para o jogo Roblox "Jogue uma Orbe! / Throw a Sphere!", seguindo exatamente a estética vibrante e legível dos maiores simuladores do Roblox (Throw a Seed, Steal An Egg e +1 Ride Pets to Fight):

REGRAS VISUAIS DA UI:
- Fontes arredondadas e grossas (`Enum.Font.FredokaOne` para títulos/números e `Enum.Font.GothamBold` para descrições).
- TODOS os textos e botões principais devem ter `UIStroke` preto (`Thickness = 2.5 a 3.5`), cantos arredondados (`UICorner`), gradientes vibrantes (`UIGradient`) e animação de escala suave ao passar o mouse (`TweenService` hover + click bounce).
- Use um Formatador de Big Numbers (`K, M, B, T, Qa, Qi, Sx, Sp, Oc, No, Dc, Ocd`) em todos os contadores.

ESTRUTURA EXATA DAS ÁREAS DA TELA:
1. TOPO CENTRAL (Evento & Combo Fever):
   - Pílula superior de Evento Ativo com barra de progresso e cronômetro (ex.: "☄️ CHUVA DE METEOROS • 5x SORTE • 03:42") e logo abaixo a barra dinâmica de "🔥 COMBO FEVER x5 (+50% SORTE)".
2. LATERAL ESQUERDA (Grid 2 colunas com ícones grandes + bolinha vermelha de notificação):
   - [📖 Bestiário / Index] | [🛒 Loja Robux!] (com brilho pulsante e selo "!")
   - [🧬 Fusão 5→1] | [🎁 Diário & Presentes] (com timer do próximo presente grátis)
   - [🔄 Rebirth] | [🏆 Ranking]
3. LATERAL DIREITA (Ações rápidas e Inventário):
   - [🐾 Minhas Criaturas] | [🔮 Orbes]
   - [⚡ Auto-Arremesso] (mostra cadeado se não tiver o passe) | [🎟️ Códigos]
4. CANTO INFERIOR ESQUERDO (Status do Jogador — números grandes!):
   - Card com `💪 Força / Alcance` (ex.: "💪 412.5B (Alcance: 680 studs)"),
   - `💰 Moedas` + subtexto verde-neon da renda passiva (`+$89.4Sp/s`),
   - `💎 Gemas de Rebirth`,
   - Barra de Nível do Jogador (`NV. 28 — 74% XP` + bônus atual de sorte).
5. CENTRO INFERIOR (Hotbar da Orbe Equipada):
   - Slot destacado mostrando o ícone e quantidade da Orbe atual (ex.: "Orbe Hextech [x42]") + botões rápidos `[AUTO]` (dourado) e `[TROCAR ORBE]` (azul) + botão de emergência `[ORBE MESTRE 79 R$]`.
6. SISTEMA DE CHUVA DE NÚMEROS FLUTUANTES (Screen Popups):
   - Função `SpawnFloatingNumber(texto, cor, escala)` que cria TextLabels temporários que saltam em arco próximo ao centro/HUD esquerda com TweenService (`EasingStyle.Back`) sempre que o jogador ganha moedas, força, XP, acerta Crítico (`1.5x!`) ou tira uma raridade absurda (`1 in 1,000,000!`).
7. MODAL DA LOJA ROBUX (`MarketplaceService`):
   - Janela com abas [Gamepasses] [Pacotes de Orbes] [Totens & Poções], exibindo cards coloridos com preços em Robux (49 R$, 149 R$, 179 R$, 199 R$, 249 R$, 299 R$, 399 R$, 599 R$, 799 R$, 1.199 R$), selo "MAIS VENDIDO" e botão verde clicável que dispara `PromptGamePassPurchase` / `PromptProductPurchase`.
```
