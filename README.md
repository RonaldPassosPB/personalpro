# 🏋️‍♂️ PersonalPro SaaS (Multi-Tenant) — Padrão FightCenter

Sistema completo **SaaS Multi-Tenant** para **Personal Trainers, Consultorias Fitness e Academias de Musculação** (App Mobile Android/iOS + Painel Web).

---

## 📂 Estrutura do Projeto (`C:\Users\ronal\PersonalPro`)

1. **[`database/`](file:///C:/Users/ronal/PersonalPro/database)**
   - [`script_completo.sql`](file:///C:/Users/ronal/PersonalPro/database/script_completo.sql): Modelagem completa SQL Server com as 10 tabelas (`PERSONAIS`, `USUARIOS`, `ALUNOS`, `AVALIACOES_FISICAS`, `EXERCICIOS_BASE`, `FICHAS_TREINO`, `FICHA_EXERCICIOS`, `HISTORICO_TREINOS`, `PAGAMENTOS`, `NOTIFICACOES`), índices de performance e Seeds iniciais (40 exercícios clássicos separados por grupo muscular + 3 perfis prontos para teste).
   - [`backup_rotina.ps1`](file:///C:/Users/ronal/PersonalPro/database/backup_rotina.ps1): Rotina automática de backup do SQL Server com compressão e retenção de 15 dias.
   - [`agendar_backup.ps1`](file:///C:/Users/ronal/PersonalPro/database/agendar_backup.ps1): Script PowerShell para registrar a tarefa diária no Windows Task Scheduler às 03:00 AM.

2. **[`PersonalProAPI/`](file:///C:/Users/ronal/PersonalPro/PersonalProAPI)** (Backend C# .NET 10 Web API + Dapper)
   - Porta padrão: `http://localhost:5250` (`http://0.0.0.0:5250`)
   - Autenticação JWT com Claims (`usuarioId`, `perfil`, `personalId`) + criptografia `BCrypt.Net-Next`
   - Kill-Switch Multi-Tenant imediato ([`AuthController.cs`](file:///C:/Users/ronal/PersonalPro/PersonalProAPI/Controllers/AuthController.cs) e [`TenantKillSwitchMiddleware.cs`](file:///C:/Users/ronal/PersonalPro/PersonalProAPI/Middlewares/TenantKillSwitchMiddleware.cs))
   - Middleware Global de Logs de Erros em arquivo diário ([`ErrorHandlingMiddleware.cs`](file:///C:/Users/ronal/PersonalPro/PersonalProAPI/Middlewares/ErrorHandlingMiddleware.cs) + [`LogService.cs`](file:///C:/Users/ronal/PersonalPro/PersonalProAPI/Services/LogService.cs))
   - Notificações Push com Firebase Admin SDK ([`FcmService.cs`](file:///C:/Users/ronal/PersonalPro/PersonalProAPI/Services/FcmService.cs) + [`NotificacaoService.cs`](file:///C:/Users/ronal/PersonalPro/PersonalProAPI/Services/NotificacaoService.cs))
   - Gerador nativo de payload PIX EMV Copia e Cola + CRC16 ([`PixPayloadService.cs`](file:///C:/Users/ronal/PersonalPro/PersonalProAPI/Services/PixPayloadService.cs))

3. **[`personalpro_app/`](file:///C:/Users/ronal/PersonalPro/personalpro_app)** (Frontend Flutter Android / iOS / Web / Desktop)
   - Tema Esportivo **Dark/Neon Gym** (`#121212` Grafite Escuro, `#00E676` Verde Energia, `#E53935` Vermelho Performance)
   - Separação de ambientes em [`app_config.dart`](file:///C:/Users/ronal/PersonalPro/personalpro_app/lib/config/app_config.dart) (`AppEnvironment.local` vs `AppEnvironment.producao`)
   - Exportação de Ficha de Treino estilizada em PDF ([`ficha_pdf_service.dart`](file:///C:/Users/ronal/PersonalPro/personalpro_app/lib/services/ficha_pdf_service.dart))
   - Integração com WhatsApp 1-clique ([`whatsapp_service.dart`](file:///C:/Users/ronal/PersonalPro/personalpro_app/lib/services/whatsapp_service.dart))
   - QR Code PIX nativo + Copia e Cola ([`pix_modal.dart`](file:///C:/Users/ronal/PersonalPro/personalpro_app/lib/widgets/pix_modal.dart))

---

## 🔑 Credenciais de Demonstração (Prontas no Banco)

| Perfil | E-mail | Senha | Função |
| :--- | :--- | :--- | :--- |
| **3 — SuperAdmin (Dono do SaaS)** | `superadmin@personalpro.com` | `admin123` | Gestão de Personais (Tenants), Receita SaaS, Kill-Switch (`STATUS = 0`) |
| **1 — Personal Trainer** | `personal@personalpro.com` | `admin123` | Gestão de Alunos, Avaliações Físicas, Criador de Fichas A/B/C, PDF, PIX |
| **2 — Aluno** | `aluno1@personalpro.com` | `admin123` | Meus Treinos A/B/C, Modo Execução na Academia, Carga (kg), Cronômetro, PIX |
