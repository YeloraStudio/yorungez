# Documentation map

[Project overview (English)](../README.md) · [Türkçe](../README.tr.md)

Detailed product/delivery records are currently mostly Turkish. Newer decisions take precedence over historical package records. This index separates current scope, implementation evidence and pending acceptance.

## Product and delivery

- [Requirements / product vision](urun-gereksinimleri.md)
- [Roadmap](yol-haritasi.md) and [traceability](teslimat-izlenebilirligi.md)
- [Current local work order / deployment deferred by owner](yayin-oncesi-yerel-plan.md)
- [Decisions / open questions](kararlar.md)
- [Domain vocabulary](alan-sozlugu.md), [user tasks](kullanici-gorevleri.md), [UX flows](ux-akislari.md)
- [Historical project status](project-status-history.md)
- [Original requirements](arsiv/OpenSky_Proje_Gereksinimleri_UX_v1.md), preserved byte-for-byte

## Current implementation

- [Account spacing / live scientific calculations / current API inventory](canli-hesap-ve-veri-guncelligi.md)

- [Bilingual keyboard / account / date control audit, first package](iki-dil-klavye-denetimi.md)

- [Local PostgreSQL / key-ring recovery drill](yerel-yedek-geri-yukleme.md)

- [Brand integration / evidence](marka-logolari.md), [brand originals / exports / prompt](../data/branding/README.md)

- [Backend / identity](altyapi-ve-kimlik.md), [frontend setup](../src/Yorungez.Web/README.md)
- [Map / location / time](tam-ekran-harita-gelistirmesi.md), [natural rendering / compass](dogal-gorunum-ve-pusula.md)
- [Tonight / calendar / place names](gozlem-cizelgesi-ve-takvim.md)
- [Shared controls / sensor-free guidance](ortak-bilesenler-ve-sensorsuz-gozlem.md)
- [Accounts / server notebook](hesap-ve-sunucu-defteri.md)
- [Observations / saved places](gozlem-kayitlari-ve-kayitli-konumlar.md)
- [Account menu / public offline sky](hesap-menusu-ve-cevrimdisi-gokyuzu.md)
- [Email / default language](eposta-ve-varsayilan-dil.md), [localisation / terms](yerellestirme-ve-terimler.md)

## Scientific evidence and data

- [Scientific strategy](bilimsel-veri-stratejisi.md), [JPL comparison method](astronomi-denemesi.md)
- [Map / catalogue comparisons](harita-ve-katalog-denemesi.md)
- [Reference data / refresh instructions](../tests/ReferenceData/README.md)
- [Catalogue provenance](../data/catalog/README.md), [events](../data/events/README.md), [places](../data/places/README.md)
- [Physical GPS / compass acceptance protocol (pending)](cihaz-konum-pusula-dogrulamasi.md)

## Architecture decisions

- [0001: first technical foundation](adr/0001-teknik-temel-ve-ilk-dikey-akis.md)
- [0002: modular foundation, CQRS, licences](adr/0002-moduler-temel-cqrs-ve-lisanslar.md)
- [0004: initial map / bright catalogue](adr/0004-ilk-harita-ve-parlak-katalog.md)
- [0010: account-required server notebook](adr/0010-hesap-zorunlu-defter-ve-sunucu-kayitlari.md)
- [0011: observations / saved places](adr/0011-gozlem-kaydi-ve-kayitli-konumlar.md)
- [0012: account menu / names](adr/0012-hesap-menusu-ve-ad-soyad.md)
- [0013: public PWA package](adr/0013-genel-gokyuzu-pwa-ve-cevrimdisi-paket.md)
- [0014: Apache-2.0 / public publication](adr/0014-acik-kaynak-yayin-ve-apache-2.md)

- [Responsive / sensor / PWA acceptance preparation](responsive-cihaz-ve-pwa-kabulu.md) and [phone session card](telefon-kabul-oturumu.md)
- [0015: responsive / sensor / PWA acceptance](adr/0015-responsive-sensor-ve-pwa-kabulu.md)

## Publication

- [Publication review / limits](open-source-publication.md)
- [Contribution guide](../CONTRIBUTING.md), [security reporting](../SECURITY.md)
- [Code licence](../LICENSE), [NOTICE](../NOTICE), [third-party licences](../THIRD_PARTY_NOTICES.md)
