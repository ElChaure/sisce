<?php
   session_start();
   unset($_SESSION["username"]);
   unset($_SESSION["password"]);
   
   echo 'Usted cerro su sesion de trabajo';
   header('Refresh: 2; URL = login.php');
?>