"""Explicit, attributed CC Wikipedia extract and Commons photograph snapshot."""
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.parse import urlencode
from datetime import datetime, timezone
import json, re, hashlib
ROOT=Path(__file__).resolve().parents[2]
def get(url):
    with urlopen(Request(url,headers={"User-Agent":"Yorungez/0.2 (local astronomy reference preparation)"}),timeout=25) as r:return r.read()
def plain(s):return re.sub("<[^>]*>","",s or "").strip()
def main():
    import argparse
    p=argparse.ArgumentParser();p.add_argument("--refresh",action="store_true")
    if not p.parse_args().refresh:raise SystemExit("Use --refresh explicitly.")
    output={}
    for lang,title in [("tr","Güneş"),("en","Sun")]:
        query=dict(action="query",prop="extracts|pageimages|info|revisions",exintro=1,explaintext=1,exchars=900,piprop="name",inprop="url",rvprop="ids|timestamp",titles=title,redirects=1,format="json",formatversion=2)
        page=json.loads(get(f"https://{lang}.wikipedia.org/w/api.php?"+urlencode(query)))["query"]["pages"][0]
        result={"title":page["title"],"extract":page["extract"],"url":page["fullurl"],"revision":page["revisions"][0]["revid"],
            "fetchedAtUtc":datetime.now(timezone.utc).isoformat(),"license":"CC BY-SA 4.0","licenseUrl":"https://creativecommons.org/licenses/by-sa/4.0/","credit":"Wikipedia contributors","image":None}
        if page.get("pageimage"):
            q=dict(action="query",prop="imageinfo",iiprop="url|extmetadata",iiurlwidth=640,titles="File:"+page["pageimage"],format="json",formatversion=2)
            commons=json.loads(get("https://commons.wikimedia.org/w/api.php?"+urlencode(q)))["query"]["pages"][0]
            if commons.get("imageinfo"):
                info=commons["imageinfo"][0];meta=info.get("extmetadata",{});value=lambda key:plain(meta.get(key,{}).get("value",""))
                if value("LicenseUrl") and value("Artist"):
                    remote=info.get("thumburl",info["url"]);raw=get(remote)
                    photo=ROOT/f"src/Yorungez.Web/public/objects/sun-{lang}.jpg";photo.parent.mkdir(parents=True,exist_ok=True);photo.write_bytes(raw)
                    result["image"]={"url":f"/objects/sun-{lang}.jpg","sourceUrl":info["descriptionurl"],"originalUrl":remote,"credit":value("Artist"),"license":value("LicenseShortName"),"licenseUrl":value("LicenseUrl"),"sha256":hashlib.sha256(raw).hexdigest()}
        output[lang]=result
    path=ROOT/"data/catalog/sun-content.json";path.write_text(json.dumps(output,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({lang:{"revision":row["revision"],"hasLicensedPhoto":bool(row["image"])} for lang,row in output.items()}))
if __name__=="__main__":main()
