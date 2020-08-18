from fxpmath import Fxp
import random
import math
import os
import shutil
# Size of the volumes
Nix = 7
Niy = 7
Nif = 32
Nof = 64
Nkx = 3
Nky = 3
S = 1
t = 6
# Tiling params
Tix = 7
Tiy = 7
Tox = Tix
Toy = Tiy
Tix = Tox + Nkx - 1
Tiy = Toy + Nky - 1
# Calculated volume
Nox = Nix // S
Noy = Niy // S
# Pruning param
Npar = 8
Nnp = 2
# Calculated parameters related to Pruning
Ngr = Nif//Npar
Ngrint = (Nif * t) // Npar
# Offset
off_fmi = 2 * 2**20
off_fmo = 4 * 2**20
off_kex = 6 * 2**20
off_kpw = 26 * 2**20
off_kdw = 44 * 2**20
# Bitwidth
BW_px = 16
BW_wg = 16
fr_px = 12
fr_wg = 12
BW_pos = math.ceil(math.log2(Npar))
Ngr = (Nif // Npar) + ((Nif % Npar) % 2)

fmo             = [[[ 0 for _ in range(Nox)] for _ in range(Noy)] for _ in range(Nof)]
fmo_obtained    = [[[ 0 for _ in range(Nox)] for _ in range(Noy)] for _ in range(Nof)]

# A : Fill FMI
with open("fmo.txt", "r") as file1:
    for f in range(0, Nof):
        for y in range(0, Noy):
            for x in range(0, Nox):
                line = "0x" + file1.readline().split('\n')[0].upper()
                fmo[f][y][x] = Fxp(line, True, BW_px, fr_px, overflow = 'wrap')

with open("result_fmo.txt", "r") as file2:
    for ty in range(0, Noy//Toy):
        for tx in range(0, Nox//Tox):
            for f in range(0, Nof):
                for y in range(0, Toy):
                    for x in range(0, Tox):
                        res = file2.readline().split(':')
                        val = "0x" + res[0].upper()
                        pos = int(res[1])
                        f_pos = pos // (Nox * Noy)
                        y_pos = (pos % (Nox * Noy)) // Noy
                        x_pos = (pos % (Nox * Noy)) % Noy
                        fmo_obtained[f_pos][y_pos][x_pos] = Fxp(val, True, BW_px, fr_px, overflow = 'wrap')
                        # Check pos
                        if (not pos == f*Nox*Noy + y * Nox + ty * Toy * Nox + x + tx * Tox):
                            input("Error: expected " + str(f*Nox*Noy + y * Nox + ty * Toy * Nox + x + tx * Tox) + ", obtained " + str(pos))
cnt_error = 0
cnt_nerror = 0
for f in range(0, Nof):
    for y in range(0, Noy):
        for x in range(0, Nox):
            diff = abs(fmo[f][y][x]() - fmo_obtained[f][y][x]())
            if (diff > 1):
                cnt_error = cnt_error + 1
            else:
                cnt_nerror = cnt_nerror + 1
print(cnt_error)
print(cnt_nerror)
