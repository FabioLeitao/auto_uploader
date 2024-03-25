#!/usr/bin/bash -x
COMMAND=$0
ARGUMENTO=$1
FLAG=$2
TIMESTAMP=`date +"%Y-%m-%d %T"`
CONTADOR=0

PASTA_HOME="/home/leitao/arquivo"
PASTA_ORIGEM="${PASTA_HOME}/enviar"
PASTA_ATIVA="${PASTA_HOME}/transferindo"
PASTA_CONTADOR="${PASTA_HOME}/contador"
PASTA_BKP="${PASTA_HOME}/bkp"
PASTA_LOG="${PASTA_HOME}/log"
ARQUIVO_LOG="${PASTA_LOG}/evidencias.log"
SFTP_HOST="sftp.riobrasilterminal.com"
SFTP_CREDENCIAL="leitao"

SFTP=`which sftp`
SCP=`which scp`
ID=`which id`

function check_service_(){
	VMIsRunning=false
	BUSCA=`${QM} list | grep ${ARGUMENTO} | grep running`
	ULTIMA=$?
	if [ ${ULTIMA} -eq 0 ] ; then
		VMIsRunning=true
		VM_NAME=`${QM} list | grep ${ARGUMENTO} | awk -F' ' {'print $2'}`
		echo "0:200:OK - VM ${ARGUMENTO} - ${VM_NAME} is running."    # returncode 0 = put sensor in OK status
	else
		#echo "1:404:WARNING - VM ${ARGUMENTO} is not present or not running."    # returncode 1 = Warning - put sensor in WARNING status
		echo "5:404:ERROR - VM ${ARGUMENTO} is not present or not running."    # returncode 5 = Content Error - put sensor in WARNING status
		exit 5
	fi
}

die_(){
	exit 999
}

is_root_(){
	local id=$(${ID} -u)
	if [ $id -ne 0 ] ; then
		echo "4:500:ERROR - You have to be root to run $0."    # returncode 4 = Protocol Error - put sensor in DOWN status
		do_log_ ERROR - You have to be root to run $0.
		die_ ;
	fi
}

do_log_(){
	# Aceitaria qualquer string para ser anotada no arquivo de evidencias configurado
	LOG_=$@
	TIMESTAMP=`date +"%Y-%m-%d %T"`
	touch ${ARQUIVO_LOG}
	echo "${TIMESTAMP} - ${LOG_}" >> ${ARQUIVO_LOG}
}

function preparation_(){
	if [ ! -d ${PASTA_LOG} ] ; then
		mkdir -p ${PASTA_LOG}
		do_log_ WARN - Recriada pasta de arquivos de evidências.
	fi 
	if [ ! -d ${PASTA_ATIVA} ] ; then
		mkdir -p ${PASTA_ATIVA}
		do_log_ WARN - Recriada pasta de transferências ativas.
	fi 
	if [ ! -d ${PASTA_BKP} ] ; then
		mkdir -p ${PASTA_BKP}
		do_log_ WARN - Recriada pasta de backups de transferências feitas.
	fi 
	if [ ! -d ${PASTA_ORIGEM} ] ; then
		mkdir -p ${PASTA_ORIGEM}
		do_log_ WARN - Recriada pasta de origem de arquivos.
	fi 
	if [ ! -d ${PASTA_CONTADOR} ] ; then
		mkdir -p ${PASTA_CONTADOR}
		do_log_ WARN - Recriada pasta de contador.
	fi
	if [ ! -x ${SFTP} ] ; then 
		echo "3:500:ERROR - command sftp not found."     # returncode = 3 = System Error - put sensor in DOWN status
		do_log_ ERROR - command sftp not found.
		die_ ; 
	fi
	if [ ! -x ${SCP} ] ; then 
		echo "3:500:ERROR - command scp not found."     # returncode = 3 = System Error - put sensor in DOWN status
		do_log_ ERROR - command scp not found.
		die_ ; 
	fi
	if [ ! -x ${ID} ] ; then
		echo "3:500:ERROR - command id not found."    # returncode = 3 = System Error - put sensor in DOWN status
		do_log_ ERROR - command id not found.
		die_ ; 
	fi
#	is_root_;
}

function ajuda_(){
        echo "2:500:ERROR - Usage: ${COMMAND} [Parâmetro TBD] [-h|--help]" >&2 ; # returncode = 2 = put sensor in DOWN status
	die_ ;
}

function atua_no_flag_(){
        if [ $# -gt 1 ]; then
                ajuda_;
        else
          case "${FLAG}" in
                -h|--help)
                        ajuda_ ;
                        ;;
                *)
                        ;;
          esac
        fi
}

function main_(){
        atua_no_flag_ ;
	preparation_;
#	check_service_;
}

if [ $# -lt 1 ]; then
        	ajuda_;
else
  case "${ARGUMENTO}" in
       	-h|--help)
               	ajuda_ ;
                exit 1
       	        ;;
        *)
		main_;
               	;;
  esac
fi
exit 0
