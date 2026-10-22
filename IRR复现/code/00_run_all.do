version 15.1

capture mkdir "Data/Clean"
capture mkdir "logs"

* 按顺序运行各模块
do "code/01_prepare_data.do"
do "code/02_table2.do"
do "code/03_table4.do"
do "code/04_cluster_extension.do"