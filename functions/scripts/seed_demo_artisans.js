const {applicationDefault, cert, initializeApp} = require('firebase-admin/app');
const {getAuth} = require('firebase-admin/auth');
const {getFirestore} = require('firebase-admin/firestore');

const password = process.env.DEMO_ARTISANS_PASSWORD;
if (!password) throw new Error('DEMO_ARTISANS_PASSWORD est requis.');

const schedules = {
  A: {duration: 60, rules: [[1, 480, 960], [2, 480, 960], [3, 480, 960], [4, 480, 960], [5, 480, 960]]},
  B: {duration: 90, rules: [[1, 540, 1080], [2, 540, 1080], [3, 540, 1080], [4, 540, 1080], [5, 540, 1080], [6, 540, 1080]]},
  C: {duration: 60, rules: [[1, 840, 1200], [2, 840, 1200], [3, 840, 1200], [4, 840, 1200], [5, 840, 1200], [6, 540, 780]]},
  D: {duration: 45, rules: [[2, 480, 840], [3, 480, 840], [4, 480, 840], [5, 480, 840], [6, 480, 840], [7, 480, 840]]},
  E: {duration: 120, rules: [[1, 600, 1140], [2, 600, 1140], [3, 600, 1140], [4, 600, 1140], [5, 600, 1140]]},
  F: {duration: 90, rules: [[3, 720, 1200], [4, 720, 1200], [5, 720, 1200], [6, 720, 1200], [7, 720, 1200]]},
};

const artisans = [
  ['demo-tunis-nabil', 'Nabil Ben Amor', 'nabil.benamor@quickfix-demo.tn', 'plumber', 'tunis', 45, 4.8, 42, true, 'A'],
  ['demo-tunis-sami', 'Sami Trabelsi', 'sami.trabelsi@quickfix-demo.tn', 'electrician', 'tunis', 50, 4.7, 36, true, 'B'],
  ['demo-tunis-youssef', 'Youssef Jaziri', 'youssef.jaziri@quickfix-demo.tn', 'air_conditioning_technician', 'tunis', 60, 4.9, 58, false, 'C'],
  ['demo-tunis-karim', 'Karim Mansouri', 'karim.mansouri@quickfix-demo.tn', 'locksmith', 'tunis', 55, 4.6, 27, true, 'D'],
  ['demo-tunis-fathi', 'Fathi Garbi', 'fathi.garbi@quickfix-demo.tn', 'painter', 'tunis', 40, 4.5, 19, true, 'E'],
  ['demo-tunis-hatem', 'Hatem Saidi', 'hatem.saidi@quickfix-demo.tn', 'carpenter', 'tunis', 55, 4.7, 31, false, 'F'],
  ['demo-sfax-mourad', 'Mourad Haddad', 'mourad.haddad@quickfix-demo.tn', 'appliance_repairer', 'sfax', 45, 4.6, 24, true, 'A'],
  ['demo-sfax-adel', 'Adel Kammoun', 'adel.kammoun@quickfix-demo.tn', 'plumber', 'sfax', 35, 4.4, 16, true, 'B'],
  ['demo-sfax-wassim', 'Wassim Chaabane', 'wassim.chaabane@quickfix-demo.tn', 'electrician', 'sfax', 45, 4.8, 39, false, 'C'],
  ['demo-sfax-walid', 'Walid Triki', 'walid.triki@quickfix-demo.tn', 'painter', 'sfax', 38, 4.3, 12, true, 'D'],
  ['demo-sfax-nader', 'Nader Ayadi', 'nader.ayadi@quickfix-demo.tn', 'locksmith', 'sfax', 50, 4.7, 22, true, 'E'],
  ['demo-sfax-fares', 'Fares Gharbi', 'fares.gharbi@quickfix-demo.tn', 'air_conditioning_technician', 'sfax', 55, 4.5, 18, false, 'F'],
  ['demo-sousse-sami', 'Sami Jellouli', 'sami.jellouli@quickfix-demo.tn', 'carpenter', 'sousse', 50, 4.8, 41, true, 'A'],
  ['demo-sousse-leith', 'Leith Ben Ali', 'leith.benali@quickfix-demo.tn', 'appliance_repairer', 'sousse', 48, 4.6, 26, true, 'B'],
  ['demo-sousse-mohamed', 'Mohamed Bouaziz', 'mohamed.bouaziz@quickfix-demo.tn', 'plumber', 'sousse', 40, 4.5, 17, false, 'C'],
  ['demo-sousse-hichem', 'Hichem Ghorbel', 'hichem.ghorbel@quickfix-demo.tn', 'electrician', 'sousse', 50, 4.9, 52, true, 'D'],
  ['demo-sousse-anis', 'Anis Hammami', 'anis.hammami@quickfix-demo.tn', 'painter', 'sousse', 42, 4.4, 14, true, 'E'],
  ['demo-sousse-nader', 'Nader Ferjani', 'nader.ferjani@quickfix-demo.tn', 'locksmith', 'sousse', 55, 4.7, 29, false, 'F'],
  ['demo-bizerte-khaled', 'Khaled Mrad', 'khaled.mrad@quickfix-demo.tn', 'air_conditioning_technician', 'bizerte', 55, 4.8, 34, true, 'A'],
  ['demo-bizerte-slim', 'Slim Ben Hmida', 'slim.benhmida@quickfix-demo.tn', 'carpenter', 'bizerte', 52, 4.6, 21, true, 'B'],
  ['demo-bizerte-aymen', 'Aymen Kefi', 'aymen.kefi@quickfix-demo.tn', 'appliance_repairer', 'bizerte', 45, 4.5, 15, false, 'C'],
  ['demo-bizerte-hassen', 'Hassen Mezghani', 'hassen.mezghani@quickfix-demo.tn', 'plumber', 'bizerte', 38, 4.7, 28, true, 'D'],
  ['demo-bizerte-riadh', 'Riadh Bouallegue', 'riadh.bouallegue@quickfix-demo.tn', 'electrician', 'bizerte', 48, 4.9, 47, true, 'E'],
  ['demo-bizerte-saber', 'Saber Turki', 'saber.turki@quickfix-demo.tn', 'painter', 'bizerte', 40, 4.3, 11, false, 'F'],
];

function initializeAdmin() {
  const serviceAccount = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  initializeApp({credential: serviceAccount ? cert(require(serviceAccount)) : applicationDefault()});
}

async function upsertAuth(auth, uid, name, email) {
  const data = {displayName: name, email, password, emailVerified: true, disabled: false};
  try {
    await auth.updateUser(uid, data);
  } catch (error) {
    if (error.code !== 'auth/user-not-found') throw error;
    await auth.createUser({uid, ...data});
  }
}

async function seed() {
  initializeAdmin();
  const auth = getAuth();
  const database = getFirestore();
  const writer = database.bulkWriter();
  for (const [uid, name, email, trade, area, startingPrice, rating, reviewCount, availableToday, scheduleKey] of artisans) {
    await upsertAuth(auth, uid, name, email);
    const schedule = schedules[scheduleKey];
    const availabilityRules = schedule.rules.map(([weekday, startMinutes, endMinutes]) => ({weekday, startMinutes, endMinutes}));
    writer.set(database.collection('users').doc(uid), {name, email, role: 'artisan'});
    writer.set(database.collection('artisans').doc(uid), {
      name, trade, area, rating, reviewCount, startingPrice, verified: true,
      verificationStatus: 'verified', availableToday, rejectionReason: null,
      availabilityRules, availabilityExceptions: [], defaultDurationMinutes: schedule.duration,
    });
  }
  await writer.close();
  console.log(JSON.stringify({seeded: artisans.length}));
}

seed().catch((error) => {
  console.error('Peuplement des artisans de démonstration impossible.', error);
  process.exitCode = 1;
});
