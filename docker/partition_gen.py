#!/usr/bin/python3
import sqlite3
import multiprocessing
from collections import defaultdict
import json
from math import ceil
from pathlib import Path
import sys


def create_partitions(gpkg_path: Path, num_partitions: int = None) -> None:
    if num_partitions is None:
        num_partitions = multiprocessing.cpu_count()

    con = sqlite3.connect(gpkg_path)
    nexus = defaultdict(list)
    for row in con.execute("SELECT toid, divide_id FROM divides"):
        nexus[row[0]].append(row[1])

    num_partitions = min(num_partitions, len(nexus))
    partition_size = ceil(len(nexus) / num_partitions)
    num_nexus = len(nexus)
    nexus = list(nexus.items())
    partitions = []
    for i in range(0, num_nexus, partition_size):
        part = {}
        part["id"] = i // partition_size
        part["cat-ids"] = []
        part["nex-ids"] = []
        part["remote-connections"] = []
        for j in range(i, i + partition_size):
            if j < num_nexus:
                part["cat-ids"].extend(nexus[j][1])
                part["nex-ids"].append(nexus[j][0])
        partitions.append(part)

    partition_folder = gpkg_path.parent

    with open(partition_folder / f"partitions_{num_partitions}.json", "w") as f:
        f.write(json.dumps({"partitions": partitions}))
    


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Please provide the path to the gpkg file as a command line argument.")
        sys.exit(1)
    
    gpkg = Path(sys.argv[1])
    create_partitions(gpkg)
    
