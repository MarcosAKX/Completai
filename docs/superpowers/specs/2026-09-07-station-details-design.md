# Perfil público do posto — desenho da feature

## Objetivo

Substituir o painel inferior provisório aberto pelos cards da home por uma
tela pública completa do posto. A tela mantém preços como informação
principal e oferece rota, serviços, horários e avaliações, seguindo o design
system do CompletAI e a arquitetura MVVM.

## Experiência

- O toque em um card abre `StationDetailsPage` passando o `stationUid` e a
  distância já calculada pela home.
- A página usa `CustomScrollView`, capa única e seções responsivas, sem alturas
  fixas para o conteúdo.
- O cabeçalho contém voltar e favorito. Não há ação "Ligar", pois o telefone
  existente é administrativo e privado.
- "Como chegar" ocupa toda a largura e abre o aplicativo de mapas com as
  coordenadas públicas do posto.
- A sequência é: identidade, como chegar, cinco preços, serviços, horário e
  prévia de avaliações.
- Horários destacam o dia atual; a semana pode ser expandida/recolhida para
  preservar legibilidade em 320 px.
- A prévia mostra no máximo duas avaliações e oferece "Ver todas". A ação
  "Avaliar posto" abre o fluxo de avaliação do cliente.
- Loading, falha e ausência de dados são apresentados na própria página com
  ação de tentar novamente.

## Arquitetura e dados

Será criada a feature `station_details`, separada do painel administrativo do
dono:

```text
station_details/
├── data/services/
├── data/repositories/
├── domain/models/
├── domain/repositories/
└── presentation/{providers,viewmodels,views,widgets}/
```

O fluxo obrigatório é View → ViewModel → Repository → Service. A View recebe
somente modelos de apresentação e callbacks. O ViewModel não importa Material.

O carregamento usa:

- `public_stations/{uid}` para identidade, endereço, coordenadas, preços,
  serviços, horários e agregados de avaliação;
- `station_covers/{uid}` para a capa única, carregada sob demanda;
- `public_stations/{uid}/reviews`, com `limit`, para a prévia e paginação;
- `users/{clientUid}/favorites/{stationUid}` para consultar e alternar o
  favorito do cliente autenticado.

O Repository mantém cache em memória do detalhe. Capa e avaliações não são
baixadas na consulta em lote da home. A criação/edição de avaliação preserva
a transação exigida pelo schema para atualizar review, `averageRating` e
`reviewCount` juntos. Nenhum campo privado de `gas_stations` é lido.

## Navegação externa

Será usado `url_launcher` para abrir coordenadas em um aplicativo de mapas.
Falhas ao abrir o mapa serão propagadas como `Failure` tipada e exibidas pela
ViewModel. Nenhuma dependência de plano Blaze ou Cloud Functions será criada.

## Componentes

- `StationDetailsHeader`
- `StationDetailsIdentityCard`
- `StationDirectionsButton`
- `StationFuelPricesSection`
- `StationServicesSection`
- `StationOpeningHoursSection`
- `StationReviewsPreview`
- diálogo ou bottom sheet pequeno para publicar uma avaliação

Os componentes usam `AppColors`, `AppSpacing` e `AppTextStyles`. A View fica
abaixo de 300 linhas e não declara widgets complexos internamente.

## Validação

- testes do mapeamento do documento público;
- testes do ViewModel para carregamento, favorito, refresh e falhas;
- testes de widget em 320×568 para rolagem sem overflow;
- teste de navegação do card da home para o uid correto;
- testes do fluxo de avaliação e atualização de agregados;
- `flutter analyze` e `flutter test` completos.

Não haverá alteração silenciosa em `firestore.rules`. Se os testes mostrarem
que favorito ou avaliação não são aceitos pelas regras atuais, a divergência
será relatada antes de qualquer mudança nas rules.
