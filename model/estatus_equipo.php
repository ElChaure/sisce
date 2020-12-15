<?php
session_start();
class Estatus_equipo
{
	private $pdo;

	public $id_estatus_eq;
	//public $id_equipo;
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

			$stm = $this->pdo->prepare("SELECT * FROM estatus_equipo_v2  WHERE active IS NOT FALSE ORDER BY id_estatus_eq");
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
			          ->prepare("SELECT * FROM estatus_equipo_v2 WHERE id_estatus_eq = ?");
			          

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
			            ->prepare("UPDATE estatus_equipo_v2 
			            	       SET active=FALSE, 
			            	       fecha_elim=NOW(), 
			            	       usr_id=".$_SESSION['uid']." WHERE id_estatus_eq = ?");

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
			$sql = "UPDATE estatus_equipo_v2 SET estatus=?
				    WHERE id_estatus_eq = ?";

			$this->pdo->prepare($sql)
			     ->execute(
				    array(
                        //$data->id_equipo,
                        $data->estatus,
                        $data->id_estatus_eq 
					)
				);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}

	public function Registrar(estatus_equipo $data)
	{
		try 
		{
		$sql = "INSERT INTO estatus_equipo_v2(estatus)
    			VALUES (?)";

		$this->pdo->prepare($sql)
		     ->execute(
				array(
                        //$data->id_estatus_eq, 
                        //$data->id_equipo,
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
			SELECT id_estatus_eq AS id,estatus AS text FROM estatus_equipo_v2 ORDER BY id");		
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
