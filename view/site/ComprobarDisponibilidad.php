<?php
require_once("DBController.php");
$db_handle = new DBController();


if(!empty($_POST["usuario"])) {
  $query = "SELECT * FROM usuarios WHERE usuario='" . $_POST["usuario"] . "'";
  $user_count = $db_handle->numRows($query);
  if($user_count>0) {
      echo "<span class='estado-no-disponible-usuario'> Usuario no Disponible.</span>";
  }else{
      echo "<span class='estado-disponible-usuario'> Usuario Disponible.</span>";
  }
}

if(!empty($_POST["email"])) {
  $query = "SELECT * FROM usuarios WHERE Email='" . $_POST["email"] . "'";
  $user_count = $db_handle->numRows($query);
  if($user_count>0) {
      echo "<span class='estado-no-disponible-email'> Email no Disponible.</span>";
  }else{
      echo "<span class='estado-disponible-email'> Email Disponible.</span>";
  }
}
?>