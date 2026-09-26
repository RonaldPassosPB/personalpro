-- ============================================================================
-- PERSONALPRO SAAS — MIGRAÇÃO V4 (VÍDEOS REAIS EM PORTUGUÊS DO BRASIL PT-BR)
-- Atualiza EXERCICIOS_BASE e FICHA_EXERCICIOS com vídeos reais de execução
-- em Português do Brasil (YouTube PT-BR HD com embed liberado)
-- ============================================================================
USE PersonalPro;
GO

-- 1. ATUALIZA BIBLIOTECA GLOBAL DE EXERCÍCIOS (EXERCICIOS_BASE) COM VÍDEOS PT-BR
UPDATE EXERCICIOS_BASE SET VIDEO_URL = 'https://www.youtube.com/watch?v=pCPyqW60Wuk' WHERE NOME LIKE '%Supino Reto%';
UPDATE EXERCICIOS_BASE SET VIDEO_URL = 'https://www.youtube.com/watch?v=Fa-X2ByLHaY' WHERE NOME LIKE '%Supino Inclinado%';
UPDATE EXERCICIOS_BASE SET VIDEO_URL = 'https://www.youtube.com/watch?v=MENdoLpyj7c' WHERE NOME LIKE '%Crucifixo%' OR NOME LIKE '%Peck Deck%' OR NOME LIKE '%Voador%';
UPDATE EXERCICIOS_BASE SET VIDEO_URL = 'https://www.youtube.com/watch?v=_hdQD_E3deE' WHERE NOME LIKE '%Crossover%';
UPDATE EXERCICIOS_BASE SET VIDEO_URL = 'https://www.youtube.com/watch?v=pCPyqW60Wuk' WHERE GRUPO_MUSCULAR = 'Peito' AND (VIDEO_URL IS NULL OR VIDEO_URL NOT LIKE 'https://www.youtube.com/watch?v=pCPyqW60Wuk%');

UPDATE EXERCICIOS_BASE SET VIDEO_URL = 'https://www.youtube.com/watch?v=ftcql3-AMRs' WHERE NOME LIKE '%Puxada%' OR NOME LIKE '%Barra Fixa%';
UPDATE EXERCICIOS_BASE SET VIDEO_URL = 'https://www.youtube.com/watch?v=SbuXAFpDUkI' WHERE NOME LIKE '%Remada Curvada%' OR NOME LIKE '%Cavalinho%';
UPDATE EXERCICIOS_BASE SET VIDEO_URL = 'https://www.youtube.com/watch?v=zw0lUIPCq-U' WHERE NOME LIKE '%Remada Baixa%' OR NOME LIKE '%Serrote%' OR NOME LIKE '%Pulldown%';
UPDATE EXERCICIOS_BASE SET VIDEO_URL = 'https://www.youtube.com/watch?v=ftcql3-AMRs' WHERE GRUPO_MUSCULAR = 'Costas' AND VIDEO_URL IS NULL;

UPDATE EXERCICIOS_BASE SET VIDEO_URL = 'https://www.youtube.com/watch?v=3vTRFnzCMaA' WHERE NOME LIKE '%Agachamento%' OR NOME LIKE '%Hack%' OR NOME LIKE '%Afundo%' OR NOME LIKE '%Búlgaro%';
UPDATE EXERCICIOS_BASE SET VIDEO_URL = 'https://www.youtube.com/watch?v=DQ4-HXFlKXI' WHERE NOME LIKE '%Leg Press%';
UPDATE EXERCICIOS_BASE SET VIDEO_URL = 'https://www.youtube.com/watch?v=y7GhuVphn4s' WHERE NOME LIKE '%Extensora%';
UPDATE EXERCICIOS_BASE SET VIDEO_URL = 'https://www.youtube.com/watch?v=umxlbgCK6oc' WHERE NOME LIKE '%Flexora%';
UPDATE EXERCICIOS_BASE SET VIDEO_URL = 'https://www.youtube.com/watch?v=6PWws7e_z-s' WHERE NOME LIKE '%Stiff%' OR NOME LIKE '%Terra%';
UPDATE EXERCICIOS_BASE SET VIDEO_URL = 'https://www.youtube.com/watch?v=Q85EzsgleaE' WHERE NOME LIKE '%Elevação Pélvica%' OR NOME LIKE '%Abdutora%';
UPDATE EXERCICIOS_BASE SET VIDEO_URL = 'https://www.youtube.com/watch?v=EILF4iyBxSQ' WHERE NOME LIKE '%Panturrilha%';
UPDATE EXERCICIOS_BASE SET VIDEO_URL = 'https://www.youtube.com/watch?v=3vTRFnzCMaA' WHERE GRUPO_MUSCULAR = 'Pernas' AND VIDEO_URL IS NULL;

UPDATE EXERCICIOS_BASE SET VIDEO_URL = 'https://www.youtube.com/watch?v=DFXtzdXN_iY' WHERE NOME LIKE '%Desenvolvimento%' OR NOME LIKE '%Arnold%';
UPDATE EXERCICIOS_BASE SET VIDEO_URL = 'https://www.youtube.com/watch?v=yURmeIEl1Fg' WHERE NOME LIKE '%Elevação Lateral%' OR NOME LIKE '%Elevação Frontal%' OR NOME LIKE '%Crucifixo Inverso%' OR NOME LIKE '%Encolhimento%';
UPDATE EXERCICIOS_BASE SET VIDEO_URL = 'https://www.youtube.com/watch?v=yURmeIEl1Fg' WHERE GRUPO_MUSCULAR = 'Ombros' AND VIDEO_URL IS NULL;

UPDATE EXERCICIOS_BASE SET VIDEO_URL = 'https://www.youtube.com/watch?v=fjS0CqDR4v8' WHERE NOME LIKE '%Rosca Direta%' OR NOME LIKE '%Rosca Scott%' OR NOME LIKE '%Rosca Inclinada%' OR NOME LIKE '%Rosca Concentrada%';
UPDATE EXERCICIOS_BASE SET VIDEO_URL = 'https://www.youtube.com/watch?v=GilFwBs_kOs' WHERE NOME LIKE '%Rosca Martelo%';
UPDATE EXERCICIOS_BASE SET VIDEO_URL = 'https://www.youtube.com/watch?v=fjS0CqDR4v8' WHERE GRUPO_MUSCULAR LIKE 'B%ceps' AND VIDEO_URL IS NULL;

UPDATE EXERCICIOS_BASE SET VIDEO_URL = 'https://www.youtube.com/watch?v=VnFopAIGO7E' WHERE NOME LIKE '%Tríceps Pulley%' OR NOME LIKE '%Tríceps Corda%' OR NOME LIKE '%Mergulho%';
UPDATE EXERCICIOS_BASE SET VIDEO_URL = 'https://www.youtube.com/watch?v=CF6N7CfABIg' WHERE NOME LIKE '%Tríceps Testa%' OR NOME LIKE '%Tríceps Francês%';
UPDATE EXERCICIOS_BASE SET VIDEO_URL = 'https://www.youtube.com/watch?v=VnFopAIGO7E' WHERE GRUPO_MUSCULAR LIKE 'Tr%ceps' AND VIDEO_URL IS NULL;

UPDATE EXERCICIOS_BASE SET VIDEO_URL = 'https://www.youtube.com/watch?v=ffHr8a6DRvU' WHERE GRUPO_MUSCULAR LIKE 'Abd%men';

-- 2. ATUALIZA EXERCÍCIOS JÁ PRESCRITOS NAS FICHAS DOS ALUNOS (FICHA_EXERCICIOS) COM VÍDEOS PT-BR
UPDATE FICHA_EXERCICIOS SET VIDEO_URL = 'https://www.youtube.com/watch?v=pCPyqW60Wuk' WHERE NOME_EXERCICIO LIKE '%Supino Reto%';
UPDATE FICHA_EXERCICIOS SET VIDEO_URL = 'https://www.youtube.com/watch?v=Fa-X2ByLHaY' WHERE NOME_EXERCICIO LIKE '%Supino Inclinado%';
UPDATE FICHA_EXERCICIOS SET VIDEO_URL = 'https://www.youtube.com/watch?v=MENdoLpyj7c' WHERE NOME_EXERCICIO LIKE '%Crucifixo%' OR NOME_EXERCICIO LIKE '%Peck Deck%' OR NOME_EXERCICIO LIKE '%Voador%';
UPDATE FICHA_EXERCICIOS SET VIDEO_URL = 'https://www.youtube.com/watch?v=_hdQD_E3deE' WHERE NOME_EXERCICIO LIKE '%Crossover%';
UPDATE FICHA_EXERCICIOS SET VIDEO_URL = 'https://www.youtube.com/watch?v=DFXtzdXN_iY' WHERE NOME_EXERCICIO LIKE '%Desenvolvimento%';
UPDATE FICHA_EXERCICIOS SET VIDEO_URL = 'https://www.youtube.com/watch?v=yURmeIEl1Fg' WHERE NOME_EXERCICIO LIKE '%Elevação Lateral%';
UPDATE FICHA_EXERCICIOS SET VIDEO_URL = 'https://www.youtube.com/watch?v=VnFopAIGO7E' WHERE NOME_EXERCICIO LIKE '%Tríceps Pulley%' OR NOME_EXERCICIO LIKE '%Tríceps Corda%';
UPDATE FICHA_EXERCICIOS SET VIDEO_URL = 'https://www.youtube.com/watch?v=CF6N7CfABIg' WHERE NOME_EXERCICIO LIKE '%Tríceps Testa%';
UPDATE FICHA_EXERCICIOS SET VIDEO_URL = 'https://www.youtube.com/watch?v=ftcql3-AMRs' WHERE NOME_EXERCICIO LIKE '%Puxada%';
UPDATE FICHA_EXERCICIOS SET VIDEO_URL = 'https://www.youtube.com/watch?v=SbuXAFpDUkI' WHERE NOME_EXERCICIO LIKE '%Remada Curvada%';
UPDATE FICHA_EXERCICIOS SET VIDEO_URL = 'https://www.youtube.com/watch?v=zw0lUIPCq-U' WHERE NOME_EXERCICIO LIKE '%Remada Baixa%';
UPDATE FICHA_EXERCICIOS SET VIDEO_URL = 'https://www.youtube.com/watch?v=fjS0CqDR4v8' WHERE NOME_EXERCICIO LIKE '%Rosca Direta%';
UPDATE FICHA_EXERCICIOS SET VIDEO_URL = 'https://www.youtube.com/watch?v=GilFwBs_kOs' WHERE NOME_EXERCICIO LIKE '%Rosca Martelo%';
UPDATE FICHA_EXERCICIOS SET VIDEO_URL = 'https://www.youtube.com/watch?v=3vTRFnzCMaA' WHERE NOME_EXERCICIO LIKE '%Agachamento%';
UPDATE FICHA_EXERCICIOS SET VIDEO_URL = 'https://www.youtube.com/watch?v=DQ4-HXFlKXI' WHERE NOME_EXERCICIO LIKE '%Leg Press%';
UPDATE FICHA_EXERCICIOS SET VIDEO_URL = 'https://www.youtube.com/watch?v=y7GhuVphn4s' WHERE NOME_EXERCICIO LIKE '%Extensora%';
UPDATE FICHA_EXERCICIOS SET VIDEO_URL = 'https://www.youtube.com/watch?v=umxlbgCK6oc' WHERE NOME_EXERCICIO LIKE '%Flexora%';
UPDATE FICHA_EXERCICIOS SET VIDEO_URL = 'https://www.youtube.com/watch?v=6PWws7e_z-s' WHERE NOME_EXERCICIO LIKE '%Stiff%';
UPDATE FICHA_EXERCICIOS SET VIDEO_URL = 'https://www.youtube.com/watch?v=Q85EzsgleaE' WHERE NOME_EXERCICIO LIKE '%Elevação Pélvica%';
UPDATE FICHA_EXERCICIOS SET VIDEO_URL = 'https://www.youtube.com/watch?v=EILF4iyBxSQ' WHERE NOME_EXERCICIO LIKE '%Panturrilha%';
UPDATE FICHA_EXERCICIOS SET VIDEO_URL = 'https://www.youtube.com/watch?v=ffHr8a6DRvU' WHERE NOME_EXERCICIO LIKE '%Abdominal%' OR NOME_EXERCICIO LIKE '%Prancha%';

PRINT '✅ Vídeos reais em Português do Brasil (PT-BR) aplicados em todos os exercícios!';
GO
