export function objectSearchKey(value:string){
 const folded=value.normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase().replace(/ı/g,'i').trim().replace(/\s+/g,' ');
 const identifier=/^(hip|hyg|ngc|messier|m)[\s-]*(\d+)$/.exec(folded);
 return identifier?(identifier[1]==='messier'?'m':identifier[1])+Number(identifier[2]):folded;
}
export function objectSearchEntry<T>(object:T,labels:string[]){const names=labels.map(objectSearchKey).filter(Boolean);return {object,names,key:names.join('\n')}}
export function findObjects<T>(rows:ReturnType<typeof objectSearchEntry<T>>[],query:string,limit=12):T[]{
 const key=objectSearchKey(query);if(!key)return [];
 return rows.filter(row=>row.key.includes(key)).map(row=>({...row,rank:row.names.includes(key)?0:row.names.some(name=>name.startsWith(key))?1:2})).sort((a,b)=>a.rank-b.rank).slice(0,limit).map(row=>row.object);
}
