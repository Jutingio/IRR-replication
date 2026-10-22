*开启日志
version 15.1
capture log close

clear all
set more off

*存放代码文件路径
log using "logs/IRR_stage01.log", text replace
use "Data/Raw/IRRData_Penn.dta", clear

*====== 数据预处理 ======ORZ
describe
count

codebook subjroundid
isid subjroundid resumenumber
bysort subjroundid:assert _N == 40 //_N：前面有空行，Stata 内置符号，表示当前组共有多少条观测


*数据区分断言
* 两个因变量必须是1—10之间的整数
assert inrange(rating_hire, 1, 10) ///
    & rating_hire == floor(rating_hire)

assert inrange(rating_accept, 1, 10) ///
    & rating_accept == floor(rating_accept)

* 第二段实习与赚钱型工作不能同时出现
assert inlist(secondint, 0, 1)
assert inlist(wfm, 0, 1)
assert !(secondint == 1 & wfm == 1)

* 构造人口统计变量前检查原始字段缺失
assert !missing(randfirstname_gender)
assert !missing(rand_eth)


*tab查看分类变量的频数分布
tab rating_hire,missing
tab secondint wfm,missing //这是行内注释的标记，第二段工作经历的添加是否会对评价有影响，以secondint与wfm组合来看 
summarize randgpa

/*
关于注释：
1.//：代码后面写解释；
2.*：注释掉一整行；
3./* ... */：注释掉多行；
4.///：一条很长的命令换行继续写。
*/

*==================
*======Table2======
*==================

* 1.利用已知数据构造并统计
*------1.1人口统计特征虚拟变量
*有性别与种族两个维度，4类 
gen byte rand_female = (randfirstname_gender == "female") //记得"=="恒等，"="不行
label variable rand_female "female candidate"

gen byte white = (rand_eth == "White":randethtype) //在名为 randethtype 的值标签中，找出"White"对应的数值。
label variable white "White candidate"

gen byte whitefemale = (rand_female == 1 & white == 1)
label variable whitefemale "Female,White"
gen byte nonwhite_female = (rand_female == 1 & white == 0)
label variable nonwhite_female "Female,Non-White"
gen byte nonwhite_male = (rand_female == 0 & white == 0)
label variable nonwhite_male "Man,Non-White"
gen byte whitemale = (rand_female == 0 & white == 1)
label variable whitemale "Man,White"

*检查是否全部覆盖,是否不重不漏
assert whitefemale + nonwhite_female + nonwhite_male + whitemale == 1

*统计并查看人数
tab rand_female white,missing //总的

*------1.2 专业
tab randmajor,generate(imajor) //查看专业频数，根据专业自动生成0/1变量

describe imajor* //*是通配符，表示所有以 imajor 开头的变量。

*每份简历只属于一个专业
egen major_total = rowtotal(imajor*) //egen生成命令 rowtotal()行相加 imajor*所有专业虚拟变量
assert major_total == 1 //确认一份简历只有一个专业
tab major_total
drop major_total //删除用于检查的辅助变量

*------1.3 领导经历
encode randleadexp,generate(lead1)
encode randleadexptwo,generate(lead2)
label variable randleadexp "First leadship experience"
label variable randleadexptwo "Second leadship experience"

*知道取值边界并检查
quietly tabulate lead1
local n_lead1 = r(r) //local 临时保存，避免覆盖
display "lead1类别数 =" `n_lead1'
assert `n_lead1' == 80 //有个`和'，因为 n_lead1 是一个 local 宏（临时存储值）。在 Stata 中，引用 local 宏时必须使用`宏名'

quietly tabulate lead2
local n_lead2 = r(r)
display "lead2类别数 = " `n_lead2' 
assert `n_lead2' == 80

*检查类别数量、缺失值
codebook lead1 lead2
assert !missing(lead1) & !missing(lead2)

*------保存好处理的数据！！！
save "Data/Clean/IRRAnalysisFile_Penn_learning_wash.dta", replace

log close