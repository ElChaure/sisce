<?php
session_start();
class User_role
{
	private $pdo;

    public $id;
	public $user_id;
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

			$stm = $this->pdo->prepare("SELECT * FROM user_role  WHERE active IS NOT FALSE ORDER BY id");
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
			          ->prepare("SELECT * FROM user_role WHERE id = ?");
			          

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
			            ->prepare("UPDATE user_role 
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
			$sql = "UPDATE user_role SET 
					user_id=?, 
					role_id=? 
				    WHERE id = ?";

			$this->pdo->prepare($sql)
			     ->execute(
				    array(
                        $data->user_id,
                        $data->role_id,
                        $data->id
					)
				);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}

	public function Registrar(user_role $data)
	{
		try 
		{
		$sql = "INSERT INTO user_role(user_id, role_id)
    			VALUES (?, ?)";

		$this->pdo->prepare($sql)
		     ->execute(
				array(
                        //$data->id_user_role, 
                        $data->user_id,
                        $data->role_id
                      )
			);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}





	
}