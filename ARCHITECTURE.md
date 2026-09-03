# ARCHITECTURE.md — CompletAI (do zero)

> Fonte da verdade da arquitetura. Toda tela, feature ou alteração de código
> DEVE seguir estas regras. Todo prompt de geração de código deve receber
> este arquivo como contexto obrigatório.

---

## 1. Stack técnica

- **Framework:** Flutter, Android como plataforma primária
- **Linguagem:** Dart, null-safety obrigatório
- **Gerenciamento de estado:** **Riverpod** (`AsyncNotifier`/`Notifier`)
- **Backend:** Firebase — **plano Spark (gratuito)**, sem Cloud Functions
  - Firestore (ver `SCHEMA-FIRESTORE.md`)
  - Firebase Auth + Google Sign-In
- **Geolocalização:** `geocoding` (1x no cadastro) + `geolocator` (cálculo de
  distância no client, em tempo de renderização)
- **Arquitetura:** MVVM + Repository Pattern, feature-first — **sem exceção,
  desde a primeira tela** (o projeto anterior falhou em manter isso
  consistente; aqui é regra travada desde o início)

---

## 2. Estrutura de pastas (obrigatória)

```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   └── routes.dart
├── core/
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── app_colors.dart
│   │   ├── app_spacing.dart
│   │   └── app_text_styles.dart
│   ├── widgets/
│   ├── utils/
│   ├── errors/
│   │   ├── failures.dart
│   │   └── exceptions.dart
│   └── constants/
├── features/
│   └── <feature>/
│       ├── data/
│       │   ├── services/
│       │   └── repositories/     # implementação concreta
│       ├── domain/
│       │   ├── models/
│       │   └── repositories/     # interface abstrata
│       └── presentation/
│           ├── viewmodels/       # AsyncNotifier/Notifier — Dart puro
│           ├── providers/        # Provider() do Riverpod
│           ├── views/
│           └── widgets/
└── shared/
    └── models/
```

## 3. Limite de tamanho — regra contínua, não campanha de limpeza

- View acima de **~300 linhas**: pare e extraia widgets antes de continuar.
- ViewModel acima de **~250 linhas**: pare e avalie se está assumindo
  responsabilidade demais.
- **Nenhum widget de apresentação declarado dentro do arquivo da tela.** Todo
  `StatelessWidget` reutilizável ou complexo vai para `widgets/` desde a
  primeira vez que é escrito.

Esta regra existe porque o projeto anterior chegou a arquivos de 2000+
linhas por não ter esse limite desde o início. Aqui, extrair é hábito
contínuo, não tarefa de refatoração à parte.

## 4. Regras de arquitetura (MVVM + Riverpod)

1. View → ViewModel (`AsyncNotifier`) → Repository (interface) → Service.
2. View nunca importa Firebase, Service, nem Repository diretamente.
3. ViewModel nunca importa `package:flutter/material.dart`.
4. ViewModel depende da abstração do Repository, nunca da implementação.
5. Erros nunca são engolidos: `AsyncValue.guard` obrigatório em toda
   operação assíncrona da ViewModel; proibido `catch (_) {}`.
6. Repository é o único responsável por cache/controle de custo de leitura
   Firestore.
7. Um Provider por Repository (`Provider<XRepository>`), injetado via
   `ref.read`/`ref.watch` — nunca instanciar Service/Repository direto na
   View ou ViewModel.

## 5. Design System

- Cores, tipografia e espaçamento sempre de `core/theme/`.
- Escala de espaçamento: `xs=4, sm=8, md=16, lg=24, xl=32, xxl=48`.
- Componentes repetidos vivem em `core/widgets/`.

## 6. Regras Firebase (orçamento zero — plano Spark)

1. Proibido Cloud Functions.
2. Repository cacheia em memória.
3. Evitar `.snapshots()` fora de onde é essencial.
4. Listas paginadas com `.limit()`.
5. Denormalizar (ver `SCHEMA-FIRESTORE.md`: `averageRating`/`reviewCount`
   agregados evitam N+1 de reviews desde o início).

## 7. Segurança de papel (lição do P0 anterior)

Um `uid` nunca pode ter `users/{uid}` e `gas_stations/{uid}`
simultaneamente. Ver `firestore.rules`, função `noConflictingRole`. Toda
Service de cadastro deve validar isso também no client antes de escrever
(defesa em profundidade — rules são a garantia real, client é UX).

## 7.1 Feature `admin/` (painel de denúncias)

- Papel de admin vem de custom claim (`admin: true`), nunca de documento
  Firestore. Ver `ADMIN.md` para o mecanismo de concessão (script local,
  sem Cloud Functions).
- `AdminViewModel` deve checar
  `FirebaseAuth.instance.currentUser?.getIdTokenResult()` antes de tentar
  ler `station_reports`/`reports` — trate como UX (evitar erro de permissão
  feio na tela); a segurança real está nas `firestore.rules`.
- Estrutura da feature segue o mesmo padrão MVVM das demais:
  `features/admin/{data,domain,presentation}`.

## 8. Checklist antes de considerar uma tela "pronta"

- [ ] Segue a estrutura de pastas da seção 2
- [ ] Nenhum arquivo passou do limite da seção 3 sem extração
- [ ] View não importa Firebase/Service/Repository diretamente
- [ ] ViewModel sem import de `material.dart`, usando `AsyncNotifier`
- [ ] Nenhum `catch (_) {}` vazio
- [ ] Sem valor de tema hardcoded
- [ ] Estados de loading/erro/vazio tratados via `AsyncValue.when`
- [ ] Teste da ViewModel escrito junto com a feature, não depois

## 9. Documentos relacionados

- `SCHEMA-FIRESTORE.md` — modelo de dados completo
- `firestore.rules` — regras de segurança
