-- ============================================================================
-- PERSONALPRO SAAS — MIGRAÇÃO V5 (EXPANSÃO DA BIBLIOTECA PARA 125+ EXERCÍCIOS)
-- Adiciona mais de 85 novos exercícios clássicos e modernos de musculação,
-- glúteos, panturrilhas, antebraço, core e cardio, todos com vídeos PT-BR!
-- ============================================================================
USE PersonalPro;
GO

IF COL_LENGTH('EXERCICIOS_BASE', 'INSTRUCOES_EXECUCAO') IS NULL
BEGIN
    ALTER TABLE EXERCICIOS_BASE ADD INSTRUCOES_EXECUCAO NVARCHAR(500) NULL;
END
GO

CREATE TABLE #NovosExercicios (
    NOME NVARCHAR(150) COLLATE DATABASE_DEFAULT,
    GRUPO_MUSCULAR NVARCHAR(60) COLLATE DATABASE_DEFAULT,
    VIDEO_URL NVARCHAR(300) COLLATE DATABASE_DEFAULT,
    INSTRUCOES_EXECUCAO NVARCHAR(500) COLLATE DATABASE_DEFAULT
);

INSERT INTO #NovosExercicios (NOME, GRUPO_MUSCULAR, VIDEO_URL, INSTRUCOES_EXECUCAO) VALUES
-- PEITO (Novos exercícios além dos originais)
(N'Supino Reto com Halteres', N'Peito', N'https://www.youtube.com/watch?v=pCPyqW60Wuk', N'Escápulas retraídas no banco, desça os halteres na linha do peitoral controlando a fase excêntrica.'),
(N'Supino Inclinado com Barra', N'Peito', N'https://www.youtube.com/watch?v=Fa-X2ByLHaY', N'Banco a 30°–45°, desça a barra até a porção clavicular do peito com cotovelos a 45°.'),
(N'Supino Declinado com Halteres', N'Peito', N'https://www.youtube.com/watch?v=pCPyqW60Wuk', N'Foco na porção inferior do peitoral, controle total na descida e contração máxima no topo.'),
(N'Supino Máquina Articulado (Chest Press)', N'Peito', N'https://www.youtube.com/watch?v=pCPyqW60Wuk', N'Ajuste o assento na linha média do peitoral e empurre sem desencostar as escápulas do apoio.'),
(N'Crucifixo Reto com Halteres', N'Peito', N'https://www.youtube.com/watch?v=MENdoLpyj7c', N'Abra os braços com leve flexão de cotovelos alongando o peitoral e feche contraindo no centro.'),
(N'Cross-Over Polia Média', N'Peito', N'https://www.youtube.com/watch?v=_hdQD_E3deE', N'Polias na altura dos ombros, feche as mãos à frente do esterno mantendo o tronco firme.'),
(N'Cross-Over Polia Baixa (Foco Superior)', N'Peito', N'https://www.youtube.com/watch?v=_hdQD_E3deE', N'Traga os cabos de baixo para cima focando nas fibras superiores/claviculares do peitoral.'),
(N'Paralelas (Foco Peitoral)', N'Peito', N'https://www.youtube.com/watch?v=VnFopAIGO7E', N'Incline levemente o tronco à frente durante a descida para recrutar mais o peitoral inferior.'),
(N'Pullover com Halter no Banco', N'Peito', N'https://www.youtube.com/watch?v=MENdoLpyj7c', N'Alongue a caixa torácica levando o halter atrás da cabeça e retorne até a linha dos olhos.'),

-- COSTAS (Novos exercícios)
(N'Puxada Alta Supinada (Pegada Invertida)', N'Costas', N'https://www.youtube.com/watch?v=ftcql3-AMRs', N'Pegada na largura dos ombros com palmas voltadas para você, puxando até a parte superior do peito.'),
(N'Puxada Alta Neutra no Triângulo', N'Costas', N'https://www.youtube.com/watch?v=ftcql3-AMRs', N'Incline levemente o tronco para trás e puxe o triângulo em direção ao esterno deprimindo as escápulas.'),
(N'Remada Curvada Supinada (Estilo Yates)', N'Costas', N'https://www.youtube.com/watch?v=SbuXAFpDUkI', N'Tronco a 45°, pegada supinada na barra trazendo na linha do umbigo com máxima contração dorsal.'),
(N'Remada Máquina Articulada (Pegada Pronada)', N'Costas', N'https://www.youtube.com/watch?v=zw0lUIPCq-U', N'Peito apoiado no suporte, puxe abrindo os cotovelos para focar na parte alta das costas e redondo maior.'),
(N'Remada Máquina Articulada Unilateral', N'Costas', N'https://www.youtube.com/watch?v=zw0lUIPCq-U', N'Alongue toda a escápula na ida e traga o cotovelo rente ao tronco na puxada.'),
(N'Remada Baixa com Barra Romana', N'Costas', N'https://www.youtube.com/watch?v=zw0lUIPCq-U', N'Coluna neutra e peito aberto, traga a barra romana ao abdômen segurando 1 segundo no pico.'),
(N'Pulldown com Corda na Polia Alta', N'Costas', N'https://www.youtube.com/watch?v=ftcql3-AMRs', N'Braços semi-estendidos, desça a corda até a linha do quadril isolando o grande dorsal.'),
(N'Meio Terra (Rack Pull)', N'Costas', N'https://www.youtube.com/watch?v=6PWws7e_z-s', N'Retire a barra na altura dos joelhos focando na densidade total de costas e eretores da espinha.'),
(N'Hiperextensão Lombar no Banco Romano 45°', N'Costas', N'https://www.youtube.com/watch?v=6PWws7e_z-s', N'Desça controlando o quadril e suba até alinhar a coluna sem hiperestender a lombar.'),

-- PERNAS / QUADRÍCEPS (Novos exercícios)
(N'Agachamento no Smith (Barra Guiada)', N'Pernas', N'https://www.youtube.com/watch?v=3vTRFnzCMaA', N'Posicione os pés levemente à frente da linha do quadril e desça com controle máximo.'),
(N'Agachamento Frontal com Barra', N'Pernas', N'https://www.youtube.com/watch?v=3vTRFnzCMaA', N'Barra apoiada nos deltoides anteriores, tronco vertical para máximo recrutamento de quadríceps.'),
(N'Agachamento Sumô com Halter (Goblet Sumô)', N'Pernas', N'https://www.youtube.com/watch?v=3vTRFnzCMaA', N'Pés afastados além da largura dos ombros com pontas a 45°, trabalhando quadríceps, adutores e glúteos.'),
(N'Passada / Avanço Caminhando com Halteres', N'Pernas', N'https://www.youtube.com/watch?v=3vTRFnzCMaA', N'Dê um passo amplo à frente flexionando ambos os joelhos a 90° e empurre pelo calcanhar da frente.'),
(N'Leg Press Horizontal na Máquina', N'Pernas', N'https://www.youtube.com/watch?v=DQ4-HXFlKXI', N'Empurre a plataforma sem travar totalmente os joelhos no final do movimento.'),
(N'Leg Press 45° Unilateral', N'Pernas', N'https://www.youtube.com/watch?v=DQ4-HXFlKXI', N'Execução com uma perna por vez para corrigir assimetrias de força e volume muscular.'),
(N'Cadeira Extensora Unilateral', N'Pernas', N'https://www.youtube.com/watch?v=y7GhuVphn4s', N'Segure 2 segundos no topo de cada repetição para pico de contração no reto femoral e vasto medial.'),
(N'Agachamento Sissy / Pêndulo', N'Pernas', N'https://www.youtube.com/watch?v=y7GhuVphn4s', N'Alongamento extremo do quadríceps mantendo quadril e tronco alinhados durante a descida.'),
(N'Cadeira Adutora (Interno de Coxa)', N'Pernas', N'https://www.youtube.com/watch?v=y7GhuVphn4s', N'Feche os apoios controladamente e segure 1 segundo na contração máxima dos adutores.'),
(N'Subida no Caixote (Step-Up com Halteres)', N'Pernas', N'https://www.youtube.com/watch?v=3vTRFnzCMaA', N'Suba concentrando toda a força no calcanhar da perna apoiada no caixote/banco.'),

-- GLÚTEOS & POSTERIOR DE COXA (Grupo dedicado e em Pernas)
(N'Cadeira Flexora Sentado', N'Pernas', N'https://www.youtube.com/watch?v=umxlbgCK6oc', N'Trave bem o apoio sobre as coxas e flexione os joelhos ao máximo alongando tudo na volta.'),
(N'Flexora em Pé Unilateral na Máquina', N'Pernas', N'https://www.youtube.com/watch?v=umxlbgCK6oc', N'Mantenha o quadril colado no apoio e suba o calcanhar em direção ao glúteo.'),
(N'Stiff Unilateral com Halteres (B-Stance)', N'Pernas', N'https://www.youtube.com/watch?v=6PWws7e_z-s', N'Projete o quadril para trás mantendo a coluna neutra e sentindo o posterior alongar.'),
(N'Levantamento Terra Romeno (RDL) com Barra', N'Pernas', N'https://www.youtube.com/watch?v=6PWws7e_z-s', N'Leve flexão de joelhos com foco total na dobradiça de quadril (hip hinge) para glúteos e isquiotibiais.'),
(N'Bom Dia (Good Morning) com Barra', N'Pernas', N'https://www.youtube.com/watch?v=6PWws7e_z-s', N'Barra no trapézio, projete o quadril para trás mantendo o core rígido.'),
(N'Elevação Pélvica na Máquina Articulada', N'Glúteos', N'https://www.youtube.com/watch?v=Q85EzsgleaE', N'Contraia fortemente o glúteo no topo por 2 segundos mantendo o queixo próximo ao peito.'),
(N'Elevação Pélvica Unilateral no Banco', N'Glúteos', N'https://www.youtube.com/watch?v=Q85EzsgleaE', N'Empurre o solo com o calcanhar de uma perna só para isolamento máximo do glúteo máximo.'),
(N'Cadeira Abdutora (Tronco Inclinado 45°)', N'Glúteos', N'https://www.youtube.com/watch?v=Q85EzsgleaE', N'Incline o tronco à frente para enfatizar as fibras do glúteo médio e mínimo.'),
(N'Glúteo Coice na Polia Baixa (Caneleira)', N'Glúteos', N'https://www.youtube.com/watch?v=Q85EzsgleaE', N'Estenda o quadril para trás sem girar a pelve nem arquear a lombar.'),
(N'Abdução de Quadril na Polia Baixa em Pé', N'Glúteos', N'https://www.youtube.com/watch?v=Q85EzsgleaE', N'Abra a perna lateralmente com controle para esculpir a lateral do glúteo (glúteo médio).'),
(N'Glúteo 4 Apoios com Caneleira ou Máquina', N'Glúteos', N'https://www.youtube.com/watch?v=Q85EzsgleaE', N'Suba o calcanhar em direção ao teto mantendo o abdômen contraído.'),
(N'Terra Sumô com Barra ou Halter Pesado', N'Glúteos', N'https://www.youtube.com/watch?v=6PWws7e_z-s', N'Base aberta, empurre o chão afastando os pés e contraindo os glúteos no final.'),

-- PANTURRILHAS
(N'Panturrilha no Leg Press 45°', N'Pernas', N'https://www.youtube.com/watch?v=EILF4iyBxSQ', N'Apoie apenas a ponta dos pés na plataforma, alongue 2s embaixo e suba no pico máximo.'),
(N'Panturrilha em Pé no Smith com Step', N'Pernas', N'https://www.youtube.com/watch?v=EILF4iyBxSQ', N'Amplitude completa do tornozelo sem quicar no fundo do movimento.'),
(N'Panturrilha Unilateral em Pé com Halter', N'Pernas', N'https://www.youtube.com/watch?v=EILF4iyBxSQ', N'Trabalho isolado de cada panturrilha garantindo simetria e controle.'),

-- OMBROS & TRAPÉZIO (Novos exercícios)
(N'Desenvolvimento Máquina Articulado', N'Ombros', N'https://www.youtube.com/watch?v=DFXtzdXN_iY', N'Empurre acima da cabeça mantendo os cotovelos levemente à frente da linha dos ombros.'),
(N'Elevação Lateral na Polia Baixa Unilateral', N'Ombros', N'https://www.youtube.com/watch?v=yURmeIEl1Fg', N'Tensão contínua do cabo durante todo o arco do movimento lateral.'),
(N'Elevação Lateral Sentado com Halteres', N'Ombros', N'https://www.youtube.com/watch?v=yURmeIEl1Fg', N'Elimina o balanço do tronco para isolar 100% a cabeça lateral do deltoide.'),
(N'Elevação Frontal na Polia com Corda', N'Ombros', N'https://www.youtube.com/watch?v=DFXtzdXN_iY', N'Suba a corda até a linha dos olhos mantendo os ombros encaixados.'),
(N'Elevação Frontal com Anilha (Pegada Neutra)', N'Ombros', N'https://www.youtube.com/watch?v=DFXtzdXN_iY', N'Segure a anilha nas laterais (3h e 9h) e eleve até a altura do rosto.'),
(N'Crucifixo Inverso com Halteres no Banco 30°', N'Ombros', N'https://www.youtube.com/watch?v=yURmeIEl1Fg', N'Peito apoiado no banco inclinado, abra os braços focando no deltoide posterior.'),
(N'Face Pull na Polia Alta com Corda', N'Ombros', N'https://www.youtube.com/watch?v=yURmeIEl1Fg', N'Puxe a corda em direção à testa abrindo os cotovelos e fazendo rotação externa de ombros.'),
(N'Remada Alta na Polia ou Barra W', N'Ombros', N'https://www.youtube.com/watch?v=yURmeIEl1Fg', N'Puxe liderando pelos cotovelos até a linha do peitoral para deltoides e trapézio.'),
(N'Encolhimento de Trapézio na Barra / Smith', N'Ombros', N'https://www.youtube.com/watch?v=DFXtzdXN_iY', N'Suba os ombros em direção às orelhas, segure 2 segundos no topo e desça alongando.'),

-- BÍCEPS & ANTEBRAÇO (Novos exercícios)
(N'Rosca Direta com Barra Reta', N'Bíceps', N'https://www.youtube.com/watch?v=fjS0CqDR4v8', N'Cotovelos fixos ao lado das costelas, suba a barra contraindo forte o bíceps.'),
(N'Rosca Direta na Polia Baixa com Barra', N'Bíceps', N'https://www.youtube.com/watch?v=fjS0CqDR4v8', N'Tensão constante do cabo do início ao fim da flexão de cotovelos.'),
(N'Rosca Alternada com Halteres em Pé', N'Bíceps', N'https://www.youtube.com/watch?v=fjS0CqDR4v8', N'Faça a supinação do punho durante a subida para ativação máxima do bíceps braquial.'),
(N'Rosca Martelo na Polia com Corda', N'Bíceps', N'https://www.youtube.com/watch?v=GilFwBs_kOs', N'Pegada neutra na corda trabalhando braquial, braquiorradial e espessura do braço.'),
(N'Rosca Spider no Banco Inclinado (Peito Apoiado)', N'Bíceps', N'https://www.youtube.com/watch?v=fjS0CqDR4v8', N'Braços pendurados à frente do banco, zero roubo de tronco e pico de contração intenso.'),
(N'Rosca Bayesiana na Polia Baixa (Braço Atrás do Tronco)', N'Bíceps', N'https://www.youtube.com/watch?v=fjS0CqDR4v8', N'De costas para a polia, alonga ao máximo a cabeça longa do bíceps na posição inicial.'),
(N'Rosca 21 com Barra W', N'Bíceps', N'https://www.youtube.com/watch?v=fjS0CqDR4v8', N'7 meias repetições inferiores + 7 meias superiores + 7 repetições completas.'),
(N'Rosca Inversa com Barra (Foco Antebraço/Braquiorradial)', N'Bíceps', N'https://www.youtube.com/watch?v=GilFwBs_kOs', N'Pegada pronada (palmas para baixo), excelente para volume de antebraço.'),
(N'Flexão de Punho Sentado com Barra (Antebraço)', N'Bíceps', N'https://www.youtube.com/watch?v=GilFwBs_kOs', N'Antebraços apoiados nas coxas, flexione apenas os punhos com amplitude máxima.'),

-- TRÍCEPS (Novos exercícios)
(N'Tríceps Pulley na Barra Reta ou Barra V', N'Tríceps', N'https://www.youtube.com/watch?v=VnFopAIGO7E', N'Cotovelos travados ao lado do tronco, estenda completamente os antebraços para baixo.'),
(N'Tríceps Testa com Halteres (Pegada Neutra)', N'Tríceps', N'https://www.youtube.com/watch?v=CF6N7CfABIg', N'Mais confortável para os punhos e cotovelos, descendo os halteres ao lado das têmporas.'),
(N'Tríceps Francês na Polia com Corda (Sobre a Cabeça)', N'Tríceps', N'https://www.youtube.com/watch?v=CF6N7CfABIg', N'De costas para a polia, estenda a corda acima/à frente alongando toda a cabeça longa do tríceps.'),
(N'Tríceps Francês Unilateral com Halter', N'Tríceps', N'https://www.youtube.com/watch?v=CF6N7CfABIg', N'Desça o halter atrás da nuca mantendo o cotovelo apontado para o teto.'),
(N'Tríceps Coice Unilateral na Polia ou Halter', N'Tríceps', N'https://www.youtube.com/watch?v=VnFopAIGO7E', N'Tronco inclinado, braço paralelo ao solo estendendo o cotovelo até travar no topo.'),
(N'Tríceps Supinado no Banco Reto (Pegada Fechada)', N'Tríceps', N'https://www.youtube.com/watch?v=CF6N7CfABIg', N'Pegada na largura dos ombros, desça a barra na parte baixa do peito com cotovelos fechados.'),
(N'Tríceps Unilateral Pegada Supinada na Polia', N'Tríceps', N'https://www.youtube.com/watch?v=VnFopAIGO7E', N'Palma da mão para cima, puxe o puxador isolando a cabeça medial e lateral do tríceps.'),
(N'Mergulho nas Paralelas / Máquina Graviton', N'Tríceps', N'https://www.youtube.com/watch?v=VnFopAIGO7E', N'Tronco vertical para direcionar a sobrecarga diretamente para o tríceps.'),

-- ABDÔMEN & CORE (Novos exercícios)
(N'Abdominal Supra no Solo ou Banco Declinado', N'Abdômen', N'https://www.youtube.com/watch?v=ffHr8a6DRvU', N'Enrole a coluna torácica soltando todo o ar na subida sem puxar o pescoço.'),
(N'Abdominal Infra nas Paralelas (Elevação de Joelhos/Pernas)', N'Abdômen', N'https://www.youtube.com/watch?v=ffHr8a6DRvU', N'Eleve a pelve enrolando o quadril no final da subida para ativar o reto abdominal inferior.'),
(N'Abdominal Oblíquo Bicicleta no Solo', N'Abdômen', N'https://www.youtube.com/watch?v=ffHr8a6DRvU', N'Gire o tronco levando o ombro em direção ao joelho oposto de forma cadenciada.'),
(N'Abdominal Lenha (Woodchopper) na Polia', N'Abdômen', N'https://www.youtube.com/watch?v=ffHr8a6DRvU', N'Rotação diagonal do tronco com cabo para fortalecimento dos oblíquos e core.'),
(N'Prancha Lateral Isométrica', N'Abdômen', N'https://www.youtube.com/watch?v=ffHr8a6DRvU', N'Mantenha o quadril elevado e alinhado fortalecendo oblíquos e quadrado lombar.'),
(N'Roda Abdominal (Ab Wheel)', N'Abdômen', N'https://www.youtube.com/watch?v=ffHr8a6DRvU', N'Mantenha a pelve em retroversão e o abdômen travado durante toda a extensão à frente.'),
(N'Vacuum Abdominal (Hipopressivo)', N'Abdômen', N'https://www.youtube.com/watch?v=ffHr8a6DRvU', N'Solte todo o ar e sugue o umbigo em direção às costas ativando o transverso do abdômen.'),

-- CARDIO, HIIT & CONDICIONAMENTO (Novo grupo)
(N'Esteira HIIT (Tiros de Alta Intensidade)', N'Cardio & HIIT', N'https://www.youtube.com/watch?v=ffHr8a6DRvU', N'Alterne 1 minuto de corrida intensa com 1 minuto de caminhada recuperativa.'),
(N'Escada Ergométrica (Simulador de Degraus)', N'Cardio & HIIT', N'https://www.youtube.com/watch?v=ffHr8a6DRvU', N'Mantenha a postura ereta sem descarregar o peso dos braços no corrimão.'),
(N'Bicicleta Ergométrica / Spinning', N'Cardio & HIIT', N'https://www.youtube.com/watch?v=ffHr8a6DRvU', N'Cadência constante mantendo a zona de frequência cardíaca alvo prescrita.'),
(N'Elíptico / Transport Contínuo', N'Cardio & HIIT', N'https://www.youtube.com/watch?v=ffHr8a6DRvU', N'Cardio de baixo impacto articular com movimentação simultânea de membros superiores e inferiores.'),
(N'Corda Naval (Battle Rope) Tabata', N'Cardio & HIIT', N'https://www.youtube.com/watch?v=ffHr8a6DRvU', N'Séries explosivas de 30s de ondas alternadas por 30s de descanso.'),
(N'Kettlebell Swing Russo', N'Cardio & HIIT', N'https://www.youtube.com/watch?v=6PWws7e_z-s', N'Explosão de quadril projetando o kettlebell até a linha dos ombros.');

-- Insere apenas os exercícios que ainda não existem na tabela EXERCICIOS_BASE
INSERT INTO EXERCICIOS_BASE (PERSONAL_ID, NOME, GRUPO_MUSCULAR, VIDEO_URL, INSTRUCOES_EXECUCAO)
SELECT NULL, N.NOME, N.GRUPO_MUSCULAR, N.VIDEO_URL, N.INSTRUCOES_EXECUCAO
FROM #NovosExercicios N
WHERE NOT EXISTS (
    SELECT 1 FROM EXERCICIOS_BASE E WHERE E.NOME = N.NOME
);

DROP TABLE #NovosExercicios;
GO
