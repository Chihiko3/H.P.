extends CharacterBody3D

#***** NODES *****#
@onready var camera_3d = $Camera3D
@onready var origCamPos : Vector3 = camera_3d.position
@onready var floorcast = $FloorDetectRayCast
@onready var player_footstep_sound = $PlayerFootstepSound
@onready var interact_cast = $Camera3D/InteractRayCast


#***** CAMERA *****#
var mouse_sens := 0.15

#***** MOVEMENT *****#
var direction
var isRunning := false
var speed := 7
var jump := 35
const GRAVITY = 3
var distanceFootstep := 0.0
var playFootstep := 8 #lower => faster
#***** HEADBOB *****#
var _delta := 0.0
var camBobSpeed := 10
var camBobUpDown := 0.5


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$MeshInstance3D.visible = false
	
func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
		camera_3d.rotate_x(deg_to_rad(-event.relative.y * mouse_sens))
		camera_3d.rotation.x = clamp(camera_3d.rotation.x, deg_to_rad(-45), deg_to_rad(45))
	if Input.is_action_just_pressed("run"):
		isRunning = true
	if Input.is_action_just_released("run"):
		isRunning = false
	if Input.is_action_just_pressed("interact"):
		var interacted = interact_cast.get_collider()
		if interacted != null and interacted.is_in_group("Interactable") and interacted.has_method("action_use"):
			interacted.action_use()
				

func _process(delta):
	process_camBob(delta)
	
	if floorcast.is_colliding():
		var walkingTerrain = floorcast.get_collider().get_parent()
		if walkingTerrain != null:
			var terraingroup = walkingTerrain.get_groups()[0]
			processGroundSounds(terraingroup)

func processGroundSounds(group : String):
	#State machine to play sounds
	if isRunning:
		playFootstep = 6
	else:
		playFootstep = 8
	
	
	if (int(velocity.x) != 0) || int(velocity.z) != 0:
		distanceFootstep += 0.1 
		
	if distanceFootstep > playFootstep and is_on_floor():
		match group:
			"WoodTerrain":
				player_footstep_sound.stream = load("res://Player/SoundsFootsteps/wood/1.ogg")
			"Grass":
				player_footstep_sound.stream = load("res://Player/SoundsFootsteps/grass/3.ogg")
		player_footstep_sound.pitch_scale = randf_range(0.8, 1.2)
		player_footstep_sound.play()
		distanceFootstep = 0.0
#Camera movement
func process_camBob(delta):
		_delta += delta
		
		var cam_bob # bob speed
		var objCam # range of up and down
		
		if isRunning:
			cam_bob = floor(abs(direction.z) + abs(direction.x)) * _delta * camBobSpeed * 1.4
			objCam = origCamPos + Vector3.UP * sin(cam_bob) * camBobUpDown
		
		elif direction != Vector3.ZERO: # NOT IDLE PLAYER
			cam_bob = floor(abs(direction.z) + abs(direction.x)) * _delta * camBobSpeed
			objCam = origCamPos + Vector3.UP * sin(cam_bob) * camBobUpDown
		else: # IDLE PLAYER
			cam_bob = floor(abs(1) + abs(1)) * _delta * 0.5
			objCam = origCamPos + Vector3.UP * sin(cam_bob) * camBobUpDown * 0.5
		
		camera_3d.position = camera_3d.position.lerp(objCam, delta)

func _physics_process(delta):
	process_movement(delta)

#***** Process movement *****#
func process_movement(delta):
	direction = Vector3.ZERO
	
	var h_rot = global_transform.basis.get_euler().y
	
	direction.x = -Input.get_action_strength("ui_left")+Input.get_action_strength( "ui_right")
	direction.z = -Input.get_action_strength("ui_up")+Input.get_action_strength("ui_down")
	
	direction = Vector3(direction.x,0,direction.z).rotated(Vector3.UP,h_rot).normalized()
	
	var actualSpeed = speed if !isRunning else speed * 1.3
	
	velocity.x = direction.x * actualSpeed
	velocity.z = direction.z * actualSpeed

	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y += jump
	if !is_on_floor():
		velocity.y -= GRAVITY
	
		
	move_and_slide()
