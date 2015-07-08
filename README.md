# orion-test

1. 该脚本仅测试f2fs文件系统
2. 该脚本仅测试ssd硬盘
3. 该脚本目前只测试磁盘的IOPS性能
4. 在最终输出结果中，IOPS值是所有测试的平均值, 每次测试的具体值，可以查看RESULTDIR
目录下的*.txt文件
5. Sample command: ./orion-test.sh -d /dev/sdc1 -D 20 -t f2fs -R rw -a kfifo -x 3 -O 10 -s 8 -l 2048 -o $PWD

TODO List:
1. 增加MBPS, Latency的测试
2. 增加结果对比功能
3. 加入结果分析，测试偏差，正态分布等
