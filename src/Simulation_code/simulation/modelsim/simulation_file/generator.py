from fxpmath import Fxp
import random
import math
# Size of the volumes
Nix = 28
Niy = 28
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
#
fmi     = [[[Fxp(random.randint(0, 255)/255, True, BW_px, fr_px, overflow = 'wrap')  for _ in range(Nix)] for _ in range(Niy)] for _ in range(Nif)]
kex_wg  = [[[Fxp(random.gauss(0, 1), True, BW_wg, fr_wg, overflow = 'wrap')          for _ in range(Nnp)] for _ in range(Ngr)] for _ in range(Nif * t)]
kex_pos = [[[Fxp(random.randint(i*(Npar//Nnp), (i+1)*(Npar//Nnp)), False, BW_pos, 0) for i in range(Nnp)] for _ in range(Ngr)] for _ in range(Nif * t)]
fmint   = [[[Fxp(0, True, BW_px, fr_px, overflow = 'wrap')                           for _ in range(Nix)] for _ in range(Niy)] for _ in range(Nif * t)]

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

with open("fmi.txt", "w") as fifi:
    for f in range (0,  Nif):
        for y in range (0, Niy):
            for x in range (0, Nix):
                stri = fmi[f][y][x]
                stri = ('0' * (8 - len(stri.hex()[2:])))+ stri.hex()[2:]
                fifi.write(stri + "\n")

with open("kex.txt", "w") as fifi:
    for f in range (0,  Nif*t):
        for y in range (0, Ngr):
            for x in range (0, Nnp):
                stri1 = kex_wg[f][y][x]
                stri2 = kex_pos[f][y][x]
                stri = ('0' * (4 - len(stri2.hex()[2:]))) + stri2.hex()[2:] + ('0' * (4 - len(stri1.hex()[2:]))) + stri1.hex()[2:]
                fifi.write(stri + "\n")

with open("fmint.txt", "w") as fifi:
    for fo in range (0,  Nif*t):
        for yo in range(0, Niy):
            for xo in range(0, Nix):
                px = Fxp(0, True, BW_px, fr_px, overflow = 'wrap')
                for gr in range(0, Ngr):
                    for np in range(0, Nnp):
                        pos = kex_pos[fo][gr][np]
                        val = kex_wg[fo][gr][np]
                        pix = fmi[pos() + gr * Npar][yo][xo]
                        px = Fxp(px() + (pix() * val()), True, BW_px, fr_px, overflow = 'wrap')
                px = Fxp(min(max(0, px()), 6), True, BW_px, fr_px, overflow = 'wrap')
                stri = px
                stri = ('0' * (8 - len(stri.hex()[2:])))+ stri.hex()[2:]
                fifi.write(stri + "\n")
