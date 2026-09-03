# ADMIN.md — Painel administrativo (denúncias)

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

## Passo 4 — Tela de admin no Flutter

A ViewModel de admin deve checar a claim antes de tentar ler
`station_reports`/`reports` (as rules já bloqueiam no servidor, mas checar
no client evita erro de permissão feio na tela — trate como UX, não como
segurança real; a segurança real está nas rules).

```dart
final idTokenResult = await FirebaseAuth.instance.currentUser
    ?.getIdTokenResult();
final isAdmin = idTokenResult?.claims?['admin'] == true;
```

Isso deve virar parte da `AuthViewModel` ou de uma `AdminViewModel`
dedicada, seguindo a mesma estrutura MVVM do resto do projeto — feature
`admin/` própria (`domain`, `data`, `presentation`).

## Revogar acesso de admin

```js
// removeAdmin.js — mesma estrutura, trocando para:
admin.auth().setCustomUserClaims(user.uid, { admin: false });
```
