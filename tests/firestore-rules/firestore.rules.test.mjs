// Exercita o arquivo de rules da raiz no Firestore Emulator real, sem mocks de autorização.
import { readFile } from 'node:fs/promises';
import assert from 'node:assert/strict';
import { before, beforeEach, after, test } from 'node:test';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { collection, doc, getDoc, getDocs, setDoc, updateDoc, runTransaction } from 'firebase/firestore';
import { client, station, publicStation, review, report } from './fixtures.mjs';

let env;
const database = (uid, claims = {}) => uid ? env.authenticatedContext(uid, claims).firestore() : env.unauthenticatedContext().firestore();
const seed = (...entries) => env.withSecurityRulesDisabled(async (context) => {
  for (const [path, value] of entries) await setDoc(doc(context.firestore(), path), value);
});

before(async () => {
  // Recusa execução fora do emulador ou em host remoto.
  const address = process.env.FIRESTORE_EMULATOR_HOST;
  assert.match(address ?? '', /^(127\.0\.0\.1|localhost):\d+$/, 'Execute via npm test para iniciar o Emulator local.');
  const [host, port] = address.split(':');
  env = await initializeTestEnvironment({
    projectId: 'demo-completai-rules',
    firestore: { host, port: Number(port), rules: await readFile(new URL('../../firestore.rules', import.meta.url), 'utf8') },
  });
});
beforeEach(async () => { await env.clearFirestore(); });
after(async () => { await env?.cleanup(); });

test('cliente cria o próprio perfil sem papel conflitante', async () => {
  await assertSucceeds(setDoc(doc(database('alice'), 'users/alice'), client('alice')));
});
test('posto cria o próprio perfil sem papel conflitante', async () => {
  await assertSucceeds(setDoc(doc(database('station'), 'gas_stations/station'), station('station')));
});
test('cliente existente não pode criar papel de posto', async () => {
  await seed(['users/alice', client('alice')]);
  await assertFails(setDoc(doc(database('alice'), 'gas_stations/alice'), station('alice')));
});
test('posto existente não pode criar papel de cliente', async () => {
  await seed(['gas_stations/alice', station('alice')]);
  await assertFails(setDoc(doc(database('alice'), 'users/alice'), client('alice')));
});
for (const [path, data] of [['users/alice', client('alice')], ['gas_stations/alice', station('alice')]]) {
  test(`nega criação de perfil alheio: ${path}`, async () => {
    await assertFails(setDoc(doc(database('bob'), path), data));
  });
  test(`nega criação de perfil anônimo: ${path}`, async () => {
    await assertFails(setDoc(doc(database(), path), data));
  });
}
test('público anônimo lê documento e lista de postos', async () => {
  await seed(['public_stations/station', publicStation('station')]);
  const db = database();
  const snapshot = await assertSucceeds(getDoc(doc(db, 'public_stations/station')));
  assert.equal(snapshot.data().brandName, 'Posto teste');
  assert.equal((await assertSucceeds(getDocs(collection(db, 'public_stations')))).size, 1);
});
test('dono cria e edita dados públicos', async () => {
  const ref = doc(database('station'), 'public_stations/station');
  await assertSucceeds(setDoc(ref, publicStation('station')));
  await assertSucceeds(updateDoc(ref, { brandName: 'Nome atualizado', 'prices.ethanol': 3.5 }));
});
test('dono não cria posto público fora de SP', async () => {
  await assertFails(setDoc(doc(database('station'), 'public_stations/station'), {
    ...publicStation('station'), state: 'RJ',
  }));
});
for (const uid of [undefined, 'alice']) {
  test(`não dono ${uid ?? 'anônimo'} não cria posto público`, async () => {
    await assertFails(setDoc(doc(database(uid), 'public_stations/station'), publicStation('station')));
  });
  test(`não dono ${uid ?? 'anônimo'} não edita dados públicos`, async () => {
    await seed(['public_stations/station', publicStation('station')]);
    await assertFails(updateDoc(doc(database(uid), 'public_stations/station'), { brandName: 'Invadido' }));
  });
}
test('cliente não dono atualiza somente agregados', async () => {
  await seed(['users/alice', client('alice')], ['public_stations/station', publicStation('station')]);
  await assertSucceeds(updateDoc(doc(database('alice'), 'public_stations/station'), { averageRating: 5, reviewCount: 1 }));
});
test('review e agregados podem ser gravados na mesma transação', async () => {
  await seed(['users/alice', client('alice')], ['public_stations/station', publicStation('station')]);
  const db = database('alice');
  const ref = doc(db, 'public_stations/station');
  await assertSucceeds(runTransaction(db, async (transaction) => {
    const previous = await transaction.get(ref);
    assert.equal(previous.data().reviewCount, 0);
    transaction.set(doc(db, 'public_stations/station/reviews/alice'), review('alice'));
    transaction.update(ref, { averageRating: 5, reviewCount: 1 });
  }));
  assert.equal((await getDoc(ref)).data().reviewCount, 1);
});
for (const change of [{ brandName: 'Invadido' }, { 'prices.ethanol': 0.01 }]) {
  test(`agregados não autorizam alterar ${Object.keys(change)[0]}`, async () => {
    await seed(['users/alice', client('alice')], ['public_stations/station', publicStation('station')]);
    await assertFails(updateDoc(doc(database('alice'), 'public_stations/station'), { averageRating: 5, reviewCount: 1, ...change }));
  });
}
test('anônimo não pode atualizar agregados', async () => {
  await seed(['public_stations/station', publicStation('station')]);
  await assertFails(updateDoc(doc(database(), 'public_stations/station'), { averageRating: 5, reviewCount: 1 }));
});
for (const rating of [1, 5]) {
  test(`cliente cria review própria com rating ${rating}`, async () => {
    await seed(['users/alice', client('alice')], ['public_stations/station', publicStation('station')]);
    await assertSucceeds(setDoc(doc(database('alice'), 'public_stations/station/reviews/alice'), review('alice', rating)));
  });
}
test('cliente não pode criar review no uid de outra pessoa', async () => {
  await assertFails(setDoc(doc(database('bob'), 'public_stations/station/reviews/alice'), review('alice')));
});
for (const rating of [0, 6, -1, '5']) {
  test(`nega rating inválido: ${JSON.stringify(rating)}`, async () => {
    await assertFails(setDoc(doc(database('alice'), 'public_stations/station/reviews/alice'), review('alice', rating)));
  });
}
for (const path of ['station_reports/station/reports/alice', 'public_stations/station/reviews/bob/reports/alice']) {
  test(`autenticado cria denúncia própria: ${path}`, async () => {
    await assertSucceeds(setDoc(doc(database('alice'), path), report('alice')));
  });
  test(`nega denúncia anônima e em nome de terceiros: ${path}`, async () => {
    await assertFails(setDoc(doc(database(), path), report('alice')));
    await assertFails(setDoc(doc(database('bob'), path), report('alice')));
  });
  test(`nega leitura comum, admin false e anônima: ${path}`, async () => {
    await seed([path, report('alice')]);
    for (const db of [database('alice'), database('bob', { admin: false }), database()]) {
      await assertFails(getDoc(doc(db, path)));
      await assertFails(getDocs(collection(db, path.split('/').slice(0, -1).join('/'))));
    }
  });
  test(`admin true lê denúncia e lista: ${path}`, async () => {
    await seed([path, report('alice')]);
    const db = database('admin', { admin: true });
    assert.equal((await assertSucceeds(getDoc(doc(db, path)))).data().reporterUid, 'alice');
    assert.equal((await assertSucceeds(getDocs(collection(db, path.split('/').slice(0, -1).join('/'))))).size, 1);
  });
}
test('dados privados só podem ser lidos pelo dono, nem admin tem exceção', async () => {
  await seed(['gas_stations/station', station('station')]);
  await assertSucceeds(getDoc(doc(database('station'), 'gas_stations/station')));
  for (const db of [database(), database('alice'), database('admin', { admin: true })]) {
    await assertFails(getDoc(doc(db, 'gas_stations/station')));
  }
});
