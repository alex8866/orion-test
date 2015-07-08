#!/bin/bash

: << EOF
Note:
1. 该脚本仅测试f2fs文件系统
2. 该脚本仅测试ssd硬盘
3. 该脚本目前只测试磁盘的IOPS性能
4. 在最终输出结果中，IOPS值是所有测试的平均值, 每次测试的具体值，可以查看RESULTDIR
目录下的*.txt文件
5. 在运行脚本前必须指定Orion工具的命令路径，默认是: $PWD/orion_linux_x86-64
6. 因为Orion工具自身的原因，Orion只测试Small Random I/O的IOPS，对于Large Random IO只测试MBPS，所以目前的测试结果中的IOPS均是Small Random I/O
7. 如果生成Excel报错，很可能是缺少某些Python包，或者Python包版本引起的，只需注释到该脚本最后两行即可
8. Sample command: ./orion-test.sh -d /dev/sdc1 -D 20 -t f2fs -R rw -a kfifo -x 3 -O 10 -s 8 -l 2048 -o $PWD -v

TODO List:
1. 增加MBPS, Latency的测试
2. 增加结果对比功能
3. 加入结果分析，测试偏差，正态分布等

依赖包:
1. gnuplot
2. PIL
EOF

VERSION="0.1.0"

function usage()
{
    cat << EOF
orion-test [-dDtRaxOslo]
    -d: The block device that will be tested, eg /dev/sdc1
    -D: The time orion tool will run
    -t: filesystem type. eg: ext3,ext4,f2fs
    -R: Test type. r=read, w=write, rw=readwrite
    -a: I/O scheduler, eg: "kfifo fiops deadline noop cfq"
    -x: times. eg: -x 100, run 100 times for each test
    -O: Outstanding I/Os, default 32
    -s: Block size for small random I/O
    -l: Block size for large random I/O
    -o: Results directoroy
    -h: Print this help message
    -V: Version
    -v: verbose
EOF

    exit
}

function deal()
{
    a=$(cat "$1" |tr '\n' '+')
    b=${a%?}

    num=$(echo $b |bc )
    line=$(wc -l $1|cut -d' ' -f1)

    echo "scale=2;$num/$line" | bc
}

while getopts d:t:R:a:x:D:O:l:s:o:hvV opt
do
    case $opt in
        d)
            DEVICE="$OPTARG"
            ;;
        t)
            FILESYSTEM="$OPTARG"
            ;;
        R)
            TYPE="$OPTARG"
            ;;
        a)
            SCHEDULER="$OPTARG"
            ;;
        x)
            TIME="$OPTARG"
            ;;
        D)
            DURATION="$OPTARG"
            ;;
        O)
            OUTSTANDING="$OPTARG"
            ;;
        s)
            SMALLSIZE="$OPTARG"
            ;;
        l)
            LARGESIZE="$OPTARG"
            ;;
        o)
            RESULTDIR="$OPTARG"
            ;;
        h)
            usage
            exit
            ;;
        V)
            echo "orion-test version $VERSION"
            exit
            ;;
        v)
            VERBOSE=True
            ;;
        *)
            usage
            ;;
    esac
done

#define colors
cyan='\033[36m';normal='\033[0m';red='\033[31m';magenta='\033[35m';yellow='\033[33m';white='\033[37m';green='\033[32m'

declare -a arr
arr[0]="read"
arr[100]="write"
LUNFILE="$PWD/oriontest.lun"

# Script start
if [ "$TYPE" == "r" ];then
    looptype="0"
elif [ "$TYPE" == "w" ];then
    looptype="100"
elif [ "$TYPE" == "rw" ];then
    looptype="0 100"
else
    echo -e "${red}ERROR: You must specify a right operation type: r,w,rw!${normal}"
    exit
fi

[ "$DEVICE" == "" ] && {
    echo -e "${red}ERROR: You must specify a device used to test!${normal}"
    exit
}

# default to run 20 times for each test
TIME="${TIME:-20}"

# Set default filesystem to f2fs
FILESYSTEM="${FILESYSTEM:-f2fs}"

# Set default scheduler
SCHEDULER="${SCHEDULER:-kfifo fiops deadline noop cfq}"

TESTDIR="/orion-test-dir"
[ ! -d "$TESTDIR" ] && mkdir "$TESTDIR"

DURATION="${DURATION:-60}"
OUTSTANDING="${OUTSTANDING:-32}"
SMALLSIZE="${SMALLSIZE:-8k}"
LARGESIZE="${LARGESIZE:-2048k}"
RESULTDIR="${RESULTDIR:-$PWD}"
ORIONTOOL="${ORIONTOOL:-$PWD/orion_linux_x86-64}"

[ "$FILESYSTEM" != "" ] && {
    mount -t "$FILESYSTEM" "$DEVICE" "$TESTDIR" &>/dev/null
}

[ ! -d "$RESULTDIR" ] && mkdir -p "$RESULTDIR"

# Create orion lun file
[ "$FILESYSTEM" != "" ] && {
    echo "$TESTDIR/orion-test.txt" > "$LUNFILE"

    # Prepare the test file
    [ ! -f "$TESTDIR/orion-test.txt" ] && {
        echo -e "${red}ERROR: You need to prepare test file: "$TESTDIR/orion-test.txt" first!
       You can use dd to create the test file with reasonable size.
       eg: dd if=/dev/zero of=$TESTDIR/orion-test.txt bs=1M count=5000${normal}"
       exit
    }
    ECHOFILESYSTEM="$FILESYSTEM"
} || {
    echo "$DEVICE" > "$LUNFILE"
    ECHOFILESYSTEM="None"
}

# Print infomation
[ "$VERBOSE" == "True" ] && echo "
orion-test Version: $VERSION
Orion Tool Binary File: $ORIONTOOL
Test Device: $DEVICE
Test Scheduler: $SCHEDULER
Test Type: $TYPE
Repeat Time: $TIME
Test Directory: $TESTDIR
Results Directory: $RESULTDIR
Test Filesystem: $ECHOFILESYSTEM
Orion Tool Duration: $DURATION
Outstanding I/Os: $OUTSTANDING
Small Random I/O Block Size: $SMALLSIZE
Large Random I/O Block Size: $LARGESIZE

Note: This script only test the performance of small random I/O and large random I/O.
For small random I/O, we only care about the IOPS
For large random I/O, we only care about the MBPS
Currently orion-test script only collect the results for IOPS
"

echo "############### `date +"%Y-%m-%d %H:%M:%S"`: Test Start  ###############"
exit
for type in $looptype
do
    for sc in $SCHEDULER
    do
        echo $sc > /sys/block/sdc/queue/scheduler
        for n in $(seq 1 1 $TIME)
        do
            "$ORIONTOOL" -run advanced -testname oriontest -num_disks 1 -size_small "$SMALLSIZE" -size_large "$LARGESIZE" -type rand -simulate concat -write "$type" -duration "$DURATION" -matrix point -num_small "$OUTSTANDING" -num_large "$OUTSTANDING"

            tail -1 *_iops.csv|awk -F'[, ]' '{print $NF}' >>  $RESULTDIR/iops_${arr[$type]}_${sc}.txt
            rm -f oriontest_*.txt *.csv
        done
    done
done

for type in $looptype
do
    cat /dev/null > /tmp/orion_${arr[$type]}.dat
done

# Deal with the results
for file in $(ls $RESULTDIR/iops_*_*.txt)
do
    BASENAME="$(basename $file)"
    rw="$(echo $BASENAME|awk -F'[_.]' '{print $2}')"
    sc="$(echo $BASENAME|awk -F'[_.]' '{print $3}')"
    value="$(deal $file)"
    echo "$sc $value" >> /tmp/orion_"$rw".dat
done

echo "############### Test Results ###############"
for type in $looptype
do
    cat /tmp/orion_${arr[$type]}.dat |
    sort -rn -k2 > $RESULTDIR/orion_${arr[$type]}.dat
    echo "Final Results File: $RESULTDIR/orion_${arr[$type]}.dat"
done

# Check system environment
if ! gnuplot --version &>/dev/null;then
    echo -e "${red}Please install gnuplot first${normal}"
    exit
fi

# Plot
for type in $looptype
do
    gnuplot << EOF
set terminal png truecolor
set grid
set style data histogram
set style histogram clustered gap 1
set style fill solid 0.4 border
set xlabel "Scheduler"
set output "$RESULTDIR/orion_${arr[$type]}.png"
plot "$RESULTDIR/orion_${arr[$type]}.dat" using 2:xtic(1) title "IOPS"
EOF
    echo "Final Histogram File: $RESULTDIR/orion_${arr[$type]}.png"
done

# Current SUSE 11 can not have openjpeg package, in order to generate excel on SUSE 11, need to install openjpeg from source first.

# Generate Excel
excel=$($PWD/gen_xls.py "$RESULTDIR")
echo "Results are recorded in file: $excel"

# Clear environment
rm -f $LUNFILE
echo "############### `date +"%Y-%m-%d %H:%M:%S"`: Test End  ###############"
