/* -*- P4_14 -*- */
#ifdef __TARGET_TOFINO__
#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
//Include the blackbox definition
#include <tofino/stateful_alu_blackbox.p4>
#else
#warning This program is intended for Tofino P4 architecture only
#endif

#define BUCKETS_L 8192
#define BUCKETS_HASH_L 13
#define MICE_LEN_L 131072 // namely, 2**17
#define MICE_LEN_HASH_L 17
#define BUCKETS_S 4096
#define BUCKETS_HASH_S 12
#define MICE_LEN_S 65536 // namely, 2**16
#define MICE_LEN_HASH_S 16
#define LAMBDA 5
// 3 * 2**13
/*--*--* HEADERS *--*--*/
header_type Ethernet {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

header_type Ipv4 {
    fields {
        version : 4;
        ihl : 4;
        diffserv : 8;
        totalLen : 16;
        identification : 16;
        flags : 3;
        fragOffset : 13;
        ttl : 8;
        protocol : 8;
        hdrChecksum : 16;
        srcAddr : 32;
        dstAddr : 32;
    }
}

header_type MyFlow {
    // header_type for parsing flow packets
    fields {
        id_x1: 32;
        id_x2: 32;
        id_x3: 32;
        id_x4: 32;
        id_x5: 32;
        id_x6: 32;
    }
}

header_type MyMeta {
    fields {
        totVotes_x1: 32; // field for reading the value of total votes from stateful registers
        totVotes_div_x1: 32; // field to store the result of totVotes/LAMBDA
        register_id_x1: 32; //field to temporarily memorize the value from stateful registers
        cond_x1: 1;
        totVotes_x2: 32;
        totVotes_div_x2: 32;
        register_id_x2: 32;
        cond_x2: 1;
        totVotes_x3: 32;
        totVotes_div_x3: 32;
        register_id_x3: 32;
        cond_x3: 1;
        totVotes_x4: 32;
        totVotes_div_x4: 32;
        register_id_x4: 32;
        cond_x4: 1;
        totVotes_x5: 32;
        totVotes_div_x5: 32;
        register_id_x5: 32;
        cond_x5: 1;
        totVotes_x6: 32;
        totVotes_div_x6: 32;
        register_id_x6: 32;
        cond_x6: 1;
    }
}

header Ethernet ethernet;
header Ipv4 ipv4;
header MyFlow myflow;
metadata MyMeta meta;


/*--*--* PARSERS *--*--*/
parser start {
    return parse_ethernet;
}

parser parse_ethernet {
    extract(ethernet);
    return parse_ipv4;
}

parser parse_ipv4 {
    extract(ipv4);
    return parse_myflow;
}

parser parse_myflow {
    extract(myflow);
    return ingress;
}

/*--*--* actions for all steps *--*--*/
action real_drop() {
    drop();
    exit();
}

/************************ sketch 1 ************************/

// registers for step 1
register totVotesReg_x1_1 {
    width: 64;
    instance_count: BUCKETS_L;
}
register freqIdReg_x1_1 {
    width: 64;
    instance_count: BUCKETS_L;
}

// registers for step 2
register totVotesReg_x1_2 {
    width: 64;
    instance_count: BUCKETS_L;
}
register freqIdReg_x1_2 {
    width: 64;
    instance_count: BUCKETS_L;
}

// registers for step 3
register totVotesReg_x1_3 {
    width: 64;
    instance_count: BUCKETS_L;
}
register freqIdReg_x1_3 {
    width: 64;
    instance_count: BUCKETS_L;
}

// registers for step 4
register totVotesReg_x1_4 {
    width: 64;
    instance_count: BUCKETS_L;
}
register freqIdReg_x1_4 {
    width: 64;
    instance_count: BUCKETS_L;
}

// registers for step 5
register miceReg_x1 {
    width: 8;
    instance_count: MICE_LEN_L;
}

/*--*--* Hash *--*--*/
field_list hash_list_x1 {
    myflow.id_x1;
}

field_list_calculation hash_heavy_x1_1 {
    input { hash_list_x1; }
    algorithm : identity;
    output_width : BUCKETS_HASH_L;
}

field_list_calculation hash_heavy_x1_2 {
    input { hash_list_x1; }
    algorithm : identity;
    output_width : BUCKETS_HASH_L;
}

field_list_calculation hash_heavy_x1_3 {
    input { hash_list_x1; }
    algorithm : identity;
    output_width : BUCKETS_HASH_L;
}

field_list_calculation hash_heavy_x1_4 {
    input { hash_list_x1; }
    algorithm : identity;
    output_width : BUCKETS_HASH_L;
}



field_list_calculation hash_mice_x1 {
    input { hash_list_x1; }
    algorithm : identity;
    output_width : MICE_LEN_HASH_L;
}


action voteDivAction_x1() {
    shift_right(meta.totVotes_div_x1, meta.totVotes_x1, LAMBDA);
}

action updateAction_x1() {
    modify_field(myflow.id_x1, meta.register_id_x1);
}

/*---------------------step 1---------------------*/
action drop_x1()
{
    modify_field(meta.cond_x1, 0);
}
table dropTable_x1_1 {
    actions {
        drop_x1;
    }
    default_action: drop_x1();
}

blackbox stateful_alu totVotesSalu_x1_1 {
    reg: totVotesReg_x1_1;
    update_lo_1_value: register_lo + 1;
    output_value: alu_lo;
    output_dst: meta.totVotes_x1;
}
action totVotesAction_x1_1() {
    totVotesSalu_x1_1.execute_stateful_alu_from_hash(hash_heavy_x1_1);
    modify_field(meta.register_id_x1, 0);
    modify_field(meta.cond_x1, 1);
}
table totVotesTable_x1_1 {
    actions {
        totVotesAction_x1_1;
    }
    default_action: totVotesAction_x1_1();
}

table voteDivTable_x1_1 {
    actions {
        voteDivAction_x1;
    }
    default_action: voteDivAction_x1();
}

blackbox stateful_alu freqIdSalu_x1_1 {
    reg: freqIdReg_x1_1;

    condition_hi: meta.totVotes_div_x1 >= register_hi;
    condition_lo: myflow.id_x1 == register_lo;

    update_lo_1_predicate: condition_lo or condition_hi;
    update_lo_1_value: myflow.id_x1;

    update_hi_1_predicate: condition_lo or condition_hi;
    update_hi_1_value: register_hi + 1;

    output_predicate: condition_lo or condition_hi;
    output_value: register_lo;
    output_dst: meta.register_id_x1;
}
action freqIdAction_x1_1() {
    freqIdSalu_x1_1.execute_stateful_alu_from_hash(hash_heavy_x1_1);
}

table freqIdTable_x1_1 {
    actions {
        freqIdAction_x1_1;
    }
    default_action: freqIdAction_x1_1();
}

table updateTable_x1_1 {
    actions {
        updateAction_x1;
    }
    default_action: updateAction_x1();
}

/*---------------------step 2---------------------*/

table dropTable_x1_2 {
    actions {
        drop_x1;
    }
    default_action: drop_x1();
}

blackbox stateful_alu totVotesSalu_x1_2 {
    reg: totVotesReg_x1_2;
    update_lo_1_value: register_lo + 1;
    output_value: alu_lo;
    output_dst: meta.totVotes_x1;
}
action totVotesAction_x1_2() {
    totVotesSalu_x1_2.execute_stateful_alu_from_hash(hash_heavy_x1_2);
    modify_field(meta.register_id_x1, 0);
}
table totVotesTable_x1_2 {
    actions {
        totVotesAction_x1_2;
    }
    default_action: totVotesAction_x1_2();
}

table voteDivTable_x1_2 {
    actions {
        voteDivAction_x1;
    }
    default_action: voteDivAction_x1();
}

blackbox stateful_alu freqIdSalu_x1_2 {
    reg: freqIdReg_x1_2;

    condition_hi: meta.totVotes_div_x1 >= register_hi;
    condition_lo: myflow.id_x1 == register_lo;

    update_lo_1_predicate: condition_lo or condition_hi;
    update_lo_1_value: myflow.id_x1;

    update_hi_1_predicate: condition_lo or condition_hi;
    update_hi_1_value: register_hi + 1;

    output_predicate: condition_lo or condition_hi;
    output_value: register_lo;
    output_dst: meta.register_id_x1;
}
action freqIdAction_x1_2() {
    freqIdSalu_x1_2.execute_stateful_alu_from_hash(hash_heavy_x1_2);
}

table freqIdTable_x1_2 {
    actions {
        freqIdAction_x1_2;
    }
    default_action: freqIdAction_x1_2();
}

table updateTable_x1_2 {
    actions {
        updateAction_x1;
    }
    default_action: updateAction_x1();
}

/*---------------------step 3---------------------*/

table dropTable_x1_3 {
    actions {
        drop_x1;
    }
    default_action: drop_x1();
}

blackbox stateful_alu totVotesSalu_x1_3 {
    reg: totVotesReg_x1_3;
    update_lo_1_value: register_lo + 1;
    output_value: alu_lo;
    output_dst: meta.totVotes_x1;
}
action totVotesAction_x1_3() {
    totVotesSalu_x1_3.execute_stateful_alu_from_hash(hash_heavy_x1_3);
    modify_field(meta.register_id_x1, 0);
}
table totVotesTable_x1_3 {
    actions {
        totVotesAction_x1_3;
    }
    default_action: totVotesAction_x1_3();
}

table voteDivTable_x1_3 {
    actions {
        voteDivAction_x1;
    }
    default_action: voteDivAction_x1();
}

blackbox stateful_alu freqIdSalu_x1_3 {
    reg: freqIdReg_x1_3;

    condition_hi: meta.totVotes_div_x1 >= register_hi;
    condition_lo: myflow.id_x1 == register_lo;

    update_lo_1_predicate: condition_lo or condition_hi;
    update_lo_1_value: myflow.id_x1;

    update_hi_1_predicate: condition_lo or condition_hi;
    update_hi_1_value: register_hi + 1;

    output_predicate: condition_lo or condition_hi;
    output_value: register_lo;
    output_dst: meta.register_id_x1;
}
action freqIdAction_x1_3() {
    freqIdSalu_x1_3.execute_stateful_alu_from_hash(hash_heavy_x1_3);
}

table freqIdTable_x1_3 {
    actions {
        freqIdAction_x1_3;
    }
    default_action: freqIdAction_x1_3();
}

table updateTable_x1_3 {
    actions {
        updateAction_x1;
    }
    default_action: updateAction_x1();
}

/*---------------------step 4---------------------*/

table dropTable_x1_4 {
    actions {
        drop_x1;
    }
    default_action: drop_x1();
}

blackbox stateful_alu totVotesSalu_x1_4 {
    reg: totVotesReg_x1_4;
    update_lo_1_value: register_lo + 1;
    output_value: alu_lo;
    output_dst: meta.totVotes_x1;
}
action totVotesAction_x1_4() {
    totVotesSalu_x1_4.execute_stateful_alu_from_hash(hash_heavy_x1_4);
    modify_field(meta.register_id_x1, 0);
}
table totVotesTable_x1_4 {
    actions {
        totVotesAction_x1_4;
    }
    default_action: totVotesAction_x1_4();
}

table voteDivTable_x1_4 {
    actions {
        voteDivAction_x1;
    }
    default_action: voteDivAction_x1();
}

blackbox stateful_alu freqIdSalu_x1_4 {
    reg: freqIdReg_x1_4;

    condition_hi: meta.totVotes_div_x1 >= register_hi;
    condition_lo: myflow.id_x1 == register_lo;

    update_lo_1_predicate: condition_lo or condition_hi;
    update_lo_1_value: myflow.id_x1;

    update_hi_1_predicate: condition_lo or condition_hi;
    update_hi_1_value: register_hi + 1;

    output_predicate: condition_lo or condition_hi;
    output_value: register_lo;
    output_dst: meta.register_id_x1;
}
action freqIdAction_x1_4() {
    freqIdSalu_x1_4.execute_stateful_alu_from_hash(hash_heavy_x1_4);
}

table freqIdTable_x1_4 {
    actions {
        freqIdAction_x1_4;
    }
    default_action: freqIdAction_x1_4();
}

table updateTable_x1_4 {
    actions {
        updateAction_x1;
    }
    default_action: updateAction_x1();
}

/*---------------------step 5---------------------*/

blackbox stateful_alu miceSalu_x1 {
     // counter of mice flows
     //
     // Whenever a flow goes through the previous 4 steps, it will be counted here.

    reg: miceReg_x1;
    update_lo_1_value: register_lo + 1;
}
action miceAction_x1() {
    // action to wrap up miceSalu
    miceSalu_x1.execute_stateful_alu_from_hash(hash_mice_x1);
}
table miceTable_x1 {
    // table to wrap up miceAction
    actions {
        miceAction_x1;
    }
    default_action: miceAction_x1();
}

/************************ sketch 2 ************************/

// registers for step 1
register totVotesReg_x2_1 {
    width: 64;
    instance_count: BUCKETS_L;
}
register freqIdReg_x2_1 {
    width: 64;
    instance_count: BUCKETS_L;
}

// registers for step 2
register totVotesReg_x2_2 {
    width: 64;
    instance_count: BUCKETS_L;
}
register freqIdReg_x2_2 {
    width: 64;
    instance_count: BUCKETS_L;
}

// registers for step 3
register totVotesReg_x2_3 {
    width: 64;
    instance_count: BUCKETS_L;
}
register freqIdReg_x2_3 {
    width: 64;
    instance_count: BUCKETS_L;
}

// registers for step 4
register totVotesReg_x2_4 {
    width: 64;
    instance_count: BUCKETS_L;
}
register freqIdReg_x2_4 {
    width: 64;
    instance_count: BUCKETS_L;
}

// registers for step 5
register miceReg_x2 {
    width: 8;
    instance_count: MICE_LEN_L;
}

/*--*--* Hash *--*--*/
field_list hash_list_x2 {
    myflow.id_x2;
}

field_list_calculation hash_heavy_x2_1 {
    input { hash_list_x2; }
    algorithm : identity;
    output_width : BUCKETS_HASH_L;
}

field_list_calculation hash_heavy_x2_2 {
    input { hash_list_x2; }
    algorithm : identity;
    output_width : BUCKETS_HASH_L;
}

field_list_calculation hash_heavy_x2_3 {
    input { hash_list_x2; }
    algorithm : identity;
    output_width : BUCKETS_HASH_L;
}

field_list_calculation hash_heavy_x2_4 {
    input { hash_list_x2; }
    algorithm : identity;
    output_width : BUCKETS_HASH_L;
}



field_list_calculation hash_mice_x2 {
    input { hash_list_x2; }
    algorithm : identity;
    output_width : MICE_LEN_HASH_L;
}


action voteDivAction_x2() {
    shift_right(meta.totVotes_div_x2, meta.totVotes_x2, LAMBDA);
}

action updateAction_x2() {
    modify_field(myflow.id_x2, meta.register_id_x2);
}

/*---------------------step 1---------------------*/
action drop_x2()
{
    modify_field(meta.cond_x2, 0);
}
table dropTable_x2_1 {
    actions {
        drop_x2;
    }
    default_action: drop_x2();
}

blackbox stateful_alu totVotesSalu_x2_1 {
    reg: totVotesReg_x2_1;
    update_lo_1_value: register_lo + 1;
    output_value: alu_lo;
    output_dst: meta.totVotes_x2;
}
action totVotesAction_x2_1() {
    totVotesSalu_x2_1.execute_stateful_alu_from_hash(hash_heavy_x2_1);
    modify_field(meta.register_id_x2, 0);
    modify_field(meta.cond_x2, 1);
}
table totVotesTable_x2_1 {
    actions {
        totVotesAction_x2_1;
    }
    default_action: totVotesAction_x2_1();
}

table voteDivTable_x2_1 {
    actions {
        voteDivAction_x2;
    }
    default_action: voteDivAction_x2();
}

blackbox stateful_alu freqIdSalu_x2_1 {
    reg: freqIdReg_x2_1;

    condition_hi: meta.totVotes_div_x2 >= register_hi;
    condition_lo: myflow.id_x2 == register_lo;

    update_lo_1_predicate: condition_lo or condition_hi;
    update_lo_1_value: myflow.id_x2;

    update_hi_1_predicate: condition_lo or condition_hi;
    update_hi_1_value: register_hi + 1;

    output_predicate: condition_lo or condition_hi;
    output_value: register_lo;
    output_dst: meta.register_id_x2;
}
action freqIdAction_x2_1() {
    freqIdSalu_x2_1.execute_stateful_alu_from_hash(hash_heavy_x2_1);
}

table freqIdTable_x2_1 {
    actions {
        freqIdAction_x2_1;
    }
    default_action: freqIdAction_x2_1();
}

table updateTable_x2_1 {
    actions {
        updateAction_x2;
    }
    default_action: updateAction_x2();
}

/*---------------------step 2---------------------*/

table dropTable_x2_2 {
    actions {
        drop_x2;
    }
    default_action: drop_x2();
}

blackbox stateful_alu totVotesSalu_x2_2 {
    reg: totVotesReg_x2_2;
    update_lo_1_value: register_lo + 1;
    output_value: alu_lo;
    output_dst: meta.totVotes_x2;
}
action totVotesAction_x2_2() {
    totVotesSalu_x2_2.execute_stateful_alu_from_hash(hash_heavy_x2_2);
    modify_field(meta.register_id_x2, 0);
}
table totVotesTable_x2_2 {
    actions {
        totVotesAction_x2_2;
    }
    default_action: totVotesAction_x2_2();
}

table voteDivTable_x2_2 {
    actions {
        voteDivAction_x2;
    }
    default_action: voteDivAction_x2();
}

blackbox stateful_alu freqIdSalu_x2_2 {
    reg: freqIdReg_x2_2;

    condition_hi: meta.totVotes_div_x2 >= register_hi;
    condition_lo: myflow.id_x2 == register_lo;

    update_lo_1_predicate: condition_lo or condition_hi;
    update_lo_1_value: myflow.id_x2;

    update_hi_1_predicate: condition_lo or condition_hi;
    update_hi_1_value: register_hi + 1;

    output_predicate: condition_lo or condition_hi;
    output_value: register_lo;
    output_dst: meta.register_id_x2;
}
action freqIdAction_x2_2() {
    freqIdSalu_x2_2.execute_stateful_alu_from_hash(hash_heavy_x2_2);
}

table freqIdTable_x2_2 {
    actions {
        freqIdAction_x2_2;
    }
    default_action: freqIdAction_x2_2();
}

table updateTable_x2_2 {
    actions {
        updateAction_x2;
    }
    default_action: updateAction_x2();
}

/*---------------------step 3---------------------*/

table dropTable_x2_3 {
    actions {
        drop_x2;
    }
    default_action: drop_x2();
}

blackbox stateful_alu totVotesSalu_x2_3 {
    reg: totVotesReg_x2_3;
    update_lo_1_value: register_lo + 1;
    output_value: alu_lo;
    output_dst: meta.totVotes_x2;
}
action totVotesAction_x2_3() {
    totVotesSalu_x2_3.execute_stateful_alu_from_hash(hash_heavy_x2_3);
    modify_field(meta.register_id_x2, 0);
}
table totVotesTable_x2_3 {
    actions {
        totVotesAction_x2_3;
    }
    default_action: totVotesAction_x2_3();
}

table voteDivTable_x2_3 {
    actions {
        voteDivAction_x2;
    }
    default_action: voteDivAction_x2();
}

blackbox stateful_alu freqIdSalu_x2_3 {
    reg: freqIdReg_x2_3;

    condition_hi: meta.totVotes_div_x2 >= register_hi;
    condition_lo: myflow.id_x2 == register_lo;

    update_lo_1_predicate: condition_lo or condition_hi;
    update_lo_1_value: myflow.id_x2;

    update_hi_1_predicate: condition_lo or condition_hi;
    update_hi_1_value: register_hi + 1;

    output_predicate: condition_lo or condition_hi;
    output_value: register_lo;
    output_dst: meta.register_id_x2;
}
action freqIdAction_x2_3() {
    freqIdSalu_x2_3.execute_stateful_alu_from_hash(hash_heavy_x2_3);
}

table freqIdTable_x2_3 {
    actions {
        freqIdAction_x2_3;
    }
    default_action: freqIdAction_x2_3();
}

table updateTable_x2_3 {
    actions {
        updateAction_x2;
    }
    default_action: updateAction_x2();
}

/*---------------------step 4---------------------*/

table dropTable_x2_4 {
    actions {
        drop_x2;
    }
    default_action: drop_x2();
}

blackbox stateful_alu totVotesSalu_x2_4 {
    reg: totVotesReg_x2_4;
    update_lo_1_value: register_lo + 1;
    output_value: alu_lo;
    output_dst: meta.totVotes_x2;
}
action totVotesAction_x2_4() {
    totVotesSalu_x2_4.execute_stateful_alu_from_hash(hash_heavy_x2_4);
    modify_field(meta.register_id_x2, 0);
}
table totVotesTable_x2_4 {
    actions {
        totVotesAction_x2_4;
    }
    default_action: totVotesAction_x2_4();
}

table voteDivTable_x2_4 {
    actions {
        voteDivAction_x2;
    }
    default_action: voteDivAction_x2();
}

blackbox stateful_alu freqIdSalu_x2_4 {
    reg: freqIdReg_x2_4;

    condition_hi: meta.totVotes_div_x2 >= register_hi;
    condition_lo: myflow.id_x2 == register_lo;

    update_lo_1_predicate: condition_lo or condition_hi;
    update_lo_1_value: myflow.id_x2;

    update_hi_1_predicate: condition_lo or condition_hi;
    update_hi_1_value: register_hi + 1;

    output_predicate: condition_lo or condition_hi;
    output_value: register_lo;
    output_dst: meta.register_id_x2;
}
action freqIdAction_x2_4() {
    freqIdSalu_x2_4.execute_stateful_alu_from_hash(hash_heavy_x2_4);
}

table freqIdTable_x2_4 {
    actions {
        freqIdAction_x2_4;
    }
    default_action: freqIdAction_x2_4();
}

table updateTable_x2_4 {
    actions {
        updateAction_x2;
    }
    default_action: updateAction_x2();
}

/*---------------------step 5---------------------*/

blackbox stateful_alu miceSalu_x2 {
     // counter of mice flows
     //
     // Whenever a flow goes through the previous 4 steps, it will be counted here.

    reg: miceReg_x2;
    update_lo_1_value: register_lo + 1;
}
action miceAction_x2() {
    // action to wrap up miceSalu
    miceSalu_x2.execute_stateful_alu_from_hash(hash_mice_x2);
}
table miceTable_x2 {
    // table to wrap up miceAction
    actions {
        miceAction_x2;
    }
    default_action: miceAction_x2();
}

/************************ sketch 3 ************************/

// registers for step 1
register totVotesReg_x3_1 {
    width: 64;
    instance_count: BUCKETS_L;
}
register freqIdReg_x3_1 {
    width: 64;
    instance_count: BUCKETS_L;
}

// registers for step 2
register totVotesReg_x3_2 {
    width: 64;
    instance_count: BUCKETS_L;
}
register freqIdReg_x3_2 {
    width: 64;
    instance_count: BUCKETS_L;
}

// registers for step 3
register totVotesReg_x3_3 {
    width: 64;
    instance_count: BUCKETS_L;
}
register freqIdReg_x3_3 {
    width: 64;
    instance_count: BUCKETS_L;
}

// registers for step 4
register totVotesReg_x3_4 {
    width: 64;
    instance_count: BUCKETS_L;
}
register freqIdReg_x3_4 {
    width: 64;
    instance_count: BUCKETS_L;
}

// registers for step 5
register miceReg_x3 {
    width: 8;
    instance_count: MICE_LEN_L;
}

/*--*--* Hash *--*--*/
field_list hash_list_x3 {
    myflow.id_x3;
}

field_list_calculation hash_heavy_x3_1 {
    input { hash_list_x3; }
    algorithm : identity;
    output_width : BUCKETS_HASH_L;
}

field_list_calculation hash_heavy_x3_2 {
    input { hash_list_x3; }
    algorithm : identity;
    output_width : BUCKETS_HASH_L;
}

field_list_calculation hash_heavy_x3_3 {
    input { hash_list_x3; }
    algorithm : identity;
    output_width : BUCKETS_HASH_L;
}

field_list_calculation hash_heavy_x3_4 {
    input { hash_list_x3; }
    algorithm : identity;
    output_width : BUCKETS_HASH_L;
}



field_list_calculation hash_mice_x3 {
    input { hash_list_x3; }
    algorithm : identity;
    output_width : MICE_LEN_HASH_L;
}


action voteDivAction_x3() {
    shift_right(meta.totVotes_div_x3, meta.totVotes_x3, LAMBDA);
}

action updateAction_x3() {
    modify_field(myflow.id_x3, meta.register_id_x3);
}

/*---------------------step 1---------------------*/
action drop_x3()
{
    modify_field(meta.cond_x3, 0);
}
table dropTable_x3_1 {
    actions {
        drop_x3;
    }
    default_action: drop_x3();
}

blackbox stateful_alu totVotesSalu_x3_1 {
    reg: totVotesReg_x3_1;
    update_lo_1_value: register_lo + 1;
    output_value: alu_lo;
    output_dst: meta.totVotes_x3;
}
action totVotesAction_x3_1() {
    totVotesSalu_x3_1.execute_stateful_alu_from_hash(hash_heavy_x3_1);
    modify_field(meta.register_id_x3, 0);
    modify_field(meta.cond_x3, 1);
}
table totVotesTable_x3_1 {
    actions {
        totVotesAction_x3_1;
    }
    default_action: totVotesAction_x3_1();
}

table voteDivTable_x3_1 {
    actions {
        voteDivAction_x3;
    }
    default_action: voteDivAction_x3();
}

blackbox stateful_alu freqIdSalu_x3_1 {
    reg: freqIdReg_x3_1;

    condition_hi: meta.totVotes_div_x3 >= register_hi;
    condition_lo: myflow.id_x3 == register_lo;

    update_lo_1_predicate: condition_lo or condition_hi;
    update_lo_1_value: myflow.id_x3;

    update_hi_1_predicate: condition_lo or condition_hi;
    update_hi_1_value: register_hi + 1;

    output_predicate: condition_lo or condition_hi;
    output_value: register_lo;
    output_dst: meta.register_id_x3;
}
action freqIdAction_x3_1() {
    freqIdSalu_x3_1.execute_stateful_alu_from_hash(hash_heavy_x3_1);
}

table freqIdTable_x3_1 {
    actions {
        freqIdAction_x3_1;
    }
    default_action: freqIdAction_x3_1();
}

table updateTable_x3_1 {
    actions {
        updateAction_x3;
    }
    default_action: updateAction_x3();
}

/*---------------------step 2---------------------*/

table dropTable_x3_2 {
    actions {
        drop_x3;
    }
    default_action: drop_x3();
}

blackbox stateful_alu totVotesSalu_x3_2 {
    reg: totVotesReg_x3_2;
    update_lo_1_value: register_lo + 1;
    output_value: alu_lo;
    output_dst: meta.totVotes_x3;
}
action totVotesAction_x3_2() {
    totVotesSalu_x3_2.execute_stateful_alu_from_hash(hash_heavy_x3_2);
    modify_field(meta.register_id_x3, 0);
}
table totVotesTable_x3_2 {
    actions {
        totVotesAction_x3_2;
    }
    default_action: totVotesAction_x3_2();
}

table voteDivTable_x3_2 {
    actions {
        voteDivAction_x3;
    }
    default_action: voteDivAction_x3();
}

blackbox stateful_alu freqIdSalu_x3_2 {
    reg: freqIdReg_x3_2;

    condition_hi: meta.totVotes_div_x3 >= register_hi;
    condition_lo: myflow.id_x3 == register_lo;

    update_lo_1_predicate: condition_lo or condition_hi;
    update_lo_1_value: myflow.id_x3;

    update_hi_1_predicate: condition_lo or condition_hi;
    update_hi_1_value: register_hi + 1;

    output_predicate: condition_lo or condition_hi;
    output_value: register_lo;
    output_dst: meta.register_id_x3;
}
action freqIdAction_x3_2() {
    freqIdSalu_x3_2.execute_stateful_alu_from_hash(hash_heavy_x3_2);
}

table freqIdTable_x3_2 {
    actions {
        freqIdAction_x3_2;
    }
    default_action: freqIdAction_x3_2();
}

table updateTable_x3_2 {
    actions {
        updateAction_x3;
    }
    default_action: updateAction_x3();
}

/*---------------------step 3---------------------*/

table dropTable_x3_3 {
    actions {
        drop_x3;
    }
    default_action: drop_x3();
}

blackbox stateful_alu totVotesSalu_x3_3 {
    reg: totVotesReg_x3_3;
    update_lo_1_value: register_lo + 1;
    output_value: alu_lo;
    output_dst: meta.totVotes_x3;
}
action totVotesAction_x3_3() {
    totVotesSalu_x3_3.execute_stateful_alu_from_hash(hash_heavy_x3_3);
    modify_field(meta.register_id_x3, 0);
}
table totVotesTable_x3_3 {
    actions {
        totVotesAction_x3_3;
    }
    default_action: totVotesAction_x3_3();
}

table voteDivTable_x3_3 {
    actions {
        voteDivAction_x3;
    }
    default_action: voteDivAction_x3();
}

blackbox stateful_alu freqIdSalu_x3_3 {
    reg: freqIdReg_x3_3;

    condition_hi: meta.totVotes_div_x3 >= register_hi;
    condition_lo: myflow.id_x3 == register_lo;

    update_lo_1_predicate: condition_lo or condition_hi;
    update_lo_1_value: myflow.id_x3;

    update_hi_1_predicate: condition_lo or condition_hi;
    update_hi_1_value: register_hi + 1;

    output_predicate: condition_lo or condition_hi;
    output_value: register_lo;
    output_dst: meta.register_id_x3;
}
action freqIdAction_x3_3() {
    freqIdSalu_x3_3.execute_stateful_alu_from_hash(hash_heavy_x3_3);
}

table freqIdTable_x3_3 {
    actions {
        freqIdAction_x3_3;
    }
    default_action: freqIdAction_x3_3();
}

table updateTable_x3_3 {
    actions {
        updateAction_x3;
    }
    default_action: updateAction_x3();
}

/*---------------------step 4---------------------*/

table dropTable_x3_4 {
    actions {
        drop_x3;
    }
    default_action: drop_x3();
}

blackbox stateful_alu totVotesSalu_x3_4 {
    reg: totVotesReg_x3_4;
    update_lo_1_value: register_lo + 1;
    output_value: alu_lo;
    output_dst: meta.totVotes_x3;
}
action totVotesAction_x3_4() {
    totVotesSalu_x3_4.execute_stateful_alu_from_hash(hash_heavy_x3_4);
    modify_field(meta.register_id_x3, 0);
}
table totVotesTable_x3_4 {
    actions {
        totVotesAction_x3_4;
    }
    default_action: totVotesAction_x3_4();
}

table voteDivTable_x3_4 {
    actions {
        voteDivAction_x3;
    }
    default_action: voteDivAction_x3();
}

blackbox stateful_alu freqIdSalu_x3_4 {
    reg: freqIdReg_x3_4;

    condition_hi: meta.totVotes_div_x3 >= register_hi;
    condition_lo: myflow.id_x3 == register_lo;

    update_lo_1_predicate: condition_lo or condition_hi;
    update_lo_1_value: myflow.id_x3;

    update_hi_1_predicate: condition_lo or condition_hi;
    update_hi_1_value: register_hi + 1;

    output_predicate: condition_lo or condition_hi;
    output_value: register_lo;
    output_dst: meta.register_id_x3;
}
action freqIdAction_x3_4() {
    freqIdSalu_x3_4.execute_stateful_alu_from_hash(hash_heavy_x3_4);
}

table freqIdTable_x3_4 {
    actions {
        freqIdAction_x3_4;
    }
    default_action: freqIdAction_x3_4();
}

table updateTable_x3_4 {
    actions {
        updateAction_x3;
    }
    default_action: updateAction_x3();
}

/*---------------------step 5---------------------*/

blackbox stateful_alu miceSalu_x3 {
     // counter of mice flows
     //
     // Whenever a flow goes through the previous 4 steps, it will be counted here.

    reg: miceReg_x3;
    update_lo_1_value: register_lo + 1;
}
action miceAction_x3() {
    // action to wrap up miceSalu
    miceSalu_x3.execute_stateful_alu_from_hash(hash_mice_x3);
}
table miceTable_x3 {
    // table to wrap up miceAction
    actions {
        miceAction_x3;
    }
    default_action: miceAction_x3();
}

/************************ sketch 4 ************************/

// registers for step 1
register totVotesReg_x4_1 {
    width: 64;
    instance_count: BUCKETS_S;
}
register freqIdReg_x4_1 {
    width: 64;
    instance_count: BUCKETS_S;
}

// registers for step 2
register totVotesReg_x4_2 {
    width: 64;
    instance_count: BUCKETS_S;
}
register freqIdReg_x4_2 {
    width: 64;
    instance_count: BUCKETS_S;
}

// registers for step 3
register totVotesReg_x4_3 {
    width: 64;
    instance_count: BUCKETS_S;
}
register freqIdReg_x4_3 {
    width: 64;
    instance_count: BUCKETS_S;
}

// registers for step 4
register totVotesReg_x4_4 {
    width: 64;
    instance_count: BUCKETS_S;
}
register freqIdReg_x4_4 {
    width: 64;
    instance_count: BUCKETS_S;
}

// registers for step 5
register miceReg_x4 {
    width: 8;
    instance_count: MICE_LEN_S;
}

/*--*--* Hash *--*--*/
field_list hash_list_x4 {
    myflow.id_x4;
}

field_list_calculation hash_heavy_x4_1 {
    input { hash_list_x4; }
    algorithm : identity;
    output_width : BUCKETS_HASH_S;
}

field_list_calculation hash_heavy_x4_2 {
    input { hash_list_x4; }
    algorithm : identity;
    output_width : BUCKETS_HASH_S;
}

field_list_calculation hash_heavy_x4_3 {
    input { hash_list_x4; }
    algorithm : identity;
    output_width : BUCKETS_HASH_S;
}

field_list_calculation hash_heavy_x4_4 {
    input { hash_list_x4; }
    algorithm : identity;
    output_width : BUCKETS_HASH_S;
}



field_list_calculation hash_mice_x4 {
    input { hash_list_x4; }
    algorithm : identity;
    output_width : MICE_LEN_HASH_S;
}


action voteDivAction_x4() {
    shift_right(meta.totVotes_div_x4, meta.totVotes_x4, LAMBDA);
}

action updateAction_x4() {
    modify_field(myflow.id_x4, meta.register_id_x4);
}

/*---------------------step 1---------------------*/
action drop_x4()
{
    modify_field(meta.cond_x4, 0);
}
table dropTable_x4_1 {
    actions {
        drop_x4;
    }
    default_action: drop_x4();
}

blackbox stateful_alu totVotesSalu_x4_1 {
    reg: totVotesReg_x4_1;
    update_lo_1_value: register_lo + 1;
    output_value: alu_lo;
    output_dst: meta.totVotes_x4;
}
action totVotesAction_x4_1() {
    totVotesSalu_x4_1.execute_stateful_alu_from_hash(hash_heavy_x4_1);
    modify_field(meta.register_id_x4, 0);
    modify_field(meta.cond_x4, 1);
}
table totVotesTable_x4_1 {
    actions {
        totVotesAction_x4_1;
    }
    default_action: totVotesAction_x4_1();
}

table voteDivTable_x4_1 {
    actions {
        voteDivAction_x4;
    }
    default_action: voteDivAction_x4();
}

blackbox stateful_alu freqIdSalu_x4_1 {
    reg: freqIdReg_x4_1;

    condition_hi: meta.totVotes_div_x4 >= register_hi;
    condition_lo: myflow.id_x4 == register_lo;

    update_lo_1_predicate: condition_lo or condition_hi;
    update_lo_1_value: myflow.id_x4;

    update_hi_1_predicate: condition_lo or condition_hi;
    update_hi_1_value: register_hi + 1;

    output_predicate: condition_lo or condition_hi;
    output_value: register_lo;
    output_dst: meta.register_id_x4;
}
action freqIdAction_x4_1() {
    freqIdSalu_x4_1.execute_stateful_alu_from_hash(hash_heavy_x4_1);
}

table freqIdTable_x4_1 {
    actions {
        freqIdAction_x4_1;
    }
    default_action: freqIdAction_x4_1();
}

table updateTable_x4_1 {
    actions {
        updateAction_x4;
    }
    default_action: updateAction_x4();
}

/*---------------------step 2---------------------*/

table dropTable_x4_2 {
    actions {
        drop_x4;
    }
    default_action: drop_x4();
}

blackbox stateful_alu totVotesSalu_x4_2 {
    reg: totVotesReg_x4_2;
    update_lo_1_value: register_lo + 1;
    output_value: alu_lo;
    output_dst: meta.totVotes_x4;
}
action totVotesAction_x4_2() {
    totVotesSalu_x4_2.execute_stateful_alu_from_hash(hash_heavy_x4_2);
    modify_field(meta.register_id_x4, 0);
}
table totVotesTable_x4_2 {
    actions {
        totVotesAction_x4_2;
    }
    default_action: totVotesAction_x4_2();
}

table voteDivTable_x4_2 {
    actions {
        voteDivAction_x4;
    }
    default_action: voteDivAction_x4();
}

blackbox stateful_alu freqIdSalu_x4_2 {
    reg: freqIdReg_x4_2;

    condition_hi: meta.totVotes_div_x4 >= register_hi;
    condition_lo: myflow.id_x4 == register_lo;

    update_lo_1_predicate: condition_lo or condition_hi;
    update_lo_1_value: myflow.id_x4;

    update_hi_1_predicate: condition_lo or condition_hi;
    update_hi_1_value: register_hi + 1;

    output_predicate: condition_lo or condition_hi;
    output_value: register_lo;
    output_dst: meta.register_id_x4;
}
action freqIdAction_x4_2() {
    freqIdSalu_x4_2.execute_stateful_alu_from_hash(hash_heavy_x4_2);
}

table freqIdTable_x4_2 {
    actions {
        freqIdAction_x4_2;
    }
    default_action: freqIdAction_x4_2();
}

table updateTable_x4_2 {
    actions {
        updateAction_x4;
    }
    default_action: updateAction_x4();
}

/*---------------------step 3---------------------*/

table dropTable_x4_3 {
    actions {
        drop_x4;
    }
    default_action: drop_x4();
}

blackbox stateful_alu totVotesSalu_x4_3 {
    reg: totVotesReg_x4_3;
    update_lo_1_value: register_lo + 1;
    output_value: alu_lo;
    output_dst: meta.totVotes_x4;
}
action totVotesAction_x4_3() {
    totVotesSalu_x4_3.execute_stateful_alu_from_hash(hash_heavy_x4_3);
    modify_field(meta.register_id_x4, 0);
}
table totVotesTable_x4_3 {
    actions {
        totVotesAction_x4_3;
    }
    default_action: totVotesAction_x4_3();
}

table voteDivTable_x4_3 {
    actions {
        voteDivAction_x4;
    }
    default_action: voteDivAction_x4();
}

blackbox stateful_alu freqIdSalu_x4_3 {
    reg: freqIdReg_x4_3;

    condition_hi: meta.totVotes_div_x4 >= register_hi;
    condition_lo: myflow.id_x4 == register_lo;

    update_lo_1_predicate: condition_lo or condition_hi;
    update_lo_1_value: myflow.id_x4;

    update_hi_1_predicate: condition_lo or condition_hi;
    update_hi_1_value: register_hi + 1;

    output_predicate: condition_lo or condition_hi;
    output_value: register_lo;
    output_dst: meta.register_id_x4;
}
action freqIdAction_x4_3() {
    freqIdSalu_x4_3.execute_stateful_alu_from_hash(hash_heavy_x4_3);
}

table freqIdTable_x4_3 {
    actions {
        freqIdAction_x4_3;
    }
    default_action: freqIdAction_x4_3();
}

table updateTable_x4_3 {
    actions {
        updateAction_x4;
    }
    default_action: updateAction_x4();
}

/*---------------------step 4---------------------*/

table dropTable_x4_4 {
    actions {
        drop_x4;
    }
    default_action: drop_x4();
}

blackbox stateful_alu totVotesSalu_x4_4 {
    reg: totVotesReg_x4_4;
    update_lo_1_value: register_lo + 1;
    output_value: alu_lo;
    output_dst: meta.totVotes_x4;
}
action totVotesAction_x4_4() {
    totVotesSalu_x4_4.execute_stateful_alu_from_hash(hash_heavy_x4_4);
    modify_field(meta.register_id_x4, 0);
}
table totVotesTable_x4_4 {
    actions {
        totVotesAction_x4_4;
    }
    default_action: totVotesAction_x4_4();
}

table voteDivTable_x4_4 {
    actions {
        voteDivAction_x4;
    }
    default_action: voteDivAction_x4();
}

blackbox stateful_alu freqIdSalu_x4_4 {
    reg: freqIdReg_x4_4;

    condition_hi: meta.totVotes_div_x4 >= register_hi;
    condition_lo: myflow.id_x4 == register_lo;

    update_lo_1_predicate: condition_lo or condition_hi;
    update_lo_1_value: myflow.id_x4;

    update_hi_1_predicate: condition_lo or condition_hi;
    update_hi_1_value: register_hi + 1;

    output_predicate: condition_lo or condition_hi;
    output_value: register_lo;
    output_dst: meta.register_id_x4;
}
action freqIdAction_x4_4() {
    freqIdSalu_x4_4.execute_stateful_alu_from_hash(hash_heavy_x4_4);
}

table freqIdTable_x4_4 {
    actions {
        freqIdAction_x4_4;
    }
    default_action: freqIdAction_x4_4();
}

table updateTable_x4_4 {
    actions {
        updateAction_x4;
    }
    default_action: updateAction_x4();
}

/*---------------------step 5---------------------*/

blackbox stateful_alu miceSalu_x4 {
     // counter of mice flows
     //
     // Whenever a flow goes through the previous 4 steps, it will be counted here.

    reg: miceReg_x4;
    update_lo_1_value: register_lo + 1;
}
action miceAction_x4() {
    // action to wrap up miceSalu
    miceSalu_x4.execute_stateful_alu_from_hash(hash_mice_x4);
}
table miceTable_x4 {
    // table to wrap up miceAction
    actions {
        miceAction_x4;
    }
    default_action: miceAction_x4();
}

/************************ sketch 5 ************************/

// registers for step 1
register totVotesReg_x5_1 {
    width: 64;
    instance_count: BUCKETS_S;
}
register freqIdReg_x5_1 {
    width: 64;
    instance_count: BUCKETS_S;
}

// registers for step 2
register totVotesReg_x5_2 {
    width: 64;
    instance_count: BUCKETS_S;
}
register freqIdReg_x5_2 {
    width: 64;
    instance_count: BUCKETS_S;
}

// registers for step 3
register totVotesReg_x5_3 {
    width: 64;
    instance_count: BUCKETS_S;
}
register freqIdReg_x5_3 {
    width: 64;
    instance_count: BUCKETS_S;
}

// registers for step 4
register totVotesReg_x5_4 {
    width: 64;
    instance_count: BUCKETS_S;
}
register freqIdReg_x5_4 {
    width: 64;
    instance_count: BUCKETS_S;
}

// registers for step 5
register miceReg_x5 {
    width: 8;
    instance_count: MICE_LEN_S;
}

/*--*--* Hash *--*--*/
field_list hash_list_x5 {
    myflow.id_x5;
}

field_list_calculation hash_heavy_x5_1 {
    input { hash_list_x5; }
    algorithm : identity;
    output_width : BUCKETS_HASH_S;
}

field_list_calculation hash_heavy_x5_2 {
    input { hash_list_x5; }
    algorithm : identity;
    output_width : BUCKETS_HASH_S;
}

field_list_calculation hash_heavy_x5_3 {
    input { hash_list_x5; }
    algorithm : identity;
    output_width : BUCKETS_HASH_S;
}

field_list_calculation hash_heavy_x5_4 {
    input { hash_list_x5; }
    algorithm : identity;
    output_width : BUCKETS_HASH_S;
}



field_list_calculation hash_mice_x5 {
    input { hash_list_x5; }
    algorithm : identity;
    output_width : MICE_LEN_HASH_S;
}


action voteDivAction_x5() {
    shift_right(meta.totVotes_div_x5, meta.totVotes_x5, LAMBDA);
}

action updateAction_x5() {
    modify_field(myflow.id_x5, meta.register_id_x5);
}

/*---------------------step 1---------------------*/
action drop_x5()
{
    modify_field(meta.cond_x5, 0);
}
table dropTable_x5_1 {
    actions {
        drop_x5;
    }
    default_action: drop_x5();
}

blackbox stateful_alu totVotesSalu_x5_1 {
    reg: totVotesReg_x5_1;
    update_lo_1_value: register_lo + 1;
    output_value: alu_lo;
    output_dst: meta.totVotes_x5;
}
action totVotesAction_x5_1() {
    totVotesSalu_x5_1.execute_stateful_alu_from_hash(hash_heavy_x5_1);
    modify_field(meta.register_id_x5, 0);
    modify_field(meta.cond_x5, 1);
}
table totVotesTable_x5_1 {
    actions {
        totVotesAction_x5_1;
    }
    default_action: totVotesAction_x5_1();
}

table voteDivTable_x5_1 {
    actions {
        voteDivAction_x5;
    }
    default_action: voteDivAction_x5();
}

blackbox stateful_alu freqIdSalu_x5_1 {
    reg: freqIdReg_x5_1;

    condition_hi: meta.totVotes_div_x5 >= register_hi;
    condition_lo: myflow.id_x5 == register_lo;

    update_lo_1_predicate: condition_lo or condition_hi;
    update_lo_1_value: myflow.id_x5;

    update_hi_1_predicate: condition_lo or condition_hi;
    update_hi_1_value: register_hi + 1;

    output_predicate: condition_lo or condition_hi;
    output_value: register_lo;
    output_dst: meta.register_id_x5;
}
action freqIdAction_x5_1() {
    freqIdSalu_x5_1.execute_stateful_alu_from_hash(hash_heavy_x5_1);
}

table freqIdTable_x5_1 {
    actions {
        freqIdAction_x5_1;
    }
    default_action: freqIdAction_x5_1();
}

table updateTable_x5_1 {
    actions {
        updateAction_x5;
    }
    default_action: updateAction_x5();
}

/*---------------------step 2---------------------*/

table dropTable_x5_2 {
    actions {
        drop_x5;
    }
    default_action: drop_x5();
}

blackbox stateful_alu totVotesSalu_x5_2 {
    reg: totVotesReg_x5_2;
    update_lo_1_value: register_lo + 1;
    output_value: alu_lo;
    output_dst: meta.totVotes_x5;
}
action totVotesAction_x5_2() {
    totVotesSalu_x5_2.execute_stateful_alu_from_hash(hash_heavy_x5_2);
    modify_field(meta.register_id_x5, 0);
}
table totVotesTable_x5_2 {
    actions {
        totVotesAction_x5_2;
    }
    default_action: totVotesAction_x5_2();
}

table voteDivTable_x5_2 {
    actions {
        voteDivAction_x5;
    }
    default_action: voteDivAction_x5();
}

blackbox stateful_alu freqIdSalu_x5_2 {
    reg: freqIdReg_x5_2;

    condition_hi: meta.totVotes_div_x5 >= register_hi;
    condition_lo: myflow.id_x5 == register_lo;

    update_lo_1_predicate: condition_lo or condition_hi;
    update_lo_1_value: myflow.id_x5;

    update_hi_1_predicate: condition_lo or condition_hi;
    update_hi_1_value: register_hi + 1;

    output_predicate: condition_lo or condition_hi;
    output_value: register_lo;
    output_dst: meta.register_id_x5;
}
action freqIdAction_x5_2() {
    freqIdSalu_x5_2.execute_stateful_alu_from_hash(hash_heavy_x5_2);
}

table freqIdTable_x5_2 {
    actions {
        freqIdAction_x5_2;
    }
    default_action: freqIdAction_x5_2();
}

table updateTable_x5_2 {
    actions {
        updateAction_x5;
    }
    default_action: updateAction_x5();
}

/*---------------------step 3---------------------*/

table dropTable_x5_3 {
    actions {
        drop_x5;
    }
    default_action: drop_x5();
}

blackbox stateful_alu totVotesSalu_x5_3 {
    reg: totVotesReg_x5_3;
    update_lo_1_value: register_lo + 1;
    output_value: alu_lo;
    output_dst: meta.totVotes_x5;
}
action totVotesAction_x5_3() {
    totVotesSalu_x5_3.execute_stateful_alu_from_hash(hash_heavy_x5_3);
    modify_field(meta.register_id_x5, 0);
}
table totVotesTable_x5_3 {
    actions {
        totVotesAction_x5_3;
    }
    default_action: totVotesAction_x5_3();
}

table voteDivTable_x5_3 {
    actions {
        voteDivAction_x5;
    }
    default_action: voteDivAction_x5();
}

blackbox stateful_alu freqIdSalu_x5_3 {
    reg: freqIdReg_x5_3;

    condition_hi: meta.totVotes_div_x5 >= register_hi;
    condition_lo: myflow.id_x5 == register_lo;

    update_lo_1_predicate: condition_lo or condition_hi;
    update_lo_1_value: myflow.id_x5;

    update_hi_1_predicate: condition_lo or condition_hi;
    update_hi_1_value: register_hi + 1;

    output_predicate: condition_lo or condition_hi;
    output_value: register_lo;
    output_dst: meta.register_id_x5;
}
action freqIdAction_x5_3() {
    freqIdSalu_x5_3.execute_stateful_alu_from_hash(hash_heavy_x5_3);
}

table freqIdTable_x5_3 {
    actions {
        freqIdAction_x5_3;
    }
    default_action: freqIdAction_x5_3();
}

table updateTable_x5_3 {
    actions {
        updateAction_x5;
    }
    default_action: updateAction_x5();
}

/*---------------------step 4---------------------*/

table dropTable_x5_4 {
    actions {
        drop_x5;
    }
    default_action: drop_x5();
}

blackbox stateful_alu totVotesSalu_x5_4 {
    reg: totVotesReg_x5_4;
    update_lo_1_value: register_lo + 1;
    output_value: alu_lo;
    output_dst: meta.totVotes_x5;
}
action totVotesAction_x5_4() {
    totVotesSalu_x5_4.execute_stateful_alu_from_hash(hash_heavy_x5_4);
    modify_field(meta.register_id_x5, 0);
}
table totVotesTable_x5_4 {
    actions {
        totVotesAction_x5_4;
    }
    default_action: totVotesAction_x5_4();
}

table voteDivTable_x5_4 {
    actions {
        voteDivAction_x5;
    }
    default_action: voteDivAction_x5();
}

blackbox stateful_alu freqIdSalu_x5_4 {
    reg: freqIdReg_x5_4;

    condition_hi: meta.totVotes_div_x5 >= register_hi;
    condition_lo: myflow.id_x5 == register_lo;

    update_lo_1_predicate: condition_lo or condition_hi;
    update_lo_1_value: myflow.id_x5;

    update_hi_1_predicate: condition_lo or condition_hi;
    update_hi_1_value: register_hi + 1;

    output_predicate: condition_lo or condition_hi;
    output_value: register_lo;
    output_dst: meta.register_id_x5;
}
action freqIdAction_x5_4() {
    freqIdSalu_x5_4.execute_stateful_alu_from_hash(hash_heavy_x5_4);
}

table freqIdTable_x5_4 {
    actions {
        freqIdAction_x5_4;
    }
    default_action: freqIdAction_x5_4();
}

table updateTable_x5_4 {
    actions {
        updateAction_x5;
    }
    default_action: updateAction_x5();
}

/*---------------------step 5---------------------*/

blackbox stateful_alu miceSalu_x5 {
     // counter of mice flows
     //
     // Whenever a flow goes through the previous 4 steps, it will be counted here.

    reg: miceReg_x5;
    update_lo_1_value: register_lo + 1;
}
action miceAction_x5() {
    // action to wrap up miceSalu
    miceSalu_x5.execute_stateful_alu_from_hash(hash_mice_x5);
}
table miceTable_x5 {
    // table to wrap up miceAction
    actions {
        miceAction_x5;
    }
    default_action: miceAction_x5();
}

/************************ sketch 6 ************************/

// registers for step 1
register totVotesReg_x6_1 {
    width: 64;
    instance_count: BUCKETS_S;
}
register freqIdReg_x6_1 {
    width: 64;
    instance_count: BUCKETS_S;
}

// registers for step 2
register totVotesReg_x6_2 {
    width: 64;
    instance_count: BUCKETS_S;
}
register freqIdReg_x6_2 {
    width: 64;
    instance_count: BUCKETS_S;
}

// registers for step 3
register totVotesReg_x6_3 {
    width: 64;
    instance_count: BUCKETS_S;
}
register freqIdReg_x6_3 {
    width: 64;
    instance_count: BUCKETS_S;
}

// registers for step 4
register totVotesReg_x6_4 {
    width: 64;
    instance_count: BUCKETS_S;
}
register freqIdReg_x6_4 {
    width: 64;
    instance_count: BUCKETS_S;
}

// registers for step 5
register miceReg_x6 {
    width: 8;
    instance_count: MICE_LEN_S;
}

/*--*--* Hash *--*--*/
field_list hash_list_x6 {
    myflow.id_x6;
}

field_list_calculation hash_heavy_x6_1 {
    input { hash_list_x6; }
    algorithm : identity;
    output_width : BUCKETS_HASH_S;
}

field_list_calculation hash_heavy_x6_2 {
    input { hash_list_x6; }
    algorithm : identity;
    output_width : BUCKETS_HASH_S;
}

field_list_calculation hash_heavy_x6_3 {
    input { hash_list_x6; }
    algorithm : identity;
    output_width : BUCKETS_HASH_S;
}

field_list_calculation hash_heavy_x6_4 {
    input { hash_list_x6; }
    algorithm : identity;
    output_width : BUCKETS_HASH_S;
}



field_list_calculation hash_mice_x6 {
    input { hash_list_x6; }
    algorithm : identity;
    output_width : MICE_LEN_HASH_S;
}


action voteDivAction_x6() {
    shift_right(meta.totVotes_div_x6, meta.totVotes_x6, LAMBDA);
}

action updateAction_x6() {
    modify_field(myflow.id_x6, meta.register_id_x6);
}

/*---------------------step 1---------------------*/
action drop_x6()
{
    modify_field(meta.cond_x6, 0);
}
table dropTable_x6_1 {
    actions {
        drop_x6;
    }
    default_action: drop_x6();
}

blackbox stateful_alu totVotesSalu_x6_1 {
    reg: totVotesReg_x6_1;
    update_lo_1_value: register_lo + 1;
    output_value: alu_lo;
    output_dst: meta.totVotes_x6;
}
action totVotesAction_x6_1() {
    totVotesSalu_x6_1.execute_stateful_alu_from_hash(hash_heavy_x6_1);
    modify_field(meta.register_id_x6, 0);
    modify_field(meta.cond_x6, 1);
}
table totVotesTable_x6_1 {
    actions {
        totVotesAction_x6_1;
    }
    default_action: totVotesAction_x6_1();
}

table voteDivTable_x6_1 {
    actions {
        voteDivAction_x6;
    }
    default_action: voteDivAction_x6();
}

blackbox stateful_alu freqIdSalu_x6_1 {
    reg: freqIdReg_x6_1;

    condition_hi: meta.totVotes_div_x6 >= register_hi;
    condition_lo: myflow.id_x6 == register_lo;

    update_lo_1_predicate: condition_lo or condition_hi;
    update_lo_1_value: myflow.id_x6;

    update_hi_1_predicate: condition_lo or condition_hi;
    update_hi_1_value: register_hi + 1;

    output_predicate: condition_lo or condition_hi;
    output_value: register_lo;
    output_dst: meta.register_id_x6;
}
action freqIdAction_x6_1() {
    freqIdSalu_x6_1.execute_stateful_alu_from_hash(hash_heavy_x6_1);
}

table freqIdTable_x6_1 {
    actions {
        freqIdAction_x6_1;
    }
    default_action: freqIdAction_x6_1();
}

table updateTable_x6_1 {
    actions {
        updateAction_x6;
    }
    default_action: updateAction_x6();
}

/*---------------------step 2---------------------*/

table dropTable_x6_2 {
    actions {
        drop_x6;
    }
    default_action: drop_x6();
}

blackbox stateful_alu totVotesSalu_x6_2 {
    reg: totVotesReg_x6_2;
    update_lo_1_value: register_lo + 1;
    output_value: alu_lo;
    output_dst: meta.totVotes_x6;
}
action totVotesAction_x6_2() {
    totVotesSalu_x6_2.execute_stateful_alu_from_hash(hash_heavy_x6_2);
    modify_field(meta.register_id_x6, 0);
}
table totVotesTable_x6_2 {
    actions {
        totVotesAction_x6_2;
    }
    default_action: totVotesAction_x6_2();
}

table voteDivTable_x6_2 {
    actions {
        voteDivAction_x6;
    }
    default_action: voteDivAction_x6();
}

blackbox stateful_alu freqIdSalu_x6_2 {
    reg: freqIdReg_x6_2;

    condition_hi: meta.totVotes_div_x6 >= register_hi;
    condition_lo: myflow.id_x6 == register_lo;

    update_lo_1_predicate: condition_lo or condition_hi;
    update_lo_1_value: myflow.id_x6;

    update_hi_1_predicate: condition_lo or condition_hi;
    update_hi_1_value: register_hi + 1;

    output_predicate: condition_lo or condition_hi;
    output_value: register_lo;
    output_dst: meta.register_id_x6;
}
action freqIdAction_x6_2() {
    freqIdSalu_x6_2.execute_stateful_alu_from_hash(hash_heavy_x6_2);
}

table freqIdTable_x6_2 {
    actions {
        freqIdAction_x6_2;
    }
    default_action: freqIdAction_x6_2();
}

table updateTable_x6_2 {
    actions {
        updateAction_x6;
    }
    default_action: updateAction_x6();
}

/*---------------------step 3---------------------*/

table dropTable_x6_3 {
    actions {
        drop_x6;
    }
    default_action: drop_x6();
}

blackbox stateful_alu totVotesSalu_x6_3 {
    reg: totVotesReg_x6_3;
    update_lo_1_value: register_lo + 1;
    output_value: alu_lo;
    output_dst: meta.totVotes_x6;
}
action totVotesAction_x6_3() {
    totVotesSalu_x6_3.execute_stateful_alu_from_hash(hash_heavy_x6_3);
    modify_field(meta.register_id_x6, 0);
}
table totVotesTable_x6_3 {
    actions {
        totVotesAction_x6_3;
    }
    default_action: totVotesAction_x6_3();
}

table voteDivTable_x6_3 {
    actions {
        voteDivAction_x6;
    }
    default_action: voteDivAction_x6();
}

blackbox stateful_alu freqIdSalu_x6_3 {
    reg: freqIdReg_x6_3;

    condition_hi: meta.totVotes_div_x6 >= register_hi;
    condition_lo: myflow.id_x6 == register_lo;

    update_lo_1_predicate: condition_lo or condition_hi;
    update_lo_1_value: myflow.id_x6;

    update_hi_1_predicate: condition_lo or condition_hi;
    update_hi_1_value: register_hi + 1;

    output_predicate: condition_lo or condition_hi;
    output_value: register_lo;
    output_dst: meta.register_id_x6;
}
action freqIdAction_x6_3() {
    freqIdSalu_x6_3.execute_stateful_alu_from_hash(hash_heavy_x6_3);
}

table freqIdTable_x6_3 {
    actions {
        freqIdAction_x6_3;
    }
    default_action: freqIdAction_x6_3();
}

table updateTable_x6_3 {
    actions {
        updateAction_x6;
    }
    default_action: updateAction_x6();
}

/*---------------------step 4---------------------*/

table dropTable_x6_4 {
    actions {
        drop_x6;
    }
    default_action: drop_x6();
}

blackbox stateful_alu totVotesSalu_x6_4 {
    reg: totVotesReg_x6_4;
    update_lo_1_value: register_lo + 1;
    output_value: alu_lo;
    output_dst: meta.totVotes_x6;
}
action totVotesAction_x6_4() {
    totVotesSalu_x6_4.execute_stateful_alu_from_hash(hash_heavy_x6_4);
    modify_field(meta.register_id_x6, 0);
}
table totVotesTable_x6_4 {
    actions {
        totVotesAction_x6_4;
    }
    default_action: totVotesAction_x6_4();
}

table voteDivTable_x6_4 {
    actions {
        voteDivAction_x6;
    }
    default_action: voteDivAction_x6();
}

blackbox stateful_alu freqIdSalu_x6_4 {
    reg: freqIdReg_x6_4;

    condition_hi: meta.totVotes_div_x6 >= register_hi;
    condition_lo: myflow.id_x6 == register_lo;

    update_lo_1_predicate: condition_lo or condition_hi;
    update_lo_1_value: myflow.id_x6;

    update_hi_1_predicate: condition_lo or condition_hi;
    update_hi_1_value: register_hi + 1;

    output_predicate: condition_lo or condition_hi;
    output_value: register_lo;
    output_dst: meta.register_id_x6;
}
action freqIdAction_x6_4() {
    freqIdSalu_x6_4.execute_stateful_alu_from_hash(hash_heavy_x6_4);
}

table freqIdTable_x6_4 {
    actions {
        freqIdAction_x6_4;
    }
    default_action: freqIdAction_x6_4();
}

table updateTable_x6_4 {
    actions {
        updateAction_x6;
    }
    default_action: updateAction_x6();
}

/*---------------------step 5---------------------*/

blackbox stateful_alu miceSalu_x6 {
     // counter of mice flows
     //
     // Whenever a flow goes through the previous 4 steps, it will be counted here.

    reg: miceReg_x6;
    update_lo_1_value: register_lo + 1;
}
action miceAction_x6() {
    // action to wrap up miceSalu
    miceSalu_x6.execute_stateful_alu_from_hash(hash_mice_x6);
}
table miceTable_x6 {
    // table to wrap up miceAction
    actions {
        miceAction_x6;
    }
    default_action: miceAction_x6();
}


/*--*--* CONTROL BLOCKS *--*--*/

control ingress {
    /********* sketch 1 *********/
    //step 1
    apply(totVotesTable_x1_1);
    apply(voteDivTable_x1_1);
    apply(freqIdTable_x1_1);
    if(not (meta.register_id_x1 == 0)){
        if(meta.register_id_x1 == myflow.id_x1) {
            apply(dropTable_x1_1);
        }
        apply(updateTable_x1_1);
    }
    //step 2
    apply(totVotesTable_x1_2);
    apply(voteDivTable_x1_2);
    apply(freqIdTable_x1_2);
    if(not (meta.register_id_x1 == 0)){
        if(meta.register_id_x1 == myflow.id_x1) {
            apply(dropTable_x1_2);
        }
        apply(updateTable_x1_2);
    }
    //step 3
    apply(totVotesTable_x1_3);
    apply(voteDivTable_x1_3);
    apply(freqIdTable_x1_3);
    if(not (meta.register_id_x1 == 0)){
        if(meta.register_id_x1 == myflow.id_x1) {
            apply(dropTable_x1_3);
        }
        apply(updateTable_x1_3);
    }
    /********* sketch 2 *********/
    //step 1
    apply(totVotesTable_x2_1);
    apply(voteDivTable_x2_1);
    apply(freqIdTable_x2_1);
    if(not (meta.register_id_x2 == 0)){
        if(meta.register_id_x2 == myflow.id_x2) {
            apply(dropTable_x2_1);
        }
        apply(updateTable_x2_1);
    }
    //step 2
    apply(totVotesTable_x2_2);
    apply(voteDivTable_x2_2);
    apply(freqIdTable_x2_2);
    if(not (meta.register_id_x2 == 0)){
        if(meta.register_id_x2 == myflow.id_x2) {
            apply(dropTable_x2_2);
        }
        apply(updateTable_x2_2);
    }
    //step 3
    apply(totVotesTable_x2_3);
    apply(voteDivTable_x2_3);
    apply(freqIdTable_x2_3);
    if(not (meta.register_id_x2 == 0)){
        if(meta.register_id_x2 == myflow.id_x2) {
            apply(dropTable_x2_3);
        }
        apply(updateTable_x2_3);
    }
    /********* sketch 3 *********/
    //step 1
    apply(totVotesTable_x3_1);
    apply(voteDivTable_x3_1);
    apply(freqIdTable_x3_1);
    if(not (meta.register_id_x3 == 0)){
        if(meta.register_id_x3 == myflow.id_x3) {
            apply(dropTable_x3_1);
        }
        apply(updateTable_x3_1);
    }
    //step 2
    apply(totVotesTable_x3_2);
    apply(voteDivTable_x3_2);
    apply(freqIdTable_x3_2);
    if(not (meta.register_id_x3 == 0)){
        if(meta.register_id_x3 == myflow.id_x3) {
            apply(dropTable_x3_2);
        }
        apply(updateTable_x3_2);
    }
    //step 3
    apply(totVotesTable_x3_3);
    apply(voteDivTable_x3_3);
    apply(freqIdTable_x3_3);
    if(not (meta.register_id_x3 == 0)){
        if(meta.register_id_x3 == myflow.id_x3) {
            apply(dropTable_x3_3);
        }
        apply(updateTable_x3_3);
    }
    /********* sketch 4 *********/
    //step 1
    apply(totVotesTable_x4_1);
    apply(voteDivTable_x4_1);
    apply(freqIdTable_x4_1);
    if(not (meta.register_id_x4 == 0)){
        if(meta.register_id_x4 == myflow.id_x4) {
            apply(dropTable_x4_1);
        }
        apply(updateTable_x4_1);
    }
    //step 2
    apply(totVotesTable_x4_2);
    apply(voteDivTable_x4_2);
    apply(freqIdTable_x4_2);
    if(not (meta.register_id_x4 == 0)){
        if(meta.register_id_x4 == myflow.id_x4) {
            apply(dropTable_x4_2);
        }
        apply(updateTable_x4_2);
    }
    //step 3
    apply(totVotesTable_x4_3);
    apply(voteDivTable_x4_3);
    apply(freqIdTable_x4_3);
    if(not (meta.register_id_x4 == 0)){
        if(meta.register_id_x4 == myflow.id_x4) {
            apply(dropTable_x4_3);
        }
        apply(updateTable_x4_3);
    }

    // /********* sketch 5 *********/
    // //step 1
    // apply(totVotesTable_x5_1);
    // apply(voteDivTable_x5_1);
    // apply(freqIdTable_x5_1);
    // if(not (meta.register_id_x5 == 0)){
    //     if(meta.register_id_x5 == myflow.id_x5) {
    //         apply(dropTable_x5_1);
    //     }
    //     apply(updateTable_x5_1);
    // }
    // //step 2
    // apply(totVotesTable_x5_2);
    // apply(voteDivTable_x5_2);
    // apply(freqIdTable_x5_2);
    // if(not (meta.register_id_x5 == 0)){
    //     if(meta.register_id_x5 == myflow.id_x5) {
    //         apply(dropTable_x5_2);
    //     }
    //     apply(updateTable_x5_2);
    // }
    // //step 3
    // apply(totVotesTable_x5_3);
    // apply(voteDivTable_x5_3);
    // apply(freqIdTable_x5_3);
    // if(not (meta.register_id_x5 == 0)){
    //     if(meta.register_id_x5 == myflow.id_x5) {
    //         apply(dropTable_x5_3);
    //     }
    //     apply(updateTable_x5_3);
    // }

    // /********* sketch 6 *********/
    // //step 1
    // apply(totVotesTable_x6_1);
    // apply(voteDivTable_x6_1);
    // apply(freqIdTable_x6_1);
    // if(not (meta.register_id_x6 == 0)){
    //     if(meta.register_id_x6 == myflow.id_x6) {
    //         apply(dropTable_x6_1);
    //     }
    //     apply(updateTable_x6_1);
    // }
    // //step 2
    // apply(totVotesTable_x6_2);
    // apply(voteDivTable_x6_2);
    // apply(freqIdTable_x6_2);
    // if(not (meta.register_id_x6 == 0)){
    //     if(meta.register_id_x6 == myflow.id_x6) {
    //         apply(dropTable_x6_2);
    //     }
    //     apply(updateTable_x6_2);
    // }
    // //step 3
    // apply(totVotesTable_x6_3);
    // apply(voteDivTable_x6_3);
    // apply(freqIdTable_x6_3);
    // if(not (meta.register_id_x6 == 0)){
    //     if(meta.register_id_x6 == myflow.id_x6) {
    //         apply(dropTable_x6_3);
    //     }
    //     apply(updateTable_x6_3);
    // }
}

control egress {
    /********* sketch 1 *********/
    //step 4
    apply(totVotesTable_x1_4);
    apply(voteDivTable_x1_4);
    apply(freqIdTable_x1_4);
    if(not (meta.register_id_x1 == 0)){
        if(meta.register_id_x1 == myflow.id_x1) {
            apply(dropTable_x1_4);
        }
        apply(updateTable_x1_4);
    }
    //step 5
    if(meta.cond_x1 == 1)
    {
        apply(miceTable_x1);
    }
    

    /********* sketch 2 *********/
    //step 4
    apply(totVotesTable_x2_4);
    apply(voteDivTable_x2_4);
    apply(freqIdTable_x2_4);
    if(not (meta.register_id_x2 == 0)){
        if(meta.register_id_x2 == myflow.id_x2) {
            apply(dropTable_x2_4);
        }
        apply(updateTable_x2_4);
    }
    //step 5
    if(meta.cond_x2 == 1)
    {
        apply(miceTable_x2);
    }

    /********* sketch 3 *********/
    //step 4
    apply(totVotesTable_x3_4);
    apply(voteDivTable_x3_4);
    apply(freqIdTable_x3_4);
    if(not (meta.register_id_x3 == 0)){
        if(meta.register_id_x3 == myflow.id_x3) {
            apply(dropTable_x3_4);
        }
        apply(updateTable_x3_4);
    }
    //step 5
    if(meta.cond_x3 == 1)
    {
        apply(miceTable_x3);
    }

    /********* sketch 4 *********/
    //step 4
    apply(totVotesTable_x4_4);
    apply(voteDivTable_x4_4);
    apply(freqIdTable_x4_4);
    if(not (meta.register_id_x4 == 0)){
        if(meta.register_id_x4 == myflow.id_x4) {
            apply(dropTable_x4_4);
        }
        apply(updateTable_x4_4);
    }
    //step 5
    if(meta.cond_x4 == 1)
    {
        apply(miceTable_x4);
    }

    // /********* sketch 5 *********/
    // //step 4
    // apply(totVotesTable_x5_4);
    // apply(voteDivTable_x5_4);
    // apply(freqIdTable_x5_4);
    // if(not (meta.register_id_x5 == 0)){
    //     if(meta.register_id_x5 == myflow.id_x5) {
    //         apply(dropTable_x5_4);
    //     }
    //     apply(updateTable_x5_4);
    // }
    // //step 5
    // if(meta.cond_x5 == 1)
    // {
    //     apply(miceTable_x5);
    // }

    // /********* sketch 6 *********/
    // //step 4
    // apply(totVotesTable_x6_4);
    // apply(voteDivTable_x6_4);
    // apply(freqIdTable_x6_4);
    // if(not (meta.register_id_x6 == 0)){
    //     if(meta.register_id_x6 == myflow.id_x6) {
    //         apply(dropTable_x6_4);
    //     }
    //     apply(updateTable_x6_4);
    // }
    // //step 5
    // if(meta.cond_x6 == 1)
    // {
    //     apply(miceTable_x6);
    // }
}
