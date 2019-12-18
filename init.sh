#!/bin/bash
# File Name   : init.sh
# Author      : moshan
# mail        : mo_shan@yeah.net
# Created Time: 2019-12-04 09:31:07
# Function    : Install MGR for Linux
#########################################################################
mgr_install_dir="/data/mgr/mgr"
mgr_port=(4406 4407 4408)
mgr_admin_passwd="mgrpassword"
mysql_base_dir="/data/mgr/base"
mysql_path="mysql"
test_user="test"
test_passwd="test"
repl_user="repl_user"
repl_passwd="repl_user615234"


#以下变量不建议修改
opt="${1}"                    #是否强制安装，如果指定了force，当数据目录不为空则清空，端口被占用则kill掉进程
version="${2}"
[ "${version}x" == "x" ] && version="${1}"
mgr_data_dir="${mgr_install_dir}/data"
mgr_undo_dir="${mgr_install_dir}/undo"
mgr_logs_dir="${mgr_install_dir}/logs"
mgr_binlog_dir="${mgr_install_dir}/binlog"
mgr_tmp_dir="${mgr_install_dir}/tmp"
mgr_conf_dir="${mgr_install_dir}/etc"
mgr_base_dir="${mgr_install_dir}/{data,binlog,tmp,logs,undo}"
localhost_ip=($(ip a 2>/dev/null|grep inet|grep brd|grep scope|awk '{print $2}'|awk -F'/' '{print $1}'))
error_file="/tmp/.error.log"
[ "${localhost_ip}x" == "x" ] && localhost_ip="127.0.0.1"
server_id="$(awk -F'.' '{print $3$4}' <<< ${localhost_ip})"

. /etc/profile

if [ "$(which mysql)x" != "${mysql_base_dir}/bin/${mysql_path}x" ]
then
	echo "export PATH=${mysql_base_dir}/bin:\${PATH}" >> /etc/profile
	source /etc/profile
fi

if [ "$(grep -c "^prompt" /etc/my.cnf)x" == "0x" ]
then
	sed -i '/\[mysql\]/aprompt                                                       = \\u@\\h:\\p\\ [\\ \\d\\ ]\\ >\\ ' /etc/my.cnf
fi

function f_get_mysql_conf()
{
	if [ ${4} -lt 7 ] #小于7个节点步长+2	
	then
		increment=$((${4}+2))
	else
		increment=${4}
	fi
	offset=${5} #起始值
	mkdir -p ${2}
	cat <<EOF |sed "s/999999/${1}/g" > ${3}
[mysql]
auto-rehash
prompt                                                       = \\u@\\h:\\p\\ [\\ \\d\\ ]\\ >\\ 



[mysqld]
###BASIC SETTINGS
server-id                                                    = ${server_id}999999
user                                                         = mysql
port                                                         = 999999
loose_admin_port                                             = 9999992
basedir                                                      = ${mysql_base_dir}
datadir                                                      = ${mgr_data_dir}/999999
socket                                                       = ${mgr_logs_dir}/999999/mysqld.sock
pid-file                                                     = ${mgr_logs_dir}/999999/mysql.pid
character-set-server                                         = utf8mb4
transaction_isolation                                        = READ-COMMITTED
explicit_defaults_for_timestamp                              = 1
max_allowed_packet                                           = 128M
open_files_limit                                             = 65535
sql_mode                                                     = NO_ENGINE_SUBSTITUTION

###TMP DIR
tmpdir                                                       = ${mgr_tmp_dir}/999999


default_authentication_plugin                                = mysql_native_password
loose_mysqlx                                                 = off



###CONNECTION SETTINGS
interactive_timeout                                          = 30
wait_timeout                                                 = 30
lock_wait_timeout                                            = 120
skip_name_resolve                                            = 1
max_connections                                              = 2560
max_user_connections                                         = 2048
max_connect_errors                                           = 1000000
back_log                                                     = 1024


###TABLE CACHE PERFORMANCE SETTINGS
table_open_cache                                             = 2048
table_definition_cache                                       = 1024
table_open_cache_instances                                   = 64


###SESSION MEMORY SETTINGS
read_buffer_size                                             = 16M
read_rnd_buffer_size                                         = 32M
sort_buffer_size                                             = 4M
join_buffer_size                                             = 4M
tmp_table_size                                               = 64M
max_heap_table_size                                          = 64M
thread_cache_size                                            = 64
loose_query_cache_size                                       = 0
loose_query_cache_type                                       = 0
key_buffer_size                                              = 16M
max_length_for_sort_data                                     = 8096
bulk_insert_buffer_size                                      = 64M
myisam_sort_buffer_size                                      = 128M
myisam_max_sort_file_size                                    = 128M
myisam_repair_threads                                        = 1


###LOG SETTINGS
log_error                                                    = ${mgr_logs_dir}/999999/mysql-error.log
slow_query_log                                               = 1
slow_query_log_file                                          = ${mgr_logs_dir}/999999/mysql-slow.log
long_query_time                                              = 0.2
log_queries_not_using_indexes                                = 1
log_slow_admin_statements                                    = 1
log_slow_slave_statements                                    = 1
log_throttle_queries_not_using_indexes                       = 60
min_examined_row_limit                                       = 100
expire_logs_days                                             = 3
#log_timestamps                                              = system


###INNODB SETTINGS
innodb_buffer_pool_size                                      = 128M
innodb_buffer_pool_instances                                 = 8
innodb_buffer_pool_load_at_startup                           = 1
innodb_buffer_pool_dump_at_shutdown                          = 1
innodb_lru_scan_depth                                        = 4096
innodb_lock_wait_timeout                                     = 20
innodb_io_capacity                                           = 2000
innodb_io_capacity_max                                       = 4000
innodb_flush_method                                          = O_DIRECT

#undo
loose_innodb_undo_directory                                  = ${mgr_undo_dir}/999999
loose_innodb_undo_logs                                       = 128
loose_innodb_undo_tablespaces                                = 3
loose_innodb_max_undo_log_size                               = 4G
loose_innodb_undo_log_truncate                               = 1

innodb_flush_neighbors                                       = 0
innodb_log_file_size                                         = 256M
innodb_log_files_in_group                                    = 3
innodb_log_buffer_size                                       = 32M
loose_innodb_large_prefix                                    = 1
innodb_thread_concurrency                                    = 64
innodb_print_all_deadlocks                                   = 1
innodb_strict_mode                                           = 1
innodb_purge_threads                                         = 4
innodb_write_io_threads                                      = 8
innodb_read_io_threads                                       = 8
innodb_page_cleaners                                         = 8
innodb_sort_buffer_size                                      = 32M
innodb_file_per_table                                        = 1
innodb_stats_persistent_sample_pages                         = 64
innodb_autoinc_lock_mode                                     = 2
innodb_online_alter_log_max_size                             = 4G
innodb_open_files                                            = 65535
innodb_data_file_path                                        = ibdata1:512M:autoextend
innodb_flush_log_at_trx_commit                               = 1
loose_innodb_checksums                                       = 1
innodb_checksum_algorithm                                    = crc32
innodb_rollback_on_timeout                                   = 1
loose_internal_tmp_disk_storage_engine                       = InnoDB
innodb_status_file                                           = 1
innodb_status_output_locks                                   = 1


###REPLICATION SETTINGS
sync_binlog                                                  = 1
master_info_repository                                       = TABLE
relay_log_info_repository                                    = TABLE
gtid_mode                                                    = on
enforce_gtid_consistency                                     = 1
log_slave_updates
binlog_format                                                = row
binlog_row_image                                             = full
binlog_cache_size                                            = 4M
binlog_gtid_simple_recovery                                  = 1
max_binlog_cache_size                                        = 2G
max_binlog_size                                              = 1G
relay_log_recovery                                           = 1
relay_log                                                    = ${mgr_data_dir}/999999/mysql-relay-bin
relay_log_purge                                              = 1
log_bin                                                      = ${mgr_binlog_dir}/999999/mysql-bin
#binlog_transaction_dependency_history_size                   = 25000
slave_parallel_type                                          = LOGICAL_CLOCK
slave_parallel_workers                                       = 8
slave_preserve_commit_order                                  = on


###PERFORMANCE_SCHEMA SETTINGS
performance_schema                                           = 1
performance_schema_instrument                                = '%=on'
performance_schema_digests_size                              = 40000
performance_schema_max_table_instances                       = 40000
performance_schema_max_sql_text_length                       = 4096
performance_schema_max_digest_length                         = 4096
performance-schema-instrument                                = 'stage/%=ON'
performance-schema-consumer-events-stages-current            = ON
performance-schema-consumer-events-stages-history            = ON
performance-schema-consumer-events-stages-history-long       = ON
performance-schema-consumer-events-transactions-history-long = ON


###aotu_increment
auto_increment_increment                                     = ${increment}
auto_increment_offset                                        = ${offset}

###INNODB MONITOR SETTINGS
innodb_monitor_enable=module_innodb,module_dml,module_ddl,module_trx,module_os,module_purge,module_log,module_lock,module_buffer,module_index,module_ibuf_system,module_buffer_page,module_adaptive_hash

###ADDITIONAL SETTINGS
# BEGIN ANSIBLE MANAGED BLOCK FOR MGR
###MGR SETTINGS
read_only                                                    = 1
super_read_only                                              = 1
binlog_transaction_dependency_tracking                       = WRITESET
transaction-write-set-extraction                             = XXHASH64
binlog_transaction_dependency_history_size                   = 25000
report_host                                                  = ${localhost_ip}
bind_address                                                 = 0.0.0.0
# optional for group replication
binlog_checksum                                              = NONE # only for group replication
loose-group_replication_group_name                           = '38f8425e-9182-5934-b32a-7e4317fe4a04'
loose-group_replication_start_on_boot                        = off
loose-group_replication_local_address                        = "${localhost_ip}:2999999"
loose-group_replication_group_seeds                          = "$(echo "${mgr_port[@]}"|tr " " "\n"|awk -v ip="${localhost_ip}" '{print ip":2"$1}'|tr "\n" ","|sed 's/,$//g')"
loose-group_replication_bootstrap_group                      = off
loose_group_replication_single_primary_mode                  = 0
loose_group_replication_enforce_update_everywhere_checks     = 1
loose_group_replication_unreachable_majority_timeout         = 120
loose_group_replication_start_on_boot                        = 0
loose_group_replication_ip_whitelist                         = "$(awk -F'.' '{print $1"."$2"."$3".0/24"}' <<< "${localhost_ip}")"
EOF
}

function f_logging()
{
	log_mode="${1}"
	log_info="${2}"
	log_enter="${3}"
	exit_mark="${4}"
	enter_opt=""
	if [ "${log_mode}x" == "WARNx" ]
	then
		echo -e "\033[33m"
	elif [ "${log_mode}x" == "ERRORx" ]
	then
		echo -e "\033[31m"
	else
		echo -en "\033[32m"
	fi
	if [ "${log_enter}x" == "0x" ]
	then
		log_enter="-n"
	elif [ "${log_enter}x" == "2x" ]
	then
		log_enter="-e"
		enter_opt="\n"
	else
		log_enter="-e"
	fi
	echo ${log_enter} "[$(date "+%F %H:%M:%S")] [${log_mode}] [${localhost_ip}] ${log_info}${enter_opt}"
	echo -en "\033[0m"
	if [ "${log_mode}x" == "ERRORx" -a "${exit_mark}x" != "0x" ]
	then
		exit
	fi
	echo -en "\033[32m"
}

function f_check_port()
{
	count=0
	for p in ${mgr_port[@]}
	do
		if [ ${#p} -gt 4 ]
		then
			f_logging "WARN" "mysql port value [\033[32m${p}\033[0m\033[33m] should not be greater than \033[34m9999\033[0m."
			count=$((${count}+1))
		else
			if [ "$(netstat -anplt |awk '{print $4}'|grep -c ":${p}$")x" != "0x" ]
			then
				f_logging "WARN" "The port [${p}] has been used and EXIT!"
				echo
				if [ "${opt}x" == "forcex" ]
				then
					netstat -anplt|grep mysqld|grep -w "${p}"|awk '{print $NF}'|awk -F/ '{print $1}'|tail -1|xargs -i kill -9 {}
				else
					exit
				fi
			fi
		fi
	done
	[ ${count} -gt 0 ] && exit
	unset count
}

function f_init_mysql()
{
	#${2}传给f_get_mysql_conf函数，作为offset的值
	port="${1}"
	mysql_conf="${mgr_conf_dir}/${port}/my.cnf"
	f_get_mysql_conf "${port}" "${mgr_conf_dir}/${port}" "${mysql_conf}" "${#mgr_port[@]}" "${2}"
	if [ "$(ls ${mgr_data_dir}/${port} 2> /dev/null|wc -l)x"  != "0x" ]
	then
		f_logging "WARN" "${mgr_data_dir}/${port} is not empy and EXIT!"
		echo
		if [ "${opt}x" == "forcex" ]
		then
			rm -rf ${mgr_data_dir} ${mgr_binlog_dir} ${mgr_tmp_dir} ${mgr_logs_dir} ${mgr_undo_dir}
			eval mkdir -p ${mgr_base_dir}/${port}
		else
			if [ "${port}x" == "${mgr_port[0]}x" ]
			then
				exit
			else
				return
			fi
		fi
	else
		eval mkdir -p ${mgr_base_dir}/${port}
	fi
	eval chown -R mysql. ${mgr_base_dir}
	f_logging "INFO" "Start installing \033[35mMySQL\033[0m \033[32mfor\033[0m \033[34m${port}\033[0m"
	f_logging "INFO" "Initializing for \033[35mMySQL\033[0m"
	#echo "cd ${mysql_base_dir} && ./bin/mysqld --defaults-file=${mysql_conf} --initialize --user=mysql --console"
	cd ${mysql_base_dir} && ./bin/mysqld --defaults-file=${mysql_conf} --initialize --user=mysql --console
	if [ $? -ne 0 ]
	then
		f_logging "ERROR" "Initialization failed for \033[35mMySQL\033[0m" "2" "0"|tee -a ${log_file}
		return 1
	else
		f_logging "INFO" "Initialization successful for \033[35mMySQL\033[0m"|tee -a ${log_file}
	fi
	passwd="$(grep "root@localhost:" ${mgr_logs_dir}/${port}/mysql-error.log |awk '{print $NF}'|tail -1)"
	f_logging "INFO" "Starting \033[35mMySQL\033[0m"
	cd ${mysql_base_dir} && ./bin/mysqld --defaults-file=${mysql_conf} --user=mysql &
	{ sleep 60 && touch /tmp/.stop_file; }&
	while :
	do
		sleep 3
		if [ "$(ps -ef|grep mysqld|grep -c "${mysql_conf}")x" == "0x" ]
		then
			f_logging "ERROR" "Startup failed for \033[35mMySQL [ ${mysql_conf} ]\033[0m" "2" "0"|tee -a ${log_file}
			return 1
		else
			if [ "$(ls ${mgr_logs_dir}/${port}/mysqld.sock 2>/dev/null|wc -l)x" == "1x" ]
			then
				f_logging "INFO" "Successful startup for \033[35mMySQL\033[0m"|tee -a ${log_file}
				break
			else
				if [ -f "/tmp/.stop_file" ]
				then
					rm -f /tmp/.stop_file
					f_logging "ERROR" "Startup failed for \033[35mMySQL [ ${mgr_logs_dir}/${port}/mysqld.sock ]\033[0m" "2" "0"|tee -a ${log_file}
					return 1
				fi
			fi
		fi
	done
	sleep 2
	f_logging "INFO" "Changing password root@localhost"
	#echo "${mysql_path} -uroot -p"${passwd}" -S ${mgr_logs_dir}/${port}/mysqld.sock --connect-expired-password -e \"set global super_read_only=0;set global read_only=0;set password=password('${mgr_admin_passwd}')\" 2>/dev/null"
	if [ "${version}x" == "8.0x" ]
	then
		${mysql_path} -uroot -p"${passwd}" -S ${mgr_logs_dir}/${port}/mysqld.sock --connect-expired-password -e "set global super_read_only=0;ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${mgr_admin_passwd}';" 2>/dev/null
		#echo "${mysql_path} -uroot -p\"${passwd}\" -S ${mgr_logs_dir}/${port}/mysqld.sock --connect-expired-password -e \"set global super_read_only=0;ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${mgr_admin_passwd}';\" 2>/dev/null"
	else
		${mysql_path} -uroot -p"${passwd}" -S ${mgr_logs_dir}/${port}/mysqld.sock --connect-expired-password -e "set global super_read_only=0;set global read_only=0;set password=password('${mgr_admin_passwd}')" 2>/dev/null
	fi
	${mysql_path} -uroot -p${mgr_admin_passwd} -S ${mgr_logs_dir}/${port}/mysqld.sock --connect-expired-password -e "select 1;" >/dev/null 2>&1
	if [ $? -eq 0 ]
	then
		f_logging "INFO" "Change password successfully for root@localhost"
		f_logging "INFO" "The installation is complete for \033[35mMySQL\033[0m"
	else
		f_logging "ERROR" "Change password unsuccessfully for root@localhost"
		return 1
	fi
	f_logging "INFO" "Start installing \033[33mMGR"
	if [ "${version}x" == "8.0x" ]
	then
		#${mysql_path} -uroot -p${mgr_admin_passwd} -S ${mgr_logs_dir}/${port}/mysqld.sock --connect-expired-password -e "set global super_read_only=0;set sql_log_bin = 0;create user '${test_user}'@'%';ALTER USER '${test_user}'@'%' IDENTIFIED WITH mysql_native_password BY '${test_passwd}';grant all on *.* to ${test_user}@'%';create user '${repl_user}'@'%';ALTER USER '${repl_user}'@'%' IDENTIFIED WITH mysql_native_password BY '${repl_passwd}';set sql_log_bin = 1;change master to master_user='${repl_user}',master_password='${repl_passwd}' for channel 'group_replication_recovery';install plugin group_replication SONAME 'group_replication.so';" #2>/dev/null
		${mysql_path} -uroot -p${mgr_admin_passwd} -S ${mgr_logs_dir}/${port}/mysqld.sock --connect-expired-password -e "set global super_read_only=0;set sql_log_bin = 0;CREATE USER ${repl_user}@'%' IDENTIFIED BY '${repl_passwd}';GRANT REPLICATION SLAVE ON *.* TO ${repl_user}@'%';GRANT BACKUP_ADMIN ON *.* TO ${repl_user}@'%';FLUSH PRIVILEGES;set sql_log_bin = 1;change master to master_user='${repl_user}',master_password='${repl_passwd}' for channel 'group_replication_recovery';install plugin group_replication SONAME 'group_replication.so';" 2>/dev/null
	else
		${mysql_path} -uroot -p${mgr_admin_passwd} -S ${mgr_logs_dir}/${port}/mysqld.sock --connect-expired-password -e "set global super_read_only=0;set sql_log_bin = 0;grant all on *.* to ${test_user}@'%' identified by '${test_passwd}';grant replication slave on *.* to ${repl_user}@'%' identified by '${repl_passwd}';set sql_log_bin = 1;change master to master_user='${repl_user}',master_password='${repl_passwd}' for channel 'group_replication_recovery';install plugin group_replication SONAME 'group_replication.so';" 2>/dev/null
	fi
	if [ $? -eq 0 ]
	then
		f_logging "INFO" "Initialization successful for \033[33mMGR\033[0m"|tee -a ${log_file}
	else
		f_logging "ERROR" "Initialization failed for \033[33mMGR\033[0m" "2" "0"|tee -a ${log_file}
		return 1
	fi
	f_logging "INFO" "Starting \033[33mMGR\033[0m"
	if [ "${port}x" == "${mgr_port[0]}x" ]
	then
		echo -en "\033[33m"
		#echo "${mysql_path} -uroot -p${mgr_admin_passwd} -S ${mgr_logs_dir}/${port}/mysqld.sock -e \"set global group_replication_bootstrap_group=on;start group_replication;set global group_replication_bootstrap_group=off;select * from performance_schema.replication_group_members;\" 2>/dev/null"
		${mysql_path} -uroot -p${mgr_admin_passwd} -S ${mgr_logs_dir}/${port}/mysqld.sock --connect-expired-password -e "set global group_replication_bootstrap_group=on;start group_replication;set global group_replication_bootstrap_group=off;select * from performance_schema.replication_group_members;" 2> ${error_file}
		if [ $? -eq 0 ]
		then
			mgr_stat=1
			mgr_pri_stat=1
		fi
		echo -en "\033[0m"
		master_gtid="$(${mysql_path} -uroot -p${mgr_admin_passwd} -S ${mgr_logs_dir}/${port}/mysqld.sock --connect-expired-password -e "show master status\G" 2>/dev/null|grep -A 1000 "Executed_Gtid_Set:"|sed 's/Executed_Gtid_Set: //'|tr -d "\n")"
	else
		if [ "${mgr_pri_stat}x" == "1x" ]
		then
			echo -en "\033[33m"
			#echo ${mysql_path} -uroot -p${mgr_admin_passwd} -S ${mgr_logs_dir}/${port}/mysqld.sock -e \"reset master;set global gtid_purged='${master_gtid}';start group_replication;select * from performance_schema.replication_group_members;\" 2>/dev/null"
			${mysql_path} -uroot -p${mgr_admin_passwd} -S ${mgr_logs_dir}/${port}/mysqld.sock --connect-expired-password -e "reset master;set global gtid_purged='${master_gtid}';start group_replication;select * from performance_schema.replication_group_members;" 2> ${error_file}
			[ $? -eq 0 ] && mgr_stat=1
			echo -en "\033[0m"
		else
			f_logging "WARN" "Master node failed to start, skip this startup. [ for \033[33mMGR\033[0m \033[32mon\033[0m \033[34m${port}\033[33m ]\033[0m"
			return
		fi
	fi
	if [ "${mgr_stat}x" == "1x" ]
	then
		f_logging "INFO" "Successful startup for \033[33mMGR\033[0m \033[32mon\033[0m \033[34m${port}\033[0m"
		mgr_online="$(${mysql_path} -uroot -p${mgr_admin_passwd} -S ${mgr_logs_dir}/${port}/mysqld.sock --connect-expired-password -NBe "select count(*) from performance_schema.replication_group_members where MEMBER_STATE = 'ONLINE';" 2>/dev/null)"
		echo "${mgr_online}"
	else
		f_logging "ERROR" "Startup failed for \033[33mMGR\033[0m \033[32mon\033[0m \033[34m${port}\033[0m" "2" "0"
		echo -e "\033[31m"
		cat ${error_file}|grep -v "mysql: [Warning] Using a password on the command line interface can be insecure"
		echo -e "\033[0m"
		[ -f "${error_file}" ] && rm -f ${error_file}
		return
	fi
	echo
	echo
}

function f_format_print_info()
{
	show_str="${1}"
	if [ "$(grep -cE "^space_str|space_str$|space_strs$" <<< "${show_str}")x" == "1x" ]
	then
		show_str_len=$((${#show_str}-9))
	else
		show_str_len=${#show_str}
	fi
	max_len="${2}"
	tmp_len=$((${max_len}-${show_str_len}))
	for ((var=0;var<${tmp_len};var++))
	do
		if [ "${1}x" == "-x" ]
		then
			show_str="${show_str}-"
		else
			show_str="${show_str}space_str"
		fi
	done
}

function f_enter_str()
{
	var_pos=0
	str_type=(0 0)
	clo=(0 0)
	for var in ${@}
	do
		col_len="${col_array[${var_pos}]}"
		eval str_type[${var_pos}]="${var}"
		f_format_print_info "${str_type[${var_pos}]}" "${col_len}"
		eval clo[${var_pos}]="${show_str}"
		var_pos=$((${var_pos}+1))
	done
	show_info=""
	for ((i=0;i<${#clo[@]};i++))
	do
		if [ "${i}x" == "0x" ]
		then
			if [ "${str_type[0]}x" == "-x" ]
			then
				show_info="${show_info}\033[32m+${clo[${i}]}-+-"
			else
				show_info="\033[32m|\033[0m\033[33m${clo[${i}]}\033[0m\033[32m|\033[0m"
			fi
		elif [ "${i}x" == "$((${#clo[@]}-1))x" ]
		then
			if [ "${str_type[0]}x" == "-x" ]
			then
				show_info="${show_info}${clo[${i}]}-+\033[0m"
			else
				show_info="${show_info}\033[33m ${clo[${i}]}\033[0m\033[32m|\033[0m"
			fi
		else
			if [ "${str_type[0]}x" == "-x" ]
			then
				show_info="${show_info}${clo[${i}]}-+-"
			else
				show_info="${show_info}\033[33m ${clo[${i}]}\033[0m \033[32m|\033[0m"
			fi
		fi
	done
	echo -e "${show_info}"|sed 's/space_str/ /g'|sed 's/:=/ -/g'
}

f_check_port
count=1
for port in ${mgr_port[@]}
do
	f_init_mysql "${port}" "${count}"
	[ "${?}x" == "1x" ] && f_init_mysql "${port}" "${count}"
	count=$((${count}+1))
done
unset count

unset col_array
col_array=(10 10 80)
f_enter_str "-" "-" "-"
f_enter_str "Rolespace_str" "Host" "Comandspace_str"
f_enter_str "-" "-" "-"
f_enter_str "Adminspace_str" "localhost" "${mysql_path}:=uroot:=p${mgr_admin_passwd}:=S${mgr_logs_dir}/${mgr_port[0]}/mysqld.sockspace_str"
f_enter_str "-" "-" "-"
f_enter_str "Testspace_str" "%" "${mysql_path}:=u${test_user}:=p${test_passwd}:=h${localhost_ip}:=P${mgr_port[0]}space_str"
f_enter_str "-" "-" "-"
