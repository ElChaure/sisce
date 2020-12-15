
<?php
   include ("include/funciones.php");
   //require_once 'model/equipo.php';
  require_once 'model/funcionario_activo.php';
  require_once 'model/empleado.php'; 
  require_once 'model/tipo_solicitud.php'; 
  require_once 'model/estatus_solicitud.php';   
  require_once 'model/ubicacion.php';
  require_once 'model/oficina.php';
  require_once 'model/departamento.php';

   //$equ = new Equipo();
   $fun = new Funcionario_activo();
   $emp = new Empleado();
   $tsol = new Tipo_solicitud();
   $esol = new Estatus_solicitud();
   $ubica = new Ubicacion();
   $ofic = new Oficina();
   $dept = new Departamento();
?>

<h1 class="page-header">
    <?php echo $sol->id_solicitud != null ? $sol->id_solicitud : 'Nueva Solicitud';?>
    <?php 
     
     if ($sol->id_solicitud != null){
         $o_fun = $fun->Obtener($sol->id_funcionario);
         $o_emp = $emp->Obtener($sol->id_empleado);
         $o_tso = $tsol->Obtener($sol->id_tipo_solicitud);
         $o_ubi = $ubica->Obtener($sol->id_ubicacion);
         $o_ofi = $ofic->Obtener($sol->id_oficina);
         $o_dep = $dept->Obtener($sol->id_departamento);
         $desc_fun  = $o_fun->nombres;
         $desc_emp  = $o_emp->nombres;   
         $desc_tso  = $o_tso->descripcion;
         $desc_ubi  = $o_ubi->ubicacion;
         $desc_ofi  = $o_ofi->nombre_oficina;
         $desc_dep  = $o_dep->nombre;
         
  }
  ?>
</h1>

<ol class="breadcrumb">
  <li><a href="?c=Solicitud">Solicitudes</a></li>
  <li class="active"><?php echo $sol->id_solicitud != null ? $sol->id_solicitud : 'Nuevo Registro'; ?>
    
  </li>
</ol>
<?php //$sol->id_solicitud != null ? $id_funcionario=$sol->id_funcionario : $id_funcionario=$_SESSION['id_funcionario']; ?>
<form id="frm-alumno" action="?c=Solicitud&a=Guardar" method="post" enctype="multipart/form-data">
    <input type="hidden" name="id_solicitud" value="<?php echo $sol->id_solicitud; ?>" />
    <!--input type="hidden" name="id_funcionario" value="<?php echo $sol->id_solicitud; ?>" /-->

    <!--div class="form-group">
        <label>Funcionario que crea la Solicitud</label>
        <select id="id_funcionario_inutilizado" name="id_funcionario" class="form-control"></select>
    </div-->    

    <div class="form-group">
        <label>Funcionario Solicitante</label>
        <select id="id_empleado" name="id_empleado" class="form-control" required>
          <?php if ($sol->id_empleado != null) {
            echo '<option selected="selected" value="'.$sol->id_empleado.'">'.
            $desc_emp.'</option>';
          } ?>

        </select>
    </div>



     <div class="form-group">
        <label>Descripcion de la Solicitud</label>
        <input type="text" name="descripcion" value="<?php echo $sol->descripcion; ?>" class="form-control" placeholder="Ingrese Descripcion de la Solicitud" maxlength="100" required>
    </div>
    
    
    <div class="form-group">
        <label>Fecha de Solicitud</label>
        <input id="fecha_solicitud" type="text" name="fecha_solicitud" value="<?php echo $sol->fecha_solicitud; ?>" class="form-control" placeholder="Ingrese Fecha de Solicitud" required>
    </div>

    <div class="form-group">
        <label>Tipo de Solicitud</label>
        <select id="id_tipo_solicitud" name="id_tipo_solicitud" class="form-control" required>
         <?php if ($sol->id_tipo_solicitud != null) {
            echo '<option selected="selected" value="'.$sol->id_tipo_solicitud.'">'.
            $desc_tso.'</option>';
          } ?> 

        </select>
    </div>
    

  
    <div class="form-group">
        <label>Ubicacion de los Equipos/Bienes Solicitados</label>
        <select id="id_ubicacion" name="id_ubicacion" class="form-control" required>
          <?php if ($sol->id_ubicacion != null) {
            echo '<option selected="selected" value="'.$sol->id_ubicacion.'">'.
            $desc_ubi.'</option>';
          } ?> 
        </select>
    </div>

    <div class="form-group" id="departamento_form" style="display:none;">
        <label>Departamento de Ubicacion de los Equipos/Bienes Solicitados</label>
        <select id="id_departamento" name="id_departamento" class="form-control">
          <?php if ($sol->id_departamento != null) {
            echo '<option selected="selected" value="'.$sol->id_departamento.'">'.
            $desc_dep.'</option>';
          } ?> 
        </select>
    </div>

    <div class="form-group" id="oficina_form" style="display:none;">
        <label>Oficina de Ubicacion de los Equipos/Bienes Solicitados</label>
        <select id="id_oficina" name="id_oficina" class="form-control">
          <?php if ($sol->id_oficina != null) {
            echo '<option selected="selected" value="'.$sol->id_oficina.'">'.
            $desc_ofi.'</option>';
          } ?> 
        </select>
    </div>   




  <!--div class="form-group">
        <label>Estatus de la Solicitud</label>

       <select id="id_estatus_solicitud" name="id_estatus_solicitud" style="width:200px;" title="Ingrese Estatus de la Solicitud.">
           <option value="1">< Seleccione ></option>
           <?php $l=make_combo($esol,"id_estatus_solicitud","descripcion","",0);?>
       </select>

    </div-->


  
    <hr />
    
    <div class="text-right">
        <button class="btn btn-success">Guardar</button>

    </div>
</form>

<script>
jQuery(document).ready(function() {
       jQuery('#id_funcionariox').select2({
placeholder: "Indique Funcionario",
//width: 'auto',
allowClear: true
});
})



  /*
    $(document).ready(function(){
        $("#frm-usuario").submit(function(){
            return $(this).validate();
        });
    })
*/
var funArray  =  <?php echo $fun->Listar_json();?>;
var empArray  =  <?php echo $emp->Listar_json();?>;
var tipsoArray=  <?php echo $tsol->Listar_json();?>;
var ubicaArray = <?php echo $ubica->Listar_json();?>;
var oficArray =  <?php echo $ofic->Listar_json();?>;
var deptArray =  <?php echo $dept->Listar_json();?>;

$("#id_funcionario").select2({
      theme: "bootstrap",
      debug: true,
      language: "es",
      //minimumResultsForSearch: Infinity,
      placeholder: {
                id: '-1', // the value of the option
             text: 'Indique Funcionario'
       },       
      allowClear: true,
      dataType: 'json',
      data: funArray
});

$("#id_empleado").select2({
      theme: "bootstrap",
      debug: true,
      language: "es",
      //minimumResultsForSearch: Infinity,
      placeholder: {
                id: '-1', // the value of the option
             text: 'Indique Empleado Solicitante'
       },      
      allowClear: true,
      dataType: 'json',
      data: empArray
});


$("#id_tipo_solicitud").select2({
      theme: "bootstrap",
      debug: true,
      language: "es",
      //minimumResultsForSearch: Infinity,
      placeholder: {
                id: '-1', // the value of the option
             text: 'Indiquel Tipo de Solicitud'
       },       
      allowClear: true,
      dataType: 'json',
      data: tipsoArray
});

$("#id_ubicacion").select2({
      theme: "bootstrap",
      debug: true,
      language: "es",
      //minimumResultsForSearch: Infinity,
      placeholder: {
                id: '-1', // the value of the option
                text: 'Indiquel la Ubicacion'
       },       

      allowClear: true, 
      dataType: 'json',
      data: ubicaArray
});
$("#id_oficina").select2({
      theme: "bootstrap",
      debug: true,
      language: "es",
      //minimumResultsForSearch: Infinity,
      
      placeholder: {
                id: '-1', // the value of the option
                text: 'Indique la Oficina de Ubicacion'
       },       

      allowClear: true, 
      dataType: 'json',
      data: oficArray
});
$("#id_departamento").select2({
      theme: "bootstrap",
      debug: true,
      language: "es",
      //minimumResultsForSearch: Infinity,
      //placeholder: 'Indique el Departamento de Ubicacion',
      placeholder: {
         id: '-1', // the value of the option
         text: 'Indique el Departamento de Ubicacion'
      }, 
      allowClear: true,
      dataType: 'json',
      data: deptArray
});


$(function(){
    $("#fecha_solicitud").datepicker({
        dateFormat: 'dd/mm/yy',
        changeMonth: true,
        changeYear: true,
        maxDate: '0',
        dayNamesMin: ['Do', 'Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sa'],
        monthNames: ['Enero','FOficina de ebrero','Martes','Abril','Mayo','Junio','Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre']
      });
});


$('#id_ubicacionx').on("change", function(e) { 
   //var value = e.params.data; Using {id,text} format
   //alert();
   var data = e.params.data;
   console.log(data);
   alert(data);

});


$('#id_ubicacion').on("change", function(e) {
    var destino=$('#id_ubicacion').select2('data')[0].id;
    if (destino == 2) {
      $('#departamento_form').hide();
      $('#oficina_form').show();
     } else {
      $('#departamento_form').show();
      $('#oficina_form').hide();
    }
    //alert(destino);
    
}); 

</script>  