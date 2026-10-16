#!/usr/bin/env python3
"""Génère les illustrations de maisons (brand/houses/*.svg) utilisées en démo.
Rendu en JPG par scripts/render_houses.js (Chromium)."""
import os

W, H = 1200, 900
OUT = os.path.join(os.path.dirname(__file__), '..', 'brand', 'houses')

def svg(body, defs=''):
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">
<defs>
<linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8FD3F4"/><stop offset=".7" stop-color="#D8F1FF"/><stop offset="1" stop-color="#FFF6E5"/></linearGradient>
<linearGradient id="glass" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#9ED8F0"/><stop offset="1" stop-color="#3C7FA6"/></linearGradient>
<linearGradient id="wallshade" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity=".12"/></linearGradient>
<linearGradient id="floor" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E9E2D6"/><stop offset="1" stop-color="#CFC6B6"/></linearGradient>
<filter id="blur"><feGaussianBlur stdDeviation="10"/></filter>
{defs}
</defs>
{body}
</svg>'''

def sky():
    return f'''<rect width="{W}" height="{H}" fill="url(#sky)"/>
<circle cx="1010" cy="140" r="64" fill="#FFE9A8"/><circle cx="1010" cy="140" r="44" fill="#FFD76A"/>
<g fill="#fff" opacity=".9"><ellipse cx="260" cy="120" rx="110" ry="30"/><ellipse cx="330" cy="100" rx="70" ry="30"/><ellipse cx="760" cy="190" rx="90" ry="24"/><ellipse cx="820" cy="172" rx="56" ry="24"/></g>'''

def win(x, y, w, h, frame='#fff'):
    return f'''<g><rect x="{x-6}" y="{y-6}" width="{w+12}" height="{h+12}" rx="4" fill="{frame}"/><rect x="{x}" y="{y}" width="{w}" height="{h}" fill="url(#glass)"/>
<rect x="{x+w/2-2}" y="{y}" width="4" height="{h}" fill="{frame}"/><path d="M{x+6} {y+h-6} L{x+w*0.4} {y+6} L{x+w*0.55} {y+6} L{x+w*0.2} {y+h-6}Z" fill="#fff" opacity=".25"/></g>'''

def palm(x, y, s=1.0):
    fr = ''.join(f'<path d="M{x} {y-230*s} q{dx*s} {-60*s} {dx*1.6*s} {20*s} q{-dx*0.4*s} {-20*s} {-dx*1.6*s} {-20*s}Z" fill="{c}" transform="rotate({r} {x} {y-230*s})"/>' for dx,c,r in [(120,'#2E8B57',-15),(120,'#3AA76D',30),(120,'#2E8B57',75),(120,'#3AA76D',150),(120,'#2E8B57',200),(120,'#3AA76D',250),(120,'#2E8B57',300)])
    return f'<path d="M{x-10*s} {y} Q{x+14*s} {y-120*s} {x} {y-230*s} L{x+12*s} {y-230*s} Q{x+30*s} {y-120*s} {x+14*s} {y}Z" fill="#8B6B4A"/>{fr}'

def shadow(x, y, w):
    return f'<ellipse cx="{x}" cy="{y}" rx="{w}" ry="16" fill="#000" opacity=".18" filter="url(#blur)"/>'

def tree(x, y, s=1.0, c='#3B9B5C'):
    return f'<rect x="{x-8*s}" y="{y-80*s}" width="{16*s}" height="{80*s}" fill="#7A5A3A"/><circle cx="{x}" cy="{y-120*s}" r="{70*s}" fill="{c}"/><circle cx="{x-40*s}" cy="{y-90*s}" r="{48*s}" fill="{c}" opacity=".9"/><circle cx="{x+42*s}" cy="{y-95*s}" r="{50*s}" fill="{c}" opacity=".95"/>'

def pot(x, y, s=1.0):
    return f'<path d="M{x-18*s} {y} h{36*s} l{-6*s} {-30*s} h{-24*s}Z" fill="#C2693F"/><circle cx="{x}" cy="{y-42*s}" r="{22*s}" fill="#3FA865"/><circle cx="{x-14*s}" cy="{y-32*s}" r="{14*s}" fill="#2F8F55"/><circle cx="{x+14*s}" cy="{y-34*s}" r="{15*s}" fill="#4DBA74"/>'

# ---------- extérieurs
def villa_cream():
    b = sky()
    b += f'<rect y="700" width="{W}" height="200" fill="#CFC4AE"/><rect y="700" width="{W}" height="14" fill="#B9AE98"/>'
    b += f'<path d="M0 760 H{W}" stroke="#BDB19A" stroke-width="3"/>' + ''.join(f'<path d="M{x} 714 L{x-80} 900" stroke="#BDB19A" stroke-width="2"/>' for x in range(0, 1300, 130))
    b += tree(110, 700, 1.1) + palm(1110, 705, 1.0)
    b += shadow(600, 712, 420)
    b += '<rect x="250" y="360" width="700" height="340" fill="#F2E2BF"/><rect x="250" y="360" width="700" height="340" fill="url(#wallshade)"/>'
    b += '<rect x="300" y="210" width="600" height="160" fill="#F7EBCF"/><rect x="300" y="210" width="600" height="160" fill="url(#wallshade)"/>'
    b += '<rect x="286" y="196" width="628" height="22" fill="#D9C79F"/><rect x="236" y="346" width="728" height="22" fill="#D9C79F"/>'
    # terrasse toit
    b += '<g fill="none" stroke="#6B6B6B" stroke-width="5"><path d="M290 196 V160 H910 V196"/>' + ''.join(f'<path d="M{x} 160 V196"/>' for x in range(310, 910, 40)) + '</g>'
    for x in (350, 540, 730): b += win(x, 250, 110, 90)
    for x in (300, 470, 760): b += win(x, 420, 120, 110)
    b += '<rect x="580" y="500" width="130" height="200" rx="6" fill="#8A5A3B"/><rect x="592" y="514" width="106" height="176" rx="4" fill="#9A6845"/><circle cx="690" cy="610" r="7" fill="#F0C27B"/>'
    b += '<rect x="210" y="560" width="780" height="140" fill="#E5D4AE" opacity="0"/>'
    # mur + portail
    b += '<rect x="130" y="610" width="320" height="92" fill="#E8D8B4"/><rect x="130" y="598" width="320" height="16" fill="#CDBA90"/><rect x="760" y="610" width="320" height="92" fill="#E8D8B4"/><rect x="760" y="598" width="320" height="16" fill="#CDBA90"/>'
    b += '<rect x="450" y="560" width="310" height="142" fill="#4B5563"/>' + ''.join(f'<rect x="{x}" y="570" width="8" height="128" fill="#6B7280"/>' for x in range(460, 760, 24))
    b += '<rect x="450" y="560" width="310" height="10" fill="#374151"/>'
    b += pot(170, 700) + pot(1040, 700, 1.1)
    return svg(b)

def villa_modern():
    b = sky()
    b += f'<rect y="690" width="{W}" height="210" fill="#7CC27A"/><path d="M0 770 Q600 730 1200 790 V900 H0Z" fill="#6AB36A"/>'
    b += '<path d="M380 900 L520 710 H800 L980 900Z" fill="#D8D5CE"/><path d="M520 710 L800 710" stroke="#B9B5AB" stroke-width="4"/>'
    b += palm(120, 720, 1.15) + palm(1080, 715, 1.0)
    b += shadow(600, 706, 460)
    # volumes
    b += '<rect x="200" y="400" width="520" height="300" fill="#FBFBFA"/><rect x="560" y="250" width="440" height="200" fill="#F4F4F1"/><rect x="200" y="400" width="520" height="300" fill="url(#wallshade)"/>'
    b += '<rect x="180" y="384" width="560" height="26" fill="#E2E2DE"/><rect x="540" y="236" width="480" height="26" fill="#DADAD6"/>'
    b += '<rect x="560" y="440" width="440" height="260" fill="#C58B5B"/>' + ''.join(f'<rect x="{x}" y="440" width="6" height="260" fill="#A9703F" opacity=".6"/>' for x in range(575, 1000, 28))
    b += '<rect x="240" y="450" width="260" height="200" fill="url(#glass)"/><rect x="368" y="450" width="4" height="200" fill="#fff"/><rect x="240" y="450" width="260" height="200" fill="none" stroke="#fff" stroke-width="6"/>'
    b += '<path d="M250 640 L330 460 L360 460 L280 640Z" fill="#fff" opacity=".22"/>'
    b += '<rect x="600" y="290" width="360" height="120" fill="url(#glass)"/><rect x="600" y="290" width="360" height="120" fill="none" stroke="#fff" stroke-width="6"/><rect x="778" y="290" width="4" height="120" fill="#fff"/>'
    b += '<rect x="610" y="500" width="110" height="200" fill="#2D3748"/><rect x="620" y="510" width="90" height="180" fill="#3B475C"/><rect x="690" y="590" width="6" height="40" rx="3" fill="#E5E7EB"/>'
    b += '<rect x="780" y="520" width="190" height="120" fill="url(#glass)" opacity=".9"/><rect x="780" y="520" width="190" height="120" fill="none" stroke="#fff" stroke-width="5"/>'
    # voiture
    b += '<g><rect x="430" y="780" width="250" height="60" rx="26" fill="#C0392B"/><path d="M470 780 L505 742 H620 L650 780Z" fill="#E74C3C"/><path d="M515 748 H575 V778 H488Z M585 748 H615 L640 778 H585Z" fill="#CFEFFF"/><circle cx="490" cy="842" r="24" fill="#222"/><circle cx="490" cy="842" r="10" fill="#aaa"/><circle cx="625" cy="842" r="24" fill="#222"/><circle cx="625" cy="842" r="10" fill="#aaa"/></g>'
    b += pot(250, 700, 1.0) + pot(180, 705, .8)
    return svg(b)

def apartment():
    b = sky()
    b += f'<rect y="740" width="{W}" height="160" fill="#8B8F95"/><rect y="740" width="{W}" height="24" fill="#B9BCC1"/><path d="M0 830 H{W}" stroke="#F2F2F2" stroke-width="6" stroke-dasharray="60 40"/>'
    b += '<rect x="60" y="200" width="150" height="540" fill="#C9B79C"/><rect x="990" y="260" width="150" height="480" fill="#D5C2A5"/>' + ''.join(f'<rect x="{x}" y="{y}" width="26" height="36" fill="#7FA9C4"/>' for x in (80,120,160) for y in range(240, 700, 70)) + ''.join(f'<rect x="{x}" y="{y}" width="26" height="36" fill="#7FA9C4"/>' for x in (1010,1050,1090) for y in range(300, 700, 70))
    b += tree(110, 745, 1.0, '#2F8F55') + tree(1110, 745, .9, '#3FA865')
    b += shadow(600, 742, 440)
    b += '<rect x="260" y="140" width="680" height="600" fill="#E3B993"/><rect x="260" y="140" width="680" height="600" fill="url(#wallshade)"/><rect x="240" y="124" width="720" height="26" fill="#B98B66"/>'
    b += '<rect x="260" y="640" width="680" height="100" fill="#F0E2CC"/>'
    for r in range(4):
        y = 180 + r*118
        for c in range(4):
            x = 300 + c*160
            b += f'<rect x="{x-6}" y="{y+70}" width="132" height="14" fill="#9C9C9C"/><rect x="{x-6}" y="{y+56}" width="132" height="5" fill="#B5B5B5"/>' + ''.join(f'<rect x="{x-6+i*21}" y="{y+56}" width="4" height="18" fill="#B5B5B5"/>' for i in range(7))
            b += win(x, y, 120, 54, '#F5EFE6')
            if (r + c) % 3 == 0: b += f'<rect x="{x+78}" y="{y-24}" width="38" height="22" rx="3" fill="#F4F4F4" stroke="#CFCFCF"/><circle cx="{x+88}" cy="{y-13}" r="6" fill="#DADADA"/>'
    b += '<rect x="520" y="620" width="160" height="120" fill="#38566B"/><rect x="530" y="630" width="64" height="110" fill="url(#glass)"/><rect x="606" y="630" width="64" height="110" fill="url(#glass)"/>'
    b += '<path d="M290 640 h200 v18 h-200Z" fill="#D9534F"/>' + ''.join(f'<path d="M{x} 640 h25 v18 h-25Z" fill="#fff" opacity=".7"/>' for x in range(300, 490, 50))
    b += '<rect x="300" y="660" width="170" height="80" fill="#FFF7E6"/><rect x="316" y="676" width="60" height="64" fill="#F2C94C"/><rect x="386" y="676" width="70" height="40" fill="#7FB7D6"/>'
    b += '<rect x="720" y="660" width="190" height="80" fill="#F7F1E6"/><rect x="740" y="676" width="150" height="64" fill="url(#glass)"/>'
    return svg(b)

def courtyard_house():
    b = sky()
    b += f'<rect y="690" width="{W}" height="210" fill="#D9C7A0"/><path d="M0 800 Q600 770 1200 820 V900 H0Z" fill="#CDB98E"/>'
    b += tree(1090, 700, 1.2, '#3FA865') + tree(120, 700, 1.0, '#2F8F55')
    b += shadow(600, 702, 440)
    b += '<rect x="260" y="400" width="620" height="300" fill="#8EC5E6"/><rect x="260" y="400" width="620" height="300" fill="url(#wallshade)"/>'
    b += '<path d="M220 410 L570 270 L920 410Z" fill="#B5523B"/>' + ''.join(f'<path d="M{245+i*40} {408-i*8} L{570} {278}" stroke="#9B4430" stroke-width="2" opacity=".5"/>' for i in range(0, 1)) + ''.join(f'<path d="M{230+k} 410 L{570} {276+0}" stroke="none"/>' for k in range(1))
    b += '<path d="M220 410 L570 270 L920 410 L920 424 L220 424Z" fill="#9B4430" opacity=".55"/>'
    b += '<rect x="250" y="420" width="640" height="16" fill="#6FA9CC"/>'
    b += win(310, 470, 100, 100, '#F7F7F7') + win(710, 470, 100, 100, '#F7F7F7')
    b += '<rect x="480" y="480" width="140" height="220" rx="4" fill="#2F8F55"/><rect x="492" y="494" width="116" height="196" rx="3" fill="#3AA568"/><circle cx="596" cy="600" r="7" fill="#F0C27B"/>'
    # véranda
    b += '<rect x="240" y="640" width="660" height="60" fill="#E7DCC5"/><rect x="240" y="636" width="660" height="10" fill="#CBBE9F"/>' + ''.join(f'<rect x="{x}" y="640" width="2" height="60" fill="#C9BC9C"/>' for x in range(280, 900, 40))
    # mur de cour
    b += '<rect x="60" y="640" width="190" height="70" fill="#F1E6CF"/><rect x="900" y="640" width="240" height="70" fill="#F1E6CF"/><rect x="60" y="628" width="190" height="14" fill="#D8C8A4"/><rect x="900" y="628" width="240" height="14" fill="#D8C8A4"/>'
    b += '<rect x="250" y="720" width="650" height="12" fill="#BFAE86" opacity=".6"/>'
    b += pot(300, 760, 1.3) + pot(880, 770, 1.4) + pot(680, 790, 1.0)
    b += '<g><rect x="470" y="730" width="60" height="10" rx="5" fill="#fff" opacity=".35"/></g>'
    return svg(b)

# ---------- intérieurs
def room_base(wall='#F1EBE0', floor_top=620):
    b = f'<rect width="{W}" height="{H}" fill="{wall}"/><rect width="{W}" height="{H}" fill="url(#wallshade)" opacity=".5"/>'
    b += f'<rect y="{floor_top}" width="{W}" height="{H-floor_top}" fill="url(#floor)"/>'
    for i in range(0, 14):
        y = floor_top + i*(H-floor_top)/13
        b += f'<path d="M0 {y} H{W}" stroke="#B9AF9D" stroke-width="2" opacity=".6"/>'
    for x in range(-600, 1800, 150):
        b += f'<path d="M{x} {H} L{600+(x-600)*0.35} {floor_top}" stroke="#B9AF9D" stroke-width="2" opacity=".6"/>'
    b += f'<rect y="{floor_top-18}" width="{W}" height="18" fill="#FFFFFF"/><rect y="{floor_top-20}" width="{W}" height="3" fill="#D9D2C5"/>'
    return b

def fan(x, y):
    return f'<rect x="{x-4}" y="0" width="8" height="{y}" fill="#777"/><circle cx="{x}" cy="{y}" r="18" fill="#555"/>' + ''.join(f'<ellipse cx="{x+dx}" cy="{y+4}" rx="70" ry="10" fill="#D8D2C4" transform="rotate({r} {x} {y})"/>' for dx,r in [(60,-6),(-60,6),(0,0)])

def sun_window(x, y, w, h):
    return f'<rect x="{x-12}" y="{y-12}" width="{w+24}" height="{h+24}" fill="#fff"/><rect x="{x}" y="{y}" width="{w}" height="{h}" fill="url(#sky)"/><rect x="{x+w/2-3}" y="{y}" width="6" height="{h}" fill="#fff"/><rect x="{x}" y="{y+h/2-3}" width="{w}" height="6" fill="#fff"/><path d="M{x} {y+h} L{x-60} {y+h+190} H{x+w+260} L{x+w} {y+h}Z" fill="#FFF3C4" opacity=".35"/>'

def bedroom():
    b = room_base('#EAF1EE')
    b += fan(600, 110) + sun_window(120, 130, 300, 300)
    b += '<path d="M120 130 q-40 160 0 320" fill="none"/><rect x="90" y="110" width="60" height="360" fill="#F6E7C9" opacity=".95"/><rect x="390" y="110" width="60" height="360" fill="#F6E7C9" opacity=".95"/>'
    # lit
    b += shadow(790, 690, 250)
    b += '<rect x="600" y="300" width="400" height="260" rx="14" fill="#8C6A4B"/><rect x="620" y="470" width="380" height="190" rx="16" fill="#F4F6F8"/><rect x="620" y="560" width="380" height="110" rx="12" fill="#2F8F8A"/><rect x="620" y="550" width="380" height="24" rx="8" fill="#3FA9A3"/><rect x="640" y="470" width="130" height="64" rx="18" fill="#fff"/><rect x="790" y="470" width="130" height="64" rx="18" fill="#FFF3D6"/><rect x="600" y="650" width="22" height="50" fill="#6D4F36"/><rect x="980" y="650" width="22" height="50" fill="#6D4F36"/>'
    # bureau
    b += '<rect x="150" y="520" width="340" height="18" rx="6" fill="#B07A4A"/><rect x="165" y="538" width="14" height="150" fill="#8F6139"/><rect x="460" y="538" width="14" height="150" fill="#8F6139"/><rect x="190" y="470" width="120" height="50" rx="4" fill="#2E3A59"/><rect x="198" y="478" width="104" height="34" fill="#7FB8E8"/><rect x="330" y="486" width="60" height="34" fill="#E9C46A"/><rect x="410" y="476" width="46" height="44" rx="8" fill="#fff" stroke="#ddd"/>'
    b += '<rect x="300" y="580" width="110" height="14" rx="6" fill="#4A5568"/><rect x="316" y="594" width="10" height="94" fill="#2D3748"/><rect x="384" y="594" width="10" height="94" fill="#2D3748"/><rect x="310" y="520" width="12" height="60" fill="#4A5568" opacity="0"/>'
    # armoire
    b += '<rect x="1010" y="230" width="150" height="430" rx="8" fill="#C9A27A"/><rect x="1084" y="240" width="4" height="410" fill="#A67F58"/><circle cx="1076" cy="450" r="6" fill="#6D4F36"/><circle cx="1096" cy="450" r="6" fill="#6D4F36"/>'
    b += pot(540, 700, 1.3)
    return svg(b)

def living():
    b = room_base('#F3EEE6')
    b += fan(600, 100)
    b += sun_window(820, 130, 280, 330)
    b += '<rect x="780" y="110" width="50" height="380" fill="#E9C46A" opacity=".9"/><rect x="1090" y="110" width="50" height="380" fill="#E9C46A" opacity=".9"/>'
    # tapis
    b += '<ellipse cx="560" cy="760" rx="380" ry="80" fill="#D96C4A" opacity=".9"/><ellipse cx="560" cy="760" rx="330" ry="62" fill="#F0A58A" opacity=".8"/>'
    b += shadow(500, 700, 380)
    # canapé
    b += '<rect x="160" y="450" width="660" height="160" rx="40" fill="#7B8794"/><rect x="190" y="560" width="600" height="110" rx="26" fill="#9AA5B1"/><rect x="140" y="500" width="70" height="170" rx="30" fill="#6B7684"/><rect x="770" y="500" width="70" height="170" rx="30" fill="#6B7684"/><rect x="210" y="480" width="120" height="100" rx="24" fill="#F2C94C"/><rect x="660" y="490" width="110" height="90" rx="24" fill="#E07A5F"/>'
    b += '<path d="M200 560 H780" stroke="#8A95A1" stroke-width="3"/><rect x="220" y="670" width="14" height="24" fill="#4A4A4A"/><rect x="750" y="670" width="14" height="24" fill="#4A4A4A"/>'
    # table basse
    b += '<rect x="360" y="700" width="260" height="22" rx="8" fill="#A9743F"/><rect x="380" y="722" width="12" height="40" fill="#7B5128"/><rect x="590" y="722" width="12" height="40" fill="#7B5128"/><rect x="400" y="684" width="90" height="16" rx="3" fill="#E9E1D0"/><rect x="520" y="676" width="40" height="24" rx="6" fill="#fff" stroke="#ddd"/>'
    # meuble TV
    b += '<rect x="60" y="150" width="10" height="10" fill="none"/>'
    b += '<g transform="translate(0 -120)">'
    b += '<rect x="90" y="330" width="260" height="170" rx="6" fill="#16202C"/><rect x="100" y="340" width="240" height="150" fill="#27465E"/><path d="M100 440 q60 -60 120 -20 t120 -20 V490 H100Z" fill="#3B7A57" opacity=".7"/><rect x="200" y="500" width="40" height="22" fill="#16202C"/>'
    b += '<rect x="60" y="522" width="330" height="40" rx="8" fill="#8B5E34"/>'
    b += '</g>'
    b += pot(1120, 700, 1.7)
    b += '<g fill="#6B7280"><rect x="1070" y="560" width="14" height="140"/></g>'
    return svg(b)

def kitchen():
    b = room_base('#F4EFE3')
    # carrelage mural
    b += ''.join(f'<rect x="{x}" y="{y}" width="75" height="75" fill="#fff" stroke="#E0DACB" stroke-width="2"/>' for x in range(0, W, 75) for y in range(285, 580, 75) if True)
    b += fan(600, 90)
    # placards hauts
    b += ''.join(f'<rect x="{x}" y="80" width="165" height="180" rx="6" fill="#E9C46A" stroke="#D3AC4C" stroke-width="3"/><circle cx="{x+140}" cy="200" r="6" fill="#8A6A1E"/>' for x in (40, 215, 390)) + ''.join(f'<rect x="{x}" y="80" width="165" height="180" rx="6" fill="#E9C46A" stroke="#D3AC4C" stroke-width="3"/><circle cx="{x+25}" cy="200" r="6" fill="#8A6A1E"/>' for x in (760, 935))
    # hotte
    b += '<path d="M600 190 L640 90 H760 L800 190Z" fill="#B8C0C8"/><rect x="560" y="190" width="280" height="22" rx="6" fill="#9AA5AE"/>'
    # plan de travail bas
    b += shadow(560, 700, 560)
    b += '<rect x="30" y="520" width="1140" height="40" rx="6" fill="#6B7280"/><rect x="40" y="560" width="1120" height="160" fill="#F2F2F0"/>' + ''.join(f'<rect x="{x}" y="570" width="176" height="140" rx="6" fill="#E9C46A" stroke="#D3AC4C" stroke-width="3"/><circle cx="{x+150}" cy="600" r="6" fill="#8A6A1E"/>' for x in (60, 245, 430)) + ''.join(f'<rect x="{x}" y="570" width="176" height="140" rx="6" fill="#E9C46A" stroke="#D3AC4C" stroke-width="3"/><circle cx="{x+26}" cy="600" r="6" fill="#8A6A1E"/>' for x in (900, 985))
    # cuisinière
    b += '<rect x="620" y="470" width="260" height="250" rx="8" fill="#E5E7EB" stroke="#C9CDD2" stroke-width="3"/><rect x="620" y="470" width="260" height="40" fill="#CBD0D6"/>' + ''.join(f'<ellipse cx="{x}" cy="486" rx="30" ry="9" fill="#3C3C3C"/><ellipse cx="{x}" cy="484" rx="14" ry="4" fill="#F28C28"/>' for x in (675, 735, 795, 855)[:4]) + '<rect x="650" y="540" width="200" height="130" rx="8" fill="#2B2F36"/><rect x="662" y="552" width="176" height="106" rx="6" fill="#3A4049"/><rect x="670" y="520" width="160" height="10" rx="5" fill="#9AA0A6"/>'
    # evier
    b += '<rect x="250" y="500" width="200" height="22" rx="6" fill="#B9C0C8"/><rect x="340" y="450" width="10" height="50" fill="#9AA5AE"/><rect x="340" y="446" width="50" height="10" rx="5" fill="#9AA5AE"/>'
    # frigo
    b += '<rect x="1020" y="280" width="130" height="400" rx="12" fill="#F5F5F7" stroke="#CFD2D6" stroke-width="3"/><rect x="1020" y="440" width="130" height="6" fill="#CFD2D6"/><rect x="1032" y="340" width="8" height="70" rx="4" fill="#9AA0A6"/><rect x="1032" y="470" width="8" height="90" rx="4" fill="#9AA0A6"/>'
    b += '<rect x="410" y="478" width="80" height="42" rx="6" fill="#C2693F"/><circle cx="450" cy="470" r="22" fill="#3FA865"/><rect x="520" y="486" width="60" height="34" rx="6" fill="#fff" stroke="#ddd"/>'
    return svg(b)

def studio():
    b = room_base('#EEF0F7')
    b += fan(560, 100) + sun_window(80, 130, 260, 320)
    b += '<rect x="50" y="110" width="50" height="370" fill="#C7D2FE" opacity=".95"/><rect x="320" y="110" width="50" height="370" fill="#C7D2FE" opacity=".95"/>'
    b += shadow(850, 700, 320)
    # lit double
    b += '<rect x="620" y="340" width="480" height="30" fill="#7A5A3F"/><rect x="620" y="370" width="480" height="230" rx="14" fill="#7A5A3F"/><rect x="640" y="470" width="450" height="170" rx="18" fill="#FAFAFA"/><rect x="640" y="560" width="450" height="100" rx="14" fill="#6C8EAD"/><rect x="640" y="548" width="450" height="26" rx="10" fill="#8DAAC4"/><rect x="665" y="470" width="150" height="70" rx="20" fill="#fff"/><rect x="850" y="470" width="150" height="70" rx="20" fill="#F7E7CE"/><rect x="620" y="640" width="24" height="60" fill="#5C4330"/><rect x="1076" y="640" width="24" height="60" fill="#5C4330"/>'
    # kitchenette murale
    b += '<rect x="420" y="520" width="170" height="170" fill="#F2F2F0"/><rect x="415" y="505" width="180" height="22" fill="#6B7280"/><rect x="440" y="560" width="130" height="110" rx="6" fill="#E9C46A"/><circle cx="460" cy="600" r="5" fill="#8A6A1E"/><rect x="430" y="210" width="150" height="100" rx="6" fill="#E9C46A" stroke="#D3AC4C" stroke-width="3"/><ellipse cx="470" cy="496" rx="24" ry="7" fill="#3C3C3C"/><ellipse cx="540" cy="496" rx="24" ry="7" fill="#3C3C3C"/>'
    # table + chaises
    b += '<ellipse cx="230" cy="740" rx="150" ry="22" fill="#000" opacity=".16" filter="url(#blur)"/><ellipse cx="230" cy="598" rx="120" ry="22" fill="#B07A4A"/><rect x="224" y="606" width="12" height="120" fill="#8F6139"/><ellipse cx="230" cy="726" rx="50" ry="9" fill="#8F6139"/>'
    b += '<rect x="75" y="560" width="76" height="14" rx="6" fill="#E76F51"/><rect x="82" y="574" width="8" height="120" fill="#B94E35"/><rect x="136" y="574" width="8" height="120" fill="#B94E35"/><rect x="75" y="480" width="12" height="84" rx="5" fill="#E76F51"/>'
    b += '<rect x="312" y="560" width="76" height="14" rx="6" fill="#E76F51"/><rect x="319" y="574" width="8" height="120" fill="#B94E35"/><rect x="373" y="574" width="8" height="120" fill="#B94E35"/><rect x="376" y="480" width="12" height="84" rx="5" fill="#E76F51"/>'
    b += '<rect x="196" y="570" width="60" height="28" rx="5" fill="#fff" stroke="#ddd"/><circle cx="270" cy="584" r="12" fill="#3FA865"/>'
    b += '<rect x="1130" y="300" width="60" height="400" rx="6" fill="#CBA37A"/>'
    return svg(b)

SCENES = {
    'house1': villa_cream, 'house2': villa_modern, 'house3': apartment, 'house4': courtyard_house,
    'house5': bedroom, 'house6': living, 'house7': kitchen, 'house8': studio,
}

if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    for name, fn in SCENES.items():
        with open(os.path.join(OUT, name + '.svg'), 'w') as f:
            f.write(fn())
    print('ok', len(SCENES))
