import base64, io, struct, math, sys
from PIL import Image, ImageDraw
out = sys.argv[1]
def img(fmt, color, label):
    im = Image.new('RGB', (160, 120), color)
    d = ImageDraw.Draw(im); d.rectangle([20,20,140,100], outline=(255,255,255), width=4); d.text((40,52), label, fill=(255,255,255))
    b = io.BytesIO(); im.save(b, fmt, quality=85) if fmt=='JPEG' else im.save(b, fmt); return b.getvalue()
jpeg = img('JPEG', (139,41,66), 'E2E JPEG')
png = img('PNG', (21,101,192), 'GROUP PNG')
# minimal one-page PDF with correct xref
objs = [b"<< /Type /Catalog /Pages 2 0 R >>", b"<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
        b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 200 200] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>",
        None, b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>"]
stream = b"BT /F1 18 Tf 30 100 Td (E2E PDF) Tj ET"
objs[3] = b"<< /Length %d >>\nstream\n" % len(stream) + stream + b"\nendstream"
pdf = b"%PDF-1.4\n"; offs = []
for i,o in enumerate(objs):
    offs.append(len(pdf)); pdf += b"%d 0 obj\n" % (i+1) + o + b"\nendobj\n"
x = len(pdf); pdf += b"xref\n0 %d\n0000000000 65535 f \n" % (len(objs)+1)
for o in offs: pdf += b"%010d 00000 n \n" % o
pdf += b"trailer\n<< /Size %d /Root 1 0 R >>\nstartxref\n%d\n%%%%EOF\n" % (len(objs)+1, x)
# 0.5 s 440 Hz mono 8 kHz WAV
n=4000; data=b''.join(struct.pack('<h', int(8000*math.sin(2*math.pi*440*i/8000))) for i in range(n))
wav = b'RIFF'+struct.pack('<I',36+len(data))+b'WAVEfmt '+struct.pack('<IHHIIHH',16,1,1,8000,16000,2,16)+b'data'+struct.pack('<I',len(data))+data
# minimal MP4 container (ftyp + free); not playable, only exercises the upload path/rules
def box(t, p): return struct.pack('>I', 8+len(p)) + t + p
mp4 = box(b'ftyp', b'isom' + struct.pack('>I', 512) + b'isomiso2mp41') + box(b'free', b'\0'*64)
with open(out, 'w', newline='\n') as f:
    f.write("// GENERATED test fixtures (scratchpad gen_fixtures.py): real JPEG/PNG\n// (PIL), a valid 1-page PDF, a 0.5 s WAV, and a minimal MP4 container\n// (ftyp only - exercises upload paths/rules, not playback).\n// ignore_for_file: constant_identifier_names\n")
    for name, b in [('jpegB64', jpeg), ('pngB64', png), ('pdfB64', pdf), ('wavB64', wav), ('mp4B64', mp4)]:
        f.write("const String %s =\n    '%s';\n" % (name, base64.b64encode(b).decode()))
print('ok', len(jpeg), len(png), len(pdf), len(wav), len(mp4))
