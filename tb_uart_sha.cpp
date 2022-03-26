#include <stdlib.h>
#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vuart_sha.h"
#include "Vuart_sha___024root.h"

#define MAX_SIM_TIME 100000000
vluint64_t sim_time = 0;

const long freq = 100000000;
const long baud = 115200;
long pulse_width = freq / baud * 2;
long pulse_width_2 = pulse_width / 2;

VerilatedVcdC *m_trace;

int rx_bit(Vuart_sha *dut)
{
    int ret;
    for(int i = 0; i < pulse_width_2; i++) {
        dut->clk ^= 1;
        dut->eval();
        m_trace->dump(sim_time);
        sim_time++;
    }
    ret = dut->out_uart_txd;
    for(int i = 0; i < pulse_width_2; i++) {
        dut->clk ^= 1;
        dut->eval();
        m_trace->dump(sim_time);
        sim_time++;
    }
    return ret;
}

void rx_bit_and_assert(Vuart_sha *dut, int bit)
{
    int ret = rx_bit(dut);
    if(ret != bit) {
        printf("Expected %d, received %d\n", bit, ret);
    }
}

unsigned char rx(Vuart_sha *dut)
{
    rx_bit_and_assert(dut, 0);
    unsigned char byte = 0x00;
    for(int j = 0; j < 8; j++) {
        int bit = rx_bit(dut);
        byte |= (bit << j);
    }
    rx_bit_and_assert(dut, 1);
    //printf("Received: 0x%02x\n", byte);
    return byte;
}

bool wait_for_start_bit(Vuart_sha *dut, int max_cycles)
{
    for (int i = 0; i < max_cycles; i++) {
        dut->clk ^= 1;
        dut->eval();

        bool have_sig = !dut->out_uart_txd;
        m_trace->dump(sim_time);
        sim_time++;
        if(have_sig) {
            return true;
        }
    }
    return false;
}

uint32_t rx_uint(Vuart_sha *dut)
{
    uint32_t res = 0;
    res |= rx(dut);
    wait_for_start_bit(dut, 1000);
    res |= rx(dut) << 8;
    wait_for_start_bit(dut, 1000);
    res |= rx(dut) << 16;
    wait_for_start_bit(dut, 1000);
    res |= rx(dut) << 24;
    return res;
}

void rx_and_assert(Vuart_sha *dut, unsigned char byte)
{
    unsigned char ret = rx(dut);
    if(ret != byte) {
        printf("Expected 0x%02x, received 0x%02x\n", byte, ret);
    }
}

void tx_bit(Vuart_sha *dut, int bit)
{
    for(int i = 0; i < pulse_width; i++) {
        dut->clk ^= 1;
        dut->in_uart_rxd = bit != 0;
        dut->eval();
        m_trace->dump(sim_time);
        sim_time++;
    }
}

void tx(Vuart_sha *dut, unsigned char byte)
{
    tx_bit(dut, 0);
    for(int j = 0; j < 8; j++) {
        tx_bit(dut, (byte >> j) & 1);
    }
    tx_bit(dut, 1);
}

void reset_dut(Vuart_sha *dut)
{
    for (int i = 0; i < 10; i++) {
        dut->clk ^= 1;
        dut->eval();
        if(i > 7) {
            dut->in_rst = 0;
        }
        else if(i > 2) {
            dut->in_rst = 1;
        }
        m_trace->dump(sim_time);
        sim_time++;
    }
}

void send_data(Vuart_sha *dut)
{
    const uint32_t senddata[34] = {
            // data
            0x61626369,
            0x61626364,
            0x61626364,
            0x61626364,
            0x61626364,
            0x61626364,
            0x61626364,
            0x61626364,
            0x61626364,
            0x61626364,
            0x61626364,
            0x61626364,
            0x61626364,
            0x61626364,
            0x61626364,
            0x61626364,

            // state
            0x1a99f33d,
            0x7de98c78,
            0x7fb266ac,
            0x210072fa,
            0x5df453ab,
            0x449609bf,
            0x63c043b5,
            0x61c2f2ad,

            // target
            0x00000000,
            0x00000000,
            0x00000000,
            0x00000000,
            0x00000000,
            0x00000000,
            0x00000000,
            0x00f00000,

            0x00000000, // nonce base
            0x00000000, // position
    };

    for(int i = 0; i < 34; i++) {
        for(int j = 0; j < 4; j++) {
            tx(dut, (senddata[i] >> (j * 8)) & 0xff);
        }
    }
    rx_and_assert(dut, 'S');
}

void check_hash_result(Vuart_sha *dut)
{
    for (int i = 0; i < 10000000; i++) {
        dut->clk ^= 1;
        dut->eval();

        if(!dut->out_uart_txd) {
            m_trace->dump(sim_time);
            sim_time++;
            unsigned char ret = rx(dut);
            if(ret == 'Y') {
                wait_for_start_bit(dut, 1000);
                uint32_t res = rx_uint(dut);
                printf("Found nonce (expected 0x1da): 0x%08x\n", res);
            } else {
                printf("Received 0x%02x, expected 'Y'\n", ret);
            }
            break;
        } else {
            m_trace->dump(sim_time);
            sim_time++;
        }
    }
}

int main(int argc, char** argv) {
    Vuart_sha *dut = new Vuart_sha;

    Verilated::traceEverOn(true);
    m_trace = new VerilatedVcdC;
    dut->trace(m_trace, 5);
    m_trace->open("waveform.vcd");

    reset_dut(dut);
    tx(dut, 'H'); rx_and_assert(dut, '1');
    send_data(dut);
    check_hash_result(dut);

    tx(dut, 'H'); rx_and_assert(dut, '1');
    send_data(dut);
    check_hash_result(dut);

    reset_dut(dut);
    tx(dut, 'H'); rx_and_assert(dut, '1');
    send_data(dut);
    check_hash_result(dut);

    m_trace->close();
    delete dut;
    exit(EXIT_SUCCESS);
}


