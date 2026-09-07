# Station Details Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Substituir o painel provisório da home por um perfil público funcional do posto, sem a ação de telefone.

**Architecture:** Uma feature `station_details` seguirá View → AsyncNotifier → Repository → Service. O detalhe público será lido por uid, reviews e favorito serão consultas limitadas/separadas, e a capa continuará usando a feature `station_cover` já existente.

**Tech Stack:** Flutter, Dart, Riverpod, Cloud Firestore, Firebase Auth, `url_launcher`.

**Spec:** `docs/superpowers/specs/2026-09-07-station-details-design.md`

## Global Constraints

- Android é a plataforma primária e o app permanece no plano Spark.
- ViewModels não importam Material ou Firebase.
- Nenhuma View acessa Service, Repository ou Firebase diretamente.
- Views ficam abaixo de 300 linhas e usam widgets extraídos.
- Nenhuma alteração em `firestore.rules` será feita sem revisão explícita.
- Não criar commit ou branch; o usuário fará isso manualmente.

---

### Task 1: Modelo e leitura pública do detalhe

**Files:**
- Create: `lib/features/station_details/domain/models/station_details.dart`
- Create: `lib/features/station_details/domain/models/station_review.dart`
- Create: `lib/features/station_details/domain/repositories/station_details_repository.dart`
- Create: `lib/features/station_details/data/services/station_details_service.dart`
- Create: `lib/features/station_details/data/repositories/station_details_repository_impl.dart`
- Test: `test/station_details_service_test.dart`

**Interfaces:**
- Produces: `Future<StationDetails> load(String stationUid, {bool forceRefresh = false})`.
- Produces: `Future<List<StationReview>> loadReviews(String stationUid, {int limit = 2})`.

- [x] Escrever teste que semeia `public_stations/{uid}` e valida cinco preços, serviços e sete dias.
- [x] Executar o teste e confirmar falha por tipos ausentes.
- [x] Implementar modelos, mapeamento e cache em memória.
- [x] Executar o teste e confirmar aprovação.

### Task 2: Estado, favorito e avaliação

**Files:**
- Create: `lib/features/station_details/domain/models/station_details_state.dart`
- Modify: `lib/features/station_details/domain/repositories/station_details_repository.dart`
- Modify: `lib/features/station_details/data/services/station_details_service.dart`
- Modify: `lib/features/station_details/data/repositories/station_details_repository_impl.dart`
- Create: `lib/features/station_details/presentation/viewmodels/station_details_viewmodel.dart`
- Create: `lib/features/station_details/presentation/providers/station_details_providers.dart`
- Test: `test/station_details_viewmodel_test.dart`

**Interfaces:**
- Produces: provider family por `stationUid`.
- Produces: `refresh()`, `toggleFavorite()` e `submitReview(rating:, comment:)`.

- [x] Escrever testes de carregamento, refresh, favorito e avaliação.
- [x] Confirmar falhas pela ausência do ViewModel.
- [x] Implementar operações com `AsyncValue.guard` e erros tipados.
- [x] Persistir favorito no caminho privado do cliente.
- [x] Persistir review e agregados na mesma transação.
- [x] Confirmar aprovação dos testes focados.

### Task 3: Interface responsiva do perfil

**Files:**
- Create: `lib/features/station_details/presentation/views/station_details_page.dart`
- Create: `lib/features/station_details/presentation/widgets/station_details_header.dart`
- Create: `lib/features/station_details/presentation/widgets/station_identity_card.dart`
- Create: `lib/features/station_details/presentation/widgets/station_directions_button.dart`
- Create: `lib/features/station_details/presentation/widgets/station_fuel_prices_section.dart`
- Create: `lib/features/station_details/presentation/widgets/station_services_section.dart`
- Create: `lib/features/station_details/presentation/widgets/station_opening_hours_section.dart`
- Create: `lib/features/station_details/presentation/widgets/station_reviews_preview.dart`
- Create: `lib/features/station_details/presentation/widgets/station_review_sheet.dart`
- Test: `test/station_details_page_test.dart`

**Interfaces:**
- Consumes: `stationDetailsViewModelProvider(stationUid)`.
- Produces: `StationDetailsPage(stationUid:, distanceKm:)`.

- [x] Escrever teste de widget em 320×568 que rola todas as seções e confirma ausência de “Ligar”.
- [x] Confirmar falha pela ausência da tela.
- [x] Implementar `CustomScrollView`, estados AsyncValue e widgets extraídos.
- [x] Usar tokens do tema e áreas de toque de pelo menos 48 dp.
- [x] Confirmar aprovação do teste responsivo.

### Task 4: Mapa e navegação pela home

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/features/station_discovery/presentation/views/station_discovery_station_widgets.dart`
- Modify: `lib/app/routes.dart`
- Test: `test/station_discovery_home_test.dart`

**Interfaces:**
- Consumes: `StationDetailsPage(stationUid:, distanceKm:)`.

- [x] Escrever teste que toca no card e encontra a página do uid correto.
- [x] Confirmar falha enquanto o bottom sheet provisório ainda abre.
- [x] Adicionar `url_launcher` e serviço injetável para abrir coordenadas.
- [x] Trocar o bottom sheet por navegação de página.
- [x] Confirmar aprovação dos testes focados.

### Task 5: Documentação e validação final

**Files:**
- Modify: `CLAUDE.md`
- Modify: `SCHEMA-FIRESTORE.md` somente se o código esclarecer comportamento já previsto no schema.

- [x] Atualizar “O que já existe” e “próximos passos”.
- [x] Executar `dart format` nos arquivos alterados.
- [x] Executar `flutter analyze --no-pub` e exigir zero ocorrências.
- [x] Executar `flutter test --no-pub` e exigir zero falhas.
- [x] Verificar `git diff --check` e revisar que rules não foram alteradas.

