import sys
from pathlib import Path
from PyPDF2 import PdfReader

# Usage: python extract_pdf.py <pdf_path>
if len(sys.argv) < 2:
    print("Usage: python extract_pdf.py <pdf_path>")
    sys.exit(1)

pdf_path = Path(sys.argv[1])
if not pdf_path.exists():
    print("ERROR: PDF not found:", pdf_path)
    sys.exit(2)

reader = PdfReader(str(pdf_path))
text_parts = []
for i, page in enumerate(reader.pages):
    try:
        txt = page.extract_text() or ""
    except Exception as e:
        txt = f"[page {i} extract error: {e}]"
    text_parts.append(txt)

full = "\n\n".join(text_parts).strip()
output_txt = pdf_path.with_suffix('.txt')
with open(output_txt, 'w', encoding='utf-8') as f:
    f.write(full)

print('EXTRACTED LENGTH:', len(full))
print('SAVED TO:', output_txt)
# print first 2000 chars
print('\n--- TEXT PREVIEW ---\n')
print(full[:2000])
if len(full) == 0:
    print('\nNote: extracted text is empty. If the PDF is scanned, OCR is required.')
