version 15.1
capture log close
clear all
set more off

log using "logs/IRR_stage03.log",text replace
use "Data/Clean/IRRAnalysisFile_Penn_learning_wash.dta", clear

*==================
*======Table4======
*==================
*因变量变成了接受录用可能性
* 1.OLS
* 1.1 专业固定效应
reg rating_accept ///
	randgpa topemp secondint wfm techskills ///
	whitefemale nonwhite_male nonwhite_female ///
	imajor*,robust
	
estimates store table4_col1

testparm imajor*

*检验三类性别和种族变量的组合是否共同显著
test whitefemale nonwhite_male nonwhite_female

display "N  = " e(N)
display "R-squared = " e(r2)

* 1.2 加入领导经历和评价顺序的固定效应
reg rating_accept ///
	randgpa topemp secondint wfm techskills ///
	whitefemale nonwhite_male nonwhite_female ///
	i.resumenumber imajor* i.lead1 i.lead2,robust
	
estimates store table4_col2

testparm imajor*

test whitefemale nonwhite_male nonwhite_female

display "N = " e(N)
display "R-squared = " %6.3f e(r2)

* 1.3 加入招聘者固定效应
areg rating_accept ///
	randgpa topemp secondint wfm techskills ///
	whitefemale nonwhite_male nonwhite_female ///
	i.resumenumber imajor* i.lead1 i.lead2, ///
	absorb(subjroundid) robust
	
estimates store table4_col3

testparm imajor*

test whitefemale nonwhite_male nonwhite_female

display "N = " e(N)
display "r-squared = " %6.3f e(r2)

* 1.4 有序Probit
oprobit rating_accept ///
	randgpa topemp secondint wfm techskills ///
	whitefemale nonwhite_male nonwhite_female ///
	imajor*,robust
	
estimates store table4_col4

testparm imajor*

test whitefemale nonwhite_male nonwhite_female

display "N = " e(N)

forvalues k = 1/9 {
	display "cut`k' = "%6.2f _b[/cut`k']
}

*==================
*====汇总与核对====
*==================
*查看当前内存存储
estimates dir

*核心变量
local core randgpa topemp secondint wfm techskills ///
    whitefemale nonwhite_male nonwhite_female
	
*Table4
esttab table4_col1 table4_col2 table4_col3 table4_col4, ///
    b(3) se(3) ///
    keep(`core') order(`core') ///
    mtitles("OLS (1)" "OLS (2)" "OLS (3)" ///
            "Ordered Probit") ///
    stats(N r2, fmt(0 3) labels("N" "R-squared")) ///
    star(* 0.05 ** 0.01 *** 0.001) ///
    compress

log close