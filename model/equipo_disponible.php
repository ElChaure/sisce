<?php
session_start();
class Equipo_disponible
{
	private $pdo;

	public $id_equipo;
	public $cod_equipo;
	public $serial;
	public $id_estatus;
	public $id_ubicacion;
	public $num_bien_nac;
	public $descripcion;
	public $num_factura;
	public $fecha_factura;
	public $id_proveedor;
    public $valor;


	public function __CONSTRUCT()
	{
		try
		{
			$this->pdo = Database::StartUp();     
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

			$stm = $this->pdo->prepare("SELECT * FROM equipos_disponibles");
			$stm->execute();

			return $stm->fetchAll(PDO::FETCH_OBJ);
		}
		catch(Exception $e)
		{
			die($e->getMessage());
		}
	}

        public function Contar()
	{
		try
		{
			$result = array();

			$stmt1= $this->pdo->query("SELECT count(id_equipo) FROM equipo_disponible WHERE active IS NOT FALSE");
                        $totalRecords = (int) $stmt1->fetchColumn(); 

			return $totalRecords;
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
			$stm = $this->pdo
			          ->prepare("SELECT * FROM equipo_disponible WHERE id_equipo = ?");
			          

			$stm->execute(array($id));
			return $stm->fetch(PDO::FETCH_OBJ);
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
		SELECT id_equipo AS id,descripcion AS text FROM equipos_disponibles
		ORDER BY id");		
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
