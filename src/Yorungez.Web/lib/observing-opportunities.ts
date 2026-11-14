export const weatherBodies = ['moon', 'mercury', 'venus', 'mars', 'jupiter', 'saturn'];
export type ObservingSelection = { target?: string; startUtc?: string; endUtc?: string; nightOnly?: boolean; monthly?: boolean };
export const monthlyObservingTitle = { en: '30-day observing plan', tr: '30 günlük gözlem planı' };
export const moonPhases: Record<'en' | 'tr', Record<string, string>> = {
  en: { 'new-moon': 'New Moon', 'waxing-crescent': 'Waxing crescent', 'first-quarter': 'First quarter',
    'waxing-gibbous': 'Waxing gibbous', 'full-moon': 'Full Moon', 'waning-gibbous': 'Waning gibbous',
    'last-quarter': 'Last quarter', 'waning-crescent': 'Waning crescent' },
  tr: { 'new-moon': 'Yeni ay', 'waxing-crescent': 'Büyüyen hilal', 'first-quarter': 'İlk dördün',
    'waxing-gibbous': 'Büyüyen şişkin ay', 'full-moon': 'Dolunay', 'waning-gibbous': 'Küçülen şişkin ay',
    'last-quarter': 'Son dördün', 'waning-crescent': 'Küçülen hilal' },
};
export const observingTitle = { en: 'Where should I look?', tr: 'Nereye bakmalıyım?' };
export const eventNames: Record<'en' | 'tr', Record<string, string>> = {
  en: {
    'penumbral-lunar': 'Penumbral lunar eclipse', 'partial-lunar': 'Partial phase of the lunar eclipse',
    'total-lunar': 'Total phase of the lunar eclipse', geminids: 'Geminids meteor shower',
    quadrantids: 'Quadrantids meteor shower', perseids: 'Perseids meteor shower',
  },
  tr: {
    'penumbral-lunar': 'Yarı gölgeli Ay tutulması', 'partial-lunar': 'Ay tutulmasının parçalı evresi',
    'total-lunar': 'Ay tutulmasının tam evresi', geminids: 'İkizler meteor yağmuru',
    quadrantids: 'Dörtlük meteor yağmuru', perseids: 'Perseid meteor yağmuru',
  },
};

export function observingAround(target: string, instant: string, hours = 12): ObservingSelection {
  const time = Date.parse(instant);
  const padding = hours * 60 * 60 * 1000;
  return {
    target,
    startUtc: new Date(Math.max(time - padding, Date.UTC(2000, 0, 1))).toISOString(),
    endUtc: new Date(Math.min(time + padding, Date.UTC(2036, 0, 1) - 1)).toISOString(),
  };
}
