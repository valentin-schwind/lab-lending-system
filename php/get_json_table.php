<?php   
    
    try {   
        require "db_config.php";    

        $allowedTables = ['Inventory', 'Locations', 'Lenders', 'Lendings', 'Borrowers']; // Whitelist of table names

        // Internal update before request
        $updateOverdueSql = "UPDATE Lendings SET Status = 'overdue' WHERE PlannedReturnDate < NOW() AND Status != 'filed'";
        $updateOverdueStmt = $bdd->prepare($updateOverdueSql);
        $updateOverdueStmt->execute();

        // Reset the Status to "lent" for lendings that are marked as "overdue" but the ReturnDate is today or in the future
        $resetStatusSql = "UPDATE Lendings SET Status = 'lent' WHERE PlannedReturnDate >= NOW() AND Status = 'overdue'";
        $resetStatusStmt = $bdd->prepare($resetStatusSql);
        $resetStatusStmt->execute();
    
        $table = $_GET['table'];
        $columns = json_decode($_GET['columns']);

        if (!in_array($table, $allowedTables)) {
            throw new Exception("Unknown Table");
        }  

        if (!empty($columns)) {
            // Validate each column name
            foreach ($columns as $col) {
                if (!preg_match('/^[a-zA-Z0-9_]+$/', $col)) {
                    throw new Exception("Invalid Column Name");
                }
            }
            $columnList = implode(", ", $columns);
        } else { 
            // Fetch column names from the table
            $columnQuery = $bdd->prepare("DESCRIBE " . $table);
            $columnQuery->execute();
            $tableColumns = $columnQuery->fetchAll(PDO::FETCH_COLUMN);
            $columnList = implode(", ", $tableColumns);
        }

        $sql = "SELECT " . $columnList . " FROM " . $table;
        $result = $bdd->query($sql);

        $data = [];
        while ($row = $result->fetch(PDO::FETCH_ASSOC)) {
            $data[] = $row;
        }

        // If data is empty, create an array with null values for each column
        if (empty($data) && isset($tableColumns)) {
            $emptyRow = array_fill_keys($tableColumns, null);
            $data[] = $emptyRow;
        }

        echo json_encode($data);
    
    } catch(PDOException $e) {
        $result = array(
            "status" => "error",
            "message" => "Ein Fehler ist aufgetreten." // Generic error message for production environment
        );
         
        echo json_encode($result);
    } finally {  
        $bdd = null;
    }
?>
