<?php
    require('fechaesp.php');
    $miFecha=date('d-m-Y H:i:s');
?>
            <div class="row">
                <div class="col-xs-12">
                    <hr />
                    <footer class="text-center well">
                        <p>Sistema de Control de Equipos Telematicos | <?php echo fechaCastellano($miFecha); ?></p>
                    </footer>                
                </div>    
            </div>
        </div>
<!--
        <script src="assets/js/jquery.js"></script>
        <script src="assets/js/bootstrap.min.js"></script>
        <script src="assets/js/jquery-ui/jquery-ui.min.js"></script>
        <script src="assets/js/ini.js"></script>
        <script src="assets/js/jquery.anexsoft-validator.js"></script>-->
    </body>
</html>