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
  direto no combustível, pull-to-refresh e painel inicial do posto.
- O cadastro do posto persiste `city` canônica e `citySearchKey` derivadas da
  geocodificação. As rules exigem os campos em escritas do dono.
- Painel administrativo do dono do posto em `station_panel/` (MVVM). Substitui
  o antigo `HomePlaceholder`. Bottom nav de 4 abas: **Preços** (edita os 5
  combustíveis, publicação por diff), **Informações/Horários/Avaliações**
  (placeholder). Card "Prévia para clientes" espelha o card da listagem;
  "Editar exibição" ajusta **bandeira** (`public_stations.brand`) e **foto**.
  Tela de **Perfil** edita nome, celular e endereço (re-geocodifica, valida
  SP); CNPJ só exibe; botão Sair.
- Foto do posto em `station_cover/` (feature própria, consumida pelo painel e
  pela listagem do motorista): documento `station_covers/{uid}` com JPEG
  base64 comprimido no client (`core/utils/jpeg_compressor.dart`, pacote
  `image`), carregado sob demanda via `stationCoverProvider(uid)`.
- `AddressGeocodingService` movido de `auth/` para `lib/shared/services/`
  (usado no cadastro e na edição de endereço). `StationBrand` em
  `lib/shared/models/`. Mapeador comum de erro de infra em
  `core/errors/failure_mapper.dart` (`guardInfra` com timeout).
- `core/theme/`, `core/errors/`, `core/widgets/` já estabelecidos como padrão;
  O seletor de combustível usa opções amplas com ícones, contraste de seleção
  e área de toque confortável. `core/widgets/station_brand_badge.dart` (selo
  da bandeira) e `core/widgets/station_logo.dart` (quadrado arredondado com a
  foto ou iniciais/ícone de fallback) são usados no painel e na listagem.
- Estrutura de pastas da feature `admin/` reservada (vazia), aguardando
  implementação.
- Dependências novas: `image` e `image_picker` (foto do posto).

## Ainda não existe / próximos passos típicos

- **Rodar os testes do Emulator antes do próximo push que toque
  `firestore.rules`** — esta tarefa adicionou o bloco `station_covers` e
  casos de teste novos em `tests/firestore-rules/`; ainda não foram
  executados no Emulator nesta máquina.
- Abas **Informações** (editar `services`/`tags`), **Horários** (editar
  `openingHours`) e **Avaliações** do painel do posto — hoje placeholder.
- Favoritos, reviews e admin.

## Nota sobre manutenção deste arquivo

Este arquivo (e `ARCHITECTURE.md`/`SCHEMA-FIRESTORE.md`) devem estar sempre
sincronizados com o código real. Antes de confiar cegamente no que está
escrito aqui, uma checagem rápida (ex: `flutter analyze`, olhar a árvore de
`lib/features/`) é mais confiável do que assumir que a última atualização
foi feita corretamente — mas o objetivo é que normalmente não seja
necessário, porque cada tarefa já deixa isso atualizado.
