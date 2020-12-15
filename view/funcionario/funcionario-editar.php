<?php
   include ("include/funciones.php");
   require_once 'model/oficina.php';
   $ofic = new Oficina();
?>


<h1 class="page-header">
    <?php echo $fun->id_funcionario != null ? $fun->id_funcionario : 'Nuevo Registro'; ?>
</h1>

<ol class="breadcrumb">
  <li><a href="?c=Funcionario">Funcionarios</a></li>
  <li class="active"><?php echo $fun->id_funcionario != null ? $fun->id_funcionario : 'Nuevo Registro'; ?></li>
</ol>

<form id="frm-alumno" action="?c=Funcionario&a=Guardar" method="post" enctype="multipart/form-data">
    <input type="hidden" name="id_funcionario" value="<?php echo $fun->id_funcionario; ?>" />
    

    <div class="form-group">
        <label>Cedula</label>
        <input type="text" name="cedula" value="<?php echo $fun->cedula; ?>" class="form-control" placeholder="Ingrese Cedula del Funcionario" data-validacion-tipo="requerido|min:3" />
    </div>
    
    <div class="form-group">
        <label>Nombres</label>
        <input type="text" name="nombre" value="<?php echo $fun->nombre; ?>" class="form-control" placeholder="Ingrese Nombres del Funcionario" data-validacion-tipo="requerido|min:10" />
    </div>
    
    <div class="form-group">
        <label>Apellidos</label>
        <input type="text" name="apellido" value="<?php echo $fun->apellido; ?>" class="form-control" placeholder="Ingrese Apellidos del Funcionario" data-validacion-tipo="requerido|min:10" />
    </div>
    
    <div class="form-group">
        <label>Telefono</label>
        <input type="text" name="telefono" value="<?php echo $fun->telefono; ?>" class="form-control" placeholder="Ingrese Telefono" data-validacion-tipo="requerido|min:10" />
    </div>

    <div class="form-group">
        <label>Email</label>
        <input type="text" name="email" value="<?php echo $fun->email; ?>" class="form-control" placeholder="Ingrese Email del Funcionario" data-validacion-tipo="requerido|min:10" />
    </div>

    <div class="form-group">
        <label>Oficina</label>
        <select id="id_oficina" name="id_oficina" style="width:200px;" title="Ingrese Oficina de Adscripcion.">
           <option value="1"><-- Seleccione --></option>
           <?php $l=make_combo($ofic,"id_oficina","nombre_oficina","",0);?>
       </select>
   </div>

    <div class="form-group">
        <label>Cargo</label>
        <input type="text" name="cargo" value="<?php echo $fun->cargo; ?>" class="form-control" placeholder="Ingrese Cargo del Funcionario" data-validacion-tipo="requerido|min:10" />
    </div>

    
    <hr />
    
    <div class="text-right">
        <button class="btn btn-success">Guardar</button>
    </div>
</form>

<script>
    $(document).ready(function(){
        $("#frm-usuario").submit(function(){
            return $(this).validate();
        });
    })
</script>