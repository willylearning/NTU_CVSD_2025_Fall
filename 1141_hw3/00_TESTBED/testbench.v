`timescale 1ns/1ps
`define CYCLE       5.0     // CLK period.
`define HCYCLE      (`CYCLE/2)
`define MAX_CYCLE   20000
`define RST_DELAY   2

`ifdef tb1
    `define INFILE "../00_TESTBED/PATTERNS/img1_030101_00.dat"
    `define WFILE  "../00_TESTBED/PATTERNS/weight_img1_030101_00.dat"
    `define GOLDEN "../00_TESTBED/PATTERNS/golden_img1_030101_00.dat"
    `define K_SIZE 3
    `define S_SIZE 1
    `define D_SIZE 1
    `define VALID_OP 1
    `define OUTPUTSIZE 4096
`elsif tb2
    `define INFILE "../00_TESTBED/PATTERNS/img1_030102_053.dat"
    `define WFILE  "../00_TESTBED/PATTERNS/weight_img1_030102_053.dat"
    `define GOLDEN "../00_TESTBED/PATTERNS/golden_img1_030102_053.dat"
    `define K_SIZE 3
    `define S_SIZE 1
    `define D_SIZE 2
    `define VALID_OP 1
    `define OUTPUTSIZE 4096
`elsif tb3
    `define INFILE "../00_TESTBED/PATTERNS/img1_030201_70.dat"
    `define WFILE  "../00_TESTBED/PATTERNS/weight_img1_030201_70.dat"
    `define GOLDEN "../00_TESTBED/PATTERNS/golden_img1_030201_70.dat"
    `define K_SIZE 3
    `define S_SIZE 2
    `define D_SIZE 1
    `define VALID_OP 1
    `define OUTPUTSIZE 1024
`elsif tb4
    `define INFILE "../00_TESTBED/PATTERNS/img1_030202_753.dat"
    `define WFILE  "../00_TESTBED/PATTERNS/weight_img1_030202_753.dat"
    `define GOLDEN "../00_TESTBED/PATTERNS/golden_img1_030202_753.dat"
    `define K_SIZE 3
    `define S_SIZE 2
    `define D_SIZE 2
    `define VALID_OP 1
    `define OUTPUTSIZE 1024
////
`elsif tb5
    `define INFILE "../00_TESTBED/PATTERNS/img1_050101_432.dat"
    `define WFILE  "../00_TESTBED/PATTERNS/weight_img1_050101_432.dat"
    `define GOLDEN "../00_TESTBED/PATTERNS/golden_img1_050101_432.dat"
    `define K_SIZE 0
    `define S_SIZE 0
    `define D_SIZE 0
    `define VALID_OP 0
    `define OUTPUTSIZE 4096
`elsif tb6
    `define INFILE "../00_TESTBED/PATTERNS/img6_030101_0054.dat"
    `define WFILE  "../00_TESTBED/PATTERNS/weight_img6_030101_0054.dat"
    `define GOLDEN "../00_TESTBED/PATTERNS/golden_img6_030101_0054.dat"
    `define K_SIZE 3
    `define S_SIZE 1
    `define D_SIZE 1
    `define VALID_OP 1
    `define OUTPUTSIZE 4096
`elsif tb7
    `define INFILE "../00_TESTBED/PATTERNS/img7_030101_0754.dat"
    `define WFILE  "../00_TESTBED/PATTERNS/weight_img7_030101_0754.dat"
    `define GOLDEN "../00_TESTBED/PATTERNS/golden_img7_030101_0754.dat"
    `define K_SIZE 3
    `define S_SIZE 1
    `define D_SIZE 1
    `define VALID_OP 1
    `define OUTPUTSIZE 4096
`elsif tb2_1
    `define INFILE "../00_TESTBED/PATTERNS/img2_030101_00.dat"
    `define WFILE  "../00_TESTBED/PATTERNS/weight_img2_030101_00.dat"
    `define GOLDEN "../00_TESTBED/PATTERNS/golden_img2_030101_00.dat"
    `define K_SIZE 3
    `define S_SIZE 1
    `define D_SIZE 1
    `define VALID_OP 1
    `define OUTPUTSIZE 4096
`elsif tb2_2
    `define INFILE "../00_TESTBED/PATTERNS/img2_030102_053.dat"
    `define WFILE  "../00_TESTBED/PATTERNS/weight_img2_030102_053.dat"
    `define GOLDEN "../00_TESTBED/PATTERNS/golden_img2_030102_053.dat"
    `define K_SIZE 3
    `define S_SIZE 1
    `define D_SIZE 2
    `define VALID_OP 1
    `define OUTPUTSIZE 4096
`elsif tb2_3
    `define INFILE "../00_TESTBED/PATTERNS/img2_030201_70.dat"
    `define WFILE  "../00_TESTBED/PATTERNS/weight_img2_030201_70.dat"
    `define GOLDEN "../00_TESTBED/PATTERNS/golden_img2_030201_70.dat"
    `define K_SIZE 3
    `define S_SIZE 2
    `define D_SIZE 1
    `define VALID_OP 1
    `define OUTPUTSIZE 1024
`elsif tb2_4
    `define INFILE "../00_TESTBED/PATTERNS/img2_030202_753.dat"
    `define WFILE  "../00_TESTBED/PATTERNS/weight_img2_030202_753.dat"
    `define GOLDEN "../00_TESTBED/PATTERNS/golden_img2_030202_753.dat"
    `define K_SIZE 3
    `define S_SIZE 2
    `define D_SIZE 2
    `define VALID_OP 1
    `define OUTPUTSIZE 1024
`elsif tb2_5
    `define INFILE "../00_TESTBED/PATTERNS/img2_050102_514.dat"
    `define WFILE  "../00_TESTBED/PATTERNS/weight_img2_050102_514.dat"
    `define GOLDEN "../00_TESTBED/PATTERNS/golden_img2_050102_514.dat"
    `define K_SIZE 0
    `define S_SIZE 0
    `define D_SIZE 0
    `define VALID_OP 0
    `define OUTPUTSIZE 4096
`elsif tb3_1
    `define INFILE "../00_TESTBED/PATTERNS/img3_030101_053.dat"
    `define WFILE  "../00_TESTBED/PATTERNS/weight_img3_030101_053.dat"
    `define GOLDEN "../00_TESTBED/PATTERNS/golden_img3_030101_053.dat"
    `define K_SIZE 3
    `define S_SIZE 1
    `define D_SIZE 1
    `define VALID_OP 1
    `define OUTPUTSIZE 4096
`elsif tb3_2
    `define INFILE "../00_TESTBED/PATTERNS/img3_030102_00.dat"
    `define WFILE  "../00_TESTBED/PATTERNS/weight_img3_030102_00.dat"
    `define GOLDEN "../00_TESTBED/PATTERNS/golden_img3_030102_00.dat"
    `define K_SIZE 3
    `define S_SIZE 1
    `define D_SIZE 2
    `define VALID_OP 1
    `define OUTPUTSIZE 4096
`elsif tb3_3
    `define INFILE "../00_TESTBED/PATTERNS/img3_030201_753.dat"
    `define WFILE  "../00_TESTBED/PATTERNS/weight_img3_030201_753.dat"
    `define GOLDEN "../00_TESTBED/PATTERNS/golden_img3_030201_753.dat"
    `define K_SIZE 3
    `define S_SIZE 2
    `define D_SIZE 1
    `define VALID_OP 1
    `define OUTPUTSIZE 1024
`elsif tb3_4
    `define INFILE "../00_TESTBED/PATTERNS/img3_030202_70.dat"
    `define WFILE  "../00_TESTBED/PATTERNS/weight_img3_030202_70.dat"
    `define GOLDEN "../00_TESTBED/PATTERNS/golden_img3_030202_70.dat"
    `define K_SIZE 3
    `define S_SIZE 2
    `define D_SIZE 2
    `define VALID_OP 1
    `define OUTPUTSIZE 1024
`elsif tb3_5
    `define INFILE "../00_TESTBED/PATTERNS/img3_050101_514.dat"
    `define WFILE  "../00_TESTBED/PATTERNS/weight_img3_050101_514.dat"
    `define GOLDEN "../00_TESTBED/PATTERNS/golden_img3_050101_514.dat"
    `define K_SIZE 0
    `define S_SIZE 0
    `define D_SIZE 0
    `define VALID_OP 0
    `define OUTPUTSIZE 4096
`elsif tb4_1
    `define INFILE "../00_TESTBED/PATTERNS/img4_030101_053.dat"
    `define WFILE  "../00_TESTBED/PATTERNS/weight_img4_030101_053.dat"
    `define GOLDEN "../00_TESTBED/PATTERNS/golden_img4_030101_053.dat"
    `define K_SIZE 3
    `define S_SIZE 1
    `define D_SIZE 1
    `define VALID_OP 1
    `define OUTPUTSIZE 4096
`elsif tb4_2
    `define INFILE "../00_TESTBED/PATTERNS/img4_030102_00.dat"
    `define WFILE  "../00_TESTBED/PATTERNS/weight_img4_030102_00.dat"
    `define GOLDEN "../00_TESTBED/PATTERNS/golden_img4_030102_00.dat"
    `define K_SIZE 3
    `define S_SIZE 1
    `define D_SIZE 2
    `define VALID_OP 1
    `define OUTPUTSIZE 4096
`elsif tb4_3
    `define INFILE "../00_TESTBED/PATTERNS/img4_030201_753.dat"
    `define WFILE  "../00_TESTBED/PATTERNS/weight_img4_030201_753.dat"
    `define GOLDEN "../00_TESTBED/PATTERNS/golden_img4_030201_753.dat"
    `define K_SIZE 3
    `define S_SIZE 2
    `define D_SIZE 1
    `define VALID_OP 1
    `define OUTPUTSIZE 1024
`elsif tb4_4
    `define INFILE "../00_TESTBED/PATTERNS/img4_030202_70.dat"
    `define WFILE  "../00_TESTBED/PATTERNS/weight_img4_030202_70.dat"
    `define GOLDEN "../00_TESTBED/PATTERNS/golden_img4_030202_70.dat"
    `define K_SIZE 3
    `define S_SIZE 2
    `define D_SIZE 2
    `define VALID_OP 1
    `define OUTPUTSIZE 1024
`elsif tb4_5
    `define INFILE "../00_TESTBED/PATTERNS/img4_040202_424.dat"
    `define WFILE  "../00_TESTBED/PATTERNS/weight_img4_040202_424.dat"
    `define GOLDEN "../00_TESTBED/PATTERNS/golden_img4_040202_424.dat"
    `define K_SIZE 0
    `define S_SIZE 0
    `define D_SIZE 0
    `define VALID_OP 0
    `define OUTPUTSIZE 4096
`elsif tb5_1
    `define INFILE "../00_TESTBED/PATTERNS/img5_030101_753.dat"
    `define WFILE  "../00_TESTBED/PATTERNS/weight_img5_030101_753.dat"
    `define GOLDEN "../00_TESTBED/PATTERNS/golden_img5_030101_753.dat"
    `define K_SIZE 3
    `define S_SIZE 1
    `define D_SIZE 1
    `define VALID_OP 1
    `define OUTPUTSIZE 4096
`elsif tb5_2
    `define INFILE "../00_TESTBED/PATTERNS/img5_030102_70.dat"
    `define WFILE  "../00_TESTBED/PATTERNS/weight_img5_030102_70.dat"
    `define GOLDEN "../00_TESTBED/PATTERNS/golden_img5_030102_70.dat"
    `define K_SIZE 3
    `define S_SIZE 1
    `define D_SIZE 2
    `define VALID_OP 1
    `define OUTPUTSIZE 4096
`elsif tb5_3
    `define INFILE "../00_TESTBED/PATTERNS/img5_030201_053.dat"
    `define WFILE  "../00_TESTBED/PATTERNS/weight_img5_030201_053.dat"
    `define GOLDEN "../00_TESTBED/PATTERNS/golden_img5_030201_053.dat"
    `define K_SIZE 3
    `define S_SIZE 2
    `define D_SIZE 1
    `define VALID_OP 1
    `define OUTPUTSIZE 1024
`elsif tb5_4
    `define INFILE "../00_TESTBED/PATTERNS/img5_030202_00.dat"
    `define WFILE  "../00_TESTBED/PATTERNS/weight_img5_030202_00.dat"
    `define GOLDEN "../00_TESTBED/PATTERNS/golden_img5_030202_00.dat"
    `define K_SIZE 3
    `define S_SIZE 2
    `define D_SIZE 2
    `define VALID_OP 1
    `define OUTPUTSIZE 1024
`elsif tb5_5
    `define INFILE "../00_TESTBED/PATTERNS/img5_114514_244.dat"
    `define WFILE  "../00_TESTBED/PATTERNS/weight_img5_114514_244.dat"
    `define GOLDEN "../00_TESTBED/PATTERNS/golden_img5_114514_244.dat"
    `define K_SIZE 0
    `define S_SIZE 0
    `define D_SIZE 0
    `define VALID_OP 0
    `define OUTPUTSIZE 4096
`elsif tb6
    `define INFILE "../00_TESTBED/PATTERNS/img6_030101_0054.dat"
    `define WFILE  "../00_TESTBED/PATTERNS/weight_img6_030101_0054.dat"
    `define GOLDEN "../00_TESTBED/PATTERNS/golden_img6_030101_0054.dat"
    `define K_SIZE 3
    `define S_SIZE 1
    `define D_SIZE 1
    `define VALID_OP 1
    `define OUTPUTSIZE 4096
`elsif tb7
    `define INFILE "../00_TESTBED/PATTERNS/img7_030101_0754.dat"
    `define WFILE  "../00_TESTBED/PATTERNS/weight_img7_030101_0754.dat"
    `define GOLDEN "../00_TESTBED/PATTERNS/golden_img7_030101_0754.dat"
    `define K_SIZE 3
    `define S_SIZE 1
    `define D_SIZE 1
    `define VALID_OP 1
    `define OUTPUTSIZE 4096     
`elsif my_tb1
    `define INFILE "../00_TESTBED/MY_PATTERN/img1_K03_S01_D01_R54_C7.dat"
    `define WFILE  "../00_TESTBED/MY_PATTERN/weight_img1_K03_S01_D01_R54_C7.dat"
    `define GOLDEN "../00_TESTBED/MY_PATTERN/golden_img1_K03_S01_D01_R54_C7.dat"
    `define K_SIZE 3
    `define S_SIZE 1
    `define D_SIZE 1
    `define VALID_OP 1
    `define OUTPUTSIZE 4096
`elsif my_tb2
    `define INFILE "../00_TESTBED/MY_PATTERN/img2_K03_S01_D01_R54_C0.dat"
    `define WFILE  "../00_TESTBED/MY_PATTERN/weight_img2_K03_S01_D01_R54_C0.dat"
    `define GOLDEN "../00_TESTBED/MY_PATTERN/golden_img2_K03_S01_D01_R54_C0.dat"
    `define K_SIZE 3
    `define S_SIZE 1
    `define D_SIZE 1
    `define VALID_OP 1
    `define OUTPUTSIZE 4096
`elsif my_tb3
    `define INFILE "../00_TESTBED/MY_PATTERN/img3_K03_S01_D02_R10_C4_prelude_partial_same_col.dat"
    `define WFILE  "../00_TESTBED/MY_PATTERN/weight_img3_K03_S01_D02_R10_C4_prelude_partial_same_col.dat"
    `define GOLDEN "../00_TESTBED/MY_PATTERN/golden_img3_K03_S01_D02_R10_C4_prelude_partial_same_col.dat"
    `define K_SIZE 3
    `define S_SIZE 1
    `define D_SIZE 2
    `define VALID_OP 1
    `define OUTPUTSIZE 4096
`elsif my_tb4
    `define INFILE "../00_TESTBED/MY_PATTERN/img4_K03_S02_D01_R52_C3_prelude_partial_same_col.dat"
    `define WFILE  "../00_TESTBED/MY_PATTERN/weight_img4_K03_S02_D01_R52_C3_prelude_partial_same_col.dat"
    `define GOLDEN "../00_TESTBED/MY_PATTERN/golden_img4_K03_S02_D01_R52_C3_prelude_partial_same_col.dat"
    `define K_SIZE 3
    `define S_SIZE 2
    `define D_SIZE 1
    `define VALID_OP 1
    `define OUTPUTSIZE 1024
`elsif my_tb5
    `define INFILE "../00_TESTBED/MY_PATTERN/img5_K03_S02_D02_R46_C2_prelude_partial_same_col.dat"
    `define WFILE  "../00_TESTBED/MY_PATTERN/weight_img5_K03_S02_D02_R46_C2_prelude_partial_same_col.dat"
    `define GOLDEN "../00_TESTBED/MY_PATTERN/golden_img5_K03_S02_D02_R46_C2_prelude_partial_same_col.dat"
    `define K_SIZE 3
    `define S_SIZE 2
    `define D_SIZE 2
    `define VALID_OP 1
    `define OUTPUTSIZE 1024
`elsif my_tb6
    `define INFILE "../00_TESTBED/MY_PATTERN/img6_K03_S02_D01_R38_C5_prelude_partial_other_col.dat"
    `define WFILE  "../00_TESTBED/MY_PATTERN/weight_img6_K03_S02_D01_R38_C5_prelude_partial_other_col.dat"
    `define GOLDEN "../00_TESTBED/MY_PATTERN/golden_img6_K03_S02_D01_R38_C5_prelude_partial_other_col.dat"
    `define K_SIZE 3
    `define S_SIZE 2
    `define D_SIZE 1
    `define VALID_OP 1
    `define OUTPUTSIZE 1024
`elsif my_tb7
    `define INFILE "../00_TESTBED/MY_PATTERN/img7_K03_S01_D01_R30_C6_skirted_start_stop.dat"
    `define WFILE  "../00_TESTBED/MY_PATTERN/weight_img7_K03_S01_D01_R30_C6_skirted_start_stop.dat"
    `define GOLDEN "../00_TESTBED/MY_PATTERN/golden_img7_K03_S01_D01_R30_C6_skirted_start_stop.dat"
    `define K_SIZE 3
    `define S_SIZE 1
    `define D_SIZE 1
    `define VALID_OP 1
    `define OUTPUTSIZE 4096
`elsif my_tb8
    `define INFILE "../00_TESTBED/MY_PATTERN/img8_K03_S01_D01_R20_C4_ladder_incomplete.dat"
    `define WFILE  "../00_TESTBED/MY_PATTERN/weight_img8_K03_S01_D01_R20_C4_ladder_incomplete.dat"
    `define GOLDEN "../00_TESTBED/MY_PATTERN/golden_img8_K03_S01_D01_R20_C4_ladder_incomplete.dat"
    `define K_SIZE 3
    `define S_SIZE 1
    `define D_SIZE 1
    `define VALID_OP 1
    `define OUTPUTSIZE 4096
`elsif my_tb9
    `define INFILE "../00_TESTBED/MY_PATTERN/img9_K03_S01_D02_R15_C5_sprinkle_noise_random.dat"
    `define WFILE  "../00_TESTBED/MY_PATTERN/weight_img9_K03_S01_D02_R15_C5_sprinkle_noise_random.dat"
    `define GOLDEN "../00_TESTBED/MY_PATTERN/golden_img9_K03_S01_D02_R15_C5_sprinkle_noise_random.dat"
    `define K_SIZE 3
    `define S_SIZE 1
    `define D_SIZE 2
    `define VALID_OP 1
    `define OUTPUTSIZE 4096
`elsif my_tb10
    `define INFILE "../00_TESTBED/MY_PATTERN/img10_K03_S01_D02_R45_C7_prelude_partial_other_col.dat"
    `define WFILE  "../00_TESTBED/MY_PATTERN/weight_img10_K03_S01_D02_R45_C7_prelude_partial_other_col.dat"
    `define GOLDEN "../00_TESTBED/MY_PATTERN/golden_img10_K03_S01_D02_R45_C7_prelude_partial_other_col.dat"
    `define K_SIZE 3
    `define S_SIZE 1
    `define D_SIZE 2
    `define VALID_OP 1
    `define OUTPUTSIZE 4096
`elsif my_tb11
    `define INFILE "../00_TESTBED/MY_PATTERN/img11_K03_S02_D02_R44_C7_prelude_partial_other_col.dat"
    `define WFILE  "../00_TESTBED/MY_PATTERN/weight_img11_K03_S02_D02_R44_C7_prelude_partial_other_col.dat"
    `define GOLDEN "../00_TESTBED/MY_PATTERN/golden_img11_K03_S02_D02_R44_C7_prelude_partial_other_col.dat"
    `define K_SIZE 3
    `define S_SIZE 2
    `define D_SIZE 2
    `define VALID_OP 1
    `define OUTPUTSIZE 1024
`elsif my_tb12
    `define INFILE "../00_TESTBED/MY_PATTERN/img12_K03_S02_D01_R38_C5_prelude_partial_other_col.dat"
    `define WFILE  "../00_TESTBED/MY_PATTERN/weight_img12_K03_S02_D01_R38_C5_prelude_partial_other_col.dat"
    `define GOLDEN "../00_TESTBED/MY_PATTERN/golden_img12_K03_S02_D01_R38_C5_prelude_partial_other_col.dat"
    `define K_SIZE 3
    `define S_SIZE 2
    `define D_SIZE 1
    `define VALID_OP 1
    `define OUTPUTSIZE 1024
`elsif my_tb13
    `define INFILE "../00_TESTBED/MY_PATTERN/img13_K03_S01_D01_R45_C7_prelude_partial_other_col.dat"
    `define WFILE  "../00_TESTBED/MY_PATTERN/weight_img13_K03_S01_D01_R45_C7_prelude_partial_other_col.dat"
    `define GOLDEN "../00_TESTBED/MY_PATTERN/golden_img13_K03_S01_D01_R45_C7_prelude_partial_other_col.dat"
    `define K_SIZE 3
    `define S_SIZE 1
    `define D_SIZE 1
    `define VALID_OP 1
    `define OUTPUTSIZE 4096
`elsif my_tb14
    `define INFILE "../00_TESTBED/MY_PATTERN/img14_K03_S02_D01_R32_C7_prelude_partial_other_col.dat"
    `define WFILE  "../00_TESTBED/MY_PATTERN/weight_img14_K03_S02_D01_R32_C7_prelude_partial_other_col.dat"
    `define GOLDEN "../00_TESTBED/MY_PATTERN/golden_img14_K03_S02_D01_R32_C7_prelude_partial_other_col.dat"
    `define K_SIZE 3
    `define S_SIZE 2
    `define D_SIZE 1
    `define VALID_OP 1
    `define OUTPUTSIZE 1024
`elsif my_tb15
    `define INFILE "../00_TESTBED/MY_PATTERN/img15_K03_S02_D02_R25_C7_prelude_partial_other_col.dat"
    `define WFILE  "../00_TESTBED/MY_PATTERN/weight_img15_K03_S02_D02_R25_C7_prelude_partial_other_col.dat"
    `define GOLDEN "../00_TESTBED/MY_PATTERN/golden_img15_K03_S02_D02_R25_C7_prelude_partial_other_col.dat"
    `define K_SIZE 3
    `define S_SIZE 2
    `define D_SIZE 2
    `define VALID_OP 1
    `define OUTPUTSIZE 1024
`elsif my_tb16
    `define INFILE "../00_TESTBED/MY_PATTERN/img16_K03_S01_D01_R45_C2_prelude_partial_other_col.dat"
    `define WFILE  "../00_TESTBED/MY_PATTERN/weight_img16_K03_S01_D01_R45_C2_prelude_partial_other_col.dat"
    `define GOLDEN "../00_TESTBED/MY_PATTERN/golden_img16_K03_S01_D01_R45_C2_prelude_partial_other_col.dat"
    `define K_SIZE 3
    `define S_SIZE 1
    `define D_SIZE 1
    `define VALID_OP 1
    `define OUTPUTSIZE 4096
`elsif my_tb17
    `define INFILE "../00_TESTBED/MY_PATTERN/img17_K03_S01_D02_R44_C5_prelude_partial_other_col.dat"
    `define WFILE  "../00_TESTBED/MY_PATTERN/weight_img17_K03_S01_D02_R44_C5_prelude_partial_other_col.dat"
    `define GOLDEN "../00_TESTBED/MY_PATTERN/golden_img17_K03_S01_D02_R44_C5_prelude_partial_other_col.dat"
    `define K_SIZE 3
    `define S_SIZE 1
    `define D_SIZE 2
    `define VALID_OP 1
    `define OUTPUTSIZE 4096
`elsif my_tb18
    `define INFILE "../00_TESTBED/MY_PATTERN/img18_K03_S01_D01_R32_C2_prelude_partial_same_col.dat"
    `define WFILE  "../00_TESTBED/MY_PATTERN/weight_img18_K03_S01_D01_R32_C2_prelude_partial_same_col.dat"
    `define GOLDEN "../00_TESTBED/MY_PATTERN/golden_img18_K03_S01_D01_R32_C2_prelude_partial_same_col.dat"
    `define K_SIZE 3
    `define S_SIZE 1
    `define D_SIZE 1
    `define VALID_OP 1
    `define OUTPUTSIZE 4096
`elsif my_tb19
    `define INFILE "../00_TESTBED/MY_PATTERN/img19_K03_S01_D02_R32_C2_prelude_partial_same_col.dat"
    `define WFILE  "../00_TESTBED/MY_PATTERN/weight_img19_K03_S01_D02_R32_C2_prelude_partial_same_col.dat"
    `define GOLDEN "../00_TESTBED/MY_PATTERN/golden_img19_K03_S01_D02_R32_C2_prelude_partial_same_col.dat"
    `define K_SIZE 3
    `define S_SIZE 1
    `define D_SIZE 2
    `define VALID_OP 1
    `define OUTPUTSIZE 4096
`elsif my_tb20
    `define INFILE "../00_TESTBED/MY_PATTERN/img20_K03_S02_D01_R32_C2_prelude_partial_same_col.dat"
    `define WFILE  "../00_TESTBED/MY_PATTERN/weight_img20_K03_S02_D01_R32_C2_prelude_partial_same_col.dat"
    `define GOLDEN "../00_TESTBED/MY_PATTERN/golden_img20_K03_S02_D01_R32_C2_prelude_partial_same_col.dat"
    `define K_SIZE 3
    `define S_SIZE 2
    `define D_SIZE 1
    `define VALID_OP 1
    `define OUTPUTSIZE 1024
// `elsif tbh
// `define INFILE "../00_TESTBED/PATTERN/.dat"
// `define WFILE  "../00_TESTBED/PATTERN/.dat"
// `define GOLDEN "../00_TESTBED/PATTERN/.dat"
// `define K_SIZE 
// `define S_SIZE 
// `define D_SIZE 
// `define VALID_OP 
// `define OUTPUTSIZE 
`else
    `define INFILE "../00_TESTBED/PATTERNS/img1_050102_514.dat"
    `define WFILE  "../00_TESTBED/PATTERNS/weight_img1_050102_514.dat"
    `define GOLDEN "../00_TESTBED/PATTERNS/golden_img1_050102_514.dat"
    `define K_SIZE 0
    `define S_SIZE 0
    `define D_SIZE 0
    `define VALID_OP 0
    `define OUTPUTSIZE 0
`endif

// Modify your sdf file name
`define SDFFILE "../02_SYN/Netlist/core_syn.sdf"


module testbed;

    reg         clk, rst_n;
    reg         in_valid;
    reg [ 31:0] in_data;
    wire        in_ready;
    wire        out_valid1;
    wire        out_valid2;
    wire        out_valid3;
    wire        out_valid4;

    wire [11:0] out_addr1;
    wire [11:0] out_addr2;
    wire [11:0] out_addr3;
    wire [11:0] out_addr4;

    wire [ 7:0] out_data1;
    wire [ 7:0] out_data2;
    wire [ 7:0] out_data3;
    wire [ 7:0] out_data4;
    
    wire        exe_finish;
    
    reg  [ 7:0] indata_mem [0:4096-1];
    reg  [ 7:0] weight_mem [0:25-1  ];
    reg  [ 7:0] golden_mem [0:4096-1];

    reg  [ 7:0] out_mem    [0:4096-1];
    
    reg stage1_finish;
    

    integer cnt1, cnt2, cnt3, cntw;
    integer cycle_count, error, error_spec, error_spec2;

    // For gate-level simulation only
    `ifdef SDF
        initial $sdf_annotate(`SDFFILE, u_core);
        initial #1 $display("SDF File %s were used for this simulation.", `SDFFILE);
    `endif

    // Write out waveform file
    initial begin
    $fsdbDumpfile("core.fsdb");
    $fsdbDumpvars(0, testbed,"+mda");
    end


    core u_core (
        .i_clk       (clk),
        .i_rst_n     (rst_n),
        .i_in_valid  (in_valid),
        .i_in_data   (in_data),

        .o_in_ready  (in_ready),

        .o_out_data1 (out_data1),
        .o_out_data2 (out_data2),
        .o_out_data3 (out_data3),
        .o_out_data4 (out_data4),

        .o_out_addr1 (out_addr1),
        .o_out_addr2 (out_addr2),
        .o_out_addr3 (out_addr3),
        .o_out_addr4 (out_addr4),

        .o_out_valid1 (out_valid1),
        .o_out_valid2 (out_valid2),
        .o_out_valid3 (out_valid3),
        .o_out_valid4 (out_valid4),

        .o_exe_finish (exe_finish)

    );

    // Read in test pattern and golden pattern
    initial $readmemh(`INFILE, indata_mem);
    initial $readmemh(`WFILE , weight_mem);
    initial $readmemh(`GOLDEN, golden_mem);

    // Clock generation
    initial clk = 1'b0;
    always begin #(`CYCLE/2) clk = ~clk; end

    // Reset generation 
    initial begin
        rst_n = 1; # (               0.25 * `CYCLE);
        rst_n = 0; # ((`RST_DELAY  + 0.7) * `CYCLE);
        rst_n = 1; # (         `MAX_CYCLE * `CYCLE);
        $display("Error! Runtime exceeded!");
        $finish;
    end

    //in_data
    initial begin
        cnt1 = 0;
        cntw = 0;
        in_valid = 0;
        wait (rst_n === 1'b0);
        wait (rst_n === 1'b1);

        // start
        @(negedge clk);
        @(negedge clk);
        in_valid = 1;
        in_data = {indata_mem[cnt1*4],indata_mem[cnt1*4 + 1],indata_mem[cnt1*4 + 2],indata_mem[cnt1*4 + 3]};

        //data_input
        wait (in_ready === 1);
        while(cnt1 < 1023) begin
            @(negedge clk);
            if(in_ready) begin
                cnt1 = cnt1 + 1;
                in_data = {indata_mem[cnt1*4],indata_mem[cnt1*4 + 1],indata_mem[cnt1*4 + 2],indata_mem[cnt1*4 + 3]};
            end
        end

        @(negedge clk);
        in_valid  = 1'b0;
        in_data   = 0;

        //weight_input
        if(`VALID_OP) begin
            wait (stage1_finish);
            @(negedge clk);
            in_valid = 1;
            in_data = {weight_mem[cntw*4],weight_mem[cntw*4 + 1],weight_mem[cntw*4 + 2],weight_mem[cntw*4 + 3]}; 

            while(cntw <= ((`K_SIZE*`K_SIZE) >> 2)) begin
                @(negedge clk);
                if(in_ready) begin
                    cntw = cntw + 1;
                    in_data = {weight_mem[cntw*4],weight_mem[cntw*4 + 1],weight_mem[cntw*4 + 2],weight_mem[cntw*4 + 3]};   
                end
            end
            in_valid = 0;
        end
    end

    //detect in_valid out_valid SPEC error
    initial begin
        error_spec = 0;

        wait (rst_n === 1'b0);
        wait (rst_n === 1'b1);
        
        while(!exe_finish) begin
            @(negedge clk);
            if(in_valid === 1 && out_valid1 === 1) begin
                $display("Time %t: SPEC Error! i_in_valid and o_out_valid1 can't be HIGH in the same time", $time);
                error_spec = error_spec + 1;
            end
            if(in_valid === 1 && out_valid2 === 1)begin
                $display("Time %t: SPEC Error! i_in_valid and o_out_valid2 can't be HIGH in the same time", $time);
                error_spec = error_spec + 1;
            end
            if(in_valid === 1 && out_valid3 === 1)begin
                $display("Time %t: SPEC Error! i_in_valid and o_out_valid3 can't be HIGH in the same time", $time);
                error_spec = error_spec + 1;
            end
            if(in_valid === 1 && out_valid4 === 1)begin
                $display("Time %t: SPEC Error! i_in_valid and o_out_valid4 can't be HIGH in the same time", $time);
                error_spec = error_spec + 1;
            end
        end

    end

    //check barcode, output
    initial begin
        error       = 0;
        error_spec2  = 0;
        cnt3        = 0;
        stage1_finish = 0;

        // reset
        wait (rst_n === 1'b0);
        wait (rst_n === 1'b1);

        // start
        $display("----------------------------------------------");
        $display("          STAGE 1:  BARCODE DECODING          ");
        $display("----------------------------------------------");

        wait((out_valid1 === 1) && (out_valid2 === 1) && (out_valid3 === 1));

        @(negedge clk);
        if ((out_valid1 === 1) && (out_valid2 === 1) && (out_valid3 === 1)) begin
            if (out_data1 !== `K_SIZE)    $display("Error!   Kernal size should be =%b, Yours=%b" ,`K_SIZE ,out_data1);
            if (out_data2 !== `S_SIZE)    $display("Error!   Stride size should be =%b, Yours=%b" ,`S_SIZE ,out_data2);
            if (out_data3 !== `D_SIZE)    $display("Error! Dilation size should be =%b, Yours=%b" ,`D_SIZE ,out_data3);
            if (out_data1 === `K_SIZE && out_data2 === `S_SIZE && out_data3 === `D_SIZE)begin
                if(`VALID_OP)   $display("All Configurations Correct! Permission Granted to Enter STAGE 2");
                else            $display("All Configurations Correct! CONGRATULATION!!!");
                stage1_finish = 1;
            end
        end

        if(`VALID_OP) begin
            $display("----------------------------------------------");
            $display("             STAGE 2:  CONVOLUTION            ");
            $display("----------------------------------------------");
            //detect out_addr SPEC error
            while (!exe_finish) begin
                @(negedge clk);
                if (out_valid1) begin
                    out_mem[out_addr1] = out_data1;
                    case (1'b1)
                        out_valid2: begin
                            if(out_addr1 === out_addr2) begin
                                $display("Time %t: Error! out_data1 and out_data2 written to the same address", $time);
                                error_spec2 = error_spec2 + 1;
                            end
                        end
                        out_valid3: begin
                            if(out_addr1 === out_addr3) begin
                                $display("Time %t: SPEC Error! out_data1 and out_data3 written to the same address", $time);
                                error_spec2 = error_spec2 + 1;
                            end
                        end
                        out_valid4: begin
                            if(out_addr1 === out_addr4) begin
                                $display("Time %t: SPEC Error! out_data1 and out_data4 written to the same address", $time);
                                error_spec2 = error_spec2 + 1;
                            end
                        end
                    endcase
                end
                if (out_valid2) begin
                    out_mem[out_addr2] = out_data2;
                    case (1'b1)
                        out_valid3: begin
                            if(out_addr2 === out_addr3) begin
                                $display("Time %t: SPEC Error! out_data2 and out_data3 written to the same address", $time);
                                error_spec2 = error_spec2 + 1;
                            end
                        end
                        out_valid4: begin
                            if(out_addr2 === out_addr4) begin
                                $display("Time %t: SPEC Error! out_data2 and out_data4 written to the same address", $time);
                                error_spec2 = error_spec2 + 1;
                            end
                        end
                    endcase
                end
                if (out_valid3) begin
                    out_mem[out_addr3] = out_data3;
                    if(out_valid4 && (out_addr3 === out_addr4)) begin
                        $display("Time %t: SPEC Error! out_data3 and out_data4 written to the same address", $time);
                        error_spec2 = error_spec2 + 1;
                    end
                end
                if (out_valid4) out_mem[out_addr4] = out_data4;
            end

            @(negedge clk);
            while (cnt3 < `OUTPUTSIZE) begin
                if (golden_mem[cnt3] !== out_mem[cnt3]) begin
                    $display("[ADDR %d] Error: golden=[%b], your answer=[%b]",cnt3, golden_mem[cnt3], out_mem[cnt3]);
                    error = error + 1;
                end
                //else $display("[ADDR %d] Correct: golden=[%b], your answer=[%b]",cnt3, golden_mem[cnt3], out_mem[cnt3]);
                cnt3 = cnt3 + 1;
            end
            $display("\n  *************************************");
            $display("  *    OVERALL COMPARISON RESULTS     *");
            $display("  *************************************");

            if (error === 0) begin
                $display("");
                $display("         #    ###############    _   _ ");
                $display("        #     #             #    *   * ");
                $display("   #   #      #   CORRECT   #      |   ");
                $display("    # #       #             #    \\___/ ");
                $display("     #        ###############          ");
                $display("");
                $display("----------------------------------------------");
                $display("       CONGRATULATION! ALL DATA PASS!       ");
                $display("----------------------------------------------\n");
            end else begin
                $display("");
                $display("    #   #     ################# ");
                $display("     # #      #               # ");
                $display("      #       #   INCORRECT   # ");
                $display("     # #      #               # ");
                $display("    #   #     ################# ");
                $display("");
                $display("----------------------------------------------");
                $display("       Wrong! Total Error for DATA:%d  ",error);
                $display("----------------------------------------------");;
            end
        end

        wait(exe_finish);
        $display("------------   Total SPEC Error: %d    ---------------", error_spec + error_spec2);

        # (2 * `CYCLE);
        $finish;
    end

endmodule
