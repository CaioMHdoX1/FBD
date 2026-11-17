# Curadoria e Restauração de Filmes Analógicos

Este repositório contém o **projeto de banco de dados** desenvolvido para o mini‑mundo de **arquivologia cinematográfica**. O objetivo é modelar, armazenar e consultar informações sobre filmes, suas cópias físicas, salas climatizadas, equipamentos de laboratório, restauradores e intervenções de restauração.

---

## 📚 Descrição

- **Tema**: Arquivologia Cinematográfica – um arquivo que gerencia a restauração de filmes analógicos.
- **Entidades principais**: `Filme`, `SalaClimatizada`, `CopiaFisica`, `LataArmazenamento`, `Restaurador`, `EquipamentoLaboratorio`, `IntervencaoRestauracao`.
- **Requisitos atendidos**:
  - ≥ 6 entidades.
  - Relacionamento N × N com atributo (`Restaurador ↔ Equipamento` – uso diário).
  - Entidade fraca (`LataArmazenamento`).
  - Autorrelacionamento (`Filme` sequencia `Filme`).
  - Uma regra `CHECK` e um **trigger** que impede intervenções com duração > 30 dias.
  - Script `INSERT` com no mínimo 8 linhas por tabela.
  - **12 consultas** (filtros, joins, agregações, view, etc.) com comentários de pergunta e resultado esperado.

---

## 🚀 Como Executar

1. **Pré‑requisitos**
   - PostgreSQL (versão 12 ou superior).
   - Cliente `psql` disponível no seu PATH.

2. **Clonar / copiar o repositório**
   ```bash
   git clone <url-do-repositorio>   # ou simplesmente copie a pasta
   cd <pasta-do-repositorio>
   ```

3. **Executar o script SQL**
   ```bash
   psql -U <usuario> -d <banco> -f curadoria_filmes.sql
   ```
   O script criará todas as tabelas, inserirá os dados de exemplo e deixará pronto o ambiente para as consultas.

4. **Testar as consultas**
   - Abra o `psql` conectado ao banco que acabou de ser criado.
   - Copie‑e‑cole qualquer um dos itens 1‑12 que estão no final do script ou rode-os separadamente.

---

## 📂 Estrutura do Repositório

```
├─ curadoria_filmes.sql   # Script completo (DDL, DML, trigger, views e 12 consultas)
├─ README.md              # Este documento
└─ (eventuais recursos adicionais, imagens, etc.)
```

---

## 🛠️ Customizações

- **Novas colunas**: basta editar a seção `CREATE TABLE` e os `INSERT`s correspondentes.
- **Novas consultas**: adicione-as após a seção *12 itens de consulta* ou crie um novo arquivo `.sql` de teste.
- **Trigger**: a lógica pode ser alterada na função `fn_verifica_duracao_intervencao()`.

---

## 📜 Licença

Este projeto foi criado para fins acadêmicos e pode ser usado livremente. Sinta‑se à vontade para adaptar e distribuir conforme necessário.

---

### 🎉 Obrigado por conferir!

Qualquer dúvida ou sugestão, é só abrir uma *issue* no repositório ou entrar em contato.
