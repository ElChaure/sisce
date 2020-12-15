<!DOCTYPE html>
<html>
<head>
<style>
.box2 {
  display: inline-block;
  width: 200px;
  height: 100px;
  margin: 1em;
}
</style>
</head>
<body>
<nav class="navbar navbar-default">
  <div class="container-fluid">
    <!-- Brand and toggle get grouped for better mobile display -->
    <div class="navbar-header">
      <button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#bs-example-navbar-collapse-1" aria-expanded="false">
        <span class="sr-only">Toggle navigation</span>
        <span class="icon-bar"></span>
        <span class="icon-bar"></span>
        <span class="icon-bar"></span>
      </button>
      <a class="navbar-brand" href="?c=Site"><i class="fa fa-home"></i> Bienes Telematicos </a>
    </div>

    <!-- Collect the nav links, forms, and other content for toggling -->
    <div class="collapse navbar-collapse" id="bs-example-navbar-collapse-1">
      <ul class="nav navbar-nav">
        <li><a href="index.php?c=equipo">Bienes<i class="fa fa-crosshairs" aria-hidden="true"></i>
        <li><a href="index.php?c=solicitud">Solicitud <i class="fa fa-sign-in" aria-hidden="true"></i>
</a></li>
<!--li><a href="index.php?c=devolucion">Devolucion <i class="fa fa-backward" aria-hidden="true"></i-->
</a></li>
        <li class="dropdown">
          <a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button" aria-haspopup="true" aria-expanded="false">Orden Salida <i class="fa fa-sign-out" aria-hidden="true"></i> <span class="caret"></span></a>
          <ul class="dropdown-menu">
            <li><a href="index.php?c=solicitud&a=view_orden">Genera Salida de Almacen <i class="fa fa-shopping-cart"></i></a></li>
            <!--li><a href="#" disabled>Soporte <i class="fa fa-wrench"></i></a></li>
            <li><a href="#">Bien Nacional  <i class="fa fa-thumbs-o-up "></i></a></li-->
          </ul>
        </li>

        
        <li class="dropdown">
          <a href="#" class="dropdown-toggle" 
                      data-toggle="dropdown" 
                      role="button" 
                      aria-haspopup="true" 
                      aria-expanded="false">
                      Reportes 
                      <i class="fa fa-print" aria-hidden="true"></i> 
                      
                      <span class="caret"></span>
          </a>
          <ul class="dropdown-menu">
            <li><a href="?c=reportes&a=equipos_general" target="_blank">Listado General de Equipos <i class="fa fa-print" aria-hidden="true"></i></a></li>
            <li><a href="?c=reportes&a=equipos_sbn" target="_blank">Listado Equipos Sin Bien Nacional Asignado <i class="fa fa-print" aria-hidden="true"></i></a></li> 
            <li><a href="?c=reportes&a=equipos_disponibles" target="_blank">Listado Equipos Disponibles <i class="fa fa-print" aria-hidden="true"></i></a></li>
            <li><a href="?c=reportes&a=equipos_itinerantes" target="_blank">Listado Equipos Itinerantes <i class="fa fa-print" aria-hidden="true"></i></a></li>
            <li><a href="?c=reportes&a=equipos_reservados" target="_blank">Listado Equipos Reservados <i class="fa fa-print" aria-hidden="true"></i></a></li>  

            <li><a href="?c=reportes&a=solicitudes" target="_blank">Listado General de Solicitudes <i class="fa fa-print" aria-hidden="true"></i></a></li>
            <li><a href="?c=reportes&a=solicitudes_pendientes" target="_blank">Listado Solicitudes Pendientes<i class="fa fa-print" aria-hidden="true"></i></a></li>            
            <li><a href="?c=reportes&a=solicitudes_procesadas" target="_blank">Listado Solicitudes Procesadas<i class="fa fa-print" aria-hidden="true"></i></a></li>            
            <li><a href="?c=reportes&a=solicitudes_parcialmente_procesadas" target="_blank">Listado Solicitudes Parcialmente Procesadas<i class="fa fa-print" aria-hidden="true"></i></a></li>  <li><a href="?c=reportes&a=solicitudes_canceladas" target="_blank">Listado Solicitudes Canceladas<i class="fa fa-print" aria-hidden="true"></i></a></li>
            <li><a href="?c=reportes&a=solicitudes_pendientes_sin_detalle" target="_blank">Listado Solicitudes Pendientes Sin Detalle<i class="fa fa-print" aria-hidden="true"></i></a></li>
            <li><a href="?c=reportes&a=solicitudes_pendientes_sin_orden" target="_blank">Listado Solicitudes Pendientes Sin Orden de Salida<i class="fa fa-print" aria-hidden="true"></i></a></li>
            <li><a href="?c=reportes&a=ordenes_salida" target="_blank">Listado Ordenes de Salida<i class="fa fa-print" aria-hidden="true"></i></a></li>                                                

            <li><a href="?c=Reportes&a=usuario" target="_blank">Listado de Usuarios<i class="fa fa-print" aria-hidden="true"></i></a></li> 
            <li><a href="?c=Reportes&a=empleados" target="_blank">Listado de Empleados<i class="fa fa-print" aria-hidden="true"></i></a></li> 
            <li><a href="?c=Reportes&a=oficinas" target="_blank">Listado de Oficinas<i class="fa fa-print" aria-hidden="true"></i></a></li>
            <li><a href="?c=Reportes&a=departamentos" target="_blank">Listado de Departamentos<i class="fa fa-print" aria-hidden="true"></i></a></li>
             <li><a href="?c=Reportes&a=marcas" target="_blank">Listado de Marcas<i class="fa fa-print" aria-hidden="true"></i></a></li>
             <li><a href="?c=Reportes&a=articulos" target="_blank">Listado de Articulos<i class="fa fa-print" aria-hidden="true"></i></a></li>
             <li><a href="?c=Reportes&a=proveedores" target="_blank">Listado de Proveedores<i class="fa fa-print" aria-hidden="true"></i></a></li>        
          </ul>
        </li>

        <li class="dropdown">
          <a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button" aria-haspopup="true" aria-expanded="false">Configuracion <i class="fa fa-cogs" aria-hidden="true"></i><span class="caret"></span></a>
          <ul class="dropdown-menu">
          <li><i class="fa fa-users" aria-hidden="true"></i> Gestion de Usuarios</li>
          <li><a href="index.php?c=Usuario">Registro de Usuarios <i class="fa fa-hand-pointer-o" aria-hidden="true"></i></a></li>
          <li><a href="index.php?c=Roles">Roles de Usuario <i class="fa fa-angellist" aria-hidden="true"></i></a></li>
          <li><a href="index.php?c=Role_perm">Permisos a Roles <i class="fa fa-user-plus" aria-hidden="true"></i></a></li>
          <li><a href="index.php?c=Permissions">Permisos <i class="fa fa-user-plus" aria-hidden="true"></i></a></li>
          <!--li><a href="index.php?c=User_role">Gestion de Roles de Usuario <i class="fa fa-user-plus" aria-hidden="true"></i></a></li>
          <li><a href="#">Cambiar Clave</a></li-->
          <li class="divider"></li>
          <li><i class="fa fa-dropbox" aria-hidden="true"></i> Gestion de Trabajadores</li>
          <li><a href="index.php?c=Empleado">Registro de Empleados/Funcionarios <i class="fa fa-hand-pointer-o" aria-hidden="true"></i></a></li>
          <li><a href="index.php?c=Oficina">Registro de Oficinas <i class="fa fa-angellist" aria-hidden="true"></i></a></li>
          <li><a href="index.php?c=Departamento">Registro de Departamentos <i class="fa fa-angellist" aria-hidden="true"></i></a></li>
          <li class="divider"></li>
          <li><i class="fa fa-dropbox" aria-hidden="true"></i> Gestion de Catalogos</li>
          <li><a href="index.php?c=Marca">Registro de Marcas <i class="fa fa-registered" aria-hidden="true"></i></a></li>
          <li><a href="index.php?c=Articulo">Registro de Articulos <i class="fa fa-modx" aria-hidden="true"></i></a></li>
          <li><a href="index.php?c=Proveedor">Registro de Proveedor <i class="fa fa-modx" aria-hidden="true"></i></a></li>
            
          </ul>
        </li>        

        <li><a href="?c=Site&a=Cerrarsesion">Salir <i class="fa fa-power-off padding-left-ten-px red-text"></i></a></li>

      </ul>
    </div><!-- /.navbar-collapse -->
  </div><!-- /.container-fluid -->
</nav>
</div> 
</br>
</br>
<p class="bienvenida"><?php echo "Bienvenido(a): ".$_SESSION['usuario_nombre']; ?>
</br>
<?php 
    //echo "Ultimo acceso: ".$_SESSION['ultimoAcceso']; 
    $fechaGuardada = $_SESSION["ultimoAcceso"];

    echo "  Ultimo acceso: ".date("d-m-Y  H:i:s", strtotime($fechaGuardada));

    $ahora = date("Y-n-j H:i:s");
    $tiempo_transcurrido = (strtotime($ahora)-strtotime($fechaGuardada)); 
    if($tiempo_transcurrido >= 600) {
        //si pasaron 10 minutos o más
        require_once 'model/usuario.php';
        $usu = new Usuario();
        $sal = $usu->logout();
        session_destroy(); // destruyo la sesión
        header("Location: index.php"); //envío al usuario a la pag. de autenticación
        //sino, actualizo la fecha de la sesión
    }else {
        $_SESSION["ultimoAcceso"] = $ahora;
   } 
?>
</p>
</br>
</br>
 <p> 
<img src="assets/img/collage1.jpg" align="center"> Descripcion del sistema.......
</p>

</body>
</html>
