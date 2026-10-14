# ADMIN.md — Painel administrativo

## Como funciona

O papel de administrador **não é um documento no Firestore** (isso repetiria
o mesmo erro P0 do projeto anterior — papel gravável pelo cliente). É uma
**custom claim** no token do Firebase Auth (`admin: true`), atribuída
manualmente por você via um script local que roda o Firebase Admin SDK.

Isso **não usa Cloud Functions** e **não tem custo** — é só um script Node
que você roda na sua máquina quando precisar promover alguém a
administrador.

## Passo 1 — Gerar a chave de serviço

1. No Firebase Console → Configurações do projeto → Contas de serviço.
2. Clique em "Gerar nova chave privada" → baixa um arquivo `.json`.
3. **Nunca commite esse arquivo no Git.** Salve fora do repositório ou
   adicione ao `.gitignore` imediatamente (ex:
   `serviceAccountKey.json`).

## Passo 2 — Script para conceder admin

Crie uma pasta separada (fora do projeto Flutter, ex: `admin-scripts/`), com:

```json
// package.json
{
  "name": "completai-admin-scripts",
  "version": "1.0.0",
  "dependencies": {
    "firebase-admin": "^12.0.0"
  }
}
```

```js
// setAdmin.js
const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const email = process.argv[2];
if (!email) {
  console.error("Uso: node setAdmin.js email@exemplo.com");
  process.exit(1);
}

admin
  .auth()
  .getUserByEmail(email)
  .then((user) =>
    admin.auth().setCustomUserClaims(user.uid, { admin: true })
  )
  .then(() => {
    console.log(`✅ ${email} agora é administrador.`);
    process.exit(0);
  })
  .catch((err) => {
    console.error("Erro:", err);
    process.exit(1);
  });
```

Rodar com: `npm install` (uma vez) e depois
`node setAdmin.js seuemail@gmail.com`.

## Passo 3 — Refletir a claim no app Flutter

O token do usuário só é atualizado com a nova claim depois de um novo login
(ou de forçar refresh: `user.getIdTokenResult(true)` no Firebase Auth do
Flutter). Depois de rodar o script, se o usuário já estiver logado no app,
ele precisa deslogar/logar de novo (ou você chama refresh do token) para o
app enxergar a claim `admin`.

## Passo 4 — A tela de admin (implementada)

Feature `features/admin/`, em MVVM como as demais. `AuthGate` verifica
`session.isAdmin` **antes** de `needsProfile`: a conta de admin não tem
documento em `users/` nem em `gas_stations/`, então sem essa ordem ela cairia
na tela de escolha de papel e ficaria presa lá — e escolher um papel a
transformaria em cliente ou posto.

Três abas:

| Aba | O que faz |
|---|---|
| **Pendentes** | Posto recém-cadastrado (`status: 'pending'`). Mostra endereço, CEP, CNPJ, e-mail e telefone; aprova ou recusa. |
| **Postos listados** | Já revisados. Permite reverter a decisão — é a única forma de corrigir sem mexer no banco. |
| **Denúncias** | Denúncias de avaliação, com o texto denunciado. Mantém (descarta a denúncia) ou remove a avaliação. |

Remover a avaliação apaga o documento e recalcula `averageRating`/
`reviewCount` do posto **na mesma transação**, a partir do estado atual em vez
de subtrair às cegas — se a avaliação já tinha sido removida, os agregados não
entram em valor negativo.

### Por que o admin lê dado privado

`gas_stations/{uid}` guarda CNPJ, e-mail e telefone administrativo. A regra
era `allow read: if isOwner(uid)` e existia um teste garantindo que **nem
admin** lia essa coleção.

**Essa garantia foi trocada de propósito**, porque aprovar um posto sem ver o
CNPJ não é conferência de nada. A regra passou a ser:

```
allow read: if isOwner(uid) || isAdmin();
```

O que continua valendo, e está coberto por teste no Emulator:

- usuário comum e anônimo **não** leem `gas_stations`;
- admin **não escreve** em `gas_stations` — nem `update`, nem `delete`;
- admin **não** altera preço, endereço ou agregado em `public_stations`: a
  regra de aprovação aceita apenas o campo `status`.

Era uma decisão deliberada sendo revista, não um descuido. Se a conferência de
CNPJ sair do escopo algum dia, reverter essas duas linhas restaura a garantia
original.

### Aprovação: onde mora o `status`

`public_stations/{uid}.status`, com três valores (`pending`, `approved`,
`rejected`) — ver `StationApprovalStatus` em `lib/shared/models/`.

Mora no documento público, e não numa coleção à parte, porque a Home precisa
saber se o posto é visível na mesma leitura em que lista a cidade. Como o dono
pode escrever qualquer campo do próprio documento, as rules travam o campo
explicitamente:

- `create` do dono exige `status == 'pending'` — ele não escolhe;
- `update` do dono exige que `status` **não mude**
  (`request.resource.data.get('status','') == resource.data.get('status','')`,
  com `get` para aceitar documento antigo que não tem o campo);
- um terceiro caso de `update` deixa o admin mudar **somente** `status`.

Sem a segunda regra o dono se aprovaria sozinho.

**Documento sem `status` é tratado como aprovado.** Isso preserva todo posto
cadastrado antes da fila existir, e é o motivo de o filtro de visibilidade
rodar em Dart e não como `where('status','==','approved')`: a query não
traria documento sem o campo, e a Home ficaria vazia.

### Denúncias: motivo é lista fechada

`ReportReason` (`lib/shared/models/report_reason.dart`) define os seis motivos
e os `wireValue` são validados nas rules. O painel do posto mostra as opções
num `ReportReasonPicker`; não existe mais campo de texto livre.

Os valores estão escritos à mão em dois lugares — no enum e na rule. Há um
teste em `test/admin_enums_test.dart` que falha se a lista do enum mudar, para
lembrar de atualizar a rule junto; sem isso a denúncia volta como
`permission-denied`.

O admin **lista** as denúncias por `collectionGroup('reports')`. Sem a regra
de collection group ele só leria uma denúncia por vez sabendo o caminho exato
— ou seja, não teria como descobrir que existe denúncia nova. A regra concede
apenas `list`, e apenas a admin. Exige o índice de collection group em
`firestore.indexes.json`.

`stationUid` e `clientUid` saem do **caminho** do documento, não de campos.
A mesma regra alcança `station_reports/.../reports`; a tela descarta o que não
casa o formato do caminho de denúncia de avaliação.

**Remover a avaliação apaga também as denúncias penduradas nela.** O
Firestore não apaga subcoleção junto com o documento pai, e o id do documento
de review é o uid do cliente — então o caminho se repete quando a mesma
pessoa avalia de novo. Sem apagar, a denúncia resolvida sobrevivia e passava
a exibir o texto da avaliação **nova**, fazendo o admin julgar o texto errado.
Há ainda uma rede de segurança na leitura: avaliação mais recente que a
denúncia não pode ser a denunciada, e é tratada como removida.

Quando a avaliação já não existe (o próprio autor apagou), a denúncia é
marcada como resolvida em vez de apagada — o registro da análise fica.

**O índice não é composto.** A consulta ordena por um campo só (`createdAt`)
num collection group, e o Firestore recusa um índice composto de campo único
("this index is not necessary, configure using single field index controls").
O que vale é um `fieldOverride` em `firestore.indexes.json` declarando o
escopo `COLLECTION_GROUP` para `reports.createdAt` — o Firestore cria índice
de campo único sozinho, mas só com escopo de coleção.

## Revogar acesso de admin

```js
// removeAdmin.js — mesma estrutura, trocando para:
admin.auth().setCustomUserClaims(user.uid, { admin: false });
```
