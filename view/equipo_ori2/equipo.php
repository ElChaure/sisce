
  <?php include("modal_agregar.php");?>
  <?php include("modal_modificar.php");?>
  <?php include("modal_eliminar.php");?>
<ol class="breadcrumb">
  <a class="btn btn-warning" href="?c=site&a=index">Inicio</a>
</ol>
    <div class="container-fluid">
	 
		<div class='col-xs-6'>	
			<h3> Listado de Equipos (Bienes)</h3>
		</div>
		<div class='col-xs-6'>
			<h3 class='text-right'>		
				<button type="button" class="btn btn-default" data-toggle="modal" data-target="#dataRegister"><i class='glyphicon glyphicon-plus'></i> Agregar Equipo o Bien</button>
			</h3>
		</div>	
		
	  <div class="row">
		<div class="col-xs-12">
		<div id="loader" class="text-center"> <img src="assets/img/loader.gif"></div>
		<div class="datos_ajax_delete"></div><!-- Datos ajax Final -->
		<div class="outer_div"></div><!-- Datos ajax Final -->
		</div>
	  </div>
	</div>
	
	<script src="assets/js/equipo.js"></script>
	<script>
		$(document).ready(function(){
			load(1);
		});
	</script>
 </body>
</html>

