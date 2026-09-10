# CompletAI

Aplicativo Flutter para descobrir e comparar postos de combustível em cidades
do estado de São Paulo. Usa Firebase no plano Spark e arquitetura MVVM com
Riverpod. Consulte [ARCHITECTURE.md](ARCHITECTURE.md),
[SCHEMA-FIRESTORE.md](SCHEMA-FIRESTORE.md) e [DESIGN.md](DESIGN.md).

## Executar localmente

Configure o projeto Firebase Android e execute:

```powershell
flutter pub get
flutter run
```

O login Google permanecerá sem ação visual até o OAuth Android ser configurado.

Para Web, use `flutter run -d chrome` e permita localização para detectar a
cidade. Caso negue, escolha Bebedouro manualmente. A conversão Web usa um
serviço externo gratuito; detalhes e roteiro de validação em
[docs/TESTING.md](docs/TESTING.md#localização-automática-no-chrome).

## Testes

```powershell
flutter analyze
flutter test
```

Os testes de segurança usam o Firebase Emulator; veja
[docs/TESTING.md](docs/TESTING.md) para requisitos e comandos.
