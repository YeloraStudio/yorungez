"""Generate the editable SVG wireframes and matching PNG previews.

Optional documentation tooling; requires Pillow and Segoe UI on Windows.
Run: python docs/ux/wireframes/render_wireframes.py
The diagrams contain schematic placement, no ephemerides or real location data.
"""
from pathlib import Path
from html import escape
import json
from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).resolve().parent
REGULAR = Path(r'C:\Windows\Fonts\segoeui.ttf')
BOLD = Path(r'C:\Windows\Fonts\segoeuib.ttf')
INK, GRAY, LINE, LIGHT, WHITE = '#20252b', '#59616a', '#b5bbc2', '#f1f3f5', '#ffffff'


class Diagram:
    def __init__(self, width, height, title, description):
        self.width, self.height = width, height
        self.image = Image.new('RGB', (width, height), WHITE)
        self.draw = ImageDraw.Draw(self.image)
        self.svg = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}" role="img" aria-labelledby="title desc">',
                    f'<title id="title">{escape(title)}</title><desc id="desc">{escape(description)}</desc>',
                    f'<rect width="{width}" height="{height}" fill="{WHITE}"/>']
        self.fonts = {}

    def font(self, size, bold=False):
        key = size, bold
        if key not in self.fonts:
            self.fonts[key] = ImageFont.truetype(str(BOLD if bold else REGULAR), size)
        return self.fonts[key]

    def rect(self, x, y, width, height, fill=WHITE, stroke=LINE, radius=8):
        assert x >= 0 and y >= 0 and x + width <= self.width and y + height <= self.height
        self.draw.rounded_rectangle((x, y, x+width, y+height), radius=radius, fill=fill, outline=stroke, width=1)
        self.svg.append(f'<rect x="{x}" y="{y}" width="{width}" height="{height}" rx="{radius}" fill="{fill}" stroke="{stroke}"/>')

    def line(self, x1, y1, x2, y2, color=LINE, width=1):
        self.draw.line((x1, y1, x2, y2), fill=color, width=width)
        self.svg.append(f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{color}" stroke-width="{width}"/>')

    def text(self, x, y, value, size=17, bold=False, fill=INK, max_width=None):
        font = self.font(size, bold)
        words = value.split()
        lines = ['']
        for word in words:
            candidate = (lines[-1] + ' ' + word).strip()
            if max_width and font.getlength(candidate) > max_width and lines[-1]:
                lines.append(word)
            else:
                lines[-1] = candidate
        for offset, line in enumerate(lines):
            top = y + offset * (size + 8)
            assert x + font.getlength(line) < self.width - 4, f'Text outside diagram: {line}'
            assert top + size + 5 < self.height, f'Text below diagram: {line}'
            self.draw.text((x, top), line, font=font, fill=fill, anchor='lt')
            weight = 600 if bold else 400
            self.svg.append(f'<text x="{x}" y="{top}" font-family="Segoe UI, Arial, sans-serif" font-size="{size}" font-weight="{weight}" fill="{fill}" dominant-baseline="hanging">{escape(line)}</text>')

    def button(self, x, y, width, label, active=False, height=42, size=16):
        self.rect(x, y, width, height, INK if active else WHITE, INK if active else LINE, 6)
        font = self.font(size)
        left = x + (width - font.getlength(label)) / 2
        self.text(left, y + (height-size)/2 - 1, label, size, fill=WHITE if active else INK)

    def dot(self, x, y, radius=3, selected=False):
        self.draw.ellipse((x-radius, y-radius, x+radius, y+radius), fill=INK)
        self.svg.append(f'<circle cx="{x}" cy="{y}" r="{radius}" fill="{INK}"/>')
        if selected:
            self.draw.ellipse((x-14, y-14, x+14, y+14), outline=INK, width=2)
            self.svg.append(f'<circle cx="{x}" cy="{y}" r="14" fill="none" stroke="{INK}" stroke-width="2"/>')

    def field(self, x, y, width, label, value, invalid=False):
        self.text(x, y, label, 16, bold=True)
        self.rect(x, y+29, width, 47, WHITE, INK if invalid else LINE, 5)
        self.text(x+14, y+42, value, 17, fill=INK if invalid else GRAY)

    def sky(self, x, y, width, height):
        self.rect(x, y, width, height, WHITE, LINE, 4)
        self.text(x+18, y+17, 'Şematik harita · örnek yerleşim', 15, fill=GRAY)
        points = [(0.13,0.32),(0.22,0.24),(0.33,0.39),(0.46,0.21),(0.63,0.34),(0.75,0.18),(0.84,0.43)]
        for a,b in points:
            self.dot(round(x+a*width), round(y+b*height), 3)
        self.line(round(x+0.13*width),round(y+0.32*height),round(x+0.22*width),round(y+0.24*height))
        self.line(round(x+0.22*width),round(y+0.24*height),round(x+0.33*width),round(y+0.39*height))
        selected_x, selected_y = round(x+0.54*width), round(y+0.47*height)
        self.dot(selected_x, selected_y, 5, selected=True)
        self.text(selected_x+21, selected_y-8, 'Jüpiter', 17, bold=True)
        horizon = y+round(height*0.77)
        self.line(x+20,horizon,x+width-20,horizon,GRAY)
        self.text(x+21,horizon+12,'Ufuk',15,fill=GRAY)
        self.text(x+round(width/2)-25,horizon+12,'Güney',15,fill=GRAY)

    def save(self, name):
        svg = '\n'.join(self.svg + ['</svg>']) + '\n'
        (OUT / f'{name}.svg').write_text(svg, encoding='utf-8')
        self.image.save(OUT / f'{name}.png')
        return {'name':name,'size':[self.width,self.height],'png':str(OUT/f'{name}.png')}


def desktop():
    d = Diagram(1280, 820, 'yorungez masaüstü wireframe', 'Düşük ayrıntılı yerleşim: üstte dört bölüm, ortada baskın şematik harita, sağda nesne kartı; simülasyon ve örnek konum açık. Astronomik hesap içermez.')
    d.text(24,19,'yorungez',25,bold=True)
    for x,w,label,active in [(204,104,'Gökyüzü',True),(320,88,'Keşfet',False),(420,88,'Olaylar',False),(520,100,'Defterim',False)]:
        d.button(x,14,w,label,active,height=40)
    d.text(968,27,'AKIŞ TASLAĞI · MASAÜSTÜ',14,fill=GRAY)
    d.line(24,70,1256,70)
    d.button(24,91,245,'Örnek konum · Değiştir')
    d.button(282,91,240,'Tarih ve saat · Simülasyon')
    d.button(535,91,156,'Şimdiye dön',True)
    d.button(1038,91,218,'Ara: ad / M31 / NGC')
    d.text(24,153,'Gökyüzü',22,bold=True)
    d.text(188,158,'Örnek gözlem noktası',16,fill=GRAY)
    d.sky(24,193,834,449)
    d.button(40,586,46,'+',height=40,size=21)
    d.button(94,586,46,'−',height=40,size=21)
    d.button(154,586,119,'Katmanlar',height=40)
    d.button(286,586,153,'Metinsel bilgi',height=40)
    d.rect(880,193,376,449,LIGHT,LINE,4)
    d.text(900,214,'Seçili nesne',15,fill=GRAY)
    d.text(900,244,'Jüpiter',28,bold=True)
    d.text(900,283,'Gezegen · kaynaklı atlas içeriği',16,fill=GRAY)
    d.line(900,321,1236,321)
    for y,label,value in [(343,'Geometrik durum','Hesap bekleniyor'),(411,'Gözlem koşulları','Bilinmiyor'),(479,'Algılanabilirlik','Henüz değerlendirilemedi')]:
        d.text(900,y,label,16,bold=True)
        d.text(900,y+28,value,17,fill=GRAY)
    d.button(900,576,204,'Hedefe odaklan',True)
    d.button(1116,576,118,'Kartı kapat')
    d.rect(24,666,1232,99,WHITE,LINE,4)
    d.text(44,684,'Simülasyon · seçili tarih / yerel saat / saat dilimi',17,bold=True)
    d.text(45,727,'Önce',15,fill=GRAY)
    d.line(120,735,1080,735,GRAY,2)
    d.dot(570,735,6)
    d.text(1111,727,'Sonra',15,fill=GRAY)
    d.text(24,788,'Örnek veriler · konum hesabı ve kaynak entegrasyonu henüz yapılmadı',15,fill=GRAY)
    return d.save('masaustu')


def mobile():
    d = Diagram(420, 950, 'yorungez mobil wireframe', 'Şematik mobil harita, konum ve zaman, kısmen açık hedef paneli ve dört ana bölüm. Gerçek astronomi veya sensör işlevi yoktur.')
    d.text(18,18,'yorungez',25,bold=True)
    d.text(250,26,'MOBİL TASLAK',14,fill=GRAY)
    d.line(18,63,402,63)
    d.button(18,78,384,'Örnek konum · Değiştir')
    d.button(18,132,384,'Ara: Türkçe / İngilizce ad / katalog')
    d.sky(18,190,384,364)
    d.button(31,501,43,'+',height=39,size=21)
    d.button(82,501,43,'−',height=39,size=21)
    d.button(137,501,122,'Metinsel bilgi',height=39,size=14)
    d.text(18,574,'Simülasyon · seçili yerel tarih ve saat',16,bold=True)
    d.button(18,606,200,'Tarih ve saati değiştir',size=15)
    d.button(229,606,173,'Şimdiye dön',True,size=15)
    d.rect(18,666,384,172,LIGHT,LINE,8)
    d.line(175,679,245,679,GRAY,2)
    d.text(36,697,'Jüpiter',25,bold=True)
    d.text(36,736,'Geometrik durum: hesap bekleniyor',16)
    d.button(36,779,184,'Ayrıntıyı aç',True,height=40,size=15)
    d.button(232,779,152,'Haritayı genişlet',height=40,size=14)
    d.line(18,857,402,857)
    for x,w,label,active in [(18,91,'Gökyüzü',True),(117,84,'Keşfet',False),(209,84,'Olaylar',False),(301,101,'Defterim',False)]:
        d.button(x,870,w,label,active,height=42,size=14)
    d.text(18,928,'Örnek yerleşim · astronomik hesap içermez',14,fill=GRAY)
    return d.save('mobil')


def editors():
    d = Diagram(1140, 590, 'yorungez konum ve zaman düzenleyicileri', 'Solda geçersiz enlem örneği ve alan hatası; sağda tarih/saat, saat dilimi bağlamı ve iptal/uygula eylemleri. Sayılar varsayılan konum değildir.')
    d.text(24,19,'Konum ve zaman düzenleyicileri',25,bold=True)
    d.text(24,59,'Düşük ayrıntılı akış taslağı · aynı anda açılan iki pencereyi temsil etmez',16,fill=GRAY)
    for x,title in [(24,'Koordinat gir'),(594,'Tarih ve saat')]:
        d.rect(x,104,522,452,WHITE,LINE,8)
        d.text(x+22,125,title,24,bold=True)
        d.line(x+22,169,x+500,169)
    d.field(46,192,478,'Enlem','91',True)
    d.text(46,280,'Enlem −90 ile +90 arasında olmalı.',16,bold=True)
    d.field(46,324,478,'Boylam','−180 … +180')
    d.text(46,422,'Örnek hata · uygulanmış konum değişmez',16,fill=GRAY)
    d.button(266,485,118,'İptal')
    d.button(396,485,128,'Uygula',False)
    d.field(616,192,224,'Tarih','Tarih seç')
    d.field(860,192,234,'Saat','Saat seç')
    d.text(616,291,'Saat dilimi',16,bold=True)
    d.rect(616,322,478,47,LIGHT,LINE,5)
    d.text(630,337,'Seçili konumun saat dilimi',17)
    d.text(616,394,'Uyguladığında simülasyon başlar.',17)
    d.text(616,426,'İptal mevcut zamanı korur.',16,fill=GRAY)
    d.button(836,485,118,'İptal')
    d.button(966,485,128,'Uygula',True)
    return d.save('duzenleyiciler')


if __name__ == '__main__':
    if not REGULAR.is_file() or not BOLD.is_file():
        raise RuntimeError('Segoe UI font files are required to reproduce these documentation previews.')
    print(json.dumps([desktop(),mobile(),editors()],ensure_ascii=False,indent=2))
