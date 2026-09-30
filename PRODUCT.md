# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Users

- **Personal Trainer (Consultoria Online e Presencial):** Profissional de Educação Física que gerencia sua carteira de alunos no computador ou celular, prescreve treinos periodizados (fichas A/B/C/D), calcula gasto energético e dieta (TMB/GET), realiza avaliações físicas, controla agenda semanal e recebe mensalidades via PIX.
- **Aluno (Praticante na Academia):** Usuário que acessa o aplicativo no chão da academia (uma mão ocupada entre séries, tela sob iluminação variável) para assistir ao vídeo curto de execução em Português (PT-BR), registrar carga/RPE e séries concluídas, acionar o cronômetro de descanso com alerta sonoro, acompanhar sua meta diária de água/dieta e quitar mensalidades pendentes via PIX Copia e Cola.
- **SuperAdmin (Operador SaaS):** Administrador da plataforma que monitora o faturamento recorrente (MRR), gerencia contas de Personal Trainers/Academias (`Tenants`) e controla o status de ativação de cada assinatura.

## Product Purpose

**PersonalPro** é uma plataforma SaaS Multi-Tenant completa que unifica a operação técnica, nutricional, de agendamento e financeira do Personal Trainer em um único ecossistema integrado à experiência de execução de treino em tempo real do Aluno.

O sucesso do produto significa:
- O Personal Trainer montar ou ajustar uma ficha de treino e prescrição de dieta completas em menos de 3 minutos, com exportação imediata em PDF e cobrança automatizada.
- O Aluno executar seu treino do dia na academia sem dúvidas de biomecânica (vídeos demonstrativos reais em PT-BR integrados ao card do exercício), sem perder o tempo de descanso entre séries e sem bloqueios burocráticos quando paga sua mensalidade via PIX.
- A evolução do produto ocorre **uma superfície e perfil por vez** (tratando cada fluxo — Login, Personal, Aluno, SuperAdmin — com foco dedicado).

## Positioning

Diferente de planilhas estáticas ou aplicativos que separam prescrição de treino, dieta e cobrança financeira em ferramentas desconectadas, o **PersonalPro** conecta diretamente o motor financeiro e de prescrição ao fluxo de execução do aluno:
- **Bloqueio e Desbloqueio Automático por Inadimplência (`INADIMPLENTE` / `EM_DIA`):** O status financeiro impacta o acesso ao treino em tempo real e é liberado instantaneamente via confirmação PIX Copia e Cola / QR Code.
- **Biblioteca Nativa de 121 Exercícios com Vídeos em Português (PT-BR) e Biomecânica:** Cada exercício na ficha do aluno já traz instruções técnicas passo a passo, dicas posturais, músculos alvo e vídeo demonstrativo em português embutido diretamente na tela de treino.
- **Prescrição Unificada (Treino + Dieta Mifflin-St Jeor + Avaliação Pollock 7 Dobras + Agenda Semanal):** Tudo isolado por `ID_TENANT` em arquitetura Multi-Tenant segura.

## Operating Context

- **No chão de academia (Aluno):** Uso primariamente móvel (vertical/touch), sob fadiga física entre séries de musculação. Exige alvos de toque amplos, leitura rápida de séries/repetições/carga/descanso, player de vídeo imediato sem sair do aplicativo e cronômetro regressivo audível.
- **No escritório ou entre aulas (Personal Trainer):** Uso híbrido em Desktop/Web e Mobile. Exige busca instantânea na biblioteca de 121 exercícios, criação rápida de fichas A/B/C/D, calculadora automática de macronutrientes, gráficos comparativos de evolução física/cargas e geração de relatórios em PDF.
- **Ambiente de Iluminação Dupla:** Suporte obrigatório e persistente a **Tema Escuro (`🌙 Dark Mode`)** e **Tema Claro (`☀️ Light Mode`)**, permitindo leitura confortável tanto em academias com baixa iluminação quanto em ambientes externos ou sob luz solar.

## Capabilities and Constraints

- **Stack e Arquitetura Existentes:**
  - **Backend:** C# .NET 10 Web API (`PersonalProAPI`) em `http://localhost:5250` e `http://localhost:5255`, autenticação JWT (`Bearer`) e senhas com hash BCrypt.
  - **Banco de Dados:** SQL Server (`Database=PersonalPro`) com isolamento Multi-Tenant (`ID_TENANT`), encoding UTF-8 (`65001`) e catálogo de 121 exercícios categorizados em 9 grupos musculares (`Peito`, `Costas`, `Pernas`, `Glúteos`, `Ombros`, `Bíceps`, `Tríceps`, `Abdômen`, `Cardio & HIIT`).
  - **Frontend:** Flutter (`personalpro_app`) compilado para Web e dispositivos móveis/desktop (`adaptive`), utilizando `Plus Jakarta Sans` e `Roboto` com suporte completo a acentuação PT-BR.
- **Restrições Duráveis:**
  - Todo o texto da interface, instruções biomecânicas, grupos musculares e vídeos demonstrativos devem permanecer 100% em **Português do Brasil (PT-BR)**.
  - Nenhum dado de um `Tenant` (Personal/Academia) pode vazar para outro `Tenant`.
  - O alternador de **Tema Claro / Tema Escuro** (`BotaoAlternarTema`) deve ser preservado e respeitado em qualquer nova superfície ou refatoração visual.

## Brand Commitments

- **Nome da Marca:** PersonalPro (`PERSONALPRO` — Gestão de Treinos & Performance).
- **Tom de Voz:** Profissional, energético, direto, técnico na medida certa (biomecânica e nutrição) e motivador para o aluno.
- **Tipografia Atual:** `Plus Jakarta Sans` (títulos e interface) + `Roboto` (apoio/dados tabulares).

## Evidence on Hand

- **Código e Superfícies Reais Implementadas (`personalpro_app/lib/`):**
  - Autenticação e Login com acesso rápido de demonstração (`lib/screens/auth/login_screen.dart`).
  - Dashboard completo do Personal Trainer (`lib/screens/personal/personal_dashboard_screen.dart`).
  - Ambiente de Execução do Aluno (`lib/screens/aluno/aluno_home_screen.dart`).
  - Painel SaaS SuperAdmin (`lib/screens/superadmin/superadmin_screen.dart`).
  - Gráficos de Evolução Física e Cargas (`lib/widgets/evolucao_charts_widget.dart`), Dieta/Macros/Agenda/Player de Vídeo (`lib/widgets/exercicio_animado_dieta_agenda_widget.dart`), Cobrança PIX (`lib/widgets/pix_modal.dart`) e Sistema de Tema Duplo (`lib/theme.dart`).
- **Dados Reais de Demonstração no Banco (`database/`):**
  - 121 exercícios reais com vídeos do YouTube em PT-BR (`database/migracao_v5_biblioteca_120_exercicios.sql`).
  - Ausência confirmada: Não inventar depoimentos fictícios de clientes, selos de imprensa inexistentes ou integrações bancárias externas além do fluxo PIX implementado.

## Product Principles

1. **Uma Superfície por Vez com Foco Total:** Evoluir e refinar cada jornada (Login, Personal, Aluno, SuperAdmin) individualmente até atingir excelência antes de passar para a próxima.
2. **Zero Fricção Entre Séries:** Na visão do Aluno, toda ação crítica (ver o vídeo de execução, marcar a série concluída, registrar a carga e disparar o cronômetro de descanso) deve exigir no máximo um toque.
3. **Velocidade de Prescrição para o Personal:** Ferramentas densas de trabalho (montagem de fichas de 121 exercícios, cálculo de macros e cobrança) devem priorizar busca instantânea, clareza tabular e feedback imediato.
4. **Paridade Absoluta entre Tema Escuro e Tema Claro:** Toda superfície e componente deve ter contraste impecável e hierarquia clara tanto em `Dark Mode` quanto em `Light Mode`.
