import csv
import os
import pdfplumber


def batch_extract_pdf_tables(input_dir, output_dir):
    """Scans the input directory for all PDF files and exports their tables

    to corresponding CSV files in the output directory.
    """
    # Dynamically find all files ending in .pdf inside the input folder
    pdf_files = [f for f in os.listdir(input_dir) if f.lower().endswith(".pdf")]

    if not pdf_files:
        print(f"ℹ️ No PDF files found in '{input_dir}/'.")
        return

    print(f"📋 Found {len(pdf_files)} PDF file(s) to process.")
    print("-" * 50)

    for pdf_file in pdf_files:
        # Isolate the name without extension (e.g., '145.pdf' -> '145')
        base_name = os.path.splitext(pdf_file)[0]
        csv_filename = f"{base_name}.csv"

        # Safely construct paths
        pdf_path = os.path.join(input_dir, pdf_file)
        csv_path = os.path.join(output_dir, csv_filename)

        print(f"🔄 Processing '{pdf_path}' -> Exporting to '{csv_path}'...")

        try:
            with pdfplumber.open(pdf_path) as pdf:
                with open(csv_path, mode="w", newline="", encoding="utf-8") as csv_file:
                    writer = csv.writer(csv_file, delimiter=";")

                    for page in pdf.pages:
                        tables = page.extract_tables()

                        for table in tables:
                            for row in table:
                                # Clean up text internal line breaks and outer whitespaces
                                cleaned_row = [
                                    (
                                        cell.replace("\n", " ").strip()
                                        if cell is not None
                                        else ""
                                    )
                                    for cell in row
                                ]

                                # Prevent saving entirely empty rows
                                if any(cleaned_row):
                                    writer.writerow(cleaned_row)

            print(f"✅ Successfully created '{csv_path}'")

        except Exception as e:
            print(f"❌ Error processing '{pdf_path}': {e}")

        print("-" * 50)


# Folder Configurations
INPUT_FOLDER = "input"
OUTPUT_FOLDER = "output"

if __name__ == "__main__":
    print("Starting automatic batch PDF to CSV extraction from designated folders...")
    print("=" * 50)

    # Sanity check to make sure folders exist
    if not os.path.exists(INPUT_FOLDER):
        print(f"❌ Error: The input directory '{INPUT_FOLDER}' does not exist.")
    elif not os.path.exists(OUTPUT_FOLDER):
        print(f"❌ Error: The output directory '{OUTPUT_FOLDER}' does not exist.")
    else:
        batch_extract_pdf_tables(INPUT_FOLDER, OUTPUT_FOLDER)

    print("Batch processing complete.")
