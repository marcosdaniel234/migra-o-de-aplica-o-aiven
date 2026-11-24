# Migração do dashboard para a Aiven

O Flask roda no Render e grava indicadores do Banco Central e registros de acesso no PostgreSQL da Aiven. O GitHub Actions provisiona a infraestrutura com Terraform. Em outro workflow, ele verifica o Python, publica a imagem Docker no GHCR e aciona o deploy do Render pelo hook. O Render faz o build do Dockerfile a partir do repositório.

## O que fiz e por quê

1. **Infraestrutura.** Executei o Terraform com o plano Free `free-1-1gb`. Para esse plano, deixei a nuvem e a janela de manutenção sob controle da Aiven. Os planos pagos continuam exigindo a nuvem. O apply criou o serviço `dashboard-pg`, o banco `dashboard` e o usuário `dashboard_app`. A aplicação usa a URI TLS padrão do novo serviço, cujo banco é `defaultdb`.
2. **Configuração.** Usei o repositório público e a branch `main` no Render, com Docker, instância Free, diretório raiz vazio, porta `8080` e Health Check Path `/healthz`. O contexto fica na raiz porque ali está o Dockerfile que copia a pasta `app/`.
3. **Pipeline.** Troquei o namespace fixo do repositório original por `github.repository` e adicionei execução manual. O health check agora aguarda a instância inicializar e exige o JSON com `status: ok`. A página HTML de espera do Render não satisfaz esse teste.
4. **Dashboard.** Acrescentei a série de acessos por minuto e a tabela de acessos recentes. A rota `/api/visits` atualiza esses dados a cada dez segundos sem registrar a própria consulta como nova visita.

## Como diagnostiquei as falhas

- O Gunicorn falhou ao iniciar porque a variável do banco continha uma string inválida. Conferi o log, substituí a variável pela URI correta e reconstruí a aplicação.
- O primeiro Terraform falhou na autenticação. Atualizei o secret com um token válido e executei o workflow novamente. O segundo apply concluiu com três recursos criados.
- Validei a aplicação primeiro com o PostgreSQL Developer já existente e depois a conectei ao `dashboard-pg` Free. O banco Free começou com as tabelas criadas pelo app e dados do Banco Central. Não houve operação de cópia de uma base histórica.

## Comprovação

- [Dashboard publicado](https://migra-o-de-aplica-o-aiven.onrender.com/). Recarregar a página registra uma visita e atualiza o contador. No teste, ele passou de 5 para 6 e a tabela mostrou seis registros.
- [Health check](https://migra-o-de-aplica-o-aiven.onrender.com/healthz). O JSON esperado é `{"status":"ok"}`, resultado de uma consulta ao PostgreSQL.
- [Terraform no GitHub Actions](https://github.com/marcosdaniel234/migra-o-de-aplica-o-aiven/actions/runs/45320658183). Confira o resultado `3 added, 0 changed, 0 destroyed`.
- [CI/CD final](https://github.com/marcosdaniel234/migra-o-de-aplica-o-aiven/actions/runs/45321490365). Confira os jobs de teste, publicação e deploy.

Para reproduzir, cadastre os secrets `AIVEN_API_TOKEN`, `AIVEN_PROJECT`, `RENDER_DEPLOY_HOOK_URL` e `APP_HEALTHCHECK_URL` no GitHub. A variável `AIVEN_DB_URL` fica no Render. O token do laboratório tem validade de sete dias. O estado Terraform desta execução ficou no runner temporário do GitHub. Para gerir os mesmos recursos em execuções futuras, configure um backend de estado com acesso restrito e importe os recursos existentes antes do próximo apply.
