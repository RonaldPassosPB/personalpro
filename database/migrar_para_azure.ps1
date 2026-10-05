# ==============================================================================
# Coach Center - Script de Migração Completa para Azure SQL Database
# ==============================================================================
$ErrorActionPreference = "Stop"

# As connection strings vêm de variáveis de ambiente (nunca versionar senhas):
#   $env:PERSONALPRO_LOCAL_CONN = "Server=localhost;Database=PersonalPro;Trusted_Connection=True;TrustServerCertificate=True;"
#   $env:PERSONALPRO_AZURE_CONN = "Server=tcp:<servidor>.database.windows.net,1433;Initial Catalog=<banco>;User Id=<usuario>;Password=<senha>;Encrypt=True;"
$localConnStr = $env:PERSONALPRO_LOCAL_CONN
$azureConnStr = $env:PERSONALPRO_AZURE_CONN
if (-not $localConnStr -or -not $azureConnStr) {
    throw "Defina PERSONALPRO_LOCAL_CONN e PERSONALPRO_AZURE_CONN antes de executar."
}

Write-Output "--- INICIANDO MIGRAÇÃO PARA AZURE SQL (coachcenter-db) ---"

$azureConn = New-Object System.Data.SqlClient.SqlConnection($azureConnStr)
$azureConn.Open()
Write-Output "Conectado ao Azure SQL com sucesso!"

$localConn = New-Object System.Data.SqlClient.SqlConnection($localConnStr)
$localConn.Open()
Write-Output "Conectado ao banco local com sucesso!"

# 1. CRIAR AS TABELAS NO AZURE SQL
$ddlScript = @"
-- 1. PERSONAIS
IF OBJECT_ID('PERSONAIS', 'U') IS NULL
BEGIN
    CREATE TABLE PERSONAIS (
        ID                      INT IDENTITY(1,1)   NOT NULL,
        NOME_PROFISSIONAL       NVARCHAR(300)       NOT NULL,
        CREF                    VARCHAR(30)         NULL,
        CPF_CNPJ                VARCHAR(20)         NULL,
        EMAIL                   VARCHAR(150)        NOT NULL,
        TELEFONE                VARCHAR(20)         NULL,
        CHAVE_PIX               VARCHAR(150)        NULL,
        PLANO                   VARCHAR(30)         NOT NULL DEFAULT ('PRO'),
        STATUS                  BIT                 NOT NULL DEFAULT ((1)),
        VALOR_ASSINATURA        DECIMAL(10,2)       NOT NULL DEFAULT ((99.90)),
        DIA_VENCIMENTO          TINYINT             NOT NULL DEFAULT ((10)),
        ULTIMO_PAGAMENTO_MES    VARCHAR(7)          NULL,
        DATA_CADASTRO           DATETIME            NOT NULL DEFAULT (GETDATE()),
        LOGO_URL                NVARCHAR(MAX)       NULL,
        CONSTRAINT PK_PERSONAIS PRIMARY KEY (ID)
    );
END;

-- 2. USUARIOS
IF OBJECT_ID('USUARIOS', 'U') IS NULL
BEGIN
    CREATE TABLE USUARIOS (
        ID                      INT IDENTITY(1,1)   NOT NULL,
        PERSONAL_ID             INT                 NULL,
        NOME                    NVARCHAR(300)       NOT NULL,
        EMAIL                   VARCHAR(150)        NOT NULL,
        SENHA_HASH              NVARCHAR(512)       NOT NULL,
        PERFIL                  TINYINT             NOT NULL DEFAULT ((2)),
        STATUS                  BIT                 NOT NULL DEFAULT ((1)),
        FCM_TOKEN               NVARCHAR(1000)      NULL,
        DATA_CADASTRO           DATETIME            NOT NULL DEFAULT (GETDATE()),
        CODIGO_RECUPERACAO      VARCHAR(10)         NULL,
        RECUPERACAO_EXPIRACAO   DATETIME            NULL,
        CONSTRAINT PK_USUARIOS PRIMARY KEY (ID),
        CONSTRAINT FK_USUARIOS_PERSONAL FOREIGN KEY (PERSONAL_ID) REFERENCES PERSONAIS(ID),
        CONSTRAINT UQ_USUARIOS_EMAIL UNIQUE (EMAIL)
    );
END;

-- 3. ALUNOS
IF OBJECT_ID('ALUNOS', 'U') IS NULL
BEGIN
    CREATE TABLE ALUNOS (
        ID                      INT IDENTITY(1,1)   NOT NULL,
        USUARIO_ID              INT                 NOT NULL,
        PERSONAL_ID             INT                 NOT NULL,
        CPF                     VARCHAR(14)         NULL,
        TELEFONE                VARCHAR(20)         NULL,
        DATA_NASCIMENTO         DATE                NULL,
        OBJETIVO                NVARCHAR(120)       NOT NULL DEFAULT ('Hipertrofia'),
        FOTO_URL                NVARCHAR(MAX)       NULL,
        VALOR_MENSALIDADE       DECIMAL(10,2)       NOT NULL DEFAULT ((150.00)),
        DIA_VENCIMENTO          TINYINT             NOT NULL DEFAULT ((10)),
        DATA_CADASTRO           DATETIME            NOT NULL DEFAULT (GETDATE()),
        CONSTRAINT PK_ALUNOS PRIMARY KEY (ID),
        CONSTRAINT FK_ALUNOS_USUARIO FOREIGN KEY (USUARIO_ID) REFERENCES USUARIOS(ID),
        CONSTRAINT FK_ALUNOS_PERSONAL FOREIGN KEY (PERSONAL_ID) REFERENCES PERSONAIS(ID)
    );
END;

-- 4. AVALIACOES_FISICAS
IF OBJECT_ID('AVALIACOES_FISICAS', 'U') IS NULL
BEGIN
    CREATE TABLE AVALIACOES_FISICAS (
        ID                      INT IDENTITY(1,1)   NOT NULL,
        ALUNO_ID                INT                 NOT NULL,
        PERSONAL_ID             INT                 NOT NULL,
        DATA_AVALIACAO          DATE                NOT NULL DEFAULT (CONVERT(DATE, GETDATE())),
        PESO                    DECIMAL(5,2)        NOT NULL,
        ALTURA                  DECIMAL(4,2)        NOT NULL,
        PERCENTUAL_GORDURA      DECIMAL(5,2)        NULL,
        MEDIDAS_JSON            NVARCHAR(MAX)       NULL,
        RESTRICOES_LESOES       NVARCHAR(1000)      NULL,
        OBSERVACOES             NVARCHAR(2000)      NULL,
        FOTO_FRENTE_URL         NVARCHAR(MAX)       NULL,
        FOTO_LADO_COSTAS_URL    NVARCHAR(MAX)       NULL,
        CONSTRAINT PK_AVALIACOES_FISICAS PRIMARY KEY (ID),
        CONSTRAINT FK_AVAL_ALUNO FOREIGN KEY (ALUNO_ID) REFERENCES ALUNOS(ID),
        CONSTRAINT FK_AVAL_PERSONAL FOREIGN KEY (PERSONAL_ID) REFERENCES PERSONAIS(ID)
    );
END;

-- 5. EXERCICIOS_BASE
IF OBJECT_ID('EXERCICIOS_BASE', 'U') IS NULL
BEGIN
    CREATE TABLE EXERCICIOS_BASE (
        ID                      INT IDENTITY(1,1)   NOT NULL,
        PERSONAL_ID             INT                 NULL,
        NOME                    NVARCHAR(300)       NOT NULL,
        GRUPO_MUSCULAR          NVARCHAR(120)       NOT NULL,
        VIDEO_URL               NVARCHAR(1000)      NULL,
        INSTRUCOES_EXECUCAO     NVARCHAR(1000)      NULL,
        CONSTRAINT PK_EXERCICIOS_BASE PRIMARY KEY (ID),
        CONSTRAINT FK_EXBASE_PERSONAL FOREIGN KEY (PERSONAL_ID) REFERENCES PERSONAIS(ID)
    );
END;

-- 6. FICHAS_TREINO
IF OBJECT_ID('FICHAS_TREINO', 'U') IS NULL
BEGIN
    CREATE TABLE FICHAS_TREINO (
        ID                      INT IDENTITY(1,1)   NOT NULL,
        ALUNO_ID                INT                 NOT NULL,
        PERSONAL_ID             INT                 NOT NULL,
        NOME_DIVISAO            NVARCHAR(240)       NOT NULL,
        DESCRICAO               NVARCHAR(1000)      NULL,
        ATIVA                   BIT                 NOT NULL DEFAULT ((1)),
        DATA_CRIACAO            DATETIME            NOT NULL DEFAULT (GETDATE()),
        DATA_VALIDADE           DATE                NULL,
        CONSTRAINT PK_FICHAS_TREINO PRIMARY KEY (ID),
        CONSTRAINT FK_FICHA_ALUNO FOREIGN KEY (ALUNO_ID) REFERENCES ALUNOS(ID),
        CONSTRAINT FK_FICHA_PERSONAL FOREIGN KEY (PERSONAL_ID) REFERENCES PERSONAIS(ID)
    );
END;

-- 7. FICHA_EXERCICIOS
IF OBJECT_ID('FICHA_EXERCICIOS', 'U') IS NULL
BEGIN
    CREATE TABLE FICHA_EXERCICIOS (
        ID                      INT IDENTITY(1,1)   NOT NULL,
        FICHA_ID                INT                 NOT NULL,
        NOME_EXERCICIO          NVARCHAR(300)       NOT NULL,
        GRUPO_MUSCULAR          NVARCHAR(120)       NOT NULL,
        SERIES                  INT                 NOT NULL DEFAULT ((4)),
        REPETICOES              NVARCHAR(80)        NOT NULL DEFAULT ('10 a 12'),
        CARGA_KG                DECIMAL(6,2)        NOT NULL DEFAULT ((0)),
        DESCANSO_SEGUNDOS       INT                 NOT NULL DEFAULT ((60)),
        OBSERVACAO_TECNICA      NVARCHAR(600)       NULL,
        VIDEO_URL               NVARCHAR(1000)      NULL,
        ORDEM                   INT                 NOT NULL DEFAULT ((1)),
        CONSTRAINT PK_FICHA_EXERCICIOS PRIMARY KEY (ID),
        CONSTRAINT FK_FICHAEX_FICHA FOREIGN KEY (FICHA_ID) REFERENCES FICHAS_TREINO(ID) ON DELETE CASCADE
    );
END;

-- 8. HISTORICO_TREINOS
IF OBJECT_ID('HISTORICO_TREINOS', 'U') IS NULL
BEGIN
    CREATE TABLE HISTORICO_TREINOS (
        ID                      INT IDENTITY(1,1)   NOT NULL,
        ALUNO_ID                INT                 NOT NULL,
        PERSONAL_ID             INT                 NOT NULL,
        FICHA_ID                INT                 NULL,
        NOME_TREINO             NVARCHAR(240)       NOT NULL,
        DATA_HORA               DATETIME            NOT NULL DEFAULT (GETDATE()),
        DURACAO_MINUTOS         INT                 NOT NULL DEFAULT ((45)),
        OBSERVACAO_ALUNO        NVARCHAR(1000)      NULL,
        CONSTRAINT PK_HISTORICO_TREINOS PRIMARY KEY (ID),
        CONSTRAINT FK_HIST_ALUNO FOREIGN KEY (ALUNO_ID) REFERENCES ALUNOS(ID),
        CONSTRAINT FK_HIST_PERSONAL FOREIGN KEY (PERSONAL_ID) REFERENCES PERSONAIS(ID),
        CONSTRAINT FK_HIST_FICHA FOREIGN KEY (FICHA_ID) REFERENCES FICHAS_TREINO(ID) ON DELETE SET NULL
    );
END;

-- 9. PAGAMENTOS
IF OBJECT_ID('PAGAMENTOS', 'U') IS NULL
BEGIN
    CREATE TABLE PAGAMENTOS (
        ID                      INT IDENTITY(1,1)   NOT NULL,
        ALUNO_ID                INT                 NOT NULL,
        PERSONAL_ID             INT                 NOT NULL,
        MES_REFERENCIA          VARCHAR(7)          NOT NULL,
        VALOR                   DECIMAL(10,2)       NOT NULL,
        DATA_VENCIMENTO         DATE                NOT NULL,
        DATA_PAGAMENTO          DATE                NULL,
        FORMA_PAGAMENTO         NVARCHAR(80)        NULL,
        STATUS                  NVARCHAR(40)        NOT NULL DEFAULT ('PENDENTE'),
        OBSERVACAO              NVARCHAR(600)       NULL,
        PIX_COPIA_E_COLA        NVARCHAR(MAX)       NULL,
        CONSTRAINT PK_PAGAMENTOS PRIMARY KEY (ID),
        CONSTRAINT FK_PAG_ALUNO FOREIGN KEY (ALUNO_ID) REFERENCES ALUNOS(ID),
        CONSTRAINT FK_PAG_PERSONAL FOREIGN KEY (PERSONAL_ID) REFERENCES PERSONAIS(ID)
    );
END;

-- 10. NOTIFICACOES
IF OBJECT_ID('NOTIFICACOES', 'U') IS NULL
BEGIN
    CREATE TABLE NOTIFICACOES (
        ID                      INT IDENTITY(1,1)   NOT NULL,
        PERSONAL_ID             INT                 NULL,
        USUARIO_ID              INT                 NOT NULL,
        TITULO                  NVARCHAR(300)       NOT NULL,
        MENSAGEM                NVARCHAR(1000)      NOT NULL,
        TIPO                    VARCHAR(30)         NOT NULL DEFAULT ('GERAL'),
        LIDA                    BIT                 NOT NULL DEFAULT ((0)),
        DATA_CRIACAO            DATETIME            NOT NULL DEFAULT (GETDATE()),
        CONSTRAINT PK_NOTIFICACOES PRIMARY KEY (ID),
        CONSTRAINT FK_NOTIF_PERSONAL FOREIGN KEY (PERSONAL_ID) REFERENCES PERSONAIS(ID),
        CONSTRAINT FK_NOTIF_USUARIO FOREIGN KEY (USUARIO_ID) REFERENCES USUARIOS(ID)
    );
END;

-- 11. PROGRESSAO_CARGAS
IF OBJECT_ID('PROGRESSAO_CARGAS', 'U') IS NULL
BEGIN
    CREATE TABLE PROGRESSAO_CARGAS (
        ID                      INT IDENTITY(1,1)   NOT NULL,
        ALUNO_ID                INT                 NOT NULL,
        PERSONAL_ID             INT                 NOT NULL,
        EXERCICIO_ID            INT                 NULL,
        NOME_EXERCICIO          NVARCHAR(300)       NOT NULL,
        GRUPO_MUSCULAR          NVARCHAR(120)       NULL,
        CARGA_KG                DECIMAL(6,2)        NOT NULL,
        DATA_REGISTRO           DATETIME            NOT NULL DEFAULT (GETDATE()),
        CONSTRAINT PK_PROGRESSAO_CARGAS PRIMARY KEY (ID),
        CONSTRAINT FK_PROG_ALUNO FOREIGN KEY (ALUNO_ID) REFERENCES ALUNOS(ID),
        CONSTRAINT FK_PROG_PERSONAL FOREIGN KEY (PERSONAL_ID) REFERENCES PERSONAIS(ID)
    );
END;

-- 12. AGENDA_AULAS
IF OBJECT_ID('AGENDA_AULAS', 'U') IS NULL
BEGIN
    CREATE TABLE AGENDA_AULAS (
        ID                      INT IDENTITY(1,1)   NOT NULL,
        TENANT_ID               INT                 NOT NULL,
        PERSONAL_ID             INT                 NOT NULL,
        ALUNO_ID                INT                 NOT NULL,
        DATA_HORA_INICIO        DATETIME            NOT NULL,
        DURACAO_MINUTOS         INT                 NULL DEFAULT ((60)),
        TIPO_AULA               NVARCHAR(100)       NULL,
        TITULO_TREINO           NVARCHAR(300)       NULL,
        LOCAL_ACADEMIA          NVARCHAR(300)       NULL,
        STATUS                  NVARCHAR(60)        NULL DEFAULT ('AGENDADA'),
        DATA_CRIACAO            DATETIME            NULL DEFAULT (GETDATE()),
        CONSTRAINT PK_AGENDA_AULAS PRIMARY KEY (ID)
    );
END;

-- 13. PLANOS_ALIMENTARES
IF OBJECT_ID('PLANOS_ALIMENTARES', 'U') IS NULL
BEGIN
    CREATE TABLE PLANOS_ALIMENTARES (
        ID                      INT IDENTITY(1,1)   NOT NULL,
        TENANT_ID               INT                 NOT NULL,
        PERSONAL_ID             INT                 NOT NULL,
        ALUNO_ID                INT                 NOT NULL,
        TITULO                  NVARCHAR(300)       NULL,
        OBJETIVO                NVARCHAR(100)       NULL,
        PESO_BASE_KG            DECIMAL(6,2)        NULL,
        ALTURA_CM               DECIMAL(6,2)        NULL,
        IDADE                   INT                 NULL,
        SEXO                    CHAR(1)             NULL,
        FATOR_ATIVIDADE         DECIMAL(4,2)        NULL,
        TMB_KCAL                INT                 NULL,
        GET_KCAL                INT                 NULL,
        META_KCAL               INT                 NULL,
        PROTEINA_G              INT                 NULL,
        CARBOIDRATO_G           INT                 NULL,
        GORDURA_G               INT                 NULL,
        AGUA_LITROS             DECIMAL(4,2)        NULL,
        OBSERVACOES             NVARCHAR(MAX)       NULL,
        ATIVO                   BIT                 NULL DEFAULT ((1)),
        DATA_CRIACAO            DATETIME            NULL DEFAULT (GETDATE()),
        CONSTRAINT PK_PLANOS_ALIMENTARES PRIMARY KEY (ID)
    );
END;

-- 14. REFEICOES_PLANO
IF OBJECT_ID('REFEICOES_PLANO', 'U') IS NULL
BEGIN
    CREATE TABLE REFEICOES_PLANO (
        ID                      INT IDENTITY(1,1)   NOT NULL,
        PLANO_ID                INT                 NOT NULL,
        HORARIO                 NVARCHAR(20)        NULL,
        NOME_REFEICAO           NVARCHAR(200)       NULL,
        ALIMENTOS_DESCRICAO     NVARCHAR(MAX)       NULL,
        SUBSTITUICOES           NVARCHAR(MAX)       NULL,
        KCAL_ESTIMADA           INT                 NULL,
        PROTEINA_G              INT                 NULL,
        CARBO_G                 INT                 NULL,
        GORDURA_G               INT                 NULL,
        ORDEM                   INT                 NULL DEFAULT ((0)),
        CONSTRAINT PK_REFEICOES_PLANO PRIMARY KEY (ID)
    );
END;

-- ÍNDICES DE PERFORMANCE MULTI-TENANT
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_USUARIOS_PERSONAL')
    CREATE NONCLUSTERED INDEX IX_USUARIOS_PERSONAL ON USUARIOS(PERSONAL_ID, PERFIL, STATUS);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ALUNOS_PERSONAL')
    CREATE NONCLUSTERED INDEX IX_ALUNOS_PERSONAL ON ALUNOS(PERSONAL_ID, USUARIO_ID);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FICHAS_ALUNO_PERSONAL')
    CREATE NONCLUSTERED INDEX IX_FICHAS_ALUNO_PERSONAL ON FICHAS_TREINO(PERSONAL_ID, ALUNO_ID, ATIVA);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_HISTORICO_PERSONAL_DATA')
    CREATE NONCLUSTERED INDEX IX_HISTORICO_PERSONAL_DATA ON HISTORICO_TREINOS(PERSONAL_ID, ALUNO_ID, DATA_HORA DESC);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_PAGAMENTOS_PERSONAL_MES')
    CREATE NONCLUSTERED INDEX IX_PAGAMENTOS_PERSONAL_MES ON PAGAMENTOS(PERSONAL_ID, MES_REFERENCIA, STATUS);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_NOTIFICACOES_USUARIO')
    CREATE NONCLUSTERED INDEX IX_NOTIFICACOES_USUARIO ON NOTIFICACOES(USUARIO_ID, LIDA, DATA_CRIACAO DESC);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_PROGRESSAO_ALUNO_EXERCICIO')
    CREATE NONCLUSTERED INDEX IX_PROGRESSAO_ALUNO_EXERCICIO ON PROGRESSAO_CARGAS(ALUNO_ID, NOME_EXERCICIO, DATA_REGISTRO DESC);
"@

Write-Output "Criando tabelas e índices no Azure SQL..."
$cmd = $azureConn.CreateCommand()
$cmd.CommandTimeout = 120
$cmd.CommandText = $ddlScript
$cmd.ExecuteNonQuery()
Write-Output "Tabelas e índices criados no Azure com sucesso!"

# 2. COPIAR DADOS DAS 14 TABELAS
$tabelasEmOrdem = @(
    'PERSONAIS',
    'USUARIOS',
    'ALUNOS',
    'AVALIACOES_FISICAS',
    'EXERCICIOS_BASE',
    'FICHAS_TREINO',
    'FICHA_EXERCICIOS',
    'HISTORICO_TREINOS',
    'PAGAMENTOS',
    'NOTIFICACOES',
    'PROGRESSAO_CARGAS',
    'AGENDA_AULAS',
    'PLANOS_ALIMENTARES',
    'REFEICOES_PLANO'
)

Write-Output "`n--- COPIANDO DADOS DO BANCO LOCAL PARA AZURE SQL ---"
foreach ($tabela in $tabelasEmOrdem) {
    # Ler dados locais
    $selectCmd = $localConn.CreateCommand()
    $selectCmd.CommandText = "SELECT * FROM [$tabela]"
    $reader = $selectCmd.ExecuteReader()
    
    $dt = New-Object System.Data.DataTable
    $dt.Load($reader)
    $reader.Close()
    
    $qtd = $dt.Rows.Count
    if ($qtd -gt 0) {
        Write-Output "Migrando tabela $tabela ($qtd registros)..."
        
        $bulkCopy = New-Object System.Data.SqlClient.SqlBulkCopy(
            $azureConn,
            [System.Data.SqlClient.SqlBulkCopyOptions]::KeepIdentity,
            $null
        )
        $bulkCopy.DestinationTableName = "[$tabela]"
        $bulkCopy.BulkCopyTimeout = 120
        
        foreach ($col in $dt.Columns) {
            [void]$bulkCopy.ColumnMappings.Add($col.ColumnName, $col.ColumnName)
        }
        
        $bulkCopy.WriteToServer($dt)
        $bulkCopy.Close()
        Write-Output "  -> $($tabela): $qtd registros migrados!"
    } else {
        Write-Output "  -> $tabela está vazia (0 registros)."
    }
}

# 3. VERIFICAÇÃO FINAL NO AZURE SQL
Write-Output "`n--- CONFERÊNCIA DE REGISTROS NO AZURE SQL ---"
foreach ($tabela in $tabelasEmOrdem) {
    $checkCmd = $azureConn.CreateCommand()
    $checkCmd.CommandText = "SELECT COUNT(*) FROM [$tabela]"
    $count = $checkCmd.ExecuteScalar()
    Write-Output "Azure SQL [$tabela] => $count registros"
}

$azureConn.Close()
$localConn.Close()
Write-Output "`n=== MIGRAÇÃO CONCLUÍDA COM 100% DE SUCESSO! ==="
