class_name VictoryOverlay
extends Control

signal advance_requested

@onready var star1_rect: TextureRect = $Panel/VBoxContainer/StarsContainer/Star1
@onready var star2_rect: TextureRect = $Panel/VBoxContainer/StarsContainer/Star2
@onready var star3_rect: TextureRect = $Panel/VBoxContainer/StarsContainer/Star3

@onready var confete_1: CPUParticles2D = $Panel/VBoxContainer/StarsContainer/Star1/CPUParticles2D
@onready var confete_2: CPUParticles2D = $Panel/VBoxContainer/StarsContainer/Star2/CPUParticles2D
@onready var confete_3: CPUParticles2D = $Panel/VBoxContainer/StarsContainer/Star3/CPUParticles2D

@onready var lbl_title: Label = $Panel/VBoxContainer/Title
@onready var lbl_desc: Label = $Panel/VBoxContainer/Desc
@onready var btn_advance: Button = $Panel/VBoxContainer/Buttons/BtnAdvance
@onready var btn_retry: Button = $Panel/VBoxContainer/Buttons/BtnRetry

var earned_star1: bool = false
var earned_star2: bool = false
var earned_star3: bool = false

func _ready():
	hide()
	btn_advance.pressed.connect(_on_advance_pressed)
	btn_retry.pressed.connect(_on_retry_pressed)
	
	star1_rect.modulate = Color(0.2, 0.2, 0.2, 1.0)
	star2_rect.modulate = Color(0.2, 0.2, 0.2, 1.0)
	star3_rect.modulate = Color(0.2, 0.2, 0.2, 1.0)
	
	PanelArtLoader.apply_background(self)
	PanelArtLoader.skin_all_buttons(self)

func show_victory(s1: bool, s2: bool, s3: bool, desc: String = ""):
	earned_star1 = s1
	earned_star2 = s2
	earned_star3 = s3
	lbl_desc.text = desc
	
	show()
	_animate_stars()

func _animate_stars():
	if earned_star1:
		await get_tree().create_timer(0.5).timeout
		star1_rect.modulate = Color(1, 1, 1, 1)
		confete_1.emitting = true
	
	if earned_star2:
		await get_tree().create_timer(0.7).timeout
		star2_rect.modulate = Color(1, 1, 1, 1)
		confete_2.emitting = true
		
	if earned_star3:
		await get_tree().create_timer(0.9).timeout
		star3_rect.modulate = Color(1, 1, 1, 1)
		confete_3.emitting = true

func _on_advance_pressed():
	advance_requested.emit()
	queue_free()

func _on_retry_pressed():
	# Recarrega a fase atual
	get_tree().reload_current_scene()
