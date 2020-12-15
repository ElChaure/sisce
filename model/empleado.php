<?php
session_start();
class Empleado
{
	private $pdo;

	public $id_empleado;
	public $primer_nombre;
	public $segundo_nombre;
	public $primer_apellido;
	public $segundo_apellido;
	public $cedula;
	public $direccion;
	public $email;
	public $id_telefono;
	public $id_estatus;
	public $cargo;
	public $id_ubicacion;  
    public $id_departamento;
    public $id_oficina;
    public $id_usuario;
    public $telefono;


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

			$stm = $this->pdo->prepare("SELECT * FROM empleados  WHERE active IS NOT FALSE ORDER BY id_empleado");
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
			          ->prepare("SELECT * FROM empleado WHERE id_empleado = ?");
			          

			$stm->execute(array($id));
			return $stm->fetch(PDO::FETCH_OBJ);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}

	public function Obtener_cedula($cedula)
	{
		try 
		{
			$stm = $this->pdo
			          ->prepare("SELECT * FROM empleado WHERE cedula = ?");
			          

			$stm->execute(array($cedula));
			return $stm->fetch(PDO::FETCH_OBJ);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}

	public function Obtener_empleados($id)
	{
		try 
		{
			$stm = $this->pdo
			          ->prepare("SELECT * FROM empleados WHERE id_empleado = ?");
			          

			$stm->execute(array($id));
			return $stm->fetch(PDO::FETCH_OBJ);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}

    public function Obtener_json($cedula)
	{
		try 
		{
			$stm = $this->pdo
			          ->prepare("SELECT * FROM empleado WHERE cedula = ?");
			$stm->execute(array($cedula));

			$data = $stm->fetch(PDO::FETCH_OBJ);
            $data = json_encode($data);
            echo $data;
            return $data;
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
			            ->prepare("UPDATE empleado 
			            	       SET active=FALSE, 
			            	       fecha_elim=NOW(), 
			            	       usr_id=".$_SESSION['uid']." WHERE id_empleado = ?");

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
			$sql = "UPDATE empleado
   					SET primer_nombre=?, segundo_nombre=?, primer_apellido=?, segundo_apellido=?, cedula=?, direccion=?, email=?,id_departamento=?, telefono=?, id_estatus=?, cargo=?, id_ubicacion=?,id_oficina=?,id_usuario=?
				    WHERE id_empleado = ?";

			$this->pdo->prepare($sql)
			     ->execute(
				    array(
                        $data->primer_nombre, 
                        $data->segundo_nombre, 
                        $data->primer_apellido, 
                        $data->segundo_apellido, 
                        $data->cedula, 
                        $data->direccion, 
                        $data->email,
                        $data->id_departamento, 
                        $data->telefono,
                        $data->id_estatus, 
                        $data->cargo,
						$data->id_ubicacion,  
    					$data->id_oficina,
    					$data->id_usuario,
						$data->id_empleado
					)
				);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}

	public function Registrar(empleado $data)
	{
		try 
		{
		$sql = "INSERT INTO empleado(primer_nombre, segundo_nombre, primer_apellido,segundo_apellido, cedula, direccion, email, id_departamento, telefono, id_estatus, cargo,id_ubicacion,id_oficina,id_usuario)
    		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

		$this->pdo->prepare($sql)
		     ->execute(
				array(
                        //$data->id_empleado,
                        $data->primer_nombre, 
                        $data->segundo_nombre, 
                        $data->primer_apellido, 
                        $data->segundo_apellido, 
                        $data->cedula, 
                        $data->direccion, 
                        $data->email,
                        $data->id_departamento, 
                        $data->telefono,
                        $data->id_estatus, 
                        $data->cargo,
                        $data->id_ubicacion,  
    					$data->id_oficina,
    					$data->id_usuario
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
			SELECT id_empleado AS id, 
            primer_apellido|| ' '|| primer_nombre||'- '|| cedula  AS text 
			FROM empleados  ORDER BY id");		
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

	public function Listar_json2()
	{
		try
		{
		$stmt = $this->pdo->query("SELECT cedula AS id, primer_apellido|| ' '|| primer_nombre AS text 
			FROM empleados  ORDER BY cedula");		
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