# CLAUDE.md

> Este arquivo é lido automaticamente pelo Claude Code no início de toda
> sessão neste repositório. Contém as regras inegociáveis do projeto.

## Sobre o projeto

CompletAI — app Flutter (Android primário) de descoberta/comparação de
postos de combustível em qualquer cidade do estado de São Paulo. A cidade
deve ser confirmada pela geocodificação e o campo `state` permanece restrito
a `SP`. Firebase no plano Spark (gratuito, **sem Cloud Functions**). MVVM com
Riverpod. TCC de graduação — prazo real, qualidade de código conta na
avaliação.

## Documentos que você DEVE ler antes de qualquer tarefa

- `ARCHITECTURE.md` — estrutura de pastas, regras de MVVM, design system,
  limites de tamanho de arquivo. Fonte da verdade de arquitetura.
- `SCHEMA-FIRESTORE.md` — modelo de dados completo, coleções, regras de
  consistência (batches/transações).
- `firestore.rules` — regras de segurança atuais (já corrigidas de 3 bugs
  identificados em revisão anterior — não reintroduza os mesmos padrões).
- `ADMIN.md` — mecanismo de papel administrador (custom claim, não
  documento Firestore).
- `VERIFICATION-CHECKLIST.md` — ordem exata de comandos a rodar após
  qualquer mudança (testes de rules → deploy → testes Flutter → teste
  manual). Siga essa ordem sempre, não invente uma sequência diferente.

Se qualquer instrução minha (no chat) conflitar com esses documentos, pare e
pergunte antes de prosseguir — não assuma que o chat tem prioridade sobre a
documentação.

## Regras inegociáveis (resumo — ver ARCHITECTURE.md para detalhes)

1. **MVVM real, não de nome.** View → ViewModel (`AsyncNotifier`) →
   Repository (interface) → Service. ViewModel nunca importa
   `package:flutter/material.dart`. View nunca chama Firebase/Service/
   Repository diretamente.
2. **Zero `catch (_) {}` vazio.** Todo erro vira uma `Failure` tipada
   (`core/errors/failures.dart`) e é propagado via `AsyncValue`.
3. **Limite de tamanho, verificado a cada arquivo, não no final:** View
   acima de ~300 linhas ou ViewModel acima de ~250 linhas → pare e extraia
   widgets/métodos antes de continuar. Nenhum `StatelessWidget` reutilizável
   declarado dentro do arquivo da tela.
4. **Sem Cloud Functions, sem dependência de plano Blaze.** Toda lógica no
   client ou em Firestore Rules.
5. **Nenhuma alteração em `firestore.rules` sem reportar explicitamente
   o que mudou e por quê** — não corrija silenciosamente uma regra que
   pareça errada; pare e explique o problema encontrado antes de mudar.
6. **Um Provider por Repository**, injeção via `ref.read`/`ref.watch`.
   Nunca instanciar Service/Repository direto em View ou ViewModel.
7. **Teste escrito junto com a feature, não depois.** ViewModel testável
   sem montar árvore de widget.
8. **Papel de usuário nunca é auto-declarado sem checagem server-side.**
   Um uid não pode ser `client` e `gas_station` ao mesmo tempo — ver
   `firestore.rules`, funções `canBecomeClient`/`canBecomeStation`. Papel de
   admin é custom claim, nunca documento Firestore.

## Fluxo de trabalho esperado

- Antes de gerar código: leia os documentos relevantes listados acima.
- Ao final de qualquer tarefa: rode `flutter analyze` e `flutter test`;
  reporte o resultado, não presuma que passou.
- Se encontrar uma inconsistência entre documentação e schema/rules
  (como já aconteceu antes: caminho de coleção inválido, regra que nunca
  bloqueava nada), **documente e pare para revisão** — não corrija e siga
  em frente silenciosamente.
- Mudanças em `firestore.rules` exigem teste no Firebase Emulator antes de
  serem consideradas prontas — não é opcional.
- **Deploy de rules é automático via GitHub Actions**
  (`.github/workflows/deploy-firestore-rules.yml`): qualquer push para
  `main` que altere `firestore.rules` dispara o deploy sozinho. Não é mais
  necessário rodar `firebase deploy --only firestore:rules` manualmente
  depois de um merge — mas ainda é obrigatório rodar os testes do Emulator
  **antes** de dar push, já que o workflow não roda os testes, só publica.
- Não faça commit/push sem autorização explícita.
- Não crie documentação nova redundante — `ARCHITECTURE.md`,
  `SCHEMA-FIRESTORE.md` e `ADMIN.md` já existem; edite-os em vez de criar
  `NOVA_ARQUITETURA.md` ou similar.
- **Ao final de toda implementação, atualize este arquivo** (seções "O que
  já existe" e "Ainda não existe / próximos passos") para refletir o estado
  real do projeto. Se a tarefa também mudou o schema ou as rules, atualize
  `SCHEMA-FIRESTORE.md`/`firestore.rules` na mesma tarefa — nunca deixe a
  documentação divergir do código por mais de uma tarefa. Isso vale mesmo
  para tarefas pequenas; documentação desatualizada é pior do que nenhuma,
  porque leva a decisões erradas em sessões futuras.
- **Mantenha o `README.md` atualizado, mas com escopo restrito**: setup
  local, como rodar (`flutter run`), como rodar os testes (Flutter +
  Emulator, linkando `docs/TESTING.md`), e visão geral de 2-3 frases. O
  README **não deve duplicar** conteúdo de `ARCHITECTURE.md`/
  `SCHEMA-FIRESTORE.md` — linke para eles em vez de repetir. Documentação
  duplicada diverge com o tempo tão facilmente quanto código duplicado.

## O que já existe (não recriar)

- Documentos públicos protegidos contra formatos inválidos: rules validam
  preços, horários e tipos consumidos pelo aplicativo nas escritas do dono.
  `shared/services/public_station_data.dart` isola documentos inválidos em
  listas, registra o caminho e retorna falha tipada no detalhe individual.
  Home, favoritos e histórico continuam carregando os demais postos. Não
  corrige dados antigos; publicar rules manualmente após os testes. As
  pendências de papéis simultâneos e manipulação de reviews continuam separadas.

- Localização automática da Home compatível com Web: `CityGeocodingService`
  tenta geocodificação nativa nas plataformas compatíveis e usa BigDataCloud
  client-side como alternativa HTTP (no Chrome, diretamente). Só consulta
  coordenadas atuais obtidas com permissão, valida Brasil/SP e não trata bairro
  como cidade. Sem chave ou nova dependência; GPS/HTTP com timeout, escolha
  manual preservada. Repository compartilha chamadas simultâneas e guarda a
  cidade por 5 minutos apenas para coordenadas exatamente iguais; posição é
  obtida novamente ao atualizar. HTTP Client fechado pelo Provider.
  O provedor externo recebe coordenadas/IP; ver política e teste manual em
  `docs/TESTING.md`. Não é usado para geocodificar endereços de postos.

- Feature `auth/` completa em `data/domain/presentation`, com ViewModels
  separados de sessão, login, cadastro e recuperação (`AsyncNotifier`),
  `AuthRepository`/`AuthRepositoryImpl` e serviços de autenticação, perfil e
  geocodificação.
- Telas de login, recuperação, escolha de papel e cadastro de cliente/posto,
  com responsividade validada em 320x568.
- Splash em três estágios: recurso nativo Android, carregamento Web e animação
  Flutter com bomba, mangueira e restauração de sessão com duração mínima.
- Home funcional do motorista em `station_discovery/`, seguindo MVVM. Detecta
  a cidade pelo GPS, consulta `public_stations` por `citySearchKey`, calcula
  distância no aparelho e ordena por menor preço com distância como desempate.
  Inclui busca, filtro por avaliação/aberto, troca sequencial por swipe, toque
  direto no combustível e pull-to-refresh. O toque no card abre o perfil
  público completo do posto.
- Atualização da home respeita a origem da cidade: seleção manual recarrega
  a cidade escolhida sem consultar GPS; modo automático detecta novamente a
  localização. Filtros, combustível e ordenação são preservados, inclusive
  para nova tentativa após falha de atualização.
- Funcionamento da Home, detalhe e favoritos usa cálculo Dart compartilhado
  em `shared/models/station_hours_status.dart`. A Home preserva os horários
  semanais já recebidos na consulta e considera o expediente do dia anterior,
  inclusive domingo para segunda, tanto no card quanto no filtro Só abertos.
  Abertura igual ao fechamento representa 24 horas no dia configurado.
- Ações rápidas da home com altura uniforme e setas no canto inferior direito.
- Cartões de postos na home com fundo branco, borda azul suave e sombra
  discreta; fotos, informações e organização dos combustíveis preservadas.
- Perfil público em `station_details/` (MVVM): capa única sob demanda, cinco
  preços, serviços, horários expansíveis com suporte à virada da meia-noite,
  rota externa pelo Google Maps, favorito privado e avaliações públicas. A
  prévia exibe até três reviews em cards organizados e “Ver todas” abre uma
  tela própria com texto integral e paginação de 20 itens. A consulta usa
  cursor com timestamp completo (segundos/nanossegundos) e identificador do
  documento na paginação pública, sem pular avaliações com datas iguais.
  Cards da prévia e de “Ver todas” mostram a data original da avaliação
  abaixo do autor, no formato dd/mm/aaaa; ausência usa “Data não informada”.
  A nota agregada usa
  cinco estrelas e permanece limitada visualmente ao intervalo de 0 a 5. Não mostra telefone,
  pois o único telefone atual é administrativo e privado.
- Seções de preços, serviços, horários e avaliações do detalhe público com
  o mesmo fundo branco, borda azul suave e sombra discreta dos cartões da home.
- Botão "Como chegar" no detalhe público com título em destaque, textos
  alinhados à esquerda, ícones de rota/link externo e cantos arredondados.
  O destino enviado ao Google Maps é o **endereço em texto**
  ("Rua X, 100, Centro, Bebedouro, SP, Brasil"), não a coordenada gravada:
  o OSM quase não tem número de porta no interior de SP (Bebedouro inteira
  tem 39 objetos com `addr:housenumber`), então `latitude`/`longitude`
  apontam para o centro da via. O Google tem esses números. A coordenada
  segue como destino só quando não há endereço utilizável. Ver
  `StationDirectionsService.buildQuery`.
- A cidade atendida no MVP vive em `shared/models/service_area.dart`
  (`ServiceArea.primaryCity` / `ServiceArea.cities`), que substituiu
  `station_discovery/domain/station_discovery_scope.dart` quando passou a ser
  usada por três features. O seletor manual da home oferece só essa lista e
  não lê toda a coleção de postos para descobrir cidades. O schema permanece
  preparado para expansão dentro de SP: basta editar a constante.
- A etapa 2 do cadastro do posto e a tela de perfil do posto **não deixam
  escolher a cidade** — exibem `ServiceArea.primaryCity` num
  `core/widgets/app_read_only_field.dart` travado, com a nota de que o app
  atende só essa cidade nesta fase, e enviam sempre esse valor. A
  geocodificação continua confirmando SP e derivando a `city` canônica — a
  constante restringe a escolha, não substitui a validação. Postos legados
  gravados com outra cidade são normalizados no próximo salvamento de
  endereço.
- **Endereço em partes**, não em linha única: `street` (rua/avenida),
  `number` (aceita "S/N"), `cep` (só dígitos no documento; máscara
  `cepInputFormatter` só no formulário) e `neighborhood`. `address` continua
  existindo como a linha pronta para exibição ("Rua X, 100"), composta por
  `StationAddressInput.line` — nenhum consumidor (home, detalhe, favoritos,
  prévia) precisou mudar. Postos anteriores ao campo têm `street`/`number`
  derivados de `address` na leitura por
  `StationAddressInput.splitLegacyLine`, que só trata a cauda como número
  quando ela parece um (dígitos ou "s/n").
- CEP é **obrigatório no cadastro** e **opcional no perfil** — posto legado
  não tem um gravado, e exigir preenchimento travaria até a edição de nome,
  já que `Form.validate()` valida a tela inteira.
- Geocodificação em três tentativas, nesta ordem: plugin nativo (consulta
  livre) → Nominatim **estruturado** (`street`/`city`/`state`/`postalcode`,
  mais preciso) → Nominatim **livre** (`q=`, comportamento antigo, cobre CEP
  errado). Detalhes em `SCHEMA-FIRESTORE.md`, seção "Geolocalização".
- O cadastro do posto persiste `city` canônica e `citySearchKey` derivadas da
  geocodificação. As rules exigem os campos em escritas do dono.
- Escritas do dono em `public_stations/{uid}` e `station_covers/{uid}` também
  exigem `gas_stations/{uid}` com papel de posto. A checagem usa `getAfter()`
  para preservar o batch atômico do cadastro e bloquear clientes/contas sem
  perfil. Os 47 testes das rules passam no Emulator.
- Painel administrativo do dono do posto em `station_panel/` (MVVM). Substitui
  o antigo `HomePlaceholder`. Bottom nav de 4 abas: **Preços** (edita os 5
  combustíveis, publicação por diff), **Informações** (edita `services` via
  chips + `tags` livres, teto 20), **Horários** (edita `openingHours` por dia,
  "copiar p/ todos"), **Avaliações** (lista paginada das reviews do próprio
  posto, com "Denunciar" por review). Card "Prévia para clientes" espelha o
  card da listagem, incluindo o status "aberto/fechado agora"; "Editar
  exibição" ajusta **bandeira** (`public_stations.brand`) e **foto**. Tela de
  **Perfil** edita nome, celular e endereço (re-geocodifica, valida SP); CNPJ
  só exibe; botão Sair.
- Aba Avaliações do painel (`station_reviews_tab.dart`) reaproveita o
  `StationDetailsService`/os modelos de review de `station_details/` (mesma
  coleção `public_stations/{uid}/reviews`) via um `StationPanelReviewsRepository`
  próprio — sem duplicar a paginação por cursor. "Denunciar" escreve em
  `.../reviews/{clientUid}/reports/{reporterUid}` (caminho e rules já
  existiam, só faltava o código Dart) e não altera a lista exibida.
- `WeeklyHours.toOpeningPeriods()` converte o horário do painel para o
  formato de `shared/models/station_hours_status.dart`, usado no badge
  "aberto/fechado" da prévia — mesmo cálculo da Home/detalhe/favoritos.
- Foto do posto em `station_cover/` (feature própria, consumida pelo painel e
  pela listagem do motorista): documento `station_covers/{uid}` com JPEG
  base64 comprimido no client (`core/utils/jpeg_compressor.dart`, pacote
  `image`), carregado sob demanda via `stationCoverProvider(uid)`.
  O compressor converte falhas de decodificação em `ValidationException` e
  reduz progressivamente qualidade e dimensões até respeitar o teto.
- `AddressGeocodingService` movido de `auth/` para `lib/shared/services/`
  (usado no cadastro e na edição de endereço). Tenta o plugin nativo
  `geocoding` (Android/iOS) e, se ele não existe (web/desktop) ou falha
  (Geocoder do emulador), cai num **fallback HTTP Nominatim** (OpenStreetMap,
  sem chave). A validação de SP é a mesma nos dois caminhos. Dep: `http`.
- Cadastro (cliente e posto) desfaz a conta Auth recém-criada se a gravação
  do perfil falha (`AuthRepository.discardIncompleteAccount`) — antes sobrava
  credencial órfã que travava o retry com "e-mail já existe". `_guard` do
  `AuthRepositoryImpl` loga a causa real via `dart:developer` antes de
  traduzir para `Failure` (a UI só vê a mensagem tratada).
- `StationBrand` em `lib/shared/models/`. Mapeador comum de erro de infra em
  `core/errors/failure_mapper.dart` (`guardInfra` com timeout).
- `core/theme/`, `core/errors/`, `core/widgets/` já estabelecidos como padrão;
  O seletor de combustível usa opções amplas com ícones, contraste de seleção
  e área de toque confortável. `core/widgets/station_brand_badge.dart` (selo
  da bandeira) e `core/widgets/station_logo.dart` (quadrado arredondado com a
  foto ou iniciais/ícone de fallback) são usados no painel e na listagem.
- **Tela de admin em `admin/` (MVVM), três abas**, alcançada pelo `AuthGate`
  quando `session.isAdmin` — checado **antes** de `needsProfile`, senão a
  conta de admin (que não tem `users/` nem `gas_stations/`) fica presa na
  escolha de papel. **Pendentes**: posto novo (`status: 'pending'`) com
  endereço, CEP, CNPJ, e-mail e telefone para conferência; aprova ou recusa.
  **Postos listados**: revisados, com a decisão reversível. **Denúncias**:
  denúncias de avaliação por `collectionGroup('reports')`, com o texto
  denunciado; "Manter" descarta e "Remover" apaga a avaliação recalculando
  `averageRating`/`reviewCount` na mesma transação. Dois services separados
  (`AdminStationsService`, `AdminReportsService`) atrás de um Repository.
- Remover avaliação denunciada apaga **também as denúncias penduradas nela**:
  o Firestore não apaga subcoleção junto com o pai, e o id da review é o uid
  do cliente, então o caminho se repete quando ele avalia de novo — a
  denúncia órfã grudava na avaliação nova. A leitura ainda descarta avaliação
  mais recente que a denúncia, como rede para dados antigos.
- Fila de aprovação: `public_stations/{uid}.status`
  (`shared/models/station_approval_status.dart`). O dono grava `pending` no
  cadastro e **não pode alterar** — as rules travam o campo contra ele e
  liberam só o admin. **Documento sem `status` é tratado como aprovado**, para
  não fazer desaparecer posto cadastrado antes da fila; por isso o filtro de
  visibilidade roda em Dart (home, detalhe e lista de favoritos) e não como
  `where('status','==','approved')`, que não traria documento sem o campo.
- **Troca de conta descarta o que era da conta anterior.** Os providers de
  Repository/ViewModel **não são `autoDispose`** e guardam cache em memória,
  então sobreviviam ao logout: entrar com outro posto abria o painel com o
  perfil do anterior até puxar para atualizar. Duas defesas, e uma não
  substitui a outra: `AuthGate` chama `resetUserScopedProviders`
  (`lib/app/session_scope.dart`) quando o uid muda, o que limpa o estado já
  carregado nas ViewModels; e os repositories guardam o uid junto do cache
  (`StationPanelRepositoryImpl._cachedUid`,
  `StationDetailsRepositoryImpl._guardAccount`), o que impede uma conta de
  ler o cache de outra mesmo que o reset falhe. No detalhe isso vale também
  para `isFavorite` e `hasReviewed`, que são do usuário e não do posto, mas
  moram num cache com chave só do posto. **Provider novo que guarde dado de
  conta precisa entrar em `session_scope.dart`.**
- **Avaliação é única e definitiva**: um cliente avalia um posto uma vez e
  não reescreve. O id do documento sempre foi o uid do cliente (nunca houve
  duplicata), mas antes a segunda escrita substituía a primeira e recalculava
  o agregado. Agora `allow update: if false` na review, e `writeReview`
  recusa dentro da transação (`previous.exists`) — fora dela, dois envios
  simultâneos passariam os dois. O detalhe carrega `hasReviewed` e troca o
  botão "Avaliar posto" por um aviso. Apagar a própria avaliação continua
  permitido ao autor, e o admin continua podendo remover avaliação
  denunciada.
- **Puxar para atualizar em todos os módulos.** Já havia na home, favoritos,
  histórico e detalhe. Acrescentado nas 4 abas do painel do posto, na lista
  "Ver todas" das avaliações e no perfil do cliente; as 3 abas do admin já
  nasceram com ele. Nas abas de **edição** do painel (Preços, Informações,
  Horários) o gesto **não recarrega enquanto houver alteração não salva** —
  avisa e devolve o controle, senão apagaria o que o dono digitou. Depois de
  recarregar, cada aba re-semeia o estado local, senão o `_dirty` compararia
  tela antiga com perfil novo. Lógica única em
  `station_panel/presentation/widgets/panel_refresh.dart`. Telas de
  formulário (cadastro, edição de perfil, editar exibição) não têm o gesto:
  não há o que recarregar.
- Motivo de denúncia é **lista fechada** em
  `shared/models/report_reason.dart`, validada nas rules; o painel do posto
  usa `ReportReasonPicker` (folha com opções) em vez de campo de texto. Os
  valores vivem em dois lugares — enum e rule — e `test/admin_enums_test.dart`
  falha se o enum mudar sem a rule.
- **O admin passou a ler `gas_stations`** (`isOwner(uid) || isAdmin()`). Antes
  nem admin lia, e havia teste garantindo isso; a garantia foi trocada **de
  propósito** para a conferência de CNPJ. Admin não escreve nessa coleção, e
  na aprovação só pode mudar `status`. Ver `ADMIN.md`, seção "Por que o admin
  lê dado privado".
- Dependências novas: `image` e `image_picker` (foto do posto) e
  `url_launcher` (rota externa do perfil público).

## Ainda não existe / próximos passos típicos

- `station_reports` (denúncia do **posto** inteiro, não de avaliação) continua
  sem código Dart que escreva nela: a coleção e as rules existem, nenhuma tela
  cria esse tipo de denúncia. A regra de collection group já a alcança, e a
  tela de admin a descarta por não casar o formato do caminho.
- **Deploy de rules NÃO é automático** — não existe `.github/workflows/`.
  Depois de mergear mudança em `firestore.rules`, rodar
  `firebase deploy --only firestore:rules --project tcc-completai` na mão
  (o texto sobre GitHub Actions na seção "Fluxo de trabalho" está
  desatualizado — corrigir).

## Histórico de avaliações

- Feature `my_reviews/` em MVVM, rota `/my-reviews`; o atalho da home
  "Meus abastecimentos" foi substituído por "Minhas avaliações".
- Consulta por autor via grupo `reviews`, páginas de 20, ordenação por
  data original e caminho do documento. Busca local por nome/bairro nas
  páginas carregadas; fotos sob demanda; nota pessoal e comentário completo.
- "Ver posto" abre o detalhe; ao retornar, recarrega o histórico preservando
  a busca. Inclui erro, carregamento, vazio e posto indisponível.
- Exige publicar as rules e o novo `firestore.indexes.json` antes do uso
  no Firebase real; aguardar a conclusão da construção do índice.
- Testes de regras no Emulator: 51 aprovados, incluindo consulta pessoal
  autorizada, filtros obrigatórios e paginação com datas iguais.

## Favoritos do motorista

- Feature `favorites/` em MVVM, aberta pelo atalho "Postos favoritos" da
  home (rota `/favorites`). Lista os registros privados em
  `users/{uid}/favorites`, em páginas de 20, com cursor por `stationId`.
- Busca local por nome, bairro ou cidade nos itens carregados. O contador
  indica "carregados" enquanto existem mais páginas. Cards exibem três
  combustíveis, nota, funcionamento e foto sob demanda; não exigem GPS.
- Remover só retira o card após confirmação da escrita, com "Desfazer" no
  aviso. Falhas preservam os dados. Postos excluídos são omitidos da lista.
- Abertura do detalhe atualiza o coração; ao retornar, a lista é recarregada
  mantendo a busca. Pull-to-refresh também disponível. Cache por conta/página
  no Repository, descartado quando a feature deixa de ser observada.
- Sem alteração de schema, rules ou novas dependências.

## Perfil do motorista

- Feature `client_profile/` em MVVM, aberta pelo ícone Perfil da home
  (rota `/profile`). Exibe iniciais, nome, e-mail somente para leitura e
  celular em cards; a edição de nome/celular ocorre em tela separada.
- Salvar altera somente `users/{uid}.name` e `phone`, valida os campos e
  recarrega a sessão para atualizar a saudação da home. Erros permanecem em
  `AsyncValue`; o formulário mantém os valores digitados para nova tentativa.
- Redefinição de senha por e-mail e saída usam os ViewModels de autenticação
  existentes. Sem foto do motorista, campos novos, alteração de rules ou
  atualização automática geral ao retornar entre telas.

## Nota sobre manutenção deste arquivo

Este arquivo (e `ARCHITECTURE.md`/`SCHEMA-FIRESTORE.md`) devem estar sempre
sincronizados com o código real. Antes de confiar cegamente no que está
escrito aqui, uma checagem rápida (ex: `flutter analyze`, olhar a árvore de
`lib/features/`) é mais confiável do que assumir que a última atualização
foi feita corretamente — mas o objetivo é que normalmente não seja
necessário, porque cada tarefa já deixa isso atualizado.
