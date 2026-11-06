const {onDocumentCreated, onDocumentUpdated} = require('firebase-functions/v2/firestore');
const {initializeApp} = require('firebase-admin/app');
const {FieldValue, getFirestore} = require('firebase-admin/firestore');

initializeApp();

const database = getFirestore();

function createNotification({id, recipientId, type, title, message, requestId}) {
  if (!recipientId) return null;
  return database.collection('notifications').doc(id).set({
    recipientId,
    type,
    title,
    message,
    requestId: requestId ?? null,
    isRead: false,
    createdAt: FieldValue.serverTimestamp(),
  });
}

function notificationForStatus(request) {
  switch (request.status) {
    case 'accepted':
      return {
        recipientId: request.clientId,
        type: 'requestAccepted',
        title: 'Demande acceptée',
        message: `${request.artisanName} a accepté votre demande de ${request.service}.`,
      };
    case 'inProgress':
      return {
        recipientId: request.clientId,
        type: 'interventionStarted',
        title: 'Intervention commencée',
        message: `${request.artisanName} a commencé l’intervention.`,
      };
    case 'completed':
      return {
        recipientId: request.clientId,
        type: 'interventionCompleted',
        title: 'Intervention terminée',
        message: 'Votre intervention est terminée. Vous pouvez maintenant donner votre avis.',
      };
    case 'refused':
      return {
        recipientId: request.clientId,
        type: 'requestRefused',
        title: 'Demande refusée',
        message: `${request.artisanName} ne peut pas intervenir pour cette demande.`,
      };
    case 'cancelled':
      return {
        recipientId: request.artisanId,
        type: 'requestCancelled',
        title: 'Demande annulée',
        message: `${request.clientName} a annulé la demande de ${request.service}.`,
      };
    default:
      return null;
  }
}

exports.notifyArtisanOfNewRequest = onDocumentCreated(
  'requests/{requestId}',
  async (event) => {
    const request = event.data?.data();
    if (!request) return;
    return createNotification({
      id: `request-created-${event.id}`,
      recipientId: request.artisanId,
      type: 'requestCreated',
      title: 'Nouvelle demande d’intervention',
      message: `${request.clientName} vous sollicite pour ${request.service}.`,
      requestId: event.params.requestId,
    });
  },
);

exports.notifyRequestStatusChange = onDocumentUpdated(
  'requests/{requestId}',
  async (event) => {
    const previous = event.data?.before.data();
    const request = event.data?.after.data();
    if (!previous || !request || previous.status === request.status) return;

    const notification = notificationForStatus(request);

    if (!notification) return;
    return createNotification({
      id: `request-status-${event.id}`,
      ...notification,
      requestId: event.params.requestId,
    });
  },
);

exports.notifyArtisanOfReview = onDocumentCreated(
  'reviews/{reviewId}',
  async (event) => {
    const review = event.data?.data();
    if (!review) return;
    return createNotification({
      id: `review-created-${event.id}`,
      recipientId: review.artisanId,
      type: 'reviewCreated',
      title: 'Nouvel avis client',
      message: 'Un client a laissé un avis après votre intervention.',
      requestId: review.requestId,
    });
  },
);
