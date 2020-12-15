<?php
session_start();
class Ubicacion
{
	private $pdo;

	public $id_ubicacion;
	public $ubicacion;
	//public $id_equipo;


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

			$stm = $this->pdo->prepare("SELECT * FROM ubicacion_v2  WHERE active IS NOT FALSE ORDER BY id_ubicacion");
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
			          ->prepare("SELECT * FROM ubicacion_v2 WHERE id_ubicacion = ?");
			          

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
			            ->prepare("UPDATE ubicacion_v2 
			            	       SET active=FALSE, 
			            	       fecha_elim=NOW(), 
			            	       usr_id=".$_SESSION['uid']." WHERE id_ubicacion = ?");            			          
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
			$sql = "UPDATE ubicacion_v2 SET 
					ubicacion=?,
					//id_equipo=?
				    WHERE id_ubicacion = ?";

			$this->pdo->prepare($sql)
			     ->execute(
				    array(
                        $data->ubicacion,
                        $data->id_equipo,
						$data->id_ubicacion
					)
				);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}

	public function Registrar(ubicacion $data)
	{
		try 
		{
		$sql = "INSERT INTO ubicacion_v2(ubicacion, id_equipo)
    			VALUES (?, ?)";

		$this->pdo->prepare($sql)
		     ->execute(
				array(
						//$data->id_ubicacion,
                        $data->ubicacion
                        //$data->id_equipo
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
			SELECT id_ubicacion AS id,ubicacion AS text FROM ubicacion_v2 WHERE active IS NOT FALSE  AND id_ubicacion > 1 ORDER BY id");		
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
