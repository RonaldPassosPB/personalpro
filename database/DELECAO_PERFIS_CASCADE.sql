-- ====================================================================================
-- PERSONALPRO / COACH CENTER — CONSULTA E EXCLUSÃO EM CASCATA DE PERFIS (SQL SERVER)
-- ====================================================================================
-- Este script permite:
-- 1) Visualizar todos os Usuários, Personais e Alunos com senhas de login e status
-- 2) Excluir um ALUNO específico (e todos os seus treinos, dietas, pagamentos, avaliações)
-- 3) Excluir um PERSONAL TRAINER específico (e toda a sua consultoria em cascata)
-- ====================================================================================

USE [coachcenter-db]; -- Ou PersonalPro se for local
GO

-- ────────────────────────────────────────────────────────────────────────────────────
-- 1. SELECT GERAL: VISUALIZAR TODOS OS PERFIS E LOGINS
-- ────────────────────────────────────────────────────────────────────────────────────

-- 1.1 Todos os Usuários do Sistema (SuperAdmin, Personais e Alunos)
SELECT 
    U.ID               AS UsuarioId,
    U.NOME             AS Nome,
    U.EMAIL            AS EmailLogin,
    CASE U.PERFIL 
        WHEN 1 THEN 'PERSONAL TRAINER' 
        WHEN 2 THEN 'ALUNO' 
        WHEN 3 THEN 'SUPERADMIN (DONO)' 
    END                AS Perfil,
    CASE U.STATUS 
        WHEN 1 THEN 'ATIVO' 
        ELSE 'BLOQUEADO' 
    END                AS StatusUsuario,
    U.PERSONAL_ID      AS PersonalIdVinculado,
    P.NOME_PROFISSIONAL AS NomeConsultoria,
    U.DATA_CADASTRO    AS DataCadastro
FROM USUARIOS U
LEFT JOIN PERSONAIS P ON P.ID = U.PERSONAL_ID
ORDER BY U.PERFIL DESC, U.NOME ASC;
GO

-- 1.2 Todos os Personais Trainers Cadastrados (com Status Financeiro e Vencimento)
SELECT 
    P.ID                    AS PersonalId,
    P.NOME_PROFISSIONAL     AS NomePersonal,
    P.EMAIL                 AS EmailLogin,
    P.CREF                  AS Cref,
    P.TELEFONE              AS Telefone,
    P.CHAVE_PIX             AS ChavePix,
    P.PLANO                 AS Plano,
    CASE P.STATUS 
        WHEN 1 THEN 'ATIVO' 
        ELSE 'BLOQUEADO' 
    END                     AS StatusAssinatura,
    P.VALOR_ASSINATURA      AS MensalidadeSaaS,
    P.DIA_VENCIMENTO        AS DiaVencimento,
    ISNULL(P.ULTIMO_PAGAMENTO_MES, 'NUNCA') AS UltimoPagamentoMes,
    (SELECT COUNT(1) FROM ALUNOS A WHERE A.PERSONAL_ID = P.ID) AS QtdAlunos,
    P.DATA_CADASTRO         AS DataCadastro
FROM PERSONAIS P
ORDER BY P.ID ASC;
GO

-- 1.3 Todos os Alunos Cadastrados
SELECT 
    A.ID                    AS AlunoId,
    A.USUARIO_ID            AS UsuarioId,
    U.NOME                  AS NomeAluno,
    U.EMAIL                 AS EmailLogin,
    A.TELEFONE              AS Telefone,
    A.OBJETIVO              AS Objetivo,
    A.VALOR_MENSALIDADE     AS ValorMensalidade,
    A.DIA_VENCIMENTO        AS DiaVencimento,
    P.NOME_PROFISSIONAL     AS PersonalResponsavel,
    CASE U.STATUS 
        WHEN 1 THEN 'ATIVO' 
        ELSE 'BLOQUEADO' 
    END                     AS StatusAluno,
    A.DATA_CADASTRO         AS DataCadastro
FROM ALUNOS A
INNER JOIN USUARIOS U ON U.ID = A.USUARIO_ID
LEFT JOIN PERSONAIS P ON P.ID = A.PERSONAL_ID
ORDER BY P.NOME_PROFISSIONAL, U.NOME;
GO


-- ────────────────────────────────────────────────────────────────────────────────────
-- 2. PROCEDIMENTO DE EXCLUSÃO SEGURA EM CASCATA: APENAS 1 ALUNO
-- ────────────────────────────────────────────────────────────────────────────────────
-- Para usar: Substitua o ID ou Email do aluno na variável @AlunoIdOuEmail
-- ────────────────────────────────────────────────────────────────────────────────────

BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @AlunoId INT = 0;
    DECLARE @UsuarioId INT = 0;
    DECLARE @NomeAluno NVARCHAR(150) = '';

    -- DEFINA AQUI O ID DO ALUNO (Tabela ALUNOS) OU O EMAIL:
    SET @AlunoId = 0; -- <<<<< COLOQUE O ID DO ALUNO AQUI (ex: 5)
    -- OU busque pelo email:
    -- SELECT @AlunoId = ID FROM ALUNOS WHERE USUARIO_ID = (SELECT ID FROM USUARIOS WHERE EMAIL = 'aluno@teste.com');

    IF @AlunoId > 0
    BEGIN
        SELECT @UsuarioId = USUARIO_ID FROM ALUNOS WHERE ID = @AlunoId;
        SELECT @NomeAluno = NOME FROM USUARIOS WHERE ID = @UsuarioId;

        PRINT 'Iniciando delecao em cascata do Aluno ID: ' + CAST(@AlunoId AS VARCHAR) + ' - ' + ISNULL(@NomeAluno, '');

        -- 1. Excluir Itens das Refeições do Plano Alimentar do Aluno
        DELETE RP
        FROM REFEICOES_PLANO RP
        INNER JOIN PLANOS_ALIMENTARES PA ON PA.ID = RP.PLANO_ID
        WHERE PA.ALUNO_ID = @AlunoId;

        -- 2. Excluir Planos Alimentares do Aluno
        DELETE FROM PLANOS_ALIMENTARES WHERE ALUNO_ID = @AlunoId;

        -- 3. Excluir Agendamentos de Aulas do Aluno
        DELETE FROM AGENDA_AULAS WHERE ALUNO_ID = @AlunoId;

        -- 4. Excluir Histórico de Cargas do Aluno
        DELETE FROM PROGRESSAO_CARGAS WHERE ALUNO_ID = @AlunoId;

        -- 5. Excluir Histórico de Treinos do Aluno
        DELETE FROM HISTORICO_TREINOS WHERE ALUNO_ID = @AlunoId;

        -- 6. Excluir Pagamentos/Cobranças do Aluno
        DELETE FROM PAGAMENTOS WHERE ALUNO_ID = @AlunoId;

        -- 7. Excluir Avaliações Físicas e Fotos do Aluno
        DELETE FROM AVALIACOES_FISICAS WHERE ALUNO_ID = @AlunoId;

        -- 8. Excluir Exercícios das Fichas de Treino do Aluno
        DELETE FE
        FROM FICHA_EXERCICIOS FE
        INNER JOIN FICHAS_TREINO FT ON FT.ID = FE.FICHA_ID
        WHERE FT.ALUNO_ID = @AlunoId;

        -- 9. Excluir Fichas de Treino do Aluno
        DELETE FROM FICHAS_TREINO WHERE ALUNO_ID = @AlunoId;

        -- 10. Excluir Notificações do Aluno
        DELETE FROM NOTIFICACOES WHERE USUARIO_ID = @UsuarioId;

        -- 11. Excluir Registro na Tabela ALUNOS
        DELETE FROM ALUNOS WHERE ID = @AlunoId;

        -- 12. Excluir Registro de Login na Tabela USUARIOS
        DELETE FROM USUARIOS WHERE ID = @UsuarioId;

        COMMIT TRANSACTION;
        PRINT 'SUCESSO: Aluno ' + ISNULL(@NomeAluno, '') + ' excluido com sucesso em todas as 12 tabelas!';
    END
    ELSE
    BEGIN
        PRINT 'Nenhum Aluno selecionado para exclusao. Defina @AlunoId > 0.';
        ROLLBACK TRANSACTION;
    END
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'ERRO AO EXCLUIR ALUNO: ' + ERROR_MESSAGE();
END CATCH;
GO


-- ────────────────────────────────────────────────────────────────────────────────────
-- 3. PROCEDIMENTO DE EXCLUSÃO SEGURA EM CASCATA: PERSONAL TRAINER COMPLETO
-- ────────────────────────────────────────────────────────────────────────────────────
-- Para usar: Substitua o ID na variável @PersonalId
-- Isso apaga o Personal, todos os alunos dele, treinos, dietas, pagamentos e fotos.
-- ────────────────────────────────────────────────────────────────────────────────────

BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @PersonalId INT = 0; -- <<<<< COLOQUE O ID DO PERSONAL AQUI (ex: 2)
    DECLARE @NomePersonal NVARCHAR(150) = '';

    IF @PersonalId > 0
    BEGIN
        SELECT @NomePersonal = NOME_PROFISSIONAL FROM PERSONAIS WHERE ID = @PersonalId;

        PRINT 'Iniciando delecao em cascata do Personal ID: ' + CAST(@PersonalId AS VARCHAR) + ' - ' + ISNULL(@NomePersonal, '');

        -- 1. Excluir Refeições de Dietas do Personal
        DELETE RP
        FROM REFEICOES_PLANO RP
        INNER JOIN PLANOS_ALIMENTARES PA ON PA.ID = RP.PLANO_ID
        WHERE PA.PERSONAL_ID = @PersonalId;

        -- 2. Excluir Planos Alimentares do Personal
        DELETE FROM PLANOS_ALIMENTARES WHERE PERSONAL_ID = @PersonalId;

        -- 3. Excluir Aulas Agendadas
        DELETE FROM AGENDA_AULAS WHERE PERSONAL_ID = @PersonalId;

        -- 4. Excluir Progressões de Carga
        DELETE FROM PROGRESSAO_CARGAS WHERE PERSONAL_ID = @PersonalId;

        -- 5. Excluir Histórico de Treinos
        DELETE FROM HISTORICO_TREINOS WHERE PERSONAL_ID = @PersonalId;

        -- 6. Excluir Pagamentos
        DELETE FROM PAGAMENTOS WHERE PERSONAL_ID = @PersonalId;

        -- 7. Excluir Avaliações Físicas
        DELETE FROM AVALIACOES_FISICAS WHERE PERSONAL_ID = @PersonalId;

        -- 8. Excluir Exercícios de Fichas do Personal
        DELETE FE
        FROM FICHA_EXERCICIOS FE
        INNER JOIN FICHAS_TREINO FT ON FT.ID = FE.FICHA_ID
        WHERE FT.PERSONAL_ID = @PersonalId;

        -- 9. Excluir Fichas de Treino do Personal
        DELETE FROM FICHAS_TREINO WHERE PERSONAL_ID = @PersonalId;

        -- 10. Excluir Exercícios Customizados do Personal na Biblioteca
        DELETE FROM EXERCICIOS_BASE WHERE PERSONAL_ID = @PersonalId;

        -- 11. Excluir Notificações do Personal e de seus Alunos
        DELETE FROM NOTIFICACOES WHERE PERSONAL_ID = @PersonalId;

        -- 12. Excluir Alunos vinculados ao Personal
        DELETE FROM ALUNOS WHERE PERSONAL_ID = @PersonalId;

        -- 13. Excluir Usuários (Login do Personal + Logins de todos os seus alunos)
        DELETE FROM USUARIOS WHERE PERSONAL_ID = @PersonalId;

        -- 14. Excluir o Personal Trainer
        DELETE FROM PERSONAIS WHERE ID = @PersonalId;

        COMMIT TRANSACTION;
        PRINT 'SUCESSO: Personal Trainer ' + ISNULL(@NomePersonal, '') + ' e todos os seus alunos/dados foram excluidos em cascata!';
    END
    ELSE
    BEGIN
        PRINT 'Nenhum Personal selecionado para exclusao. Defina @PersonalId > 0.';
        ROLLBACK TRANSACTION;
    END
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'ERRO AO EXCLUIR PERSONAL: ' + ERROR_MESSAGE();
END CATCH;
GO

