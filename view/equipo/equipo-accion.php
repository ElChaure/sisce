<?php

$accion=$_GET["accion"];

 
 switch ($accion) {
    case "list":
        href="?c=equipo&a=ListarJSON2";
        break;
    case 1:
        echo "i es igual a 1";
        break;
    case 2:
        echo "i es igual a 2";
        break;
}
?>