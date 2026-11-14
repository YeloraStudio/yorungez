"use client";

import { useEffect, useState, type CSSProperties } from 'react';
import { accountRequest } from '../lib/account.ts';
import { messages } from '../lib/i18n.ts';
import { Temporal } from '@js-temporal/polyfill';
import { observingDateRange, observingDay } from '../lib/observing-day.ts';
import { eventNames, moonPhases, weatherBodies, type ObservingSelection } from '../lib/observing-opportunities.ts';
import type { Language, ObserverContext } from '../lib/sky/types.ts';
import DateField from './ui/DateField';
import SelectField from './ui/SelectField';

type Opportunity = {
  id: string; target: string; startUtc: string; endUtc: string; bestUtc: string;
  azimuthDegrees: number | null; altitudeDegrees: number; cloudPercent: number | null;
  conditions: 'good' | 'uncertain' | 'poor' | 'unknown';
  light: 'daylight' | 'twilight' | 'night';
};
type Forecast = {
  weatherUpdatedUtc: string | null; weatherThroughUtc: string; weatherStatus: string; windows: Opportunity[];
  moonPhase?: { instantUtc: string; phase: string; illuminatedFraction: number };
};
type WeatherReminder = {
  id: string; revision: number; targetId: string; instantUtc: string; timeZoneId: string;
  leadMinutes: number; status: string; weatherDependent: boolean;
};

const copy = {
  en: {
    next: 'Best chances over the next 48 hours', windows: 'Local observing windows',
    example: 'Example location', waiting: 'Calculating observing windows…',
    failed: 'Could not load observing windows.', retry: 'Retry',
    later: 'Weather will be assessed when the event enters the 48-hour forecast.',
    unavailable: 'Weather is unavailable. Times shown use astronomy only.',
    empty: 'No suitable observing window was found for this location and time range.',
    updated: 'Forecast updated', good: 'Good opportunity', uncertain: 'Uncertain',
    weatherCredit: 'Visibility estimates use MET Norway cloud data.',
    localLimits: 'Regional cloud forecasts cannot account for clouds in your exact line of sight or local obstructions.',
    poor: 'Poor conditions', unknown: 'Weather unknown',
    daylight: 'Daylight', twilight: 'Twilight', night: 'Night',
    more: 'Show all opportunities', less: 'Show fewer', best: 'Suggested time',
    map: 'Show on map', save: 'Schedule email',
    consent: 'We keep an approximate copy of this location until the reminder ends. We email you 10 minutes before the suggested time if the forecast still looks favorable.',
    sent: 'Reminder scheduled.', saveError: 'Could not schedule the reminder. Check that you do not already have one for this window.',
    cloud: 'Area cloud cover', radiant: 'Shower radiant. Meteors can appear across the sky.',
    azimuth: 'Azimuth', altitude: 'Altitude', phase: 'Moon phase', archive: 'Andromeda · archive image',
    signIn: 'Sign in to set reminders',
    reminders: 'Manage observing reminders', cancel: 'Cancel reminder', cancelled: 'Reminder cancelled.',
    noReminders: 'No scheduled observing reminders.', reminderError: 'Could not update reminders. Try again.',
    directions: ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'],
  },
  tr: {
    next: 'Önümüzdeki 48 saatin en iyi fırsatları', windows: 'Yerel gözlem aralıkları',
    example: 'Örnek konum', waiting: 'Gözlem aralıkları hesaplanıyor…',
    failed: 'Gözlem aralıkları yüklenemedi.', retry: 'Yeniden dene',
    later: 'Olay 48 saatlik tahmin aralığına girdiğinde hava değerlendirilecek.',
    unavailable: 'Hava tahmini alınamadı. Gösterilen saatler astronomik hesaba dayanıyor.',
    empty: 'Bu konum ve tarih aralığında uygun gözlem saati bulunamadı.',
    updated: 'Tahmin güncellendi', good: 'İyi fırsat', uncertain: 'Belirsiz',
    weatherCredit: 'Görünürlük değerlendirmesinde MET Norway bulut verileri kullanılıyor.',
    localLimits: 'Bölgesel tahmin, tam baktığın yöndeki bulutları veya çevrendeki engelleri belirleyemez.',
    poor: 'Zayıf koşullar', unknown: 'Hava bilinmiyor',
    daylight: 'Gündüz', twilight: 'Alacakaranlık', night: 'Gece',
    more: 'Tüm fırsatları göster', less: 'Daha az göster', best: 'Önerilen saat',
    map: 'Haritada göster', save: 'E-postayı planla',
    consent: 'Hatırlatıcı kapanana kadar bu konumun yaklaşık bir kopyasını saklarız. Tahmin hâlâ elverişliyse önerilen saatten 10 dakika önce e-posta göndeririz.',
    sent: 'Hatırlatıcı kuruldu.', saveError: 'Hatırlatıcı kurulamadı. Aynı saat için daha önce hatırlatıcı kurup kurmadığını kontrol et.',
    cloud: 'Bölgesel bulutluluk', radiant: 'Yağmurun çıkış noktası. Meteorlar gökyüzünün farklı bölgelerinde görülebilir.',
    azimuth: 'Azimut', altitude: 'Yükseklik', phase: 'Ay evresi', archive: 'Andromeda · arşiv görseli',
    signIn: 'Hatırlatıcı için giriş yap',
    reminders: 'Gözlem hatırlatıcılarını yönet', cancel: 'Hatırlatıcıyı iptal et', cancelled: 'Hatırlatıcı iptal edildi.',
    noReminders: 'Planlanmış gözlem hatırlatıcısı yok.', reminderError: 'Hatırlatıcılar güncellenemedi. Yeniden dene.',
    directions: ['K', 'KD', 'D', 'GD', 'G', 'GB', 'B', 'KB'],
  },
};

type Props = {
  language: Language; site: ObserverContext; zone: string; selection: ObservingSelection;
  owner: string | null; onSignIn: () => void; onNavigate: (id: string, instant: string) => void;
  onDirection: (azimuth: number, altitude: number, instant: string) => void;
};

export default function ObservingOpportunities(props: Props) {
  return props.selection.monthly ? <MonthlyObservingPlan {...props} /> : <ObservingWindows {...props} />;
}

function MonthlyObservingPlan(props: Props) {
  const { language, zone } = props;
  const turkish = language === 'tr';
  const { today, last } = observingDateRange(zone);
  const [selected, setSelected] = useState(today.toString());
  const [target, setTarget] = useState(props.selection.target ?? 'moon');
  const date = Temporal.PlainDate.from(selected < today.toString() ? today.toString() : selected > last.toString() ? last.toString() : selected);
  const labels = messages[language].celestialNames as Record<string, string>;
  const selection = { ...observingDay(date, zone), target: target || undefined, monthly: true };
  const startLabel = new Intl.DateTimeFormat(language, { day: 'numeric', month: 'short', timeZone: 'UTC' });
  const range = startLabel.formatRange(new Date(today.toString() + 'T12:00:00Z'), new Date(last.toString() + 'T12:00:00Z'));
  return <div className="monthly-observing">
    <figure className="observing-hero">
      <div className="observing-hero-copy">
        <strong>{range}</strong>
        <p>{turkish
          ? 'Bir gün seçip konumuna göre gözlem saatlerini gör. Bulut tahmini son 48 saatte eklenir.'
          : 'Choose a day to see observing times for your location. Cloud forecasts appear in the final 48 hours.'}</p>
      </div>
      <figcaption>{copy[language].archive} · <a href="https://commons.wikimedia.org/wiki/File:M31-Andromede-16-09-2023-Hamois.jpg"
        target="_blank" rel="noreferrer">Lviatour</a> · <a href="https://creativecommons.org/licenses/by-sa/2.5/"
        target="_blank" rel="noreferrer">CC BY-SA 2.5</a></figcaption>
    </figure>
    <div className="observing-filters">
    <div className="observing-date-controls">
      <button type="button" className="secondary-button" aria-label={turkish ? 'Önceki gün' : 'Previous day'}
        disabled={date.equals(today)} onClick={() => setSelected(date.subtract({ days: 1 }).toString())}>‹</button>
      <DateField language={language} label={turkish ? 'Gözlem günü' : 'Observing date'} value={date.toString()}
        min={today.toString()} max={last.toString()} onChange={setSelected} />
      <button type="button" className="secondary-button" aria-label={turkish ? 'Sonraki gün' : 'Next day'}
        disabled={date.equals(last)} onClick={() => setSelected(date.add({ days: 1 }).toString())}>›</button>
    </div>
    <SelectField language={language} label={turkish ? 'Gök cismi veya olay' : 'Object or event'}
      value={target} onChange={setTarget} options={[
        { value: '', label: turkish ? 'Tüm fırsatlar' : 'All opportunities' },
        ...weatherBodies.map(value => ({ value, label: labels[value] ?? value })),
        { value: 'lunar-eclipse', label: turkish ? 'Ay tutulmaları' : 'Lunar eclipses' },
        ...['geminids', 'quadrantids', 'perseids'].map(value => ({ value, label: eventNames[language][value] })),
      ]} />
    </div>
    <ObservingWindows {...props} key={date.toString() + ':' + target} selection={selection} />
  </div>;
}

function ObservingWindows({ language, site, zone, selection, owner, onSignIn, onNavigate, onDirection }: Props) {
  const t = copy[language];
  const { latitude, longitude, elevationMeters } = site;
  const { target, startUtc, endUtc, nightOnly, monthly } = selection;
  const [attempt, setAttempt] = useState(0);
  const [forecast, setForecast] = useState<Forecast | null>(null);
  const [failed, setFailed] = useState(false);
  const [showAll, setShowAll] = useState(false);
  const [saving, setSaving] = useState(false);
  const [feedback, setFeedback] = useState('');
  const [activeReminders, setActiveReminders] = useState<WeatherReminder[] | null>(null);
  useEffect(() => {
    const controller = new AbortController();
    const load = async () => {
      try {
        const response = await fetch('/api/observing-opportunities', {
          method: 'POST', headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ latitude, longitude, elevationMeters, target, startUtc, endUtc,
            futureOnly: monthly, includeMoonPhase: monthly && (!target || target === 'moon') }),
          signal: controller.signal, cache: 'no-store',
        });
        if (!response.ok) throw new Error('forecast');
        const data = await response.json() as Forecast;
        if (!Array.isArray(data.windows)) throw new Error('forecast');
        if (!controller.signal.aborted) setForecast(data);
      } catch {
        if (!controller.signal.aborted) setFailed(true);
      }
    };
    void load();
    return () => controller.abort();
  }, [latitude, longitude, elevationMeters, target, startUtc, endUtc, monthly, attempt]);

  const local = new Intl.DateTimeFormat(language, {
    timeZone: zone, month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit', hourCycle: 'h23', timeZoneName: 'shortOffset',
  });
  const utc = new Intl.DateTimeFormat(language, { timeZone: 'UTC', hour: '2-digit', minute: '2-digit', hourCycle: 'h23' });
  const time = (value: string) => local.format(new Date(value));
  const percentage = new Intl.NumberFormat(language, { style: 'percent', maximumFractionDigits: 0 });
  const ranks = { good: 0, uncertain: 1, unknown: 2, poor: 3 };
  const windows = forecast?.windows.filter(w => !nightOnly || w.light !== 'daylight')
    .sort((a, b) => ranks[a.conditions] - ranks[b.conditions] || a.startUtc.localeCompare(b.startUtc)) ?? [];
  const numbers = new Intl.NumberFormat(language, { maximumFractionDigits: 0 });
  const name = (id: string) => eventNames[language][id] ??
    (messages[language].celestialNames as Record<string, string>)[id] ?? id;

  async function loadReminders() {
    const data = await accountRequest('/api/notebook/reminders', language, undefined, owner ?? undefined);
    if (data.userId !== owner || !Array.isArray(data.reminders)) throw new Error('reminders');
    setActiveReminders(data.reminders.filter((r: WeatherReminder) => r.weatherDependent &&
      (r.status === 'scheduled' || r.status === 'sending')));
  }

  async function manage(reminder?: WeatherReminder) {
    if (saving || !owner) return;
    setSaving(true);
    setFeedback('');
    try {
      if (reminder) {
        await accountRequest('/api/notebook/reminders', language, {
          id: reminder.id, expectedRevision: reminder.revision, timeZoneId: reminder.timeZoneId,
          leadMinutes: reminder.leadMinutes, cancelled: true,
        }, owner);
        setFeedback(t.cancelled);
        setActiveReminders(list => list?.filter(item => item.id !== reminder.id) ?? null);
      } else {
        await loadReminders();
      }
    } catch {
      setFeedback(t.reminderError);
    } finally {
      setSaving(false);
    }
  }

  async function schedule(window: Opportunity, instant: string) {
    if (saving || !owner) return;
    setSaving(true);
    setFeedback('');
    try {
      await accountRequest('/api/notebook/reminders', language, {
        id: crypto.randomUUID(), expectedRevision: 0, targetId: window.id, instantUtc: instant,
        timeZoneId: zone, leadMinutes: 10, weatherSite: { latitude, longitude, elevationMeters },
      }, owner);
      setFeedback(t.sent);
      setActiveReminders(null);
    } catch {
      setFeedback(t.saveError);
    } finally {
      setSaving(false);
    }
  }

  return <section className="observing-panel">
    <h3>{startUtc ? t.windows : t.next}</h3>
    <p className="muted compact">{zone}</p>
    {owner && <button type="button" className="inline-term" disabled={saving} onClick={() => void manage()}>{t.reminders}</button>}
    {owner && activeReminders && <ul>
      {activeReminders.length === 0 && <li>{t.noReminders}</li>}
      {activeReminders.map(r => <li key={r.id}>{name(r.targetId)} · {new Intl.DateTimeFormat(language, {
        timeZone: r.timeZoneId, dateStyle: 'medium', timeStyle: 'short',
      }).format(new Date(r.instantUtc))}{' '}
        <button type="button" className="inline-term" disabled={saving || r.status === 'sending'} onClick={() => void manage(r)}>{t.cancel}</button>
      </li>)}
    </ul>}
    {feedback && <p role="status">{feedback}</p>}
    {site.source === 'example' && <p className="muted">{t.example}</p>}
    {!forecast && !failed && <p role="status">{t.waiting}</p>}
    {failed && <p role="alert">{t.failed} <button className="inline-term" onClick={() => {
      setFailed(false); setAttempt(n => n + 1);
    }}>{t.retry}</button></p>}
    {forecast && <>
      {forecast.moonPhase && <div className="observing-moon-phase">
        <div className="observing-moon-dial" aria-hidden="true"
          style={{ '--illuminated': forecast.moonPhase.illuminatedFraction * 100 + '%' } as CSSProperties}>
          <span className="observing-moon-glyph" />
        </div>
        <div>
          <span className="observing-phase-label">{t.phase}</span>
          <strong>{moonPhases[language][forecast.moonPhase.phase]}</strong>
          <p>{language === 'tr' ? 'Aydınlık oranı' : 'Illuminated'} {percentage.format(forecast.moonPhase.illuminatedFraction)}</p>
          <time dateTime={forecast.moonPhase.instantUtc}>{time(forecast.moonPhase.instantUtc)}</time>
        </div>
      </div>}
      {forecast.weatherUpdatedUtc
        ? <p className="muted">
          {t.updated} {time(forecast.weatherUpdatedUtc)}<br />
          {t.weatherCredit} <a href="https://creativecommons.org/licenses/by/4.0/" target="_blank" rel="noreferrer">CC BY 4.0</a>
          <br />{t.localLimits}
        </p>
        : <p className="muted">{forecast.weatherStatus === 'outside_range' ? t.later : t.unavailable}</p>}
      {windows.length === 0 && <p>{t.empty}</p>}
      {(showAll ? windows : windows.slice(0, 6)).map(w => {
        const azimuth = w.azimuthDegrees;
        const now = Date.now();
        const best = Date.parse(w.bestUtc);
        const reminder = best > now + 12 * 60000 ? best : Date.parse(w.endUtc) - 5 * 60000;
        const forecastPending = reminder >= Date.parse(forecast.weatherThroughUtc);
        const inPlan = Temporal.Instant.fromEpochMilliseconds(reminder).toZonedDateTimeISO(zone).toPlainDate()
          .since(observingDateRange(zone).today).days < 30;
        const eligible = site.source !== 'example' && (w.conditions === 'good' || (forecastPending && w.conditions === 'unknown'))
          && inPlan && reminder > now + 12 * 60000 && reminder >= Date.parse(w.startUtc) && reminder < Date.parse(w.endUtc);
        const instant = new Date(reminder).toISOString();
        return <article className="forecast-card observing-result" data-conditions={w.conditions} key={w.id + w.startUtc}>
          <header className="observing-result-header">
            <h4>{name(w.id)}</h4>
            <div className="observing-status">
              <span className="observing-condition">{forecastPending && w.conditions === 'unknown'
                ? (language === 'tr' ? 'Hava tahmini bekleniyor' : 'Weather forecast pending')
                : t[w.conditions]}</span>
              <span className="observing-light" data-light={w.light}>{t[w.light]}</span>
            </div>
          </header>
          <p className="observing-time"><span>{t.best}</span><strong>{time(w.bestUtc)}</strong><small>{utc.format(new Date(w.bestUtc))} UTC</small></p>
          <p className="observing-window-range">{time(w.startUtc)} – {time(w.endUtc)}</p>
          <dl className="observing-metrics">
            {azimuth !== null && <div><dt>{t.azimuth}</dt><dd>{t.directions[Math.floor((azimuth + 22.5) / 45) % 8]} · {numbers.format(azimuth)}°</dd></div>}
            <div><dt>{t.altitude}</dt><dd>{numbers.format(w.altitudeDegrees)}°</dd></div>
            {w.cloudPercent !== null && <div><dt>{t.cloud}</dt><dd>{numbers.format(w.cloudPercent)}%</dd></div>}
          </dl>
          {w.target === 'radiant' && <p className="muted">{t.radiant}</p>}
          {(w.target !== 'radiant' || azimuth !== null) && <button type="button" className="secondary-button" onClick={() => {
            if (w.target === 'radiant' && azimuth !== null) onDirection(azimuth, w.altitudeDegrees, w.bestUtc);
            else onNavigate(w.target, w.bestUtc);
          }}>{t.map}</button>}
          {eligible && (owner
            ? <details><summary>{language === 'tr' ? 'Hava uygunsa haber ver' : 'Notify me if skies are clear'}</summary><p>{t.consent}</p>
              <button type="button" className="secondary-button" disabled={saving} onClick={() => void schedule(w, instant)}>{t.save}</button>
            </details>
            : <button type="button" className="inline-term" onClick={onSignIn}>{t.signIn}</button>)}
        </article>;
      })}
      {windows.length > 6 && <button type="button" className="secondary-button" onClick={() => setShowAll(!showAll)}>{showAll ? t.less : t.more}</button>}
    </>}
  </section>;
}
