import mining
import json
import sys
import socket
import datetime
import time

def recvdata(sock, block=True):
    sock.setblocking(block)
    try:
        resp = sock.recv(65536)
        if len(resp) == 65536:
            resp += sock.recv(65536)
    except BlockingIOError:
        if not block:
            return list()
        else:
            raise
    alldata = resp.split()
    resp = list()
    for data in alldata:
        print('received response: %s' % data)
        respdata = json.loads(data)
        if 'error' in respdata and respdata['error'] is not None:
            print(respdata['error'])
            sys.exit(1)
        resp.append(respdata)
    return resp

def main():
    # testnet
    #host = "pool.bitcoincloud.net"
    #port = 4008
    #workername = "2N16oE62ZjAPup985dFBQYAuy5zpDraH7Hk"
    #password = "anything"

    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.connect((host, port))
    sock.sendall('{"id": 1, "method": "mining.subscribe", "params": []}\n'.encode())
    respdata = recvdata(sock)[0]
    respresult = respdata['result']
    extranonce1 = respresult[1]
    extranonce2_size = respresult[2]
    commands = respresult[0]
    difficulty = 0
    #for cmd in commands:
    #    if cmd[0] == 'mining.set_difficulty':
    #        difficulty = cmd[1]

    sock.sendall(('{"params": ["%s", "%s"], "id": 2, "method": "mining.authorize"}\n' % (workername, password)).encode())
    time.sleep(1)
    #sock.sendall(('{"params": [128], "id": 3, "method": "mining.suggest_difficulty"}\n').encode())
    #resp = recvdata(sock)

    mining_parameters = dict()
    extranon2 = 1
    while True:
        extranon2 += 1
        allresp = recvdata(sock, False)
        for resp in allresp:
            if 'method' in resp and resp['method'] == 'mining.notify' and 'params' in resp:
                pars = resp['params'] 
                job_id = pars[0] 
                prevhash = pars[1]
                coinb1 = pars[2]
                coinb2 = pars[3]
                merkles = pars[4]
                blockversion = pars[5]
                nbits = pars[6]
                ntime = pars[7]
                clean_jobs = pars[8]
        
                mining_parameters = dict()
                mining_parameters['extranonce1'] = extranonce1
                mining_parameters['extranonce2_size'] = extranonce2_size
                mining_parameters['diff'] = difficulty
                mining_parameters['prevhash'] = prevhash
                mining_parameters['coinb1'] = coinb1
                mining_parameters['coinb2'] = coinb2
                mining_parameters['merkle_branches'] = merkles
                mining_parameters['version'] = blockversion
                mining_parameters['nbits'] = nbits
                mining_parameters['ntime'] = ntime
                print('Got mining parameters')

            elif 'method' in resp and resp['method'] == 'mining.set_difficulty':
                difficulty = resp['params'][0]
                print('Difficulty set to %d' % difficulty)

        if mining_parameters:
            extrafmt = '%%0%dx' % (extranonce2_size * 2)
            extranonce2 = extrafmt % extranon2
            assert(len(extranonce2) == mining_parameters['extranonce2_size'] * 2)
            print("%s - Extranonce2: %s" % (datetime.datetime.now(), extranonce2))
            nonce = mining.do_mining_params(mining_parameters, extranonce2)
            if nonce is not None:
                sock.sendall(('{"params": ["%s", "%s", "%s", "%s", "%s"], "id": 4, "method": "mining.submit"}' % (workername, job_id, extranonce2, ntime, nonce)).encode())
                print('nonce 0x%08x found, submitted' % nonce)
                resp = recvdata(sock)
                mining_parameters = dict()
        else:
            time.sleep(1)

if __name__ == '__main__':
    main()

