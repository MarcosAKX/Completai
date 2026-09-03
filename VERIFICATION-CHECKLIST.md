# VERIFICATION-CHECKLIST.md — CompletAI

> Checklist a seguir sempre que uma tarefa (sua, da outra pessoa, ou de um
> agente como Codex/Claude Code) alterar `firestore.rules`,
> `SCHEMA-FIRESTORE.md`, ou qualquer código Flutter. Nem toda tarefa precisa
> de todos os passos — ver "quando pular etapas" no final.

## Ordem completa (mudança que toca rules + código)

1. **Testes de rules no Emulator**
   ```
   cd tests\firestore-rules
   npm ci
   npm test
   ```
   Só prossiga se todos passarem. Se algum falhar, NÃO siga para o deploy —
   volte e corrija a rule ou o teste primeiro.

2. **Deploy das rules** (só depois do passo 1 passar)
   ```
   cd ..\..
   firebase deploy --only firestore:rules
   ```

3. **Testes Flutter**
   ```
   flutter analyze
   flutter test
   ```

4. **Teste manual no app**
   ```
   flutter run
   ```
   Percorra o fluxo afetado pela mudança manualmente (ex: se mudou cadastro
   de posto, teste o cadastro de posto de ponta a ponta, incluindo um caso
   que devia ser aceito e um que devia ser rejeitado).

## Quando pular etapas

- **Mudança só em código Flutter (não toca `firestore.rules` nem
  `SCHEMA-FIRESTORE.md`)**: pule os passos 1 e 2, vá direto para 3 e 4.
- **Mudança só em `firestore.rules`** (ex: ajuste de permissão sem mudar
  código Dart): pule os passos 3 e 4, faça só 1 e 2.
- **Mudança só em documentação** (`.md`, sem código): nenhum passo é
  necessário, mas confirme que a documentação não ficou inconsistente com o
  código real (ver regra correspondente no `CLAUDE.md`).

## Por que essa ordem, não outra

- Rules são testadas **antes** de publicadas — publicar sem testar é
  publicar uma regra de segurança sem validação.
- Deploy de rules acontece **antes** dos testes Flutter porque, se as rules
  publicadas estiverem erradas, os testes manuais no app (passo 4) vão
  falhar de um jeito confuso (erro de permissão que parece bug de código,
  mas é rule desatualizada) — eliminamos essa fonte de confusão primeiro.
- Teste manual é o **último** passo porque só faz sentido rodar contra um
  ambiente (rules publicadas) já validado pelos passos anteriores.
