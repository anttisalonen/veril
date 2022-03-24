#include <stdlib.h>
#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vep0.h"
#include "Vep0___024root.h"

#define MAX_SIM_TIME 20
vluint64_t sim_time = 0;

int main(int argc, char** argv, char** env) {
    Vep0 *dut = new Vep0;

    Verilated::traceEverOn(true);
    VerilatedVcdC *m_trace = new VerilatedVcdC;
    dut->trace(m_trace, 5);
    m_trace->open("waveform.vcd");

    while (sim_time < MAX_SIM_TIME) {
        dut->eval();

        if (sim_time == 1) {
            dut->inp = 0b0000111;
        }

        m_trace->dump(sim_time);
        sim_time++;
    }

    m_trace->close();
    delete dut;
    exit(EXIT_SUCCESS);
}


