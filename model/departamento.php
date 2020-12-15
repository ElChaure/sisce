<?php
session_start();
class Departamento
{
	private $pdo;

	public $id_departamento;
	public $nombre;
	public $telf_departamento;



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

			$stm = $this->pdo->prepare("SELECT * FROM departamento  WHERE active IS NOT FALSE ORDER BY id_departamento");
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
			          ->prepare("SELECT * FROM departamento WHERE id_departamento = ?");
			          

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
			            ->prepare("UPDATE departamento 
			            	       SET active=FALSE, 
			            	       fecha_elim=NOW(), 
			            	       usr_id=".$_SESSION['uid']." WHERE id_departamento = ?");

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
			$sql = "UPDATE departamento
   					SET nombre=?, telf_departamento=?
				    WHERE id_departamento = ?";

			$this->pdo->prepare($sql)
			     ->execute(
				    array(
                        $data->nombre,
                        $data->telf_departamento,
                        $data->id_departamento
					)
				);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}

	public function Registrar(departamento $data)
	{
		try 
		{
		$sql = "INSERT INTO departamento(nombre, telf_departamento)
    			VALUES (?, ?)";

		$this->pdo->prepare($sql)
		     ->execute(
				array(
                        $data->nombre,
                        $data->telf_departamento
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
		$stmt = $this->pdo->query("SELECT id_departamento AS id,nombre AS text FROM departamento  WHERE active IS NOT FALSE ORDER BY nombre");		
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