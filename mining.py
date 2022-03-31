#!/usr/bin/env python3

import datetime
import fixedint
import hashlib
import serial
import cpusha
import time

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
    merkle_root = coinbase
    for branch in branches:
        merkle_root = doubleSHA256(merkle_root + bytes.fromhex(branch))
    return merkle_root.hex()

def prepState(data):
    d = ['%08x' % n for n in data]
    return prepSerial(''.join(d))

def prepSerial(data):
    d = split_list(data, 8)
    d = [split_list(n, 2) for n in d]
    ret = list()
    for n in d:
        ret.append([int(n2, 16) for n2 in n])
    return ret

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
    do_mining_params(kap_mining_parameters, '0000')

def do_mining_params(params, extranonce2):
    coinbase = params['coinb1'] + params['extranonce1'] + extranonce2 + params['coinb2']
    coinbase_hash_bin = doubleSHA256(bytes.fromhex(coinbase))
    merkle_root = getMerkleRoot(params['merkle_branches'], coinbase_hash_bin)
    nonce = "00000000"
    headerWithoutPadding = flipIntBytes(params['version'] + params['prevhash'] + flipIntBytes(merkle_root) + params['ntime'] + params['nbits'] + nonce)
    header = headerWithoutPadding # + "800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000280"
    header1 = header[:128]
    header2 = header[128:]
    #print("Header without padding: %s" % headerWithoutPadding)
    (_, state, _) = cpusha.sha256(bytes.fromhex(header1))
    res = doSha(state, header2[:24], params['diff'])
    #res = doShaCPU(headerWithoutPadding, params['diff'])
    if res:
        return res
    return None

def doSha(state, header2, diff):
    maxtgt = 0xffff0000
    if diff == 0:
        tgt = int(float(maxtgt) / 0.01)
    else:
        tgt = int(maxtgt / diff)
    tgtn = "00000000%08x000000000000000000000000000000000000000000000000" % tgt
    target_hex = [int(n, 16) for n in split_list(tgtn, 2)]
    target_hex.reverse()
    nonce_base = [0x00, 0x00, 0x00, 0x00]
    found_nonce = shaSerial(header2, state, target_hex, nonce_base)
    if found_nonce is None:
        return False
    else:
        return found_nonce.hex()

serconn = serial.Serial('/dev/ttyS4', 115200)

def serwrite(b):
    #print(b)
    serconn.write(b)

def serreset():
    serconn.close()
    serconn.open()

def serSendUInt(uint):
    for i in range(4):
        serwrite(bytes((uint >> ((3 - i) * 8)) & 0xff))

def shaSerial(input_data, state, target, nonce_base):
    serwrite(b'H')
    x = serconn.read()
    if x != b'1':
        print('Expected 1, got ' + str(x) + ' - retrying')
        serreset()
        serwrite(b'R')
        serconn.read()
        serwrite(b'H')
        x = serconn.read()
        if x != b'1':
            print('Expected 1, got ' + str(x))
            return None

    inp = prepSerial(input_data)
    for inpline in inp:
        inpline.reverse()
        serwrite(inpline)
    ss = prepState(state)
    for stateline in ss:
        stateline.reverse()
        serwrite(stateline)
    for t in split_list(target, 4):
        serwrite(t)
    nonce_base.reverse()
    serwrite(nonce_base)
    serwrite([0x00, 0x00, 0x00, 0x00]) # position
    x = serconn.read()
    if x != b'S':
        print('Expected S, got ' + str(x))
        return None
    for i in range(200):
        if serconn.in_waiting:
            x = serconn.read()
            if x != b'Y':
                print('Expected Y, got ' + str(x))
                return None
            x = serconn.read(4)
            x = bytes.fromhex(flipIntBytes('%08x' % int.from_bytes(x, 'big')))
            return x
        time.sleep(0.01)

def doShaCPU(data, diff):
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

if __name__ == '__main__':
    main()
    #inp = "0000002063bf28417b38570f415be2007eb71b9d36407e66e8fed8a756010000000000009b9c9ab0b1c92844e4fed3f895f9443fefcda5ae02cc5a8ad4444f93"
    #(_, state, _) = sha256(bytes.fromhex(inp))
    #for s in state:
    #    print("%08x" % s)



