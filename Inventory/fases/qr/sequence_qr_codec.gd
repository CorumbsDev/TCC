class_name SequenceQrCodec
extends RefCounted

## Empacota o CSV da sequência em payload curto para QR.
## Formato: COB1:<base64(deflate(utf8(csv)))>

const PREFIX := "COB1:"
## Limite prático de QR Version 40 / ECC LOW em modo bytes (~2953).
const MAX_PAYLOAD_CHARS := 2800


static func encode_csv(csv_text: String) -> Dictionary:
	var csv := csv_text.strip_edges()
	if csv.is_empty() or not csv.begins_with("KIND,"):
		return {"ok": false, "error": "CSV inválido para QR.", "payload": ""}
	var raw := csv.to_utf8_buffer()
	var compressed: PackedByteArray = raw.compress(FileAccess.COMPRESSION_DEFLATE)
	var b64 := Marshalls.raw_to_base64(compressed)
	var payload := PREFIX + b64
	if payload.length() > MAX_PAYLOAD_CHARS:
		return {
			"ok": false,
			"error": "Sequência grande demais para QR (%d chars). Use CSV." % payload.length(),
			"payload": payload,
		}
	return {"ok": true, "error": "", "payload": payload, "bytes_raw": raw.size(), "bytes_zip": compressed.size()}


static func decode_payload(text: String) -> Dictionary:
	var t := text.strip_edges()
	# Alguns leitores de QR adicionam espaços/quebras.
	t = t.replace("\n", "").replace("\r", "").replace(" ", "")
	if t.is_empty():
		return {"ok": false, "error": "Payload vazio.", "csv": ""}
	if not t.begins_with(PREFIX):
		# Aceita CSV cru colado por engano.
		if t.begins_with("KIND,"):
			return {"ok": true, "error": "", "csv": t}
		return {"ok": false, "error": "Payload não começa com %s" % PREFIX, "csv": ""}
	var b64 := t.substr(PREFIX.length())
	var compressed: PackedByteArray = Marshalls.base64_to_raw(b64)
	if compressed.is_empty():
		return {"ok": false, "error": "Base64 inválido.", "csv": ""}
	var raw: PackedByteArray = compressed.decompress_dynamic(-1, FileAccess.COMPRESSION_DEFLATE)
	if raw.is_empty():
		return {"ok": false, "error": "Falha ao descomprimir.", "csv": ""}
	var csv := raw.get_string_from_utf8().strip_edges()
	if not csv.begins_with("KIND,"):
		return {"ok": false, "error": "Conteúdo descomprimido não é CSV de sequência.", "csv": ""}
	return {"ok": true, "error": "", "csv": csv}


const _QrCodeScript = preload("res://Inventory/fases/qr/vendor/qr_code.gd")


static func make_texture(payload: String, module_scale: int = 8) -> ImageTexture:
	var qr := _QrCodeScript.new()
	qr.error_correct_level = _QrCodeScript.ErrorCorrectionLevel.LOW
	var tex: ImageTexture = qr.get_texture(payload)
	if tex == null:
		return null
	# Escala o QR para ficar legível na tela / celular.
	var img: Image = tex.get_image()
	if img == null:
		return tex
	var w := maxi(img.get_width() * module_scale, img.get_width())
	var h := maxi(img.get_height() * module_scale, img.get_height())
	img.resize(w, h, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(img)
