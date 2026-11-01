"use client";
import type {ComponentProps} from 'react';
import {accountName} from '../lib/account.ts';
import type {AccountSession} from '../lib/use-account-session.ts';
import AccountPanel from './AccountPanel';
import AccountStatus from './AccountStatus';
import ProfileNameForm from './ProfileNameForm';
import NotebookPanel from './NotebookPanel';
type Props=Omit<ComponentProps<typeof NotebookPanel>,'user'|'onSessionLost'|'active'>&{visible:boolean;session:AccountSession;entry:{view:'login'|'register';sequence:number}};
export default function AccountNotebook({visible,session,entry,...props}:Props){
 const {language}=props,{user,status}=session,signedIn=status==='signed-in';
 return <><AccountStatus session={session} language={language}/>
  {!signedIn&&status!=='checking'&&<AccountPanel key={entry.sequence} initialView={entry.view} language={language} onSignedIn={session.signedIn}/>}
  {user&&<div hidden={!signedIn} key={user.id}><header className="account-summary"><div><strong>{accountName(user)|| (language==='tr'?'Hesabım':'My account')}</strong><small>{user.email}</small></div><button className="inline-term" disabled={session.busy} onClick={()=>void session.logout()}>{language==='tr'?'Çıkış yap':'Sign out'}</button></header>
   {(!user.firstName||!user.lastName)&&<ProfileNameForm user={user} language={language} onSaved={session.signedIn}/>}
   <NotebookPanel {...props} active={visible&&signedIn} user={user} onSessionLost={session.sessionLost}/>
  </div>}
 </>;
}
