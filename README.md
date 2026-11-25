# Curadoria e Restauração de Filmes Analógicos

Trabalho Final da disciplina **Fundamentos de Banco de Dados (CK0443)** — Universidade Federal do Ceará (UFC).

O projeto modela e implementa em PostgreSQL o banco de dados de uma cinemateca dedicada à preservação e restauração de películas cinematográficas, abrangendo o controle de acervo, armazenamento climatizado, equipamentos de laboratório, restauradores e histórico de intervenções técnicas.

---

## Modelo de Dados

O esquema conta com **8 tabelas** (7 entidades e 1 tabela associativa):

- **`Filme`**: catálogo de obras do acervo, com autorrelacionamento (`id_filme_sequencia`) para filmes que são sequência de outro.
- **`SalaClimatizada`**: ambientes de guarda com faixas controladas de temperatura (15 °C a 25 °C), umidade relativa (30% a 60%) e capacidade máxima de latas.
- **`CopiaFisica`**: entidade fraca dependente de `Filme`, identificada pela chave parcial `(id_filme, numero_rolo)`, registrando suporte (`Acetato` ou `Poliéster`), estado de conservação e metragem.
- **`LataArmazenamento`**: entidade fraca dependente de `CopiaFisica`, identificada pela chave parcial `(id_copia, codigo_etiqueta)`.
- **`Restaurador`**: especialistas do laboratório e seus registros profissionais.
- **`EquipamentoLaboratorio`**: maquinário técnico e status operacional (`Operacional` ou `Manutenção`).
- **`RestauradorEquipamento`**: relacionamento N:N com atributo (`uso_diario_horas`) indicando a carga horária diária de operação por restaurador.
- **`IntervencaoRestauracao`**: registro ternário ligando cópia física, restaurador e equipamento em um intervalo de datas.

### Integridade e Regras de Negócio

- **Restrições declarativas (`CHECK` e `UNIQUE`)**: validação de ano de produção (`>= 1890`), temperatura, umidade, metragem positiva, estados de conservação, status operacional, datas consistentes (`data_fim >= data_inicio`) e unicidade para chaves parciais, números de tombo, série e registros profissionais.
- **Trigger (`trg_intervencao_duracao`)**: aciona a função `fn_verifica_duracao_intervencao()` antes de `INSERT` ou `UPDATE` em `IntervencaoRestauracao` para bloquear qualquer intervenção que ultrapasse 30 dias (`data_fim - data_inicio > 30`).

---

## Como Executar

1. **Pré-requisitos**
   - PostgreSQL 12 ou superior.
   - Cliente `psql` ou interface gráfica (como pgAdmin ou DBeaver).

2. **Criar um banco vazio e executar o script**
   O arquivo `.sql` foi estruturado para rodar do início ao fim em um banco vazio, criando todas as tabelas, funções, triggers, massa de dados (8 a 12 registros por tabela), visão (`vw_copia_status`) e executando as consultas.

   ```bash
   createdb -U <usuario> curadoria_filmes
   psql -U <usuario> -d curadoria_filmes -f curadoria_filmes.sql