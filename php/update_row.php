<?php 
    try {  
        require "db_config.php";  

        $input = filter_input_array(INPUT_POST);

        $allowedTables = ['Inventory', 'Locations', 'Lenders', 'Lendings', 'Borrowers'];
        $tableName = $_GET['table']; 

        $action = $input['action'];
        unset($input['action']); 

        if ($action === 'update') {
            $setPart = [];
            foreach ($input as $key => $value) {
                // Check if the value is null or empty
                if ($value === null || $value === '') {
                    $setPart[] = "$key = NULL";
                } else {
                    $setPart[] = "$key = :$key";
                }
            }
            $setString = implode(', ', $setPart);
            $sql = "UPDATE $tableName SET $setString WHERE ID = :ID";
            $stmt = $bdd->prepare($sql);
        
            foreach ($input as $key => &$value) {
                // Bind the value only if it's not null or empty
                if ($value !== null && $value !== '') {
                    $stmt->bindParam(":$key", $value);
                }
            }
            echo json_encode($sql);
        } else if ($action === 'delete') {
            $sql = "DELETE FROM $tableName WHERE ID = :ID";
            $stmt = $bdd->prepare($sql);
            $stmt->bindParam(':ID', $input['ID'], PDO::PARAM_INT); 
        } else if ($action === 'restore') {
            $sql = "UPDATE $tableName SET deleted = 0 WHERE ID = :ID";
            $stmt = $bdd->prepare($sql);
            $stmt->bindParam(':ID', $input['ID'], PDO::PARAM_INT);
        } else if ($action === 'create') {
            $columns = implode(", ", array_keys($input));
            $placeholders = array_map(function($key) { return ":$key"; }, array_keys($input));
            $placeholdersString = implode(", ", $placeholders);
            $sql = "INSERT INTO $tableName ($columns) VALUES ($placeholdersString)";
            $stmt = $bdd->prepare($sql);

            foreach ($input as $key => &$value) {
                if ($value === null || $value === '') {
                    $stmt->bindValue(":$key", $value, PDO::PARAM_NULL);
                } else {
                    $stmt->bindParam(":$key", $value);
                }
            }
        } 

        $stmt->execute();  
        


        echo json_encode($input);
    } catch(PDOException $e) {
        $result = array(
            "status" => "error",
            "message" => $e->getMessage()
        );
         
        echo json_encode($result);
    } finally {  
        $bdd = null;
    }
?>
