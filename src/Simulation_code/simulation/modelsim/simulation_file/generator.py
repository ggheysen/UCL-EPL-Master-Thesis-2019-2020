Nix = 8
Niy = 8
Nif = 8
Nof = 8
Npar = 4
Nnp = 2
Tix = 4
Tiy = 4
tix = 0
tiy = 0
par = 4
parint = 22
S = 0
t = 6
Ngr = Nif//Npar
Ngrint = (Nif * t) // Npar
off_fmi = 2 * 2**20
off_fmo = 24 * 2**20
off_kex = 46 * 2**20
off_kpw = 66 * 2**20
off_kdw = 84 * 2**20

with open("inf_conv.txt", "w") as f:
    stri = (S << 19) + (t << 16) + (Niy << 8) + (Nix)
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
    stri = ""
    prnt = False
    for i in range (0, (Nix * Niy * Nif) + 1):
        stri = ((4 - len(hex(i)[2:])) * '0') + hex(i)[2:] + stri
        if (i + 1 % Tix == 0):
            f.write(stri + "\n")
            stri = ""
            prnt = False
        elif (prnt):
            f.write(stri + "\n")
            stri = ""
            prnt = False
        else:
            prnt = True

with open("kexp.txt", "w") as f:
    stri = ""
    prnt = False
    pos = 0
    for i in range (0, (Ngr * Nnp * t * Nif) + 1):
        stri = (pos << 16) + i
        stri = ('0' * (8 - len(hex(stri)[2:])))+ hex(stri)[2:]
        f.write(stri + "\n")
        pos = (pos + 1) % Npar

with open("kpw.txt", "w") as f:
    stri = ""
    prnt = False
    pos = 0
    for i in range (0, (Ngrint * Nnp * Nof) + 1):
        stri = (pos << 16) + i
        stri = ('0' * (8 - len(hex(stri)[2:])))+ hex(stri)[2:]
        f.write(stri + "\n")
        pos = (pos + 1) % Npar



with open("res_fmi.txt", "w") as file:
    for f in range(0, Nif):
        for y in range(tiy,tiy+Tiy):
            for x in range(tix,tix+Tix):
                file.write(str(x + y*Nix + f*Nix*Niy) + "\n")

with open("res_kexp.txt", "w") as file:
    for x in range(par, par + Npar):
        for f in range(0, Ngr * Nnp):
            file.write(str(x * Ngr * Nnp + f) + "\n")

with open("res_kpw.txt", "w") as file:
    for x in range(0, Nof):
        for f in range(parint, parint + Nnp):
            file.write(str(x * Ngrint * Nnp + f) + "\n")
