<?php
session_start();
class Orden_salida
{
	private $pdo;

	public $id_orden;
	public $num_orden;
	public $id_solicitud;
	public $observacion;
	public $id_emp;
	public $id_funcionario;
	public $id_equipo;
	

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

			$stm = $this->pdo->prepare("SELECT * FROM orden_salida  WHERE active IS NOT FALSE ORDER BY id_orden");
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
			          ->prepare("SELECT * FROM orden_salida WHERE id_orden = ?");
			          

			$stm->execute(array($id));
			return $stm->fetch(PDO::FETCH_OBJ);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}

	public function Eliminar($id)
	{
		try 
		{

           $stm = $this->pdo
			            ->prepare("UPDATE orden_salida 
			            	       SET active=FALSE, 
			            	       fecha_elim=NOW(), 
			            	       usr_id=".$_SESSION['uid']." WHERE id_orden = ?");

			$stm->execute(array($id));
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}

	public function Actualizar($data)
	{
		
		
		try 
		{
			$sql = "UPDATE orden_salida 
			        SET num_orden=?, id_solicitud=?, observacion=?, id_emp=?, id_funcionario=?, id_equipo=?
				    WHERE id_orden = ?";

			$this->pdo->prepare($sql)
			     ->execute(
				    array(
                        $data->num_orden, 
                        $data->id_solicitud, 
                        $data->observacion, 
                        $data->id_emp, 
                        $data->id_funcionario, 
                        $data->id_equipo,
						$data->id_orden
					)
				);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}

	public function Registrar(orden_salida $data)
	{
		try 
		{
		$sql = "INSERT INTO orden_salida(num_orden, id_solicitud, observacion, id_emp, id_funcionario, id_equipo)
    			VALUES (?, ?, ?, ?, ?, ?)";

		$this->pdo->prepare($sql)
		     ->execute(
				array(
						//$data->id_orden,					
                        $data->num_orden, 
                        $data->id_solicitud, 
                        $data->observacion, 
                        $data->id_emp, 
                        $data->id_funcionario, 
                        $data->id_equipo
                    )
			);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}

	public function Listar_json()
	{
		try
		{
		$stmt = $this->pdo->query("SELECT id_orden AS id,num_orden AS text FROM oficina ORDER BY id_orden");		
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