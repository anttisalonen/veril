#include <stdlib.h>
#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vtumble.h"
#include "Vtumble___024root.h"

#define MAX_SIM_TIME 400
vluint64_t sim_time = 0;

int main(int argc, char** argv, char** env) {
    Vtumble *dut = new Vtumble;

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
            dut->in_data[0] = 0x00000020;
            dut->in_data[1] = 0x63bf2841;
            dut->in_data[2] = 0x7b38570f;
            dut->in_data[3] = 0x415be200;
            dut->in_data[4] = 0x7eb71b9d;
            dut->in_data[5] = 0x36407e66;
            dut->in_data[6] = 0xe8fed8a7;
            dut->in_data[7] = 0x56010000;
            dut->in_data[8] = 0x00000000;
            dut->in_data[9] = 0x9b9c9ab0;
            dut->in_data[10] = 0xb1c92844;
            dut->in_data[11] = 0xe4fed3f8;
            dut->in_data[12] = 0x95f9443f;
            dut->in_data[13] = 0xefcda5ae;
            dut->in_data[14] = 0x02cc5a8a;
            dut->in_data[15] = 0xd4444f93;
            dut->state0 = 0x6a09e667;
            dut->state1 = 0xbb67ae85;
            dut->state2 = 0x3c6ef372;
            dut->state3 = 0xa54ff53a;
            dut->state4 = 0x510e527f;
            dut->state5 = 0x9b05688c;
            dut->state6 = 0x1f83d9ab;
            dut->state7 = 0x5be0cd19;
        }

        if (sim_time == 200) {
            dut->rst = 0;
            dut->in_valid = 1;
            dut->in_data[0] = 0x03081a23;
            dut->in_data[1] = 0x8c8a145e;
            dut->in_data[2] = 0x98b0021a;
            dut->in_data[3] = 0xd0cf1040;
            dut->in_data[4] = 0x80000000;
            dut->in_data[5] = 0x00000000;
            dut->in_data[6] = 0x00000000;
            dut->in_data[7] = 0x00000000;
            dut->in_data[8] = 0x00000000;
            dut->in_data[9] = 0x00000000;
            dut->in_data[10] = 0x00000000;
            dut->in_data[11] = 0x00000000;
            dut->in_data[12] = 0x00000000;
            dut->in_data[13] = 0x00000000;
            dut->in_data[14] = 0x00000000;
            dut->in_data[15] = 0x00000280;
            dut->state0 = 0x1a99f33d;
            dut->state1 = 0x7de98c78;
            dut->state2 = 0x7fb266ac;
            dut->state3 = 0x210072fa;
            dut->state4 = 0x5df453ab;
            dut->state5 = 0x449609bf;
            dut->state6 = 0x63c043b5;
            dut->state7 = 0x61c2f2ad;
	}

        if (sim_time == 5 || sim_time == 202) {
            dut->in_valid = 0;
        }

	if((sim_time == 190 || sim_time == 390) && dut->out_valid) {
		/* expected:
		 *
		 * 1a99f33d
		 * 7de98c78
		 * 7fb266ac
		 * 210072fa
		 * 5df453ab
		 * 449609bf
		 * 63c043b5
		 * 61c2f2ad
		 *
		 * 55b075fb
		 * c0786c18
		 * ddfc9ee4
		 * 505ae042
		 * 8f5375c0
		 * 0cfe1c30
		 * 585214cc
		 * 185cbb6d
		 */
		for(int i = 0; i < 8; i++) {
			printf("%08x\n", dut->out_res[i]);
		}
		printf("\n");
	}

        m_trace->dump(sim_time);
        sim_time++;
    }

    m_trace->close();
    delete dut;
    exit(EXIT_SUCCESS);
}


