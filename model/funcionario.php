<?php
session_start();
class Funcionario
{
	private $pdo;

	public $id_funcionario;
	public $id_oficina;
	public $nombre;
	public $apellido;
	public $cedula;
	public $telefono;
	public $email;
	public $cargo;



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

			$stm = $this->pdo->prepare("SELECT * FROM funcionario  WHERE active IS NOT FALSE ORDER BY id_funcionario");
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
			          ->prepare("SELECT * FROM funcionario WHERE id_funcionario = ?");
			          

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
			            ->prepare("UPDATE funcionario 
			            	       SET active=FALSE, 
			            	       fecha_elim=NOW(), 
			            	       usr_id=".$_SESSION['uid']." WHERE id_funcionario = ?");

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
			$sql = "UPDATE funcionario SET id_oficina=?, nombre=?, apellido=?, cedula=?, telefono=?, email=?, cargo=?
				    WHERE id_funcionario = ?";

			$this->pdo->prepare($sql)
			     ->execute(
				    array(
                        $data->id_oficina,
                        $data->nombre,
                        $data->apellido,
                        $data->cedula,
                        $data->telefono,
                        $data->email,
                        $data->cargo,
                        $data->id_funcionario
					)
				);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}

	public function Registrar(funcionario $data)
	{
		try 
		{
		$sql = "INSERT INTO funcionario(id_oficina, nombre, apellido, cedula, telefono,email, cargo)
				VALUES (?, ?, ?, ?, ?, ?, ?, ?)";

		$this->pdo->prepare($sql)
		     ->execute(
				array(
                        $data->id_oficina,
                        $data->nombre,
                        $data->apellido,
                        $data->cedula,
                        $data->telefono,
                        $data->email,
                        $data->cargo
                    )
			);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}
}