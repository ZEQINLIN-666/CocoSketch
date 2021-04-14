#ifndef HHBENCH_H
#define HHBENCH_H

#include <vector>
#include <fstream>

#include "./Single/Univmon.h"
#include "./Single/Elastic.h"
#include "./Single/CMHeap.h"
#include "./Single/CountHeap.h"
#include "./Single/SpaceSaving.h"

#include "./Multiple/OurHard.h"
#include "./Multiple/OurSoft.h"
#include "./Multiple/USS.h"

#include "./Common/MMap.h"

#define HHOtherSketch Elastic


class HHBench{
public:

    HHBench(std::string PATH, std::string name){
        fileName = name;

        result = Load(PATH.c_str());
        dataset = (TUPLES*)result.start;
        length = result.length / sizeof(TUPLES);
        //cycles.resize(length);

        for(uint64_t i = 0;i < length;++i){
            tuplesMp[dataset[i]] += 1;

            mp[0][dataset[i].srcIP_dstIP()] += 1;
            mp[1][dataset[i].srcIP_srcPort()] += 1;
            mp[2][dataset[i].dstIP_dstPort()] += 1;
            mp[3][dataset[i].srcIP()] += 1;
            mp[4][dataset[i].dstIP()] += 1;
        }
    }

    ~HHBench(){
        UnLoad(result);
    }

    void HHOtherBench(uint32_t MEMORY, double alpha){
        SingleAbstract<TUPLES>* tupleSketch;
        SingleAbstract<uint64_t>* sketch[5];


        for(uint32_t i = 1;i <= MAX_TRAFFIC;++i){
            uint32_t mem = MEMORY / i;

            tupleSketch = new HHOtherSketch<TUPLES>(mem);

            for(uint32_t j = 0;j < i - 1;++j){
                sketch[j] = new HHOtherSketch<uint64_t>(mem);
            }

            //TP TP_start, TP_finish;
            //uint32_t start, finish;

            // TP_start = now();
            for(uint32_t j = 0;j < length;++j){
                // start = __rdtsc();
                switch(i){
                    case 6: sketch[4]->Insert(dataset[j].dstIP());
                    case 5: sketch[3]->Insert(dataset[j].srcIP());
                    case 4: sketch[2]->Insert(dataset[j].dstIP_dstPort());
                    case 3: sketch[1]->Insert(dataset[j].srcIP_srcPort());
                    case 2: sketch[0]->Insert(dataset[j].srcIP_dstIP());
                    default: tupleSketch->Insert(dataset[j]);
                }
                //finish = __rdtsc();
                //cycles[j] = finish - start;
            }
            //std::sort(cycles.begin(), cycles.end());
            //std::cout << "95th: " << cycles[uint32_t(0.95 * length)] << std::endl;
            //std::cout << "99th: " << cycles[uint32_t(0.99 * length)] << std::endl;
            //TP_finish = now();
            //std::cout << "Thp: " << length / durationms(TP_finish, TP_start) << std::endl;

            std::unordered_map<TUPLES, COUNT_TYPE> estTuple = tupleSketch->AllQuery();
            std::unordered_map<uint64_t, COUNT_TYPE> estMp[5];

            for(uint32_t j = 0;j < i - 1;++j){
                estMp[j] = sketch[j]->AllQuery();
            }

            COUNT_TYPE threshold = alpha * length;

            std::string saveFile = "HH-" + fileName + "-" + tupleSketch->name + "-" + std::to_string(MEMORY) +
                                   "-" + std::to_string(threshold) + "-" + std::to_string(i) + ".csv";

            std::ofstream outfile(saveFile);

            CompareHH(estTuple, tuplesMp, threshold, 1, outfile);

            for(uint32_t j = 0;j < i - 1;++j){
                CompareHH(estMp[j], mp[j], threshold, j + 2, outfile);
            }

            outfile.close();

            delete tupleSketch;
            for(uint32_t j = 0;j < i - 1;++j){
                delete sketch[j];
            }
        }
    }

    void HHOurBench(uint32_t MEMORY, double alpha){
        MultiAbstract<TUPLES>* sketch = new OurSoft<TUPLES>(MEMORY);

        //TP TP_start, TP_finish;
        //uint32_t start, finish;

        //TP_start = now();
        for(uint32_t i = 0;i < length;++i){
            //start = __rdtsc();
            sketch->Insert(dataset[i]);
            //finish = __rdtsc();
            //cycles[i] = finish - start;
        }
        //std::sort(cycles.begin(), cycles.end());
        //std::cout << "95th: " << cycles[uint32_t(0.95 * length)] << std::endl;
        //std::cout << "99th: " << cycles[uint32_t(0.99 * length)] << std::endl;
        //TP_finish = now();
        //std::cout << "Thp: " << length / durationms(TP_finish, TP_start) << std::endl;

        std::unordered_map<TUPLES, COUNT_TYPE> estTuple = sketch->AllQuery();
        std::unordered_map<uint64_t, COUNT_TYPE> estMp[5];

        for(auto it = estTuple.begin();it != estTuple.end();++it){
            estMp[0][(it->first).srcIP_dstIP()] += it->second;
            estMp[1][(it->first).srcIP_srcPort()] += it->second;
            estMp[2][(it->first).dstIP_dstPort()] += it->second;
            estMp[3][(it->first).srcIP()] += it->second;
            estMp[4][(it->first).dstIP()] += it->second;
        }

        COUNT_TYPE threshold = alpha * length;

        std::string saveFile = "HH-" + fileName + "-" + sketch->name + "-" + std::to_string(MEMORY) +
                "-" + std::to_string(threshold) + ".csv";

        std::ofstream outfile(saveFile);

        CompareHH(estTuple, tuplesMp, threshold, 1, outfile);

        for(uint32_t i = 0;i < 5;++i){
            CompareHH(estMp[i], mp[i], threshold, i + 2, outfile);
        }

        outfile.close();

        delete sketch;
    }

private:
    std::string fileName;
    //std::vector<uint32_t> cycles;

    LoadResult result;

    TUPLES* dataset;
    uint64_t length;

    std::unordered_map<TUPLES, COUNT_TYPE> tuplesMp;
    std::unordered_map<uint64_t, COUNT_TYPE> mp[5];

    template<class T>
    void CompareHH(T mp, T record, COUNT_TYPE threshold, uint32_t key_type, std::ofstream& outfile){
        double realHH = 0, estHH = 0, bothHH = 0, aae = 0, are = 0;

        for(auto it = record.begin();it != record.end();++it){
            bool real, est;
            double realF = it->second, estF = mp[it->first];

            real = (realF > threshold);
            est = (estF > threshold);

            realHH += real;
            estHH += est;

            if(real && est){
                bothHH += 1;
                aae += abs(realF - estF);
                are += abs(realF - estF) / realF;
            }
        }

        outfile << "key-type," << key_type << std::endl;
        outfile << "threshold," << threshold << std::endl;

        outfile << "realHH," << realHH << std::endl;
        outfile << "estHH," << estHH << std::endl;
        outfile << "bothHH," << bothHH << std::endl;

        outfile << "aae," << aae << std::endl;
        outfile << "are," << are << std::endl;
        outfile << std::endl;
    }
};

#endif
