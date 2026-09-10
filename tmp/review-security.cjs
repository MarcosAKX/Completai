// Sondas locais da auditoria: nunca conecta ao projeto Firebase real.
const { createRequire } = require('node:module');
const { readFileSync } = require('node:fs');
const requireTests = createRequire(require('node:path').resolve('package.json'));
const { initializeTestEnvironment } = requireTests('@firebase/rules-unit-testing');
const { doc, setDoc, updateDoc, writeBatch, collection, getDocs, query, orderBy, limit, where, Timestamp } = requireTests('firebase/firestore');
(async () => {
  if (!/^(localhost|127\.0\.0\.1):\d+$/.test(process.env.FIRESTORE_EMULATOR_HOST || '')) throw Error('Local emulator required');
  const [host, port] = process.env.FIRESTORE_EMULATOR_HOST.split(':');
  const env = await initializeTestEnvironment({projectId:'demo-completai-audit',firestore:{host,port:Number(port),rules:readFileSync('../../firestore.rules','utf8')}});
  try {
    const db = env.authenticatedContext('audit-user').firestore();
    const batch = writeBatch(db);
    batch.set(doc(db,'users/audit-user'),{type:'client'});
    batch.set(doc(db,'gas_stations/audit-user'),{type:'gas_station'});
    await batch.commit();
    console.log('CONFIRMED: same batch creates both roles');
    await env.withSecurityRulesDisabled(async context => {
      await setDoc(doc(context.firestore(),'public_stations/audit-station'),{averageRating:4.8,reviewCount:10});
      for (let i=0;i<21;i++) await setDoc(doc(context.firestore(),`public_stations/audit-station/reviews/person-${i}`),{rating:5,clientUid:`person-${i}`,createdAt:Timestamp.fromMillis(1700000000000)});
    });
    await updateDoc(doc(db,'public_stations/audit-station'),{averageRating:0,reviewCount:0});
    console.log('CONFIRMED: authenticated user zeroes existing aggregates without writing review');
    await setDoc(doc(db,'public_stations/audit-station/reviews/audit-user'),{rating:5,clientUid:'different-user',clientName:'Different person'});
    console.log('CONFIRMED: review accepts mismatched author and missing createdAt');
    const reviews = collection(db,'public_stations/audit-station/reviews');
    const first = await getDocs(query(reviews,orderBy('createdAt','desc'),limit(21)));
    const second = await getDocs(query(reviews,orderBy('createdAt','desc'),where('createdAt','<',first.docs[19].get('createdAt')),limit(21)));
    console.log(`CONFIRMED: public review cursor: first raw=${first.size}, displayed=20, second=${second.size}; one tied-date review lost`);
  } finally {await env.cleanup();}
})().catch(error=>{console.error(error);process.exitCode=1;});
