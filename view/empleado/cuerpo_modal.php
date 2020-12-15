                <p class="statusMsg"></p>
                <form role="form">
                    <div class="form-group">
                          
                 <div class="container-fluid">
                    <div class="form-group input-group">
                        <span class="input-group-addon" style="width:150px;">Id:</span>
                        <input type="text" style="width:350px;" class="form-control" value="<?php echo $emp->id_empleado; ?>" readonly>
                    </div> 

                    <div class="form-group input-group">
                        <span class="input-group-addon" style="width:150px;">Cedula:</span>
                        <input type="text" style="width:350px;" class="form-control" value="<?php echo $emp->cedula; ?>" readonly>
                    </div>

                    <div class="form-group input-group">
                        <span class="input-group-addon" style="width:150px;">Primer Nombre:</span>
                        <input type="text" style="width:350px;" class="form-control" value="<?php echo $emp->primer_nombre; ?>" readonly>
                    </div>

                    <div class="form-group input-group">
                        <span class="input-group-addon" style="width:150px;">Segundo Nombre:</span>
                        <input type="text" style="width:350px;" class="form-control" value="<?php echo $emp->segundo_nombre; ?>" readonly>
                    </div>

                    <div class="form-group input-group">
                        <span class="input-group-addon" style="width:150px;">Primer Apellido:</span>
                        <input type="text" style="width:350px;" class="form-control" value="<?php echo $emp->primer_apellido; ?>" readonly>
                    </div>

                    <div class="form-group input-group">
                        <span class="input-group-addon" style="width:150px;">Segundo Apellido:</span>
                        <input type="text" style="width:350px;" class="form-control" value="<?php echo $emp->segundo_apellido; ?>" readonly>
                    </div>                    

                    <div class="form-group input-group">
                        <span class="input-group-addon" style="width:150px;">Dirección:</span>
                        <input type="text" style="width:350px;" class="form-control" value="<?php echo $emp->direccion; ?>" readonly>
                    </div>

                    <div class="form-group input-group">
                        <span class="input-group-addon" style="width:150px;">Email:</span>
                        <input type="text" style="width:350px;" class="form-control" value="<?php echo $emp->email; ?>" readonly>
                    </div>                                                        

                    <div class="form-group input-group">
                        <span class="input-group-addon" style="width:150px;">Departamento:</span>
                        <input type="text" style="width:350px;" class="form-control" value="<?php echo $emp->nombre; ?>" readonly>
                    </div>                  

                    <div class="form-group input-group">
                        <span class="input-group-addon" style="width:150px;">Oficina:</span>
                        <input type="text" style="width:350px;" class="form-control" value="<?php echo $emp->nombre_oficina; ?>" readonly>
                    </div>                  

                    <div class="form-group input-group">
                        <span class="input-group-addon" style="width:150px;">Telefono:</span>
                        <input type="text" style="width:350px;" class="form-control" value="<?php echo $emp->telefono; ?>" readonly>
                    </div>                  

                    <div class="form-group input-group">
                        <span class="input-group-addon" style="width:150px;">Estatus:</span>
                        <input type="text" style="width:350px;" class="form-control" value="<?php echo $emp->estatus; ?>" readonly>
                    </div>                  


                </div>

                    </div>
                    <p><img src="assets/img/loader.gif" id="loaderIcon" style="display:none" /></p>
                </form>