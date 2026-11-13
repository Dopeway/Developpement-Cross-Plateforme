const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {onSchedule} = require('firebase-functions/v2/scheduler');
const {onDocumentCreated, onDocumentUpdated} = require('firebase-functions/v2/firestore');
const {initializeApp} = require('firebase-admin/app');
const {FieldValue, Timestamp, getFirestore} = require('firebase-admin/firestore');
const {availabilitySlots, hasBookingCollision, isDateKey, tunisDateKey} = require('./availability');

initializeApp();
const database = getFirestore();
const activeStatuses = new Set(['pending', 'accepted', 'awaitingQuote', 'quoteAccepted', 'inProgress', 'rescheduleRequested']);

function requireUser(request) {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Connexion requise.');
  return request.auth.uid;
}
function notificationForStatus(request) {
  const messages = {
    awaitingQuote: ['quoteSent', 'Devis à valider', `${request.artisanName} a envoyé un devis pour votre demande.`],
    accepted: ['requestAccepted', 'Intervention confirmée', `${request.clientName} a accepté le devis.`],
    quoteRefused: ['quoteRefused', 'Devis refusé', `${request.clientName} a refusé le devis.`],
    refused: ['requestRefused', 'Demande refusée', `${request.artisanName} ne peut pas intervenir pour cette demande.`],
    expired: ['requestExpired', 'Créneau libéré', 'L’artisan n’a pas répondu à temps. Choisissez une autre disponibilité.'],
    cancelled: ['requestCancelled', 'Demande annulée', `${request.clientName} a annulé la demande.`],
  };
  const item = messages[request.status];
  if (!item) return null;
  return {recipientId: request.status === 'cancelled' ? request.artisanId : request.clientId, type: item[0], title: item[1], message: item[2]};
}
function createNotification({id, recipientId, type, title, message, requestId}) {
  return database.collection('notifications').doc(id).set({recipientId, type, title, message, requestId: requestId ?? null, isRead: false, createdAt: FieldValue.serverTimestamp()});
}

function matchesAvailability(profile, start, end) {
  return availabilitySlots(profile, tunisDateKey(start)).some((slot) => slot.start.getTime() === start.getTime() && slot.end.getTime() === end.getTime());
}

exports.reserveBooking = onCall({cors: true}, async (request) => {
  const clientId = requireUser(request);
  const {artisanId, addressId, description, start, end} = request.data ?? {};
  const bookingStart = new Date(start);
  const bookingEnd = new Date(end);
  if (typeof artisanId !== 'string' || typeof addressId !== 'string' || typeof description !== 'string' || description.trim().length < 10 || Number.isNaN(bookingStart.valueOf()) || Number.isNaN(bookingEnd.valueOf()) || bookingEnd <= bookingStart) throw new HttpsError('invalid-argument', 'Les données de réservation sont invalides.');
  if (bookingStart <= new Date() || bookingEnd - bookingStart > 4 * 60 * 60 * 1000) throw new HttpsError('invalid-argument', 'Ce créneau ne peut pas être réservé.');
  const [client, address] = await Promise.all([
    database.collection('users').doc(clientId).get(), database.collection('users').doc(clientId).collection('addresses').doc(addressId).get(),
  ]);
  if (client.data()?.role !== 'client') throw new HttpsError('permission-denied', 'Seul un client peut réserver.');
  if (!address.exists) throw new HttpsError('not-found', 'Adresse introuvable.');
  const requestRef = database.collection('requests').doc();
  await database.runTransaction(async (transaction) => {
    const artisan = await transaction.get(database.collection('artisans').doc(artisanId));
    if (!artisan.exists || artisan.data().verified !== true) throw new HttpsError('failed-precondition', 'Cet artisan n’est pas disponible.');
    const profile = artisan.data();
    if (!matchesAvailability(profile, bookingStart, bookingEnd)) throw new HttpsError('failed-precondition', 'Ce créneau ne fait plus partie des disponibilités de l’artisan.');
    const existing = await transaction.get(database.collection('requests').where('artisanId', '==', artisanId));
    const collision = hasBookingCollision(existing.docs.map((doc) => doc.data()), {start: bookingStart, end: bookingEnd}, activeStatuses);
    if (collision) throw new HttpsError('already-exists', 'Ce créneau vient d’être réservé.');
    const savedAddress = address.data(); const expiresAt = new Date(Date.now() + 60 * 60 * 1000);
    transaction.set(requestRef, {service: profile.trade, artisanId, artisanName: profile.name, clientId, clientName: client.data().name, description: description.trim(), address: profile.area, addressId, addressLabel: savedAddress.label ?? 'Adresse', date: bookingStart.toISOString(), booking: {start: Timestamp.fromDate(bookingStart), end: Timestamp.fromDate(bookingEnd), timeZone: 'Africa/Tunis', expiresAt: Timestamp.fromDate(expiresAt)}, status: 'pending', createdAt: FieldValue.serverTimestamp()});
    transaction.set(requestRef.collection('private').doc('address'), {fullAddress: savedAddress.fullAddress ?? savedAddress.value, createdAt: FieldValue.serverTimestamp()});
  });
  return {requestId: requestRef.id};
});

exports.availableSlots = onCall({cors: true}, async (request) => {
  requireUser(request);
  const {artisanId, day} = request.data ?? {};
  if (typeof artisanId !== 'string' || !isDateKey(day)) throw new HttpsError('invalid-argument', 'Recherche de créneaux invalide.');
  const artisan = await database.collection('artisans').doc(artisanId).get();
  if (!artisan.exists || artisan.data().verified !== true) return {slots: []};
  const profile = artisan.data();
  const requests = await database.collection('requests').where('artisanId', '==', artisanId).get();
  const slots = [];
  for (const slot of availabilitySlots(profile, day)) {
    if (slot.start <= new Date()) continue;
    const busy = hasBookingCollision(requests.docs.map((doc) => doc.data()), slot, activeStatuses);
    if (!busy) slots.push({start: slot.start.toISOString(), end: slot.end.toISOString(), timeZone: 'Africa/Tunis'});
  }
  return {slots};
});

exports.availableBookingDays = onCall({cors: true}, async (request) => {
  requireUser(request);
  const {artisanId, startDay, days} = request.data ?? {};
  if (typeof artisanId !== 'string' || !isDateKey(startDay) || !Number.isInteger(days) || days < 1 || days > 60) throw new HttpsError('invalid-argument', 'Recherche de disponibilités invalide.');
  const artisan = await database.collection('artisans').doc(artisanId).get();
  if (!artisan.exists || artisan.data().verified !== true) return {days: []};
  const profile = artisan.data();
  const requests = await database.collection('requests').where('artisanId', '==', artisanId).get();
  const availableDays = [];
  const firstDay = new Date(`${startDay}T12:00:00+01:00`);
  for (let offset = 0; offset < days; offset++) {
    const day = tunisDateKey(new Date(firstDay.getTime() + offset * 24 * 60 * 60 * 1000));
    const hasFreeSlot = availabilitySlots(profile, day).some((slot) => slot.start > new Date() && !hasBookingCollision(requests.docs.map((doc) => doc.data()), slot, activeStatuses));
    if (hasFreeSlot) availableDays.push(day);
  }
  return {days: availableDays};
});

exports.changeRequestStatus = onCall({cors: true}, async (request) => {
  const userId = requireUser(request); const {requestId, status, refusalReason, quoteAmount} = request.data ?? {};
  if (typeof requestId !== 'string' || typeof status !== 'string') throw new HttpsError('invalid-argument', 'Mise à jour invalide.');
  const ref = database.collection('requests').doc(requestId);
  await database.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref); if (!snapshot.exists) throw new HttpsError('not-found', 'Demande introuvable.');
    const data = snapshot.data(); const artisan = data.artisanId === userId; const client = data.clientId === userId;
    const allowed = (artisan && ((data.status === 'pending' && ['awaitingQuote', 'refused'].includes(status)) || (['accepted', 'quoteAccepted'].includes(data.status) && status === 'inProgress') || (data.status === 'inProgress' && status === 'completed'))) || (client && ((data.status === 'pending' && status === 'cancelled') || (data.status === 'awaitingQuote' && ['accepted', 'quoteRefused'].includes(status))));
    if (!allowed) throw new HttpsError('permission-denied', 'Transition non autorisée.');
    const update = {status};
    if (status === 'refused' && typeof refusalReason === 'string') update.refusalReason = refusalReason.trim().slice(0, 280);
    if (status === 'awaitingQuote' && Number.isInteger(quoteAmount) && quoteAmount >= 0) update.quoteAmount = quoteAmount;
    if (status === 'awaitingQuote' && update.quoteAmount === undefined) throw new HttpsError('invalid-argument', 'Un devis est requis.');
    transaction.update(ref, update);
  });
  return {ok: true};
});

exports.expirePendingBookings = onSchedule('every 15 minutes', async () => {
  const now = Timestamp.now(); const pending = await database.collection('requests').where('status', '==', 'pending').get();
  const batch = database.batch();
  pending.docs.forEach((doc) => { if (doc.data().booking?.expiresAt?.toMillis() <= now.toMillis()) batch.update(doc.ref, {status: 'expired'}); });
  await batch.commit();
});

exports.notifyArtisanOfNewRequest = onDocumentCreated('requests/{requestId}', async (event) => { const data = event.data?.data(); if (data) return createNotification({id: `request-created-${event.id}`, recipientId: data.artisanId, type: 'requestCreated', title: 'Créneau à confirmer', message: `${data.clientName} a réservé un créneau pour ${data.service}.`, requestId: event.params.requestId}); });
exports.notifyRequestStatusChange = onDocumentUpdated('requests/{requestId}', async (event) => { const before = event.data?.before.data(); const after = event.data?.after.data(); if (!before || !after || before.status === after.status) return; const notification = notificationForStatus(after); if (notification) return createNotification({id: `request-status-${event.id}`, ...notification, requestId: event.params.requestId}); });
exports.aggregateReview = onDocumentCreated('reviews/{reviewId}', async (event) => { const review = event.data?.data(); if (!review) return; const reviews = await database.collection('reviews').where('artisanId', '==', review.artisanId).get(); const total = reviews.docs.reduce((sum, doc) => sum + doc.data().rating, 0); return database.collection('artisans').doc(review.artisanId).update({rating: total / reviews.size, reviewCount: reviews.size}); });
exports.notifyArtisanOfReview = onDocumentCreated('reviews/{reviewId}', async (event) => { const review = event.data?.data(); if (review) return createNotification({id: `review-created-${event.id}`, recipientId: review.artisanId, type: 'reviewCreated', title: 'Nouvel avis client', message: 'Un client a laissé un avis après votre intervention.', requestId: review.requestId}); });
exports.notifyParticipantOfChatMessage = onDocumentCreated('requests/{requestId}/messages/{messageId}', async (event) => { const message = event.data?.data(); const request = await database.collection('requests').doc(event.params.requestId).get(); const data = request.data(); if (!message || !data) return; return createNotification({id: `chat-message-${event.id}`, recipientId: message.senderId === data.clientId ? data.artisanId : data.clientId, type: 'chatMessage', title: 'Nouveau message', message: `${message.senderName} vous a envoyé un message concernant ${data.service}.`, requestId: event.params.requestId}); });
