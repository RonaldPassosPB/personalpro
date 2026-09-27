-- ============================================================================
-- PERSONALPRO SAAS — CORREÇÃO DEFINITIVA DE ACENTOS E CODIFICAÇÃO UTF-8
-- Usa NCHAR() exatos (imune a codepage de terminal) para limpar qualquer Mojibake
-- ============================================================================
USE PersonalPro;
GO

CREATE OR ALTER FUNCTION dbo.fn_CorrigirMojibake(@texto NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
BEGIN
    IF @texto IS NULL RETURN NULL;
    DECLARE @r NVARCHAR(MAX) = @texto;

    -- Travessão, meia-risca, bullet e graus (UTF-8 lido como CP1252)
    SET @r = REPLACE(@r, NCHAR(226) + NCHAR(8364) + NCHAR(8221), NCHAR(8212)); -- â€” -> —
    SET @r = REPLACE(@r, NCHAR(226) + NCHAR(8364) + NCHAR(8220), NCHAR(8211)); -- â€“ -> –
    SET @r = REPLACE(@r, NCHAR(226) + NCHAR(8364) + NCHAR(8226), NCHAR(8226)); -- â€¢ -> •
    SET @r = REPLACE(@r, NCHAR(194) + NCHAR(176), NCHAR(176));                 -- Â°  -> °
    SET @r = REPLACE(@r, NCHAR(194) + NCHAR(186), NCHAR(186));                 -- Âº  -> º
    SET @r = REPLACE(@r, NCHAR(194) + NCHAR(170), NCHAR(170));                 -- Âª  -> ª

    -- Minúsculas acentuadas e cedilha (C3 xx em UTF-8 lido como CP1252)
    SET @r = REPLACE(@r, NCHAR(195) + NCHAR(161), NCHAR(225)); -- Ã¡ -> á
    SET @r = REPLACE(@r, NCHAR(195) + NCHAR(160), NCHAR(224)); -- Ã  -> à
    SET @r = REPLACE(@r, NCHAR(195) + NCHAR(162), NCHAR(226)); -- Ã¢ -> â
    SET @r = REPLACE(@r, NCHAR(195) + NCHAR(163), NCHAR(227)); -- Ã£ -> ã
    SET @r = REPLACE(@r, NCHAR(195) + NCHAR(169), NCHAR(233)); -- Ã© -> é
    SET @r = REPLACE(@r, NCHAR(195) + NCHAR(170), NCHAR(234)); -- Ãª -> ê
    SET @r = REPLACE(@r, NCHAR(195) + NCHAR(173), NCHAR(237)); -- Ã­ -> í
    SET @r = REPLACE(@r, NCHAR(195) + NCHAR(179), NCHAR(243)); -- Ã³ -> ó
    SET @r = REPLACE(@r, NCHAR(195) + NCHAR(180), NCHAR(244)); -- Ã´ -> ô
    SET @r = REPLACE(@r, NCHAR(195) + NCHAR(181), NCHAR(245)); -- Ãµ -> õ
    SET @r = REPLACE(@r, NCHAR(195) + NCHAR(186), NCHAR(250)); -- Ãº -> ú
    SET @r = REPLACE(@r, NCHAR(195) + NCHAR(188), NCHAR(252)); -- Ã¼ -> ü
    SET @r = REPLACE(@r, NCHAR(195) + NCHAR(167), NCHAR(231)); -- Ã§ -> ç

    -- Maiúsculas acentuadas e cedilha
    SET @r = REPLACE(@r, NCHAR(195) + NCHAR(129), NCHAR(193)); -- Ã  -> Á
    SET @r = REPLACE(@r, NCHAR(195) + NCHAR(128), NCHAR(192)); -- Ã€ -> À
    SET @r = REPLACE(@r, NCHAR(195) + NCHAR(130), NCHAR(194)); -- Ã‚ -> Â
    SET @r = REPLACE(@r, NCHAR(195) + NCHAR(131), NCHAR(195)); -- Ãƒ -> Ã
    SET @r = REPLACE(@r, NCHAR(195) + NCHAR(137), NCHAR(201)); -- Ã‰ -> É
    SET @r = REPLACE(@r, NCHAR(195) + NCHAR(138), NCHAR(202)); -- ÃŠ -> Ê
    SET @r = REPLACE(@r, NCHAR(195) + NCHAR(141), NCHAR(205)); -- Ã  -> Í
    SET @r = REPLACE(@r, NCHAR(195) + NCHAR(147), NCHAR(211)); -- Ã“ -> Ó
    SET @r = REPLACE(@r, NCHAR(195) + NCHAR(148), NCHAR(212)); -- Ã” -> Ô
    SET @r = REPLACE(@r, NCHAR(195) + NCHAR(149), NCHAR(213)); -- Ã• -> Õ
    SET @r = REPLACE(@r, NCHAR(195) + NCHAR(154), NCHAR(218)); -- Ãš -> Ú
    SET @r = REPLACE(@r, NCHAR(195) + NCHAR(135), NCHAR(199)); -- Ã‡ -> Ç

    RETURN @r;
END
GO

UPDATE PERSONAIS SET NOME_PROFISSIONAL = dbo.fn_CorrigirMojibake(NOME_PROFISSIONAL);
GO
UPDATE USUARIOS SET NOME = dbo.fn_CorrigirMojibake(NOME);
GO
UPDATE ALUNOS SET OBJETIVO = dbo.fn_CorrigirMojibake(OBJETIVO);
GO
UPDATE EXERCICIOS_BASE
SET NOME = dbo.fn_CorrigirMojibake(NOME),
    GRUPO_MUSCULAR = dbo.fn_CorrigirMojibake(GRUPO_MUSCULAR),
    INSTRUCOES_EXECUCAO = dbo.fn_CorrigirMojibake(INSTRUCOES_EXECUCAO);
GO
UPDATE FICHAS_TREINO
SET NOME_DIVISAO = dbo.fn_CorrigirMojibake(NOME_DIVISAO),
    DESCRICAO = dbo.fn_CorrigirMojibake(DESCRICAO);
GO
UPDATE FICHA_EXERCICIOS
SET NOME_EXERCICIO = dbo.fn_CorrigirMojibake(NOME_EXERCICIO),
    GRUPO_MUSCULAR = dbo.fn_CorrigirMojibake(GRUPO_MUSCULAR),
    REPETICOES = dbo.fn_CorrigirMojibake(REPETICOES),
    OBSERVACAO_TECNICA = dbo.fn_CorrigirMojibake(OBSERVACAO_TECNICA);
GO
UPDATE AVALIACOES_FISICAS
SET RESTRICOES_LESOES = dbo.fn_CorrigirMojibake(RESTRICOES_LESOES),
    OBSERVACOES = dbo.fn_CorrigirMojibake(OBSERVACOES);
GO
UPDATE HISTORICO_TREINOS
SET NOME_TREINO = dbo.fn_CorrigirMojibake(NOME_TREINO),
    OBSERVACAO_ALUNO = dbo.fn_CorrigirMojibake(OBSERVACAO_ALUNO);
GO
UPDATE PAGAMENTOS
SET FORMA_PAGAMENTO = dbo.fn_CorrigirMojibake(FORMA_PAGAMENTO),
    OBSERVACAO = dbo.fn_CorrigirMojibake(OBSERVACAO);
GO
UPDATE NOTIFICACOES
SET TITULO = dbo.fn_CorrigirMojibake(TITULO),
    MENSAGEM = dbo.fn_CorrigirMojibake(MENSAGEM);
GO
UPDATE PLANOS_ALIMENTARES
SET TITULO = dbo.fn_CorrigirMojibake(TITULO),
    OBJETIVO = dbo.fn_CorrigirMojibake(OBJETIVO),
    OBSERVACOES = dbo.fn_CorrigirMojibake(OBSERVACOES);
GO
UPDATE REFEICOES_PLANO
SET NOME_REFEICAO = dbo.fn_CorrigirMojibake(NOME_REFEICAO),
    ALIMENTOS_DESCRICAO = dbo.fn_CorrigirMojibake(ALIMENTOS_DESCRICAO),
    SUBSTITUICOES = dbo.fn_CorrigirMojibake(SUBSTITUICOES);
GO
UPDATE AGENDA_AULAS
SET TIPO_AULA = dbo.fn_CorrigirMojibake(TIPO_AULA),
    OBSERVACOES = dbo.fn_CorrigirMojibake(OBSERVACOES);
GO
