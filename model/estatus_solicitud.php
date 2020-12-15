<?php
session_start();
class Estatus_solicitud
{
	private $pdo;

	public $id_estatus_solicitud;
	public $descripcion;
	

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

			$stm = $this->pdo->prepare("SELECT * FROM estatus_solicitud  WHERE active IS NOT FALSE ORDER BY id_estatus_solicitud");
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
			          ->prepare("SELECT * FROM estatus_solicitud WHERE id_estatus_solicitud = ?");
			          

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
			            ->prepare("UPDATE estatus_solicitud 
			            	       SET active=FALSE, 
			            	       fecha_elim=NOW(), 
			            	       usr_id=".$_SESSION['uid']." WHERE id_estatus_solicitud = ?");

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
			$sql = "UPDATE estatus_solicitud SET 
					descripcion=?
				    WHERE id_estatus_solicitud = ?";

			$this->pdo->prepare($sql)
			     ->execute(
				    array(
                        $data->descripcion,
                        $data->id_estatus_solicitud
					)
				);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}

	public function Registrar(estatus_solicitud $data)
	{
		try 
		{
		$sql = "INSERT INTO estatus_solicitud(descripcion)
    			VALUES (?)";

		$this->pdo->prepare($sql)
		     ->execute(
				array(
                        //$data->id_estatus_solicitud, 
                        $data->descripcion
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
		$stmt = $this->pdo->query("
			SELECT -1 AS id, NULL as text
            UNION 
			SELECT id_estatus_solicitud AS id,descripcion AS text FROM estatus_solicitud ORDER BY id");		
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