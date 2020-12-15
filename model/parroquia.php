<?php
session_start();
class Parroquia
{
	private $pdo;

	public $id_parroquia;
	public $nombre_parroquia;
	public $id_municipio;


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

			$stm = $this->pdo->prepare("SELECT * FROM parroquia  WHERE active IS NOT FALSE ORDER BY id_parroquia");
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
			          ->prepare("SELECT * FROM parroquia WHERE id_parroquia = ?");
			          

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
			            ->prepare("UPDATE parroquia 
			            	       SET active=FALSE, 
			            	       fecha_elim=NOW(), 
			            	       usr_id=".$_SESSION['uid']." WHERE id_parroquia = ?");

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
			$sql = "UPDATE parroquia SET nombre_parroquia=?, id_municipio=?
				    WHERE id_parroquia = ?";

			$this->pdo->prepare($sql)
			     ->execute(
				    array(
						$data->nombre_parroquia, 
						$data->id_municipio,
                        $data->id_parroquia
					)
				);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}

	public function Registrar(marca $data)
	{
		try 
		{
		$sql = "INSERT INTO marca(id_parroquia, nombre_parroquia, id_municipio)
    			VALUES (?, ?, ?, ?)";

		$this->pdo->prepare($sql)
		     ->execute(
				array(
						$data->id_parroquia,
						$data->nombre_parroquia, 
						$data->id_municipio
                        
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
		$stmt = $this->pdo->query("SELECT id_parroquia AS id,nombre_parroquia AS text, id_municipio FROM parroquia ORDER BY id_parroquia");		
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