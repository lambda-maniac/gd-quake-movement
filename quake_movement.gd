extends KinematicBody

const MAX_AIR_SPEED        := 1.5
const MAX_SPEED            := 15
const MAX_ACCELERATION     := 60
const MAX_AIR_ACCELERATION := 600

const FRICTION             := 2.5
const GRAVITY              := 25
const TERMINAL_VELOCITY    := GRAVITY * -4.5
const JUMP_IMPULSE         := 10
const MAX_SLOPE_ANGLE      := deg2rad(45)
const HALTING_SPEED        := 0.09

var sensitivity := 0.1

onready var head := $Head

var slope_snap := Vector3.ZERO

var p_desired_direction := Vector3.ZERO
var p_velocity          := Vector3.ZERO
var p_vertical_velocity := 0.0
var p_jumping           := false

func calculate_acceleration( desired_direction : Vector3
                           , velocity          : Vector3
                           , acceleration      : float
                           , max_speed         : float
                           , delta_time        : float ) -> Vector3:

    var    current_speed := velocity.dot(desired_direction)
    var additional_speed := clamp(max_speed - current_speed, 0, acceleration * delta_time)

    return velocity + desired_direction * additional_speed

func h_calculate_friction( velocity   : Vector3
                         , friction   : float
                         , delta_time : float ) -> Vector3:

    var speed           := velocity.length()
    var scaled_velocity := Vector3.ZERO

    if speed <= HALTING_SPEED:
        return scaled_velocity

    if speed != 0:
        var speed_drop := speed * friction * delta_time

        scaled_velocity = velocity * max(speed - speed_drop, 0) / speed

    return scaled_velocity

func v_ground_accelerate_and_move(delta_time: float) -> void:
    var accelerated := Vector3.ZERO

    accelerated.x = p_velocity.x
    accelerated.z = p_velocity.z

    accelerated = h_calculate_friction(accelerated, FRICTION, delta_time)
    accelerated = calculate_acceleration(
        p_desired_direction,
        accelerated,
        MAX_ACCELERATION,
        MAX_SPEED,
        delta_time
    )

    accelerated.y = p_vertical_velocity

    p_velocity = move_and_slide_with_snap(
        accelerated,
        slope_snap,
        Vector3.UP,
        true,
        4,
        MAX_SLOPE_ANGLE
    )

func v_air_accelerate_and_move(delta_time: float) -> void:
    var accelerated := Vector3.ZERO

    accelerated.x = p_velocity.x
    accelerated.z = p_velocity.z

    accelerated = calculate_acceleration(
        p_desired_direction,
        accelerated,
        MAX_AIR_ACCELERATION,
        MAX_AIR_SPEED,
        delta_time
    )

    accelerated.y = p_vertical_velocity

    p_velocity = move_and_slide_with_snap(accelerated, slope_snap, Vector3.UP)

func _ready():
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta_time):

    var cx := transform.basis.x
    var cz := transform.basis.z

    p_desired_direction = Vector3.ZERO

    if Input.is_action_pressed("move_forward"):
        p_desired_direction -= cz

    if Input.is_action_pressed("move_backward"):
        p_desired_direction += cz

    if Input.is_action_pressed("move_right"):
        p_desired_direction += cx

    if Input.is_action_pressed("move_left"):
        p_desired_direction -= cx

    p_desired_direction = p_desired_direction.normalized()

    if Input.is_action_pressed("move_jump"):
        p_jumping = true
    if Input.is_action_just_released("move_jump"):
        p_jumping = false

    if is_on_floor():

        if p_jumping:

            slope_snap = Vector3.ZERO

            p_vertical_velocity = JUMP_IMPULSE

            v_air_accelerate_and_move(delta_time)

            p_jumping = false

        else:

            slope_snap = -get_floor_normal()

            p_vertical_velocity = 0

            v_ground_accelerate_and_move(delta_time)
    else:

        slope_snap = Vector3.DOWN

        p_vertical_velocity -= GRAVITY * delta_time if p_vertical_velocity >= TERMINAL_VELOCITY else 0

        v_air_accelerate_and_move(delta_time)

    if is_on_ceiling():
        p_vertical_velocity = 0

func _input(event):
    if event is InputEventMouseMotion:
        rotate_y(
            deg2rad( -event.relative.x * sensitivity )
        )

        head.rotate_x(
            deg2rad( -event.relative.y * sensitivity )
        )

        head.rotation.x = clamp(
            head.rotation.x,
            deg2rad(-89),
            deg2rad( 89)
        )
