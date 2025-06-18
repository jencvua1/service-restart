#!/bin/bash

#ENV
servicename=javaserv
statefile=/tmp/fail-count-${servicename}
logfile=/var/log/${servicename}.log
serviceport=8989
inputstring=stats
steptime=10

#SCRIPT
number=$(<${statefile}) 2>/dev/null || number=1300
state=${number::2}
count=${number: 2}
while :
#for i in {1..30}
  do
	systemctl status ${servicename} > /dev/null 2>&1 || state=13
	case ${state} in 
		10)
		    if [[ ! `echo -e ${inputstring} | nc -w3 127.0.0.1 ${serviceport} | grep -ae Started` ]]	
			then
				count=$((count+1))
				echo "[$(date +%Y.%m.%d\ %H:%M:%S)] ${servicename} fail $count time(s)" >> ${logfile}
				
			else
				count=0
				state=10
				echo "[$(date +%Y.%m.%d\ %H:%M:%S)] ${servicename} working" >> ${logfile}
		    fi
		    if [ $count -gt 2 ]
			then
				state=11
		    fi
		    ;;
		11)
			echo "[$(date +%Y.%m.%d\ %H:%M:%S)] restarting ${servicename}" >> ${logfile}
			systemctl restart ${servicename}
			state=12
			count=0
		    ;;
		12)
                if [[ ! `echo -e ${inputstring} | nc -w3 127.0.0.1 ${serviceport} | grep -ae Started` ]]	
	       	    	then
                                count=$((count+1))
				echo "[$(date +%Y.%m.%d\ %H:%M:%S)] trying $count - ${servicename} has not loaded" >> ${logfile}
                        else
                                count=0
				state=10
			echo "[$(date +%Y.%m.%d\ %H%M%S)] ${servicename} has loaded" >> ${logfile}
		    fi
		    if [ $count -gt 59 ]
			then
			 	state=11
				count=0
		    fi
		    ;;
		13)
		    systemctl status ${servicename} > /dev/null 2>&1 && state=12 && count=0 && echo "[$(date +%Y%m%d-%H%M%S)] ${servicename} started" >> ${logfile}		    
		    ;;
	esac
	number=$((state*100+count))
	echo ${number} > ${statefile}
#	test $i -lt 30 && sleep 10
	:
	sleep ${steptime}	
  done

