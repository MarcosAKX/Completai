// Exercita o arquivo de rules da raiz no Firestore Emulator real, sem mocks de autorização.
import { readFile } from 'node:fs/promises';
import assert from 'node:assert/strict';
import { before, beforeEach, after, test } from 'node:test';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { collection, collectionGroup, query, where, orderBy, documentId, limit, startAfter, doc, getDoc, getDocs, setDoc, updateDoc, deleteDoc, runTransaction, writeBatch } from 'firebase/firestore';
import { client, station, publicStation, stationCover, review, report } from './fixtures.mjs';
import { Timestamp } from 'firebase/firestore';

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

for (const [field, value] of [
  ['prices', 'invalid'], ['prices', { ethanol: '3,99' }],
  ['prices', { ethanol: -1 }], ['prices', { ethanol: 100 }],
  ['prices', { ethanol: NaN }], ['prices', { ethanol: Infinity }],
  ['openingHours', []], ['openingHours', { monday: { open: '25:00', close: '18:00' } }],
  ['openingHours', { monday: 'aberto' }], ['brandName', 1],
  ['pricesUpdatedAt', 'ontem'], ['latitude', 91], ['longitude', '0'],
  ['services', 'loja'], ['tags', {}], ['averageRating', 6], ['reviewCount', 1.5],
]) {
  test(`posto rejeita formato inválido em ${field}: ${JSON.stringify(value)}`, async () => {
    await seed(['gas_stations/station', station('station')]);
    const ref = doc(database('station'), 'public_stations/station');
    await assertFails(setDoc(ref, { ...publicStation('station'), [field]: value }));
    await seed(['public_stations/station', publicStation('station')]);
    await assertFails(updateDoc(ref, { [field]: value }));
  });
}
test('posto aceita faixa do formulário, null, horários noturnos e 24 horas', async () => {
  await seed(['gas_stations/station', station('station')]);
  const ref = doc(database('station'), 'public_stations/station');
  await assertSucceeds(setDoc(ref, { ...publicStation('station'),
    prices: { gasolineRegular: 0.01, ethanol: 99.999, dieselS10: null },
    openingHours: { monday: { open: '18:00', close: '02:00' }, tuesday: { open: '00:00', close: '00:00' } },
  }));
  await assertSucceeds(updateDoc(ref, { 'prices.ethanol': null }));
});

test('reviews públicas paginam datas iguais sem perder nem repetir documentos', async () => {
  const date = new Timestamp(1700000000, 123456789);
  await seed(...Array.from({ length: 21 }, (_, index) => {
    const uid = `client-${String(index).padStart(2, '0')}`;
    return [`public_stations/station/reviews/${uid}`, { ...review(uid), createdAt: date }];
  }), ['public_stations/station/reviews/older', { ...review('older'), createdAt: new Timestamp(1699999999, 0) }]);
  const db = database(); // Leitura pública, inclusive sem login.
  const base = query(collection(db, 'public_stations/station/reviews'), orderBy('createdAt', 'desc'), orderBy(documentId(), 'desc'));
  const first = await assertSucceeds(getDocs(query(base, limit(21))));
  const visible = first.docs.slice(0, 20);
  const last = visible.at(-1);
  // Não depende de reler o documento que originou o cursor.
  await env.withSecurityRulesDisabled(context => deleteDoc(doc(context.firestore(), last.ref.path)));
  const savedDate = last.get('createdAt');
  const second = await assertSucceeds(getDocs(query(base,
    startAfter(new Timestamp(savedDate.seconds, savedDate.nanoseconds), last.id), limit(21))));
  const ids = [...visible, ...second.docs].map(item => item.id);
  assert.equal(first.size, 21);
  assert.equal(second.size, 2);
  assert.equal(new Set(ids).size, 22);
  assert.deepEqual(ids, [...Array.from({ length: 21 }, (_, i) => `client-${String(20-i).padStart(2, '0')}`), 'older']);
});

test('cliente cria o próprio perfil sem papel conflitante', async () => {
  await assertSucceeds(setDoc(doc(database('alice'), 'users/alice'), client('alice')));
});
test('posto cria o próprio perfil sem papel conflitante', async () => {
  await assertSucceeds(setDoc(doc(database('station'), 'gas_stations/station'), station('station')));
});
test('cadastro atômico cria perfil privado e público do posto', async () => {
  const db = database('station');
  const batch = writeBatch(db);
  batch.set(doc(db, 'gas_stations/station'), station('station'));
  batch.set(doc(db, 'public_stations/station'), publicStation('station'));
  await assertSucceeds(batch.commit());
});
test('cliente não publica posto nem capa usando o próprio uid', async () => {
  await seed(['users/alice', client('alice')]);
  const db = database('alice');
  await assertFails(setDoc(doc(db, 'public_stations/alice'), publicStation('alice')));
  await assertFails(setDoc(doc(db, 'station_covers/alice'), stationCover('alice')));
});
test('autenticado sem perfil de posto não publica posto nem capa', async () => {
  const db = database('ghost');
  await assertFails(setDoc(doc(db, 'public_stations/ghost'), publicStation('ghost')));
  await assertFails(setDoc(doc(db, 'station_covers/ghost'), stationCover('ghost')));
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
  await seed(['gas_stations/station', station('station')]);
  const ref = doc(database('station'), 'public_stations/station');
  await assertSucceeds(setDoc(ref, publicStation('station')));
  await assertSucceeds(updateDoc(ref, { brandName: 'Nome atualizado', 'prices.ethanol': 3.5 }));
});
test('dono grava bandeira e serviços em public_stations sem regra extra', async () => {
  await seed(['gas_stations/station', station('station')], ['public_stations/station', publicStation('station')]);
  await assertSucceeds(updateDoc(doc(database('station'), 'public_stations/station'), {
    brand: 'shell', services: ['calibragem', 'conveniência'],
  }));
});
test('dono grava horários de funcionamento', async () => {
  await seed(['gas_stations/station', station('station')], ['public_stations/station', publicStation('station')]);
  await assertSucceeds(updateDoc(doc(database('station'), 'public_stations/station'), {
    openingHours: { monday: { open: '08:00', close: '18:00' }, tuesday: null, wednesday: null, thursday: null, friday: null, saturday: null, sunday: null },
  }));
});
test('dono não passa de 20 serviços ou marcadores', async () => {
  await seed(['gas_stations/station', station('station')], ['public_stations/station', publicStation('station')]);
  const ref = doc(database('station'), 'public_stations/station');
  await assertFails(updateDoc(ref, { services: Array.from({ length: 21 }, (_, i) => `s${i}`) }));
  await assertFails(updateDoc(ref, { tags: Array.from({ length: 21 }, (_, i) => `t${i}`) }));
});
test('posto legado sem street/number/cep continua gravável', async () => {
  await seed(['gas_stations/station', station('station')]);
  const data = publicStation('station');
  delete data.street;
  delete data.number;
  delete data.cep;
  await assertSucceeds(setDoc(doc(database('station'), 'public_stations/station'), data));
});
test('dono grava endereço estruturado com CEP de 8 dígitos', async () => {
  await seed(['gas_stations/station', station('station')], ['public_stations/station', publicStation('station')]);
  await assertSucceeds(updateDoc(doc(database('station'), 'public_stations/station'), {
    address: 'Avenida Brasil, 250', street: 'Avenida Brasil', number: '250', cep: '14701010',
  }));
});
test('CEP vazio é aceito; com máscara ou incompleto é recusado', async () => {
  await seed(['gas_stations/station', station('station')], ['public_stations/station', publicStation('station')]);
  const ref = doc(database('station'), 'public_stations/station');
  await assertSucceeds(updateDoc(ref, { cep: '' }));
  await assertFails(updateDoc(ref, { cep: '14700-000' }));
  await assertFails(updateDoc(ref, { cep: '147' }));
  await assertFails(updateDoc(ref, { cep: 14700000 }));
});
test('número do imóvel não passa de 10 caracteres', async () => {
  await seed(['gas_stations/station', station('station')], ['public_stations/station', publicStation('station')]);
  const ref = doc(database('station'), 'public_stations/station');
  await assertSucceeds(updateDoc(ref, { number: 's/n' }));
  await assertFails(updateDoc(ref, { number: '12345678901' }));
  await assertFails(updateDoc(ref, { street: 'x'.repeat(201) }));
});
test('dono não cria posto público fora de SP', async () => {
  await seed(['gas_stations/station', station('station')]);
  await assertFails(setDoc(doc(database('station'), 'public_stations/station'), {
    ...publicStation('station'), state: 'RJ',
  }));
});
test('dono não cria posto público sem chave normalizada de cidade', async () => {
  await seed(['gas_stations/station', station('station')]);
  const data = publicStation('station');
  delete data.citySearchKey;
  await assertFails(setDoc(doc(database('station'), 'public_stations/station'), data));
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
test('qualquer um lê a foto do posto', async () => {
  await seed(['station_covers/station', stationCover('station')]);
  for (const db of [database(), database('alice'), database('station')]) {
    await assertSucceeds(getDoc(doc(db, 'station_covers/station')));
  }
});
test('dono cria e substitui a própria foto', async () => {
  await seed(['gas_stations/station', station('station')]);
  const ref = doc(database('station'), 'station_covers/station');
  await assertSucceeds(setDoc(ref, stationCover('station')));
  await assertSucceeds(setDoc(ref, stationCover('station', 2000)));
});
test('não dono e anônimo não escrevem foto de posto', async () => {
  for (const uid of [undefined, 'alice']) {
    await assertFails(setDoc(doc(database(uid), 'station_covers/station'), stationCover('station')));
  }
});
test('foto acima do teto de tamanho é rejeitada', async () => {
  await seed(['gas_stations/station', station('station')]);
  await assertFails(setDoc(doc(database('station'), 'station_covers/station'), stationCover('station', 700001)));
});
test('foto vazia é rejeitada', async () => {
  await seed(['gas_stations/station', station('station')]);
  await assertFails(setDoc(doc(database('station'), 'station_covers/station'), { uid: 'station', image: '' }));
});
test('dono remove a própria foto; terceiro não', async () => {
  await seed(['station_covers/station', stationCover('station')]);
  await assertFails(deleteDoc(doc(database('alice'), 'station_covers/station')));
  await assertSucceeds(deleteDoc(doc(database('station'), 'station_covers/station')));
});

// A garantia aqui MUDOU de proposito. Antes era "nem admin le dado privado".
// A tela de admin precisa conferir CNPJ/e-mail/telefone para aprovar um posto
// novo, e o Felipe decidiu abrir esse acesso. O que continua valendo: terceiro
// comum e anonimo nao leem, e admin NAO escreve. Ver ADMIN.md.
test('dado privado: dono e admin leem; terceiro e anônimo não', async () => {
  await seed(['gas_stations/station', station('station')]);
  await assertSucceeds(getDoc(doc(database('station'), 'gas_stations/station')));
  await assertSucceeds(getDoc(doc(database('admin', { admin: true }), 'gas_stations/station')));
  for (const db of [database(), database('alice'), database('bob', { admin: false })]) {
    await assertFails(getDoc(doc(db, 'gas_stations/station')));
  }
});

test('admin lê dado privado do posto mas não escreve nele', async () => {
  await seed(['gas_stations/station', station('station')]);
  const db = database('admin', { admin: true });
  await assertFails(updateDoc(doc(db, 'gas_stations/station'), { phone: '(17) 90000-0000' }));
  await assertFails(deleteDoc(doc(db, 'gas_stations/station')));
});

// Histórico usa o mesmo formato de consulta da feature Flutter.
test('histórico consulta apenas autor e pagina datas iguais sem perder itens', async () => {
  await seed(
    ['public_stations/a/reviews/alice', review('alice')],
    ['public_stations/b/reviews/alice', review('alice')],
    ['public_stations/a/reviews/bob', review('bob')],
  );
  const db = database('alice');
  const base = query(collectionGroup(db, 'reviews'), where('clientUid', '==', 'alice'),
    orderBy('createdAt', 'desc'), orderBy(documentId(), 'desc'), limit(1));
  const first = await assertSucceeds(getDocs(base));
  const second = await assertSucceeds(getDocs(query(base,
    startAfter(first.docs[0].get('createdAt'), first.docs[0].ref.path))));
  assert.equal(first.size, 1);
  assert.equal(second.size, 1);
  assert.notEqual(first.docs[0].ref.path, second.docs[0].ref.path);
  assert.equal(second.docs[0].data().clientUid, 'alice');
});
test('histórico nega consulta anônima, sem filtro ou pelo autor de outra conta', async () => {
  await seed(['public_stations/a/reviews/alice', review('alice')]);
  await assertFails(getDocs(query(collectionGroup(database(), 'reviews'), where('clientUid', '==', 'alice'))));
  await assertFails(getDocs(collectionGroup(database('alice'), 'reviews')));
  await assertFails(getDocs(query(collectionGroup(database('bob'), 'reviews'), where('clientUid', '==', 'alice'))));
});

// ---------- Tela de admin: aprovação de posto ----------

test('posto novo nasce pending; dono não escolhe o status', async () => {
  await seed(['gas_stations/station', station('station')]);
  const ref = doc(database('station'), 'public_stations/station');
  await assertSucceeds(setDoc(ref, publicStation('station')));
  for (const status of ['approved', 'rejected']) {
    await assertFails(setDoc(ref, { ...publicStation('station'), status }));
  }
});

test('dono não aprova o próprio posto', async () => {
  await seed(['gas_stations/station', station('station')], ['public_stations/station', publicStation('station')]);
  const ref = doc(database('station'), 'public_stations/station');
  await assertFails(updateDoc(ref, { status: 'approved' }));
  // Nem escondido junto de uma edição legítima.
  await assertFails(updateDoc(ref, { brandName: 'Outro nome', status: 'approved' }));
  // Edição legítima sem tocar no status continua passando.
  await assertSucceeds(updateDoc(ref, { brandName: 'Outro nome' }));
});

test('admin aprova e recusa, alterando somente o status', async () => {
  await seed(['gas_stations/station', station('station')], ['public_stations/station', publicStation('station')]);
  const ref = doc(database('admin', { admin: true }), 'public_stations/station');
  await assertSucceeds(updateDoc(ref, { status: 'approved' }));
  await assertSucceeds(updateDoc(ref, { status: 'rejected' }));
  await assertFails(updateDoc(ref, { status: 'qualquer_coisa' }));
  // Admin não usa a aprovação como porta para mexer em preço ou endereço.
  await assertFails(updateDoc(ref, { status: 'approved', 'prices.ethanol': 1.5 }));
  await assertFails(updateDoc(ref, { brandName: 'Renomeado pelo admin' }));
});

test('não admin não muda status de posto alheio', async () => {
  await seed(['gas_stations/station', station('station')], ['public_stations/station', publicStation('station')]);
  for (const db of [database(), database('alice'), database('bob', { admin: false })]) {
    await assertFails(updateDoc(doc(db, 'public_stations/station'), { status: 'approved' }));
  }
});

test('posto antigo sem status continua editável pelo dono', async () => {
  const legado = publicStation('station');
  delete legado.status;
  await seed(['gas_stations/station', station('station')], ['public_stations/station', legado]);
  const ref = doc(database('station'), 'public_stations/station');
  await assertSucceeds(updateDoc(ref, { brandName: 'Nome novo' }));
  // Mas não pode se autoaprovar aproveitando a ausência do campo.
  await assertFails(updateDoc(ref, { status: 'approved' }));
});

// ---------- Tela de admin: denúncias de avaliação ----------

test('motivo da denúncia vem de lista fechada', async () => {
  const db = database('alice');
  // Um caminho por assercao: reescrever o mesmo documento seria `update`,
  // que so admin pode, e o teste mediria a regra errada.
  const path = (i) => `public_stations/s${i}/reviews/bob/reports/alice`;
  const validos = ['offensive', 'fake', 'off_topic', 'spam', 'personal_data', 'other'];
  for (const [i, reason] of validos.entries()) {
    await assertSucceeds(setDoc(doc(db, path(`ok${i}`)), { ...report('alice'), reason }));
  }
  const invalidos = ['texto livre qualquer', '', 'OFFENSIVE', 7];
  for (const [i, reason] of invalidos.entries()) {
    await assertFails(setDoc(doc(db, path(`no${i}`)), { ...report('alice'), reason }));
  }
});

test('denúncia não pode declarar outro reporterUid', async () => {
  const path = 'public_stations/station/reviews/bob/reports/alice';
  await assertFails(setDoc(doc(database('alice'), path), { ...report('bob') }));
});

test('admin lista denúncias por collectionGroup; mais ninguém', async () => {
  await seed(
    ['public_stations/a/reviews/bob/reports/alice', report('alice')],
    ['public_stations/b/reviews/carol/reports/alice', report('alice')],
  );
  const snapshot = await assertSucceeds(getDocs(collectionGroup(database('admin', { admin: true }), 'reports')));
  assert.equal(snapshot.size, 2);
  for (const db of [database(), database('alice'), database('bob', { admin: false })]) {
    await assertFails(getDocs(collectionGroup(db, 'reports')));
  }
});

test('admin apaga avaliação denunciada e corrige os agregados', async () => {
  await seed(
    ['gas_stations/station', station('station')],
    ['public_stations/station', { ...publicStation('station'), averageRating: 4, reviewCount: 2 }],
    ['public_stations/station/reviews/bob', review('bob')],
  );
  const db = database('admin', { admin: true });
  await assertSucceeds(deleteDoc(doc(db, 'public_stations/station/reviews/bob')));
  await assertSucceeds(updateDoc(doc(db, 'public_stations/station'), { averageRating: 5, reviewCount: 1 }));
});

test('não admin não apaga avaliação de terceiro', async () => {
  await seed(['public_stations/station/reviews/bob', review('bob')]);
  for (const db of [database(), database('alice'), database('station')]) {
    await assertFails(deleteDoc(doc(db, 'public_stations/station/reviews/bob')));
  }
  // O autor continua podendo apagar a própria.
  await assertSucceeds(deleteDoc(doc(database('bob'), 'public_stations/station/reviews/bob')));
});

// ---------- Avaliacao unica ----------

test('cliente avalia uma vez e não reescreve a própria avaliação', async () => {
  const ref = doc(database('alice'), 'public_stations/station/reviews/alice');
  await assertSucceeds(setDoc(ref, review('alice', 5)));
  // A segunda escrita no mesmo caminho e um update -- agora negado.
  await assertFails(setDoc(ref, review('alice', 1)));
  await assertFails(updateDoc(ref, { rating: 1 }));
  await assertFails(updateDoc(ref, { comment: 'mudei de ideia' }));
});

test('dono do posto não reescreve avaliação de cliente', async () => {
  await seed(['public_stations/station/reviews/alice', review('alice')]);
  await assertFails(updateDoc(doc(database('station'), 'public_stations/station/reviews/alice'), { rating: 5 }));
});

test('cliente continua podendo apagar a própria avaliação', async () => {
  await seed(['public_stations/station/reviews/alice', review('alice')]);
  await assertSucceeds(deleteDoc(doc(database('alice'), 'public_stations/station/reviews/alice')));
});

// ---------- Redenuncia ----------

test('posto pode denunciar de novo o mesmo cliente', async () => {
  const path = 'public_stations/station/reviews/bob/reports/station';
  const db = database('station');
  // O id do documento e o uid de quem denuncia: a segunda denuncia cai no
  // mesmo caminho e vira update. Tem que passar.
  await assertSucceeds(setDoc(doc(db, path), report('station')));
  await assertSucceeds(setDoc(doc(db, path), { ...report('station'), reason: 'spam' }));
});

test('quem denuncia não decide o próprio veredito', async () => {
  const path = 'public_stations/station/reviews/bob/reports/station';
  await seed([path, report('station')]);
  const db = database('station');
  for (const status of ['resolved', 'dismissed']) {
    await assertFails(setDoc(doc(db, path), { ...report('station'), status }));
    await assertFails(updateDoc(doc(db, path), { status }));
  }
});

test('redenúncia reabre: admin resolveu, posto denuncia de novo', async () => {
  const path = 'public_stations/station/reviews/bob/reports/station';
  await seed([path, { ...report('station'), status: 'resolved' }]);
  await assertSucceeds(setDoc(doc(database('station'), path), report('station')));
});

test('terceiro não denuncia em nome do posto', async () => {
  const path = 'public_stations/station/reviews/bob/reports/station';
  await assertFails(setDoc(doc(database('alice'), path), report('station')));
});

// ---------- Posto legado consegue editar? ----------
// Documento como os cadastrados antes de street/number/cep/status existirem.
const postoLegado = (uid) => {
  const d = publicStation(uid);
  delete d.street; delete d.number; delete d.cep; delete d.status;
  return d;
};

test('posto legado salva horários', async () => {
  await seed(['gas_stations/station', station('station')], ['public_stations/station', postoLegado('station')]);
  await assertSucceeds(updateDoc(doc(database('station'), 'public_stations/station'), {
    openingHours: {
      monday: { open: '08:00', close: '23:00' }, tuesday: { open: '08:00', close: '23:00' },
      wednesday: { open: '08:00', close: '23:00' }, thursday: { open: '08:00', close: '23:00' },
      friday: { open: '08:00', close: '23:00' }, saturday: { open: '08:00', close: '23:00' },
      sunday: { open: '08:00', close: '23:00' },
    },
  }));
});

test('posto legado salva preço e serviços', async () => {
  await seed(['gas_stations/station', station('station')], ['public_stations/station', postoLegado('station')]);
  const ref = doc(database('station'), 'public_stations/station');
  await assertSucceeds(updateDoc(ref, { 'prices.ethanol': 4.19, pricesUpdatedAt: Timestamp.fromMillis(1700000000000) }));
  await assertSucceeds(updateDoc(ref, { services: ['calibragem'] }));
});

test('posto com CEP mascarado no banco não consegue salvar nada', async () => {
  // Diagnostico: se algum documento tiver '14700-000' em vez de '14700000',
  // a regra de formato derruba TODA escrita do dono, nao so a do endereco.
  const comMascara = { ...publicStation('station'), cep: '14700-000' };
  await seed(['gas_stations/station', station('station')], ['public_stations/station', comMascara]);
  await assertFails(updateDoc(doc(database('station'), 'public_stations/station'), { brandName: 'Outro' }));
});
