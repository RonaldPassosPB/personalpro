-- ==========================================================================================
-- PERSONALPRO SaaS - MIGRACAO V3:
-- 1. PLANOS ALIMENTARES / DIETA & CALCULADORA DE MACROS (TMB / GET)
-- 2. AGENDA DE AULAS PRESENCIAIS & CHECK-IN DO PERSONAL
-- 3. DEMONSTRACAO ANIMADA DE EXECUCAO DE EXERCICIOS (GIF / BIOMECANICA / DICAS TECNICAS)
-- ==========================================================================================
USE PersonalPro;
GO

-- 1. TABELA DE PLANOS ALIMENTARES (DIETA & MACROS)
IF OBJECT_ID('PLANOS_ALIMENTARES', 'U') IS NULL
BEGIN
    CREATE TABLE PLANOS_ALIMENTARES (
        ID INT IDENTITY(1,1) PRIMARY KEY,
        ALUNO_ID INT NOT NULL,
        PERSONAL_ID INT NOT NULL,
        TITULO NVARCHAR(150) NOT NULL,
        OBJETIVO NVARCHAR(80) NOT NULL DEFAULT 'Hipertrofia',
        PESO_BASE_KG DECIMAL(6,2) NOT NULL DEFAULT 80,
        ALTURA_CM DECIMAL(6,2) NOT NULL DEFAULT 178,
        IDADE INT NOT NULL DEFAULT 26,
        SEXO CHAR(1) NOT NULL DEFAULT 'M',
        FATOR_ATIVIDADE DECIMAL(4,2) NOT NULL DEFAULT 1.55,
        TMB_KCAL INT NOT NULL DEFAULT 1850,
        GET_KCAL INT NOT NULL DEFAULT 2450,
        META_KCAL INT NOT NULL DEFAULT 2650,
        PROTEINA_G INT NOT NULL DEFAULT 180,
        CARBOIDRATO_G INT NOT NULL DEFAULT 300,
        GORDURA_G INT NOT NULL DEFAULT 70,
        AGUA_LITROS DECIMAL(4,1) NOT NULL DEFAULT 3.5,
        OBSERVACOES NVARCHAR(MAX) NULL,
        ATIVO BIT NOT NULL DEFAULT 1,
        DATA_CRIACAO DATETIME NOT NULL DEFAULT GETDATE(),
        CONSTRAINT FK_PLANOS_ALIMENTARES_ALUNO FOREIGN KEY (ALUNO_ID) REFERENCES ALUNOS(ID),
        CONSTRAINT FK_PLANOS_ALIMENTARES_PERSONAL FOREIGN KEY (PERSONAL_ID) REFERENCES PERSONAIS(ID)
    );
END
GO

-- 2. TABELA DE REFEICOES DO PLANO ALIMENTAR
IF OBJECT_ID('REFEICOES_PLANO', 'U') IS NULL
BEGIN
    CREATE TABLE REFEICOES_PLANO (
        ID INT IDENTITY(1,1) PRIMARY KEY,
        PLANO_ID INT NOT NULL,
        HORARIO NVARCHAR(20) NOT NULL,
        NOME_REFEICAO NVARCHAR(120) NOT NULL,
        ALIMENTOS_DESCRICAO NVARCHAR(MAX) NOT NULL,
        SUBSTITUICOES NVARCHAR(MAX) NULL,
        KCAL_ESTIMADA INT NOT NULL DEFAULT 500,
        PROTEINA_G INT NOT NULL DEFAULT 35,
        CARBO_G INT NOT NULL DEFAULT 55,
        GORDURA_G INT NOT NULL DEFAULT 14,
        ORDEM INT NOT NULL DEFAULT 1,
        CONSTRAINT FK_REFEICOES_PLANO_PLANO FOREIGN KEY (PLANO_ID) REFERENCES PLANOS_ALIMENTARES(ID) ON DELETE CASCADE
    );
END
GO

-- 3. TABELA DE AGENDA DE AULAS PRESENCIAIS / CONSULTORIAS DO PERSONAL
IF OBJECT_ID('AGENDA_AULAS', 'U') IS NULL
BEGIN
    CREATE TABLE AGENDA_AULAS (
        ID INT IDENTITY(1,1) PRIMARY KEY,
        PERSONAL_ID INT NOT NULL,
        ALUNO_ID INT NOT NULL,
        DATA_HORA_INICIO DATETIME NOT NULL,
        DURACAO_MINUTOS INT NOT NULL DEFAULT 60,
        TIPO_AULA NVARCHAR(40) NOT NULL DEFAULT 'PRESENCIAL', -- PRESENCIAL, AVALIACAO_FISICA, CONSULTORIA_ONLINE
        TITULO_TREINO NVARCHAR(150) NOT NULL,
        LOCAL_ACADEMIA NVARCHAR(150) NULL DEFAULT 'Ironberg / SmartFit - Sala Musculação',
        STATUS NVARCHAR(30) NOT NULL DEFAULT 'AGENDADA', -- AGENDADA, CONCLUIDA, FALTOU, CANCELADA
        OBSERVACOES NVARCHAR(500) NULL,
        DATA_CRIACAO DATETIME NOT NULL DEFAULT GETDATE(),
        CONSTRAINT FK_AGENDA_AULAS_PERSONAL FOREIGN KEY (PERSONAL_ID) REFERENCES PERSONAIS(ID),
        CONSTRAINT FK_AGENDA_AULAS_ALUNO FOREIGN KEY (ALUNO_ID) REFERENCES ALUNOS(ID)
    );
END
GO

-- 4. ENRIQUECER EXERCICIOS COM DICAS BIOMECANICAS E IDENTIFICADOR DE ANIMACAO
IF COL_LENGTH('EXERCICIOS_BASE', 'INSTRUCOES_EXECUCAO') IS NULL
BEGIN
    ALTER TABLE EXERCICIOS_BASE ADD INSTRUCOES_EXECUCAO NVARCHAR(MAX) NULL;
END
GO

-- Atualiza instrucoes biomecanicas detalhadas nos exercicios base
UPDATE EXERCICIOS_BASE
SET INSTRUCOES_EXECUCAO = CASE
    WHEN GRUPO_MUSCULAR = 'Peito' THEN 'Mantenha as escápulas retraídas e apoiadas no banco. Desça a carga controlando em 2 segundos até a linha média do peitoral (alongamento máximo) e empurre soltando o ar sem perder a estabilidade dos ombros.'
    WHEN GRUPO_MUSCULAR = 'Costas' THEN 'Inicie o movimento pela depressão escapular (destravando os ombros) antes de flexionar os cotovelos. Puxe trazendo os cotovelos em direção ao quadril, segure 1s no pico de contração e retorne alongando as dorsais.'
    WHEN GRUPO_MUSCULAR = 'Pernas' THEN 'Mantenha o abdômen contraído (bracing), coluna neutra e joelhos alinhados com a ponta dos pés durante toda a descida. Desça com controle até pelo menos 90° e empurre o piso pelo meio/calcanhar dos pés.'
    WHEN GRUPO_MUSCULAR = 'Ombros' THEN 'Estabilize o tronco, mantenha uma leve flexão nos cotovelos e eleve a carga até a linha dos ombros liderando o movimento pelos cotovelos, evitando encolher o trapézio.'
    WHEN GRUPO_MUSCULAR = 'Bíceps' THEN 'Mantenha os cotovelos fixos ao lado do tronco sem balançar a lombar. Suba contraindo o bíceps até o topo, segure 1 segundo e controle a fase excêntrica (descida) em 2 a 3 segundos.'
    WHEN GRUPO_MUSCULAR = 'Tríceps' THEN 'Trave os ombros e cotovelos colados ao corpo. Estenda completamente o antebraço até contrair totalmente a cabeça lateral/longa do tríceps no final do movimento.'
    ELSE 'Mantenha a respiração ritmada (solte o ar na contração máxima) e controle totalmente a volta do movimento.'
END
WHERE INSTRUCOES_EXECUCAO IS NULL;
GO

-- 5. SEED DE PLANO ALIMENTAR COMPLETO PARA O ALUNO DEMO (LUCAS MENDES)
DECLARE @AlunoId INT = (SELECT TOP 1 ID FROM ALUNOS ORDER BY ID ASC);
DECLARE @PersonalId INT = (SELECT TOP 1 ID FROM PERSONAIS ORDER BY ID ASC);

IF @AlunoId IS NOT NULL AND @PersonalId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM PLANOS_ALIMENTARES WHERE ALUNO_ID = @AlunoId)
BEGIN
    INSERT INTO PLANOS_ALIMENTARES (
        ALUNO_ID, PERSONAL_ID, TITULO, OBJETIVO, PESO_BASE_KG, ALTURA_CM, IDADE, SEXO,
        FATOR_ATIVIDADE, TMB_KCAL, GET_KCAL, META_KCAL, PROTEINA_G, CARBOIDRATO_G, GORDURA_G,
        AGUA_LITROS, OBSERVACOES, ATIVO
    )
    VALUES (
        @AlunoId, @PersonalId,
        'Protocolo Hipertrofia Limpa & Definição (Fase 2)',
        'Hipertrofia', 81.4, 178, 26, 'M',
        1.55, 1825, 2450, 2750, 185, 320, 72,
        3.6,
        'Beber 3.6L de água ao longo do dia (45ml/kg). Creatina 5g todos os dias (inclusive dias sem treino). Evitar frituras e açúcar refinado.',
        1
    );

    DECLARE @PlanoId INT = SCOPE_IDENTITY();

    INSERT INTO REFEICOES_PLANO (PLANO_ID, HORARIO, NOME_REFEICAO, ALIMENTOS_DESCRICAO, SUBSTITUICOES, KCAL_ESTIMADA, PROTEINA_G, CARBO_G, GORDURA_G, ORDEM)
    VALUES
    (@PlanoId, '07:30', 'Refeição 1 — Café da Manhã Anabólico',
     '• 3 Ovos inteiros mexidos + 2 Claras\n• 2 Fatias de pão integral (ou 60g de aveia em flocos)\n• 1 Banana prata amassada com canela\n• 1 Xícara de café preto sem açúcar',
     'Substituição: Crepioca (2 ovos + 40g goma de tapioca + 40g frango desfiado ou queijo minas padrão)',
     560, 36, 58, 18, 1),

    (@PlanoId, '12:30', 'Refeição 2 — Almoço (Carga de Glicogênio)',
     '• 180g de Filé de Peito de Frango grelhado (pesado pronto)\n• 200g de Arroz branco ou integral cozido\n• 100g de Feijão carioca/preto\n• Salada verde à vontade + 1 colher de sopa de Azeite de Oliva Extra Virgem (12ml)',
     'Substituição: 180g de Patinho moído magro ou Tilápia grelhada + 220g de Batata inglesa/doce assada',
     690, 54, 78, 16, 2),

    (@PlanoId, '16:30', 'Refeição 3 — Pré-Treino (Energia Rápida)',
     '• 40g de Whey Protein Concentrado (1 scoop)\n• 50g de Aveia em flocos finos\n• 150g de Mamão ou Banana + 20g de Pasta de Amendoim integral\n• 5g de Creatina Monohidratada',
     'Substituição: 150g de Frango desfiado + 160g de Mandioca/Batata doce cozida',
     510, 38, 56, 14, 3),

    (@PlanoId, '20:00', 'Refeição 4 — Pós-Treino Sólido / Jantar',
     '• 180g de Carne Bovina Magra (Patinho / Alcatra) ou Peito de Frango\n• 180g de Arroz branco ou Macarrão grano duro\n• 100g de Brócolis e Legumes no vapor',
     'Substituição: 200g de Filé de Peixe branco + 220g de Purê de batata ou Abóbora cabotiá',
     620, 50, 72, 14, 4),

    (@PlanoId, '22:30', 'Refeição 5 — Ceia Recuperadora Noturna',
     '• 170g de Iogurte Natural Desnatado (ou Grego Zero)\n• 20g de Castanhas-do-Pará / Amêndoas (ou 15g Pasta de Amendoim)\n• 2 Morangos ou 1 Kiwi picado',
     'Substituição: Omelete com 2 ovos inteiros + 1 colher de sopa de queijo cottage',
     370, 17, 26, 10, 5);
END
GO

-- 6. SEED DE AGENDA DE AULAS PRESENCIAIS E AVALIACOES DA SEMANA
DECLARE @Aluno1 INT = (SELECT TOP 1 ID FROM ALUNOS ORDER BY ID ASC);
DECLARE @Aluno2 INT = (SELECT TOP 1 ID FROM ALUNOS WHERE ID > ISNULL(@Aluno1, 0) ORDER BY ID ASC);
IF @Aluno2 IS NULL SET @Aluno2 = @Aluno1;
DECLARE @PersId INT = (SELECT TOP 1 ID FROM PERSONAIS ORDER BY ID ASC);

IF @Aluno1 IS NOT NULL AND @PersId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM AGENDA_AULAS WHERE PERSONAL_ID = @PersId)
BEGIN
    INSERT INTO AGENDA_AULAS (PERSONAL_ID, ALUNO_ID, DATA_HORA_INICIO, DURACAO_MINUTOS, TIPO_AULA, TITULO_TREINO, LOCAL_ACADEMIA, STATUS, OBSERVACOES)
    VALUES
    (@PersId, @Aluno1, DATEADD(HOUR, 18, CAST(CAST(GETDATE() AS DATE) AS DATETIME)), 60,
     'PRESENCIAL', 'Treino A — Peito, Ombro Anterior e Tríceps (Foco Progressão no Supino)',
     'Unidade Principal — Sala de Musculação', 'AGENDADA',
     'Acompanhar execução na última série de Supino Reto (tentar 37.5kg/lado com spotter).'),

    (@PersId, @Aluno2, DATEADD(HOUR, 19, CAST(CAST(GETDATE() AS DATE) AS DATETIME)), 60,
     'PRESENCIAL', 'Treino Inferior — Glúteos e Posterior de Coxa',
     'Unidade Principal — Sala de Musculação', 'AGENDADA',
     'Atenção à amplitude no Stiff com Barra e ativação no Elevação Pélvica.'),

    (@PersId, @Aluno1, DATEADD(HOUR, 18, DATEADD(DAY, -1, CAST(CAST(GETDATE() AS DATE) AS DATETIME))), 60,
     'PRESENCIAL', 'Treino C — Pernas Completo (Quadríceps & Panturrilha)',
     'Unidade Principal — Sala de Musculação', 'CONCLUIDA',
     'Excelente treino! Bateu PR no Agachamento Livre (45kg cada lado).'),

    (@PersId, @Aluno1, DATEADD(HOUR, 10, DATEADD(DAY, 2, CAST(CAST(GETDATE() AS DATE) AS DATETIME))), 45,
     'AVALIACAO_FISICA', 'Reavaliação Antropométrica + Fotos Antes/Depois (Bioimpedância)',
     'Consultório de Avaliação Física — Sala 02', 'AGENDADA',
     'Aluno orientado a vir com bermuda de compressão para padronização das fotos.'),

    (@PersId, @Aluno2, DATEADD(HOUR, 20, DATEADD(DAY, 1, CAST(CAST(GETDATE() AS DATE) AS DATETIME))), 45,
     'CONSULTORIA_ONLINE', 'Alinhamento de Dieta & Ajuste de Volume Semanal (Vídeo)',
     'Google Meet / WhatsApp Vídeo', 'AGENDADA',
     'Revisar aderência à dieta e reativar frequência semanal.');
END
GO
