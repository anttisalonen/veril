import fixedint

def rotright(a, b):
    return fixedint.UInt32(a) >> b | (fixedint.UInt32(a) << (32 - b))

def ch(x, y, z):
    return fixedint.UInt32(((x) & (y)) ^ (~fixedint.UInt32(x) & (z)))

def maj(x, y, z):
    return fixedint.UInt32(((x) & (y)) ^ ((x) & (z)) ^ ((y) & (z)))

def ep0(x):
    return rotright(x, 2) ^ rotright(x,13) ^ rotright(x,22)

def ep1(x):
    return rotright(x, 6) ^ rotright(x, 11) ^ rotright(x,25)

def sig0(x):
    return rotright(x, 7) ^ rotright(x, 18) ^ (fixedint.UInt32(x) >> 3)

def sig1(x):
    return rotright(x, 17) ^ rotright(x, 19) ^ (fixedint.UInt32(x) >> 10)


k = [
    0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
    0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
    0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
    0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
    0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
    0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
    0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
    0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2
]

# state: [UInt32]
# data: [UInt8]
def sha256_transform(state, data):
    m = [0] * 64
    j = 0
    for i in range(16):
        m1 = data[j + 3]
        m2 = data[j + 2] << 8
        m3 = data[j + 1] << 16
        m4 = data[j + 0] << 24
        m[i] = m1 | m2 | m3 | m4
        j += 4
 
    for i in range(16, 64):
        m[i] = (fixedint.UInt32(sig1(m[i - 2])) + fixedint.UInt32(m[i - 7]) + fixedint.UInt32(sig0(m[i - 15])) + fixedint.UInt32(m[i - 16]))

    a = state[0]
    b = state[1]
    c = state[2]
    d = state[3]
    e = state[4]
    f = state[5]
    g = state[6]
    h = state[7]
    
    for i in range(64):
        t1 = (fixedint.UInt32(h) + fixedint.UInt32(ep1(e)) + fixedint.UInt32(ch(e, f, g)) + fixedint.UInt32(k[i]) + fixedint.UInt32(m[i]))
        t2 = (fixedint.UInt32(ep0(a)) + fixedint.UInt32(maj(a, b, c)))
        h = g
        g = f
        f = e
        e = (fixedint.UInt32(d) + fixedint.UInt32(t1))
        d = c
        c = b
        b = a
        a = (fixedint.UInt32(t1) + fixedint.UInt32(t2))
    
    return [(fixedint.UInt32(state[0]) + fixedint.UInt32(a)),
    (fixedint.UInt32(state[1]) + fixedint.UInt32(b)),
    (fixedint.UInt32(state[2]) + fixedint.UInt32(c)),
    (fixedint.UInt32(state[3]) + fixedint.UInt32(d)),
    (fixedint.UInt32(state[4]) + fixedint.UInt32(e)),
    (fixedint.UInt32(state[5]) + fixedint.UInt32(f)),
    (fixedint.UInt32(state[6]) + fixedint.UInt32(g)),
    (fixedint.UInt32(state[7]) + fixedint.UInt32(h))]

# inp: [UInt8]
def sha256(inp):
    state = [
        0x6a09e667,
        0xbb67ae85,
        0x3c6ef372,
        0xa54ff53a,
        0x510e527f,
        0x9b05688c,
        0x1f83d9ab,
        0x5be0cd19,
    ]
    datalen = 0
    bitlen = 0
    data = [0] * 64
    for i in range(len(inp)):
        data[datalen] = inp[i]
        datalen += 1
        if datalen == 64:
            state = sha256_transform(state, data)
            bitlen += 512
            datalen = 0
    
    it = datalen
    if datalen < 56:
        data[it] = 0x80
        it += 1
        while it < 56:
            data[it] = 0x00
            it += 1
    else:
        data[it] = 0x80
        it += 1
        while it < 64:
            data[it] = 0x00
            it += 1
        state = sha256_transform(state, data)
        for i in range(56):
            data[i] = 0
    penultimate_state = state
    
    bitlen = bitlen + datalen * 8
    data[63] = (bitlen & 0xff)
    data[62] = ((bitlen >> 8) & 0xff)
    data[61] = ((bitlen >> 16) & 0xff)
    data[60] = ((bitlen >> 24) & 0xff)
    data[59] = ((bitlen >> 32) & 0xff)
    data[58] = ((bitlen >> 40) & 0xff)
    data[57] = ((bitlen >> 48) & 0xff)
    data[56] = ((bitlen >> 56) & 0xff)
    state = sha256_transform(state, data)
    
    result = [0] * 32
    for i in range(4):
        result[i]      = ((state[0] >> (24 - i * 8)) & 0x000000ff)
        result[i + 4]  = ((state[1] >> (24 - i * 8)) & 0x000000ff)
        result[i + 8]  = ((state[2] >> (24 - i * 8)) & 0x000000ff)
        result[i + 12] = ((state[3] >> (24 - i * 8)) & 0x000000ff)
        result[i + 16] = ((state[4] >> (24 - i * 8)) & 0x000000ff)
        result[i + 20] = ((state[5] >> (24 - i * 8)) & 0x000000ff)
        result[i + 24] = ((state[6] >> (24 - i * 8)) & 0x000000ff)
        result[i + 28] = ((state[7] >> (24 - i * 8)) & 0x000000ff)
    return (result, penultimate_state, bitlen)


