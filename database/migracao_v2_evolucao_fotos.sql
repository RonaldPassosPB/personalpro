-- ====================================================================================
-- PERSONALPRO — Migração v2.0:
-- 1) Recuperação de Senha (6 dígitos) + Background Service de Cobranças/Vencimentos
-- 2) Histórico de Progressão de Carga por Exercício (PROGRESSAO_CARGAS)
-- 3) Fotos Antes x Depois na Avaliação Física + Foto do Aluno e Logo do Personal
-- ====================================================================================

USE PersonalPro;
GO

-- 1. Colunas de Recuperação de Senha em USUARIOS
IF COL_LENGTH('USUARIOS', 'CODIGO_RECUPERACAO') IS NULL
BEGIN
    ALTER TABLE USUARIOS ADD CODIGO_RECUPERACAO VARCHAR(10) NULL;
    ALTER TABLE USUARIOS ADD RECUPERACAO_EXPIRACAO DATETIME NULL;
END
GO

-- 2. Coluna de Logo em PERSONAIS
IF COL_LENGTH('PERSONAIS', 'LOGO_URL') IS NULL
BEGIN
    ALTER TABLE PERSONAIS ADD LOGO_URL NVARCHAR(MAX) NULL;
END
GO

-- 3. Expandir FOTO_URL em ALUNOS para suportar Base64 / Data URI
ALTER TABLE ALUNOS ALTER COLUMN FOTO_URL NVARCHAR(MAX) NULL;
GO

-- 4. Colunas de Fotos Antes x Depois em AVALIACOES_FISICAS
IF COL_LENGTH('AVALIACOES_FISICAS', 'FOTO_FRENTE_URL') IS NULL
BEGIN
    ALTER TABLE AVALIACOES_FISICAS ADD FOTO_FRENTE_URL NVARCHAR(MAX) NULL;
    ALTER TABLE AVALIACOES_FISICAS ADD FOTO_LADO_COSTAS_URL NVARCHAR(MAX) NULL;
END
GO

-- 5. Tabela de Histórico de Progressão de Carga por Exercício
IF OBJECT_ID('PROGRESSAO_CARGAS', 'U') IS NULL
BEGIN
    CREATE TABLE PROGRESSAO_CARGAS (
        ID                  INT IDENTITY(1,1)   NOT NULL,
        ALUNO_ID            INT                 NOT NULL,
        PERSONAL_ID         INT                 NOT NULL,
        EXERCICIO_ID        INT                 NULL,
        NOME_EXERCICIO      NVARCHAR(150)       NOT NULL,
        GRUPO_MUSCULAR      NVARCHAR(60)        NULL,
        CARGA_KG            DECIMAL(6,2)        NOT NULL,
        DATA_REGISTRO       DATETIME            NOT NULL DEFAULT GETDATE(),
        CONSTRAINT PK_PROGRESSAO_CARGAS PRIMARY KEY (ID),
        CONSTRAINT FK_PROG_ALUNO FOREIGN KEY (ALUNO_ID) REFERENCES ALUNOS(ID),
        CONSTRAINT FK_PROG_PERSONAL FOREIGN KEY (PERSONAL_ID) REFERENCES PERSONAIS(ID)
    );

    CREATE NONCLUSTERED INDEX IX_PROGRESSAO_ALUNO_EXERCICIO
        ON PROGRESSAO_CARGAS(ALUNO_ID, NOME_EXERCICIO, DATA_REGISTRO ASC);
END
GO

-- 6. Seeds de Histórico de Progressão de Carga e Avaliação Intermediária para Gráficos
DECLARE @Aluno1Id INT = (SELECT TOP 1 A.ID FROM ALUNOS A INNER JOIN USUARIOS U ON U.ID = A.USUARIO_ID WHERE U.EMAIL = 'aluno1@personalpro.com');
DECLARE @PersonalDemoId INT = (SELECT TOP 1 PERSONAL_ID FROM ALUNOS WHERE ID = @Aluno1Id);

IF @Aluno1Id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM PROGRESSAO_CARGAS WHERE ALUNO_ID = @Aluno1Id)
BEGIN
    INSERT INTO PROGRESSAO_CARGAS (ALUNO_ID, PERSONAL_ID, NOME_EXERCICIO, GRUPO_MUSCULAR, CARGA_KG, DATA_REGISTRO)
    VALUES
    -- Supino Reto com Barra (Evolução: 55kg -> 60kg -> 65kg -> 70kg)
    (@Aluno1Id, @PersonalDemoId, N'Supino Reto com Barra', N'Peito', 55.0, DATEADD(DAY, -45, GETDATE())),
    (@Aluno1Id, @PersonalDemoId, N'Supino Reto com Barra', N'Peito', 60.0, DATEADD(DAY, -30, GETDATE())),
    (@Aluno1Id, @PersonalDemoId, N'Supino Reto com Barra', N'Peito', 65.0, DATEADD(DAY, -15, GETDATE())),
    (@Aluno1Id, @PersonalDemoId, N'Supino Reto com Barra', N'Peito', 70.0, GETDATE()),

    -- Agachamento Livre com Barra (Evolução: 70kg -> 80kg -> 85kg -> 90kg)
    (@Aluno1Id, @PersonalDemoId, N'Agachamento Livre com Barra', N'Pernas', 70.0, DATEADD(DAY, -45, GETDATE())),
    (@Aluno1Id, @PersonalDemoId, N'Agachamento Livre com Barra', N'Pernas', 80.0, DATEADD(DAY, -30, GETDATE())),
    (@Aluno1Id, @PersonalDemoId, N'Agachamento Livre com Barra', N'Pernas', 85.0, DATEADD(DAY, -15, GETDATE())),
    (@Aluno1Id, @PersonalDemoId, N'Agachamento Livre com Barra', N'Pernas', 90.0, GETDATE()),

    -- Remada Curvada com Barra Pronada (Evolução: 45kg -> 50kg -> 55kg -> 60kg)
    (@Aluno1Id, @PersonalDemoId, N'Remada Curvada com Barra Pronada', N'Costas', 45.0, DATEADD(DAY, -45, GETDATE())),
    (@Aluno1Id, @PersonalDemoId, N'Remada Curvada com Barra Pronada', N'Costas', 50.0, DATEADD(DAY, -30, GETDATE())),
    (@Aluno1Id, @PersonalDemoId, N'Remada Curvada com Barra Pronada', N'Costas', 55.0, DATEADD(DAY, -15, GETDATE())),
    (@Aluno1Id, @PersonalDemoId, N'Remada Curvada com Barra Pronada', N'Costas', 60.0, GETDATE()),

    -- Leg Press 45° (Evolução: 180kg -> 200kg -> 220kg)
    (@Aluno1Id, @PersonalDemoId, N'Leg Press 45°', N'Pernas', 180.0, DATEADD(DAY, -35, GETDATE())),
    (@Aluno1Id, @PersonalDemoId, N'Leg Press 45°', N'Pernas', 200.0, DATEADD(DAY, -18, GETDATE())),
    (@Aluno1Id, @PersonalDemoId, N'Leg Press 45°', N'Pernas', 220.0, GETDATE());

    -- Adiciona uma 3ª avaliação intermediária (1 mês atrás) para deixar o gráfico de linha com 3 pontos de evolução!
    IF (SELECT COUNT(1) FROM AVALIACOES_FISICAS WHERE ALUNO_ID = @Aluno1Id) = 2
    BEGIN
        INSERT INTO AVALIACOES_FISICAS (ALUNO_ID, PERSONAL_ID, DATA_AVALIACAO, PESO, ALTURA, PERCENTUAL_GORDURA, MEDIDAS_JSON, RESTRICOES_LESOES, OBSERVACOES)
        VALUES (
            @Aluno1Id,
            @PersonalDemoId,
            DATEADD(MONTH, -1, CAST(GETDATE() AS DATE)),
            79.80,
            1.78,
            15.40,
            N'{"bracoDireito":38.4,"bracoEsquerdo":38.1,"peitoral":104.2,"cintura":81.0,"abdomen":83.0,"quadril":98.5,"coxaDireita":59.2,"coxaEsquerda":59.0,"panturrilha":39.6}',
            N'Sem dores.',
            N'Evolução consistente no 1º mês de protocolo.'
        );
    END
END
GO
