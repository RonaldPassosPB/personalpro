# 🏋️‍♂️ PersonalPro SaaS (Multi-Tenant) — Padrão FightCenter

Sistema completo **SaaS Multi-Tenant** para **Personal Trainers, Consultorias Fitness e Academias de Musculação** (App Mobile Android/iOS + Painel Web).

---

## 🌐 Demonstração

Aplicação no ar: https://coachcenter-bxdugvdgg6akhxhh.canadacentral-01.azurewebsites.net/

---

## 📂 Estrutura do Projeto

1. **[`database/`](database)**
   - [`script_completo.sql`](database/script_completo.sql): Modelagem completa SQL Server com as 10 tabelas (`PERSONAIS`, `USUARIOS`, `ALUNOS`, `AVALIACOES_FISICAS`, `EXERCICIOS_BASE`, `FICHAS_TREINO`, `FICHA_EXERCICIOS`, `HISTORICO_TREINOS`, `PAGAMENTOS`, `NOTIFICACOES`), índices de performance e Seeds iniciais (40 exercícios clássicos separados por grupo muscular + 3 perfis prontos para teste).
   - [`backup_rotina.ps1`](database/backup_rotina.ps1): Rotina automática de backup do SQL Server com compressão e retenção de 15 dias.
   - [`agendar_backup.ps1`](database/agendar_backup.ps1): Script PowerShell para registrar a tarefa diária no Windows Task Scheduler às 03:00 AM.

2. **[`PersonalProAPI/`](PersonalProAPI)** (Backend C# .NET 10 Web API + Dapper)
   - Porta padrão: `http://localhost:5250` (`http://0.0.0.0:5250`)
   - Autenticação JWT com Claims (`usuarioId`, `perfil`, `personalId`) + criptografia `BCrypt.Net-Next`
   - Kill-Switch Multi-Tenant imediato ([`AuthController.cs`](PersonalProAPI/Controllers/AuthController.cs) e [`TenantKillSwitchMiddleware.cs`](PersonalProAPI/Middlewares/TenantKillSwitchMiddleware.cs))
   - Middleware Global de Logs de Erros em arquivo diário ([`ErrorHandlingMiddleware.cs`](PersonalProAPI/Middlewares/ErrorHandlingMiddleware.cs) + [`LogService.cs`](PersonalProAPI/Services/LogService.cs))
   - Notificações Push com Firebase Admin SDK ([`FcmService.cs`](PersonalProAPI/Services/FcmService.cs) + [`NotificacaoService.cs`](PersonalProAPI/Services/NotificacaoService.cs))
   - Gerador nativo de payload PIX EMV Copia e Cola + CRC16 ([`PixPayloadService.cs`](PersonalProAPI/Services/PixPayloadService.cs))

3. **[`personalpro_app/`](personalpro_app)** (Frontend Flutter Android / iOS / Web / Desktop)
   - Tema Esportivo **Dark/Neon Gym** (`#121212` Grafite Escuro, `#00E676` Verde Energia, `#E53935` Vermelho Performance)
   - Separação de ambientes em [`app_config.dart`](personalpro_app/lib/config/app_config.dart) (`AppEnvironment.local` vs `AppEnvironment.producao`)
   - Exportação de Ficha de Treino estilizada em PDF ([`ficha_pdf_service.dart`](personalpro_app/lib/services/ficha_pdf_service.dart))
   - Integração com WhatsApp 1-clique ([`whatsapp_service.dart`](personalpro_app/lib/services/whatsapp_service.dart))
   - QR Code PIX nativo + Copia e Cola ([`pix_modal.dart`](personalpro_app/lib/widgets/pix_modal.dart))

---

## ⚙️ Configuração

Nenhum segredo é versionado. O `appsettings.json` traz apenas a estrutura; os valores reais vêm de fora do repositório:

- **Produção (Azure App Service):** *Configuration* → connection string `PersonalPro` (tipo SQLAzure) e application setting `Jwt__Key`.
- **Desenvolvimento local:** crie `PersonalProAPI/appsettings.Development.json` (já está no `.gitignore`):

```json
{
  "ConnectionStrings": {
    "PersonalPro": "Server=localhost;Database=PersonalPro;Trusted_Connection=True;TrustServerCertificate=True;"
  },
  "Jwt": { "Key": "<chave aleatória com pelo menos 32 caracteres>" }
}
```

Os usuários de demonstração do `script_completo.sql` existem apenas para o ambiente local.
