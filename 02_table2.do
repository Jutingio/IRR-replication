version 15.1
capture log close
clear all
set more off

log using "logs/IRR_stage02.log",text replace
use "Data/Clean/IRRAnalysisFile_Penn_learning_wash.dta", clear

*----------------------
* 2.OLS
*----------------------
* 2.1 Table2 第1列：专业固定效应 OLS
reg rating_hire ///
	randgpa topemp secondint wfm techskills ///
	whitefemale nonwhite_male nonwhite_female ///
	imajor*,robust //使用 HC1 异方差稳健标准误
	
*暂存第1列
estimates store table2_col1

*联合检验：所有专业固定效应是否共同显著
testparm imajor*

*单独显示样本量和拟合优度
display "N = "e(N)
display "R-squared = "%6.3f e(r2)
*第一次运行R-squared = 0.129

* 2.2 Table2 第2列：加入领导经历和评价顺序固定效应
reg rating_hire ///
	randgpa topemp secondint wfm techskills ///
	whitefemale nonwhite_male nonwhite_female ///
	i.resumenumber imajor* i.lead1 i.lead2,robust
	
estimates store table2_col2

testparm imajor*

display "N = " e(N)
display "R-squared = " %6.3f e(r2)

* 2.3 Table2 第3列：加入招聘者严宽程度固定效应
*reg不接受absorb()所以使用areg
*lead2后有个英文逗号
areg rating_hire ///
	randgpa topemp secondint wfm techskills ///
	whitefemale nonwhite_male nonwhite_female ///
	i.resumenumber imajor* i.lead1 i.lead2 , ///
	absorb(subjroundid) robust

estimates store table2_col3

testparm imajor*

display "N = " e(N)
display "R-square = " %6.3f e(r2)

* 2.4 Table2 第4列：GPA-Scaled OLS
*第3列数据重现re
estimates restore table2_col3

*将第3列个系数转换为等价的GPA变化
*nlcom 计算回归系数的非线性组合。要确保平行不然又要报错。
nlcom ///
    (randgpa:        _b[randgpa]        / _b[randgpa]) ///
    (topemp:         _b[topemp]         / _b[randgpa]) ///
    (secondint:      _b[secondint]      / _b[randgpa]) ///
    (wfm:            _b[wfm]            / _b[randgpa]) ///
    (techskills:     _b[techskills]     / _b[randgpa]) ///
    (whitefemale:    _b[whitefemale]    / _b[randgpa]) ///
    (nonwhite_male:  _b[nonwhite_male]  / _b[randgpa]) ///
    (nonwhite_female:_b[nonwhite_female]/ _b[randgpa]), post

estimates store table2_col4

*2.5 Table2第5列：有序Probit
*不依赖于等距假设
*每位招聘者只有40条评价，而完整模型要加入专业、两组领导经历、评价顺序和招聘者等大量虚拟变量；在有序Probit这种非线性模型中，虚拟变量过多可能导致估计不可靠。因此第5列只保留第1列的专业固定效应。
*采用第1列的模型，只保留专业固定效应，严格来说只能说明第1列的基础结果对有序Probit设定稳健
*系数结果只表示对有序Probit潜在变量的影响，不能与OLS输出系数相比较
oprobit rating_hire ///
	randgpa topemp secondint wfm techskills ///
	whitefemale nonwhite_male nonwhite_female ///
	imajor*,robust
	
estimates store table2_col5

testparm imajor*

display "N = " e(N)

*看有序Probit切点，看切点间距是否大致均匀，从而判断等距假设是否严重失真
*_b[...] 中引用的切点参数名不能有空格；引号中的显示文字可以有空格。
forvalues k = 1/9 {
	display "cut `k' = " %6.2f _b[/cut`k']
}

*==================
*====汇总与核对====
*==================
*查看当前内存存储
estimates dir

*核心变量
*Table2
local core randgpa topemp secondint wfm techskills ///
    whitefemale nonwhite_male nonwhite_female
	
esttab table2_col1 table2_col2 table2_col3 ///
	table2_col4 table2_col5, ///
	b(3) se(3) ///
	keep(`core') order(`core') ///
	mtitles("OLS(1)" "OLS(2)" "OLS(3)" ///
			"GPA-Scaled OLS" "Ordered Probit") ///
	stats(N r2,fmt(0 3) labels("N" "R-squared")) ///
	star(* 0.05 ** 0.01 *** 0.001) ///
	compress
	
log close