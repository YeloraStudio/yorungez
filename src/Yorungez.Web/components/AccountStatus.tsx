"use client";
import type {AccountSession} from '../lib/use-account-session.ts';
import type {Language} from '../lib/sky/types.ts';
export default function AccountStatus({session,language}:{session:AccountSession;language:Language}){
 const tr=language==='tr';
 if(session.status==='checking')return <p className="muted compact" role="status">{tr?'Oturum kontrol ediliyor…':'Checking session…'}</p>;
 if(session.status!=='unavailable'&&session.status!=='offline')return null;
 return <p className="form-error compact" role="alert">{session.status==='offline'?(tr?'Çevrimdışısın. Hesap ve kişisel kayıtlar için bağlantı gerekir.':'You are offline. Accounts and personal records need a connection.'):(tr?'Hesap servisine şu anda ulaşılamıyor. Lütfen biraz sonra tekrar dene.':'The account service is temporarily unavailable. Please try again shortly.')} <button type="button" className="inline-term" onClick={()=>void session.check()}>{tr?'Yeniden dene':'Retry'}</button></p>;
}
