/**********************************************************************/
/*   ____  ____                                                       */
/*  /   /\/   /                                                       */
/* /___/  \  /                                                        */
/* \   \   \/                                                         */
/*  \   \        Copyright (c) 2003-2020 Xilinx, Inc.                 */
/*  /   /        All Right Reserved.                                  */
/* /---/   /\                                                         */
/* \   \  /  \                                                        */
/*  \___\/\___\                                                       */
/**********************************************************************/

#if defined(_WIN32)
 #include "stdio.h"
 #define IKI_DLLESPEC __declspec(dllimport)
#else
 #define IKI_DLLESPEC
#endif
#include "iki.h"
#include <string.h>
#include <math.h>
#ifdef __GNUC__
#include <stdlib.h>
#else
#include <malloc.h>
#define alloca _alloca
#endif
/**********************************************************************/
/*   ____  ____                                                       */
/*  /   /\/   /                                                       */
/* /___/  \  /                                                        */
/* \   \   \/                                                         */
/*  \   \        Copyright (c) 2003-2020 Xilinx, Inc.                 */
/*  /   /        All Right Reserved.                                  */
/* /---/   /\                                                         */
/* \   \  /  \                                                        */
/*  \___\/\___\                                                       */
/**********************************************************************/

#if defined(_WIN32)
 #include "stdio.h"
 #define IKI_DLLESPEC __declspec(dllimport)
#else
 #define IKI_DLLESPEC
#endif
#include "iki.h"
#include <string.h>
#include <math.h>
#ifdef __GNUC__
#include <stdlib.h>
#else
#include <malloc.h>
#define alloca _alloca
#endif
typedef void (*funcp)(char *, char *);
extern int main(int, char**);
IKI_DLLESPEC extern void vlog_const_rhs_process_execute_0_fast_for_reg(char*, char*, char*);
IKI_DLLESPEC extern void execute_1187(char*, char *);
IKI_DLLESPEC extern void execute_4(char*, char *);
IKI_DLLESPEC extern void execute_481(char*, char *);
IKI_DLLESPEC extern void execute_482(char*, char *);
IKI_DLLESPEC extern void execute_483(char*, char *);
IKI_DLLESPEC extern void execute_484(char*, char *);
IKI_DLLESPEC extern void execute_485(char*, char *);
IKI_DLLESPEC extern void execute_486(char*, char *);
IKI_DLLESPEC extern void execute_487(char*, char *);
IKI_DLLESPEC extern void execute_488(char*, char *);
IKI_DLLESPEC extern void execute_480(char*, char *);
IKI_DLLESPEC extern void execute_7(char*, char *);
IKI_DLLESPEC extern void execute_8(char*, char *);
IKI_DLLESPEC extern void vlog_simple_process_execute_0_fast_no_reg_no_agg(char*, char*, char*);
IKI_DLLESPEC extern void execute_12(char*, char *);
IKI_DLLESPEC extern void execute_13(char*, char *);
IKI_DLLESPEC extern void execute_16(char*, char *);
IKI_DLLESPEC extern void execute_17(char*, char *);
IKI_DLLESPEC extern void execute_31(char*, char *);
IKI_DLLESPEC extern void execute_32(char*, char *);
IKI_DLLESPEC extern void execute_33(char*, char *);
IKI_DLLESPEC extern void execute_495(char*, char *);
IKI_DLLESPEC extern void execute_496(char*, char *);
IKI_DLLESPEC extern void execute_497(char*, char *);
IKI_DLLESPEC extern void execute_498(char*, char *);
IKI_DLLESPEC extern void execute_519(char*, char *);
IKI_DLLESPEC extern void execute_520(char*, char *);
IKI_DLLESPEC extern void execute_523(char*, char *);
IKI_DLLESPEC extern void execute_524(char*, char *);
IKI_DLLESPEC extern void execute_525(char*, char *);
IKI_DLLESPEC extern void execute_755(char*, char *);
IKI_DLLESPEC extern void execute_237(char*, char *);
IKI_DLLESPEC extern void execute_757(char*, char *);
IKI_DLLESPEC extern void execute_758(char*, char *);
IKI_DLLESPEC extern void execute_756(char*, char *);
IKI_DLLESPEC extern void execute_252(char*, char *);
IKI_DLLESPEC extern void execute_772(char*, char *);
IKI_DLLESPEC extern void execute_773(char*, char *);
IKI_DLLESPEC extern void execute_774(char*, char *);
IKI_DLLESPEC extern void execute_775(char*, char *);
IKI_DLLESPEC extern void execute_771(char*, char *);
IKI_DLLESPEC extern void execute_476(char*, char *);
IKI_DLLESPEC extern void execute_477(char*, char *);
IKI_DLLESPEC extern void execute_478(char*, char *);
IKI_DLLESPEC extern void execute_479(char*, char *);
IKI_DLLESPEC extern void execute_1188(char*, char *);
IKI_DLLESPEC extern void execute_1189(char*, char *);
IKI_DLLESPEC extern void execute_1190(char*, char *);
IKI_DLLESPEC extern void execute_1191(char*, char *);
IKI_DLLESPEC extern void execute_1192(char*, char *);
IKI_DLLESPEC extern void execute_1193(char*, char *);
IKI_DLLESPEC extern void vlog_transfunc_eventcallback(char*, char*, unsigned, unsigned, unsigned, char *);
IKI_DLLESPEC extern void transaction_77(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_82(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_87(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_92(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_97(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_102(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_155(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_160(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_165(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_170(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_175(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_180(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_185(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_190(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_195(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_200(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_205(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_210(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_215(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_220(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_225(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_230(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_235(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_240(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_245(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_250(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_255(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_260(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_265(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_270(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_275(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_280(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_285(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_290(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_295(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_300(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_305(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_310(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_323(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_633(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_638(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_643(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_648(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_653(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_658(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_663(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_668(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_673(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_678(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_683(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_688(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_693(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_698(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_703(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_708(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_713(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_718(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_723(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_728(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_733(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_738(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_743(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_748(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_753(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_758(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_763(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_768(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_773(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_778(char*, char*, unsigned, unsigned, unsigned);
IKI_DLLESPEC extern void transaction_783(char*, char*, unsigned, unsigned, unsigned);
funcp funcTab[123] = {(funcp)vlog_const_rhs_process_execute_0_fast_for_reg, (funcp)execute_1187, (funcp)execute_4, (funcp)execute_481, (funcp)execute_482, (funcp)execute_483, (funcp)execute_484, (funcp)execute_485, (funcp)execute_486, (funcp)execute_487, (funcp)execute_488, (funcp)execute_480, (funcp)execute_7, (funcp)execute_8, (funcp)vlog_simple_process_execute_0_fast_no_reg_no_agg, (funcp)execute_12, (funcp)execute_13, (funcp)execute_16, (funcp)execute_17, (funcp)execute_31, (funcp)execute_32, (funcp)execute_33, (funcp)execute_495, (funcp)execute_496, (funcp)execute_497, (funcp)execute_498, (funcp)execute_519, (funcp)execute_520, (funcp)execute_523, (funcp)execute_524, (funcp)execute_525, (funcp)execute_755, (funcp)execute_237, (funcp)execute_757, (funcp)execute_758, (funcp)execute_756, (funcp)execute_252, (funcp)execute_772, (funcp)execute_773, (funcp)execute_774, (funcp)execute_775, (funcp)execute_771, (funcp)execute_476, (funcp)execute_477, (funcp)execute_478, (funcp)execute_479, (funcp)execute_1188, (funcp)execute_1189, (funcp)execute_1190, (funcp)execute_1191, (funcp)execute_1192, (funcp)execute_1193, (funcp)vlog_transfunc_eventcallback, (funcp)transaction_77, (funcp)transaction_82, (funcp)transaction_87, (funcp)transaction_92, (funcp)transaction_97, (funcp)transaction_102, (funcp)transaction_155, (funcp)transaction_160, (funcp)transaction_165, (funcp)transaction_170, (funcp)transaction_175, (funcp)transaction_180, (funcp)transaction_185, (funcp)transaction_190, (funcp)transaction_195, (funcp)transaction_200, (funcp)transaction_205, (funcp)transaction_210, (funcp)transaction_215, (funcp)transaction_220, (funcp)transaction_225, (funcp)transaction_230, (funcp)transaction_235, (funcp)transaction_240, (funcp)transaction_245, (funcp)transaction_250, (funcp)transaction_255, (funcp)transaction_260, (funcp)transaction_265, (funcp)transaction_270, (funcp)transaction_275, (funcp)transaction_280, (funcp)transaction_285, (funcp)transaction_290, (funcp)transaction_295, (funcp)transaction_300, (funcp)transaction_305, (funcp)transaction_310, (funcp)transaction_323, (funcp)transaction_633, (funcp)transaction_638, (funcp)transaction_643, (funcp)transaction_648, (funcp)transaction_653, (funcp)transaction_658, (funcp)transaction_663, (funcp)transaction_668, (funcp)transaction_673, (funcp)transaction_678, (funcp)transaction_683, (funcp)transaction_688, (funcp)transaction_693, (funcp)transaction_698, (funcp)transaction_703, (funcp)transaction_708, (funcp)transaction_713, (funcp)transaction_718, (funcp)transaction_723, (funcp)transaction_728, (funcp)transaction_733, (funcp)transaction_738, (funcp)transaction_743, (funcp)transaction_748, (funcp)transaction_753, (funcp)transaction_758, (funcp)transaction_763, (funcp)transaction_768, (funcp)transaction_773, (funcp)transaction_778, (funcp)transaction_783};
const int NumRelocateId= 123;

void relocate(char *dp)
{
	iki_relocate(dp, "xsim.dir/TRNG_func_synth/xsim.reloc",  (void **)funcTab, 123);

	/*Populate the transaction function pointer field in the whole net structure */
}

void sensitize(char *dp)
{
	iki_sensitize(dp, "xsim.dir/TRNG_func_synth/xsim.reloc");
}

	// Initialize Verilog nets in mixed simulation, for the cases when the value at time 0 should be propagated from the mixed language Vhdl net

void wrapper_func_0(char *dp)

{

}

void simulate(char *dp)
{
		iki_schedule_processes_at_time_zero(dp, "xsim.dir/TRNG_func_synth/xsim.reloc");
	wrapper_func_0(dp);

	iki_execute_processes();

	// Schedule resolution functions for the multiply driven Verilog nets that have strength
	// Schedule transaction functions for the singly driven Verilog nets that have strength

}
#include "iki_bridge.h"
void relocate(char *);

void sensitize(char *);

void simulate(char *);

extern SYSTEMCLIB_IMP_DLLSPEC void local_register_implicit_channel(int, char*);
extern SYSTEMCLIB_IMP_DLLSPEC int xsim_argc_copy ;
extern SYSTEMCLIB_IMP_DLLSPEC char** xsim_argv_copy ;

int main(int argc, char **argv)
{
    iki_heap_initialize("ms", "isimmm", 0, 2147483648) ;
    iki_set_xsimdir_location_if_remapped(argc, argv)  ;
    iki_set_sv_type_file_path_name("xsim.dir/TRNG_func_synth/xsim.svtype");
    iki_set_crvs_dump_file_path_name("xsim.dir/TRNG_func_synth/xsim.crvsdump");
    void* design_handle = iki_create_design("xsim.dir/TRNG_func_synth/xsim.mem", (void *)relocate, (void *)sensitize, (void *)simulate, (void*)0, 0, isimBridge_getWdbWriter(), 0, argc, argv);
     iki_set_rc_trial_count(100);
    (void) design_handle;
    return iki_simulate_design();
}
