#!/bin/bash
# Titulo:	Encender una maquina remotamente
# Fecha:	14/02/13
# Autor:	elsudano
# Versión:	1.0
# Descripción:	Utiliza el wol de linux para poder encender una maquina remotamente
# Opciones: Ninguna
# Uso: ./wol-gui.sh sin parámetros
#------------------------------------------------------------Cabeceras de Configuración------------------------------------------------------------------------------------------------------------
REGEX="^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){2}(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5]))$"
RED=($(route | grep default))
PUERTA=${RED[1]}
INTERFACE=${RED[7]}
unset RED
BINARIOS=(kdialog wol)
# kdialog	Este Fichero es para poder ejecutar la interfaz gráfica
# wol		Este fichero es para poder ocultar las transacciones a través de internet

#------------------------------------------------------------Función Comprobar Ficheros--------------------------------------------------------------------------------------------------------
function comprobar(){
  local valido=0
  local retval=0
  for fichero in ${BINARIOS[@]}
  do
    df=($(find / -name $fichero)) # variable df = directorios de ficheros
    if [[ ${#df[@]} -gt "1" ]]; then
      for opcion in ${df[@]}
      do
	local opciones="$opciones $opcion $opcion false "
      done
      seleccion=$(kdialog --title "Elija una opción " --radiolist " Elija donde se encuentra el\nfichero: $fichero en su sistema " $opciones)
      if [[ $? = "0" ]] && [ -x $seleccion ]; then
	SITUACION=("${SITUACION[*]} $seleccion")
	kdialog --title "Fichero encontrado " --passivepopup "El fichero $seleccion se ha encontrado, y es ejecutable" 3
	valido=$(($valido+1))
      else
	kdialog --title "Advertencia " --sorry "Si el fichero $fichero no estaba en la lista anterior\nsignifica que no se encuentra en su\nsistema y deberá instalarlo\no bien el fichero no es ejecutable"
	exit 4
      fi
      opciones=""
    elif [[ ${#df[@]} -eq "1" ]] && [ -x ${df[0]} ]; then
      SITUACION=("${SITUACION[*]} ${df[0]}")
      kdialog --title "Fichero encontrado " --passivepopup "El fichero ${df[0]} se ha encontrado, y es ejecutable" 3
      valido=$(($valido+1))
    else
      kdialog --title "Fichero NO encontrado " --passivepopup "El fichero $fichero no se ha encontrado en su sistema\npor favor instalelo y vuelva a ejecutar este script" 5
      local no_encontrados="$no_encontrados $fichero"
    fi
  done
  if [[ ${#array[@]} -eq "$valido" ]]; then
    kdialog --title "Fichero necesario " --passivepopup "La comprobación de los ficheros ha sido un éxito" 3
    retval=1
  else
    kdialog --title "Fichero necesario " --msgbox "Uno o varios de los ficheros necesarios para ejecutar este script no
se ha encontrado en su sistema por favor instale los siguientes ficheros
y vuelva a ejecutar este script\n
$no_encontrados"
    exit 5
  fi
  unset no_encontrados
  unset opciones
  unset valido
  return $retval
}
#------------------------------------------------------------Función Submenu Encender red local--------------------------------------------------------------------------------------------------------
function submenu_local(){
  datos="-h $(kdialog --title "Que equipo quiere encender" --inputbox "Introduzca el nombre del equipo" "portátil")"
  datos="$datos -i $(kdialog --title "Que equipo quiere encender" --inputbox "Introduzca la IP" $PUERTA)"
  datos="$datos $(kdialog --title "Que equipo quiere encender" --inputbox "Introduzca la MAC ADDRESS" "00:19:DB:57:D4:C9")"
  echo $datos
  #kdialog --title "alerta" --msgbox $datos
}
#------------------------------------------------------------Función Submenu Encender red externa--------------------------------------------------------------------------------------------------------
function submenu_externa(){
  datos=($(kdialog --title "Que equipo quiere encender" --inputbox "Introduzca la IP" "$PUERTA"))
  datos=(${datos[@]} $(kdialog --title "Que equipo quiere encender" --inputbox "Introduzca la MAC ADDRESS" "xx:xx:xx:xx:xx:xx"))
  echo $(${datos[@]})
}
#------------------------------------------------------------Función Menú Principal---------------------------------------------------------------------------------------------------------------
function menu_main(){
  case $(kdialog --title "Wake on Lan GUI" --menu "Elija una opción" pwonnet "Encender ordenador de la misma red" pwoninet "Encender ordenador de una red remota" salir "Salir") in
    pwonnet)
      wol $(submenu_local) -p 9 -v
      if [[ $? -eq "0" ]]; then
      menu_main
      fi;;
    pwoninet)
      submenu_externa
      if [[ $? -eq "0" ]]; then
      menu_main
      fi;;
    salir)
      if [[ $(kdialog --title "Salir" --yesno "Quiere salir de la aplicación"; echo $?) -eq "1" ]]; then
      menu_main
      fi;;
  esac
  exit 0
}
menu_main