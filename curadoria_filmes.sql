-- ====================================================
-- Projeto de Banco de Dados: Curadoria e Restauração de Filmes Analógicos
-- Tema: Arquivologia Cinematográfica
-- ====================================================

-- ====================================================
-- 1️⃣ Criação das tabelas
-- ====================================================

-- Tabela Filme (entidade principal)
CREATE TABLE Filme (
    id_filme               SERIAL PRIMARY KEY,
    titulo_original        VARCHAR(200) NOT NULL,
    titulo_distribuicao    VARCHAR(200) NOT NULL,
    ano_producao           INT NOT NULL CHECK (ano_producao >= 1890), -- [NOVO CHECK]
    pais_origem            VARCHAR(100) NOT NULL,
    duracao_minutos        INT NOT NULL CHECK (duracao_minutos > 0),
    formato_original       VARCHAR(50) NOT NULL,
    sinopse                TEXT,
    id_filme_sequencia     INT,
    CONSTRAINT fk_filme_sequencia FOREIGN KEY (id_filme_sequencia) REFERENCES Filme(id_filme)
);

CREATE TABLE SalaClimatizada (
    id_sala                   SERIAL PRIMARY KEY,
    codigo_sala               VARCHAR(20) NOT NULL UNIQUE, -- [NOVO UNIQUE]
    temperatura_alvo_celsius  NUMERIC(4,1) NOT NULL CHECK (temperatura_alvo_celsius BETWEEN 15 AND 25),
    umidade_relativa_alvo     NUMERIC(4,1) NOT NULL CHECK (umidade_relativa_alvo BETWEEN 30 AND 60), -- [NOVO CHECK]
    capacidade_maxima_latas   INT NOT NULL CHECK (capacidade_maxima_latas > 0) -- [NOVO CHECK]
);

-- Tabela CopiaFisica (entidade fraca, depende de Filme)
CREATE TABLE CopiaFisica (
    id_copia                SERIAL PRIMARY KEY,
    id_filme                INT NOT NULL,
    id_sala_atual           INT NOT NULL,
    numero_registro_tombo   VARCHAR(30) NOT NULL UNIQUE, -- [NOVO UNIQUE]
    numero_rolo             VARCHAR(30) NOT NULL,
    tipo_suporte            VARCHAR(30) NOT NULL,
    estado_conservacao      VARCHAR(30) NOT NULL CHECK (estado_conservacao IN ('Bom','Regular','Ruim')), -- [NOVO CHECK]
    metragem_atual          NUMERIC(6,2) NOT NULL CHECK (metragem_atual > 0), -- [NOVO CHECK]
    data_aquisicao          DATE NOT NULL,
    CONSTRAINT uq_copia_rolo UNIQUE (id_filme, numero_rolo),   -- [NOVA CHAVE PARCIAL]
    CONSTRAINT fk_copia_filme FOREIGN KEY (id_filme) REFERENCES Filme(id_filme),
    CONSTRAINT fk_copia_sala  FOREIGN KEY (id_sala_atual) REFERENCES SalaClimatizada(id_sala)
);

CREATE TABLE LataArmazenamento (
    id_lata                 SERIAL PRIMARY KEY,
    id_copia                INT NOT NULL,
    codigo_etiqueta         VARCHAR(30) NOT NULL,
    material_lata           VARCHAR(30) NOT NULL,
    possui_respiro          BOOLEAN NOT NULL,
    CONSTRAINT uq_lata_etiqueta UNIQUE (id_copia, codigo_etiqueta),  -- [NOVA CHAVE PARCIAL]
    CONSTRAINT fk_lata_copia FOREIGN KEY (id_copia) REFERENCES CopiaFisica(id_copia)
);

-- Tabela Restaurador
CREATE TABLE Restaurador (
    id_restaurador          SERIAL PRIMARY KEY,
    nome_completo           VARCHAR(150) NOT NULL,
    especialidade           VARCHAR(100) NOT NULL,
    registro_profissional   VARCHAR(50) NOT NULL UNIQUE, -- [NOVO UNIQUE]
    email_contato           VARCHAR(150) NOT NULL
);

CREATE TABLE EquipamentoLaboratorio (
    id_equipamento          SERIAL PRIMARY KEY,
    nome_equipamento        VARCHAR(150) NOT NULL,
    numero_serie            VARCHAR(100) NOT NULL UNIQUE, -- [NOVO UNIQUE]
    status_operacional      VARCHAR(30) NOT NULL CHECK (status_operacional IN ('Operacional','Manutenção')), -- [NOVO CHECK]
    ultima_afericao         DATE NOT NULL
);

CREATE TABLE IntervencaoRestauracao (
    id_intervencao          SERIAL PRIMARY KEY,
    id_copia                INT NOT NULL,
    id_restaurador          INT NOT NULL,
    id_equipamento          INT NOT NULL,
    data_inicio             DATE NOT NULL,
    data_fim                DATE,
    tipo_procedimento       VARCHAR(100) NOT NULL,
    produtos_utilizados     TEXT,
    observacoes_tecnicas    TEXT,
    CONSTRAINT ck_interv_datas CHECK (data_fim IS NULL OR data_fim >= data_inicio), -- [NOVO CHECK]
    CONSTRAINT fk_interv_copia FOREIGN KEY (id_copia) REFERENCES CopiaFisica(id_copia),
    CONSTRAINT fk_interv_restaurador FOREIGN KEY (id_restaurador) REFERENCES Restaurador(id_restaurador),
    CONSTRAINT fk_interv_equipamento FOREIGN KEY (id_equipamento) REFERENCES EquipamentoLaboratorio(id_equipamento)
);

CREATE TABLE RestauradorEquipamento (
    id_restaurador          INT NOT NULL,
    id_equipamento          INT NOT NULL,
    uso_diario_horas        NUMERIC(4,2) NOT NULL CHECK (uso_diario_horas > 0 AND uso_diario_horas <= 24), -- [NOVO CHECK]
    PRIMARY KEY (id_restaurador, id_equipamento),
    CONSTRAINT fk_re_restaurador FOREIGN KEY (id_restaurador) REFERENCES Restaurador(id_restaurador),
    CONSTRAINT fk_re_equipamento FOREIGN KEY (id_equipamento) REFERENCES EquipamentoLaboratorio(id_equipamento)
);

-- ====================================================
-- 2️⃣ Triggers e funções auxiliares
-- ====================================================

-- Função que verifica a duração da intervenção (não pode exceder 30 dias)
CREATE OR REPLACE FUNCTION fn_verifica_duracao_intervencao()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.data_fim IS NOT NULL THEN
        IF (NEW.data_fim - NEW.data_inicio) > 30 THEN
            RAISE EXCEPTION 'Intervenção excede 30 dias – operação bloqueada';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger associado à tabela IntervencaoRestauracao
CREATE TRIGGER trg_intervencao_duracao
BEFORE INSERT OR UPDATE ON IntervencaoRestauracao
FOR EACH ROW EXECUTE FUNCTION fn_verifica_duracao_intervencao();

-- ====================================================
-- 3️⃣ Inserções de dados (≥ 8 linhas por tabela)
-- ====================================================

-- Filmes
-- Filmes (o filme 4 é sequência do filme 3; o filme 9 ainda não tem cópia física)
INSERT INTO Filme (titulo_original, titulo_distribuicao, ano_producao, pais_origem, duracao_minutos, formato_original, sinopse, id_filme_sequencia) VALUES
('O Estranho Mundo de Mr. W', 'Mr. W Original', 1975, 'Brasil', 90, '35mm', 'Documentário sobre um colecionador cearense que passou a vida registrando em película o cotidiano de uma vila de pescadores.', NULL),
('A Luz da Aurora', 'Aurora Studios', 1982, 'Portugal', 110, '35mm', 'Drama histórico sobre uma família de faroleiros no litoral português durante a Revolução dos Cravos.', NULL),
('CineLab 1', 'CineLab', 1990, 'EUA', 95, '35mm', 'Ficção científica em que estudantes de cinema descobrem um laboratório secreto de revelação de filmes.', NULL),
('CineLab 2', 'CineLab', 1992, 'EUA', 105, '35mm', 'Continuação de CineLab 1: os estudantes tentam salvar o laboratório da demolição.', 3),
('Rolos Perdidos', 'ArchFilm', 2001, 'Itália', 120, '16mm', 'Uma arquivista italiana busca rolos de um filme mudo desaparecido após a Segunda Guerra.', NULL),
('Sombras da Tela', 'ScreenArts', 2005, 'França', 100, '35mm', 'Suspense ambientado em um cinema de Paris onde projeções antigas revelam um crime.', NULL),
('Eco da Película', 'RetroVision', 2010, 'Argentina', 85, '35mm', 'Retrato nostálgico de um projecionista de Buenos Aires em seus últimos dias de trabalho.', NULL),
('Vozes do Passado', 'Heritage Films', 2015, 'Chile', 92, '35mm', 'Entrevistas com cineastas chilenos veteranos sobre a produção durante os anos 1960.', NULL),
('Fragmentos de Fortaleza', 'Cinemateca Norte', 2018, 'Brasil', 78, '35mm', 'Mosaico de registros urbanos de Fortaleza; a cópia física ainda será incorporada ao acervo.', NULL);

-- Salas climatizadas
INSERT INTO SalaClimatizada (codigo_sala, temperatura_alvo_celsius, umidade_relativa_alvo, capacidade_maxima_latas) VALUES
('SC-01', 20.0, 45.0, 50),
('SC-02', 21.5, 50.0, 40),
('SC-03', 19.0, 48.0, 60),
('SC-04', 20.5, 46.0, 45),
('SC-05', 22.0, 44.0, 55),
('SC-06', 20.0, 47.0, 35),
('SC-07', 19.5, 49.0, 30),
('SC-08', 21.0, 45.5, 40);

-- Cópias físicas
INSERT INTO CopiaFisica (id_filme, id_sala_atual, numero_registro_tombo, numero_rolo, tipo_suporte, estado_conservacao, metragem_atual, data_aquisicao) VALUES
(1,1,'T-001','R-001','35mm','Bom',300.00,'2000-05-10'),
(2,2,'T-002','R-002','35mm','Regular',250.50,'2002-07-15'),
(3,3,'T-003','R-003','35mm','Ruim',180.75,'2005-11-20'),
(4,4,'T-004','R-004','35mm','Bom',290.20,'2007-02-12'),
(5,5,'T-005','R-005','16mm','Regular',210.00,'2010-09-05'),
(6,6,'T-006','R-006','35mm','Bom',320.10,'2012-04-18'),
(7,7,'T-007','R-007','35mm','Bom',275.30,'2014-01-23'),
(8,8,'T-008','R-008','35mm','Regular',260.00,'2016-06-30');

-- Latas de armazenamento (entidade fraca)
INSERT INTO LataArmazenamento (id_copia, codigo_etiqueta, material_lata, possui_respiro) VALUES
(1,'L-001','Alumínio',TRUE),
(2,'L-002','Aço',FALSE),
(3,'L-003','Alumínio',TRUE),
(4,'L-004','Aço',TRUE),
(5,'L-005','Alumínio',FALSE),
(6,'L-006','Aço',TRUE),
(7,'L-007','Alumínio',TRUE),
(8,'L-008','Aço',FALSE);
(1,'L-009','Alumínio',TRUE),
(1,'L-010','Alumínio',TRUE),
(3,'L-011','Alumínio',TRUE),
(9,'L-012','Aço',TRUE);

-- Restauradores
INSERT INTO Restaurador (nome_completo, especialidade, registro_profissional, email_contato) VALUES
('Ana Silva','Limpeza de emulsão','RP-1001','ana.silva@restauracao.org'),
('Bruno Costa','Reparo físico','RP-1002','bruno.costa@restauracao.org'),
('Clara Mendes','Digitalização','RP-1003','clara.mendes@restauracao.org'),
('David Nogueira','Correção de cor','RP-1004','david.nogueira@restauracao.org'),
('Elisa Ramos','Montagem de trilha sonora','RP-1005','elisa.ramos@restauracao.org'),
('Fábio Duarte','Conservação química','RP-1006','fabio.duarte@restauracao.org'),
('Gisele Pires','Inspeção e reembalagem','RP-1007','gisele.pires@restauracao.org'),
('Hugo Lopes','Reparo de danos físicos','RP-1008','hugo.lopes@restauracao.org');
-- Equipamentos de laboratório
INSERT INTO EquipamentoLaboratorio (nome_equipamento, numero_serie, status_operacional, ultima_afericao) VALUES
('Mesa Enroladeira','EQ-001','Operacional','2025-12-01'),
('Scanner 35mm 4K','EQ-002','Operacional','2025-10-15'),
('Câmara de Secagem','EQ-003','Operacional','2025-08-20'),
('Balança de Precisão','EQ-004','Operacional','2025-09-05'),
('Máquina de Limpeza Ultrassônica','EQ-005','Operacional','2025-11-20'),
('Prensa de Emendas','EQ-006','Operacional','2025-07-30'),
('Estação de Digitalização','EQ-007','Manutenção','2025-01-12'),
('Mesa de Montagem','EQ-008','Operacional','2025-06-18');

-- Relacionamento N:N Restauro ↔ Equipamento (uso_diario)
INSERT INTO RestauradorEquipamento (id_restaurador, id_equipamento, uso_diario_horas) VALUES
(1,5,4.5),(2,6,3.0),(3,2,5.0),(4,2,2.5),(5,8,3.5),(6,4,4.0),(7,1,2.0),(8,6,3.0),(1,1,1.5),(2,3,1.0);

-- Intervenções de restauração (≥ 8 linhas)
INSERT INTO IntervencaoRestauracao (id_copia, id_restaurador, id_equipamento, data_inicio, data_fim, tipo_procedimento, produtos_utilizados, observacoes_tecnicas) VALUES
(1,1,5,'2026-01-10','2026-01-15','Limpeza de emulsão','Álcool isopropílico, tecido sem fiapos','Procedimento padrão, sem perda de imagem'),
(2,2,6,'2026-02-05','2026-02-08','Reparo físico','Fita de emenda de poliéster','Pequenos rasgos corrigidos'),
(3,3,2,'2026-03-12','2026-03-20','Digitalização','Cartela de calibração, software de captura','Digitalização em 4K de cópia em estado ruim'),
(4,4,2,'2026-04-01','2026-04-04','Correção de cor','Cartela de calibração IT8','Cores equilibradas após digitalização'),
(5,5,8,'2026-05-15','2026-05-18','Montagem de trilha sonora','Fita magnética 16mm','Sincronização de áudio concluída'),
(6,6,4,'2026-06-10','2026-06-14','Conservação química','Solução estabilizadora','Dosagem pesada e reação controlada'),
(7,7,1,'2026-07-03','2026-07-06','Inspeção e reembalagem','Núcleos de rolo, luvas de algodão','Rolo reembalado e etiquetado'),
(8,8,6,'2026-08-20','2026-08-23','Reparo físico','Fita de emenda de acetato','Rasgo maior restaurado');

-- ====================================================
-- 4️⃣ 12 itens de consulta (com comentários)
-- ====================================================

-- Item 1 (Filtro por intervalo de datas)
-- Pergunta: Quais intervenções tiveram início entre 2026-03-01 e 2026-06-30?
SELECT id_intervencao, data_inicio, data_fim
FROM IntervencaoRestauracao
WHERE data_inicio BETWEEN '2026-03-01' AND '2026-06-30'
ORDER BY id_intervencao;
-- Resultado esperado: 3,4,5,6

-- Item 2 (Filtro de texto com LIKE)
-- Pergunta: Quais filmes têm "CineLab" no título de distribuição?
SELECT id_filme, titulo_original, titulo_distribuicao
FROM Filme
WHERE titulo_distribuicao LIKE '%CineLab%'
ORDER BY id_filme;
-- Resultado esperado: 3,4

-- Item 3 (UNION e INTERSECT)
-- Pergunta: Liste os IDs de filmes que têm cópias armazenadas em salas com capacidade > 45 (UNION) e aqueles que são sequências de outro filme (INTERSECT).
-- 3a - UNION:
SELECT c.id_filme
FROM CopiaFisica c
JOIN SalaClimatizada s ON c.id_sala_atual = s.id_sala
WHERE s.capacidade_maxima_latas > 45
UNION
SELECT id_filme FROM Filme WHERE id_filme_sequencia IS NOT NULL
ORDER BY id_filme;

--3b - INTERSECT:
SELECT c.id_filme
FROM CopiaFisica c
JOIN SalaClimatizada s ON c.id_sala_atual = s.id_sala
WHERE s.capacidade_maxima_latas > 45
INTERSECT
SELECT id_filme FROM CopiaFisica WHERE estado_conservacao IN ('Regular','Ruim')
ORDER BY id_filme;
-- Resultado esperado: (dependendo dos dados, provável retorno 4)

-- Item 4 (Função agregada)
-- Pergunta: Qual a média de duração (em minutos) dos filmes?
SELECT ROUND(AVG(duracao_minutos), 2) AS media_duracao FROM Filme;
-- Item 5 (GROUP BY)
-- Pergunta: Quantas cópias físicas existem por filme?
SELECT f.id_filme, f.titulo_original, COUNT(c.id_copia) AS total_copias
FROM Filme f LEFT JOIN CopiaFisica c ON f.id_filme = c.id_filme
GROUP BY f.id_filme, f.titulo_original;
-- Resultado esperado: 1 para cada filme (8 linhas)

-- Item 6 (HAVING)
-- Pergunta: Quais salas armazenam mais de 1 lata?
SELECT s.id_sala, s.codigo_sala, COUNT(l.id_lata) AS total_latas
FROM SalaClimatizada s JOIN CopiaFisica c ON s.id_sala = c.id_sala_atual
JOIN LataArmazenamento l ON c.id_copia = l.id_copia
GROUP BY s.id_sala, s.codigo_sala
HAVING COUNT(l.id_lata) > 1
ORDER BY s.id_sala;
-- Resultado esperado: (possível) SC-01, SC-03, etc.

-- Item 7 (Subconsulta IN)
-- Pergunta: Quais cópias nunca tiveram intervenção de restauração?
SELECT id_copia, numero_registro_tombo
FROM CopiaFisica
WHERE id_copia NOT IN (SELECT id_copia FROM IntervencaoRestauracao)
ORDER BY id_copia;
-- Resultado esperado: (nenhuma, pois todas têm intervenções)

-- Item 8 (Subconsulta correlacionada EXISTS)
-- Pergunta: Quais cópias têm tempo de restauração (diferença entre data_fim e data_inicio) maior que a média de todas as intervenções?
SELECT c.id_copia, c.numero_registro_tombo
FROM CopiaFisica c
WHERE EXISTS (
    SELECT 1
    FROM IntervencaoRestauracao i
    WHERE i.id_copia = c.id_copia
      AND (i.data_fim - i.data_inicio) > (
          SELECT AVG(i2.data_fim - i2.data_inicio)
          FROM IntervencaoRestauracao i2
          WHERE i2.data_fim IS NOT NULL)
)
ORDER BY c.id_copia;
-- Resultado esperado: (dependendo dos dados, pode retornar algumas cópias)

-- Item 9 (INNER JOIN com três tabelas)
-- Pergunta: Para cada intervenção, mostre o filme, o restaurador e o equipamento usado.
SELECT f.titulo_original, r.nome_completo, e.nome_equipamento, i.data_inicio
FROM IntervencaoRestauracao i
JOIN CopiaFisica c ON i.id_copia = c.id_copia
JOIN Filme f ON c.id_filme = f.id_filme
JOIN Restaurador r ON i.id_restaurador = r.id_restaurador
JOIN EquipamentoLaboratorio e ON i.id_equipamento = e.id_equipamento
ORDER BY i.data_inicio;
-- Resultado esperado: 8 linhas com informações completas

-- Item 10 (LEFT JOIN mostrando quem "não tem")
-- Pergunta: Quais filmes ainda não têm cópias associadas?
SELECT f.id_filme, f.titulo_original
FROM Filme f LEFT JOIN CopiaFisica c ON f.id_filme = c.id_filme
WHERE c.id_copia IS NULL;
-- Resultado esperado: (nenhum, pois todos têm ao menos uma cópia)

-- Item 11 (VIEW + consulta)
-- Criação da view que mostra cópias com seu estado de conservação e a sala onde estão armazenadas
CREATE VIEW vw_copia_status AS
SELECT c.id_copia, f.titulo_original, c.estado_conservacao, s.codigo_sala, s.temperatura_alvo_celsius
FROM CopiaFisica c
JOIN Filme f ON c.id_filme = f.id_filme
JOIN SalaClimatizada s ON c.id_sala_atual = s.id_sala;

SELECT * FROM vw_copia_status
WHERE temperatura_alvo_celsius > 20
ORDER BY id_copia;

-- Consulta usando a view: listar cópias em salas com temperatura acima de 20°C
SELECT * FROM vw_copia_status WHERE temperatura_alvo_celsius > 20;
-- Resultado esperado: linhas correspondentes às salas SC-02, SC-04, SC-05, SC-08

-- Item 12 (Trigger já criada acima)
-- Pergunta: O trigger impede a inserção de uma intervenção que dure mais de 30 dias.
-- Teste (comentado para não gerar erro ao executar o script):
-- INSERT INTO IntervencaoRestauracao (id_copia, id_restaurador, id_equipamento, data_inicio, data_fim, tipo_procedimento)
-- VALUES (1,1,2,'2026-09-01','2026-10-15','Teste longo');
-- Resultado esperado: erro "Intervenção excede 30 dias – operação bloqueada"

-- ====================================================
-- FIM DO SCRIPT
-- ====================================================
