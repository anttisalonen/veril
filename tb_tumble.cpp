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

        if (sim_time == 3 || sim_time == 200) {
            dut->rst = 0;
            dut->in_valid = 1;
            dut->in_data[0] = 0xdeadbeef;
            dut->in_data[1] = 0xc0dec0da;
            dut->in_data[2] = 3;
            dut->in_data[3] = 0x33333333;
            dut->in_data[4] = 0x44444444;
            dut->in_data[5] = 0x55555555;
            dut->in_data[6] = 0x66666666;
            dut->in_data[7] = 0x77777777;
            dut->in_data[8] = 0x88888888;
            dut->in_data[9] = 0x99999999;
            dut->in_data[10] = 0xaaaaaaaa;
            dut->in_data[11] = 0xbbbbbbbb;
            dut->in_data[12] = 0xcccccccc;
            dut->in_data[13] = 0xdddddddd;
            dut->in_data[14] = 0xeeeeeeee;
            dut->in_data[15] = 0xffffffff;
            dut->state0 = 123 + sim_time;
            dut->state1 = 456;
            dut->state2 = 789;
            dut->state3 = 234;
            dut->state4 = 345;
            dut->state5 = 567;
            dut->state6 = 890;
            dut->state7 = 901;
        }

        if (sim_time == 5 || sim_time == 202) {
            dut->in_valid = 0;
        }

        m_trace->dump(sim_time);
        sim_time++;
    }

    m_trace->close();
    delete dut;
    exit(EXIT_SUCCESS);
}


