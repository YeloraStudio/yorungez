import {notFound} from 'next/navigation';
import AccountLinkAction from '../../../../components/AccountLinkAction';
import DeleteAccountForm from '../../../../components/DeleteAccountForm';
export const metadata={robots:{index:false,follow:false},referrer:'no-referrer' as const};
export default async function Page({params}:{params:Promise<{lang:string;action:string}>}){
 const {lang,action}=await params;if(lang!=='tr'&&lang!=='en')notFound();
 if(action==='delete-account')return <DeleteAccountForm language={lang}/>;
 if(action!=='confirm-email'&&action!=='reset-password')notFound();
 return <AccountLinkAction language={lang} action={action}/>;
}
