<?php
/**
 * Utility to read the last few lines of spot_monitor.log
 */
$log_file = __DIR__ . '/spot_monitor.log';
if (file_exists($log_file)) {
    $lines = file($log_file);
    echo implode("", array_slice($lines, -20));
} else {
    echo "Log file not found at $log_file";
}
