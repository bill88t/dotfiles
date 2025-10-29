import os
import hashlib
from concurrent.futures import ThreadPoolExecutor, as_completed
import multiprocessing
import argparse

def get_hash(filepath, hash_algo='sha1', chunk_size=8192):
    """Compute hash of a file using specified algorithm."""
    h = hashlib.new(hash_algo)
    try:
        with open(filepath, 'rb') as f:
            while chunk := f.read(chunk_size):
                h.update(chunk)
        return h.hexdigest()
    except Exception as e:
        print(f"Error reading {filepath}: {e}")
        return None

def find_files(folder):
    """Recursively list all files in folder."""
    files = []
    for root, _, filenames in os.walk(folder):
        for f in filenames:
            files.append(os.path.join(root, f))
    return files

def process_file(filepath, hash_algo):
    """Hash a file and return (hash, filepath)."""
    h = get_hash(filepath, hash_algo)
    return (h, filepath) if h else None

def find_duplicates(folder, output_file, hash_algo='sha1'):
    files = find_files(folder)
    print(f"Found {len(files)} files, hashing with {hash_algo}...")

    duplicates = {}
    num_threads = multiprocessing.cpu_count() + 1

    with ThreadPoolExecutor(max_workers=num_threads) as executor:
        futures = {executor.submit(process_file, f, hash_algo): f for f in files}
        for future in as_completed(futures):
            result = future.result()
            if result:
                h, filepath = result
                duplicates.setdefault(h, []).append(filepath)

    # Filter only hashes with duplicates
    duplicates = {h: paths for h, paths in duplicates.items() if len(paths) > 1}

    # Write results
    with open(output_file, 'w') as f:
        for paths in duplicates.values():
            f.write("Duplicate group:\n")
            for p in paths:
                f.write(f"{p}\n")
            f.write("\n")

    print(f"Done. Found {len(duplicates)} sets of duplicates. Output written to {output_file}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Find duplicate files in a folder.")
    parser.add_argument("folder", help="Folder to scan")
    parser.add_argument("output", help="Output file for duplicates")
    parser.add_argument("--hash", default="sha1", help="Hash algorithm to use (default: sha1)")
    args = parser.parse_args()

    find_duplicates(args.folder, args.output, args.hash)
