#include "HHBench.h"
#include "HCBench.h"
#include "HHHBench.h"
#include "HHH2Bench.h"

std::string folder = "./Dataset/";

std::string file[2] = {"CAIDA-18.dat", "MAWI-07.dat"};

int main() {

    HHBench caida_1(folder + file[0], "CAIDA");
    caida_1.HHOurBench(500000, 0.0001);
    caida_1.HHOtherBench(500000, 0.0001);
    /*
    HHBench mawi_1(folder + file[1], "MAWI");
    mawi_1.HHOurBench(500000, 0.0001);
    mawi_1.HHOtherBench(500000, 0.0001);*/

    HCBench caida_2(folder + file[0], "CAIDA");
    caida_2.HCOurBench(500000, 0.0001);
    caida_2.HCOtherBench(500000, 0.0001);
    /*
    HCBench mawi_2(folder + file[1], "MAWI");
    mawi_2.HCOurBench(500000, 0.0001);
    mawi_2.HCOtherBench(500000, 0.0001);*/

    HHHBench caida_3(folder + file[0], "CAIDA");
    for(uint32_t i = 1;i <= 5;++i){
        std::cout << i << "MB" << std::endl << std::endl;
        caida_3.HHHOurBench(i * 500000, 0.00005);
        caida_3.HHHOtherBench(i * 500000, 0.00005);
    }

    HHH2Bench caida_4(folder + file[0], "CAIDA");
    for(uint32_t i = 1;i <= 5;++i){
        std::cout << i << "MB" << std::endl << std::endl;
        caida_4.HHH2OtherBench(i * 5000000, 0.00005);
        caida_4.HHH2OurBench(i * 5000000, 0.00005);
    }

    return 0;
}