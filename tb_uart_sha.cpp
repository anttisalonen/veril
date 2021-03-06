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
        printf("%llu: Expected bit %d, received %d\n", sim_time / 2, bit, ret);
        m_trace->close();
        exit(EXIT_SUCCESS);
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

void wait_n_cycles(Vuart_sha *dut, int max_cycles)
{
    for (int i = 0; i < max_cycles; i++) {
        dut->clk ^= 1;
        dut->eval();

        m_trace->dump(sim_time);
        sim_time++;
    }
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
        if(ret >= '0' && ret <= 'z')
            printf("Expected '%c', received '%c'\n", byte, ret);
        else
            printf("Expected '%c', received 0x%02x\n", byte, ret);
    } else {
        printf("rx: '%c'\n", ret);
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

void tx(Vuart_sha *dut, unsigned char byte, bool log)
{
    tx_bit(dut, 0);
    for(int j = 0; j < 8; j++) {
        tx_bit(dut, (byte >> j) & 1);
    }
    tx_bit(dut, 1);
    if(log) printf("tx: '%c'\n", byte);
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

void send_data(Vuart_sha *dut, bool is_valid)
{
    const uint32_t senddata[21] = {
            // data
            0x03081a23,
            0x8c8a145e,
            0x98b0021a,

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
            0xff9c0000,
            0x00000063,

            0xd0cf1000, // nonce base
            0x00000000, // position
    };

    printf("Sending data\n");
    for(int i = 0; i < 21; i++) {
        for(int j = 0; j < 4; j++) {
            tx(dut, (senddata[i] >> (j * 8)) & 0xff, false);
        }
    }
    if(is_valid) {
        rx_and_assert(dut, 'S');
    } else {
        rx(dut);
    }
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
                printf("Found nonce (expected 0xd0cf1040): 0x%08x\n", res);
            } else {
                if(ret >= '0' && ret <= 'z')
                    printf("Expected 'Y', received '%c'\n", ret);
                else
                    printf("Expected 'Y', received 0x%02x\n", ret);
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

    // test reaction on invalid input data
    reset_dut(dut);
    tx(dut, 'H', true); rx_and_assert(dut, '1');
    send_data(dut, true);
    send_data(dut, false);
    wait_n_cycles(dut, 100);
    tx(dut, 'H', true); rx(dut);
    wait_n_cycles(dut, 100);

    tx(dut, 'H', true); rx_and_assert(dut, '1');
    tx(dut, 'H', true); rx_and_assert(dut, '1');
    send_data(dut, true);
    check_hash_result(dut);

    tx(dut, 'H', true); rx_and_assert(dut, '1');
    send_data(dut, true);
    check_hash_result(dut);

    m_trace->close();
    delete dut;
    exit(EXIT_SUCCESS);
}


