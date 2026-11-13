const test = require('node:test');
const assert = require('node:assert/strict');
const {availabilitySlots, hasBookingCollision} = require('../availability');

test('découpe une plage selon la durée publiée', () => {
  const slots = availabilitySlots({
    defaultDurationMinutes: 60,
    availabilityRules: [{weekday: 1, startMinutes: 9 * 60, endMinutes: 11 * 60}],
  }, '2026-11-09');

  assert.equal(slots.length, 2);
  assert.equal(slots[0].start.toISOString(), '2026-11-09T08:00:00.000Z');
});

test('ne propose aucun créneau lors d’une absence', () => {
  const slots = availabilitySlots({
    availabilityExceptions: [{date: '2026-11-09', unavailable: true}],
  }, '2026-11-09');

  assert.deepEqual(slots, []);
});

test('détecte la collision avec une réservation active', () => {
  const candidate = {
    start: new Date('2026-11-09T08:00:00.000Z'),
    end: new Date('2026-11-09T09:00:00.000Z'),
  };
  const bookings = [{
    status: 'pending',
    booking: {
      start: {toDate: () => new Date('2026-11-09T08:30:00.000Z')},
      end: {toDate: () => new Date('2026-11-09T09:30:00.000Z')},
    },
  }];

  assert.equal(hasBookingCollision(bookings, candidate, new Set(['pending'])), true);
});
