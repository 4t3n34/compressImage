#!/bin/bash

# Author: Ing. Maurel Reyes
# Country: Nicaragua
# City: Managua
# Email: maurel.reyes1993@gmail.com 
# Telegram: http://t.me/maurel19

scriptName=$0

#Colores
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

#Variables globales
suffix="_compress"
output="./"
verbose=0
verboseMessage=""
showHelp=0
fileExt=""
fileName=""
fileFullName=""
filePath=""
fileCompressName=""
url=""
cantImage=0
cantImageCompress=0


trap ctrl_c INT
function ctrl_c(){
    echo -e "\n${redColour}[!] Cancelando ejecución del script...\n${endColour}"
    #Mostrar nuevamente el cursor y retornar 1
    tput cnorm; exit 1
}

function helpPanel(){
    echo -e "\n${blueColour}[!] Uso: ./compressPrice [-s arg|-o arg|v|h] [FILES]${endColour}"
    for i in $(seq 1 90); do echo -ne "${grayColour}-"; done; echo -ne "${endColour}"
    echo -e "\nEste script te permite automatizar la compresión de imagenes en formato .jpeg y .png\nutilizando la web ${greenColour}https://tinypng.com/${endColour}"
    
    echo -e "\n\tOpciones:"
    echo -e "\t${grayColour}  [-s | --suffix]${endColour}${yellowColour}\tDefine el sufijo de las imagenes comprimidas${endColour} ${purpleColour}ej: ./$scriptName -s _compress imagen1.png -> imagen1_compress.png${endColour}"
    echo -e "\t${grayColour}  [-o | --output]${endColour}${yellowColour}\tDefine la carpeta donde se guardaran las imagenes comprimidas${endColour}"
    echo -e "\t${grayColour}  [-v | --verbose]${endColour}${yellowColour}\tModo verbose${endColour}"
    echo -e "\t${grayColour}  [-h | --help]${endColour}${yellowColour}\t\tMuestra este panel de ayuda${endColour}"
    
    for i in $(seq 1 90); do echo -ne "${grayColour}-"; done; echo -ne "${endColour}"
    echo -e "\n\tEjemplos:"
    echo -e "\t${yellowColour} Usando con find: ${endColour}${purpleColour}\tfind . -iname \"*.jpg\" -or -iname \"*.png\" | xargs ./$scriptName  ${endColour}"
    echo -e "\t${yellowColour} Usando con ls: ${endColour}${purpleColour}\tls -d *.jpg *.png | xargs ./$scriptName  ${endColour}"
    tput cnorm; exit
}

showError(){
    echo  -e "\e[01;31m === $ERROR ===\e[0m "
}

showVerbose(){
    if [ $verbose -eq 1 ]; then
        echo -e "$(date +"%d/%m/%Y %r"):$verboseMessage"
    fi
}

validatePathOutput(){

    if [ ! -d "$output" ]; then
        echo -e "${blueColour}Creando el directorio $output ${endColour}"
        mkdir -p "$output"
    fi
}

downloadFile(){
    
    verboseMessage="Descargando el archivo $fileFullName"
    showVerbose
    tempName="$output/temp$fileFullName"
    wget -O "$tempName" "$url/$fileFullName" 2>/dev/null;
    #Validar si el archivo descargado no esta corrupto
    identify $tempName>/dev/null 2>&1
    if [ $? -eq 1 ];then
        echo -e "${redColour}Ocurrio un error al tratar de descargar el archivo $fileFullName${endColour}"
        rm -f $tempName
    else
        mv $tempName "$output/$fileCompressName"
    fi
    verboseMessage="Guardado como $fileCompressName"
    showVerbose
}

compressFile(){
    verboseMessage="Comprimiendo el archivo $fileFullName ($cantImageCompress/$cantImage)"
    showVerbose
    response=$(curl -X POST "https://tinypng.com/web/shrink" -H "Content-Type: image/jpeg" -H "user-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.141 Safari/537.36" --data-binary @$filePath 2>/dev/null)
    if [[ $response == *"url"* ]];then
        url=$(echo $response | python -c "import json,sys;obj=json.load(sys.stdin);print(obj['output']['url']);")
        downloadFile
    else
        echo -e "${blueColour} Pausando el proceso por 1m para reintentar...${endColour}"
        sleep 1m
        compressFile
    fi
}

# read the options https://www.tutorialspoint.com/unix_commands/getopt.htm
TEMP=$(getopt -o v::s:o:h:: --long verbose::,sufix:,output:,help:: -- "$@")
eval set -- "$TEMP"

while true ; do
    case "$1" in
        -v|--verbose)
            verbose=1; shift 2;;
        -s|--sufix)
            case "$2" in
                "") suffix="_compress"; shift 2;;
                *) suffix=$2; shift 2;;
            esac;;
        -o|output:)
            output=$2; validatePathOutput; shift 2;;
        -h|--help)
            helpPanel;shift 2;;
        --) shift; break;;
        *) echo -e "${redColour}El argumento $1 no es valido. ${endColour}"; exit 1;;
    esac
done

cantImage=$#
count=0
if [ $# -gt 0 ]
then
    echo -e "$(date +"%d/%m/%Y %r"):${greenColour}[!] Iniciando la compresión de imagenes${endColour}"
    echo -e "$(date +"%d/%m/%Y %r"):${greenColour}[!] $cantImage imagenes a comprimir${endColour}"
    for ARCHIVO in $*;
    do
         # Validar que el ARCHIVO exista
        if [ -f $ARCHIVO ] && [  -e $ARCHIVO ] && [ "$(file -b --mime-type $ARCHIVO)" == "image/jpeg" ] || [ "$(file -b --mime-type $ARCHIVO)" == "image/png" ]
        then
            filePath=$ARCHIVO
            fileFullName=$(basename $filePath)
            fileExt=$(echo $fileFullName | awk -F "." '{printf $NF}')
            fileName=$(basename -s .$fileExt $fileFullName)
            fileCompressName="$fileName$suffix.$fileExt"
            let cantImageCompress+=1
            compressFile
            sleep 1
        else
            echo -e "${redColour}[!] El archivo $ARCHIVO no existe o no es valido${endColour}"
        fi
    done
    echo -e "$(date +"%d/%m/%Y %r"):${greenColour}[!] Compresión finalizada${endColour}"
else
    ERROR="Debes especificar el archivo a comprimir";showError
fi

