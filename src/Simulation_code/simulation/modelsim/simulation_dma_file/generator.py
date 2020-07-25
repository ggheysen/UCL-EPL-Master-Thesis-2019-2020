# Size of the volumes
Nix = 28
Niy = 28
Nif = 8
Nof = 8
Nkx = 3
Nky = 3
S = 2
t = 6
# Tiling params
Tix = 14
Tiy = 14
Tox = 14
Toy = 14
# Calculated volume
Nox = Nix // S
Noy = Niy // S
# Pruning param
Npar = 4
Nnp = 2
# Calculated parameters related to Pruning
Ngr = Nif//Npar
Ngrint = (Nif * t) // Npar
# Tiles to process
#1: IFM tile
tix = 14
tiy = 14
tox = 0
toy = 0
# Par
par = 36
pargr = 18
# Offset
off_fmi = 2 * 2**20
off_fmo = 4 * 2**20
off_kex = 6 * 2**20
off_kpw = 26 * 2**20
off_kdw = 44 * 2**20

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

with open("fmi.txt", "w") as f:
    for i in range (0, (Nix * Niy * Nif)):
        stri = i
        stri = ('0' * (8 - len(hex(stri)[2:])))+ hex(stri)[2:]
        f.write(stri + "\n")

with open("kexp.txt", "w") as f:
    pos = 0
    for i in range (0, (Ngr * Nnp * t * Nif)):
        stri = (pos << 16) + i
        stri = ('0' * (8 - len(hex(stri)[2:])))+ hex(stri)[2:]
        f.write(stri + "\n")
        pos = (pos + 1) % Npar

with open("kpw.txt", "w") as f:
    pos = 0
    for i in range (0, (Ngrint * Nnp * Nof) ):
        stri = (pos << 16) + i
        stri = ('0' * (8 - len(hex(stri)[2:])))+ hex(stri)[2:]
        f.write(stri + "\n")
        pos = (pos + 1) % Npar

with open("kdw.txt", "w") as f:
    for i in range (0, Nif * t * Nkx * Nky):
        stri = i
        stri = ('0' * (8 - len(hex(stri)[2:])))+ hex(stri)[2:]
        f.write(stri + "\n")

# Generate what to compare

with open("res_fmi.txt", "w") as file:
    for f in range(0, Nif):
        for y in range(tiy,tiy+Tiy):
            for x in range(tix,tix+Tix):
                file.write(str(x + y*Nix + f*Nix*Niy) + "\n")

with open("res_kexp.txt", "w") as file:
    for x in range(par, par + Npar):
        for f in range(0, Ngr * Nnp):
            file.write(str(x * Ngr * Nnp + f) + " : " + str((x * Ngr * Nnp + f) % 4)  + "\n")

with open("res_kpw.txt", "w") as file:
    for x in range(0, Nof):
        for f in range(pargr, pargr + Nnp):
            file.write(str(x * Ngrint * Nnp + f) + " : " + str((x * Ngrint * Nnp + f) % 4)  + "\n")

with open("res_kdw.txt", "w") as file:
    for f in range(par, par + Npar):
        for y in range(0, Nky):
            for x in range(0, Nkx):
                file.write(str(x + y*Nkx + f*Nkx*Nky) + "\n")

with open("res_fmo.txt", "w") as file:
    for f in range(0, Nof):
        for y in range(toy, toy + (Toy // S)):
            for x in range(tox, tox + (Tox // S)):
                file.write(str(x + y*Nox + f*Nox*Noy) + "\n")
