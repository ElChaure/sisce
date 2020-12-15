<?php
session_start();
class Estado
{
	private $pdo;

	public $id_estado;
	public $nombre_estado;
	

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

			$stm = $this->pdo->prepare("SELECT * FROM estado  WHERE active IS NOT FALSE ORDER BY id_estado");
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
			          ->prepare("SELECT * FROM estado WHERE id_estado = ?");
			          

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
			            ->prepare("UPDATE estado 
			            	       SET active=FALSE, 
			            	       fecha_elim=NOW(), 
			            	       usr_id=".$_SESSION['uid']." WHERE id_estado = ?");

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
			$sql = "UPDATE estado SET 
					nombre_estado=?
				    WHERE id_estado = ?";

			$this->pdo->prepare($sql)
			     ->execute(
				    array(
                        $data->nombre_estado,
						$data->id_estado
					)
				);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}

	public function Registrar(estado $data)
	{
		try 
		{
		$sql = "INSERT INTO estado(id_estado, nombre_estado)
    			VALUES (?, ?)";

		$this->pdo->prepare($sql)
		     ->execute(
				array(
                        $data->id_estado, 
                        $data->nombre_estado
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
		$stmt = $this->pdo->query("SELECT id_estado AS id,nombre_estado AS text FROM estado   ORDER BY id_estado");		
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