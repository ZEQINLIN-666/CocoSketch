#include "HHBench.h"
#include "HCBench.h"
#include "HHHBench.h"
#include "HHH2Bench.h"

std::string folder = "./Dataset/";

std::string file[2] = {"CAIDA-18.dat", "MAWI-07.dat"};

int main() {

    HHBench caida(folder + file[0], "CAIDA");
    caida.HHOurBench(500000, 0.0001);
    caida.HHOtherBench(500000, 0.0001);
    /*
    HHBench mawi(folder + file[1], "MAWI");
    mawi.HHOurBench(500000, 0.0001);
    mawi.HHOtherBench(500000, 0.0001);*/

    HCBench caida(folder + file[0], "CAIDA");
    caida.HCOurBench(500000, 0.0001);
    caida.HCOtherBench(500000, 0.0001);
    /*
    HCBench mawi(folder + file[1], "MAWI");
    mawi.HCOurBench(500000, 0.0001);
    mawi.HCOtherBench(500000, 0.0001);*/

    HHHBench caida(folder + file[0], "CAIDA");
    for(uint32_t i = 1;i <= 5;++i){
        std::cout << i << "MB" << std::endl << std::endl;
        caida.HHHOurBench(i * 500000, 0.00005);
        caida.HHHOtherBench(i * 500000, 0.00005);
    }

    HHH2Bench caida(folder + file[0], "CAIDA");
    for(uint32_t i = 1;i <= 5;++i){
        std::cout << i << "MB" << std::endl << std::endl;
        caida.HHH2OtherBench(i * 5000000, 0.00005);
        caida.HHH2OurBench(i * 5000000, 0.00005);
    }

    return 0;
}