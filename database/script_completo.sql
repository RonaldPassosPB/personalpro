-- ====================================================================================
-- PERSONALPRO — Script Completo do Banco de Dados (Arquitetura Multi-Tenant / SaaS)
-- Padrão FightCenter | SQL Server
-- ====================================================================================

-- ─── 1. CRIAR BANCO DE DADOS ────────────────────────────────────────────────────────
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'PersonalPro')
BEGIN
    CREATE DATABASE PersonalPro
        COLLATE Latin1_General_CI_AI;
END
GO

USE PersonalPro;
GO

-- ─── 2. TABELA DE PERSONAIS / CONSULTORIAS (TENANTS DO SAAS) ────────────────────────
IF OBJECT_ID('PERSONAIS', 'U') IS NULL
BEGIN
    CREATE TABLE PERSONAIS (
        ID                      INT IDENTITY(1,1)   NOT NULL,
        NOME_PROFISSIONAL       NVARCHAR(150)       NOT NULL,
        CREF                    VARCHAR(30)         NULL,
        CPF_CNPJ                VARCHAR(20)         NULL,
        EMAIL                   VARCHAR(150)        NOT NULL,
        TELEFONE                VARCHAR(20)         NULL,
        CHAVE_PIX               VARCHAR(150)        NULL,
        PLANO                   VARCHAR(30)         NOT NULL DEFAULT 'PRO', -- 'BASICO', 'PRO', 'ELITE'
        STATUS                  BIT                 NOT NULL DEFAULT 1,     -- 1 = Ativo, 0 = Bloqueado (Kill-Switch)
        VALOR_ASSINATURA        DECIMAL(10,2)       NOT NULL DEFAULT 99.90,
        DIA_VENCIMENTO          TINYINT             NOT NULL DEFAULT 10,
        ULTIMO_PAGAMENTO_MES    VARCHAR(7)          NULL,                   -- Ex: '2026-09' (EM DIA quando igual ao mês atual)
        DATA_CADASTRO           DATETIME            NOT NULL DEFAULT GETDATE(),
        CONSTRAINT PK_PERSONAIS PRIMARY KEY (ID)
    );
END
GO

-- ─── 3. TABELA DE USUÁRIOS (AUTENTICAÇÃO & PERFIS) ──────────────────────────────────
-- PERFIL: 1 = Personal Trainer | 2 = Aluno | 3 = SuperAdmin (Dono do SaaS)
IF OBJECT_ID('USUARIOS', 'U') IS NULL
BEGIN
    CREATE TABLE USUARIOS (
        ID                      INT IDENTITY(1,1)   NOT NULL,
        PERSONAL_ID             INT                 NULL, -- NULL para SuperAdmin
        NOME                    NVARCHAR(150)       NOT NULL,
        EMAIL                   VARCHAR(150)        NOT NULL,
        SENHA_HASH              NVARCHAR(256)       NOT NULL,
        PERFIL                  TINYINT             NOT NULL DEFAULT 2, -- 1=Personal, 2=Aluno, 3=SuperAdmin
        STATUS                  BIT                 NOT NULL DEFAULT 1,
        FCM_TOKEN               NVARCHAR(500)       NULL,
        DATA_CADASTRO           DATETIME            NOT NULL DEFAULT GETDATE(),
        CONSTRAINT PK_USUARIOS PRIMARY KEY (ID),
        CONSTRAINT FK_USUARIOS_PERSONAL FOREIGN KEY (PERSONAL_ID) REFERENCES PERSONAIS(ID),
        CONSTRAINT UQ_USUARIOS_EMAIL UNIQUE (EMAIL)
    );
END
GO

-- ─── 4. TABELA DE ALUNOS ────────────────────────────────────────────────────────────
IF OBJECT_ID('ALUNOS', 'U') IS NULL
BEGIN
    CREATE TABLE ALUNOS (
        ID                      INT IDENTITY(1,1)   NOT NULL,
        USUARIO_ID              INT                 NOT NULL,
        PERSONAL_ID             INT                 NOT NULL,
        CPF                     VARCHAR(14)         NULL,
        TELEFONE                VARCHAR(20)         NULL,
        DATA_NASCIMENTO         DATE                NULL,
        OBJETIVO                NVARCHAR(60)        NOT NULL DEFAULT 'Hipertrofia', -- Hipertrofia, Emagrecimento, Condicionamento, Força
        FOTO_URL                NVARCHAR(500)       NULL,
        VALOR_MENSALIDADE       DECIMAL(10,2)       NOT NULL DEFAULT 150.00,
        DIA_VENCIMENTO          TINYINT             NOT NULL DEFAULT 10,
        DATA_CADASTRO           DATETIME            NOT NULL DEFAULT GETDATE(),
        CONSTRAINT PK_ALUNOS PRIMARY KEY (ID),
        CONSTRAINT FK_ALUNOS_USUARIO FOREIGN KEY (USUARIO_ID) REFERENCES USUARIOS(ID),
        CONSTRAINT FK_ALUNOS_PERSONAL FOREIGN KEY (PERSONAL_ID) REFERENCES PERSONAIS(ID)
    );
END
GO

-- ─── 5. TABELA DE AVALIAÇÕES FÍSICAS & MEDIDAS (ANAMNESE) ───────────────────────────
IF OBJECT_ID('AVALIACOES_FISICAS', 'U') IS NULL
BEGIN
    CREATE TABLE AVALIACOES_FISICAS (
        ID                      INT IDENTITY(1,1)   NOT NULL,
        ALUNO_ID                INT                 NOT NULL,
        PERSONAL_ID             INT                 NOT NULL,
        DATA_AVALIACAO          DATE                NOT NULL DEFAULT CAST(GETDATE() AS DATE),
        PESO                    DECIMAL(5,2)        NOT NULL,
        ALTURA                  DECIMAL(4,2)        NOT NULL,
        PERCENTUAL_GORDURA      DECIMAL(5,2)        NULL,
        MEDIDAS_JSON            NVARCHAR(MAX)       NULL, -- JSON com bracoDireito, bracoEsquerdo, peitoral, cintura, abdomen, quadril, coxaDireita, coxaEsquerda, panturrilha
        RESTRICOES_LESOES       NVARCHAR(500)       NULL,
        OBSERVACOES             NVARCHAR(1000)      NULL,
        CONSTRAINT PK_AVALIACOES_FISICAS PRIMARY KEY (ID),
        CONSTRAINT FK_AVAL_ALUNO FOREIGN KEY (ALUNO_ID) REFERENCES ALUNOS(ID),
        CONSTRAINT FK_AVAL_PERSONAL FOREIGN KEY (PERSONAL_ID) REFERENCES PERSONAIS(ID)
    );
END
GO

-- ─── 6. TABELA DE EXERCÍCIOS BASE (BIBLIOTECA GLOBAL + CUSTOM DO PERSONAL) ──────────
IF OBJECT_ID('EXERCICIOS_BASE', 'U') IS NULL
BEGIN
    CREATE TABLE EXERCICIOS_BASE (
        ID                      INT IDENTITY(1,1)   NOT NULL,
        PERSONAL_ID             INT                 NULL, -- NULL para Biblioteca Global (40 exercícios clássicos)
        NOME                    NVARCHAR(150)       NOT NULL,
        GRUPO_MUSCULAR          NVARCHAR(60)        NOT NULL, -- Peito, Costas, Pernas, Ombros, Bíceps, Tríceps, Abdômen
        VIDEO_URL               NVARCHAR(500)       NULL,
        CONSTRAINT PK_EXERCICIOS_BASE PRIMARY KEY (ID),
        CONSTRAINT FK_EXBASE_PERSONAL FOREIGN KEY (PERSONAL_ID) REFERENCES PERSONAIS(ID)
    );
END
GO

-- ─── 7. TABELA DE FICHAS DE TREINO (DIVISÕES A, B, C, D, E) ─────────────────────────
IF OBJECT_ID('FICHAS_TREINO', 'U') IS NULL
BEGIN
    CREATE TABLE FICHAS_TREINO (
        ID                      INT IDENTITY(1,1)   NOT NULL,
        ALUNO_ID                INT                 NOT NULL,
        PERSONAL_ID             INT                 NOT NULL,
        NOME_DIVISAO            NVARCHAR(120)       NOT NULL, -- Ex: 'Treino A - Peito, Ombros e Tríceps'
        DESCRICAO               NVARCHAR(500)       NULL,
        ATIVA                   BIT                 NOT NULL DEFAULT 1,
        DATA_CRIACAO            DATETIME            NOT NULL DEFAULT GETDATE(),
        DATA_VALIDADE           DATE                NULL,
        CONSTRAINT PK_FICHAS_TREINO PRIMARY KEY (ID),
        CONSTRAINT FK_FICHA_ALUNO FOREIGN KEY (ALUNO_ID) REFERENCES ALUNOS(ID),
        CONSTRAINT FK_FICHA_PERSONAL FOREIGN KEY (PERSONAL_ID) REFERENCES PERSONAIS(ID)
    );
END
GO

-- ─── 8. TABELA DE EXERCÍCIOS DA FICHA ───────────────────────────────────────────────
IF OBJECT_ID('FICHA_EXERCICIOS', 'U') IS NULL
BEGIN
    CREATE TABLE FICHA_EXERCICIOS (
        ID                      INT IDENTITY(1,1)   NOT NULL,
        FICHA_ID                INT                 NOT NULL,
        NOME_EXERCICIO          NVARCHAR(150)       NOT NULL,
        GRUPO_MUSCULAR          NVARCHAR(60)        NOT NULL,
        SERIES                  INT                 NOT NULL DEFAULT 4,
        REPETICOES              NVARCHAR(40)        NOT NULL DEFAULT '10 a 12',
        CARGA_KG                DECIMAL(6,2)        NOT NULL DEFAULT 0,
        DESCANSO_SEGUNDOS       INT                 NOT NULL DEFAULT 60,
        OBSERVACAO_TECNICA      NVARCHAR(300)       NULL, -- Ex: 'Drop-set na última série', 'Cadência 3010'
        VIDEO_URL               NVARCHAR(500)       NULL,
        ORDEM                   INT                 NOT NULL DEFAULT 1,
        CONSTRAINT PK_FICHA_EXERCICIOS PRIMARY KEY (ID),
        CONSTRAINT FK_FICHAEX_FICHA FOREIGN KEY (FICHA_ID) REFERENCES FICHAS_TREINO(ID) ON DELETE CASCADE
    );
END
GO

-- ─── 9. TABELA DE HISTÓRICO DE TREINOS (FREQUÊNCIA / EXECUÇÃO) ──────────────────────
IF OBJECT_ID('HISTORICO_TREINOS', 'U') IS NULL
BEGIN
    CREATE TABLE HISTORICO_TREINOS (
        ID                      INT IDENTITY(1,1)   NOT NULL,
        ALUNO_ID                INT                 NOT NULL,
        PERSONAL_ID             INT                 NOT NULL,
        FICHA_ID                INT                 NULL,
        NOME_TREINO             NVARCHAR(120)       NOT NULL,
        DATA_HORA               DATETIME            NOT NULL DEFAULT GETDATE(),
        DURACAO_MINUTOS         INT                 NOT NULL DEFAULT 45,
        OBSERVACAO_ALUNO        NVARCHAR(500)       NULL,
        CONSTRAINT PK_HISTORICO_TREINOS PRIMARY KEY (ID),
        CONSTRAINT FK_HIST_ALUNO FOREIGN KEY (ALUNO_ID) REFERENCES ALUNOS(ID),
        CONSTRAINT FK_HIST_PERSONAL FOREIGN KEY (PERSONAL_ID) REFERENCES PERSONAIS(ID),
        CONSTRAINT FK_HIST_FICHA FOREIGN KEY (FICHA_ID) REFERENCES FICHAS_TREINO(ID) ON DELETE SET NULL
    );
END
GO

-- ─── 10. TABELA DE PAGAMENTOS (MENSALIDADES DO ALUNO PARA O PERSONAL) ───────────────
IF OBJECT_ID('PAGAMENTOS', 'U') IS NULL
BEGIN
    CREATE TABLE PAGAMENTOS (
        ID                      INT IDENTITY(1,1)   NOT NULL,
        ALUNO_ID                INT                 NOT NULL,
        PERSONAL_ID             INT                 NOT NULL,
        MES_REFERENCIA          VARCHAR(7)          NOT NULL, -- Ex: '2026-09'
        VALOR                   DECIMAL(10,2)       NOT NULL,
        DATA_VENCIMENTO         DATE                NOT NULL,
        DATA_PAGAMENTO          DATE                NULL,
        FORMA_PAGAMENTO         NVARCHAR(40)        NULL,     -- 'PIX', 'Cartão', 'Dinheiro', 'Transferência'
        STATUS                  NVARCHAR(20)        NOT NULL DEFAULT 'PENDENTE', -- 'PENDENTE', 'PAGO', 'ATRASADO'
        OBSERVACAO              NVARCHAR(300)       NULL,
        PIX_COPIA_E_COLA        NVARCHAR(MAX)       NULL,
        CONSTRAINT PK_PAGAMENTOS PRIMARY KEY (ID),
        CONSTRAINT FK_PAG_ALUNO FOREIGN KEY (ALUNO_ID) REFERENCES ALUNOS(ID),
        CONSTRAINT FK_PAG_PERSONAL FOREIGN KEY (PERSONAL_ID) REFERENCES PERSONAIS(ID)
    );
END
GO

-- ─── 11. TABELA DE NOTIFICAÇÕES (IN-APP + PUSH FCM) ─────────────────────────────────
IF OBJECT_ID('NOTIFICACOES', 'U') IS NULL
BEGIN
    CREATE TABLE NOTIFICACOES (
        ID                      INT IDENTITY(1,1)   NOT NULL,
        PERSONAL_ID             INT                 NULL,
        USUARIO_ID              INT                 NOT NULL,
        TITULO                  NVARCHAR(150)       NOT NULL,
        MENSAGEM                NVARCHAR(500)       NOT NULL,
        TIPO                    VARCHAR(30)         NOT NULL DEFAULT 'GERAL', -- 'TREINO_CONCLUIDO', 'FINANCEIRO', 'AVALIACAO', 'GERAL'
        LIDA                    BIT                 NOT NULL DEFAULT 0,
        DATA_CRIACAO            DATETIME            NOT NULL DEFAULT GETDATE(),
        CONSTRAINT PK_NOTIFICACOES PRIMARY KEY (ID),
        CONSTRAINT FK_NOTIF_PERSONAL FOREIGN KEY (PERSONAL_ID) REFERENCES PERSONAIS(ID),
        CONSTRAINT FK_NOTIF_USUARIO FOREIGN KEY (USUARIO_ID) REFERENCES USUARIOS(ID)
    );
END
GO

-- ─── 12. ÍNDICES DE PERFORMANCE MULTI-TENANT ────────────────────────────────────────
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
GO

-- ====================================================================================
-- 13. SEEDS INICIAIS — 40 EXERCÍCIOS CLÁSSICOS DE ACADEMIA + USUÁRIOS DE DEMONSTRAÇÃO
-- ====================================================================================

-- 13.1 Biblioteca Global com 40 Exercícios Clássicos separados por Grupo Muscular
IF NOT EXISTS (SELECT 1 FROM EXERCICIOS_BASE WHERE PERSONAL_ID IS NULL)
BEGIN
    INSERT INTO EXERCICIOS_BASE (PERSONAL_ID, NOME, GRUPO_MUSCULAR, VIDEO_URL) VALUES
    -- PEITO (7)
    (NULL, N'Supino Reto com Barra', N'Peito', 'https://www.youtube.com/results?search_query=execucao+supino+reto+barra'),
    (NULL, N'Supino Inclinado com Halteres', N'Peito', 'https://www.youtube.com/results?search_query=execucao+supino+inclinado+halteres'),
    (NULL, N'Crucifixo na Máquina (Peck Deck)', N'Peito', 'https://www.youtube.com/results?search_query=execucao+peck+deck+voador'),
    (NULL, N'Cross-Over Polia Alta', N'Peito', 'https://www.youtube.com/results?search_query=execucao+crossover+polia+alta'),
    (NULL, N'Supino Declinado com Barra', N'Peito', 'https://www.youtube.com/results?search_query=execucao+supino+declinado'),
    (NULL, N'Crucifixo Inclinado com Halteres', N'Peito', 'https://www.youtube.com/results?search_query=execucao+crucifixo+inclinado+halteres'),
    (NULL, N'Flexão de Braços Tradicional', N'Peito', 'https://www.youtube.com/results?search_query=execucao+flexao+de+bracos'),

    -- COSTAS (7)
    (NULL, N'Puxada Frontal Aberta (Pulley)', N'Costas', 'https://www.youtube.com/results?search_query=execucao+puxada+frontal+pulley'),
    (NULL, N'Remada Curvada com Barra Pronada', N'Costas', 'https://www.youtube.com/results?search_query=execucao+remada+curvada+barra'),
    (NULL, N'Remada Baixa no Triângulo', N'Costas', 'https://www.youtube.com/results?search_query=execucao+remada+baixa+triangulo'),
    (NULL, N'Remada Unilateral com Halter (Serrote)', N'Costas', 'https://www.youtube.com/results?search_query=execucao+remada+serrote+halter'),
    (NULL, N'Barra Fixa (Pull-Up)', N'Costas', 'https://www.youtube.com/results?search_query=execucao+barra+fixa+pronada'),
    (NULL, N'Pulldown na Polia com Corda', N'Costas', 'https://www.youtube.com/results?search_query=execucao+pulldown+polia+corda'),
    (NULL, N'Remada Cavalinho (T-Bar Row)', N'Costas', 'https://www.youtube.com/results?search_query=execucao+remada+cavalinho'),

    -- PERNAS (9)
    (NULL, N'Agachamento Livre com Barra', N'Pernas', 'https://www.youtube.com/results?search_query=execucao+agachamento+livre+barra'),
    (NULL, N'Leg Press 45°', N'Pernas', 'https://www.youtube.com/results?search_query=execucao+leg+press+45'),
    (NULL, N'Cadeira Extensora', N'Pernas', 'https://www.youtube.com/results?search_query=execucao+cadeira+extensora'),
    (NULL, N'Mesa Flexora', N'Pernas', 'https://www.youtube.com/results?search_query=execucao+mesa+flexora'),
    (NULL, N'Stiff com Barra (Posterior de Coxa)', N'Pernas', 'https://www.youtube.com/results?search_query=execucao+stiff+com+barra'),
    (NULL, N'Afundo / Passada com Halteres', N'Pernas', 'https://www.youtube.com/results?search_query=execucao+afundo+halteres'),
    (NULL, N'Elevação Pélvica com Barra (Hip Thrust)', N'Pernas', 'https://www.youtube.com/results?search_query=execucao+elevacao+pelvica+barra'),
    (NULL, N'Cadeira Abdutora', N'Pernas', 'https://www.youtube.com/results?search_query=execucao+cadeira+abdutora'),
    (NULL, N'Panturrilha em Pé no Aparelho', N'Pernas', 'https://www.youtube.com/results?search_query=execucao+panturrilha+em+pe'),

    -- OMBROS (5)
    (NULL, N'Desenvolvimento com Halteres Sentado', N'Ombros', 'https://www.youtube.com/results?search_query=execucao+desenvolvimento+halteres'),
    (NULL, N'Elevação Lateral com Halteres', N'Ombros', 'https://www.youtube.com/results?search_query=execucao+elevacao+lateral+halteres'),
    (NULL, N'Elevação Frontal Alternada', N'Ombros', 'https://www.youtube.com/results?search_query=execucao+elevacao+frontal+halteres'),
    (NULL, N'Crucifixo Inverso no Peck Deck (Posterior)', N'Ombros', 'https://www.youtube.com/results?search_query=execucao+crucifixo+inverso+maquina'),
    (NULL, N'Encolhimento de Ombros com Halteres (Trapézio)', N'Ombros', 'https://www.youtube.com/results?search_query=execucao+encolhimento+ombros'),

    -- BÍCEPS (4)
    (NULL, N'Rosca Direta com Barra W', N'Bíceps', 'https://www.youtube.com/results?search_query=execucao+rosca+direta+barra+w'),
    (NULL, N'Rosca Alternada com Halteres Supinada', N'Bíceps', 'https://www.youtube.com/results?search_query=execucao+rosca+alternada+halteres'),
    (NULL, N'Rosca Martelo com Halteres', N'Bíceps', 'https://www.youtube.com/results?search_query=execucao+rosca+martelo'),
    (NULL, N'Rosca Scott na Máquina ou Barra W', N'Bíceps', 'https://www.youtube.com/results?search_query=execucao+rosca+scott'),

    -- TRÍCEPS (4)
    (NULL, N'Tríceps Pulley com Corda', N'Tríceps', 'https://www.youtube.com/results?search_query=execucao+triceps+corda+polia'),
    (NULL, N'Tríceps Testa com Barra W', N'Tríceps', 'https://www.youtube.com/results?search_query=execucao+triceps+testa+barra+w'),
    (NULL, N'Tríceps Pulley Barra Reta', N'Tríceps', 'https://www.youtube.com/results?search_query=execucao+triceps+pulley+barra+reta'),
    (NULL, N'Tríceps Francês Unilateral com Halter', N'Tríceps', 'https://www.youtube.com/results?search_query=execucao+triceps+frances+halter'),

    -- ABDÔMEN (4)
    (NULL, N'Abdominal Supra na Polia (Crunch)', N'Abdômen', 'https://www.youtube.com/results?search_query=execucao+abdominal+polia+alta'),
    (NULL, N'Abdominal Infra Paralelas / Elevação de Pernas', N'Abdômen', 'https://www.youtube.com/results?search_query=execucao+abdominal+infra+paralelas'),
    (NULL, N'Prancha Isométrica Abdominal', N'Abdômen', 'https://www.youtube.com/results?search_query=execucao+prancha+isometrica'),
    (NULL, N'Abdominal Oblíquo Russo (Russian Twist)', N'Abdômen', 'https://www.youtube.com/results?search_query=execucao+abdominal+russian+twist');
END
GO

-- 13.2 Usuários e Dados de Demonstração (Senha padrão: admin123)
-- Hash BCrypt válido para 'admin123': $2a$11$B/tpjRzgpzW6lzxKbpqRRe7xfmrxk8N/FYqcChJI9VeJrzSRMoPFi
DECLARE @SenhaAdmin123 NVARCHAR(256) = '$2a$11$B/tpjRzgpzW6lzxKbpqRRe7xfmrxk8N/FYqcChJI9VeJrzSRMoPFi';
DECLARE @MesAtual VARCHAR(7) = FORMAT(GETDATE(), 'yyyy-MM');

-- 1) SUPER ADMIN (PERFIL 3)
IF NOT EXISTS (SELECT 1 FROM USUARIOS WHERE EMAIL = 'superadmin@personalpro.com')
BEGIN
    INSERT INTO USUARIOS (PERSONAL_ID, NOME, EMAIL, SENHA_HASH, PERFIL, STATUS)
    VALUES (NULL, N'Master SaaS — PersonalPro', 'superadmin@personalpro.com', @SenhaAdmin123, 3, 1);
END

-- 2) PERSONAL TRAINER DE DEMONSTRAÇÃO (PERFIL 1)
DECLARE @PersonalDemoId INT;
IF NOT EXISTS (SELECT 1 FROM PERSONAIS WHERE EMAIL = 'personal@personalpro.com')
BEGIN
    INSERT INTO PERSONAIS (NOME_PROFISSIONAL, CREF, CPF_CNPJ, EMAIL, TELEFONE, CHAVE_PIX, PLANO, STATUS, VALOR_ASSINATURA, DIA_VENCIMENTO, ULTIMO_PAGAMENTO_MES)
    VALUES (
        N'Coach Rodrigo Silva — Team PersonalPro',
        'CREF 014892-G/SP',
        '321.654.987-00',
        'personal@personalpro.com',
        '5511999998888',
        'personal@personalpro.com',
        'ELITE',
        1,
        149.90,
        10,
        @MesAtual
    );
    SET @PersonalDemoId = SCOPE_IDENTITY();

    -- Segundo Personal no SaaS (para demonstrar painel do SuperAdmin com múltiplos tenants)
    INSERT INTO PERSONAIS (NOME_PROFISSIONAL, CREF, CPF_CNPJ, EMAIL, TELEFONE, CHAVE_PIX, PLANO, STATUS, VALOR_ASSINATURA, DIA_VENCIMENTO, ULTIMO_PAGAMENTO_MES)
    VALUES (
        N'Dra. Amanda Costa — Consultoria Fitness',
        'CREF 099412-G/RJ',
        '456.789.123-00',
        'amanda@personalpro.com',
        '5521988887777',
        '5521988887777',
        'PRO',
        1,
        99.90,
        15,
        NULL -- Pagamento Pendente no mês para demonstração do filtro SaaS!
    );
    DECLARE @PersonalAmandaId INT = SCOPE_IDENTITY();

    INSERT INTO USUARIOS (PERSONAL_ID, NOME, EMAIL, SENHA_HASH, PERFIL, STATUS)
    VALUES (@PersonalAmandaId, N'Dra. Amanda Costa', 'amanda@personalpro.com', @SenhaAdmin123, 1, 1);
END
ELSE
BEGIN
    SELECT @PersonalDemoId = ID FROM PERSONAIS WHERE EMAIL = 'personal@personalpro.com';
END

DECLARE @UsuarioPersonalId INT;
IF NOT EXISTS (SELECT 1 FROM USUARIOS WHERE EMAIL = 'personal@personalpro.com')
BEGIN
    INSERT INTO USUARIOS (PERSONAL_ID, NOME, EMAIL, SENHA_HASH, PERFIL, STATUS)
    VALUES (@PersonalDemoId, N'Coach Rodrigo Silva', 'personal@personalpro.com', @SenhaAdmin123, 1, 1);
    SET @UsuarioPersonalId = SCOPE_IDENTITY();
END
ELSE
BEGIN
    SELECT @UsuarioPersonalId = ID FROM USUARIOS WHERE EMAIL = 'personal@personalpro.com';
END

-- 3) ALUNO 1 DE DEMONSTRAÇÃO (PERFIL 2) — Já com Treinos A, B e C montados!
DECLARE @UsuarioAluno1Id INT;
DECLARE @Aluno1Id INT;
IF NOT EXISTS (SELECT 1 FROM USUARIOS WHERE EMAIL = 'aluno1@personalpro.com')
BEGIN
    INSERT INTO USUARIOS (PERSONAL_ID, NOME, EMAIL, SENHA_HASH, PERFIL, STATUS)
    VALUES (@PersonalDemoId, N'Lucas Mendes', 'aluno1@personalpro.com', @SenhaAdmin123, 2, 1);
    SET @UsuarioAluno1Id = SCOPE_IDENTITY();

    INSERT INTO ALUNOS (USUARIO_ID, PERSONAL_ID, CPF, TELEFONE, DATA_NASCIMENTO, OBJETIVO, VALOR_MENSALIDADE, DIA_VENCIMENTO)
    VALUES (@UsuarioAluno1Id, @PersonalDemoId, '123.456.789-01', '5511977776666', '1996-05-14', N'Hipertrofia', 250.00, 10);
    SET @Aluno1Id = SCOPE_IDENTITY();

    -- Segundo aluno (sumido há +10 dias para acionar o Alerta de Alunos Sumidos no painel do Personal!)
    INSERT INTO USUARIOS (PERSONAL_ID, NOME, EMAIL, SENHA_HASH, PERFIL, STATUS)
    VALUES (@PersonalDemoId, N'Mariana Oliveira', 'mariana@personalpro.com', @SenhaAdmin123, 2, 1);
    DECLARE @UsuarioAluno2Id INT = SCOPE_IDENTITY();

    INSERT INTO ALUNOS (USUARIO_ID, PERSONAL_ID, CPF, TELEFONE, DATA_NASCIMENTO, OBJETIVO, VALOR_MENSALIDADE, DIA_VENCIMENTO)
    VALUES (@UsuarioAluno2Id, @PersonalDemoId, '987.654.321-09', '5511966665555', '1999-11-22', N'Emagrecimento', 220.00, 15);
    DECLARE @Aluno2Id INT = SCOPE_IDENTITY();

    -- Histórico de treino antigo (11 dias atrás) para a Mariana aparecer no card "Alunos Sumidos (+7 dias)"
    INSERT INTO HISTORICO_TREINOS (ALUNO_ID, PERSONAL_ID, FICHA_ID, NOME_TREINO, DATA_HORA, DURACAO_MINUTOS, OBSERVACAO_ALUNO)
    VALUES (@Aluno2Id, @PersonalDemoId, NULL, N'Treino A - Full Body Metabólico', DATEADD(DAY, -11, GETDATE()), 50, N'Treino intenso!');

    -- Avaliações Físicas do Aluno 1 (Evolução comparativa)
    INSERT INTO AVALIACOES_FISICAS (ALUNO_ID, PERSONAL_ID, DATA_AVALIACAO, PESO, ALTURA, PERCENTUAL_GORDURA, MEDIDAS_JSON, RESTRICOES_LESOES, OBSERVACOES)
    VALUES
    (@Aluno1Id, @PersonalDemoId, DATEADD(MONTH, -2, CAST(GETDATE() AS DATE)), 78.50, 1.78, 16.80,
     N'{"bracoDireito":37.5,"bracoEsquerdo":37.2,"peitoral":102.0,"cintura":83.0,"abdomen":85.0,"quadril":98.0,"coxaDireita":58.0,"coxaEsquerda":57.8,"panturrilha":39.0}',
     N'Leve desconforto no ombro direito em elevação acima de 90 graus.',
     N'Início do protocolo de hipertrofia limpa.'),
    (@Aluno1Id, @PersonalDemoId, CAST(GETDATE() AS DATE), 81.20, 1.78, 14.20,
     N'{"bracoDireito":39.2,"bracoEsquerdo":39.0,"peitoral":106.5,"cintura":79.5,"abdomen":81.0,"quadril":99.0,"coxaDireita":60.5,"coxaEsquerda":60.2,"panturrilha":40.2}',
     N'Ombro 100% estabilizado após fortalecimento de manguito.',
     N'Excelente ganho de massa magra (+2.7kg) com redução de 2.6% de gordura corporal!');

    -- FICHA A: Peito, Ombros e Tríceps
    INSERT INTO FICHAS_TREINO (ALUNO_ID, PERSONAL_ID, NOME_DIVISAO, DESCRICAO, ATIVA, DATA_VALIDADE)
    VALUES (@Aluno1Id, @PersonalDemoId, N'Treino A - Peito, Ombros e Tríceps', N'Foco em tensão mecânica e progressão de carga nos básicos. Descanso controlado.', 1, DATEADD(MONTH, 2, CAST(GETDATE() AS DATE)));
    DECLARE @FichaA INT = SCOPE_IDENTITY();

    INSERT INTO FICHA_EXERCICIOS (FICHA_ID, NOME_EXERCICIO, GRUPO_MUSCULAR, SERIES, REPETICOES, CARGA_KG, DESCANSO_SEGUNDOS, OBSERVACAO_TECNICA, VIDEO_URL, ORDEM)
    VALUES
    (@FichaA, N'Supino Reto com Barra', N'Peito', 4, '8 a 10', 70.0, 90, N'Cadência 3010 — segurar 1s no peito sem relaxar escápulas.', 'https://www.youtube.com/results?search_query=execucao+supino+reto+barra', 1),
    (@FichaA, N'Supino Inclinado com Halteres', N'Peito', 4, '10 a 12', 28.0, 75, N'Amplitude máxima alongando bem o peitoral superior.', 'https://www.youtube.com/results?search_query=execucao+supino+inclinado+halteres', 2),
    (@FichaA, N'Crucifixo na Máquina (Peck Deck)', N'Peito', 3, '12 a 15', 55.0, 60, N'Pico de contração de 2s fechado + Drop-set na última série.', 'https://www.youtube.com/results?search_query=execucao+peck+deck+voador', 3),
    (@FichaA, N'Desenvolvimento com Halteres Sentado', N'Ombros', 4, '10 a 12', 22.0, 75, N'Cotovelos levemente à frente da linha do tronco.', 'https://www.youtube.com/results?search_query=execucao+desenvolvimento+halteres', 4),
    (@FichaA, N'Elevação Lateral com Halteres', N'Ombros', 4, '12 a 15', 14.0, 60, N'Rest-Pause de 15s na última série até a falha.', 'https://www.youtube.com/results?search_query=execucao+elevacao+lateral+halteres', 5),
    (@FichaA, N'Tríceps Pulley com Corda', N'Tríceps', 4, '12 a 15', 35.0, 60, N'Abrir a corda no final do movimento contraindo a cabeça lateral.', 'https://www.youtube.com/results?search_query=execucao+triceps+corda+polia', 6),
    (@FichaA, N'Tríceps Testa com Barra W', N'Tríceps', 3, '10 a 12', 30.0, 60, N'Manter cotovelos apontados para o teto.', 'https://www.youtube.com/results?search_query=execucao+triceps+testa+barra+w', 7);

    -- FICHA B: Costas, Trapézio e Bíceps
    INSERT INTO FICHAS_TREINO (ALUNO_ID, PERSONAL_ID, NOME_DIVISAO, DESCRICAO, ATIVA, DATA_VALIDADE)
    VALUES (@Aluno1Id, @PersonalDemoId, N'Treino B - Costas, Trapézio e Bíceps', N'Foco em expansão dorsal e remadas pesadas com retração escapular completa.', 1, DATEADD(MONTH, 2, CAST(GETDATE() AS DATE)));
    DECLARE @FichaB INT = SCOPE_IDENTITY();

    INSERT INTO FICHA_EXERCICIOS (FICHA_ID, NOME_EXERCICIO, GRUPO_MUSCULAR, SERIES, REPETICOES, CARGA_KG, DESCANSO_SEGUNDOS, OBSERVACAO_TECNICA, VIDEO_URL, ORDEM)
    VALUES
    (@FichaB, N'Puxada Frontal Aberta (Pulley)', N'Costas', 4, '10 a 12', 65.0, 75, N'Tracionar pelos cotovelos em direção ao quadril.', 'https://www.youtube.com/results?search_query=execucao+puxada+frontal+pulley', 1),
    (@FichaB, N'Remada Curvada com Barra Pronada', N'Costas', 4, '8 a 10', 60.0, 90, N'Tronco firme a 45 graus, puxar na linha umbilical.', 'https://www.youtube.com/results?search_query=execucao+remada+curvada+barra', 2),
    (@FichaB, N'Remada Baixa no Triângulo', N'Costas', 4, '10 a 12', 60.0, 60, N'Alongar bem na fase excêntrica e esmagar as escápulas atrás.', 'https://www.youtube.com/results?search_query=execucao+remada+baixa+triangulo', 3),
    (@FichaB, N'Pulldown na Polia com Corda', N'Costas', 3, '12 a 15', 30.0, 60, N'Movimento contínuo sem perder tensão na grande dorsal.', 'https://www.youtube.com/results?search_query=execucao+pulldown+polia+corda', 4),
    (@FichaB, N'Crucifixo Inverso no Peck Deck (Posterior)', N'Ombros', 3, '12 a 15', 45.0, 60, N'Foco total em deltoide posterior.', 'https://www.youtube.com/results?search_query=execucao+crucifixo+inverso+maquina', 5),
    (@FichaB, N'Rosca Direta com Barra W', N'Bíceps', 4, '10 a 12', 32.0, 60, N'Sem balançar o tronco. Fase excêntrica de 3 segundos.', 'https://www.youtube.com/results?search_query=execucao+rosca+direta+barra+w', 6),
    (@FichaB, N'Rosca Martelo com Halteres', N'Bíceps', 3, '12', 16.0, 60, N'Foco em braquial e antebraço.', 'https://www.youtube.com/results?search_query=execucao+rosca+martelo', 7);

    -- FICHA C: Pernas Completo & Abdômen
    INSERT INTO FICHAS_TREINO (ALUNO_ID, PERSONAL_ID, NOME_DIVISAO, DESCRICAO, ATIVA, DATA_VALIDADE)
    VALUES (@Aluno1Id, @PersonalDemoId, N'Treino C - Pernas Completo & Core', N'Treino de alta demanda energética para quadríceps, posteriores, glúteos e panturrilhas.', 1, DATEADD(MONTH, 2, CAST(GETDATE() AS DATE)));
    DECLARE @FichaC INT = SCOPE_IDENTITY();

    INSERT INTO FICHA_EXERCICIOS (FICHA_ID, NOME_EXERCICIO, GRUPO_MUSCULAR, SERIES, REPETICOES, CARGA_KG, DESCANSO_SEGUNDOS, OBSERVACAO_TECNICA, VIDEO_URL, ORDEM)
    VALUES
    (@FichaC, N'Agachamento Livre com Barra', N'Pernas', 4, '8 a 10', 90.0, 120, N'Descer quebrando a paralela com core travado.', 'https://www.youtube.com/results?search_query=execucao+agachamento+livre+barra', 1),
    (@FichaC, N'Leg Press 45°', N'Pernas', 4, '10 a 12', 220.0, 90, N'Pés na largura dos ombros, sem travar os joelhos no topo.', 'https://www.youtube.com/results?search_query=execucao+leg+press+45', 2),
    (@FichaC, N'Cadeira Extensora', N'Pernas', 4, '12 a 15', 65.0, 60, N'Segurar 2s no topo + Drop-set duplo na última série!', 'https://www.youtube.com/results?search_query=execucao+cadeira+extensora', 3),
    (@FichaC, N'Stiff com Barra (Posterior de Coxa)', N'Pernas', 4, '10 a 12', 70.0, 90, N'Coluna neutra, projetando o quadril para trás.', 'https://www.youtube.com/results?search_query=execucao+stiff+com+barra', 4),
    (@FichaC, N'Mesa Flexora', N'Pernas', 4, '12 a 15', 50.0, 60, N'Quadril colado no banco durante toda a série.', 'https://www.youtube.com/results?search_query=execucao+mesa+flexora', 5),
    (@FichaC, N'Panturrilha em Pé no Aparelho', N'Pernas', 4, '15 a 20', 80.0, 45, N'Pausa de 2s no alongamento máximo e 2s na contração.', 'https://www.youtube.com/results?search_query=execucao+panturrilha+em+pe', 6),
    (@FichaC, N'Abdominal Supra na Polia (Crunch)', N'Abdômen', 4, '15', 35.0, 45, N'Soltar todo o ar enrolando a coluna.', 'https://www.youtube.com/results?search_query=execucao+abdominal+polia+alta', 7);

    -- Histórico de treinos recentes do Aluno 1
    INSERT INTO HISTORICO_TREINOS (ALUNO_ID, PERSONAL_ID, FICHA_ID, NOME_TREINO, DATA_HORA, DURACAO_MINUTOS, OBSERVACAO_ALUNO)
    VALUES
    (@Aluno1Id, @PersonalDemoId, @FichaA, N'Treino A - Peito, Ombros e Tríceps', DATEADD(DAY, -3, GETDATE()), 52, N'Subi a carga do supino para 70kg com ótima execução!'),
    (@Aluno1Id, @PersonalDemoId, @FichaB, N'Treino B - Costas, Trapézio e Bíceps', DATEADD(DAY, -1, GETDATE()), 48, N'Pump excelente nas dorsais, remada curvada muito firme.');

    -- Mensalidades (1 Paga no mês passado + 1 Pendente no mês atual pronta para pagar via PIX!)
    INSERT INTO PAGAMENTOS (ALUNO_ID, PERSONAL_ID, MES_REFERENCIA, VALOR, DATA_VENCIMENTO, DATA_PAGAMENTO, FORMA_PAGAMENTO, STATUS, OBSERVACAO, PIX_COPIA_E_COLA)
    VALUES
    (@Aluno1Id, @PersonalDemoId, FORMAT(DATEADD(MONTH, -1, GETDATE()), 'yyyy-MM'), 250.00, DATEADD(MONTH, -1, CAST(GETDATE() AS DATE)), DATEADD(MONTH, -1, CAST(GETDATE() AS DATE)), N'PIX', N'PAGO', N'Consultoria PersonalPro — Pago em dia', NULL),
    (@Aluno1Id, @PersonalDemoId, @MesAtual, 250.00, DATEADD(DAY, 5, CAST(GETDATE() AS DATE)), NULL, NULL, N'PENDENTE', N'Mensalidade Consultoria PersonalPro — Mês Atual',
     '00020126480014br.gov.bcb.pix0126personal@personalpro.com5204000053039865406250.005802BR5925COACH RODRIGO SILVA6009SAO PAULO62140510PERSONAL016304A1B2'),
    (@Aluno2Id, @PersonalDemoId, @MesAtual, 220.00, DATEADD(DAY, -2, CAST(GETDATE() AS DATE)), NULL, NULL, N'PENDENTE', N'Mensalidade Consultoria PersonalPro',
     '00020126480014br.gov.bcb.pix0126personal@personalpro.com5204000053039865406220.005802BR5925COACH RODRIGO SILVA6009SAO PAULO62140510PERSONAL026304C3D4');

    -- Notificações Iniciais
    INSERT INTO NOTIFICACOES (PERSONAL_ID, USUARIO_ID, TITULO, MENSAGEM, TIPO, LIDA)
    VALUES
    (@PersonalDemoId, @UsuarioPersonalId, N'💪 Treino Concluído!', N'O aluno Lucas Mendes acabou de concluir o Treino B - Costas, Trapézio e Bíceps (48 min)!', 'TREINO_CONCLUIDO', 0),
    (@PersonalDemoId, @UsuarioPersonalId, N'⚠️ Alerta de Aluno Sumido', N'A aluna Mariana Oliveira está há 11 dias sem registrar treino concluído. Que tal chamar no WhatsApp?', 'GERAL', 0),
    (@PersonalDemoId, @UsuarioAluno1Id, N'🔥 Nova Ficha Prescrita!', N'Seu Personal Coach Rodrigo Silva atualizou seus Treinos A, B e C. Bom treino!', 'GERAL', 0);
END
GO
