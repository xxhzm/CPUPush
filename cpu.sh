#!/bin/bash
frequency=0

# 持续次数
Durationtimes=3
# 持续时间(s)
Duration=300
# CPU峰值(最高100)
peakValue=80
# 推送标题
title="您的服务器持续高负债状态"
# Server酱秘钥
key=""


cpu_num=`cat /proc/stat | grep cpu[0-9] -c`
start_idle=()
start_total=()
cpu_rate=()


while(true)
do
    for((i=0;i<${cpu_num};i++))
    {
        start=$(cat /proc/stat | grep "cpu$i" | awk '{print $2" "$3" "$4" "$5" "$6" "$7" "$8}')
        start_idle[$i]=$(echo ${start} | awk '{print $4}')
        start_total[$i]=$(echo ${start} | awk '{printf "%.f",$1+$2+$3+$4+$5+$6+$7}')
    }
    start=$(cat /proc/stat | grep "cpu " | awk '{print $2" "$3" "$4" "$5" "$6" "$7" "$8}')
    start_idle[${cpu_num}]=$(echo ${start} | awk '{print $4}')
    start_total[${cpu_num}]=$(echo ${start} | awk '{printf "%.f",$1+$2+$3+$4+$5+$6+$7}')
    sleep 2s
    for((i=0;i<${cpu_num};i++))
    {
        end=$(cat /proc/stat | grep "cpu$i" | awk '{print $2" "$3" "$4" "$5" "$6" "$7" "$8}')
        end_idle=$(echo ${end} | awk '{print $4}')
        end_total=$(echo ${end} | awk '{printf "%.f",$1+$2+$3+$4+$5+$6+$7}')
        idle=`expr ${end_idle} - ${start_idle[$i]}`
        total=`expr ${end_total} - ${start_total[$i]}`
        idle_normal=`expr ${idle} \* 100`
        cpu_usage=`expr ${idle_normal} / ${total}`
        cpu_rate[$i]=`expr 100 - ${cpu_usage}`
        # echo "The CPU$i Rate : ${cpu_rate[$i]}%"
    }
    end=$(cat /proc/stat | grep "cpu " | awk '{print $2" "$3" "$4" "$5" "$6" "$7" "$8}')
    end_idle=$(echo ${end} | awk '{print $4}')
    end_total=$(echo ${end} | awk '{printf "%.f",$1+$2+$3+$4+$5+$6+$7}')
    idle=`expr ${end_idle} - ${start_idle[$i]}`
    total=`expr ${end_total} - ${start_total[$i]}`
    idle_normal=`expr ${idle} \* 100`
    cpu_usage=`expr ${idle_normal} / ${total}`
    cpu_rate[${cpu_num}]=`expr 100 - ${cpu_usage}`
    # echo "The Average CPU Rate : ${cpu_rate[${cpu_num}]}%"

    if (( ${cpu_rate[${cpu_num}]} > ${peakValue} ));then
    
        # frequency变量次数自增 
        ((frequency++));

        # 通过判断frequency变量来获取执行的第几次
        if (( $frequency == 1 ));then
            time1=$(date "+%Y%m%d%H%M%S")
        fi

        if (( $frequency == ${Durationtimes} ));then
            time2=$(date "+%Y%m%d%H%M%S")
            time3=$(( time2-time1 ))
            if (( $time3 < $Duration ));then
                # 获取时间点
                time=$(date "+%Y-%m-%d %H:%M:%S")
                # 使用Server酱推送到微信
                local_ip=`ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"​`
                desp="您ip为"${local_ip}"的服务器持续高负债状态，在"${Duration}"秒内，连续"${Durationtimes}"次，峰值都超过了"${peakValue}"，触发了预警，请检查您的服务器是否正常！时间："${time}
                curl -X POST --data "title=${title}&desp=${desp}" https://sctapi.ftqq.com/${key}.send?
                # 如果成立frequency变量重置为0，脚本休眠5分钟。以防推送BUG
                frequency=0
                
                sleep ${Duration}
            else 
                # 如果不成立frequency变量重置为0
                frequency=0
            fi
        fi

    fi
done
