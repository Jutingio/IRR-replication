version 15.1
capture log close
clear all
set more off

log using "logs/IRR_stage04.log",text replace

use "Data/Clean/IRRAnalysisFile_Penn_learning_wash.dta", clear

local core randgpa topemp secondint wfm techskills ///
    whitefemale nonwhite_male nonwhite_female
	
* 0. 数据检查

isid subjroundid resumenumber
assert _N == 2880

bysort subjroundid: assert _N == 40

* 计算招聘者聚类数
tempvar recruiter_tag
egen byte `recruiter_tag' = tag(subjroundid)

quietly count if `recruiter_tag' == 1
local G = r(N)

assert `G' == 72
drop `recruiter_tag'

display as result "总观测数 = " _N
display as result "招聘者聚类数 = " `G'

* 两张表共同报告的核心变量
local core randgpa topemp secondint wfm techskills ///
    whitefemale nonwhite_male nonwhite_female

	
*标准误聚类
*Table2
* 1.1 招聘者聚类标准误
reg rating_hire ///
    randgpa topemp secondint wfm techskills ///
    whitefemale nonwhite_male nonwhite_female ///
    imajor*, ///
    vce(cluster subjroundid)

estimates store table2_col1_cluster

testparm imajor*

display "N = " e(N)
display "招聘者聚类数 = " e(N_clust)
display "R-squared = " %6.3f e(r2)

* 1.2 加入评价顺序和两组领导经历固定效应
reg rating_hire ///
    randgpa topemp secondint wfm techskills ///
    whitefemale nonwhite_male nonwhite_female ///
    i.resumenumber imajor* i.lead1 i.lead2, ///
    vce(cluster subjroundid)

estimates store table2_col2_cluster

testparm imajor*

display "N = " e(N)
display "招聘者聚类数 = " e(N_clust)
display "R-squared = " %6.3f e(r2)

* 1.3 招聘者固定
areg rating_hire ///
    randgpa topemp secondint wfm techskills ///
    whitefemale nonwhite_male nonwhite_female ///
    i.resumenumber imajor* i.lead1 i.lead2, ///
    absorb(subjroundid) ///
    vce(cluster subjroundid)

estimates store table2_col3_cluster

testparm imajor*

display "N = " e(N)
display "招聘者聚类数 = " e(N_clust)
display "R-squared = " %6.3f e(r2)

* 1.4 Table 2第4列
* 将第3列系数换算为等价GPA变化
* Delta method继续使用第3列的聚类协方差矩阵
*------------------------------------------------------------

estimates restore table2_col3_cluster

nlcom ///
    (randgpa:         _b[randgpa]         / _b[randgpa]) ///
    (topemp:          _b[topemp]          / _b[randgpa]) ///
    (secondint:       _b[secondint]       / _b[randgpa]) ///
    (wfm:             _b[wfm]             / _b[randgpa]) ///
    (techskills:      _b[techskills]      / _b[randgpa]) ///
    (whitefemale:     _b[whitefemale]     / _b[randgpa]) ///
    (nonwhite_male:   _b[nonwhite_male]   / _b[randgpa]) ///
    (nonwhite_female: _b[nonwhite_female] / _b[randgpa]), ///
    post

assert e(N) == 2880

* nlcom, post不会保存e(N_clust)，因此手动补入
estadd scalar G = `G'
estimates store table2_col4_cluster

display "N = " e(N)
display "招聘者聚类数 = " `G'


* 1.5 Table2 有序Probit 招聘者聚类标准误
oprobit rating_hire ///
    randgpa topemp secondint wfm techskills ///
    whitefemale nonwhite_male nonwhite_female ///
    imajor*, ///
    vce(cluster subjroundid)

assert e(N) == 2880
assert e(N_clust) == `G'

estadd scalar G = `G'
estimates store table2_col5_cluster

* 聚类VCE下使用Wald联合检验
testparm imajor*
display "专业固定效应联合检验p值 = " %7.4f r(p)

display "N = " e(N)
display "招聘者聚类数 = " e(N_clust)
display "Pseudo R-squared = " %6.3f e(r2_p)

forvalues k = 1/9 {
    display "cut `k' = " %7.3f _b[/cut`k']
}



* 2. Table4
*2.1 专业固定效应 招聘者聚类标准误

reg rating_accept ///
    randgpa topemp secondint wfm techskills ///
    whitefemale nonwhite_male nonwhite_female ///
    imajor*, ///
    vce(cluster subjroundid)

assert e(N) == 2880
assert e(N_clust) == `G'

estadd scalar G = `G'
estimates store table4_col1_cluster

testparm imajor*
display "专业固定效应联合检验p值 = " %7.4f r(p)

testparm whitefemale nonwhite_male nonwhite_female
display "人口统计变量联合检验p值 = " %7.4f r(p)

display "N = " e(N)
display "招聘者聚类数 = " e(N_clust)
display "R-squared = " %6.3f e(r2)


* 2.2 加入评价顺序和两组领导经历固定效应

reg rating_accept ///
    randgpa topemp secondint wfm techskills ///
    whitefemale nonwhite_male nonwhite_female ///
    i.resumenumber imajor* i.lead1 i.lead2, ///
    vce(cluster subjroundid)

assert e(N) == 2880
assert e(N_clust) == `G'

estadd scalar G = `G'
estimates store table4_col2_cluster

testparm imajor*
display "专业固定效应联合检验p值 = " %7.4f r(p)

testparm whitefemale nonwhite_male nonwhite_female
display "人口统计变量联合检验p值 = " %7.4f r(p)

display "N = " e(N)
display "招聘者聚类数 = " e(N_clust)
display "R-squared = " %6.3f e(r2)


* 2.3 加入招聘者固定效应，同时聚类到招聘者层级

areg rating_accept ///
    randgpa topemp secondint wfm techskills ///
    whitefemale nonwhite_male nonwhite_female ///
    i.resumenumber imajor* i.lead1 i.lead2, ///
    absorb(subjroundid) ///
    vce(cluster subjroundid)

assert e(N) == 2880
assert e(N_clust) == `G'

estadd scalar G = `G'
estimates store table4_col3_cluster

testparm imajor*
display "专业固定效应联合检验p值 = " %7.4f r(p)

testparm whitefemale nonwhite_male nonwhite_female
display "人口统计变量联合检验p值 = " %7.4f r(p)

display "N = " e(N)
display "招聘者聚类数 = " e(N_clust)
display "R-squared = " %6.3f e(r2)


* 2.4 Ordered Probit 招聘者聚类标准误

oprobit rating_accept ///
    randgpa topemp secondint wfm techskills ///
    whitefemale nonwhite_male nonwhite_female ///
    imajor*, ///
    vce(cluster subjroundid)

assert e(N) == 2880
assert e(N_clust) == `G'

estadd scalar G = `G'
estimates store table4_col4_cluster

testparm imajor*
display "专业固定效应联合检验p值 = " %7.4f r(p)

testparm whitefemale nonwhite_male nonwhite_female
display "人口统计变量联合检验p值 = " %7.4f r(p)

display "N = " e(N)
display "招聘者聚类数 = " e(N_clust)
display "Pseudo R-squared = " %6.3f e(r2_p)

forvalues k = 1/9 {
    display "cut `k' = " %7.3f _b[/cut`k']
}


*============================================================
* 3. 汇总全部招聘者聚类结果
*============================================================

display as result "========== Table 2：招聘者聚类标准误 =========="

esttab ///
    table2_col1_cluster ///
    table2_col2_cluster ///
    table2_col3_cluster ///
    table2_col4_cluster ///
    table2_col5_cluster, ///
    b(3) se(3) ///
    keep(`core') ///
    order(`core') ///
    mtitles( ///
        "OLS (1)" ///
        "OLS (2)" ///
        "OLS (3)" ///
        "GPA-Scaled OLS" ///
        "Ordered Probit" ///
    ) ///
    stats( ///
        N G r2, ///
        fmt(0 0 3) ///
        labels( ///
            "N" ///
            "Recruiter clusters" ///
            "R-squared" ///
        ) ///
    ) ///
    star(* 0.05 ** 0.01 *** 0.001) ///
    compress


display as result "========== Table 4：招聘者聚类标准误 =========="

esttab ///
    table4_col1_cluster ///
    table4_col2_cluster ///
    table4_col3_cluster ///
    table4_col4_cluster, ///
    b(3) se(3) ///
    keep(`core') ///
    order(`core') ///
    mtitles( ///
        "OLS (1)" ///
        "OLS (2)" ///
        "OLS (3)" ///
        "Ordered Probit" ///
    ) ///
    stats( ///
        N G r2, ///
        fmt(0 0 3) ///
        labels( ///
            "N" ///
            "Recruiter clusters" ///
            "R-squared" ///
        ) ///
    ) ///
    star(* 0.05 ** 0.01 *** 0.001) ///
    compress


*============================================================
* 4. 主规格比较
* 第3列 HC1异方差稳健标准误与招聘者聚类标准误
*============================================================

* 4.1 Table 2第3列原始HC1稳健标准误

quietly areg rating_hire ///
    randgpa topemp secondint wfm techskills ///
    whitefemale nonwhite_male nonwhite_female ///
    i.resumenumber imajor* i.lead1 i.lead2, ///
    absorb(subjroundid) ///
    vce(robust)

estimates store table2_col3_robust


* 4.2 Table 4第3列原始HC1稳健标准误

quietly areg rating_accept ///
    randgpa topemp secondint wfm techskills ///
    whitefemale nonwhite_male nonwhite_female ///
    i.resumenumber imajor* i.lead1 i.lead2, ///
    absorb(subjroundid) ///
    vce(robust)

estimates store table4_col3_robust


* 4.3 Table 2第3列对照表
* 系数应相同，括号中的标准误可能不同

display as result ///
    "========== Table 2第3列：HC1与聚类标准误比较 =========="

esttab ///
    table2_col3_robust ///
    table2_col3_cluster, ///
    b(3) se(3) ///
    keep(`core') ///
    order(`core') ///
    mtitles( ///
        "HC1 Robust" ///
        "Recruiter-Clustered" ///
    ) ///
    stats( ///
        N r2, ///
        fmt(0 3) ///
        labels("N" "R-squared") ///
    ) ///
    star(* 0.05 ** 0.01 *** 0.001) ///
    compress


*------------------------------------------------------------
* 4.4 Table 4第3列对照表
*------------------------------------------------------------

display as result ///
    "========== Table 4第3列：HC1与聚类标准误比较 =========="

esttab ///
    table4_col3_robust ///
    table4_col3_cluster, ///
    b(3) se(3) ///
    keep(`core') ///
    order(`core') ///
    mtitles( ///
        "HC1 Robust" ///
        "Recruiter-Clustered" ///
    ) ///
    stats( ///
        N r2, ///
        fmt(0 3) ///
        labels("N" "R-squared") ///
    ) ///
    star(* 0.05 ** 0.01 *** 0.001) ///
    compress


*============================================================
* 5. 最终检查
*============================================================

estimates dir

display as result ///
    "04_cluster_extension.do completed successfully"

log close