 #!/usr/bin/env python

""" Python code generating a .txt reference for the output of the simulated layer """

###############################################################################
#                                   IMPORT                                    #
###############################################################################

import os
import random
import math
from datetime import datetime
from fxpmath import Fxp

###############################################################################
#                          Authorship information                             #
###############################################################################

__author__ = "Guillaume Gheysen"

###############################################################################
#                          Global parameters                                  #
###############################################################################

# 1: Bitwidth
BW_px = 16
BW_wg = 16
fr_px = 12
fr_wg = 12
# 2: Network & Tiling parameters
S   = 1
t   = 6
Nix = 14
Niy = 14
Nif = 160
Nof = 320
Nox = Nix // S
Noy = Niy // S
Nkx = 3
Nky = 3
Tix = 7
Tiy = 7
Tif = 160
Tox = Tix // S
Toy = Tiy // S
# 3: pruning parameters
Npar   = 8
Nnp    = 2
BW_pos = math.ceil(math.log2(Npar))
# 4: File name
fmi_txt         = "FM_I.txt"
filter_ex_txt   = "filter_ex.txt"
filter_dw_txt   = "filter_dw.txt"
filter_pw_txt   = "filter_pw.txt"
fmo_txt         = "FM_O.txt"

###############################################################################
#                          Main functions                                     #
###############################################################################

def main():
    # 0: Handle the paths & file
    now = datetime.now()
    path = os.getcwd()
    top_dir  = os.path.join(path, 'references')
    if not os.path.isdir(top_dir):
        os.mkdir(top_dir)
    dir  = os.path.join(top_dir, now.strftime("%d%m%Y_%H%M%S"))
    os.mkdir(dir)
    print("Folders created")
    # 1: Create the input FM & Write ut
    fmi = FM_generator()
    fmi_file = os.path.join(dir, fmi_txt)
    Write_vol(fmi, fmi_file)
    print("FM input created")
    # 2: Create the kernels - pw and dw
    filter_ex = Filter_11_generator(Nif, t*Nif)
    filter_ex_file = os.path.join(dir, filter_ex_txt)
    Write_vol(filter_ex, filter_ex_file)
    print("Filter expansion created")
    #
    filter_dw = Filter_dw_generator()
    filter_dw_file = os.path.join(dir, filter_dw_txt)
    Write_vol(filter_dw, filter_dw_file)
    print("Filter DW created")
    #
    filter_pw = Filter_11_generator(t*Nif, Nof)
    filter_pw_file = os.path.join(dir, filter_pw_txt)
    Write_vol(filter_dw, filter_pw_file)
    print("Filter PW created")
    # 3: Compute the output FM
    fmo = [[[ Fxp(0, True, BW_px, fr_px, overflow = 'wrap') ] * Nox for _ in range(Noy)] for _ in range(Nof)]
    for g0 in range(0, math.ceil(Nif/Npar)):
        # A: calcul des résultats intérmédiaires
        fmint = exp_conv(g0, fmi, filter_ex)
        print("expan conv done")
        # B: DSC
        dsc(g0, fmint, fmo, filter_dw, filter_pw)
        print(str(g0) + " group done")
    print("Convolution done")
    # 4: write the output
    fmo_file = os.path.join(dir, fmo_txt)
    Write_vol(fmo, fmo_file)
    print("Output written")

###############################################################################
#                          Additional functions                               #
###############################################################################

def exp_conv(g, fmi, k):
    fmint = []
    for of in range(0, Npar):
        layer = []
        for oy in range(0, Niy):
            row = []
            for ox in range(0, Nix):
                px = Fxp(0, True, BW_px, fr_px, overflow = 'wrap')
                for gi in range(0, math.ceil(len(fmi)/Npar)):
                    for np in range(0, Nnp):
                        wg_pos = Fxp(k[g*Npar + of][gi*Nnp + np][1](), True, BW_wg, fr_wg, overflow = 'wrap')
                        wg_val = Fxp(k[g*Npar + of][gi*Nnp + np][0](), True, BW_wg, fr_wg, overflow = 'wrap')
                        fm = Fxp(fmi[wg_pos() + gi*Npar][oy][ox](), True, BW_px, fr_px, overflow = 'wrap')
                        px = Fxp(px() + (fm() * wg_val()), True, BW_px, fr_px, overflow = 'wrap')
                px = Fxp(max(0, 6, px()), True, BW_px, fr_px, overflow = 'wrap')
                row.append(px)
            layer.append(row)
        fmint.append(layer)
    return fmint
###############################################################################
def dsc(g, fmint, fmO, filter_dw, filter_pw):
    for oy in range(0, Niy, S):
        for ox in range(0, Nix, S):
            #DW
            list_px = []
            for ch in range(0, Npar):
                px = Fxp(0, True, BW_px, fr_px, overflow = 'wrap')
                for kx in range(0, Nkx):
                    for ky in range(0, Nky):
                        if ((oy + ky >= Niy) | (ox + kx >= Nix)):
                            fm_px = Fxp(0, True, BW_px, fr_px, overflow = 'wrap')
                        else:
                            fm_px = Fxp(fmint[ch][oy+ky][ox+kx](), True, BW_px, fr_px, overflow = 'wrap')
                        #
                        wg = Fxp(filter_dw[g*Npar + ch][ky][kx](), True, BW_wg, fr_wg, overflow = 'wrap')
                        #
                        px = Fxp(px() + (fm_px()*wg()), True, BW_px, fr_px, overflow = 'wrap')
                px = Fxp(max(0, 6, px()), True, BW_px, fr_px, overflow = 'wrap')
                list_px.append(px)
            #PW
            for of in range(0, Nof):
                for fi in range(0, Nnp):
                    wg_pos = Fxp(filter_pw[of][g*Npar + fi][1](), True, BW_wg, fr_wg, overflow = 'wrap')
                    wg_val = Fxp(filter_pw[of][g*Npar + fi][0](), True, BW_wg, fr_wg, overflow = 'wrap')
                    fm_px = Fxp(list_px[wg_pos()](), True, BW_px, fr_px, overflow = 'wrap')
                    fmO[of][oy][ox] = Fxp(fmO[of][oy][ox]() + (fm_px()*wg_val()), True, BW_px, fr_px, overflow = 'wrap')
###############################################################################
def FM_generator():
    fm = []
    for f in range(0, Nif):
        layer = []
        for y in range(0, Niy):
            row = []
            for x in range(0, Nix):
                row.append(Fxp(random.randint(0, 255)/255, True, BW_px, fr_px, overflow = 'wrap'))
            layer.append(row)
        fm.append(layer)
    return fm
###############################################################################
def Filter_dw_generator():
    filter = []
    for f in range(0, t*Nif):
        kernel = []
        for y in range(0, Nky):
            row = []
            for x in range(0, Nkx):
                row.append(Fxp(random.gauss(0, 1), True, BW_wg, fr_wg, overflow = 'wrap'))
            kernel.append(row)
        filter.append(kernel)
    return filter
###############################################################################
def Filter_11_generator(nif, nof):
    filter = []
    Ngroup = math.ceil(nif/Npar)
    for f in range(0, nof):
        kernel = []
        for g in range(0, Ngroup):
            min = 0
            max = Npar - Nnp
            for np in range(0, Nnp):
                #
                val = Fxp(random.gauss(0, 1), True, BW_wg, fr_wg, overflow = 'wrap')
                pos = Fxp(random.randint(min, max), False, BW_pos, 0)
                min = pos() + 1
                max = max + 1
                kernel.append((val, pos))
        filter.append(kernel)
    return filter
###############################################################################
def Write_vol(vol, path):
    with open(path, 'w') as file:
        for f in range(0, len(vol)):
            for y in range(0, len(vol[f])):
                for x in range(0, len(vol[f][y])):
                    str = vol[f][y][x].hex()
                    if len(str) < 2 + (BW_px // 4):
                        str = str[0:2] + '0'*(2 + (BW_px // 4) - len(str)) + str[2:]
                    file.write(str + "\n")

###############################################################################
#                                 Main code                                   #
###############################################################################

if __name__ == '__main__':
    main()
