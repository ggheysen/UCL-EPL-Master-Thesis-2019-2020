from fxpmath import Fxp
import random
import math

Nix = 28
Niy = 28
Nif = 8
Nof = 8
Nkx = 3
Nky = 3
BW_px = 16
BW_wg = 16
fr_px = 12
fr_wg = 12
fmi             = [[[ 0 for _ in range(Nix)] for _ in range(Niy)] for _ in range(Nif)]
with open("fmi.txt", "r") as file1:
    for f in range(0, Nif):
        for y in range(0, Niy):
            for x in range(0, Nix):
                line = "0x" + file1.readline().split('\n')[0].upper()
                fmi[f][y][x] = Fxp(line, True, BW_px, fr_px, overflow = 'wrap')

for f in range(0, Nif):
    for y in range(13, 29):
        for x in range(13, 29):
            if((y == Niy) | (x == Nix)):
                print("0000")
            else:
                print(fmi[f][y][x].hex())
