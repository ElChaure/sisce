<?php
   ob_start();
   session_start();
   require_once 'model/usuario.php';
?>

<form class="login100-form validate-form" method="post" action="<?php echo $_SERVER['PHP_SELF']; ?>">
    <span class="login100-form-title p-b-34">
    Inicio de Sesión
    </span>

    <div class="wrap-input100 rs1-wrap-input100 validate-input m-b-20" data-validate="Type user name">
        <input id="first-name" class="input100" type="text" name="usuario" placeholder="Usuario">
        <span class="focus-input100"></span>
    </div>
    <div class="wrap-input100 rs2-wrap-input100 validate-input m-b-20" data-validate="Type password">
        <input class="input100" type="password" name="pwd" placeholder="Contraseña">
        <span class="focus-input100"></span>
    </div>

    <div class="container-login100-form-btn">
        <input type="submit" name="iniciar_sesion" class="login100-form-btn" value="Iniciar Sesión">
    </div>

</form>

