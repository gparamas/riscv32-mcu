import serial
import numpy as np

s = serial.Serial('COM11', 10000000, timeout=1)


code = np.fromfile("main.bin", dtype=np.uint32)
code = np.append(code, [np.uint32(0xFFFFFFFF)])

hex_array_with_prefix = [f"0x{x:08x}" for x in code]

print(hex_array_with_prefix)

for x in code:
    for i in range(4):
        s.write(bytes([(x >> (i * 8)) & 0xFF]))

while True:
    data = s.readline(1)
    if(data):
        print(data.hex())
    else:
        print("nothing received")