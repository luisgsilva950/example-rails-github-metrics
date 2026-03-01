# README

This README would normally document whatever steps are necessary to get the
application up and running.

## Endpoint de Métricas de Autores

Foi adicionado o endpoint `GET /metrics/authors` que retorna um ranking de autores (baseado em `normalized_author_name`) ordenado pelo total de commits, incluindo breakdown por repositório.

Exemplo de resposta:

```json
[
	{
		"author": "alice",
		"total_commits": 42,
		"repos": [
			{ "name": "org/repo1", "commits": 10 },
			{ "name": "org/repo2", "commits": 32 }
		]
	},
	{
		"author": "bob",
		"total_commits": 17,
		"repos": [
			{ "name": "org/repo1", "commits": 5 },
			{ "name": "org/repo3", "commits": 12 }
		]
	}
]
```

### Uso

```bash
curl http://localhost:3000/metrics/authors | jq
```

### Notas de Implementação
* A agregação usa `JOIN` entre `commits` e `repositories` + `GROUP BY` para reduzir carga na aplicação.
* O índice único em `commits.sha` permite uso futuro de inserção em lote com `upsert_all` sem duplicações.
* Variáveis de ambiente para retries/timeouts da API GitHub:
	- `GITHUB_API_RETRY_MAX`, `GITHUB_API_RETRY_INTERVAL`, `GITHUB_API_RETRY_BACKOFF`
	- `GITHUB_OPEN_TIMEOUT`, `GITHUB_READ_TIMEOUT`
	- `COMMITS_BATCH_SIZE` para futuro processamento em lote.

## Extração de Bugs do Jira

Foi adicionada a integração básica para importar bugs via JQL.

### Campos armazenados
- issue_key
- title
- opened_at
- components (array)
- categories (array)
- root_cause_analysis (texto)

### Variáveis de ambiente necessárias
Defina no seu `.env` ou ambiente de execução:
```
JIRA_SITE=https://sua-instancia.atlassian.net
JIRA_USERNAME=seu.email@dominio.com
JIRA_API_TOKEN=token_gerado_no_atlassian
JIRA_BUGS_JQL=project = ABC AND issuetype = Bug ORDER BY created DESC
JIRA_MAX_RESULTS=500 # opcional
```
Gere um token em https://id.atlassian.com/manage-profile/security/api-tokens.

### Variáveis avançadas (opcionais)
- `JIRA_FIELDS` (default `*all`): lista de campos ex: `summary,components,labels,customfield_12345`
- `JIRA_EXPAND`: ex: `changelog,renderedFields`
- `JIRA_FETCH_FULL` (default `true`): se `false`, não refaz fetch individual por issue

### Execução
Suba o Postgres (ex: `docker compose up -d db`) e rode as migrations:
```
bin/rails db:migrate
```
Execute a tarefa de extração:
```
JIRA_BUGS_JQL="project = ABC AND issuetype = Bug ORDER BY created DESC" bin/rake jira:extract_bugs
```

### Customização de campos
Se a sua instância usa campos customizados para Categorias ou RCA, ajuste os métodos `extract_categories` e `extract_rca` em `app/services/jira_bugs_extractor.rb`.

### Troubleshooting SSL para Jira

Se você receber erro como:
```
SSL_connect returned=1 errno=0 state=error: certificate verify failed (unable to get certificate CRL)
```
Passos:
1. Atualize certificados locais (macOS Homebrew):
   ```bash
   brew update
   brew reinstall ca-certificates
   sudo security delete-certificate -Z <SHA1_antigo> /Library/Keychains/System.keychain || true
   ```
2. Baixe a cadeia de certificados corporativos e salve em um arquivo PEM, ex: `corp-ca.pem`, e defina:
   ```bash
   export JIRA_SSL_CERT_FILE="$PWD/corp-ca.pem"
   ```
3. Se possuir vários certificados, coloque-os em um diretório e defina:
   ```bash
   export JIRA_SSL_CERT_PATH="$PWD/certs"
   ```
4. Teste conexão simples (opcional):
   ```ruby
   require 'net/https'; require 'uri'
   uri = URI(ENV['JIRA_SITE']); http = Net::HTTP.new(uri.host, 443)
   http.use_ssl = true; http.verify_mode = OpenSSL::SSL::VERIFY_PEER
   http.start { puts http.head('/').code }
   ```
5. Como último recurso em DEV apenas:
   ```bash
   export JIRA_VERIFY_SSL=0
   ```
   (NÃO use em produção.)
6. Invalidação de CRL: pode indicar que a cadeia não inclui lista de revogação; obtenha CRL corporativa ou ignore somente em dev.

## Testes

Rodar apenas o teste do controller:

```bash
bin/rails test test/controllers/metrics/authors_controller_test.rb
```

Ou toda a suíte:

```bash
bin/rails test
```
