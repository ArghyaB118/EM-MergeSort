#!/bin/bash
#how-to-tun: sudo ./cache-ex.sh 32 128 cache-test-arghya
#g++ ./merge-sort/binary-merge-sort.cpp -o ./executables/binary-merge-sort
#chmod a+x ./executables/binary-merge-sort
#g++ ./merge-sort/k-way-merge-sort.cpp -o ./executables/k-way-merge-sort
#chmod a+x ./executables/k-way-merge-sort
#g++ ./merge-sort/k-way-merge-sort-constant-memory.cpp -o ./executables/k-way-merge-sort-constant-memory
#chmod a+x ./executables/k-way-merge-sort-constant-memory
#g++ ./merge-sort/k-way-merge-sort-worst-case-memory.cpp -o ./executables/k-way-merge-sort-worst-case-memory
#chmod a+x ./executables/k-way-merge-sort-worst-case-memory
g++ ./merge-sort/opt-extmem-merge-sort.cpp -o ./executables/opt-extmem-merge-sort
chmod a+x ./executables/opt-extmem-merge-sort
#g++ ./funnel-sort/funnel_sort.cpp -o ./executables/funnel_sort
#chmod a+x ./executables/funnel_sort
g++ ./funnel-sort/funnel-sort-int.cpp -o ./executables/funnel-sort-int
chmod a+x ./executables/funnel-sort-int
#g++ ./matrix-mul/cache_adaptive.cpp -o ./executables/cache-adaptive
#chmod a+x ./executables/cache-adaptive
#g++ ./matrix-mul/non_cache_adaptive.cpp -o ./executables/non-cache-adaptive
#chmod a+x ./executables/non-cache-adaptive

g++ ./large-file-creation/make-unsorted-data.cpp -o ./executables/make-unsorted-data
chmod a+x ./executables/make-unsorted-data

#creating the cgroup
#if [ -d  "/var/cgroups/cache-test-arghya" ]
#then
#	cgdelete memory:cache-test-arghya
#fi
#cgcreate -g "memory:cache-test-arghya" -t arghya:arghya

#creating nullbytes
if [ ! -f "/home/arghya/EM-MergeSort/merge-sort/nullbytes" ]
then
  echo "First creating file for storing data."
  dd if=/dev/urandom of=nullbytes count=32768 bs=1048576
  mv nullbytes merge-sort/nullbytes
fi
#deleting out-sorting.txt and creating again
if [ -f "/home/arghya/EM-MergeSort/out-sorting.txt" ]
then
  echo "out-sorting.txt already exists. Deleting it first."
  rm /home/arghya/EM-MergeSort/out-sorting.txt
  touch /home/arghya/EM-MergeSort/out-sorting.txt
fi

#deleting mem_profile.txt and creating again
if [ -f "/home/arghya/EM-MergeSort/mem_profile.txt" ]
then
  echo "mem_profile.txt already exists. Deleting it first."
  rm /home/arghya/EM-MergeSort/mem_profile.txt
  touch /home/arghya/EM-MergeSort/mem_profile.txt
fi

declare -a data_size=( 1536 )
declare -a memory_given=( 16 )
#declare -a data_size=( 32 64 )
#declare -a memory_given=( 16 32 )
NUMRUNS=3

for (( index=0; index<=${#data_size[@]}-1; index++ ));
do
	for i in `seq 1 $NUMRUNS`;
	do
		data_size_run=${data_size[$index]}
		memory_given_run=${memory_given[$index]}
		


		#code to run worse case memory profile on funnel sort
		./cgroup_creation.sh cache-test-arghya
		./executables/make-unsorted-data $data_size_run
		sudo sh -c "sync; echo 3 > /proc/sys/vm/drop_caches; echo 0 > /proc/sys/vm/vfs_cache_pressure"
		IFS=$'\r\n ' GLOBIGNORE='*' command eval  'XYZ=($(cat /home/arghya/EM-MergeSort/mem_profile_use.txt))'
		echo "funnel sort on worse case memory for data size $data_size_run and memory size $memory_given_run" >> out-sorting.txt
		cgexec -g memory:cache-test-arghya ./executables/funnel-sort-int $memory_given_run $data_size_run cache-test-arghya &
		PID=$!
		STATUS=$(ps ax|grep "$PID"|wc -l)
		X=0
		CURRENT=0
		while [ $STATUS -gt 1 ] && [ $X -lt "${#XYZ[@]}" ]; do
		   VAL=${XYZ[$X]%.*}
		   sleep $(calc "($VAL-$CURRENT)")
		   CURRENT=$VAL
		   let X+=1
		   echo "sleeping $CURRENT seconds and writing memory size $((XYZ[X]))"
		   echo $((XYZ[X])) > /var/cgroups/cache-test-arghya/memory.limit_in_bytes
		   let X+=1
		   STATUS=$(ps ax|grep "$PID"|wc -l)
		done 
		echo "Success for worse case profile on funnel sort!"
		wait

		
		#code for constant memory profile merge sort
		./cgroup_creation.sh cache-test-arghya
		./executables/make-unsorted-data $data_size_run
		sudo sh -c "sync; echo 3 > /proc/sys/vm/drop_caches; echo 0 > /proc/sys/vm/vfs_cache_pressure"
		echo "merge sort constant memory for data size $data_size_run and memory size $memory_given_run" >> out-sorting.txt 
		cgexec -g memory:cache-test-arghya ./executables/opt-extmem-merge-sort $memory_given_run $data_size_run cache-test-arghya 1 8
		
		#code for constant memory profile funnel sort
		./cgroup_creation.sh cache-test-arghya
		./executables/make-unsorted-data $data_size_run
		sudo sh -c "sync; echo 3 > /proc/sys/vm/drop_caches; echo 0 > /proc/sys/vm/vfs_cache_pressure"
		echo "funnel sort constant memory for data size $data_size_run and memory size $memory_given_run" >> out-sorting.txt 
		cgexec -g memory:cache-test-arghya ./executables/funnel-sort-int $memory_given_run $data_size_run cache-test-arghya

		#code for random memory profile for merge sort
	#	./cgroup_creation.sh cache-test-arghya
	#	./executables/make-unsorted-data $data_size_run
	#	sudo sh -c "sync; echo 3 > /proc/sys/vm/drop_caches; echo 0 > /proc/sys/vm/vfs_cache_pressure"
	#	echo "merge sort random memory for data size $data_size_run and memory size $memory_given_run" >> out-sorting.txt 
	#	cgexec -g memory:cache-test-arghya ./executables/opt-extmem-merge-sort-const-mem $memory_given_run $data_size_run cache-test-arghya &
	#	PID=$!
	#	STATUS=$(ps ax|grep "$PID"|wc -l)
	#	CURRENT=$memory_given_run*1024*1024
	#	while [ $STATUS -gt 1 ] ; do
	#		sleep 5
	#		if (( $RANDOM % 2 == 1 )) || (( $CURRENT == $memory_given_run*1024*1024 )) || (( $CURRENT == 2*$memory_given_MB*1024*1024 ));
	#		then
	#			echo "increasing memory"
	#			let CURRENT=$CURRENT+$memory_given_run*1024*1024
	#		else
	#			echo "decreasing memory"
	#			let CURRENT=$CURRENT-$memory_given_run*1024*1024
	#		fi
	#		echo $CURRENT > /var/cgroups/cache-test-arghya/memory.limit_in_bytes
	#		STATUS=$(ps ax|grep "$PID"|wc -l) 
	#	done
	#	echo "Success for random memory profile for merge sort!"
	#	wait


		#code for random memory profile for funnel sort
	#	./cgroup_creation.sh cache-test-arghya
	#	./executables/make-unsorted-data $data_size_run
	#	sudo sh -c "sync; echo 3 > /proc/sys/vm/drop_caches; echo 0 > /proc/sys/vm/vfs_cache_pressure"
	#	echo "funnel sort random memory for data size $data_size_run and memory size $memory_given_run" >> out-sorting.txt 
	#	cgexec -g memory:cache-test-arghya ./executables/funnel-sort-int $memory_given_run $data_size_run cache-test-arghya &
	#	PID=$!
	#	STATUS=$(ps ax|grep "$PID"|wc -l)
	#	CURRENT=$memory_given_run*1024*1024
	#	while [ $STATUS -gt 1 ] ; do
	#		sleep 5
	#		if (( $RANDOM % 2 == 1 )) || (( $CURRENT == $memory_given_run*1024*1024 )) || (( $CURRENT == 2*$memory_given_MB*1024*1024 )) ;
	#		then
	#			echo "increasing memory"
	#			let CURRENT=$CURRENT+$memory_given_run*1024*1024
	#		else
	#			echo "decreasing memory"
	#			let CURRENT=$CURRENT-$memory_given_run*1024*1024
	#		fi
	#		echo $CURRENT > /var/cgroups/cache-test-arghya/memory.limit_in_bytes
	#		STATUS=$(ps ax|grep "$PID"|wc -l) 
	#	done
	#	echo "Success for random memory profile for funnel sort!"
	#	wait


		#code to generate worse case memory profile from merge sort
		./cgroup_creation.sh cache-test-arghya
		./executables/make-unsorted-data $data_size_run
		sudo sh -c "sync; echo 3 > /proc/sys/vm/drop_caches; echo 0 > /proc/sys/vm/vfs_cache_pressure"
		sudo bash -c "echo 1 > /var/cgroups/cache-test-arghya/memory.oom_control"
		echo "merge sort to generate worse case memory for data size $data_size_run and memory size $memory_given_run" >> out-sorting.txt
		cgexec -g memory:cache-test-arghya ./executables/opt-extmem-merge-sort $memory_given_run $data_size_run cache-test-arghya 2 8


		#code to run worse case memory profile on merge sort
		./cgroup_creation.sh cache-test-arghya
		./executables/make-unsorted-data $data_size_run
		sudo sh -c "sync; echo 3 > /proc/sys/vm/drop_caches; echo 0 > /proc/sys/vm/vfs_cache_pressure"
		#putting the important memory profile in a separate file before the two next sections
		cp /home/arghya/EM-MergeSort/mem_profile.txt /home/arghya/EM-MergeSort/mem_profile_use.txt
		IFS=$'\r\n ' GLOBIGNORE='*' command eval  'XYZ=($(cat /home/arghya/EM-MergeSort/mem_profile_use.txt))'
		echo "merge sort rerun on worse case memory for data size $data_size_run and memory size $memory_given_run" >> out-sorting.txt
		cgexec -g memory:cache-test-arghya ./executables/opt-extmem-merge-sort $memory_given_run $data_size_run cache-test-arghya 1 8 &
		PID=$!
		STATUS=$(ps ax|grep "$PID"|wc -l)
		X=0
		CURRENT=0
		while [ $STATUS -gt 1 ] && [ $X -lt "${#XYZ[@]}" ]; do
		   VAL=${XYZ[$X]%.*}
		   sleep $(calc "($VAL-$CURRENT)")
		   CURRENT=$VAL
		   let X+=1
		   echo "sleeping $CURRENT seconds and writing memory size $((XYZ[X]))"
		   echo $((XYZ[X])) > /var/cgroups/cache-test-arghya/memory.limit_in_bytes
		   let X+=1
		   STATUS=$(ps ax|grep "$PID"|wc -l)
		done 
		echo "Success for worse case profile on merge sort!"
		wait

		#code to run worse case memory profile on funnel sort
		./cgroup_creation.sh cache-test-arghya
		./executables/make-unsorted-data $data_size_run
		sudo sh -c "sync; echo 3 > /proc/sys/vm/drop_caches; echo 0 > /proc/sys/vm/vfs_cache_pressure"
		IFS=$'\r\n ' GLOBIGNORE='*' command eval  'XYZ=($(cat /home/arghya/EM-MergeSort/mem_profile_use.txt))'
		echo "funnel sort on worse case memory for data size $data_size_run and memory size $memory_given_run" >> out-sorting.txt
		cgexec -g memory:cache-test-arghya ./executables/funnel-sort-int $memory_given_run $data_size_run cache-test-arghya &
		PID=$!
		STATUS=$(ps ax|grep "$PID"|wc -l)
		X=0
		CURRENT=0
		while [ $STATUS -gt 1 ] && [ $X -lt "${#XYZ[@]}" ]; do
		   VAL=${XYZ[$X]%.*}
		   sleep $(calc "($VAL-$CURRENT)")
		   CURRENT=$VAL
		   let X+=1
		   echo "sleeping $CURRENT seconds and writing memory size $((XYZ[X]))"
		   echo $((XYZ[X])) > /var/cgroups/cache-test-arghya/memory.limit_in_bytes
		   let X+=1
		   STATUS=$(ps ax|grep "$PID"|wc -l)
		done 
		echo "Success for worse case profile on funnel sort!"
		wait
	done
done
