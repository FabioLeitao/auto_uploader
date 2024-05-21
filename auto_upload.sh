#!/usr/bin/bash 
COMMAND=$0
ARGUMENTO=$1
FLAG=$2
QUANTOS=$#
DEBUG=FALSE
TIMESTAMP=`date +"%Y-%m-%d %T"`
CONTADOR=0

PASTA_HOME="${HOME}/arquivo_mnt"
PASTA_ORIGEM="${PASTA_HOME}/enviar"
PASTA_ATIVA="${PASTA_HOME}/transferindo"
PASTA_CONTADOR="${PASTA_HOME}/contador"
PASTA_BKP="${PASTA_HOME}/bkp"
PASTA_LOG="${PASTA_HOME}/log"
ARQUIVO_LOG="${PASTA_LOG}/evidencias.log"
ARQUIVO_LISTA="${PASTA_LOG}/lista.log"
ARQUIVO_LISTB="${PASTA_LOG}/listb.log"
ARQUIVO_CONTA="${PASTA_LOG}/conta.log"
ARQUIVO_CONTB="${PASTA_LOG}/contb.log"
ARQUIVO_SUM="${PASTA_LOG}/sum.log"
ARQUIVO_MOVE="${PASTA_LOG}/move.log"
ARQUIVO_TOTAL="${PASTA_CONTADOR}/contador.log"
SFTP_HOST="p-prdftp.ictsi.net"
SFTP_PORT="1122"
SFTP_CREDENCIAL="P-PRDFTP\PRD_EAMS_RIO"
SFTP_ID="~/.ssh/id_ed25519.pub"
SFTP_PASTA_REMOTA="./"


WHOAMI=`which whoami`
HOSTNAME=`which hostname`
TOUCH=`which touch`
SFTP=`which sftp`
SCP=`which scp`
SUM=`which sha256sum`
DIFF=`which diff`
EXPR=`which expr`
CAT=`which cat`
CUT=`which cut`
AWK=`which awk`
SED=`which sed`
WC=`which wc`
NC=`which nc`
ID=`which id`
QUAL=`${HOSTNAME} -s`
QUEM=`${WHOAMI}`

function transfere_(){
	if [ ${SSHIsRunning} ] || [ ${PRONTO} ] ; then
		for FILE in ${FILES} ; do
			TRANSMITIDO=false
			FALHOU=false
			$SCP -q -4 -o ConnectionAttempts=4 ${PASTA_ATIVA}/${FILE} ${SFTP_CREDENCIAL}@${SFTP_HOST}:${SFTP_PASTA_REMOTA}
			ULTIMA=$?
				if [ ${ULTIMA} -ne 0 ] ; then
					mv ${PASTA_ATIVA}/${FILE} ${PASTA_ORIGEM}/${FILE}
					do_log_ OK - Movido arquivo ${FILE} para pasta de origem para tentar novamente
					FALHOU=true
					die_ ;
				else
					mv ${PASTA_ATIVA}/${FILE} ${PASTA_BKP}/${FILE}
					do_log_ OK - Movido arquivo ${FILE} para pasta de bkp para armazenamento temporário
					CONTADOR=`${CAT} ${ARQUIVO_TOTAL}`
					NOVO_TOTAL=`${EXPR} ${CONTADOR} + 1`
					echo ${NOVO_TOTAL} > ${ARQUIVO_TOTAL}
					do_log_ Ok - Total ${NOVO_TOTAL} transmitidos.
					TRANSMITIDO=true
				fi
		done
	else
		echo Nao vai dar
	fi
	CONTADOR=`${CAT} ${ARQUIVO_TOTAL}`
	echo "0:${CONTADOR}:OK - Total ${CONTADOR} arquivos transmitidos."    # returncode 0 = put sensor in OK status
	do_log_ OK - Transferência completada com sucesso.
}

function arruma_(){
	PRONTO=false
	cd ${PASTA_ORIGEM}
	if [ ! -f ${ARQUIVO_LISTA} ] ; then
		ls -ls > ${ARQUIVO_LISTA}
	else
		ls -ls > ${ARQUIVO_LISTB}
		${DIFF} -qN ${ARQUIVO_LISTA} ${ARQUIVO_LISTB}
		ULTIMA=$?
		if [ ${ULTIMA} -ne 0 ] ; then
			ls -ls > ${ARQUIVO_LISTA}
			ls -ls | ${WC} -l > ${ARQUIVO_CONTA}
			CONTA=`${CAT} ${ARQUIVO_CONTA}`
			if [ ${CONTA} -gt 1 ] ; then
				${SUM} * > ${ARQUIVO_SUM}
			fi
			die_ ;
		fi
	fi
	LISTADO=true
	if [ ! -f ${ARQUIVO_CONTA} ] ; then
		ls -ls | ${WC} -l > ${ARQUIVO_CONTA}
	else 
		ls -ls | ${WC} -l > ${ARQUIVO_CONTB}
		${DIFF} -qN ${ARQUIVO_CONTA} ${ARQUIVO_CONTB}
		ULTIMA=$?
		if [ ${ULTIMA} -ne 0 ] ; then
			ls -ls | ${WC} -l > ${ARQUIVO_CONTA}
			CONTA=`${CAT} ${ARQUIVO_CONTA}`
			if [ ${CONTA} -gt 1 ] ; then
                        	${SUM} * > ${ARQUIVO_SUM}
			fi
			die_ ;
		fi

	fi
	CONTADO=true
	if [ ! -f ${ARQUIVO_SUM} ] ; then
		CONTA=`${CAT} ${ARQUIVO_CONTA}`
		if [ ${CONTA} -gt 1 ] ; then
			${SUM} * > ${ARQUIVO_SUM}
		fi
		die_ ;
	else
		${SUM} --quiet -c ${ARQUIVO_SUM}
		ULTIMA=$?
		if [ ${ULTIMA} -ne 0 ] ; then
			CONTA=`${CAT} ${ARQUIVO_CONTA}`
			if [ ${CONTA} -gt 1 ] ; then
                        	${SUM} * > ${ARQUIVO_SUM}
			fi
			die_ ; 
		fi
	fi
	SOMADO=true
	${CAT} ${ARQUIVO_SUM} | ${CUT} -d " " -f3- > ${ARQUIVO_MOVE}
	FILES=`${CAT} ${ARQUIVO_MOVE}`
	for FILE in * ; do
		FILE_NOVO=`echo ${FILE} | sed -e 's/ /_/g'| sed -e 'y/ñçãāáǎàēéěèīíǐìõōóǒòūúǔùǖǘǚǜÑÇÃĀÁǍÀĒÉĚÈĪÍǏÌÕŌÓǑÒŪÚǓÙǕǗǙǛ/ncaaaaaeeeeiiiiooooouuuuüüüüNCAAAAAEEEEIIIIOOOOOUUUUÜÜÜÜ/'`
		mv "./${FILE}" "./${FILE_NOVO}"
		do_log_ WARN - Arquivo ${FILE} renomeado para compatibilidade.
	done
	${CAT} ${ARQUIVO_MOVE} | ${SED} -e 's/ /_/g' | ${SED} -e 'y/ñçãāáǎàēéěèīíǐìõōóǒòūúǔùǖǘǚǜÑÇÃĀÁǍÀĒÉĚÈĪÍǏÌÕŌÓǑÒŪÚǓÙǕǗǙǛ/ncaaaaaeeeeiiiiooooouuuuüüüüNCAAAAAEEEEIIIIOOOOOUUUUÜÜÜÜ/' > ${ARQUIVO_MOVE}.2
	FILES=`${CAT} ${ARQUIVO_MOVE}.2`
	for FILE in ${FILES} ; do
		mv ${PASTA_ORIGEM}/${FILE} ${PASTA_ATIVA}/${FILE}
		do_log_ WARN - Movido arquivo ${FILE} para pasta de transferência.
	done
	rm -f ${ARQUIVO_LISTA} ${ARQUIVO_LISTB} 
	rm -f ${ARQUIVO_CONTA} ${ARQUIVO_CONTB}
	rm -f ${ARQUIVO_SUM}
	LIMPADO=true
	cd - 
	${TOUCH} ${ARQUIVO_TOTAL}
	PRONTO=true
}

function check_service_(){
	SSHIsRunning=false
	BUSCA=`${NC} -z -w2 ${SFTP_HOST} ${SFTP_PORT} `
	ULTIMA=$?
	if [ ${ULTIMA} -eq 0 ] ; then
		SSHIsRunning=true
		#echo "0:200:OK - Server ${SFTP_HOST} is running SSH."    # returncode 0 = put sensor in OK status
		#do_log_ OK - Server ${SFTP_HOST} is running SSH.
	else
		#echo "1:404:WARNING - VM ${ARGUMENTO} is not present or not running."    # returncode 1 = Warning - put sensor in WARNING status
		echo "5:404:ERROR - Server ${SFTP_HOST} is not present or not running SSH."    # returncode 5 = Content Error - put sensor in WARNING status
		do_log_ ERROR - Server ${SFTP_HOST} is not present or not running SSH.
		exit 5
	fi
}

die_(){
	exit 999
}

is_usr_(){
	local id=$(${ID} -u)
	if [ $id -ne 1000 ] ; then
		echo "4:500:ERROR - You have to be usr leitao to run $0."    # returncode 4 = Protocol Error - put sensor in DOWN status
		do_log_ ERROR - You have to be usr leitao to run $0.
		die_ ;
	fi
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
	if [ ${DEBUG} = "TRUE" ] ; then
		echo "${TIMESTAMP} - ${LOG_}" | tee -a ${ARQUIVO_LOG}
	else
		echo "${TIMESTAMP} - ${LOG_}" >> ${ARQUIVO_LOG}
	fi
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
	if [ ! -x ${NC} ] ; then
		echo "3:500:ERROR - command nc not found."    # returncode = 3 = System Error - put sensor in DOWN status
		do_log_ ERROR - command nc not found.
		die_ ; 
	fi
#	is_root_;
	is_usr_;
}

function ajuda_(){
        echo "2:500:ERROR - Usage: ${COMMAND} [Parâmetro TBD] [-h|--help]" >&2 ; # returncode = 2 = put sensor in DOWN status
	die_ ;
}

function atua_no_flag_(){
        if [ ${QUANTOS} -gt 2 ]; then
                ajuda_;
        else
          case "${FLAG}" in
                -h|--help)
                        ajuda_ ;
                        ;;
                -v|--vorbose)
			echo "Server Server: ${QUAL}"
			DEBUG=TRUE
                        ;;
                *)
			DEBUG=FALSE
                        ;;
          esac
        fi
	preparation_   ;
	check_service_ ;
	arruma_        ;
	transfere_     ;
}

function main_(){
        atua_no_flag_  ;
}

if [ ${QUANTOS} -lt 1 ]; then
        	ajuda_;
else
  case "${ARGUMENTO}" in
       	-h|--help)
               	ajuda_ ;
                exit 1
       	        ;;
        -v|--vorbose)
		echo "Server Server: ${QUAL}"
		DEBUG=true 
		main_;
                ;;
        *)
		main_;
               	;;
  esac
fi
exit 0
