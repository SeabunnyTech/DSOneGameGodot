extends Node
## 全局錯誤記錄器
## 記錄所有錯誤和重要事件到檔案，方便追蹤 crash 原因

const LOG_DIR = "user://logs/"
const LOG_FILE = "crash_log.txt"
const MAX_LOG_SIZE = 1024 * 1024  # 1 MB
const MAX_RECENT_EVENTS = 100

var log_file_path: String
var recent_events: Array[String] = []
var session_start_time: String

func _ready():
	_ensure_log_directory()
	session_start_time = Time.get_datetime_string_from_system()
	log_file_path = LOG_DIR + LOG_FILE

	# 記錄程式啟動
	log_event("SESSION_START", "Game started at %s" % session_start_time)
	log_event("SYSTEM_INFO", "OS: %s, Godot: %s" % [OS.get_name(), Engine.get_version_info().string])

func _notification(what):
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			log_event("SESSION_END", "Game closed normally")
			_flush_to_file()
		NOTIFICATION_CRASH:
			log_event("CRASH", "Game crashed!")
			_flush_to_file()

func _ensure_log_directory():
	var dir = DirAccess.open("user://")
	if dir and not dir.dir_exists("logs"):
		dir.make_dir("logs")

## 記錄一般事件
func log_event(category: String, message: String):
	var timestamp = Time.get_datetime_string_from_system()
	var entry = "[%s] [%s] %s" % [timestamp, category, message]
	recent_events.append(entry)

	# 保持最近事件數量在限制內
	while recent_events.size() > MAX_RECENT_EVENTS:
		recent_events.pop_front()

	# 同時輸出到 console
	print(entry)

## 記錄錯誤（會立即寫入檔案）
func log_error(category: String, message: String):
	log_event("ERROR:%s" % category, message)
	_flush_to_file()

## 記錄網路相關事件
func log_network(message: String, payload: Variant = null):
	var log_msg = message
	if payload != null:
		log_msg += " | payload_type: %s" % typeof(payload)
		if payload is Dictionary:
			log_msg += " | keys: %s" % str(payload.keys())
		elif payload is Array:
			log_msg += " | size: %d" % payload.size()
	log_event("NETWORK", log_msg)

## 記錄網路錯誤（會立即寫入檔案）
func log_network_error(message: String, payload: Variant = null):
	var log_msg = message
	if payload != null:
		# 記錄完整的 payload 內容以便除錯
		log_msg += " | payload: %s" % str(payload).substr(0, 500)  # 限制長度
	log_error("NETWORK", log_msg)

## 將最近事件寫入檔案
func _flush_to_file():
	_rotate_log_if_needed()

	var file = FileAccess.open(log_file_path, FileAccess.READ_WRITE)
	if file == null:
		# 檔案不存在，創建新檔案
		file = FileAccess.open(log_file_path, FileAccess.WRITE)

	if file == null:
		push_error("CrashLogger: Cannot open log file: %s" % log_file_path)
		return

	# 移動到檔案末尾
	file.seek_end()

	# 寫入分隔線和最近事件
	file.store_line("\n=== Session: %s ===" % session_start_time)
	for event in recent_events:
		file.store_line(event)

	file.close()

	# 清空已寫入的事件（保留最後幾筆以防重複 flush）
	if recent_events.size() > 10:
		recent_events = recent_events.slice(-10)

## 檢查並輪換過大的 log 檔案
func _rotate_log_if_needed():
	if not FileAccess.file_exists(log_file_path):
		return

	var file = FileAccess.open(log_file_path, FileAccess.READ)
	if file == null:
		return

	var size = file.get_length()
	file.close()

	if size > MAX_LOG_SIZE:
		var dir = DirAccess.open(LOG_DIR)
		if dir:
			var backup_name = "crash_log_%s.txt" % Time.get_datetime_string_from_system().replace(":", "-")
			dir.rename(LOG_FILE, backup_name)

## 取得 log 檔案的完整路徑（方便使用者找到）
func get_log_path() -> String:
	return ProjectSettings.globalize_path(log_file_path)
