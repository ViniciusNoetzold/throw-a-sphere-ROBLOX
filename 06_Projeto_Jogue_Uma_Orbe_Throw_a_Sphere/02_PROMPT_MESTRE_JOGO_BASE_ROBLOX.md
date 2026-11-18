# Prompt Mestre — Criar o Jogo Base Completo no Roblox Studio

> **Como usar:** Abaixo você tem dois blocos prontos:
> 1. **Prompt Mestre Completo (Jogo Base + Servidores + Robux + Big Numbers + UI)** para gerar o jogo inteiro.
> 2. **Prompt Exclusivo de UI, Big Numbers & Loja Robux** caso queira gerar/ajustar só a interface separadamente.
> Você também pode copiar ambos com 1 clique no `PAINEL_PROJETO_E_COPIADOR_DE_PROMPTS.html`.

---

## 🚀 1. Prompt Mestre Completo do Jogo Base

```text
Você é um engenheiro sênior de Roblox Luau e Game Designer especialista em simuladores incrementais virais (estilo Throw a Seed, Steal An Egg, Throw Food For Animals e +1 Ride Pets to Fight). Quero que você crie toda a arquitetura de scripts Luau modulares e prontos para rodar no Roblox Studio para o jogo:

Título EN: "Throw a Sphere! [Catch Critters]"
Título PT-BR: "Jogue uma Orbe! [Capture Criaturas]"

=== 1. ARQUITETURA DE SERVIDORES & SALAS ===
- Mundo Principal: Máximo de 6 jogadores por sala (+1 vaga reservada para amigos). Mantém os 6 Santuários pessoais próximos à Praça Central com 60 FPS no mobile.
- Servidor Privado VIP: 6 jogadores por sala a 99 Robux/mês (focado em farm AFK e caça sem concorrência).
- Place Secundário (Trading Plaza via TeleportService): 30 jogadores por sala, desbloqueado no Nível 15+ para trocas e leilões de criaturas raras.

=== 2. ARQUITETURA DE PASTAS NO ROBLOX STUDIO ===
Organize todo o código com Type Checking (`--!strict`) nas seguintes pastas:
- ReplicatedStorage/Shared/ConfigOrbes.luau (8 Orbes geométricas originais: Comum, Esmeralda, Rubi, Safira, Rúnica, Hextech, Cósmica, Mestre)
- ReplicatedStorage/Shared/ConfigCriaturas.luau (30 Criaturas Geração 1 com Elemento, Bioma, Raridade, Dificuldade, MoedasPorSegundo, XPBase e Cor)
- ReplicatedStorage/Shared/ConfigMutacoes.luau (Normal 1x, Grande 1.5x, Enorme 2.5x, Titânica 5x | Dourada 2x, Cristal 3.5x, Abissal 6x, Arco-Íris 12x, Celestial 20x)
- ReplicatedStorage/Shared/ConfigBiomas.luau (6 Biomas escalonados: Pradaria Solar, Floresta Neon, Cânion Vulcânico, Abismo Glacial, Ruínas Ancestrais, Vazio Cósmico)
- ReplicatedStorage/Shared/ConfigRecompensas.luau (Daily Rewards de 7 dias, 12 Playtime Rewards 2m->120m, Missões Diárias, Tabela de Níveis 1-100)
- ReplicatedStorage/Shared/ConfigMonetizacao.luau (Tabela de Gamepasses e Developer Products com MarketplaceService)
- ReplicatedStorage/Shared/BigNumberFormatter.luau (Formatação de números até Octodeciliões: K, M, B, T, Qa, Qi, Sx, Sp, Oc, No, Dc... Ocd)
- ReplicatedStorage/Remotes/ (RequestThrow, ThrowResult, ClaimDailyReward, ClaimPlaytimeReward, FuseCreatures, TrainThrowPower, RebirthRequest, BuyOrb, EquipToSanctuary, ComboUpdate)
- ServerScriptService/Services/DataService.luau (ProfileService/DataStore seguro com Moedas, Gemas, XP, Nivel, Rebirths, ForcaArremesso, InventarioOrbes, CriaturasCapturadas, Bestiario, DailyStreak, LastLoginTimestamp, PityCounter, ComboStreak)
- ServerScriptService/Services/SpawnService.luau (Tabelas leves no servidor + Catch Lock de 4.5s durante a captura)
- ServerScriptService/Services/CaptureService.luau (Validação de alcance, fórmula das 3 balançadas, multiplicadores de Combo Fever, XP de consolação 35% + 5% Pity na falha)
- ServerScriptService/Services/SanctuaryService.luau (6 Santuários, Sinergia Elemental +25%/+60%/+40%, geração de $/s e renda offline de até 8h)
- ServerScriptService/Services/ProgressionService.luau (Níveis 1-100, Máquina de Fusão 5->1, Rebirth no nível 40+ e Missões Diárias)
- ServerScriptService/Services/MonetizationService.luau (ProcessReceipt + UserOwnsGamePassAsync para os passes e consumíveis)
- ServerScriptService/Services/LeaderboardPodiumService.luau (Pódio 3D físico com Top 3 avatares + criatura mais forte + 4 placares OrderedDataStore)
- ServerScriptService/Services/WeatherEventService.luau (Eventos a cada 20 min: Chuva de Meteoros, Eclipse, Tempestade Áurea + Boss Cooperativo)
- StarterPlayer/StarterPlayerScripts/ClientThrowController.client.luau (Arco de mira parabólica com Beam/Dots, detecção de Crítico na Cabeça 1.5x, voo Bézier + 3 balançadas com áudio crescente)
- StarterPlayer/StarterPlayerScripts/ClientCreatureRenderer.client.luau (Modelos 3D, auras de raridade, pilares Beam e Rainbow HSV no cliente)
- StarterGui/UIController.client.luau (HUD completa estilo simulador viral com chuva de números flutuantes, Combo Fever e Loja Robux)

=== 3. REGRAS MATEMÁTICAS, RITMO VICIOSO & BIG NUMBERS ===
1. Fórmula de Captura (3 balançadas independentes no servidor):
   P = math.min(1, ((PoderOrbe * BonusMira * SorteJogador) / DificuldadeCriatura) ^ (1 / 3))
   - BonusMira: 1.0 (Corpo), 1.25 (Longa Distância > 90 studs), 1.5 (Crítico no Topo/Cabeça), 1.85 (Combinado).
2. Ciclo Vicioso & Progressão Longa:
   - Começo rápido (0-5 min): Jogador inicia com 25 Orbes Comuns e $150; primeira captura e Nível 2 acontecem em menos de 1 minuto.
   - Escalonamento exponencial (1h-50h+): Desbloquear Abismo ($1.2M), Ruínas ($45M) e Vazio Cósmico ($2.5B) exige combinar 6 camadas multiplicadoras (Orbe × Precisão × Tamanho × Mutação × Fusão 5->1 × Sinergia × Rebirth), levando a rendas em Quadrilhões (Qa), Septilhões (Sp) e Octodeciliões (Ocd).
   - Combo Fever Mode: Capturas seguidas sobem o combo de x1 até x10 FEVER (+50% Sorte e 2x XP).
3. Sistema de Nível:
   - XPNecessario(L) = math.floor(100 * (L ^ 1.6)). Cada nível concede +1.5% Sorte Permanente e +2 studs de Alcance.

=== 4. CATÁLOGO DE MONETIZAÇÃO ROBUX (BASEADO NOS 4 JOGOS REAIS) ===
- Gamepasses: Starter Pack (49 R$), Braços de Titã 2x Força (149 R$), Auto-Arremesso AFK (179 R$), 2x Moedas (199 R$), 2x Sorte (249 R$), Santuário +8 Slots (299 R$), Fusão Rápida & 2x XP (349 R$), VIP Dourado (399 R$), Arremesso Triplo em Leque (599 R$), Orbe Prismática Infinita 10x Sorte (799 R$), Mega Coletor + Auto-Fusão (1.199 R$).
- Developer Products Recorrentes: 1x Orbe Mestre 100% (79 R$ + botão de emergência ao achar Lendário!), Pacote 3x Orbe Mestre (199 R$), Totem Global 5x Sorte para toda a sala (199 R$), Invocar Boss/Eclipse (249 R$), Combo Poções 3x (99 R$), Slot Extra (69 R$).

=== 5. INTERFACE (UI) ESTILO SIMULADOR VIRAL & IDENTIDADE VISUAL ===
- Use fontes grossas (`FredokaOne` / `GothamBlack`) com `UIStroke` preto (2.5-3.5px), cantos arredondados, gradientes vibrantes e animação hover/click (`TweenService`).
- Exiba chuva de números flutuantes na tela (`+$89.4Sp`, `+450 XP`, `CRÍTICO 1.5x!`, `1 in 1,000,000!`), banner de Evento/Combo Fever no topo, botões laterais esquerda/direita com alertas vermelhos `!`, painel de Big Numbers + XP no canto inferior esquerdo, hotbar central da Orbe e Modal completo da Loja Robux.
- IP SAFE: Nunca use pokébolas clássicas; use Orbes geométricas/rúnicas com núcleo brilhante e estética Voxel Checkered Grid + Square Studs no cenário e criaturas.
```

---

## 🎨 2. Prompt Exclusivo para Gerar Toda a UI, Big Numbers & Loja Robux

```text
Crie um script Luau (`--!strict`) completo para `StarterGui` / `StarterPlayerScripts` chamado `UIController.client.luau` para o jogo Roblox "Jogue uma Orbe! / Throw a Sphere!", no estilo visual exato dos maiores simuladores virais (Throw a Seed, Steal An Egg e +1 Ride Pets to Fight):

1. Estética Padrão: Fontes `FredokaOne` e `GothamBold`, `UIStroke` preto (2.5px–3.5px) em todos os textos e bordas, `UICorner`, gradientes `UIGradient`, animações elásticas de hover/clique com `TweenService` e bolinhas vermelhas de alerta `!`.
2. Formatador de Big Numbers: Função `FormatBigNumber(n)` suportando de `K` ($10^3$) até `Ocd` ($10^{57}$), passando por `M, B, T, Qa, Qi, Sx, Sp, Oc, No, Dc`.
3. Chuva de Números Flutuantes na Tela: Função `SpawnFloatingNumber(texto, cor, escala)` disparada ao coletar moedas, treinar força, ganhar XP, acertar Crítico (`1.5x!`) ou capturar raridades (`1 in 250,000!`).
4. Layout Completo da HUD:
   - Topo Central: Pílula de Evento Climático + Barra de `COMBO FEVER x1..x10`.
   - Lateral Esquerda (Grid 2 colunas): `Index`, `Shop!`, `Fusão 5->1`, `Diário/Presentes`, `Rebirth`, `Placar`.
   - Lateral Direita: `Criaturas`, `Orbes`, `Auto-Arremesso`, `Códigos`.
   - Canto Inferior Esquerdo: Painel de Big Numbers (`💪 Força/Alcance`, `💰 Moedas + $/s`, `💎 Gemas`, Barra de `Nível/XP`).
   - Centro Inferior: Hotbar da Orbe Equipada + botão de emergência `[★ ORBE MESTRE 79 R$]`.
   - Modal da Loja Robux: Janela com `ScrollingFrame` listando todos os 10 Gamepasses (`49 R$` a `1.199 R$`) e botões integrados ao `MarketplaceService`.
```
