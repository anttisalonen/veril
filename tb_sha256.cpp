#include <stdlib.h>
#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vsha256.h"
#include "Vsha256___024root.h"

#define MAX_SIM_TIME 400
vluint64_t sim_time = 0;

int main(int argc, char** argv, char** env) {
    Vsha256 *dut = new Vsha256;

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
            dut->in_data[0] = 0x1a99f33d;
            dut->in_data[1] = 0x7de98c78;
            dut->in_data[2] = 0x7fb266ac;
            dut->in_data[3] = 0x210072fa;
            dut->in_data[4] = 0x5df453ab;
            dut->in_data[5] = 0x449609bf;
            dut->in_data[6] = 0x63c043b5;
            dut->in_data[7] = 0x61c2f2ad;
        }

        if (sim_time == 200) {
            dut->rst = 0;
            dut->in_valid = 1;
            dut->in_data[0] = 0x55b075fb;
            dut->in_data[1] = 0xc0786c18;
            dut->in_data[2] = 0xddfc9ee4;
            dut->in_data[3] = 0x505ae042;
            dut->in_data[4] = 0x8f5375c0;
            dut->in_data[5] = 0x0cfe1c30;
            dut->in_data[6] = 0x585214cc;
            dut->in_data[7] = 0x185cbb6d;
	}

        if (sim_time == 5 || sim_time == 202) {
            dut->in_valid = 0;
        }

	if((sim_time == 180 || sim_time == 380) && dut->out_valid) {
	    // expected: c3c11d760968096f833b0b7e3fb0441db1763c9634c93b8000d76f85969ca233
	    //           26ca20257dee994e128c0970ae215c6adcf28b46fa024dfc6715202f03000000
	    for(int i = 0; i < 8; i++) {
		    printf("%08x", dut->out_res[i]);
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


