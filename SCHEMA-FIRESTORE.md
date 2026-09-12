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
  phone: string,               // celular, contato administrativo do cliente
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
  phone: string,                // telefone administrativo (contato do dono, não público)
  brandName: string,
  createdAt: timestamp,
  updatedAt: timestamp
}
```

### `public_stations/{uid}` (leitura pública; escrita só pelo dono via batch)
```
{
  uid: string,
  brandName: string,           // nome do posto exibido ao cliente
  brand: string,               // bandeira: 'shell' | 'ipiranga' | 'petrobras' |
                               // 'ale' | 'raizen' | 'branca' | 'outra'.
                               // Ausente/desconhecido = tratado como 'branca'.
  address: string,
  neighborhood: string,       // bairro — ajuda o motorista a localizar o posto
  city: string,                // cidade canônica retornada pela geocodificação
  citySearchKey: string,       // cidade normalizada para consulta (minúscula/sem acento)
  state: string,                // UF, derivado da geocodificação (não do texto
                                 // digitado) — ver seção "Escopo geográfico"
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

### Validação e leitura defensiva de `public_stations`

Criação e edição pelo dono validam os tipos de nome/endereço/bairro/bandeira,
coordenadas nos limites geográficos, `pricesUpdatedAt` como timestamp,
`averageRating` numérico entre 0 e 5, `reviewCount` inteiro não negativo,
e `services`/`tags` como listas de no máximo 20 itens.
`prices` deve ser mapa: cada combustível admite `null` ou número entre
0,01 e 99,999, conforme o formulário. `openingHours` deve ser mapa de dias,
cada período `null` ou `{open, close}` no formato HH:mm válido. Campos de
combustível/dia ausentes equivalem a não informado/fechado, respectivamente.

A leitura de listas isola documentos com valores inválidos e registra seu
caminho para diagnóstico, sem interromper os demais. A abertura direta de um
posto inválido retorna `ValidationException`. Campos opcionais/ausentes de
documentos antigos preservam os fallbacks de leitura existentes. Favoritos
não são apagados; um posto inválido é omitido e o histórico de avaliações
pode apresentá-lo como indisponível.

As regras não corrigem documentos existentes. Registros antigos incompletos
podem exigir reparo para aceitar novas edições pelo dono; não executar migração
ou exclusão automática. Esta validação de formato não resolve as pendências
separadas de exclusividade de papel e integridade dos agregados de reviews.

### `station_covers/{uid}` (leitura pública; escrita só pelo dono)
```
{
  uid: string,
  image: string,               // foto de exibição em JPEG base64, ~1080px no
                               // maior lado, comprimida pelo client para
                               // ≤ ~500 KB (rules limitam a string a 700 000
                               // chars para respeitar o limite de 1 MiB/doc)
  updatedAt: timestamp
}
```

> **Por que a foto fica fora de `public_stations`:** a home do motorista lê
> `public_stations` em lote (`.limit(50)` por cidade) para comparar preços.
> Embutir a foto ali faria essa query baixar dezenas de imagens de uma vez,
> violando a regra de leitura barata (ARCHITECTURE.md seção 6). Em documento
> separado, a foto é buscada **sob demanda**: quando o motorista abre um
> posto e conforme os cards entram na tela (memoizada por uid na sessão),
> nunca em massa. A bandeira (`public_stations.brand`) fica no documento
> principal porque é texto curto e aparece já na listagem.
>
> **Limitação conhecida — formato da imagem:** a compressão
> (`core/utils/jpeg_compressor.dart`, pacote `image`) decodifica JPEG, PNG,
> GIF, BMP, TIFF e WebP. **HEIC/HEIF (padrão do iPhone) não é suportado** —
> a seleção falha com `ValidationException` ("Não foi possível ler a
> imagem"). Android é a plataforma primária e a galeria do Android entrega
> JPEG, então o impacto é baixo; suporte a HEIC exigiria plugin nativo
> (`flutter_image_compress`), que foi evitado para manter os testes e o
> build desktop funcionando.

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

Além disso, criar ou editar `public_stations/{uid}` e `station_covers/{uid}`
exige que o estado final da operação contenha `gas_stations/{uid}` com
`type: "gas_station"`. A validação usa `getAfter()` para aceitar o batch
atômico do cadastro, que cria o perfil privado e o documento público juntos,
mas impede clientes e contas sem perfil de publicarem dados de posto.

## Geolocalização

- `latitude`/`longitude` são gravados **uma única vez**, no momento do
  cadastro do posto, usando o pacote `geocoding` sobre o campo `address`.
- Distância até o usuário é **calculada no client**, em tempo de
  renderização, usando `geolocator` sobre a posição atual do usuário e as
  coordenadas já salvas — nunca gera leitura extra ao Firestore.
- Se a geocodificação falhar no cadastro (endereço não encontrado), o posto
  não deve ser salvo até o dono corrigir o endereço — não persista
  `latitude`/`longitude` nulos silenciosamente.

## Escopo geográfico

O MVP aceita cadastro de postos em **qualquer cidade do estado de São
Paulo** (não mais restrito a Bebedouro). A restrição de estado é aplicada
assim:

> **Cobertura inicial da descoberta:** embora o schema continue preparado
> para cidades de todo o estado, o seletor manual do MVP oferece somente
> `Bebedouro`. Essa lista é definida localmente no domínio e não consulta
> todos os documentos de `public_stations`, evitando leituras desnecessárias.

1. O dono do posto digita endereço, bairro e cidade livremente para localizar o endereço.
2. No cadastro, a `AddressGeocodingService` usa `placemarkFromAddress`
   (não só `locationFromAddress`) para obter o `administrativeArea`
   (UF) retornado pela geocodificação — **não o texto que o usuário
   digitou**.
3. Se o `administrativeArea` não corresponder a "SP", o cadastro é
   rejeitado no client com `ValidationException` ("Cadastro disponível
   apenas para postos no estado de São Paulo.") **antes** de qualquer
   escrita no Firestore.
4. O campo `state` gravado em `public_stations/{uid}` vem do resultado da
   geocodificação, não do input do usuário — evita que alguém digite
   "SP" manualmente para burlar a restrição enquanto o endereço real é de
   outro estado.
5. O campo `city` persistido também vem da geocodificação. O client deriva
   `citySearchKey` em minúsculas, sem acentos e com espaços normalizados. A
   home deriva a mesma chave da cidade detectada pelo GPS e consulta apenas
   os postos correspondentes, evitando divergências de grafia.
6. **Limitação conhecida:** essa validação acontece no client. Um cliente
   adulterado (chamando a API do Firestore diretamente) poderia, em teoria,
   gravar `state: "SP"` mesmo com endereço de outro estado, já que as rules
   validam apenas o valor do campo `state`, não a veracidade da
   geocodificação (rules não têm acesso a serviços de geocodificação
   externos). Isso é uma restrição de **escopo de produto** (quais postos
   o app pretende listar), não de segurança de dados sensíveis — o risco
   aceito aqui é bem menor do que o P0 de escalada de papel, e documentado
   pelo mesmo motivo: correção completa exigiria validação server-side.

## Adição de campos administrativos (celular, telefone, bairro)

`users.phone`, `gas_stations.phone` e `public_stations.neighborhood` foram
adicionados após a implementação inicial das telas de cadastro. **Nenhuma
mudança em `firestore.rules` foi necessária** — as regras de criação/edição
desses documentos validam apenas dono, tipo e tamanho de arrays, não a lista
completa de campos permitidos, então os novos campos já são aceitos.

## Painel do posto (bandeira, foto, edição de preços/nome/endereço)

`public_stations.brand` foi adicionado junto com o painel administrativo do
dono (`features/station_panel`). **Não exigiu mudança em `firestore.rules`**
pelo mesmo motivo acima — a regra de `update` do dono não lista campos, só
valida `state`/`city`/`citySearchKey` e o tamanho de `services`/`tags`, que
continuam presentes no documento após um `update` parcial.

A coleção `station_covers/{uid}` **exigiu** um bloco novo em
`firestore.rules` (leitura pública, escrita só do dono, teto de 700 000
chars na string `image`). A escrita também exige o papel privado de posto,
assim como `public_stations`, impedindo que um motorista publique uma capa
usando o próprio uid.

O painel edita `public_stations` por `update` parcial (preços via
`prices.<chave>` + `pricesUpdatedAt`; bandeira via `brand`; aba Informações
grava `services` + `tags` juntos; aba Horários grava `openingHours` inteiro
com as 7 chaves) e o nome/telefone por **batch** em `gas_stations` +
`public_stations` (o nome vive nas duas). Editar o endereço re-executa a
geocodificação (`AddressGeocodingService`, agora em `lib/shared/services/`) e
regrava cidade canônica, `citySearchKey`, `state` e coordenadas — mesma
validação SP do cadastro. **Nenhuma dessas edições exigiu mudança de rules** —
o limite de 20 em `services`/`tags` já existia e é o client que impede passar
disso antes de escrever.

## Histórico pessoal de avaliações

A feature `my_reviews/` consulta `collectionGroup('reviews')` filtrando
`clientUid == uid` da sessão, com `createdAt` decrescente e caminho do
documento decrescente como desempate. Usa páginas de 20 e cursor com
timestamp completo (segundos/nanossegundos) + caminho, evitando perder
avaliações criadas no mesmo instante.

O índice de grupo está em `firestore.indexes.json`, registrado em
`firebase.json`. As rules permitem essa consulta filtrada ao autor por
um match recursivo somente de `list`; não há nova permissão de escrita.
As avaliações individuais nos postos continuam públicas.

Não há coleção duplicada nem migração dos documentos atuais. O histórico
exibe somente caminhos `public_stations/{stationUid}/reviews/{uid}`.
Mostra a data original `createdAt` (preservada ao editar), a nota pessoal
e o comentário; não comprova abastecimentos nem registra visitas repetidas.
Postos excluídos são mostrados como indisponíveis, preservando a avaliação.
Consultas ordenadas requerem `createdAt`, campo já presente no schema.

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
