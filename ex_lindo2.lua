--
-- luatabox unit tests
--
-- runlindo
local Lindo = require("base_lindo")
local pars = Lindo.parameters
local errs = Lindo.errors
local info = Lindo.info

function myprintlog(pModel,str)
  printf("%s",str)
end

function myprintlog2(pModel,str)
  printf("%s",str)
  if pModel.utable and pModel.utable.ncalls  then
    pModel.utable.ncalls=pModel.utable.ncalls+1
  end
  --print_table3(pModel.utable)
end

--- Solver ex#2
-- Generated by LSwriteSrcFile (mode=+1). 
function solver_ex2()

 -- begin LP data

-------- Model sizes, objective sense and constant
  local      nErr = 0;
  local     nCons = 331;
  local     nVars = 45;
  local     dObjSense = 1 -- LS_MIN
  local     dObjConst = 0;
-------- Objective coefficients
  local  padC= 
  {
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  
  };

-------- RHS values
  local  padB= 
  {
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    22,   
  };

-------- Constraint types
  local  pszConTypes= 
  
   "GGGGGGGGGGGGGGGGGGGGGGGGGGGGGG" ..
   "GGGGGGGGGGGGGGGGGGGGGGGGGGGGGG" ..
   "GGGGGGGGGGGGGGGGGGGGGGGGGGGGGG" ..
   "GGGGGGGGGGGGGGGGGGGGGGGGGGGGGG" ..
   "GGGGGGGGGGGGGGGGGGGGGGGGGGGGGG" ..
   "GGGGGGGGGGGGGGGGGGGGGGGGGGGGGG" ..
   "GGGGGGGGGGGGGGGGGGGGGGGGGGGGGG" ..
   "GGGGGGGGGGGGGGGGGGGGGGGGGGGGGG" ..
   "GGGGGGGGGGGGGGGGGGGGGGGGGGGGGG" ..
   "GGGGGGGGGGGGGGGGGGGGGGGGGGGGGG" ..
   "GGGGGGGGGGGGGGGGGGGGGGGGGGGGGG" ..
   "G";

--------  Total nonzeros in A matrix
  local     nAnnz = 1034;
--------  Column offset
  local  paiAcols= 
  {
               0,            23,            46,            69,            92,           115, 
             138,           161,           184,           207,           230,           253, 
             276,           299,           322,           345,           368,           391, 
             415,           437,           460,           484,           508,           531, 
             554,           577,           600,           623,           645,           668, 
             691,           713,           736,           759,           782,           804, 
             827,           850,           873,           896,           919,           942, 
             965,           988,          1011,          1034,   -1
  };

--------  Column counts
  local  panAcols= 
  {
              23,            23,            23,            23,            23,            23, 
              23,            23,            23,            23,            23,            23, 
              23,            23,            23,            23,            23,            24, 
              22,            23,            24,            24,            23,            23, 
              23,            23,            23,            22,            23,            23, 
              22,            23,            23,            23,            22,            23, 
              23,            23,            23,            23,            23,            23, 
              23,            23,            23,   -1
  };

--------  A coeff
  local  padAcoef= 
  {
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1
  };

--------- Row indices
  local  paiArows= 
  {
               2,             3,             6,             9,            20,            25, 
              30,           105,           106,           107,           108,           109, 
             110,           111,           112,           113,           114,           115, 
             116,           117,           118,           119,           330,             3, 
               4,             5,             7,            21,            26,            31, 
             120,           121,           122,           123,           124,           125, 
             126,           127,           128,           129,           130,           131, 
             132,           133,           134,           330,             0,             4, 
               6,             8,            22,            27,            32,           135, 
             136,           137,           138,           139,           140,           141, 
             142,           143,           144,           145,           146,           147, 
             148,           149,           330,             0,             1,             7, 
               9,            23,            28,            33,           150,           151, 
             152,           153,           154,           155,           156,           157, 
             158,           159,           160,           161,           162,           163, 
             164,           330,             1,             2,             5,             8, 
              24,            29,            34,           165,           166,           167, 
             168,           169,           170,           171,           172,           173, 
             174,           175,           176,           177,           178,           179, 
             330,             0,             5,            12,            13,            16, 
              19,            30,           180,           181,           182,           183, 
             184,           185,           186,           187,           188,           189, 
             190,           191,           192,           193,           194,           330, 
               1,             6,            13,            14,            15,            17, 
              31,           195,           196,           197,           198,           199, 
             200,           201,           202,           203,           204,           205, 
             206,           207,           208,           209,           330,             2, 
               7,            10,            14,            16,            18,            32, 
             210,           211,           212,           213,           214,           215, 
             216,           217,           218,           219,           220,           221, 
             222,           223,           224,           330,             3,             8, 
              10,            11,            17,            19,            33,           225, 
             226,           227,           228,           229,           230,           231, 
             232,           233,           234,           235,           236,           237, 
             238,           239,           330,             4,             9,            11, 
              12,            15,            18,            34,           240,           241, 
             242,           243,           244,           245,           246,           247, 
             248,           249,           250,           251,           252,           253, 
             254,           330,            10,            15,            22,            23, 
              26,            29,            30,           255,           256,           257, 
             258,           259,           260,           261,           262,           263, 
             264,           265,           266,           267,           268,           269, 
             330,            11,            16,            23,            24,            25, 
              27,            31,           270,           271,           272,           273, 
             274,           275,           276,           277,           278,           279, 
             280,           281,           282,           283,           284,           330, 
              12,            17,            20,            24,            26,            28, 
              32,           285,           286,           287,           288,           289, 
             290,           291,           292,           293,           294,           295, 
             296,           297,           298,           299,           330,            13, 
              18,            20,            21,            27,            29,            33, 
             300,           301,           302,           303,           304,           305, 
             306,           307,           308,           309,           310,           311, 
             312,           313,           314,           330,            14,            19, 
              21,            22,            25,            28,            34,           315, 
             316,           317,           318,           319,           320,           321, 
             322,           323,           324,           325,           326,           327, 
             328,           329,           330,            37,            38,            41, 
              44,            55,            60,            65,           105,           120, 
             135,           150,           165,           180,           195,           210, 
             225,           240,           255,           270,           285,           300, 
             315,           330,            38,            39,            40,            42, 
              56,            61,            66,           106,           121,           136, 
             151,           166,           181,           196,           211,           226, 
             241,           256,           271,           286,           301,           316, 
             330,            35,            39,            41,            43,            57, 
              62,            67,            68,           107,           122,           137, 
             152,           167,           182,           197,           212,           227, 
             242,           257,           272,           287,           302,           317, 
             330,            35,            36,            42,            44,            58, 
              63,           108,           123,           138,           153,           168, 
             183,           198,           213,           228,           243,           258, 
             273,           288,           303,           318,           330,            36, 
              37,            40,            43,            59,            64,            69, 
             109,           124,           139,           154,           169,           184, 
             199,           214,           229,           244,           259,           274, 
             289,           304,           319,           330,            35,            40, 
              47,            48,            51,            54,            65,            73, 
             110,           125,           140,           155,           170,           185, 
             200,           215,           230,           245,           260,           275, 
             290,           305,           320,           330,            36,            41, 
              48,            49,            50,            52,            66,           111, 
             126,           141,           156,           171,           186,           201, 
             216,           231,           246,           261,           276,           291, 
             306,           312,           321,           330,            37,            42, 
              45,            49,            51,            53,            67,           112, 
             127,           142,           157,           172,           187,           202, 
             217,           232,           247,           262,           277,           292, 
             307,           322,           330,            38,            43,            45, 
              46,            52,            54,            68,           113,           128, 
             143,           158,           173,           188,           203,           218, 
             233,           248,           263,           278,           293,           308, 
             323,           330,            39,            44,            46,            47, 
              50,            53,            69,           114,           129,           144, 
             159,           174,           189,           204,           219,           234, 
             249,           264,           279,           294,           309,           324, 
             330,            45,            50,            57,            58,            61, 
              64,            65,           115,           130,           145,           160, 
             175,           190,           205,           220,           235,           250, 
             265,           280,           295,           310,           325,           330, 
              46,            51,            58,            59,            60,            62, 
              66,           116,           131,           146,           161,           176, 
             191,           206,           221,           236,           251,           266, 
             281,           296,           311,           326,           330,            47, 
              52,            55,            59,            61,            63,            67, 
             117,           132,           147,           162,           177,           192, 
             207,           222,           237,           252,           267,           282, 
             297,           327,           330,            48,            53,            55, 
              56,            62,            64,            68,           118,           133, 
             148,           163,           178,           193,           208,           223, 
             238,           253,           268,           283,           298,           313, 
             328,           330,            49,            54,            56,            57, 
              60,            63,            69,           119,           134,           149, 
             164,           179,           194,           209,           224,           239, 
             254,           269,           284,           299,           314,           329, 
             330,            72,            76,            79,            90,            95, 
             100,           105,           128,           141,           159,           172, 
             190,           197,           214,           226,           243,           260, 
             284,           298,           312,           326,           330,            73, 
              74,            75,            77,            91,            96,           101, 
             113,           121,           144,           157,           170,           184, 
             206,           213,           225,           242,           267,           276, 
             295,           314,           328,           330,            70,            74, 
              76,            78,            92,            97,           102,           111, 
             129,           137,           155,           173,           183,           195, 
             222,           229,           241,           269,           283,           292, 
             311,           325,           330,            70,            71,            77, 
              79,            93,            98,           103,           114,           127, 
             140,           153,           171,           182,           199,           211, 
             238,           240,           266,           280,           299,           308, 
             327,           330,            71,            72,            75,            78, 
              94,            99,           104,           112,           125,           143, 
             156,           169,           181,           198,           210,           227, 
             254,           268,           282,           296,           310,           330, 
              70,            75,            82,            83,            86,            89, 
             100,           115,           124,           138,           152,           166, 
             185,           208,           221,           239,           252,           255, 
             277,           294,           306,           323,           330,            71, 
              76,            83,            84,            85,            87,           101, 
             107,           131,           135,           154,           168,           193, 
             201,           224,           237,           250,           264,           271, 
             293,           305,           322,           330,            72,            77, 
              80,            84,            86,            88,           102,           109, 
             123,           147,           151,           165,           191,           209, 
             217,           235,           253,           263,           275,           287, 
             309,           321,           330,            73,            78,            80, 
              81,            87,            89,           103,           106,           120, 
             139,           163,           167,           194,           207,           220, 
             233,           251,           262,           279,           291,           303, 
             320,           330,            74,            79,            81,            82, 
              85,            88,           104,           108,           122,           136, 
             150,           179,           192,           205,           223,           236, 
             249,           261,           278,           290,           307,           319, 
             330,            80,            85,            92,            93,            96, 
              99,           100,           110,           132,           149,           161, 
             178,           180,           204,           218,           232,           246, 
             265,           273,           286,           304,           317,           330, 
              81,            86,            93,            94,            95,            97, 
             101,           119,           126,           148,           160,           177, 
             187,           196,           215,           234,           248,           258, 
             281,           289,           302,           315,           330,            82, 
              87,            90,            94,            96,            98,           102, 
             118,           130,           142,           164,           176,           189, 
             203,           212,           231,           245,           256,           274, 
             297,           300,           318,           330,            83,            88, 
              90,            91,            97,            99,           103,           117, 
             134,           146,           158,           175,           186,           200, 
             219,           228,           247,           259,           272,           285, 
             313,           316,           330,            84,            89,            91, 
              92,            95,            98,           104,           116,           133, 
             145,           162,           174,           188,           202,           216, 
             230,           244,           257,           270,           288,           301, 
             329,           330,   -1
  };

-------- Lower bounds
  local  padL= 
  {
    0,  0,  0,  0,  0,  0, 
    0,  0,  0,  0,  0,  0, 
    0,  0,  0,  0,  0,  0, 
    0,  0,  0,  0,  0,  0, 
    0,  0,  0,  0,  0,  0, 
    0,  0,  0,  0,  0,  0, 
    0,  0,  0,  0,  0,  0, 
    0,  0,  0,   -1.0
  };

-------- Upper bounds
  local  padU= 
  {
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,  1,  1,  1, 
    1,  1,  1,   -1.0
  };

-------- Load LP data
  
   local solver = xta:solver()  
   printf("Solver: %s\n",solver.version)
   local pModel = solver:mpmodel()     
      
   local res = pModel:loadLPData(
               dObjSense,
               dObjConst,
               xta:field(padC,"padC","double"),
               xta:field(padB,"padB","double"),
               pszConTypes,
               xta:field(paiAcols,"paiAcols","int"),
               xta:field(panAcols,"panAcols","int"),
               xta:field(padAcoef,"padAcoef","double"),
               xta:field(paiArows,"paiArows","int"),
               xta:field(padL,"padL","double"),
               xta:field(padU,"padU","double") )
  print_table3(res)
  local szmsg = sprintf("Error %d: %s\n",res.ErrorCode,pModel:errmsg(res.ErrorCode) or "N/A")
  assert(res.ErrorCode==0,szmsg)
 -- end LP/QP/CONE data




 -- begin INTEGER data

--------  Variable type
  local     nErr = 0;
  local  pszVarTypes= 
  
   "IIIIIIIIIIIIIIIIIIIIIIIIIIIIII"..
   "IIIIIIIIIIIIIII";
   
   if 2>1 then
    res = pModel:loadVarType(pszVarTypes:gsub("\n",""):gsub(" ",""));
    print_table3(res)    
    szmsg = sprintf("Error %d: %s\n",res.ErrorCode,pModel:errmsg(res.ErrorCode) or "N/A")
    assert(res.ErrorCode==0,szmsg)
   end
 -- end INTEGER data
   pModel.utable = {ncalls=0}

   pModel.logfun = myprintlog2
   
   local nStatus
   if 0>1 then
    res = pModel:solveMIP()
   else
    res = pModel:optimize()
   end
   print_table3(res)   
   szmsg = sprintf("Error %d: %s\n",res.ErrorCode,pModel:errmsg(res.ErrorCode) or "N/A")
   assert(res.ErrorCode==0,szmsg)
   
   res = pModel:writeMPSFile("a.mps",0)
   print_table3(res)
   szmsg = sprintf("Error %d: %s\n",res.ErrorCode,pModel:errmsg(res.ErrorCode) or "N/A")
   assert(res.ErrorCode==0,szmsg)
       
   if 0>1 then
     res = pModel:writeSrcFile("a.lua",-1,2)
     print_table3(res)
     szmsg = sprintf("Error %d: %s\n",res.ErrorCode,pModel:errmsg(res.ErrorCode) or "N/A")
     printf(szmsg)
   end 
   
   res = pModel:getVarType()
   print_table3(res)  
   szmsg = sprintf("Error %d: %s\n",res.ErrorCode,pModel:errmsg(res.ErrorCode) or "N/A")
   assert(res.ErrorCode==0,szmsg)
   
   local result = {}
   res = pModel:getPrimalSolution()
   print_table3(res)  
   szmsg = sprintf("Error %d: %s\n",res.ErrorCode,pModel:errmsg(res.ErrorCode) or "N/A")
   assert(res.ErrorCode==0,szmsg)
   result.jstrPrimal = res.padPrimal:ser()
   
   res = pModel:getDualSolution()
   print_table3(res)  
   szmsg = sprintf("Error %d: %s\n",res.ErrorCode,pModel:errmsg(res.ErrorCode) or "N/A")
   assert(res.ErrorCode==0,szmsg)
   result.jstrDual = res.padDual:ser()     
   
      
   printf("Disposing model %s\n",tostring(pModel))
   pModel:dispose()
   
   printf("Disposing env %s\n",tostring(solver))
   solver:dispose()
 -- begin QCP data

 -- end QCP data




 -- begin CONE data

 -- end CONE data




 -- begin SETS data

 -- end SETS data




 -- begin SC data

 -- end SC data
  return result
end
  
local result = solver_ex2()
print_table3(result)
local fPrimal = xta:field(0,"primal","double")
fPrimal:des(result.jstrPrimal)
fPrimal:print()