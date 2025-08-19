extends Node
@export var mob_scene:PackedScene

func _ready():
	$UserInterface/Retry.hide()
	
# 怪物生成信号 0.5s生成一次
func _on_mob_timer_timeout():
	# 创建怪物场景
	var mob = mob_scene.instantiate()
	
	# 在生成路径 (SpawnPath) 上随机选择一个位置。
	# 我们把这个位置对应的 SpawnLocation 节点的引用保存下来。
	var mob_spawn_location = get_node("SpawnPath/SpawnLocation")
	# 给这个位置加一个随机偏移量
	mob_spawn_location.progress_ratio = randf()
	
	# 获取玩家当前位置
	var player_position = $Player.position
	# 初始化怪物朝着玩家附近的方向移动
	mob.initalize(mob_spawn_location.position,player_position)
	
	# 把怪物添加到主场景里面
	add_child(mob)
	
	mob.squashed.connect($UserInterface/ScoreLabel._on_mob_squashed.bind())


# 玩家死亡发出的信号
func _on_player_hit():
	$MobTimer.stop() # 停止继续生成怪物
	$UserInterface/Retry.show()
	
func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("ui_accept") and $UserInterface/Retry.visible:
		get_tree().reload_current_scene()
