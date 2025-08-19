extends CharacterBody3D
signal  squashed #定义一个踩扁的信号

@export var min_speed = 10 # 最低移动速度
@export var max_speed = 18 # 最高移动速度

func _physics_process(_delta: float):
	move_and_slide()

func initalize(start_position,player_position):
	# 生成怪物并且朝向玩家方向
	look_at_from_position(start_position,player_position,Vector3.UP)
	# 敌人（mob）在 -45° 到 +45° 范围内随机旋转，这样它就不会笔直地朝玩家移动，而是带点随机偏移
	rotate_y(randf_range(-PI / 4,PI / 4))
	# 给一个随机的移动速度
	var random_speed = randi_range(min_speed,max_speed)
	# 向前移动
	velocity = Vector3.FORWARD * random_speed
	# 然后根据怪物（mob）的 Y 轴旋转角度来旋转速度向量，从而让怪物按照它面朝的方向移动。
	velocity = velocity.rotated(Vector3.UP,rotation.y)
	
	$AnimationPlayer.speed_scale = random_speed / float(min_speed)

# 离开屏幕的信号
func _on_visible_on_screen_notifier_3d_screen_exited():
	queue_free() # 释放资源
	
# 踩扁怪物
func squash():
	squashed.emit()
	queue_free()
	
