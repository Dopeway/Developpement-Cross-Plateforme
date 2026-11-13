const defaultDurationMinutes = 60;

function tunisDateKey(date) {
  const local = new Date(date.getTime() + 60 * 60 * 1000);
  return `${local.getUTCFullYear()}-${String(local.getUTCMonth() + 1).padStart(2, '0')}-${String(local.getUTCDate()).padStart(2, '0')}`;
}

function isDateKey(value) {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
  const date = new Date(`${value}T12:00:00+01:00`);
  return !Number.isNaN(date.valueOf()) && tunisDateKey(date) === value;
}

function availabilitySlots(profile, day) {
  if (!isDateKey(day)) return [];
  const noon = new Date(`${day}T12:00:00+01:00`);
  const weekday = noon.getUTCDay() || 7;
  const duration = Number.isInteger(profile.defaultDurationMinutes) && profile.defaultDurationMinutes >= 15 && profile.defaultDurationMinutes <= 240 ? profile.defaultDurationMinutes : defaultDurationMinutes;
  const rules = Array.isArray(profile.availabilityRules) ? profile.availabilityRules : [{weekday, startMinutes: 540, endMinutes: 1020}];
  const exceptions = Array.isArray(profile.availabilityExceptions) ? profile.availabilityExceptions : [];
  if (exceptions.some((item) => item?.date === day && item.unavailable === true)) return [];

  const slots = [];
  for (const rule of rules) {
    if (!rule || rule.weekday !== weekday || !Number.isInteger(rule.startMinutes) || !Number.isInteger(rule.endMinutes) || rule.startMinutes < 0 || rule.endMinutes > 1440 || rule.startMinutes >= rule.endMinutes) continue;
    for (let minute = rule.startMinutes; minute + duration <= rule.endMinutes; minute += duration) {
      const hour = String(Math.floor(minute / 60)).padStart(2, '0');
      const minutes = String(minute % 60).padStart(2, '0');
      const start = new Date(`${day}T${hour}:${minutes}:00+01:00`);
      slots.push({start, end: new Date(start.getTime() + duration * 60000)});
    }
  }
  return slots;
}

function hasBookingCollision(bookings, candidate, activeStatuses) {
  return bookings.some((booking) => {
    const slot = booking.booking;
    return activeStatuses.has(booking.status) && slot?.start?.toDate() < candidate.end && slot?.end?.toDate() > candidate.start;
  });
}

module.exports = {availabilitySlots, hasBookingCollision, isDateKey, tunisDateKey};
