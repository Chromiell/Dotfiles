# PDF to CSV Batch Table Extractor

Scans an `input/` folder for PDF files, extracts the structured tables found on
every page, flattens cell line breaks, and writes one semicolon-separated CSV per
PDF into `output/`.

---

## 📂 Structure

```text
pdf-to-csv/
├── convert.py          # extraction script
├── requirements.txt    # pdfplumber dependency
├── input/              # drop source .pdf files here
└── output/             # generated .csv files appear here
```

The `input/` and `output/` folders are tracked only through their `.gitignore`
files; their contents never enter the dotfiles repository.

---

## 🚀 Setup

```bash
cd ~/Projects/PythonScripts/pdf-to-csv
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

---

## 🧾 Usage

1. Copy the `.pdf` files to parse into `input/`.
2. Run the script from the project directory:

   ```bash
   cd ~/Projects/PythonScripts/pdf-to-csv
   .venv/bin/python3 convert.py
   ```

Each `input/<name>.pdf` becomes `output/<name>.csv`.

---

## 📝 Output Notes

- **Delimiter:** semicolon (`;`), for direct import into spreadsheets and SQL
  tools without colliding with punctuation inside cells.
- **Cleaning:** leading/trailing whitespace is stripped and multi-line cells are
  collapsed into a single line.
- **Empty rows:** rows whose cells are all empty are skipped.
