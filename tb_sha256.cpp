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

        if (sim_time == 3 || sim_time == 200) {
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
        }

        if (sim_time == 5 || sim_time == 202) {
            dut->in_valid = 0;
        }

	if((sim_time == 180 || sim_time == 380) && dut->out_valid) {
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


