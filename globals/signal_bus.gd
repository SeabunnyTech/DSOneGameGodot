extends Node

signal ui_ready
signal hud_ready

signal player_signup_portal_changed(player: Node, is_entered: bool)
signal player_ready_portal_changed(player: Node, is_entered: bool)
signal player_full_rotation_completed(player: Node)
signal player_rotation_detected(player: Node, clockwise: bool, speed: float)
signal level_portal_entered(player: Node, level: String)
signal level_portal_exited(player: Node, level: String)

signal electrons_to_spawn(count: int, player_id: int, spawn_id: int)
signal electrons_to_collect(player_id: int, spawn_id: int)
signal electrons_scoring(count: int, player_id: int)
signal electrons_scored()
