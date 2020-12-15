<?php
session_start();
class Role_perm
{
	private $pdo;

    public $id;
	public $perm_id;
	public $role_id;
	


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

			$stm = $this->pdo->prepare("SELECT * FROM roles_permisos  WHERE active IS NOT FALSE ORDER BY id");
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
			          ->prepare("SELECT * FROM role_perm WHERE id = ?");
			          

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
			            ->prepare("UPDATE role_perm 
			            	       SET active=FALSE, 
			            	       fecha_elim=NOW(), 
			            	       usr_id=".$_SESSION['uid']." WHERE id = ?");			            		          

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
			$sql = "UPDATE role_perm SET 
					perm_id=?, 
					role_id=? 
				    WHERE id = ?";

			$this->pdo->prepare($sql)
			     ->execute(
				    array(
                        $data->perm_id,
                        $data->role_id,
                        $data->id
					)
				);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}

	public function Registrar(role_perm $data)
	{
		try 
		{
		$sql = "INSERT INTO role_perm(perm_id, role_id)
    			VALUES (?, ?)";

		$this->pdo->prepare($sql)
		     ->execute(
				array(
                        //$data->id_role_perm, 
                        $data->perm_id,
                        $data->role_id
                      )
			);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}
}