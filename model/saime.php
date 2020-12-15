<?php
session_start();
class Saime
{
	private $pdo;

	public $letra;
	public $numcedula;
	public $paisorigen;
	public $nacionalidad;
	public $primernombre;
	public $segundonombre;
	public $primerapellido;
	public $segundoapellido;
	public $fechanac;
	public $fechacedorg;
	public $codobjecion;
	public $codoficina;
	public $codestadocivil;
	public $naturalizado;
	public $sexo;



	public function __CONSTRUCT()
	{
		try
		{
			$this->pdo = Database::StartUp_saime();     
		}
		catch(Exception $e)
		{
			die($e->getMessage());
		}
	}

	public function Listar()
	{
		try
		{
			$result = array();

			$stm = $this->pdo->prepare("SELECT * FROM datos_personas_v   ORDER BY numcedula");
			$stm->execute();

			return $stm->fetchAll(PDO::FETCH_OBJ);
		}
		catch(Exception $e)
		{
			die($e->getMessage());
		}
	}

	public function Obtener($id)
	{
		try 
		{
		
            require_once 'model/empleado.php';
            $emp = new Empleado();
            $origen=$emp->Obtener_cedula($id);
            $ced_emp = $origen->id_empleado;
            $id_empexist = 0;

            if ($ced_emp != NULL){
            	$id_empexist=$ced_emp;
            }
             
			$stm = $this->pdo
			          ->prepare("SELECT letra, numcedula, paisorigen, nacionalidad, primernombre, segundonombre, primerapellido, segundoapellido, fechanac, fechacedorg, codobjecion, codoficina, codestadocivil, naturalizado, sexo, ".$id_empexist." AS id_empexist 
			          	FROM datos_personas_v WHERE numcedula = ?");
			$stm->execute(array($id));

			$data = $stm->fetch(PDO::FETCH_OBJ);
            $data = json_encode($data);
            echo $data;
            return $data;
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}


	public function Listar_json()
	{
		try
		{
		$stmt = $this->pdo->query("
			SELECT numcedula AS id,primerapellido||' '||primernombre AS text FROM datos_personas_v  ORDER BY id");		
		$data = [];
		$data[] = [
            'id' => -1,
            'text' => ''
        ];
        while ($row = $stmt->fetch(\PDO::FETCH_ASSOC)) {
            $data[] = [
                'id' => $row['id'],
                'text' => $row['text']
            ];
        }
        $data = json_encode($data);
        return $data;
		}
		catch(Exception $e)
		{
			die($e->getMessage());
		}
	}


}