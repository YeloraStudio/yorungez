import {notFound} from 'next/navigation';
import AccountLinkAction from '../../../../components/AccountLinkAction';
export default async function Page({params}:{params:Promise<{lang:string;action:string}>}){
 const {lang,action}=await params;if((lang!=='tr'&&lang!=='en')||(action!=='confirm-email'&&action!=='reset-password'))notFound();
 return <AccountLinkAction language={lang} action={action}/>;
}
