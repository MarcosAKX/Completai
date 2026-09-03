# SCHEMA-FIRESTORE.md — CompletAI (do zero)

> Documento de referência do modelo de dados. Toda Service/Repository deve
> seguir exatamente esses nomes de coleção e campo. Alterações aqui exigem
> atualizar `firestore.rules` na mesma mudança.

---

## Coleções

### `users/{uid}` (privado — só o próprio dono lê/escreve)
```
{
  uid: string,
  type: "client",              // fixo, nunca "gas_station" — ver regra de exclusividade
  name: string,
  email: string,
  createdAt: timestamp
}
```

### `users/{uid}/favorites/{stationId}` (subcoleção privada)
```
{
  stationId: string,
  addedAt: timestamp
}
```

### `gas_stations/{uid}` (privado — só o próprio dono lê/escreve; dados sensíveis)
```
{
  uid: string,
  type: "gas_station",         // fixo, nunca "client" — ver regra de exclusividade
  cnpj: string,
  email: string,
  brandName: string,
  createdAt: timestamp,
  updatedAt: timestamp
}
```

### `public_stations/{uid}` (leitura pública; escrita só pelo dono via batch)
```
{
  uid: string,
  brandName: string,
  address: string,
  city: string,               // "Bebedouro" fixo no MVP
  latitude: number,           // geocodificado 1x no cadastro
  longitude: number,          // geocodificado 1x no cadastro
  prices: {
    gasolineRegular: number | null,
    gasolineAdditive: number | null,
    ethanol: number | null,
    dieselS10: number | null,
    dieselS500: number | null
  },
  pricesUpdatedAt: timestamp,
  openingHours: {
    monday: { open: string, close: string } | null,
    tuesday: { open: string, close: string } | null,
    wednesday: { open: string, close: string } | null,
    thursday: { open: string, close: string } | null,
    friday: { open: string, close: string } | null,
    saturday: { open: string, close: string } | null,
    sunday: { open: string, close: string } | null
  },
  averageRating: number,       // agregado, evita N+1 (ver nota abaixo)
  reviewCount: number,         // agregado, evita N+1
  services: array<string>,     // limitado em tamanho nas rules
  tags: array<string>          // limitado em tamanho nas rules
}
```

> **Por que `averageRating`/`reviewCount` são agregados aqui, e não
> recalculados por N+1 de subcoleção:** essa foi uma dívida P1 explícita do
> projeto anterior. Neste schema, toda escrita em `reviews/{uid}/{reviewId}`
> deve atualizar esses dois campos via transação Firestore no mesmo momento
> (ver seção "Consistência" abaixo). Isso evita 1 leitura de posto + N
> leituras de review por posto listado.

### `public_stations/{uid}/reviews/{clientUid}` (leitura pública; 1 review por cliente por posto)
```
{
  clientUid: string,
  clientName: string,
  rating: number,              // 1 a 5
  comment: string,
  createdAt: timestamp
}
```

### `public_stations/{uid}/reviews/{clientUid}/reports/{reporterUid}` (denúncia de review)
```
{
  reporterUid: string,
  reason: string,
  createdAt: timestamp
}
```

### `station_reports/{stationUid}/reports/{reporterUid}` (denúncia de posto)
```
{
  reporterUid: string,
  reason: string,
  createdAt: timestamp
}
```

---

## Papel de administrador

Não é um documento no Firestore — é uma **custom claim** (`admin: true`) no
token do Firebase Auth, atribuída manualmente via script local (ver
`ADMIN.md`). Isso evita repetir o erro do papel gravável pelo cliente (P0 do
projeto anterior). As coleções `station_reports` e as subcoleções `reports`
de review só permitem leitura com `isAdmin() == true` nas rules.

## Regra de exclusividade de papel (mitigação do P0 do projeto anterior)

Um mesmo `uid` **nunca** pode ter simultaneamente `users/{uid}` e
`gas_stations/{uid}`. As `firestore.rules` devem negar a criação de um se o
outro já existir. Ver `firestore.rules` para a implementação.

## Geolocalização

- `latitude`/`longitude` são gravados **uma única vez**, no momento do
  cadastro do posto, usando o pacote `geocoding` sobre o campo `address`.
- Distância até o usuário é **calculada no client**, em tempo de
  renderização, usando `geolocator` sobre a posição atual do usuário e as
  coordenadas já salvas — nunca gera leitura extra ao Firestore.
- Se a geocodificação falhar no cadastro (endereço não encontrado), o posto
  não deve ser salvo até o dono corrigir o endereço — não persista
  `latitude`/`longitude` nulos silenciosamente.

## Consistência (batches e transações)

- Criar/editar posto: `gas_stations/{uid}` e `public_stations/{uid}` são
  escritos juntos via **batch write**.
- Criar/editar/excluir review: a escrita em
  `public_stations/{uid}/reviews/{clientUid}` e a atualização de
  `averageRating`/`reviewCount` em `public_stations/{uid}` acontecem na
  **mesma transação Firestore**. As `firestore.rules` permitem que qualquer
  cliente autenticado atualize *somente* esses dois campos do documento do
  posto (via `diff().affectedKeys().hasOnly([...])`) — nenhum outro campo
  pode ser alterado por quem não é o dono do posto.
- Excluir conta (cliente ou posto): deve remover recursivamente todas as
  subcoleções relacionadas (favoritos, reviews, denúncias) — ponto que ficou
  pendente no projeto anterior; tratar desde o início aqui evita repetir a
  dívida P1 de "exclusão não recursiva".

## Limitação conhecida — corrida de papel concorrente

A checagem `canBecomeClient`/`canBecomeStation` nas rules impede que um uid
já registrado como um papel crie o outro papel **depois**. Ela não cobre o
caso raro de duas requisições simultâneas (criar `users/{uid}` e
`gas_stations/{uid}` ao mesmo tempo, nenhuma tendo visto a outra ainda).
Correção completa exigiria transação server-side (Cloud Functions, fora do
plano Spark). Documentado como risco residual aceito para o escopo do TCC.
