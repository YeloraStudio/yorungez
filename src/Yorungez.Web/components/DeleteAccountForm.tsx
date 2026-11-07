'use client';

import {useState, type FormEvent} from 'react';
import {AccountError, accountRequest} from '../lib/account';
import type {Language} from '../lib/sky/types';
import BrandLogo from './BrandLogo';

const copy = {
  en: {
    title: 'Delete your Yorungez account',
    scope: 'This permanently deletes your account, notebook entries, saved locations, preferences and reminders from the active service. You will be signed out on all devices. Backup copies may remain until they expire.',
    email: 'Account email', password: 'Current password', confirm: 'I want to permanently delete this account and its data.',
    action: 'Delete account permanently', busy: 'Deleting…', done: 'Your Yorungez account and its data were deleted.',
    invalid: 'Check your email and password and try again. If the account is locked, wait before retrying.',
    limited: 'Too many attempts. Try again later.', failed: 'We could not confirm deletion. Try again or contact Yorungez support.',
    help: 'Need help accessing your account? Email Yorungez support.', back: 'Return to Yorungez',
  },
  tr: {
    title: 'Yorungez hesabını sil',
    scope: 'Hesabın, defter kayıtların, kayıtlı konumların, tercihlerin ve hatırlatıcıların etkin sistemden kalıcı olarak silinir. Tüm cihazlarda oturumun kapanır. Yedek kopyalar saklama süreleri dolana kadar kalabilir.',
    email: 'Hesap e-postası', password: 'Güncel parola', confirm: 'Bu hesabı ve verilerini kalıcı olarak silmek istiyorum.',
    action: 'Hesabı kalıcı olarak sil', busy: 'Siliniyor…', done: 'Yorungez hesabın ve hesabına bağlı veriler silindi.',
    invalid: 'E-postanı ve parolanı kontrol edip tekrar dene. Hesap kilitliyse yeniden denemeden önce bekle.',
    limited: 'Çok fazla deneme yapıldı. Daha sonra tekrar dene.', failed: 'Silme işlemi doğrulanamadı. Tekrar dene veya Yorungez desteğine ulaş.',
    help: 'Hesabına erişemiyor musun? Yorungez desteğine e-posta gönder.', back: 'Yorungez’a dön',
  },
};

export default function DeleteAccountForm({language}: {language: Language}) {
  const t = copy[language];
  const [busy, setBusy] = useState(false);
  const [done, setDone] = useState(false);
  const [error, setError] = useState('');

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (busy) return;
    const form = event.currentTarget;
    const data = new FormData(form);
    if (!data.has('confirm')) return;
    setBusy(true);
    setError('');
    try {
      await accountRequest('/api/account/delete-account', language, {
        email: String(data.get('email')).trim(),
        password: String(data.get('password')),
      });
      setDone(true);
    } catch (failure) {
      const status = failure instanceof AccountError ? failure.status : 0;
      setError(status === 400 || status === 401 ? t.invalid : status === 429 ? t.limited : t.failed);
    } finally {
      const password = form.elements.namedItem('password');
      if (password instanceof HTMLInputElement) password.value = '';
      setBusy(false);
    }
  }

  return <main className="account-page">
    <a className="account-wordmark" href={`/${language}`}><BrandLogo/></a>
    <h1>{t.title}</h1>
    {done ? <p role="status">{t.done}</p> : <>
      <p>{t.scope}</p>
      <form method="post" action="/api/account/delete-account" onSubmit={submit} aria-busy={busy}>
        <label>{t.email}<input name="email" type="email" autoComplete="username" maxLength={254} required disabled={busy}/></label>
        <label>{t.password}<input name="password" type="password" autoComplete="current-password" maxLength={128} required disabled={busy}/></label>
        <label className="account-confirmation"><input name="confirm" type="checkbox" required disabled={busy}/> {t.confirm}</label>
        <button className="primary-button" disabled={busy}>{busy ? t.busy : t.action}</button>
      </form>
      {error && <p role="alert">{error}</p>}
      <p><a href="mailto:info@yorungez.com">{t.help}</a></p>
    </>}
    <p><a href={`/${language}`}>{t.back}</a></p>
  </main>;
}
