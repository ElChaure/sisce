<?php
session_start();
class Estatus_empleado
{
	private $pdo;

	public $id_estatus;
	public $estatus;
	

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

			$stm = $this->pdo->prepare("SELECT * FROM estatus_empleado  WHERE active IS NOT FALSE ORDER BY id_estatus");
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
			          ->prepare("SELECT * FROM estatus_empleado WHERE id_estatus = ?");
			          

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
			            ->prepare("UPDATE estatus_empleado 
			            	       SET active=FALSE, 
			            	       fecha_elim=NOW(), 
			            	       usr_id=".$_SESSION['uid']." WHERE id_estatus = ?");

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
			$sql = "UPDATE estatus_empleado SET 
					estatus=?
				    WHERE id_estatus = ?";

			$this->pdo->prepare($sql)
			     ->execute(
				    array(
                        $data->estatus,
                        $data->id_estatus
					)
				);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}

	public function Registrar(estatus_empleado $data)
	{
		try 
		{
		$sql = "INSERT INTO estatus_empleado(id_estatus, estatus)
    			VALUES (?, ?)";

		$this->pdo->prepare($sql)
		     ->execute(
				array(
                        $data->id_estatus, 
                        $data->estatus
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
			SELECT id_estatus AS id,estatus AS text FROM estatus_empleado ORDER BY id");		
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