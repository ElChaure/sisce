<?php
session_start();
class Permissions
{
	private $pdo;

    public $perm_id;
	public $perm_desc;
	public $accion;
	public $pages;
	public $item_per_page;

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
			//Preparacion de Paginacion
			$item_per_page=12;
			$results = $this->pdo->prepare("SELECT COUNT(*) FROM permissions");
			$results->execute();
			$get_total_rows = $results->fetch();

			//breaking total records into pages
			$pages = ceil($get_total_rows[0]/$item_per_page); 
         
            $_SESSION['totreg'] = $get_total_rows[0];
            $_SESSION['totpag'] = $pages[0];

			$result = array();

			$stm = $this->pdo->prepare("SELECT * FROM permissions  WHERE active IS NOT FALSE ORDER BY perm_id");
			$stm->execute();

			return $stm->fetchAll(PDO::FETCH_OBJ);
		}
		catch(Exception $e)
		{
			die($e->getMessage());
		}
	}

	public function Obtener($perm_id)
	{
		try 
		{
			$stm = $this->pdo
			          ->prepare("SELECT * FROM permissions WHERE perm_id = ?");
			          

			$stm->execute(array($perm_id));
			return $stm->fetch(PDO::FETCH_OBJ);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}

	public function Eliminar($perm_id)
	{
		try 
		{
			

          $stm = $this->pdo
			            ->prepare("UPDATE permissions 
			            	       SET active=FALSE, 
			            	       fecha_elim=NOW(), 
			            	       usr_id=".$_SESSION['uid']." WHERE perm_id = ?");

			$stm->execute(array($perm_id));
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}

	public function Actualizar($data)
	{
		
		
		try 
		{
			$sql = "UPDATE permissions SET 
					perm_desc=?, 
					accion=? 
				    WHERE perm_id = ?";

			$this->pdo->prepare($sql)
			     ->execute(
				    array(
                        $data->perm_desc,
                        $data->accion,
                        $data->perm_id
					)
				);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}

	public function Registrar(permissions $data)
	{
		try 
		{
		$sql = "INSERT INTO permissions(perm_desc, accion)
    			VALUES (?, ?)";

		$this->pdo->prepare($sql)
		     ->execute(
				array(
                        //$data->perm_id_permissions, 
                        $data->perm_desc,
                        $data->accion
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
			SELECT perm_id AS id,perm_desc||' Accion: '||accion AS text FROM permissions WHERE active IS NOT FALSE ORDER BY id");		
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