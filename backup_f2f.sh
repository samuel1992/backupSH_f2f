#!/bin/bash
#script by Samuel
#SCRIPT QUE COMPACTA DETERMINADOS ARQUIVOS EM SEU LOCAL ESCLHIDO E POR FIM VERIFICA OS ARQUIVOS COMPLETADOS E OS DELETA [...]
#[...] DE SUA ORIGEM
#
#O SCRIPT FUNCIONA COM PARAMETROS SENDO O PRIMEIRO O DIRETORIO DE ORIGEM, O SEGUNDO O DE DESTINO E O TERCEIRO O NOME PARA O [...]
#[...] ARQUIVO TGZ
#ESSE SCRIPT REMOVE TODOS OS ESPAÇOS NOS ARQUIVOS/DIRETORIOS PARA BACKUPEAR

#diretorio de ogigem do backup
DIR_ORIG=$2
#diretorio de destino, para onde quer colocar o backup compactado
DIR_DEST=$3
#nome do arquivo compactado (dica: colocar em data/hora usando %d%M%h etc etc)
BKP_NAME_TGZ=$4".tgz"
#nome do arquivo sem ser compactado
BKP_NAME=$4

INFO="\e[00;32m[INFO]\e[00m" #variavel info para facilitar a vida com as cor verde
NOTICE="\e[00;33m[NOTICE]\e[00m" #variavel notice para facilitar a vida com a cor amarela
LOG="${DIR_DEST}log_tar_tf_`date +%d%m%Y_%H%M%S`" #criando o arquivo de log no caminho do destino do bkp
touch $LOG

#
#FUNCAO PARA DELETAR O LOG
#
showChoice(){
read -p "Deseja deletar o log dos itens transitados ?" CHOICE

if [ $CHOICE == "s" ]; then
	echo -e "$(date +"%d-%m-%Y %H:%M:%S") $INFO Removendo o arquivo $1" ; rm "$1"
else
	echo -e "$(date +"%d-%m-%Y %H:%M:%S") $INFO O arquivo de log foi armazenado em $1"
fi
}

#
#FUNCAO PARA REMOVER OS ESPACOS DOS AQUIVOS
#
removeSpaces(){
#ENTRANDO DENTRO DO DIRETORIO PASSADO E SUBSTITUINDO OS ESPACOS POR "_"
#
cd $DIR_ORIG ; find . -name "* *" | while read i; do novo=`echo $i | tr ' ' '_'`; mv "$i" $novo; done
}

#
#FUNCAO PARA COMPACTAR E REMOVER O ORIGINAL
#
compactAndRemove(){

removeSpaces $1 #removendo os espaços da origem

#compactando os arquivos solicitados
tar -czpf $2$3 $1
#gerando lista dos arquivos compactados
tar -tf $2$3 > $4

#LOOP DENTRO DO LOG GERADO COM OS ARQUIVOS QUE ESTAO COMPACTADOS
for i in $(cat $4); 
do
	if test -f /$i; 
	then
		echo -e "$(date +"%d-%m-%Y %H:%M:%S") $INFO Removendo o item => /$i" ; 
		rm "/$i" ;
	else
		echo -e "$(date +"%d-%m-%Y %H:%M:%S") $NOTICE O item /$i não é um arquivo valido ";
	fi
done

echo "Todos os itens compactados e removidos da origem"

showChoice $4

exit
}

#
#FUNCAO PARA COMPACTAR MAS MANTER O ORIGINAL
#
compactOnly(){

removeSpaces $1 #removendo os espaços da origem

#compactando os arquivos solicitados
tar -czpf $2$3 $1
#gerando lista dos arquivos que foram compactados
tar -tf $2$3 > $4

#LOOP DENTRO DO LOG GERADO COM OS ARQUIVOS QUE ESTAO COMPACTADOS
for i in $(cat $4); 
do
	echo -e "$(date +"%d-%m-%Y %H:%M:%S") $INFO Item compactado=> /$i" ; 

done

echo "Todos os itens compactados e mantidos na origem"

showChoice $4

exit
}

#
#FUNCAO PARA COPIAR OS ARQUIVOS E REMOVER OS ORIGINAIS COM SEGURANCA
#
copyAndRemove(){

removeSpaces $1 #removendo os spacos dos nomes dos arquivos antes de fazer as operacoes

#criando o novo diretorio de backup
mkdir $2$3

cd $1 ; #entrando no diretorio original
#LOOP PARA COPIAR OS ARQUIVOS E GERAR UM LOG
for i in * ; do 
	cp -rfv $i $2$3 >> $4 ; 
done

#UM NOVO LOOP PARA INTERAGIR NO ARQUIVO DE LOG E REMOVER OS ITENS COPIADOS DA ORIGEM
for x in $(cat $4 | awk '{print $3}' | sed -e 's/‘\|’\|.*\///g') ; do #cortando a ultima linha do log e achando o nome do arquivo
	if test -f $1$x ; then
		rm $1$x &&
		echo -e "$(date +"%d-%m-%Y %H:%M:%S") $INFO Removido o item $x do diretório original ($1)";
	else 
		echo -e "$(date +"%d-%m-%Y %H:%M:%S") $NOTICE O item $DIR_ORIG$x não é um arquivo valido ";
	fi
done

echo "Todos os itens copiados e removidos da origem"

showChoice $4

exit
}

#
#FUNCAO PARA COPIAR OS ARQUIVOS E NÃO REMOVER DO ORIGINAL
#
copyOnly(){

removeSpaces $1 #removendo os spacos no nome dos arquivos	
	
#criando o novo diretorio de backup
mkdir $2$3

cd $1 ; #entrando no diretorio original
#LOOP PARA COPIAR OS ARQUIVOS E GERAR UM LOG
for i in * ; do 
	cp -rfv $i $2$3 >> $4 ;
    echo -e "$INFO Copiado o item => $i"	
done

echo "Todos os itens copiados e mantidos na origem"

showChoice $4

exit
}

Menu(){
case $1 in 
	"--help") echo "Script com objetivo de fazer backups ou apenas mover arquivos com segurança, as opções são as seguintes :
		 -cr => Para copiar o diretorio compactando na origem e removendo o orignal.
		 -c  => Para copiar o diretorio compactando na origem sem remover o original.
		 -pr => Para copiar o diretorio sem compactar e remover o original.
		 -p  => Para copiar o diretorio sem compactar sem remover o original.

		 MODELOO DE USO: $ ./backup_f2f.sh PARAMETRO_DE_COPIA DIRETORIO_ORIGEM DIRETORIO_DESTINO NOME_DO_BACKUP 
		 exemplo de uso: $ ./backup_f2f.sh -cr /tmp/arquivos/ /tmp/bkp/ bkpSohFesta (onde copiamos compactando para /tmp/bkp/ e removemos de /tmp/arquivos/)"
	    exit 
		;;
	"-cr") compactAndRemove $DIR_ORIG $DIR_DEST $BKP_NAME_TGZ $LOG
		;;
	"-c") compactOnly $DIR_ORIG $DIR_DEST $BKP_NAME_TGZ $LOG
		;;
	"-pr") copyAndRemove $DIR_ORIG $DIR_DEST $BKP_NAME $LOG
		;;
	"-p") copyOnly $DIR_ORIG $DIR_DEST $BKP_NAME $LOG
		;;
	"-v") echo "Versão 0.1.8_beta"
		;;
	   *) echo -e "$NOTICE OPÇÃO INVÁLIDA." ; exit 1  ;; 
esac
}
#INICIANDO O PROGRAMA
Menu $1 $2 $3 $4
