extends CharacterBody3D
signal hit

@export var speed = 14 #玩家移动速度（单位：m/s）
@export var fall_acceleration = 75 #当物体在空中时的向下加速度，单位是米每二次方秒（m/s²）
@export var jump_impule = 20 # 角色跳跃时施加的垂直冲量，单位：m/s 也可以理解成跳起来的高度
@export var bounce_impulse = 16 # 当角色踩到（或弹跳在）怪物身上时，施加给角色的垂直冲量，单位：m/s 。

var target_velocity = Vector3.ZERO

func _physics_process(delta: float):
	var direction = Vector3.ZERO
	
	# 监听用户按下的按钮
	# 在 3D 游戏里，位置/方向通常用三维向量 (x, y, z) 表示。
	# x 和 z 通常表示水平面上的坐标（左右、前后）。
	# y 则常用来表示垂直方向（上下，高度）。
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_back"):
		direction.z += 1
	if Input.is_action_pressed("move_forward"):
		direction.z -= 1
	
	if direction != Vector3.ZERO:
		direction = direction.normalized() # 归一化
		$Pivot.basis = Basis.looking_at(direction) # 让玩家对着这个方向
		$AnimationPlayer.speed_scale = 4
	else: 
		$AnimationPlayer.speed_scale = 1
		
	target_velocity.x = direction.x * speed
	target_velocity.z = direction.z * speed
	
	# 如果物体与地板碰撞了，这个函数返回就是true,只要物体没有回到地面，那么就每一帧都会下落
	if not is_on_floor(): # 如果跳起来了，那就按照重力加速度算法掉落到地面
		target_velocity.y = target_velocity.y - (fall_acceleration * delta)
		
	# 跳跃 必须在地板上才能执行跳跃操作
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		target_velocity.y = jump_impule
		
	# 移动玩家
	velocity = target_velocity
	# 这是CharacterBody3D的方法，允许平滑的移动角色。如果角色在运动过程中撞到墙，引擎会尝试帮你平滑移动。
	move_and_slide()
	
	$Pivot.rotation.x = PI / 6 * velocity.y / jump_impule
	
	# 处理玩家踩怪物碰撞机制
	# 遍历本帧中发生的所有碰撞
	for index in range(get_slide_collision_count()):
		# 获取其中一个碰撞器
		var collision = get_slide_collision(index)
		
		# 如果和同一个怪物在一帧内发生了多次碰撞
		# 第一次处理时怪物已经被删除，再次调用 get_collider 会返回 null
		# 避免了 重复处理同一个已销毁的怪物（否则会导致空指针错误）。
		if collision.get_collider() == null:
			continue
		
		# 判断碰撞的是不是怪物
		if collision.get_collider().is_in_group("mob"):
			var mob = collision.get_collider()
			# 检测是不是玩家从上方碰撞怪物
			# 这里用了 点积 (dot) 来判断碰撞法线和“向上”方向的关系。
			# 碰撞法线是一个 3D 向量，它与碰撞发生平面垂直。点积允许我们将它与向上方向进行比较
			# 通过点积，当结果大于 0 时，两个向量之间的角度小于 90 度。一个高于 0.1 的值告诉我们我们大致在怪物的上方。
			# 如果结果大于 0.1，说明碰撞的表面大致朝上 → 玩家确实是“踩”到了怪物。
			if Vector3.UP.dot(collision.get_normal()) > 0.1:
				# 如果是，就压扁怪物并让角色反弹
				mob.squash()
				# 给玩家一个向上的反弹速度，类似马里奥踩怪
				target_velocity.y = bounce_impulse
				# 防止后续再处理重复的碰撞
				break
		

# 当CharacterBody3D或者RigidBody3D节点碰到到MobDetector时，会发出一个body_entered的信号
# 就可以推断出怪物在玩家没有跳起来之前碰到了玩家，玩家死亡
func _on_mob_detector_body_entered(_body: Node3D):
	die()
	
func die():
	# 这里做两件事
	# game over 信号
	# player die
	hit.emit()
	queue_free()
