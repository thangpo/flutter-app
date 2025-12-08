<?php
// api/v2/endpoints/webrtc.php
// -----------------------------------------------------------------------------
// WebRTC signaling endpoint (P2P) cho gọi 1-1 audio/video trên WoWonder.
// Hỗ trợ:
//   - create    : tạo cuộc gọi (status: ringing) + gửi FCM call_invite (nếu có token)
//   - offer     : gửi SDP offer
//   - answer    : gửi SDP answer
//   - candidate : gửi ICE candidate
//   - poll      : lấy cập nhật (sdp/candidate/status) từ phía đối diện
//   - action    : answer | decline | end
//   - inbox     : callee kiểm tra có cuộc gọi 'ringing' mới không
// -----------------------------------------------------------------------------

ini_set('display_errors', 0);
ini_set('log_errors', 1);
ini_set('error_log', '/tmp/webrtc_debug.log');  // 🟢 ghi ra thư mục /tmp (luôn có quyền ghi)
error_reporting(E_ALL);
// === ADD: base64url helper (APNs JWT bắt buộc) ===
if (!function_exists('_b64url')) {
    function _b64url($s) {
        return rtrim(strtr(base64_encode($s), '+/', '-_'), '=');
    }
}
// Simple request logger
function log_webrtc($msg, $ctx = array())
{
    $req = isset($GLOBALS['__REQ_ID']) ? $GLOBALS['__REQ_ID'] : uniqid('req_', true);
    $out = "[webrtc][{$req}] {$msg}";
    if (!empty($ctx) && is_array($ctx)) {
        $out .= ' ' . json_encode($ctx, JSON_UNESCAPED_UNICODE);
    }
    error_log($out);
}
$GLOBALS['__REQ_ID'] = uniqid('req_', true);

header('Content-Type: application/json; charset=utf-8');

// Debug sớm + sanity ping (chạy trước bootstrap để tránh fatal khi có parse error khác)
if (isset($_GET['debug'])) {
    ini_set('display_errors', 1);
    ini_set('display_startup_errors', 1);
    error_reporting(E_ALL);
}
if (isset($_GET['ping'])) {
    echo json_encode(['api_status' => 200, 'pong' => time()]);
    exit;
}

// -----------------------------------------------------------------------------
// Helpers an toàn cho mysqli (tránh fatal nếu $sqlConnect không hợp lệ)
// -----------------------------------------------------------------------------
if (!function_exists('__is_mysqli')) {
    function __is_mysqli($link)
    {
        return $link instanceof mysqli;
    }
}
if (!function_exists('__safe_num_rows')) {
    function __safe_num_rows($res)
    {
        return ($res instanceof mysqli_result) ? mysqli_num_rows($res) : 0;
    }
}

// -----------------------------------------------------------------------------
// 1) Bootstrap WoWonder - ĐÃ SỬA ĐƯỜNG DẪN TUYỆT ĐỐI
// -----------------------------------------------------------------------------
$__INIT_CANDIDATES = array(
    '/home/vnshop247.com/domains/social.vnshop247.com/_social/assets/init.php', // TUYỆT ĐỐI
    __DIR__ . '/../../../../assets/init.php',
    __DIR__ . '/../../../assets/init.php',
    __DIR__ . '/../../assets/init.php',
    dirname(__DIR__, 3) . '/assets/init.php',
    dirname(__DIR__, 4) . '/assets/init.php',
);
$__INIT_OK = false;
foreach ($__INIT_CANDIDATES as $__p) {
    if (file_exists($__p)) {
        require_once $__p;
        $__INIT_OK = true;
        break;
    }
}
if (!$__INIT_OK) {
    http_response_code(500);
    echo json_encode(array('api_status' => 500, 'error' => 'assets/init.php not found'), JSON_PRETTY_PRINT);
    exit;
}

// 2) Debug (sau bootstrap)
$__DEBUG = isset($_GET['debug']) ? 1 : 0;
if ($__DEBUG) {
    ini_set('display_errors', 1);
    ini_set('display_startup_errors', 1);
    error_reporting(E_ALL);
}

// 3) Giải mã config nếu có
if (function_exists('decryptConfigData')) {
    decryptConfigData();
}

// 4) Context
global $config, $wo, $server_key, $sqlConnect, $user;
if (!function_exists('Wo_Secure')) {
    function Wo_Secure($s, $c = 1)
    {
        return $s;
    }
}

// -----------------------------------------------------------------------------
// Tiện ích trả JSON
// -----------------------------------------------------------------------------
$error_code = null;
$error_message = null;
function _ok($d = array())
{
    return array_merge(array('api_status' => 200), $d);
}
function _fail($code, $msg)
{
    global $error_code, $error_message;
    $error_code = $code;
    $error_message = $msg;
    return null;
}

// -----------------------------------------------------------------------------
// AUTH từ access_token
// -----------------------------------------------------------------------------
$access_token = isset($_GET['access_token']) ? $_GET['access_token'] : (isset($_POST['access_token']) ? $_POST['access_token'] : '');
$__auth_trace = array();
function __get_user_by_id($uid)
{
    if (function_exists('Wo_UserData'))
        return Wo_UserData($uid);
    return null;
}
$me_id = 0;
if (!empty($access_token) && function_exists('Wo_UserIdFromToken')) {
    $try = Wo_UserIdFromToken($access_token);
    $__auth_trace['Wo_UserIdFromToken'] = $try;
    if (!empty($try))
        $me_id = (int) $try;
}
if ($me_id <= 0 && !empty($access_token) && function_exists('Wo_UserIdFromSessionID')) {
    $try = Wo_UserIdFromSessionID($access_token);
    $__auth_trace['Wo_UserIdFromSessionID'] = $try;
    if (!empty($try))
        $me_id = (int) $try;
}
// Fallback tra DB an toàn
if ($me_id <= 0 && !empty($access_token) && __is_mysqli($sqlConnect)) {
    $token_esc = mysqli_real_escape_string($sqlConnect, $access_token);
    $tbl = defined('T_APP_SESSIONS') ? T_APP_SESSIONS : 'app_sessions';
    $q = mysqli_query($sqlConnect, "SHOW COLUMNS FROM {$tbl} LIKE 'session_id'");
    $q2 = mysqli_query($sqlConnect, "SHOW COLUMNS FROM {$tbl} LIKE 'user_id'");
    $has_session_id = __safe_num_rows($q) > 0;
    $has_user_id = __safe_num_rows($q2) > 0;
    if ($has_session_id && $has_user_id) {
        $res = mysqli_query($sqlConnect, "SELECT user_id FROM {$tbl} WHERE session_id='{$token_esc}' LIMIT 1");
        if ($res && __safe_num_rows($res)) {
            $row = mysqli_fetch_assoc($res);
            $__auth_trace['db_app_sessions'] = isset($row['user_id']) ? $row['user_id'] : 0;
            if (!empty($row['user_id']))
                $me_id = (int) $row['user_id'];
        }
    }
}
if ($me_id > 0 && (empty($user) || empty($user['user_id']))) {
    $ud = __get_user_by_id($me_id);
    if (!empty($ud) && !empty($ud['user_id']))
        $user = $ud;
}
if (isset($_GET['auth_debug'])) {
    echo json_encode(array(
        'api_status' => 200,
        'trace' => $__auth_trace,
        'me_id' => $me_id,
        'has_user' => (!empty($user) && !empty($user['user_id'])) ? true : false,
    ), JSON_PRETTY_PRINT);
    exit;
}
log_webrtc('auth', array('me_id' => $me_id, 'token_prefix' => substr($access_token, 0, 10)));

// -----------------------------------------------------------------------------
// SERVER KEY
// -----------------------------------------------------------------------------
$requested_type = isset($_REQUEST['type']) ? $_REQUEST['type'] : '';
$provided_key = isset($_POST['server_key']) ? $_POST['server_key'] : (isset($_GET['server_key']) ? $_GET['server_key'] : '');
$valid_keys = array();
if (!empty($config['server_key']))
    $valid_keys[] = $config['server_key'];
if (!empty($wo['config']['server_key']))
    $valid_keys[] = $wo['config']['server_key'];
if (!empty($wo['config']['widnows_app_api_key']))
    $valid_keys[] = $wo['config']['widnows_app_api_key'];
if (!empty($wo['config']['windows_app_api_key']))
    $valid_keys[] = $wo['config']['windows_app_api_key'];
if (!empty($config['widnows_app_api_key']))
    $valid_keys[] = $config['widnows_app_api_key'];
if (!empty($config['windows_app_api_key']))
    $valid_keys[] = $config['windows_app_api_key'];
if (!empty($server_key))
    $valid_keys[] = $server_key;
$valid_keys = array_values(array_unique(array_filter($valid_keys)));
$response_data = null;

if (empty($provided_key)) {
    _fail(5, 'No server key.');
} else if (!in_array($provided_key, $valid_keys, true)) {
    _fail(6, 'Invalid server key.');
} else if ($me_id <= 0 || empty($user) || empty($user['user_id'])) {
    // Cho phép ghi client_log ngay cả khi không xác thực được user (để debug)
    if ($requested_type !== 'client_log') {
        _fail(401, 'Not authorized.');
    }
}

// Kiểm tra bảng signaling
function __table_exists($link, $name)
{
    if (!__is_mysqli($link))
        return false;
    $name = mysqli_real_escape_string($link, $name);
    $q = mysqli_query($link, "SHOW TABLES LIKE '{$name}'");
    return $q && __safe_num_rows($q) > 0;
}
if (empty($error_code)) {
    if (
        !__table_exists($sqlConnect, 'wow_calls')
        || !__table_exists($sqlConnect, 'wow_call_sdp')
        || !__table_exists($sqlConnect, 'wow_call_ice')
    ) {
        echo json_encode(array('api_status' => 500, 'error' => 'Missing signaling tables (wow_calls / wow_call_sdp / wow_call_ice). Import SQL step 1.'), JSON_PRETTY_PRINT);
        exit;
    }
}

// -----------------------------------------------------------------------------
// Helpers DB
// -----------------------------------------------------------------------------
$fetch_call = function ($call_id) use ($sqlConnect) {
    $call_id = (int) $call_id;
    $res = mysqli_query($sqlConnect, "SELECT * FROM wow_calls WHERE id={$call_id} LIMIT 1");
    return ($res && mysqli_num_rows($res)) ? mysqli_fetch_assoc($res) : null;
};
$my_role = function ($call, $uid) {
    if (!$call)
        return null;
    if ((int) $call['caller_id'] === (int) $uid)
        return 'caller';
    if ((int) $call['callee_id'] === (int) $uid)
        return 'callee';
    return null;
};
$insert_sdp = function ($call_id, $role, $type, $sdp) use ($sqlConnect) {
    $call_id = (int) $call_id;
    $role = mysqli_real_escape_string($sqlConnect, $role);
    $type = mysqli_real_escape_string($sqlConnect, $type);
    mysqli_query($sqlConnect, "DELETE FROM wow_call_sdp WHERE call_id={$call_id} AND role='{$role}' AND sdp_type='{$type}'");
    $sdp_esc = mysqli_real_escape_string($sqlConnect, $sdp);
    mysqli_query($sqlConnect, "INSERT INTO wow_call_sdp (call_id,role,sdp_type,sdp,created_at) VALUES ({$call_id},'{$role}','{$type}','{$sdp_esc}',NOW())");
    return (bool) mysqli_insert_id($sqlConnect);
};
$insert_candidate = function ($call_id, $role, $cand, $mid, $mline) use ($sqlConnect) {
    $call_id = (int) $call_id;
    $role = mysqli_real_escape_string($sqlConnect, $role);
    $cand = mysqli_real_escape_string($sqlConnect, $cand);
    $mid = $mid !== null ? "'" . mysqli_real_escape_string($sqlConnect, $mid) . "'" : "NULL";
    $mline = $mline !== null ? (int) $mline : "NULL";
    mysqli_query($sqlConnect, "INSERT INTO wow_call_ice (call_id,role,candidate,sdp_mid,sdp_mline_index,delivered,created_at)
                               VALUES ({$call_id},'{$role}','{$cand}',{$mid},{$mline},0,NOW())");
    return (int) mysqli_insert_id($sqlConnect);
};

// Trả lỗi auth/key chuẩn v2
if (!empty($error_code)) {
    echo json_encode(array('api_status' => '400', 'errors' => array('error_id' => $error_code, 'error_text' => $error_message)), JSON_PRETTY_PRINT);
    exit;
}

// -----------------------------------------------------------------------------
// FCM helper
// -----------------------------------------------------------------------------
function __get_fcm_server_key()
{
    global $wo, $config;
    $keys = array(
        isset($config['fcm_server_key']) ? $config['fcm_server_key'] : null,
        isset($wo['config']['fcm_server_key']) ? $wo['config']['fcm_server_key'] : null,
        isset($wo['config']['android_push_notification_key']) ? $wo['config']['android_push_notification_key'] : null,
        isset($config['android_push_notification_key']) ? $config['android_push_notification_key'] : null,
        isset($wo['config']['android_fcm_key']) ? $wo['config']['android_fcm_key'] : null,
        isset($config['android_fcm_key']) ? $config['android_fcm_key'] : null,
    );
    foreach ($keys as $k) {
        if (!empty($k))
            return $k;
    }
    return null;
}
function __send_fcm_call_invite($to_token, $data)
{
    $serverKey = __get_fcm_server_key();
    if (empty($serverKey) || empty($to_token))
        return false;

    $payload = array(
        'to' => $to_token,
        'priority' => 'high',
        'data' => $data,
    );
    $json = json_encode($payload, JSON_UNESCAPED_UNICODE);

    if (function_exists('curl_init')) {
        $ch = curl_init('https://fcm.googleapis.com/fcm/send');
        curl_setopt_array($ch, array(
            CURLOPT_POST => true,
            CURLOPT_HTTPHEADER => array(
                'Content-Type: application/json',
                'Authorization: key=' . $serverKey,
            ),
            CURLOPT_POSTFIELDS => $json,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT => 8,
        ));
        // trong __send_fcm_call_invite
        $resp = curl_exec($ch);
        if ($resp === false) {
            error_log('[webrtc] FCM cURL error: ' . curl_error($ch));
        } else {
            error_log('[webrtc] FCM resp=' . substr($resp, 0, 200)); // tránh log quá dài
        }
        curl_close($ch);
        return $resp !== false;
    }

    $opts = array(
        'http' => array(
            'method' => 'POST',
            'header' => "Content-Type: application/json\r\n" .
                "Authorization: key={$serverKey}\r\n",
            'content' => $json,
            'timeout' => 8,
        )
    );
    $ctx = stream_context_create($opts);
    $resp = @file_get_contents('https://fcm.googleapis.com/fcm/send', false, $ctx);
    if ($resp === false) {
        error_log('[webrtc] FCM stream error (no curl).');
    }
    return $resp !== false;
}

function __get_user_fcm_token($user_id)
{
    global $sqlConnect;
    static $has_col = null;
    $users_tbl = defined('T_USERS') ? T_USERS : 'Wo_Users';
    if ($has_col === null) {
        $rq = mysqli_query($sqlConnect, "SHOW COLUMNS FROM {$users_tbl} LIKE 'firebase_device_token'");
        $has_col = ($rq && mysqli_num_rows($rq) > 0);
    }
    if (!$has_col)
        return null;
    $uid = (int) $user_id;
    if ($uid <= 0)
        return null;
    $r = mysqli_query($sqlConnect, "SELECT firebase_device_token FROM {$users_tbl} WHERE user_id={$uid} LIMIT 1");
    if ($r && mysqli_num_rows($r)) {
        $row = mysqli_fetch_assoc($r);
        if (!empty($row['firebase_device_token']))
            return $row['firebase_device_token'];
    }
    return null;
}

// === REPLACE: trả token + env + bundle (nếu DB có cột) ===
function __get_pushkit_info($user_id) {
    global $sqlConnect;
    $users_tbl = defined('T_USERS') ? T_USERS : 'Wo_Users';
    $uid = (int)$user_id;
    if ($uid <= 0) return [null, null, null];

    $has_token = false; $has_env = false; $has_bundle = false;
    if ($rq = mysqli_query($sqlConnect, "SHOW COLUMNS FROM {$users_tbl} LIKE 'pushkit_token'")) {
        $has_token = mysqli_num_rows($rq) > 0;
    }
    if ($rq2 = mysqli_query($sqlConnect, "SHOW COLUMNS FROM {$users_tbl} LIKE 'pushkit_env'")) {
        $has_env = mysqli_num_rows($rq2) > 0;
    }
    if ($rq3 = mysqli_query($sqlConnect, "SHOW COLUMNS FROM {$users_tbl} LIKE 'pushkit_bundle'")) {
        $has_bundle = mysqli_num_rows($rq3) > 0;
    }
    if (!$has_token) return [null, null, null];

    $cols = "pushkit_token";
    if ($has_env)    $cols .= ", pushkit_env";
    if ($has_bundle) $cols .= ", pushkit_bundle";

    $q = mysqli_query($sqlConnect, "SELECT {$cols} FROM {$users_tbl} WHERE user_id={$uid} LIMIT 1");
    if ($q && mysqli_num_rows($q)) {
        $row    = mysqli_fetch_assoc($q);
        $token  = !empty($row['pushkit_token'])  ? $row['pushkit_token']  : null;
        $env    = ($has_env    && !empty($row['pushkit_env']))    ? $row['pushkit_env']    : null; // 'sandbox'|'prod'
        $bundle = ($has_bundle && !empty($row['pushkit_bundle'])) ? $row['pushkit_bundle'] : null;
        return [$token, $env, $bundle];
    }
    return [null, null, null];
}

// === REPLACE: Gửi APNs VoIP chuẩn + hỗ trợ override bundle để set apns-topic theo từng thiết bị ===
function __send_apns_voip($tokenHex, array $payload, $forceEnv = null, $bundleOverride = null) {
    // Require config
    $authKeyPath = defined('APNS_VOIP_KEY_PATH') ? APNS_VOIP_KEY_PATH : null;
    $teamId      = defined('APNS_VOIP_TEAM_ID') ? APNS_VOIP_TEAM_ID : null;
    $keyId       = defined('APNS_VOIP_KEY_ID') ? APNS_VOIP_KEY_ID : null;
    $bundleIdDef = defined('APNS_VOIP_BUNDLE_ID') ? APNS_VOIP_BUNDLE_ID : null;

    if (empty($authKeyPath) || !file_exists($authKeyPath) || empty($teamId) || empty($keyId) || empty($bundleIdDef)) {
        error_log('[webrtc] APNs VoIP config missing, skip send.');
        return false;
    }
    if (empty($tokenHex) || !preg_match('/^[0-9a-f]{64,512}$/i', $tokenHex)) {
        error_log('[webrtc] APNs VoIP invalid token');
        return false;
    }

    // Env
    $useSandbox = defined('APNS_VOIP_SANDBOX') ? (bool)APNS_VOIP_SANDBOX : true;
    if ($forceEnv === 'sandbox') $useSandbox = true;
    if ($forceEnv === 'prod')    $useSandbox = false;
    $host = $useSandbox ? 'https://api.sandbox.push.apple.com' : 'https://api.push.apple.com';

    // JWT ES256
    $p8 = file_get_contents($authKeyPath);
    $priv = openssl_pkey_get_private($p8, '');
    if (!$priv) {
        error_log('[webrtc] APNs cannot load .p8 private key');
        return false;
    }
    $header  = _b64url(json_encode(['alg' => 'ES256', 'kid' => $keyId]));
    $claims  = _b64url(json_encode(['iss' => $teamId, 'iat' => time()]));
    $signing = $header . '.' . $claims;

    $sig = '';
    if (!openssl_sign($signing, $sig, $priv, OPENSSL_ALGO_SHA256)) {
        error_log('[webrtc] APNs openssl_sign failed');
        return false;
    }
    $jwt = $signing . '.' . _b64url($sig);

    // Body
    $body = json_encode(['aps' => ['content-available' => 1], 'data' => $payload], JSON_UNESCAPED_UNICODE);

    // Topic theo bundleOverride (nếu có) hoặc bundle default
    $bundleTopic = ($bundleOverride && preg_match('~^[A-Za-z0-9.\-]+$~', $bundleOverride))
        ? $bundleOverride
        : $bundleIdDef;
    $topic = $bundleTopic . '.voip';

    $url = $host . '/3/device/' . $tokenHex;
    $headers = [
        'authorization: bearer ' . $jwt,
        'apns-topic: ' . $topic,
        'apns-push-type: voip',
        'apns-priority: 10',
        'content-type: application/json',
    ];

    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_HTTP_VERSION   => CURL_HTTP_VERSION_2TLS, // HTTP/2
        CURLOPT_POST           => true,
        CURLOPT_POSTFIELDS     => $body,
        CURLOPT_HTTPHEADER     => $headers,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HEADER         => true,
        CURLOPT_TIMEOUT        => 10,
    ]);
    $resp = curl_exec($ch);
    if ($resp === false) {
        error_log('[webrtc] APNs curl error: ' . curl_error($ch));
        curl_close($ch);
        return false;
    }
    $status    = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $headerLen = curl_getinfo($ch, CURLINFO_HEADER_SIZE);
    $respBody  = substr($resp, $headerLen);
    curl_close($ch);

    error_log(sprintf('[APNs] http=%d env=%s topic=%s body=%s',
        $status, ($useSandbox?'sandbox':'prod'), $topic, $respBody
    ));

    return ($status >= 200 && $status < 300);
}

function __notify_peer_signal($call, $me_id, $payload)
{
    if (!$call || !is_array($call))
        return;
    $other_id = ((int) $call['caller_id'] === (int) $me_id)
        ? (int) $call['callee_id']
        : (int) $call['caller_id'];
    if ($other_id <= 0) {
        return;
    }

    $data = array_merge(array(
        'type' => 'call_signal',
        'call_id' => isset($call['id']) ? (int) $call['id'] : 0,
        'ts' => time(),
    ), $payload);

    // Push qua FCM (Android/iOS) nEU cA3 token
    $to_token = __get_user_fcm_token($other_id);
    $pushed = false;
    if (!empty($to_token)) {
        error_log('[webrtc] notify_peer_signal FCM to=' . substr($to_token, 0, 10) . '... call_id=' . $data['call_id'] . ' payload=' . json_encode($payload));
        __send_fcm_call_invite($to_token, $data);
        $pushed = true;
    }

    // ⚠️ Không gửi APNs VoIP cho các tín hiệu peer (offer/answer/candidate/action).
    // Chỉ call_invite mới cần CallKit. Gửi VoIP cho các signal khác sẽ bật CallKit lại ở caller.
    error_log('[webrtc] skip APNs VoIP for peer signal call_id=' . $data['call_id'] . ' other_id=' . $other_id . ' payload=' . json_encode($payload));

    if (!$pushed) {
        error_log('[webrtc] No push target for peer signal call_id=' . $data['call_id'] . ' other_id=' . $other_id);
    }
}

// -----------------------------------------------------------------------------
// Xử lý type
// -----------------------------------------------------------------------------
$type = isset($_REQUEST['type']) ? $_REQUEST['type'] : '';
switch ($type) {
    case 'create': {
        $recipient_id = isset($_POST['recipient_id']) ? (int) $_POST['recipient_id'] : 0;
        $media_type = isset($_POST['media_type']) ? strtolower(trim($_POST['media_type'])) : 'audio';
        if (!in_array($media_type, array('audio', 'video'), true))
            $media_type = 'audio';
        if ($recipient_id <= 0) {
            $response_data = _ok(array('api_status' => 400, 'error' => 'recipient_id is required.'));
            break;
        }
        if ($recipient_id == $me_id) {
            $response_data = _ok(array('api_status' => 400, 'error' => 'Cannot call yourself.'));
            break;
        }

        $ins = "INSERT INTO wow_calls (caller_id,callee_id,media_type,status,created_at,updated_at)
                VALUES ({$me_id},{$recipient_id},'{$media_type}','ringing',NOW(),NOW())";
        if (!mysqli_query($sqlConnect, $ins)) {
            $response_data = _ok(array('api_status' => 500, 'error' => 'Failed to create call.' . ($__DEBUG ? ' :: ' . mysqli_error($sqlConnect) : '')));
            break;
        }
        $call_id = (int) mysqli_insert_id($sqlConnect);

        // Gửi FCM call_invite nếu callee có token
        $to_token = null;
        $users_tbl = defined('T_USERS') ? T_USERS : 'Wo_Users';
        $rq = mysqli_query($sqlConnect, "SHOW COLUMNS FROM {$users_tbl} LIKE 'firebase_device_token'");
        if ($rq && mysqli_num_rows($rq) > 0) {
            $r = mysqli_query($sqlConnect, "SELECT firebase_device_token FROM {$users_tbl} WHERE user_id={$recipient_id} LIMIT 1");
            if ($r && ($row = mysqli_fetch_assoc($r))) {
                $to_token = isset($row['firebase_device_token']) ? $row['firebase_device_token'] : null;
            }
        }
        if (!empty($to_token)) {
            __send_fcm_call_invite($to_token, array(
                'type' => 'call_invite',
                'call_id' => $call_id,
                'media' => $media_type,
                'caller_id' => $me_id,
                'ts' => time(),
            ));
        }
        // Gửi VoIP (PushKit) nếu callee có pushkit_token
        list($pushkit_token, $pushkit_env, $pushkit_bundle) = __get_pushkit_info($recipient_id);
        if (!empty($pushkit_token)) {
            // forceEnv: 'sandbox' | 'prod' | null
            $forceEnv = null;
            if (!empty($pushkit_env)) {
                $forceEnv = ($pushkit_env === 'sandbox') ? 'sandbox' : 'prod';
            }
            __send_apns_voip($pushkit_token, array(
                'type'          => 'call_invite',
                'call_id'       => $call_id,
                'media'         => $media_type,
                'caller_id'     => $me_id,
                'caller_name'   => isset($user['name']) ? $user['name'] : '',
                'caller_avatar' => isset($user['avatar']) ? $user['avatar'] : '',
                'ts'            => time(),
            ), $forceEnv, $pushkit_bundle /* <= topic = <bundle>.voip */);
        }

        log_webrtc('create', array('call_id' => $call_id, 'media' => $media_type, 'recipient_id' => $recipient_id));
        $response_data = _ok(array('call_id' => $call_id, 'status' => 'ringing', 'media_type' => $media_type));
        break;
    }

    case 'offer': {
        $call_id = isset($_POST['call_id']) ? (int) $_POST['call_id'] : 0;
        $sdp = isset($_POST['sdp']) ? $_POST['sdp'] : '';
        $call = $fetch_call($call_id);
        if (!$call) {
            $response_data = _ok(array('api_status' => 404, 'error' => 'Call not found.'));
            break;
        }
        $role = $my_role($call, $me_id);
        if (!$role) {
            $response_data = _ok(array('api_status' => 403, 'error' => 'Forbidden.'));
            break;
        }
        if (!$sdp) {
            $response_data = _ok(array('api_status' => 400, 'error' => 'SDP is required.'));
            break;
        }
        if (!$insert_sdp($call_id, $role, 'offer', $sdp)) {
            error_log("[webrtc] offer insert failed call_id={$call_id} role={$role} err=" . mysqli_error($sqlConnect));
            $response_data = _ok(array('api_status' => 500, 'error' => 'Failed to save offer.'));
            break;
        }
        // Force call status=ringing to unstick callee poll
        mysqli_query($sqlConnect, "UPDATE wow_calls SET status='ringing', updated_at=NOW() WHERE id={$call_id}");
        mysqli_query($sqlConnect, "UPDATE wow_calls SET updated_at=NOW() WHERE id={$call_id}");
        log_webrtc('offer', array('call_id' => $call_id, 'role' => $role, 'len' => strlen($sdp)));
        __notify_peer_signal($call, $me_id, array(
            'signal' => 'offer',
            'sdp_offer' => $sdp,
            'call_status' => $call['status'],
            'media' => $call['media_type'],
        ));
        $response_data = _ok(array('saved' => true));
        break;
    }

    case 'answer': {
        $call_id = isset($_POST['call_id']) ? (int) $_POST['call_id'] : 0;
        $sdp = isset($_POST['sdp']) ? $_POST['sdp'] : '';
        $call = $fetch_call($call_id);
        if (!$call) {
            $response_data = _ok(array('api_status' => 404, 'error' => 'Call not found.'));
            break;
        }
        $role = $my_role($call, $me_id);
        if (!$role) {
            $response_data = _ok(array('api_status' => 403, 'error' => 'Forbidden.'));
            break;
        }
        if (!$sdp) {
            $response_data = _ok(array('api_status' => 400, 'error' => 'SDP is required.'));
            break;
        }
        if (!$insert_sdp($call_id, $role, 'answer', $sdp)) {
            error_log("[webrtc] answer insert failed call_id={$call_id} role={$role} err=" . mysqli_error($sqlConnect));
            $response_data = _ok(array('api_status' => 500, 'error' => 'Failed to save answer.'));
            break;
        }
        mysqli_query($sqlConnect, "UPDATE wow_calls SET status='answered', updated_at=NOW() WHERE id={$call_id}");
        log_webrtc('answer', array('call_id' => $call_id, 'role' => $role, 'len' => strlen($sdp)));
        __notify_peer_signal($call, $me_id, array(
            'signal' => 'answer',
            'sdp_answer' => $sdp,
            'call_status' => 'answered',
            'media' => $call['media_type'],
        ));
        $response_data = _ok(array('saved' => true, 'status' => 'answered'));
        break;
    }

    case 'candidate': {
        $call_id = isset($_POST['call_id']) ? (int) $_POST['call_id'] : 0;
        $cand = isset($_POST['candidate']) ? $_POST['candidate'] : '';
        $mid = isset($_POST['sdp_mid']) ? $_POST['sdp_mid'] : null;
        $mline = isset($_POST['sdp_mline_index']) ? $_POST['sdp_mline_index'] : null;
        $call = $fetch_call($call_id);
        if (!$call) {
            $response_data = _ok(array('api_status' => 404, 'error' => 'Call not found.'));
            break;
        }
        $role = $my_role($call, $me_id);
        if (!$role) {
            $response_data = _ok(array('api_status' => 403, 'error' => 'Forbidden.'));
            break;
        }
        if (!$cand) {
            $response_data = _ok(array('api_status' => 400, 'error' => 'candidate is required.'));
            break;
        }
        $cand_esc = mysqli_real_escape_string($sqlConnect, $cand);
        $role_esc = mysqli_real_escape_string($sqlConnect, $role);
        $mid_esc = $mid !== null ? "'" . mysqli_real_escape_string($sqlConnect, $mid) . "'" : "NULL";
        $mline_int = $mline !== null ? (int) $mline : "NULL";
        $dup_q = "SELECT id FROM wow_call_ice WHERE call_id={$call_id} AND role='{$role_esc}' AND candidate='{$cand_esc}' AND (sdp_mid IS NULL OR sdp_mid={$mid_esc}) AND (sdp_mline_index IS NULL OR sdp_mline_index={$mline_int}) LIMIT 1";
        $dup_res = mysqli_query($sqlConnect, $dup_q);
        if ($dup_res && mysqli_num_rows($dup_res) > 0) {
            $response_data = _ok(array('api_status' => 200, 'duplicate' => true));
            break;
        }
        $id = $insert_candidate($call_id, $role, $cand, $mid, $mline);
        if ($id <= 0) {
            $response_data = _ok(array('api_status' => 500, 'error' => 'Failed to save candidate.'));
            break;
        }
        mysqli_query($sqlConnect, "UPDATE wow_calls SET updated_at=NOW() WHERE id={$call_id}");
        log_webrtc('candidate', array('call_id' => $call_id, 'role' => $role, 'len' => strlen($cand)));
        __notify_peer_signal($call, $me_id, array(
            'signal' => 'candidate',
            'candidate' => $cand,
            'sdp_mid' => $mid,
            'sdp_mline_index' => $mline,
        ));
        $response_data = _ok(array('id' => $id));
        break;
    }

    case 'poll': {
        $call_id = isset($_REQUEST['call_id']) ? (int) $_REQUEST['call_id'] : 0;
        $call = $fetch_call($call_id);
        if (!$call) {
            $response_data = _ok(array('api_status' => 404, 'error' => 'Call not found.'));
            break;
        }
        $role = $my_role($call, $me_id);
        if (!$role) {
            $response_data = _ok(array('api_status' => 403, 'error' => 'Forbidden.'));
            break;
        }
        // Auto-timeout: nếu không tiến triển >60s thì kết thúc cuộc gọi để client dừng poll
        $timeout_sec = 60;
        $now = time();
        $t_updated = isset($call['updated_at']) ? strtotime($call['updated_at']) : 0;
        $t_created = isset($call['created_at']) ? strtotime($call['created_at']) : 0;
        $last_ts = $t_updated ?: $t_created ?: $now;
        if (in_array($call['status'], array('ringing', 'answered'), true) && ($now - $last_ts) > $timeout_sec) {
            mysqli_query($sqlConnect, "UPDATE wow_calls SET status='ended', updated_at=NOW() WHERE id={$call_id}");
            mysqli_query($sqlConnect, "DELETE FROM wow_call_sdp WHERE call_id={$call_id}");
            mysqli_query($sqlConnect, "DELETE FROM wow_call_ice WHERE call_id={$call_id}");
            $call['status'] = 'ended';
            __notify_peer_signal($call, $me_id, array(
                'signal' => 'action',
                'call_status' => 'ended',
                'reason' => 'timeout_server_poll',
            ));
            log_webrtc('poll_timeout', array('call_id' => $call_id, 'role' => $role));
        }
        $other = ($role === 'caller') ? 'callee' : 'caller';

        $sdp_offer = null;
        $sdp_answer = null;
        $cands = array();

        $q_offer = "SELECT id,call_id,role,sdp_type,sdp,created_at
                    FROM wow_call_sdp
                    WHERE call_id={$call_id} AND role='{$other}' AND sdp_type='offer'
                    ORDER BY id DESC LIMIT 1";
        if ($res = mysqli_query($sqlConnect, $q_offer)) {
            if (mysqli_num_rows($res))
                $sdp_offer = mysqli_fetch_assoc($res);
        }
        // fallback: lỡ role sai, lấy offer mới nhất bất kể role
        if (!$sdp_offer) {
            $q_offer_any = "SELECT id,call_id,role,sdp_type,sdp,created_at FROM wow_call_sdp WHERE call_id={$call_id} AND sdp_type='offer' ORDER BY id DESC LIMIT 1";
            if ($res = mysqli_query($sqlConnect, $q_offer_any)) {
                if (mysqli_num_rows($res))
                    $sdp_offer = mysqli_fetch_assoc($res);
            }
        }

        $q_answer = "SELECT id,call_id,role,sdp_type,sdp,created_at
                     FROM wow_call_sdp
                     WHERE call_id={$call_id} AND role='{$other}' AND sdp_type='answer'
                     ORDER BY id DESC LIMIT 1";
        if ($res = mysqli_query($sqlConnect, $q_answer)) {
            if (mysqli_num_rows($res))
                $sdp_answer = mysqli_fetch_assoc($res);
        }
        // fallback: lỡ role sai, lấy answer mới nhất bất kể role
        if (!$sdp_answer) {
            $q_answer_any = "SELECT id,call_id,role,sdp_type,sdp,created_at FROM wow_call_sdp WHERE call_id={$call_id} AND sdp_type='answer' ORDER BY id DESC LIMIT 1";
            if ($res = mysqli_query($sqlConnect, $q_answer_any)) {
                if (mysqli_num_rows($res))
                    $sdp_answer = mysqli_fetch_assoc($res);
            }
        }

        $q_cand = "SELECT id,candidate,sdp_mid,sdp_mline_index,created_at
                   FROM wow_call_ice
                   WHERE call_id={$call_id} AND role='{$other}' AND delivered=0
                   ORDER BY id ASC LIMIT 200";
        if ($res = mysqli_query($sqlConnect, $q_cand)) {
            while ($row = mysqli_fetch_assoc($res)) {
                $cands[] = $row;
            }
        }
        if (!empty($cands)) {
            $ids = implode(',', array_map('intval', array_column($cands, 'id')));
            mysqli_query($sqlConnect, "UPDATE wow_call_ice SET delivered=1 WHERE id IN ({$ids})");
        }

        // Giảm spam log: chỉ log poll khi debug hoặc ngẫu nhiên 1/20
        if ($__DEBUG || mt_rand(1, 20) === 1) {
            log_webrtc('poll', array(
                'call_id' => $call_id,
                'role' => $role,
                'status' => $call['status'],
                'offer' => $sdp_offer ? 'y' : 'n',
                'answer' => $sdp_answer ? 'y' : 'n',
                'ice' => count($cands),
            ));
        }
        $response_data = _ok(array(
            'call_status' => $call['status'],
            'media_type' => $call['media_type'],
            'sdp_offer' => $sdp_offer,
            'sdp_answer' => $sdp_answer,
            'ice_candidates' => $cands,
        ));
        break;
    }

    case 'client_log': {
        $call_id = isset($_POST['call_id']) ? (int) $_POST['call_id'] : 0;
        $event   = isset($_POST['event']) ? trim($_POST['event']) : '';
        $details_raw = isset($_POST['details']) ? $_POST['details'] : '';
        $details = $details_raw;
        if (is_string($details_raw)) {
            $decoded = json_decode($details_raw, true);
            if (is_array($decoded)) $details = $decoded;
        }
        log_webrtc('client_log', array(
            'call_id' => $call_id,
            'event'   => $event,
            'details' => $details,
            'me_id'   => $me_id,
        ));
        $response_data = _ok(array('logged' => true));
        break;
    }

    case 'action': {
        $call_id = isset($_POST['call_id']) ? (int) $_POST['call_id'] : 0;
        $action = isset($_POST['action']) ? strtolower(trim($_POST['action'])) : '';
        $call = $fetch_call($call_id);
        if (!$call) {
            $response_data = _ok(array('api_status' => 404, 'error' => 'Call not found.'));
            break;
        }
        $role = $my_role($call, $me_id);
        if (!$role) {
            $response_data = _ok(array('api_status' => 403, 'error' => 'Forbidden.'));
            break;
        }

        $map = array('answer' => 'answered', 'decline' => 'declined', 'end' => 'ended');
        if (!isset($map[$action])) {
            $response_data = _ok(array('api_status' => 400, 'error' => 'Invalid action.'));
            break;
        }
        $new_status = $map[$action];

        if (!mysqli_query($sqlConnect, "UPDATE wow_calls SET status='{$new_status}', updated_at=NOW() WHERE id={$call_id}")) {
            $response_data = _ok(array('api_status' => 500, 'error' => 'Failed to update status.' . ($__DEBUG ? ' :: ' . mysqli_error($sqlConnect) : '')));
            break;
        }
        // cleanup signaling khi end/decline
        if (in_array($new_status, array('ended', 'declined'), true)) {
            mysqli_query($sqlConnect, "DELETE FROM wow_call_sdp WHERE call_id={$call_id}");
            mysqli_query($sqlConnect, "DELETE FROM wow_call_ice WHERE call_id={$call_id}");
        }
        log_webrtc('action', array('call_id' => $call_id, 'role' => $role, 'action' => $action, 'status' => $new_status));
        __notify_peer_signal($call, $me_id, array(
            'signal' => 'action',
            'call_status' => $new_status,
        ));
        $response_data = _ok(array('status' => $new_status));
        break;
    }

    case 'inbox': {
        $since = isset($_GET['since']) ? (int) $_GET['since'] : (time() - 120);
        $q = "SELECT id, caller_id, callee_id, media_type, status, UNIX_TIMESTAMP(created_at) AS ts
              FROM wow_calls
              WHERE callee_id={$me_id} AND status='ringing' AND UNIX_TIMESTAMP(created_at) >= {$since}
              ORDER BY id DESC LIMIT 1";
        $res = mysqli_query($sqlConnect, $q);
        $row = ($res && mysqli_num_rows($res)) ? mysqli_fetch_assoc($res) : null;
        $response_data = _ok(array('incoming' => $row));
        break;
    }

    default:
        $response_data = _ok(array('api_status' => 400, 'error' => 'Invalid type.'));
        break;
}

// Trả JSON
echo json_encode($response_data ? $response_data : array('api_status' => 200), JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
exit;
