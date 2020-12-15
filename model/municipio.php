<?php
session_start();
class Municipio
{
	private $pdo;

	public $id_municipio;
	public $nombre_municipio;
	public $id_estado;



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

			$stm = $this->pdo->prepare("SELECT * FROM municipio  WHERE active IS NOT FALSE ORDER BY id_municipio");
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
			          ->prepare("SELECT * FROM municipio WHERE id_municipio = ?");
			          

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
			            ->prepare("UPDATE municipio 
			            	       SET active=FALSE, 
			            	       fecha_elim=NOW(), 
			            	       usr_id=".$_SESSION['uid']." WHERE id_municipio = ?");

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
			$sql = "UPDATE municipio SET nombre_municipio=?, id_estado=?
				    WHERE id_municipio = ?";

			$this->pdo->prepare($sql)
			     ->execute(
				    array(
						$data->nombre_municipio, 
						$data->id_estado,
                        $data->id_municipio
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
		$sql = "INSERT INTO marca(id_municipio, nombre_municipio, id_estado)
    			VALUES (?, ?, ?, ?)";

		$this->pdo->prepare($sql)
		     ->execute(
				array(
						$data->id_municipio,
						$data->nombre_municipio, 
						$data->id_estado
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
		$stmt = $this->pdo->query("SELECT id_municipio AS id,nombre_municipio AS text, id_estado FROM municipio ORDER BY id_municipio");		
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