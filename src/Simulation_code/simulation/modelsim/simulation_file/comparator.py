from fxpmath import Fxp
import random
import math

Nix = 14
Niy = 14
Nif = 8
Nof = 8
Nkx = 3
Nky = 3
S = 1
t = 1
# Tiling params
Tix = 14
Tiy = 14
Tox = Tix
Toy = Tiy
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

fmi             = [[[ 0 for _ in range(Nix)] for _ in range(Niy)] for _ in range(Nif)]
fmi_obtained    = [[[ 0 for _ in range(Nix)] for _ in range(Niy)] for _ in range(Nif)]
kex_wg          = [[[ 0 for _ in range(Nnp)] for _ in range(Ngr)] for _ in range(Nif * t)]
kex_ps          = [[[ 0 for _ in range(Nnp)] for _ in range(Ngr)] for _ in range(Nif * t)]
kex_wg_obtained = [[[ 0 for _ in range(Nnp)] for _ in range(Ngr)] for _ in range(Nif * t)]
kex_ps_obtained = [[[ 0 for _ in range(Nnp)] for _ in range(Ngr)] for _ in range(Nif * t)]
fmint           = [[[ 0 for _ in range(Nix)] for _ in range(Niy)] for _ in range(Nif)]
fmint_obtained  = [[[ 0 for _ in range(Nix)] for _ in range(Niy)] for _ in range(Nif)]

# A : Fill FMI
with open("fmi.txt", "r") as file1:
    for f in range(0, Nif):
        for y in range(0, Niy):
            for x in range(0, Nix):
                line = "0x" + file1.readline().split('\n')[0].upper()
                fmi[f][y][x] = Fxp(line, True, BW_px, fr_px, overflow = 'wrap')

with open("result_fmi.txt", "r") as file2:
    for ty in range(0, Niy//Tiy):
        for tx in range(0, Nix//Tix):
            for f in range(0, Nif):
                for y in range(0, Tiy):
                    for x in range(0, Tix):
                        res = file2.readline().split(':')
                        val = "0x" + res[0].upper()
                        fmi_obtained[f][y + ty * Tiy][x + tx * Tix] = Fxp(val, True, BW_px, fr_px, overflow = 'wrap')
                        # Check pos
                        pos = int(res[1])
                        if (not pos == f*Tiy*Tix + y*Tiy + x):
                            input("Error: expected " + str(f*Tiy*Tix + y*Tiy + x) + ", obtained " + str(pos))
#Compare fmi
for f in range(0, Nif):
    for y in range(0, Niy):
        for x in range(0, Nix):
            if (not fmi[f][y][x] == fmi_obtained[f][y][x]):
                input("Error: expected " + str(fmi[f][y][x]) + ", obtained " + str(fmi_obtained[f][y][x]))

# B : Fill KEX
with open("kex.txt", "r") as file1:
    for f in range(0, Nif*t):
        for y in range(0, Ngr):
            for x in range(0, Nnp):
                line = file1.readline().split('\n')[0]
                wg = "0x" + line[4:].upper()
                ps = "0x" + line[:4].upper()
                kex_wg [f][y][x] = Fxp(wg, True, BW_px, fr_px, overflow = 'wrap')
                kex_ps [f][y][x] = Fxp(ps, True, BW_px, fr_px, overflow = 'wrap')

with open("result_kexp.txt", "r") as file2:
    for par in range(0, (Nif*t) // Npar):
        for f in range(0, Npar):
            for y in range(0, Ngr):
                for x in range(0, Nnp):
                    res = file2.readline().split(':')
                    wg = "0x" + res[0].upper()
                    ps = "0x" + res[1].upper()
                    pos = int(res[2].split("\n")[0].upper())
                    kex_wg_obtained[f + par * Npar][y][x] = Fxp(wg, True, BW_wg, fr_wg, overflow = 'wrap')
                    kex_ps_obtained[f + par * Npar][y][x] = Fxp(ps, True, BW_wg, fr_wg, overflow = 'wrap')
                    # Check pos
                    if (not pos == f*Ngr*Nnp + y*Nnp + x):
                        input("Error: expected " + str(f*Ngr*Nnp + y*Nnp + x) + ", obtained " + str(pos))

for f in range(0, Nif*t):
    for y in range(0, Ngr):
        for x in range(0, Nnp):
            if (not kex_wg[f][y][x] == kex_wg_obtained[f][y][x]):
                input("Error: expected " + str(kex_wg[f][y][x]) + ", obtained " + str(kex_wg_obtained[f][y][x]))
            if (not kex_ps[f][y][x] == kex_ps_obtained[f][y][x]):
                input("Error: expected " + str(kex_ps[f][y][x]) + ", obtained " + str(kex_ps_obtained[f][y][x]))

# C : Fmint
with open("fmint.txt", "r") as file1:
    for f in range(0, Nif*t):
        for y in range(0, Niy):
            for x in range(0, Nix):
                line = "0x" + file1.readline().split('\n')[0].upper()
                fmint[f][y][x] = Fxp(line, True, BW_px, fr_px, overflow = 'wrap')

with open("result_fmo.txt", "r") as file2:
    for f in range(0, Nif*t):
        for y in range(0, Niy):
            for x in range(0, Nix):
                res = file2.readline().split(':')
                val = "0x" + res[0].upper()
                add = int(res[1])
                add_c = add % (Niy * Nix)

                add_x = add_c % Niy
                add_y = add_c // Niy
                add_f = add // (Niy * Nix)
                fmint_obtained[add_f][add_y][add_x] = Fxp(val, True, BW_px, fr_px, overflow = 'wrap')

#Compare fmi
for f in range(0, Nif*t):
    for y in range(0, Niy):
        for x in range(0, Nix):
            if (abs(fmint[f][y][x]() - fmint_obtained[f][y][x]()) > 0.1):
                print(f)
                print(y)
                print(x)
                input("Error: expected " + str(fmint[f][y][x]) + ", obtained " + str(fmint_obtained[f][y][x]))
