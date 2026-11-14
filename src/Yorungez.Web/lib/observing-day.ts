import { Temporal } from '@js-temporal/polyfill';

export function observingDateRange(zone: string, now: Temporal.Instant = Temporal.Now.instant()) {
  const today = now.toZonedDateTimeISO(zone).toPlainDate();
  const supportedLast = Temporal.PlainDate.from('2035-12-30');
  const last = today.add({ days: 29 });
  return { today, last: Temporal.PlainDate.compare(last, supportedLast) > 0 ? supportedLast : last };
}

export function observingDay(date: Temporal.PlainDate, zone: string) {
  return {
    startUtc: date.toZonedDateTime(zone).toInstant().toString(),
    endUtc: date.add({ days: 1 }).toZonedDateTime(zone).toInstant().toString(),
  };
}
