const {applicationDefault, cert, initializeApp} = require('firebase-admin/app');
const {getFirestore} = require('firebase-admin/firestore');

const tradeByLegacyValue = new Map([
  ['plomberie', 'plumber'],
  ['plombier', 'plumber'],
  ['électricité', 'electrician'],
  ['electricite', 'electrician'],
  ['électricien', 'electrician'],
  ['electricien', 'electrician'],
]);
const areaByLegacyValue = new Map([
  ['tunis', 'tunis'],
  ['ariana', 'ariana'],
  ['ben arous', 'ben_arous'],
  ['manouba', 'manouba'],
  ['sfax', 'sfax'],
  ['sousse', 'sousse'],
  ['bizerte', 'bizerte'],
]);
const supportedTrades = new Set([
  'plumber', 'electrician', 'air_conditioning_technician',
  'appliance_repairer', 'locksmith', 'painter', 'carpenter',
]);
const supportedAreas = new Set([
  'tunis', 'ariana', 'ben_arous', 'manouba', 'sfax', 'sousse', 'bizerte',
]);

function normalized(value) {
  return typeof value === 'string' ? value.trim().toLowerCase() : '';
}

function catalogValue(value, legacyValues, supportedValues) {
  const normalizedValue = normalized(value);
  if (supportedValues.has(normalizedValue)) return normalizedValue;
  return legacyValues.get(normalizedValue);
}

function initializeAdmin() {
  const serviceAccount = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  initializeApp({
    credential: serviceAccount ? cert(require(serviceAccount)) : applicationDefault(),
  });
}

async function migrate() {
  initializeAdmin();
  const database = getFirestore();
  const snapshot = await database.collection('artisans').get();
  const writer = database.bulkWriter();
  const skipped = [];
  let updated = 0;

  for (const document of snapshot.docs) {
    const data = document.data();
    const trade = catalogValue(data.trade, tradeByLegacyValue, supportedTrades);
    const area = catalogValue(data.area, areaByLegacyValue, supportedAreas);
    if (!trade || !area) {
      skipped.push(document.id);
      continue;
    }
    if (data.trade !== trade || data.area !== area) {
      writer.update(document.ref, {trade, area});
      updated += 1;
    }
  }

  await writer.close();
  console.log(JSON.stringify({updated, skipped}));
  if (skipped.length > 0) process.exitCode = 1;
}

migrate().catch((error) => {
  console.error('Migration du catalogue artisan impossible.', error);
  process.exitCode = 1;
});
