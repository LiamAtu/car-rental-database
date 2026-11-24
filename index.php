<?php
// Car Rental Database - Embedded Queries (PHP + PDO)
// Run with:  php -S localhost:8000   then open http://localhost:8000

// ---- 1. Connect to the database -----------------------------------
$host     = '127.0.0.1';
$dbname   = 'car_rental';
$user     = 'root';
$password = '';            // <-- put your MySQL root password here

$pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $user, $password);
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);   // throw errors as exceptions

$message = '';

// ---- 2. Book a car (calls the stored procedure) -------------------
if (isset($_POST['book'])) {
    try {
        $stmt = $pdo->prepare("CALL book_car(?, ?, ?, ?, ?, ?)");
        $stmt->execute([
            $_POST['customer_id'], $_POST['car_id'],
            $_POST['branch_id'],   $_POST['branch_id'],
            $_POST['start_date'],  $_POST['end_date']
        ]);
        $message = "Booking confirmed!";
    } catch (PDOException $e) {
        $message = "Booking failed: " . $e->errorInfo[2];   // e.g. "Car is already booked for those dates"
    }
}

// ---- 3. Simple query: use the view ---------------------------------
$cars = $pdo->query("SELECT * FROM available_cars")->fetchAll(PDO::FETCH_ASSOC);

// ---- 4. Prepared statement with user input -------------------------
// The ? placeholder stops SQL injection - the email is sent
// separately from the SQL, so it can never be run as code.
$rentals = [];
$email = $_GET['email'] ?? '';
if ($email !== '') {
    $stmt = $pdo->prepare("
        SELECT r.rental_id, c.reg_number, r.start_date, r.end_date, r.total_cost, r.status
        FROM Rental r
        JOIN Customer cu ON r.customer_id = cu.customer_id
        JOIN Car c       ON r.car_id = c.car_id
        WHERE cu.email = ?
        ORDER BY r.start_date");
    $stmt->execute([$email]);
    $rentals = $stmt->fetchAll(PDO::FETCH_ASSOC);
}

// ---- 5. Aggregation query ------------------------------------------
$revenue = $pdo->query("
    SELECT b.name AS branch, SUM(p.amount) AS revenue
    FROM Payment p
    JOIN Rental r ON p.rental_id = r.rental_id
    JOIN Branch b ON r.pickup_branch_id = b.branch_id
    GROUP BY b.name
    ORDER BY revenue DESC")->fetchAll(PDO::FETCH_ASSOC);

// Helper: print any result set as an HTML table
function show_table($rows) {
    if (!$rows) { echo "<p>No results.</p>"; return; }
    echo "<table><tr>";
    foreach (array_keys($rows[0]) as $col) echo "<th>" . htmlspecialchars($col) . "</th>";
    echo "</tr>";
    foreach ($rows as $row) {
        echo "<tr>";
        foreach ($row as $val) echo "<td>" . htmlspecialchars($val ?? 'NULL') . "</td>";
        echo "</tr>";
    }
    echo "</table>";
}
?>
<!DOCTYPE html>
<html>
<head>
    <title>Car Rental</title>
    <style>
        body  { font-family: Arial, sans-serif; margin: 30px; }
        table { border-collapse: collapse; margin-bottom: 25px; }
        th, td { border: 1px solid #ccc; padding: 6px 10px; }
        th    { background: #34495e; color: white; }
        .msg  { padding: 10px; background: #eef; margin-bottom: 20px; }
    </style>
</head>
<body>
    <h1>Car Rental Database</h1>

    <?php if ($message): ?>
        <div class="msg"><?= htmlspecialchars($message) ?></div>
    <?php endif; ?>

    <h2>Available cars</h2>
    <?php show_table($cars); ?>

    <h2>Revenue per branch</h2>
    <?php show_table($revenue); ?>

    <h2>Find a customer's rentals</h2>
    <form method="get">
        <input name="email" placeholder="e.g. conor.byrne@example.com" size="35"
               value="<?= htmlspecialchars($email) ?>">
        <button>Search</button>
    </form>
    <?php if ($email !== '') show_table($rentals); ?>

    <h2>Book a car</h2>
    <form method="post">
        Customer ID <input name="customer_id" size="3" required>
        Car ID <input name="car_id" size="3" required>
        Branch ID <input name="branch_id" size="3" required>
        From <input type="date" name="start_date" required>
        To <input type="date" name="end_date" required>
        <button name="book">Book</button>
    </form>
</body>
</html>
