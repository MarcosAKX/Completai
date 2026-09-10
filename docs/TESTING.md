# Testes de segurança do Firestore

Esta suíte carrega o `firestore.rules` da raiz e executa requisições contra o
Firestore Emulator real. Os testes Dart com `fake_cloud_firestore` continuam úteis
para o app, mas não substituem estes testes de autorização.

## Abordagem

Projeto Node independente em `tests/firestore-rules/`, usando o runner nativo
`node:test`, `firebase` e a biblioteca oficial `@firebase/rules-unit-testing`.
Ela oferece contextos autenticados/anônimos, custom claims e limpeza do banco,
sem precisar de conta real ou de um emulador Auth adicional. A opção Dart não
foi adotada: não há ganho em adicionar uma camada de compatibilidade de terceiros
ao fluxo oficial de teste das rules. Nenhuma dependência Flutter foi modificada.

Referências: [testes oficiais de rules](https://firebase.google.com/docs/rules/unit-tests)
e [Firestore Emulator](https://firebase.google.com/docs/emulator-suite/connect_firestore).

## Pré-requisitos e execução

- Node.js 22 ou superior (validado com Node 24).
- Java 21 ou superior no PATH; `java -version` deve mostrar a versão correta.
- Porta local 8080 livre. A CLI também utiliza portas auxiliares do Emulator Suite.
- Internet para `npm ci` e para o primeiro download do Emulator.

Na raiz do projeto, em PowerShell:

```powershell
Set-Location tests/firestore-rules
npm ci
npm test
```

Se o PATH selecionar Java 8, pode usar o Java incluído no Android Studio somente
na sessão atual do PowerShell:

```powershell
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
java -version
npm test
```

`npm test` executa a CLI instalada e fixada no lockfile:

```text
firebase emulators:exec --only firestore --project demo-completai-rules --config ../../firebase.emulators.json "npm run test:rules"
```

A CLI inicia o Emulator, executa a suíte, encerra os processos e propaga o código
de saída. A configuração dedicada fica na raiz (`firebase.emulators.json`), pois
a CLI não aceita carregar rules fora do diretório da configuração. Isso mantém
o arquivo original como fonte única, sem copiar ou alterar rules.
Não é alterado o `firebase.json` usado pelo app. Não precisa de `firebase login`,
chave de serviço, Blaze ou deploy.
O ID `demo-completai-rules` é fictício e não usa o projeto Firebase do aplicativo.
O teste recusa ausência de `FIRESTORE_EMULATOR_HOST` ou host não local.

Para reutilizar um Emulator iniciado manualmente com a mesma configuração:

```powershell
$env:FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080'
npm run test:rules
```

O banco de teste é limpo antes de cada caso. Não execute duas suítes simultâneas
no mesmo Emulator/projeto. Fixtures são inseridas com `withSecurityRulesDisabled`
somente para preparar cenários; todas as operações verificadas usam rules ativas.
Permissões negadas esperadas podem aparecer nos logs mesmo com testes aprovados.

## Cobertura

- Cadastro inicial de ambos os papéis; conflito sequencial nos dois sentidos;
  criação de perfil alheio e anônimo negada.
- Leitura anônima de documento/lista pública; escrita pelo dono e negação a terceiros.
- Cadastro público aceita `state: 'SP'` e nega estado diferente; fixtures usam
  cidade livre (`Ribeirão Preto`), bairro e telefones conforme o schema atual.
- Atualização de agregados por cliente não dono, inclusive junto de review em
  transação; negação de alteração simultânea de nome ou preço; negação anônima.
- Reviews no próprio UID, impersonação negada, limites 1 e 5 aceitos e valores
  fora da faixa/tipo incorreto negados.
- Denúncias de posto e de review: criação própria autenticada; leitura/listagem
  negadas sem claim, com `admin: false` e sem autenticação; permitidas com
  `authenticatedContext('admin', { admin: true })`.
- Perfil privado de posto: leitura pelo dono; negação a terceiros, anônimo e admin.

## Limites e revisão de segurança

O cenário de concorrência de papéis já aceito no SCHEMA-FIRESTORE.md não é uma
garantia desta suíte. Não se deve interpretar os testes sequenciais como prova
de exclusividade em requisições simultâneas ou em batch.

A regra de agregados restringe campos e faixas, mas não exige a presença da review
na mesma transação: o teste de atualização direta, pedido neste escopo, demonstra
essa permissão. A transação positiva prova que o fluxo funciona, não que as rules
obrigam todos os clientes a utilizá-lo nem que validam a média matematicamente.

Não se altera `firestore.rules` para fazer a suíte passar. Se um caso falhar,
investigue dados/expectativa, caminho e erro do Emulator; reporte divergências
de autorização antes de propor alterações nas regras.

## Publicação necessária para "Minhas avaliações"

Após executar os testes do Emulator com `npm test` na pasta
`tests/firestore-rules`, publique da raiz do projeto:

```powershell
firebase deploy --only "firestore:rules,firestore:indexes" --project tcc-completai
```

Aguarde o índice do grupo `reviews` ficar pronto no Firebase Console antes
de validar a tela com dados reais. O Emulator verifica as regras, mas não
comprova a disponibilidade/construção do índice em produção.
O histórico exige o filtro `clientUid` e ordena por `createdAt` e caminho
do documento; dados novos e existentes com esses campos são consultados.

## Paginação pública de avaliações

O teste do Emulator `reviews públicas paginam datas iguais sem perder nem
repetir documentos` cobre a consulta de “Ver todas”: data decrescente,
identificador decrescente e `startAfter` com ambos os valores. Inclui remoção
do documento do cursor entre páginas. A suíte atual tem 52 testes aprovados.

O `fake_cloud_firestore` 4.2.0 não suporta corretamente `startAfter` com
`FieldPath.documentId`. Por isso, a continuação é validada no Emulator; os
testes Flutter verificam a montagem do cursor (incluindo nanossegundos),
a primeira página e o comportamento da tela. Não há alteração de rules
ou índices para esta correção.

## Localização automática no Chrome

- Rodar `flutter run -d chrome` e permitir localização ao entrar como motorista.
  Conferir cidade, lista e distâncias. Web publicado exige HTTPS; localhost
  pode ser usado no desenvolvimento.
- Negar localização e conferir “Escolher cidade”; selecionar Bebedouro e
  puxar para atualizar deve funcionar sem solicitar GPS novamente.
- Simular rede indisponível e conferir a alternativa manual. Serviço externo
  indisponível não deve manter carregamento indefinidamente.
- `city_geocoding_service_test.dart` e `device_location_flow_test.dart` usam
  GPS/HTTP simulados, sem enviar coordenadas de teste para o serviço real.

BigDataCloud é a alternativa gratuita para a **posição atual do próprio
dispositivo**, diretamente do navegador/app. Não usar para coordenadas de
postos, em backend ou em lotes. O serviço recebe coordenadas e IP para
aprimorar sua geolocalização. Uso sujeito à
[política de uso](https://www.bigdatacloud.com/docs/article/fair-use-policy-for-free-client-side-reverse-geocoding-api)
e à [explicação de privacidade do serviço](https://www.bigdatacloud.com/docs/article/why-is-reverse-geocoding-api-free).
O cadastro de endereços continua usando a implementação anterior.

## Estado de Git

Não havia repositório Git nem AGENTS.md no projeto/ancestrais verificados.
Foi inicializado Git na branch `test/firestore-rules-emulator`, sem commit/push.
A branch ainda não tem commit inicial; portanto não há base para um worktree
separado ou diff contra histórico. Os arquivos anteriores permanecem sem stage.

## Resultado da execução

Execução em 03/09/2026: **35 testes passaram; 0 falhas, 0 ignorados**.
`npm test` encerrou com código 0 e desligou o Emulator.

Ambiente: Node 24.18.0, Java 21.0.10, Firebase CLI 15.29.0,
Firestore Emulator 1.22.0, rules-unit-testing 5.0.2 e Firebase JS 12.18.0.

Na primeira tentativa, a configuração dentro da pasta Node apontava para uma
rules fora do diretório do projeto e a CLI recusou iniciar. O erro era da
configuração de teste, corrigido movendo somente essa configuração para a raiz.
Nenhum teste de autorização falhou na execução válida.

Os 16 testes Flutter passaram com `flutter test --no-pub`. A primeira execução
paralela dos comandos Flutter teve conflito transitório em arquivos gerados iOS;
a execução sequencial passou. A análise Dart inicialmente incluiu templates da
CLI no node_modules. `analysis_options.yaml` agora exclui somente essa pasta
de dependências externas, mantendo a análise integral do app.
Após o ajuste, `flutter analyze` concluiu com **No issues found**.

SHA256 de `firestore.rules`, idêntico antes e depois da tarefa:
`F76447A26B91798FAEB11970BE68B678F67CC67D9C4A34D5C5DACEC377005A9B`.
