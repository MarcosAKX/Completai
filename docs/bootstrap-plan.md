# Plano do bootstrap CompletAI

Documento de execução baseado em ARCHITECTURE.md, SCHEMA-FIRESTORE.md e ADMIN.md.

- Instalar dependências preservando a configuração FlutterFire existente.
- Criar domínio de auth, contratos e testes de loading, falha, sessão e cache.
- Implementar serviços Firebase/Google, perfil com exclusividade e batch de posto.
- Implementar Repository com cache por UID e tradução de erros; AsyncNotifier sem Flutter.
- Criar tokens ajustáveis, AppButton e AppTextField; inicializar Firebase e ProviderScope.
- Manter diretórios vazios com .gitkeep, incluindo a estrutura futura de admin.
- Preservar firestore.rules literalmente; documentar incompatibilidades encontradas.
- Executar dart format, flutter analyze e flutter test; entregar árvore e fontes completas.

Decisões: conta Auth e conclusão do perfil são operações separadas para permitir
retomada após falha. Papel ausente significa cadastro pendente. Admin é uma claim,
independente do papel cliente/posto. Não há exclusão de conta neste bootstrap:
ela exige limpeza recursiva e revisão das permissões antes de ser disponibilizada.
Paleta verde, tipografia Roboto e nomes auxiliares são sugestões ajustáveis.
