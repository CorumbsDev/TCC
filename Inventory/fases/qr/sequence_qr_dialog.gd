extends AcceptDialog

## Diálogo de compartilhamento por QR (gera imagem + permite colar payload).

@onready var qr_image: TextureRect = %QrImage
@onready var status_label: Label = %StatusLabel
@onready var payload_edit: TextEdit = %PayloadEdit
@onready var btn_copy: Button = %BtnCopyPayload
@onready var btn_import: Button = %BtnImportPayload

signal import_requested(csv_text: String)

var _payload: String = ""


func setup_export(payload: String, texture: ImageTexture, info: String = "") -> void:
	_payload = payload
	title = "QR da Sequência"
	if qr_image:
		qr_image.texture = texture
		qr_image.visible = texture != null
	if payload_edit:
		payload_edit.text = payload
		payload_edit.editable = false
	if status_label:
		status_label.text = info if not info.is_empty() else "Aponte a câmera do celular ou use Copiar payload no outro PC."
	if btn_import:
		btn_import.visible = false
	if btn_copy:
		btn_copy.visible = true


func setup_import() -> void:
	_payload = ""
	title = "Importar via QR / Payload"
	if qr_image:
		qr_image.texture = null
		qr_image.visible = false
	if payload_edit:
		payload_edit.text = DisplayServer.clipboard_get().strip_edges()
		payload_edit.editable = true
		payload_edit.placeholder_text = "Cole aqui o texto COB1:... (ou o CSV completo)"
	if status_label:
		status_label.text = "Cole o payload lido do QR (apps de celular costumam copiar o texto) e clique em Importar."
	if btn_import:
		btn_import.visible = true
	if btn_copy:
		btn_copy.visible = false


func _ready() -> void:
	ok_button_text = "Fechar"
	if btn_copy and not btn_copy.pressed.is_connected(_on_copy_pressed):
		btn_copy.pressed.connect(_on_copy_pressed)
	if btn_import and not btn_import.pressed.is_connected(_on_import_pressed):
		btn_import.pressed.connect(_on_import_pressed)


func _on_copy_pressed() -> void:
	var t := _payload if not _payload.is_empty() else (payload_edit.text if payload_edit else "")
	if t.strip_edges().is_empty():
		if status_label:
			status_label.text = "Nada para copiar."
		return
	DisplayServer.clipboard_set(t)
	if status_label:
		status_label.text = "Payload copiado. Cole no outro jogo com «Importar QR»."


func _on_import_pressed() -> void:
	var raw := payload_edit.text if payload_edit else ""
	var decoded: Dictionary = SequenceQrCodec.decode_payload(raw)
	if not decoded.get("ok", false):
		if status_label:
			status_label.text = "Erro: " + str(decoded.get("error", "?"))
		return
	import_requested.emit(str(decoded.get("csv", "")))
	hide()
