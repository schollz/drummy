import sqlite3

from tqdm import tqdm
import numpy as np

con = sqlite3.connect("db.db")
cur = con.cursor()
ins1 = 1

idd = 0
fo = open("out.sql", "w")
fo.write(
    """CREATE TABLE prob(id INTEGER, ins1 INTEGER, ins2 INTEGER, pidbase INTEGER, pid INTEGER, prob REAL);
BEGIN;
"""
)

for ins1 in [1, 2, 3, 4, 5]:
    q = """SELECT DISTINCT pid FROM drum INDEXED BY idx_ins 
    WHERE ins=={}"""
    pidbases = []
    for row in cur.execute(q.format(ins1)):
        pidbases.append(row[0])
    print("found {} pids for ins {}".format(len(pidbases), ins1))

    q = """SELECT pid,count(pid) FROM drum INDEXED BY idx_gid 
    WHERE gid in (
        SELECT gid FROM drum INDEXED BY idx_pid 
        WHERE pid=={} AND ins=={}
    ) 
    AND ins=={} 
    GROUP BY pid ORDER BY count(pid) DESC LIMIT 50"""
    for ins2 in [1, 2, 3, 4, 5]:
        if ins1 == ins2:
            continue
        for pidbase in tqdm(pidbases):
            pids = []
            weights = []
            for row in cur.execute(q.format(pidbase, ins1, ins2)):
                pids.append(row[0])
                weights.append(row[1])
            total_weight = np.sum(weights)
            ##print("found {} pids for pid={},ins={}",len(pids),pidbase,ins1)
            for j, pid in enumerate(pids):
                idd += 1
                fo.write(
                    "INSERT INTO prob VALUES ({},{},{},{},{},{:2.6f});\n".format(
                        idd, ins1, ins2, pidbase, pid, weights[j] / total_weight
                    )
                )

fo.write("COMMIT;\n")
fo.write("CREATE INDEX idx_inspid ON prob(ins1,pidbase)")
fo.close()
