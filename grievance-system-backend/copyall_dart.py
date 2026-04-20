import os

def consolidate_dart_files(source_folder, output_path):
    # Ensure the destination directory exists
    output_dir = os.path.dirname(output_path)
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    with open(output_path, 'w', encoding='utf-8') as outfile:
        for root, dirs, files in os.walk(source_folder):
            for file in files:
                if file.endswith(".dart"):
                    full_path = os.path.join(root, file)
                    
                    # Add the separator and file path
                    outfile.write(f"\n======= {full_path} =======\n\n")
                    
                    # Read and append the file content
                    try:
                        with open(full_path, 'r', encoding='utf-8') as infile:
                            outfile.write(infile.read())
                        outfile.write("\n")
                    except Exception as e:
                        outfile.write(f"Error reading file {full_path}: {e}\n")

if __name__ == "__main__":
    # Source folder containing dart files
    source = "/Users/navanathmemane/Downloads/PCMC/PCMC/frontend"
    
    # Destination single text file
    output = "/Users/navanathmemane/Downloads/PCMC/PCMC/grievance-system-backend/consolidated_dart_files.txt"
    
    consolidate_dart_files(source, output)
    print(f"Successfully created: {output}")
