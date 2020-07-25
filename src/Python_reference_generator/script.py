import random
from fxpmath import Fxp
BW_px = 16
BW_wg = 16
fr_px = 12
fr_wg = 12

a = Fxp(random.gauss(0, 1), True, BW_px, fr_px, overflow = 'wrap')
b = Fxp(random.gauss(0, 1), True, BW_wg, fr_wg, overflow = 'wrap')
c = Fxp(a() * b(), True, BW_px, fr_px, overflow = 'wrap')
print(a.hex())
print(b.hex())
print(c.hex())
