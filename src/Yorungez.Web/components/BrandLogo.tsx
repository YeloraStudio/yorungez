import {brand} from '../lib/brand';

export default function BrandLogo({variant='dark',className=''}:{variant?:'dark'|'light';className?:string}){
 const asset=variant==='dark'?brand.wordmarkDark:brand.wordmarkLight;
 // Direct static URLs also work in the verified offline pack, without an image-proxy request.
 return <img className={`brand-logo ${className}`} src={asset.src} width={asset.width} height={asset.height} alt="yorungez" decoding="async"/>;
}
