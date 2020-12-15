<?php
session_start();
class Oficina
{
	private $pdo;

	public $id_oficina;
	public $nombre_oficina;
	public $direccion;
	public $codigo;
	public $telefono;
	public $id_parroquia;
	

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

			$stm = $this->pdo->prepare("SELECT * FROM oficina  WHERE active IS NOT FALSE ORDER BY id_oficina");
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
			          ->prepare("SELECT * FROM oficina WHERE id_oficina = ?");
			          

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
			            ->prepare("UPDATE oficina 
			            	       SET active=FALSE, 
			            	       fecha_elim=NOW(), 
			            	       usr_id=".$_SESSION['uid']." WHERE id_oficina = ?");

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
			$sql = "UPDATE oficina 
			        SET nombre_oficina=?, direccion=?, telefono=?, id_parroquia=?
				    WHERE id_oficina = ?";

			$this->pdo->prepare($sql)
			     ->execute(
				    array(
                        $data->nombre_oficina,
                        $data->direccion, 
                        $data->telefono, 
                        $data->id_parroquia,
						$data->id_oficina
					)
				);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}
 
	public function Registrar(oficina $data)
	{
		try 
		{
		$sql = "INSERT INTO oficina(nombre_oficina, direccion, telefono, id_parroquia)
    			VALUES (?, ?, ?, ?)";

		$this->pdo->prepare($sql)
		     ->execute(
				array(
                        $data->nombre_oficina,
                        $data->direccion, 
                        $data->telefono, 
                        $data->id_parroquia
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
		$stmt = $this->pdo->query("SELECT id_oficina AS id,nombre_oficina||' - '||codigo AS text FROM oficina ORDER BY id");		
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