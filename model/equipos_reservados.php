<?php
session_start();
class Equipos_reservados
{
	private $pdo;

	public $id_equipo; 
	public $cod_equipo; 
	public $serial; 
	public $estatus; 
	public $ubicacion; 
	public $num_bien_nac; 
	public $descripcion;
	public $num_factura; 
	public $fecha_factura; 
	public $valor;
	public $nombre_oficina; 
	public $nombre;
	public $id_estatus; 
	public $id_ubicacion;
	public $id_solicitud_detalle_reserva;

	

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

			$stm = $this->pdo->prepare("SELECT * FROM equipos_reservados ORDER BY id_equipo");
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
			$stm = $this->pdo
			          ->prepare("SELECT * FROM equipos_reservados WHERE id_equipo = ?");
			          

			$stm->execute(array($id));
			return $stm->fetch(PDO::FETCH_OBJ);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}


	public function Devolver($id)
	{
		try 
		{
			$stm = $this->pdo
			          ->prepare("SELECT * FROM equipos_reservados WHERE id_equipo = ?");
			          

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
			SELECT -1 AS id, NULL as text
            UNION 
			SELECT id_equipo AS id,descripcion AS text FROM equipos_reservados ORDER BY id");		
		$data = $stmt->fetchAll(PDO::FETCH_ASSOC);
		$data = json_encode($data);
        return $data;
		}
		catch(Exception $e)
		{
			die($e->getMessage());
		}
	}


}
