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
Npar = 2
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
#
fmi     = [[[Fxp(random.randint(0, 255)/255, True, BW_px, fr_px, overflow = 'wrap')  for _ in range(Nix)] for _ in range(Niy)] for _ in range(Nif)]

fmo_res = [[[Fxp(0, True, BW_px, fr_px, overflow = 'wrap')                           for _ in range(Nox)] for _ in range(Noy)] for _ in range(Nof)]

kex_wg  = [[[Fxp(random.gauss(0, 1), True, BW_wg, fr_wg, overflow = 'wrap')          for _ in range(Nnp)] for _ in range(Ngr)] for _ in range(Nif * t)]
kex_pos = [[[Fxp(random.randint(i*(Npar//Nnp), (i+1)*(Npar//Nnp)), False, BW_pos, 0) for i in range(Nnp)] for _ in range(Ngr)] for _ in range(Nif * t)]

kdw_wg  = [[[Fxp(random.gauss(0, 1), True, BW_wg, fr_wg, overflow = 'wrap')          for _ in range(Nkx)] for _ in range(Nkx)] for _ in range(Nif * t)]

kpw_wg  = [[[Fxp(random.gauss(0, 1), True, BW_wg, fr_wg, overflow = 'wrap')          for _ in range(Nnp)] for _ in range(Ngrint)] for _ in range(Nof)]
kpw_pos = [[[Fxp(random.randint(i*(Npar//Nnp), (i+1)*(Npar//Nnp)), False, BW_pos, 0) for i in range(Nnp)] for _ in range(Ngrint)] for _ in range(Nof)]

# Generate folders

if (os.path.isdir("Tile")):
    shutil.rmtree("Tile")
os.mkdir("Tile")
os.mkdir("Tile/fmi_tile")
os.mkdir("Tile/kex_tile")
os.mkdir("Tile/kdw_tile")
os.mkdir("Tile/kpw_tile")
os.mkdir("Tile/fmint_tile")
os.mkdir("Tile/fmo_tile")
os.mkdir("Tile/conv_kdw_tile")

# Generate content

with open("inf_conv.txt", "w") as f:
    stri = ((S-1) << 19) + (t << 16) + (Niy << 8) + (Nix)
    stri = ('0' * (8 - len(hex(stri)[2:])))+ hex(stri)[2:]
    f.write(stri + "\n")
    stri =  (Nof << 12) + (Nif)
    stri = ('0' * (8 - len(hex(stri)[2:]))) + hex(stri)[2:]
    f.write(stri + "\n")
    stri =  (Ngrint << 12) + (Ngr)
    stri = ('0' * (8 - len(hex(stri)[2:]))) + hex(stri)[2:]
    f.write(stri + "\n")
    stri = off_fmi
    stri = ('0' * (8 - len(hex(stri)[2:])))+ hex(stri)[2:]
    f.write(stri + "\n")
    stri = off_fmo
    stri = ('0' * (8 - len(hex(stri)[2:])))+ hex(stri)[2:]
    f.write(stri + "\n")
    stri = off_kex
    stri = ('0' * (8 - len(hex(stri)[2:])))+ hex(stri)[2:]
    f.write(stri + "\n")
    stri = off_kpw
    stri = ('0' * (8 - len(hex(stri)[2:])))+ hex(stri)[2:]
    f.write(stri + "\n")
    stri = off_kdw
    stri = ('0' * (8 - len(hex(stri)[2:])))+ hex(stri)[2:]
    f.write(stri + "\n")

# Create FMI & FMI Tile for verification

with open("fmi.txt", "w") as fifi:
    for f in range (0,  Nif):
        for y in range (0, Niy):
            for x in range (0, Nix):
                stri = fmi[f][y][x]
                stri = ('0' * (8 - len(stri.hex()[2:])))+ stri.hex()[2:]
                fifi.write(stri + "\n")

for ty in range(0, Noy//Toy):
    for tx in range(0, Nox//Tox):
        with open("Tile/fmi_tile/fmi_tile_" + str((ty*(Nox//Tox)) + tx) + ".txt", "w") as fifi:
            for f in range(0, Nif):
                for y in range(0, Tiy):
                    for x in range(0, Tix):
                        if ((ty * Toy + y == 0) | (ty * Toy + y > Niy) | (tx * Tox + x == 0) | (tx * Tox + x > Nix)):
                            stri = Fxp(0, True, BW_px, fr_px, overflow = 'wrap')
                        else:
                            stri = fmi[f][ty * Toy + y - 1][tx * Tox + x - 1]
                        stri = ('0' * (8 - len(stri.hex()[2:])))+ stri.hex()[2:]
                        stri = stri + " : " + str(f*Tix*Tiy + y * Tiy + x)
                        fifi.write(stri + "\n")

# Create Kex and the Tile (Npar)

with open("kex.txt", "w") as fifi:
    for f in range (0,  Nif*t):
        for y in range (0, Ngr):
            for x in range (0, Nnp):
                stri1 = kex_wg[f][y][x]
                stri2 = kex_pos[f][y][x]
                stri = ('0' * (4 - len(stri2.hex()[2:]))) + stri2.hex()[2:] + ('0' * (4 - len(stri1.hex()[2:]))) + stri1.hex()[2:]
                fifi.write(stri + "\n")

for par in range(0, t*Nif, Npar):
    with open("Tile/kex_tile/kex_tile_" + str(par//Npar) + ".txt", "w") as fifi:
        for f in range(0, Npar):
            for gr in range(0, Ngr):
                for wg in range(0, Nnp):
                    stri1 = kex_wg[f + par][gr][wg]
                    stri2 = kex_pos[f + par][gr][wg]
                    stri = ('0' * (4 - len(stri2.hex()[2:]))) + stri2.hex()[2:] + ('0' * (4 - len(stri1.hex()[2:]))) + stri1.hex()[2:]
                    stri = stri + " : " + str(f*Ngr*Nnp + gr * Nnp + wg)
                    fifi.write(stri + "\n")

# Create KDW and the Tile (Npar)

with open("kdw.txt", "w") as fifi:
    for f in range (0,  Nif*t):
        for y in range (0, Nky):
            for x in range (0, Nkx):
                stri = kdw_wg[f][y][x]
                stri = ('0' * (8 - len(stri.hex()[2:])))+ stri.hex()[2:]
                fifi.write(stri + "\n")

for par in range(0, t*Nif, Npar):
    with open("Tile/kdw_tile/kdw_tile_" + str(par//Npar) + ".txt", "w") as fifi:
        for f in range(0, Npar):
            for y in range(0, Nky):
                for x in range(0, Nkx):
                    stri = kdw_wg[f + par][y][x]
                    stri = ('0' * (8 - len(stri.hex()[2:])))+ stri.hex()[2:]
                    stri = stri + " : " + str(f*Nkx*Nky + y * Nkx + x)
                    fifi.write(stri + "\n")

# Create KPW and the Tile (Npar)

with open("kpw.txt", "w") as fifi:
    for f in range (0,  Nof):
        for y in range (0, Ngrint):
            for x in range (0, Nnp):
                stri1 = kpw_wg[f][y][x]
                stri2 = kpw_pos[f][y][x]
                stri = ('0' * (4 - len(stri2.hex()[2:]))) + stri2.hex()[2:] + ('0' * (4 - len(stri1.hex()[2:]))) + stri1.hex()[2:]
                fifi.write(stri + "\n")

for gr in range(0, Ngrint):
    with open("Tile/kpw_tile/kpw_tile_" + str(gr) + ".txt", "w") as fifi:
        for f in range(0, Nof):
            for x in range(0, Nnp):
                    stri1 = kpw_wg[f][gr][x]
                    stri2 = kpw_pos[f][gr][x]
                    stri = ('0' * (4 - len(stri2.hex()[2:]))) + stri2.hex()[2:] + ('0' * (4 - len(stri1.hex()[2:]))) + stri1.hex()[2:]
                    stri = stri + " : " + str(f*Nnp + x)
                    fifi.write(stri + "\n")

# Obtain the intermediate results
for ty in range(0, Noy//Toy):
    for tx in range(0, Nox//Tox):
        #1: Compute FMO each Tile
        fmo   = [[[Fxp(0, True, BW_px, fr_px, overflow = 'wrap') for _ in range(Tox)] for _ in range(Toy)] for _ in range(Nof)]
        for par in range(0, t*Nif, Npar):
            # For each (int) group we compute the FMint
            fmint = [[[Fxp(0, True, BW_px, fr_px, overflow = 'wrap') for _ in range(Tix)] for _ in range(Tiy)] for _ in range(Npar)]
            for f in range(0, Npar):
                for y in range(0, Tiy):
                    for x in range(0, Tix):
                        px = Fxp(0, True, BW_px, fr_px, overflow = 'wrap')
                        for gr in range(0, Ngr):
                            for np in range(0,Nnp):
                                pos = kex_pos[f + par][gr][np]
                                val = kex_wg [f + par][gr][np]
                                if ((ty * Toy + y == 0) | (ty * Toy + y > Niy) | (tx * Tox + x == 0) | (tx * Tox + x > Nix)):
                                    pix = Fxp(0, True, BW_px, fr_px, overflow = 'wrap')
                                else:
                                    pix = fmi[pos() + gr * Npar][ty * Toy + y - 1][tx * Tox + x - 1]
                                px = Fxp(px() + (pix() * val()), True, BW_px, fr_px, overflow = 'wrap')
                        px = Fxp(min(max(0, px()), 6), True, BW_px, fr_px, overflow = 'wrap')
                        fmint[f][y][x] = px
            #Write results
            with open("Tile/fmint_tile/fmint_tile_ " + str((ty*(Nox//Tox)) + tx) + "_par_" + str(par//Npar)  + ".txt", "w") as fifi:
                for f in range(0, Npar):
                    for y in range(0, Tiy):
                        for x in range(0, Tix):
                            stri = fmint[f][y][x]
                            stri = ('0' * (8 - len(stri.hex()[2:])))+ stri.hex()[2:]
                            stri = stri + " : " + str(f*Tix*Tiy + y * Tiy + x)
                            fifi.write(stri + "\n")

            # Now compute the FMO (intermediate or final)
            for y in range(0, Toy):
                for x in range(0, Tox):
                    DW_res = [Fxp(0, True, BW_px, fr_px, overflow = 'wrap') for _ in range(Npar)]
                    # DW conv
                    for ch in range(0, Npar):
                        for ky in range(0, Nky):
                            for kx in range(0, Nkx):
                                wg = kdw_wg[ch + par][ky][kx]
                                px = fmint[ch][y*S + ky][x*S + kx]
                                DW_res[ch] = Fxp(DW_res[ch]() + (wg() * px()), True, BW_px, fr_px, overflow = 'wrap')
                        DW_res[ch] = Fxp(max(0, min(DW_res[ch](), 6)), True, BW_px, fr_px, overflow = 'wrap')
                    #Save for debug
                    with open("Tile/conv_kdw_tile/dw_conv_ " + str((ty*(Nox//Tox)) + tx) + "_par_" + str(par//Npar) + "_x_" + str(x) + "_y_" + str(y)  + ".txt", "w") as fifi:
                        for ch in range(0, Npar):
                            fifi.write(DW_res[ch].hex() + "\n")

                    #PW conv
                    for f in range(0, Nof):
                        for np in range(Nnp):
                            pos = kpw_pos[f][par//Npar][np]
                            val = kpw_wg [f][par//Npar][np]
                            px = DW_res[pos()]
                            fmo[f][y][x] = Fxp(fmo[f][y][x]() + (val() * px()), True, BW_px, fr_px, overflow = 'wrap')
                            fmo_res[f][y + ty * Toy][x + tx * Tox] = fmo[f][y][x]
            #Write results
            with open("Tile/fmo_tile/fmo_tile_ " + str((ty*(Nox//Tox)) + tx) + "_par_" + str(par//Npar)  + ".txt", "w") as fifi:
                for f in range(0, Nof):
                    for y in range(0, Toy):
                        for x in range(0, Tox):
                            stri = fmo[f][y][x]
                            stri = ('0' * (8 - len(stri.hex()[2:])))+ stri.hex()[2:]
                            stri = stri + " : " + str(f*Tox*Toy + y * Toy + x)
                            fifi.write(stri + "\n")

# Write FMO
with open("fmo.txt", "w") as fifi:
    for f in range (0,  Nof):
        for y in range (0, Noy):
            for x in range (0, Nox):
                stri = fmo_res[f][y][x]
                stri = ('0' * (8 - len(stri.hex()[2:])))+ stri.hex()[2:]
                fifi.write(stri + "\n")
