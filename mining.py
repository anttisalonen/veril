#!/usr/bin/env python3

import datetime
import fixedint
import hashlib

# correct: 0x013817dd
stratum_mining_parameters = dict()
stratum_mining_parameters['extranonce1'] = '20000024'
stratum_mining_parameters['extranonce2_size'] = 4
stratum_mining_parameters['diff'] = 0
stratum_mining_parameters['prevhash'] = '23291b066f70a02b9a75b341dafc2fa8ebe247c9827956bbab00000000000000'
stratum_mining_parameters['coinb1'] = '01000000010000000000000000000000000000000000000000000000000000000000000000ffffffff2503a0921504026e486008'
stratum_mining_parameters['coinb2'] = '122f626974636f696e636c6f75642e6e65742f0000000002062c9c04000000001976a91423e020eacd64acfe093150331d44fdbcc0c7ce0688acc2eb0b00000000001976a91400bf6d61c2a34df5a9ea338fcad188c31bb4a52388ac00000000'
stratum_mining_parameters['merkle_branches'] = []
stratum_mining_parameters['version'] = '00000002'
stratum_mining_parameters['nbits'] = 'fb39031a'
stratum_mining_parameters['ntime'] = '216e4860'

# correct: 0xb2957c02
docs_mining_parameters = dict()
docs_mining_parameters['extranonce1'] = '08000002'
docs_mining_parameters['extranonce2_size'] = 4
docs_mining_parameters['diff'] = 0
docs_mining_parameters['prevhash'] = '4d16b6f85af6e2198f44ae2a6de67f78487ae5611b77c6c0440b921e00000000'
docs_mining_parameters['coinb1'] = '01000000010000000000000000000000000000000000000000000000000000000000000000ffffffff20020862062f503253482f04b8864e5008'
docs_mining_parameters['coinb2'] = '072f736c7573682f000000000100f2052a010000001976a914d23fcdf86f7e756a64a7a9688ef9903327048ed988ac00000000'
docs_mining_parameters['merkle_branches'] = []
docs_mining_parameters['version'] = '00000002'
docs_mining_parameters['nbits'] = '1c2ac4af'
docs_mining_parameters['ntime'] = '504e86ed'

# correct: d0cf1040
kap_mining_parameters = dict()
kap_mining_parameters['extranonce1'] = '40000004'
kap_mining_parameters['extranonce2_size'] = 4
kap_mining_parameters['diff'] = 0
kap_mining_parameters['prevhash'] = '4128bf630f57387b00e25b419d1bb77e667e4036a7d8fee80000015600000000'
kap_mining_parameters['coinb1'] = '01000000010000000000000000000000000000000000000000000000000000000000000000ffffffff2503a77614048c8a145e08'
kap_mining_parameters['coinb2'] = '122f626974636f696e636c6f75642e6e65742f0000000002062c9c04000000001976a91423e020eacd64acfe093150331d44fdbcc0c7ce0688acc2eb0b00000000001976a91400bf6d61c2a34df5a9ea338fcad188c31bb4a52388ac00000000'
kap_mining_parameters['merkle_branches'] = []
kap_mining_parameters['version'] = '20000000'
kap_mining_parameters['nbits'] = '1a02b098'
kap_mining_parameters['ntime'] = '5e148a8c'

mining_parameters = kap_mining_parameters

def doubleSHA256(data):
    h1 = hashlib.sha256()
    h1.update(data)
    inter = h1.digest()
    h2 = hashlib.sha256()
    h2.update(inter)
    return h2.digest()

def getMerkleRoot(branches, coinbase):
    merkle_root = bytes(coinbase)
    for branch in branches:
        merkle_root.append(bytes.fromhex(branch))
        merkle_root = doubleSHA256(merkle_root)
    return merkle_root.hex()

def split_list(l, howmany):
    return [l[i:i + howmany] for i in range(0, len(l), howmany)]

# string to string
# flip endianness
def flipIntBytes(inp):
    inps = split_list(inp, 8)
    res = list()
    for l in inps:
        l2 = split_list(l, 2)
        l2.reverse()
        res.append(''.join(l2))
    return ''.join([item for sublist in res for item in sublist])

def revByteOrder(data):
    l2 = split_list(data, 2)
    l2.reverse()
    return ''.join(l2)

def main():
    for extranon2 in range(0xffff):
        extranon2 = 0
        extranonce2 = '%08x' % extranon2
        assert(len(extranonce2) == mining_parameters['extranonce2_size'] * 2)
        print("%s - Extranonce2: %08x" % (datetime.datetime.now(), extranon2))
        coinbase = mining_parameters['coinb1'] + mining_parameters['extranonce1'] + extranonce2 + mining_parameters['coinb2']
        coinbase_hash_bin = doubleSHA256(bytes.fromhex(coinbase))
        merkle_root = getMerkleRoot(mining_parameters['merkle_branches'], coinbase_hash_bin)
        nonce = "00000000"
        headerWithoutPadding = flipIntBytes(mining_parameters['version'] + mining_parameters['prevhash'] + flipIntBytes(merkle_root) + mining_parameters['ntime'] + mining_parameters['nbits'] + nonce)
        header = headerWithoutPadding # + "800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000280"
        header1 = header[:128]
        header2 = header[128:]
        #print("Header without padding: %s" % headerWithoutPadding)
        #assert(len(header) == 256)
        #(_, state, _) = sha256(bytes.fromhex(header1))
        #res = doSha(state, header2, mining_parameters['diff'])
        res = doSha(header, mining_parameters['diff'])
        if res:
            print(res)
            break

def doSha(data, diff):
    # TODO use diff
    target = '0000000fffff0000000000000000000000000000000000000000000000000000'
    target_hex = bytes.fromhex(target)
    for nonce in range(0xd0c00000, 0xffffffff):
        noncestr = '%08x' % nonce
        this_data = data[:152] + noncestr + data[160:]
        res = doubleSHA256(bytes.fromhex(this_data))
        found = False
        for i in range(len(res)):
            if res[31 - i] > target_hex[i]:
                break
            if res[31 - i] < target_hex[i]:
                found = True
                return revByteOrder(res.hex()), '0x' + '%08x' % nonce

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

if __name__ == '__main__':
    main()
    #inp = "0000002063bf28417b38570f415be2007eb71b9d36407e66e8fed8a756010000000000009b9c9ab0b1c92844e4fed3f895f9443fefcda5ae02cc5a8ad4444f93"
    #(_, state, _) = sha256(bytes.fromhex(inp))
    #for s in state:
    #    print("%08x" % s)



