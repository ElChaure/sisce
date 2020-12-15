
<?php
   include ("include/funciones.php");
   require_once 'model/equipo.php';
   require_once 'model/equipo_disponible.php';
   $equ = new Equipo();
   $eqdisp = new Equipo_disponible();
?>
<ol class="breadcrumb">
  <a class="btn btn-warning" href="?c=solicitud&a=index">Regresar</a>
</ol>

<h1 class="page-header">Detalle Solicitud <?php echo $_REQUEST['id_solicitud']; ?></h1>

<h1 class="page-header">
    <?php echo $soldet->id_solicitud_detalle != null ? $soldet->id_solicitud_detalle : 'Nuevo Equipo Solicitado'; ?>
</h1>

<ol class="breadcrumb">
  <li><a href="?c=Solicitud_detalle">Detalle Solicitud</a></li>
  <li class="active"><?php echo $soldet->id_solicitud_detalle != null ? $soldet->id_solicitud_detalle : 'Nuevo Registro'; ?></li>
</ol>

<form id="frm-alumno" action="?c=Solicitud_detalle&a=Guardar" method="post" enctype="multipart/form-data">
    <input type="hidden" name="id_solicitud_detalle" value="<?php echo $soldet->id_solicitud_detalle; ?>" />

    <input type="hidden" name="id_solicitud" value="<?php echo $_REQUEST['id_solicitud']; ?>" />
    
    <div class="form-group">
        <label>Equipo a Solicitar o Solicitado</label>

        <select id="id_equipo" name="id_equipo" class="form-control" required>
          <?php if ($soldet->id_equipo != null) {
            echo '<option selected="selected" value="'.$soldet->id_equipo.'">'.
            $desc_emp.'</option>';
          } ?>

        </select>


           

    </div>

 
    <hr />
    
    <div class="text-right">
        <button class="btn btn-success">Guardar</button>
    </div>
</form>
<script>

var equiArray  =  <?php echo $eqdisp->Listar_json();?>;


$("#id_equipo").select2({
      theme: "bootstrap",
      debug: true,
      language: "es",
      //minimumResultsForSearch: Infinity,
       
      placeholder: {
         id: '-1', // the value of the option
         text: 'Indique Equipo'
      },      
      allowClear: true,
      dataType: 'json',
      data: equiArray
});

</script>  

