extends KinematicBody

const GD_SOURCE_RATIO := 10 # Not actually correct, tweak as wanted.

const MAX_AIR_SPEED        := 30   / GD_SOURCE_RATIO
const MAX_SPEED            := 320  / GD_SOURCE_RATIO
const MAX_ACCELERATION     := 3200 / GD_SOURCE_RATIO
const MAX_AIR_ACCELERATION := 6400 / GD_SOURCE_RATIO
const FRICTION             := 0.9  / GD_SOURCE_RATIO
const GRAVITY              := 0 # Testing Air strafes # 180  / GD_SOURCE_RATIO

onready var head              := $Head
var         sensitivity       := 0.25
var         desired_direction := Vector3.ZERO
var         velocity          := Vector3.ZERO

func _physics_process(delta_time):

    var cx := transform.basis.x # Left, right
    var cz := transform.basis.z # Forward, backward

    desired_direction = Vector3.ZERO

    if Input.is_action_pressed("move_forward"):
        desired_direction -= cz

    if Input.is_action_pressed("move_backward"):
        desired_direction += cz

    if Input.is_action_pressed("move_right"):
        desired_direction += cx

    if Input.is_action_pressed("move_left"):
        desired_direction -= cx

    desired_direction = desired_direction.normalized()

    # Assume it's on air.
    velocity.y += GRAVITY * delta_time

    var max_speed        := MAX_AIR_SPEED
    var max_acceleration := MAX_AIR_ACCELERATION

    # It's actually on ground.
    if is_on_floor():
        velocity.y = 0

        velocity *= FRICTION * delta_time

        max_speed        = MAX_SPEED
        max_acceleration = MAX_ACCELERATION

    var current_speed := desired_direction.dot(velocity)
    var     add_speed := max(
        0,
        min(
            max_acceleration * delta_time,
            max_speed        - current_speed
        )
    ) # Clipping.

    velocity += add_speed * desired_direction

    move_and_slide(velocity)
