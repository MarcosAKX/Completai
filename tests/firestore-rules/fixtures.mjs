// Fixtures completas do schema; timestamps determinísticos sem dependências Flutter.
import { Timestamp } from 'firebase/firestore';

const createdAt = Timestamp.fromMillis(1700000000000);
export const client = (uid) => ({ uid, type: 'client', name: 'Cliente teste', email: `${uid}@example.test`, phone: '(17) 99999-9999', createdAt });
export const station = (uid) => ({ uid, type: 'gas_station', cnpj: '12345678000190', email: `${uid}@example.test`, phone: '(17) 3333-4444', brandName: 'Posto teste', createdAt, updatedAt: createdAt });
export const publicStation = (uid) => ({
  uid, brandName: 'Posto teste', address: 'Rua de teste, 100', neighborhood: 'Centro', city: 'Ribeirão Preto', state: 'SP',
  latitude: -20.949, longitude: -48.479,
  prices: { gasolineRegular: null, gasolineAdditive: null, ethanol: null, dieselS10: null, dieselS500: null },
  pricesUpdatedAt: createdAt,
  openingHours: { monday: null, tuesday: null, wednesday: null, thursday: null, friday: null, saturday: null, sunday: null },
  averageRating: 0, reviewCount: 0, services: [], tags: [],
});
export const review = (uid, rating = 5) => ({ clientUid: uid, clientName: 'Cliente teste', rating, comment: 'Atendimento bom', createdAt });
export const report = (uid) => ({ reporterUid: uid, reason: 'Dados incorretos', createdAt });
