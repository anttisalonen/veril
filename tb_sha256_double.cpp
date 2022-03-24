#include <stdlib.h>
#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vsha256_double.h"
#include "Vsha256_double___024root.h"

#define MAX_SIM_TIME 1000000
vluint64_t sim_time = 0;

int main(int argc, char** argv, char** env) {
    Vsha256_double *dut = new Vsha256_double;

    Verilated::traceEverOn(true);
    VerilatedVcdC *m_trace = new VerilatedVcdC;
    dut->trace(m_trace, 5);
    m_trace->open("waveform.vcd");

    while (sim_time < MAX_SIM_TIME) {
        dut->clk ^= 1;
        dut->eval();

        if (sim_time == 1) {
            dut->rst = 1;
        }

        if (sim_time == 3) {
            dut->rst = 0;
            dut->in_valid = 1;
            dut->in_data[0] = 0x61626364;
            dut->in_data[1] = 0x61626364;
            dut->in_data[2] = 0x61626364;
            dut->in_data[3] = 0x61626364;
            dut->in_data[4] = 0x61626364;
            dut->in_data[5] = 0x61626364;
            dut->in_data[6] = 0x61626364;
            dut->in_data[7] = 0x61626364;

            dut->in_target[0] = 0x00000000;
            dut->in_target[1] = 0x00000000;
            dut->in_target[2] = 0x00000000;
            dut->in_target[3] = 0x00000000;
            dut->in_target[4] = 0x00000000;
            dut->in_target[5] = 0x00000000;
            dut->in_target[6] = 0x00000000;
            dut->in_target[7] = 0x00f00000;

            dut->in_state[0] = 0x1a99f33d;
            dut->in_state[1] = 0x7de98c78;
            dut->in_state[2] = 0x7fb266ac;
            dut->in_state[3] = 0x210072fa;
            dut->in_state[4] = 0x5df453ab;
            dut->in_state[5] = 0x449609bf;
            dut->in_state[6] = 0x63c043b5;
            dut->in_state[7] = 0x61c2f2ad;

            dut->in_nonce_base = 0;
            dut->in_position = 0;
        }

        if (sim_time == 5) {
            dut->in_valid = 0;
        }

        m_trace->dump(sim_time);
        sim_time++;

        if(dut->out_valid) {
            for(int i = 0; i < 8; i++) {
                printf("%08x", dut->out_result[i]);
            }
            printf("\n");
            printf("%08x\n", dut->out_nonce_found);
            break;
        }
    }

    m_trace->close();
    delete dut;
    exit(EXIT_SUCCESS);
}


